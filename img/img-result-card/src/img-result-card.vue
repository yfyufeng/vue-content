<template>
  <div
    ref="card"
    :class="cls"
    @mouseenter="handleMouseenter"
    @mouseleave="handleMouseleave"
  >
    <div class="h-image-result-card__item">
      <div
        v-if="choosable"
        :class="{
          'h-image-result-card__item-choosable': true,
          'h-image-result-card__item-choosable--active': isChoosed
        }"
        @click="chooseHandle"
      />
      <div
        :style="picStyle"
        class="h-image-result-card__item-pic"
        @click="picHandle"
      >
        <h-img-snippets-thumbnail
          v-if="data.thumbnail"
          :mode="picMode"
          :img-url="data.pic"
          :rect-props="{
            width: 'w',
            left: 'x',
            height: 'h',
            top: 'y'
          }"
          :rect="data.thumbnail"
          original
          bg="gray"
        />
        <h-img-view v-else :src="data.pic" :mode="picMode" bg="gray" />
        <div v-if="$slots.topLeft" class="h-image-result-card__extra-topLeft">
          <slot name="topLeft" />
        </div>
        <div v-if="$slots.topRight" class="h-image-result-card__extra-topRight">
          <slot name="topRight" />
        </div>
        <div
          v-if="$slots.bottomLeft"
          class="h-image-result-card__extra-bottomLeft"
        >
          <slot name="bottomLeft" />
        </div>
        <div
          v-if="$slots.bottomRight"
          class="h-image-result-card__extra-bottomRight"
        >
          <slot name="bottomRight" />
        </div>
        <div v-if="data.label" class="h-image-result-card__item-label">
          {{ data.label }}
        </div>
      </div>
      <div
        v-if="data && data.info"
        :style="infoStyle"
        class="h-image-result-card__item-info"
      >
        <ul>
          <template
            v-for="(item, infoIndex) in data.info"
            :label="item.label"
            :title="item.content || ''"
            :class="`${item.keynote ? 'keynote' : ''}`"
          >
            <li v-if="$slots.info || $scopedSlots.info" :key="infoIndex">
              <slot :item="item" name="info" />
            </li>
            <li v-else-if="!isInfoEmpty(item)" :key="infoIndex">
              <i v-if="item.icon" :class="item.icon" />
              <label v-if="item.label" v-text="item.label" />
              <span v-if="item.content" v-text="item.content" />
            </li>
          </template>
        </ul>
      </div>
      <div
        v-if="data.detail || (data.btns && data.btns.length > 0)"
        ref="btns"
        class="h-image-result-card__item-btns"
      >
        <div ref="btnsWrapper" class="h-image-result-card__item-btns-wrapper">
          <div ref="btnsContent" class="h-image-result-card__item-btns-content">
            <template>
              <el-button
                v-for="(btn, btnsIndex) in data.btns.filter(doFilter1)"
                :ref="`btn${btnsIndex}`"
                :key="btnsIndex"
                :icon="btn.icon"
                :title="btn.title || ''"
                size="small"
                @click="
                  e => {
                    clickBtnHandle(e, btn, data);
                  }
                "
              >
                <span v-if="showTitle">{{ btn.title }}</span>
              </el-button>
            </template>
            <el-popover
              v-if="hasMoreBtns"
              ref="popover"
              placement="bottom"
              trigger="hover"
              popper-class="h-image-result-card__item-btns-popover"
              @hide="popBtnsHide"
            >
              <el-button
                v-for="(btn, btnsIndex) in data.btns.filter(doFilter2)"
                :key="btnsIndex"
                :icon="btn.icon"
                :title="btn.title || ''"
                size="small"
                @click="
                  e => {
                    clickBtnHandle(e, btn, data);
                  }
                "
              >
                <span v-if="showTitle">{{ btn.title }}</span>
              </el-button>
              <el-button
                ref="moreBtn"
                slot="reference"
                icon="lidaicon-h-more-horizontal"
                size="small"
              >
                <span v-if="showTitle" v-text="t('h.imgResultCard.more')" />
              </el-button>
            </el-popover>
          </div>
        </div>
      </div>
    </div>
    <div v-if="$slots.default" class="h-image-result-card__extra">
      <slot />
    </div>
  </div>
</template>
<script>
import { t } from '@hui-pro/locale';
import {
  style,
  width,
  height,
  contains,
  isEmpty,
  isNumber
} from '@hui-pro/utils';
// components
import ImgView from '@hui-pro/img-view/src/img-view.vue';
import Thumbnail from '@hui-pro/img-snippets/src/thumbnail.vue';

