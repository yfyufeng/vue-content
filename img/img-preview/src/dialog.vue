<template>
  <div :class="[`h-img-preview--theme-${$parent.theme}`]" class="h-img-preview">
    <transition name="zoom" @after-enter="afterEnter" @after-leave="afterLeave">
      <div
        v-show="isShow"
        :style="{ transformOrigin: transformOrigin }"
        :class="{
          'has-album': $parent.showAlbum
        }"
        class="h-img-preview__wrapper"
      >
        <div v-if="hasTop" class="h-img-preview__top">
          <slot :item="item" name="top" />
        </div>
        <div class="h-img-preview__container">
          <h-img-carousel
            ref="carousel"
            v-bind="imgCarouselCtor.$props"
            :data="$parent.data"
            :data-props="$parent.dataProps"
            :current-index.sync="actualIndex"
            :view-data.sync="viewData"
            @on-zoom="handleOnZoom"
            @on-prev="handleOnPrev"
            @on-next="handleOnNext"
            @on-change="handleCarouselOnChange"
          >
            <!-- 此处有坑，v-if无法控制slot显隐，固使用动态slot -->
            <template
              :slot="hasImgCarouselItem ? 'item' : null"
              slot-scope="scope"
            >
              <slot :item="scope.item" name="imgCarouselItem" />
            </template>
          </h-img-carousel>
        </div>
        <div class="h-img-preview__btn-group">
          <h-img-snippets-btn-group v-if="hasBtnGroup" :theme="snippetsTheme">
            <slot :item="item" name="btnGroup" />
          </h-img-snippets-btn-group>
        </div>
        <h-album
          v-if="$parent.showAlbum"
          ref="album"
          v-bind="albumCtor.$props"
          :data="$parent.data"
          :data-props="$parent.dataProps"
          :current-index.sync="actualIndex"
          class="h-img-preview__album"
        >
          <template :slot="hasAlbumItem ? 'item' : null" slot-scope="scope">
            <slot :item="scope.item" name="albumItem" />
          </template>
        </h-album>
        <div class="h-img-preview__close" @click="$close">
          <i class="h-icon-close_sm" />
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
import Vue from 'vue';
import { contains, popupManager, removeNode, merge } from '@hui-pro/utils';
// components
import ImgSnippetsBtnGroup from '@hui-pro/img-snippets/src/btn-group.vue';
import ImgCarousel from '@hui-pro/img-carousel/src/img-carousel.vue';
import Album from '@hui-pro/album/src/album.vue';

