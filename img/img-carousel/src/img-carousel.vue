<template>
  <div :class="[`h-img-carousel--theme-${theme}`]" class="h-img-carousel">
    <div v-show="!noData" class="h-img-carousel__wrapper">
      <div ref="items" :style="itemsStyle" class="h-img-carousel__items">
        <div
          v-for="item in visibleData"
          :key="item[props.key] || `h-img-carousel-${item.$$index}`"
          class="h-img-carousel__item"
        >
          <slot
            v-if="$slots.item || $scopedSlots.item"
            :item="item"
            name="item"
          />
          <div
            v-else-if="item[props.type] === 1"
            class="h-img-carousel__video-wrapper"
          >
            <video
              :ref="item.$$index"
              :src="item[props.url]"
              :style="videoStyle(item)"
              class="h-img-carousel__video"
              controls
              @loadstart="handleVideoLoad(item)"
              @error="handleVideoError(item)"
              @canplay="
                itemMounted(item.$$index === internalCurrentPage, ...arguments)
              "
            />
            <h-empty
              v-if="item.$$error"
              :size="emptySize"
              class="h-img-carousel__placeholder"
            >
              <h-empty-error-video />
            </h-empty>
          </div>
          <h-img-view
            v-else
            :ref="item.$$index"
            v-bind="imgViewCtor.$props"
            :bg="imgViewBg"
            :title="item[props.title]"
            :src="item[props.url]"
            no-transition
            @on-zoom="onZoom"
            @on-view-change="
              onViewChange(item.$$index === internalCurrentPage, ...arguments)
            "
          />
        </div>
      </div>
      <div v-if="$slots.btnGroup" class="h-img-carousel__btn-group">
        <slot name="btnGroup" />
      </div>
    </div>
    <h-empty v-if="noData" :size="emptySize">
      <h-empty-no-data />
    </h-empty>
    <span v-if="showBtn" @click="$prev">
      <slot
        v-if="$slots.prev || $scopedSlots.prev"
        :disabled="disabledPrev"
        name="prev"
      />
      <button
        v-else
        :disabled="disabledPrev"
        :class="{
          'is-disabled': disabledPrev
        }"
        type="button"
        class="h-img-carousel__prev"
      >
        <i class="h-icon-angle_left" />
      </button>
    </span>
    <span v-if="showBtn" @click="$next">
      <slot
        v-if="$slots.next || $scopedSlots.next"
        :disabled="disabledNext"
        name="next"
      />
      <button
        v-else
        :disabled="disabledNext"
        :class="{
          'is-disabled': disabledNext
        }"
        type="button"
        class="h-img-carousel__next"
      >
        <i class="h-icon-angle_right" />
      </button>
    </span>
  </div>
</template>
<script>
import Vue from 'vue';
import {
  isArray,
  isObject,
  merge,
  width,
  on,
  off,
  throttle,
  addClass,
  removeClass,
  type,
  isElement,
  isUndefined,
  Stack,
  isEmpty,
  isNull
} from '@hui-pro/utils';
// components
import ImgView from '@hui-pro/img-view/src/img-view.vue';
import emptySvg from '@hui-pro/empty/src/assets/svg.common.js';

const { NoData, ErrorVideo } = emptySvg;