export default {
  name: 'HImgResultCard',
  components: {
    HImgView: ImgView,
    HImgSnippetsThumbnail: Thumbnail
  },
  props: {
    animate: {
      type: Boolean,
      default: false
    },
    horizontal: {
      type: Boolean,
      default: false
    },
    choosable: {
      type: Boolean,
      default: false
    },
    active: {
      type: Boolean,
      default: false
    },
    isChoosed: {
      type: Boolean,
      default: false
    },
    picMode: {
      type: String,
      default: 'cover'
    },
    picSize: {
      type: [Object, Number],
      default: () => {
        return {
          width: 215,
          height: 215
        };
      }
    },
    showTitle: {
      type: Boolean,
      default: false
    },
    data: {
      type: Object,
      default: () => {}
    }
  },
  data() {
    return {
      t,
      showShadow: false,
      maxBtnsNum: 0,
      hasMoreBtns: true
    };
  },
  computed: {
    cls() {
      return {
        'h-image-result-card': true,
        'h-image-result-card--choosed': this.isChoosed && this.choosable,
        'h-image-result-card--active': this.active,
        'h-image-result-card--horizontal': this.horizontal,
        'h-image-result-card--animate': this.animate
      };
    },
    picStyle() {
      return {
        width: this.addPx(this.picSize.width),
        height: this.addPx(this.picSize.height)
      };
    },
    infoStyle() {
      return {
        width: this.addPx(this.picSize.width)
      };
    }
  },
  mounted() {
    this.init();
  },
  methods: {
    init() {
      if (this.data.btns) {
        this.maxBtnsNum = this.data.btns.length;
        let maxBtnsNum = 0;
        const moreBtnWidth = this.$refs.moreBtn
          ? width(this.$refs.moreBtn.$el)
          : 0;
        this.$nextTick(() => {
          let wrapperWidth = this.picSize.width + 4 - moreBtnWidth;
          if (this.showTitle) {
            for (const el of this.$refs.btnsContent.children) {
              if (wrapperWidth - width(el) > 0) {
                wrapperWidth -= width(el);
                maxBtnsNum++;
              } else {
                break;
              }
            }
            this.maxBtnsNum = maxBtnsNum;
          } else {
            this.maxBtnsNum = Math.floor(this.picSize.width / 32);
            if (this.data.btns.length > this.maxBtnsNum) {
              this.maxBtnsNum--;
            }
          }
          this.hasMoreBtns = this.data.btns.length > this.maxBtnsNum;
        });
      }
    },
    addPx(val) {
      return isNumber(val) ? `${val}px` : val;
    },
    handleMouseenter() {
      const h1 = this.$refs.btnsWrapper
        ? height(this.$refs.btnsWrapper, 'outer')
        : 0;
      style(this.$refs.card, {
        marginBottom: -h1,
        top: this.animate ? '-4px' : 0,
        zIndex: 1001
      });
      if (this.$refs.btns) {
        style(this.$refs.btns, {
          height: h1
        });
      }
    },
    handleMouseleave(event) {
      const isContains = contains(this.$refs.card, event.relatedTarget);
      const isContainsPop =
        event.relatedTarget &&
        (event.relatedTarget.className === 'popper__arrow' ||
          event.relatedTarget.className.indexOf('popover') > -1);
      if (!isContains && !isContainsPop) {
        style(this.$refs.card, {
          marginBottom: 0,
          top: 0,
          zIndex: null
        });
        if (this.$refs.btns) {
          style(this.$refs.btns, {
            height: 0
          });
        }
      }
    },
    // 点击buttons 处理事件
    clickBtnHandle(e, btn, dataItem) {
      if (btn.click) {
        e.stopPropagation();
        btn.click(dataItem);
      }
    },
    isInfoEmpty(item) {
      return isEmpty(item.icon) && isEmpty(item.label) && isEmpty(item.content);
    },
    doFilter1(element, index) {
      return index < this.maxBtnsNum - (this.hasMoreBtns ? 1 : 0);
    },
    doFilter2(element, index) {
      return index > this.maxBtnsNum - (this.hasMoreBtns ? 2 : 1);
    },
    popBtnsHide() {
      style(this.$refs.card, {
        marginBottom: 0,
        top: 0
      });
      style(this.$refs.btns, {
        height: 0
      });
    },
    chooseHandle(event) {
      this.stopEvent(event);
      this.$emit('choose', this.data);
    },
    picHandle(event) {
      this.stopEvent(event);
      this.$emit('click-pic', this.data);
    },
    stopEvent(event) {
      // 阻止冒泡事件
      if (event && event.stopPropagation) {
        event.stopPropagation();
      } else if (window.event) {
        window.event.cancelBubble = true;
      }
    }
  }
};
</script>