export default {
  components: {
    HImgSnippetsBtnGroup: ImgSnippetsBtnGroup,
    HImgCarousel: ImgCarousel,
    HAlbum: Album
  },
  data() {
    return {
      previewId: null,
      isShow: false,
      wrapperPadding: '',
      actualIndex: 0,
      item: {},
      transformOrigin: null,
      viewData: {}
    };
  },
  computed: {
    isDark() {
      return this.$parent.theme === 'dark';
    },
    isLight() {
      return this.$parent.theme === 'light';
    },
    albumRef() {
      return this.$refs.album;
    },
    carouselRef() {
      return this.$refs.carousel;
    },
    hasTop() {
      return !!(this.$parent.$slots.top || this.$parent.$scopedSlots.top);
    },
    hasBtnGroup() {
      return !!(
        this.$parent.$slots.btnGroup || this.$parent.$scopedSlots.btnGroup
      );
    },
    hasImgCarouselItem() {
      return !!(
        this.$parent.$slots.imgCarouselItem ||
        this.$parent.$scopedSlots.imgCarouselItem
      );
    },
    hasAlbumItem() {
      return !!(
        this.$parent.$slots.albumItem || this.$parent.$scopedSlots.albumItem
      );
    },
    snippetsTheme() {
      if (this.$parent.theme === 'light') {
        return 'light-gray';
      } else {
        return 'transparent';
      }
    }
  },
  watch: {
    '$parent.currentIndex'(val) {
      this.actualIndex = val;
      this.$emit('emit-proxy', 'current-index', val);
    },
    viewData(val) {
      this.$emit('emit-proxy', 'view-data', val);
    }
  },
  destroyed() {
    removeNode(this.$el);
    const id = `h-preview-modal--${this.$parent.theme}`;
    const $id = document.getElementById(id);
    if ($id) {
      removeNode($id);
    }
  },
  beforeMount() {
    this.previewId = `h-preview-${+new Date()}`;
    popupManager.register(this.previewId, this);
  },
  beforeDestroy() {
    popupManager.deregister(this.previewId);
    popupManager.closeModal(this.previewId);
  },
  created() {
    this.$update();
  },
  mounted() {
    this.actualIndex = this.$parent.currentIndex;
    this.item = this.$parent.data[this.actualIndex];
  },
  methods: {
    $update() {
      const ImgCarouselCtor = Vue.extend(ImgCarousel);
      const AlbumCtor = Vue.extend(Album);
      this.imgCarouselCtor = new ImgCarouselCtor({
        propsData: merge(
          {
            theme: this.$parent.theme === 'light' ? 'dark' : 'transparent',
            singleHideBtn: true
          },
          this.$parent.imgCarouselProps
        )
      });
      this.albumCtor = new AlbumCtor({
        propsData: merge(
          {
            theme: this.$parent.theme === 'light' ? 'light' : 'dark',
            alwaysCenter: true
          },
          this.$parent.albumProps
        )
      });
      this.$updateSlots();
    },
    $updateSlots() {
      this.$nextTick(() => {
        this.$slots = this.$parent.$slots;
        this.$scopedSlots = this.$parent.$scopedSlots;
        this.$forceUpdate();
      });
    },
    $open({ transformOrigin }) {
      this.transformOrigin = transformOrigin;
      this.isShow = true;
      const $el = this.$el;
      if (!contains(document.body, $el)) {
        document.body.appendChild($el);
      }
      popupManager.openModal({
        id: this.previewId,
        zIndex: 2000,
        modalClass: `h-img-preview--${this.$parent.theme}`,
        timeout: 350
      });
      if (!this.$parent.visible) {
        this.$emit('emit-proxy', 'on-open');
      }
    },
    $close() {
      this.isShow = false;
      popupManager.closeModal({
        id: this.previewId,
        timeout: 350
      });
      if (this.$parent.visible) {
        this.$emit('emit-proxy', 'on-close');
      }
    },
    afterEnter() {
      this.albumRef && this.albumRef.$resetVisible();
      this.$emit('emit-proxy', 'on-opened');
    },
    afterLeave() {
      if (this.$parent.autoReset) {
        this.$reset();
      }
      this.$emit('emit-proxy', 'on-closed');
    },
    handleOnPrev(item) {
      this.albumRef && this.albumRef.$prev();
    },
    handleOnNext(item) {
      this.albumRef && this.albumRef.$next();
    },
    handleCarouselOnChange(item, index) {
      this.item = item;
      this.$emit('emit-proxy', 'on-change', item, index);
    },
    handleOnZoom(opts) {
      this.$emit('emit-proxy', 'on-zoom', opts);
    },
    $prev() {
      this.carouselRef.$prev();
    },
    $next() {
      this.carouselRef.$next();
    },
    $selected(index) {
      this.carouselRef.$selected(index);
      this.albumRef && this.albumRef.$selected(index);
      this.$resetImgView();
    },
    $reset() {
      this.$nextTick(() => {
        this.actualIndex = this.$parent.currentIndex;
        this.carouselRef.$reset();
        this.albumRef && this.albumRef.$reset();
      });
    },
    $resetImgView() {
      this.carouselRef.$resetImgView();
    },
    $zoomOut() {
      this.carouselRef.$zoomOut();
    },
    $zoomIn() {
      this.carouselRef.$zoomIn();
    }
  }
};
</script>