export default {
  name: 'HImgCarousel',
  components: {
    HImgView: ImgView,
    HEmptyErrorVideo: ErrorVideo,
    hEmptyNoData: NoData
  },
  props: {
    ...ImgView.props,
    theme: {
      type: String,
      default: 'light',
      validator(value) {
        return ['light', 'light-gray', 'dark', 'transparent'].includes(value);
      }
    },
    data: {
      type: Array,
      default: () => []
    },
    dataProps: {
      type: Object,
      default: () => {
        return {};
      }
    },
    currentIndex: {
      type: Number,
      default: 0,
      validator(value) {
        return type(value) === 'Integer' && value >= 0;
      }
    },
    singleHideBtn: {
      type: Boolean,
      default: false
    },
    noTransition: {
      type: Boolean,
      default: false
    },
    beforeChange: {
      type: Function,
      default: () => {
        return new Promise(resolve => {
          resolve();
        });
      }
    },
    /**
     * rewrite props
     */
    resize: {
      type: Boolean,
      default: true
    }
  },
  data() {
    return {
      props: {
        title: 'title',
        url: 'url',
        key: 'key',
        type: 'type'
      },
      // 当前可视数据
      visibleData: [],
      // 缓存数据
      cacheData: [],
      translateX: 0,
      // 当前真实索引
      internalCurrentPage: null,
      prveCurrentPage: 0,
      isLocked: false,
      imgViewCtor: {}
    };
  },
  computed: {
    imgViewBg() {
      if (this.bg !== 'transparent') {
        return this.bg;
      }
      if (['light-gray', 'light-gray-big-btn'].includes(this.theme)) {
        return 'gray';
      } else if (this.theme === 'dark') {
        return 'transparent';
      }
      return 'transparent';
    },
    noData() {
      return this.data.length === 0;
    },
    itemsStyle() {
      return {
        transform: `translateX(${this.translateX}px)`
      };
    },
    disabledPrev() {
      // 禁用前一页按钮
      return this.internalCurrentPage === 0 || this.noData;
    },
    disabledNext() {
      // 禁用下一页按钮
      let length = this.cacheData.length - 1;
      if (length < 0) {
        length = 0;
      }
      return this.internalCurrentPage === length || this.noData;
    },
    videoStyle() {
      return function(item) {
        return {
          display: this.isLocked || item.$$error ? 'none' : 'block'
        };
      };
    },
    showBtn() {
      const length = this.data.length;
      if (this.singleHideBtn) {
        return length !== 1;
      } else {
        return true;
      }
    }
  },
  watch: {
    data: {
      deep: true,
      handler(val) {
        this.$reset();
      }
    },
    internalCurrentPage(val, oldVal) {
      this.prveCurrentPage = oldVal;
      if (val !== oldVal && !isNull(oldVal)) {
        this.$emit('on-change', this.data[val], val);
        this.$emit('update:current-index', val);
        this.$selected(val);
      }
    },
    theme() {
      this.$reset();
    },
    currentIndex: {
      immediate: true,
      handler(val) {
        if (this.data.length > val) {
          this.internalCurrentPage = val;
        } else {
          this.internalCurrentPage = 0;
        }
      }
    },
    isLocked(val) {
      if (!val) {
        removeClass(this.$refs.items, 'is-transition');
      }
    }
  },
  created() {
    this.stack = new Stack();
    const ImgViewCtor = Vue.extend(ImgView);
    this.imgViewCtor = new ImgViewCtor({ propsData: this.$props });
    this.props = merge(this.props, this.dataProps);
  },
  mounted() {
    if (isElement(this.$refs.items)) {
      on(this.$refs.items, 'transitionend', this.onTransitionend);
    }
    if (isElement(this.$el)) {
      on(this.$el, 'resize', this.onResize);
    }
    if (!this.$isServer) {
      on(document.documentElement, 'keydown', this.handleKeydown);
    }
    this.init();
  },
  beforeDestroyed() {
    if (isElement(this.$refs.items)) {
      off(this.$refs.items, 'transitionend', this.onTransitionend);
    }
    if (isElement(this.$el)) {
      off(this.$el, 'resize', this.onResize);
    }
    if (!this.$isServer) {
      off(document.documentElement, 'keydown', this.handleKeydown);
    }
  },
  methods: {
    onResize: throttle(function() {
      if (this.resize) {
        this.init();
      }
    }, 320),
    viewWidth() {
      if (this.$refs.items) {
        return width(this.$refs.items);
      }
      return 0;
    },
    init() {
      this.initData();
      this.refresh();
    },
    refresh() {
      this.isLocked = false;
      this.refreshData();
    },
    refreshData() {
      let startIndex = this.internalCurrentPage - (this.noTransition ? 0 : 1);
      let endIndex = this.internalCurrentPage + (this.noTransition ? 1 : 2);
      if (startIndex < 0) {
        startIndex = 0;
      }
      if (endIndex > this.data.length) {
        endIndex = this.data.length;
      }
      this.visibleData = this.cacheData.slice(startIndex, endIndex);
      this.$nextTick(() => {
        if (
          this.internalCurrentPage === 0 ||
          this.visibleData.length === 1 ||
          this.noTransition
        ) {
          this.translateX = 0;
        } else {
          this.translateX = -this.viewWidth();
        }
        this.$resetImgView();
      });
    },
    initData() {
      if (isArray(this.data)) {
        this.cacheData = [];
        this.data.forEach((item, index) => {
          this.cacheData.push(
            merge(
              {},
              isObject(item)
                ? item
                : {
                    url: item
                  },
              {
                $$index: index,
                $$error: false
              }
            )
          );
        });
      }
    },
    handleVideoLoad(item) {
      this.$set(item, '$$error', false);
    },
    handleVideoError(item) {
      this.$set(item, '$$error', true);
    },
    handleKeydown(e) {
      if (
        !['INPUT', 'TEXTAREA'].includes(e.target.tagName) &&
        [37, 38, 39, 40].includes(e.keyCode)
      ) {
        e.preventDefault();
        switch (e.keyCode) {
          case 37:
          case 38:
            this.$prev();
            break;
          case 39:
          case 40:
            this.$next();
            break;
        }
      }
    },
    onTransitionend(e) {
      // 只渲染可视区域数据，减少DOM加载
      if (isUndefined(e) || e.target === e.currentTarget) {
        const internalCurrentPage = this.internalCurrentPage;
        const item = this.data[internalCurrentPage];
        this.refreshData();
        const ref = this.$getItemRef();
        this.updateViewData(ref);
        this.$emit('on-changed', item, internalCurrentPage);
        this.isLocked = false;
      }
    },
    onZoom(opts) {
      this.$emit('on-zoom', opts);
    },
    updateViewData(ref) {
      let viewData = {
        scale: 1,
        ratio: 1,
        translateX: 0,
        translateY: 0
      };
      if (ref instanceof Vue) {
        viewData = ref.$getZoomData();
      }
      this.$emit('update:view-data', viewData);
    },
    itemMounted(isCurrent, ref) {
      if (isCurrent) {
        this.updateViewData(ref);
      }
    },
    onViewChange(isCurrent, val) {
      if (isCurrent) {
        this.$emit('update:view-data', val);
      }
    },
    move(length) {
      if (!this.noTransition && Math.abs(length) !== 0) {
        addClass(this.$refs.items, 'is-transition');
        this.$nextTick(() => {
          this.translateX += length;
        });
      } else {
        this.onTransitionend();
      }
    },
    $getItemRef(key) {
      const ref = this.$refs[
        !isUndefined(key) ? key : this.internalCurrentPage
      ];
      if (ref) {
        if (ref[0] instanceof Vue) {
          return ref[0];
        }
      }
      return null;
    },
    async $prev() {
      if (this.internalCurrentPage === 0 || this.isLocked || this.noData) {
        return;
      }
      try {
        const item = this.data[this.internalCurrentPage];
        await this.stack.promise(this.beforeChange(item));
        this.isLocked = true;
        this.internalCurrentPage--;
        this.$emit(
          'on-prev',
          this.data[this.internalCurrentPage],
          this.internalCurrentPage
        );
        this.move(+this.viewWidth());
      } catch (error) {
        if (!isEmpty(error)) {
          throw error;
        }
      }
    },
    async $next() {
      if (
        this.internalCurrentPage === this.cacheData.length - 1 ||
        this.isLocked ||
        this.noData
      ) {
        return;
      }
      try {
        const item = this.data[this.internalCurrentPage];
        await this.stack.promise(this.beforeChange(item));
        this.isLocked = true;
        this.internalCurrentPage++;
        this.$emit(
          'on-next',
          this.data[this.internalCurrentPage],
          this.internalCurrentPage
        );
        this.move(-this.viewWidth());
      } catch (error) {
        if (!isEmpty(error)) {
          throw error;
        }
      }
    },
    async $selected(index) {
      const offsetIndex =
        index === this.internalCurrentPage
          ? this.prveCurrentPage
          : this.internalCurrentPage;
      if (
        index === offsetIndex ||
        index >= this.cacheData.length ||
        this.isLocked ||
        this.noData
      ) {
        return;
      }
      try {
        const item = this.data[index];
        await this.stack.promise(this.beforeChange(item));
        this.isLocked = true;
        if (index - offsetIndex > 0) {
          this.visibleData[this.visibleData.length - 1] = this.cacheData[index];
          this.move(-this.viewWidth());
        } else {
          this.visibleData[0] = this.cacheData[index];
          this.move(+this.viewWidth());
        }
        this.internalCurrentPage = index;
      } catch (error) {
        if (!isEmpty(error)) {
          throw error;
        }
      }
    },
    $resetImgView(original = false) {
      this.$nextTick(() => {
        const ref = this.$getItemRef();
        const prevRef = this.$getItemRef(this.internalCurrentPage - 1);
        const nextRef = this.$getItemRef(this.internalCurrentPage + 1);
        if (ref) {
          ref.$resetView(original);
        }
        if (prevRef) {
          prevRef.$resetView(original);
        }
        if (nextRef) {
          nextRef.$resetView(original);
        }
      });
    },
    $reset() {
      this.init();
    },
    $zoomOut() {
      this.$nextTick(() => {
        const ref = this.$getItemRef();
        if (ref) {
          ref.$zoomOut();
        }
      });
    },
    $zoomIn() {
      this.$nextTick(() => {
        const ref = this.$getItemRef();
        if (ref) {
          ref.$zoomIn();
        }
      });
    }
  }
};
</script>
