<template>
  <div
    :title="title"
    :class="{
      [`h-img-view--bg-${bg}`]: true,
      [`h-img-view--${mode}`]: true
    }"
    class="h-img-view"
    @mousewheel="imgMousewheel"
  >
    <div
      v-if="isValidImg && !isError"
      ref="wrapper"
      :style="imgWrapperStyle"
      :class="{
        'is-move-transition': isMoveTransition,
        'is-drag': isDrag,
        'is-native': isUseNative
      }"
      class="h-img-view__wrapper"
      @mousedown="imgMousedown"
    >
      <img
        ref="img"
        :style="imgStyle"
        v-bind="$attrs"
        :src="internalSrc"
        class="h-img-view__img"
        v-on="$listeners"
        @load="onLoad"
        @error="onError"
      />
      <slot />
    </div>
    <template v-if="showDefault">
      <slot name="defaultPlaceholder">
        <h-empty :size="emptySize" class="h-img--placeholder">
          <h-empty-default-image />
        </h-empty>
      </slot>
    </template>
    <template v-else-if="showError">
      <slot name="errorPlaceholder">
        <h-empty :size="emptySize" class="h-img--placeholder">
          <h-empty-error-image />
        </h-empty>
      </slot>
    </template>
  </div>
</template>

<script>
import {
  isEmpty,
  on,
  off,
  size,
  offset,
  getPage,
  merge,
  isElement,
  isNumber,
  isUndefined,
  addClass,
  removeClass,
  isNull,
  base64Url2blobUrl
} from '@hui-pro/utils';
// components
import Empty from '@hui-pro/empty/src/empty.vue';
import emptySvg from '@hui-pro/empty/src/assets/svg.common.js';

const { DefaultImage, ErrorImage } = emptySvg;

export default {
  name: 'HImgView',
  components: {
    HEmpty: Empty,
    hEmptyDefaultImage: DefaultImage,
    hEmptyErrorImage: ErrorImage
  },
  props: {
    title: {
      type: String,
      default: null
    },
    mode: {
      type: String,
      default: 'adjust',
      validator(value) {
        return [
          'adjust',
          'fill',
          'cover',
          'contain',
          'none',
          'scale-down'
        ].includes(value);
      }
    },
    bg: {
      default: 'transparent',
      validator(value) {
        return ['white', 'gray', 'transparent'].includes(value);
      }
    },
    src: {
      type: String,
      default: null
    },
    radix: {
      type: Number,
      default: 0.2
    },
    max: {
      type: Number,
      default: 8
    },
    min: {
      type: Number,
      default: 0.1
    },
    cursor: {
      type: String,
      default: null
    },
    noTransition: {
      type: Boolean,
      default: false
    },
    lock: {
      type: Boolean,
      default: false
    },
    emptySize: {
      type: String,
      default: 'fit'
    },
    lazyload: {
      type: Boolean,
      default: false
    },
    resize: {
      type: Boolean,
      default: true
    },
    viewData: {
      type: Object,
      default: () => {
        return {
          scale: 1,
          ratio: 1,
          translateX: 0,
          translateY: 0
        };
      }
    }
  },
  data() {
    return {
      internalSrc: null,
      isSuccess: false,
      isError: false,
      isValidImg: false,
      isMoveTransition: false,
      isDrag: false,
      imgViewSize: {}, // 图片预览尺寸
      naturalSize: {}, // 图片原始尺寸
      wrapperSize: {}, // 图片外包裹尺寸
      dragRect: {}, // 拖拽范围矩形
      // 缩放拖拽数据
      eventData: {
        translateX: 0,
        translateY: 0,
        scale: 1,
        ratio: 1
      },
      // 缩放拖拽临时数据
      eventTempData: {
        translateX: 0,
        translateY: 0,
        x: 0,
        y: 0
      }
    };
  },
  computed: {
    imgWrapperStyle() {
      return {
        transform: `translate(${this.addPx(
          this.eventData.translateX
        )}, ${this.addPx(this.eventData.translateY)}) scale(${
          this.eventData.scale
        })`,
        cursor: this.cursor,
        width: this.isDone ? null : 0,
        height: this.isDone ? null : 0,
        overflow: this.isDone ? null : 'hidden'
      };
    },
    imgStyle() {
      if (this.isUseNative) {
        return {
          'object-fit': this.mode
        };
      } else {
        const { width, height } = this.imgViewSize;
        const style = {
          width: this.addPx(width),
          height: this.addPx(height)
        };
        return style;
      }
    },
    showDefault() {
      return (!this.isError && !this.isSuccess) || isNull(this.internalSrc);
    },
    showError() {
      return this.isError;
    },
    isDone() {
      return this.isSuccess || this.isError;
    },
    isUseNative() {
      if (this.$isServer) {
        return false;
      }
      const objectFit = ['fill', 'cover', 'contain', 'none', 'scale-down'];
      if (
        !isUndefined(document.documentElement.style.objectFit) &&
        isUndefined(this.$slots.default) &&
        objectFit.includes(this.mode)
      ) {
        return true;
      } else {
        return false;
      }
    }
  },
  watch: {
    src(val) {
      this.setUrl();
    },
    internalSrc: {
      deep: true,
      handler(val) {
        this.isError = false;
        this.isSuccess = false;
        this.$nextTick(() => {
          this.isValidImg = !isEmpty(this.internalSrc);
        });
      }
    },
    mode() {
      this.$resetView();
    },
    lazyload(val) {
      this.$emit('visible', !val);
    },
    viewData: {
      deep: true,
      handler(val) {
        this.isMoveTransition = !isUndefined(val.transition)
          ? val.transition
          : false;
        this.eventData.scale = val.scale;
        this.eventData.ratio = val.ratio;
        this.eventData.translateX = val.translateX;
        this.eventData.translateY = val.translateY;
      }
    },
    eventData: {
      deep: true,
      handler(val) {
        const viewData = {
          scale: val.scale,
          ratio: val.ratio,
          translateX: val.translateX,
          translateY: val.translateY
        };
        this.$emit('on-view-change', viewData);
      }
    }
  },
  created() {
    this.resetData();
  },
  mounted() {
    if (this.$isServer) {
      return;
    }
    if (isElement(this.$el)) {
      on(this.$el, 'resize', this.onResize);
    }
    this.$on('visible', show => {
      if (!this.isError) {
        if (show) {
          this.setUrl();
        } else {
          this.setUrl(null);
        }
      } else {
        this.onError(new Error('InValid Url'));
      }
    });
    this.$emit('visible', !this.lazyload);
  },
  beforeDestroyed() {
    if (isElement(this.$el)) {
      off(this.$el, 'resize', this.onResize);
    }
  },
  methods: {
    setUrl(url = this.src) {
      this.internalSrc = base64Url2blobUrl(url);
    },
    addPx(val) {
      if (isUndefined(val)) {
        return null;
      }
      return isNumber(val) ? `${val}px` : val;
    },
    onResize() {
      if (this.isSuccess && this.resize) {
        this.$resetView();
      }
    },
    onError(err) {
      if (this.$refs.img) {
        this.isError = true;
        this.$emit('on-error', err);
        this.$emit('mounted', this);
      }
    },
    onLoad() {
      if (this.$refs.img) {
        const { naturalWidth, naturalHeight } = this.$refs.img;
        this.naturalSize = {
          width: naturalWidth,
          height: naturalHeight
        };
        this.$resetView();
        this.isSuccess = true;
        if (!this.noTransition && this.$refs.wrapper) {
          on(this.$refs.wrapper, 'animationend', this.fadeEnd);
          addClass(this.$refs.wrapper, 'is-fade');
        }
        this.$emit('on-success', this.$refs.img);
      }
    },
    fadeEnd() {
      const $wrapper = this.$refs.wrapper;
      if ($wrapper) {
        removeClass($wrapper, 'is-fade');
        off($wrapper, 'animationend', this.fadeEnd);
      }
      this.$emit('mounted', this);
    },
    resetData() {
      merge(this.$data, this.$options.data(), {
        isError: this.src === ''
      });
      this.$emit('update:view-data', this.$getZoomData());
    },
    imgMousedown(e) {
      e.preventDefault();
      this.$emit('mousedown', e, this.img);
      if (this.mode === 'adjust' && !this.lock) {
        this.isMoveTransition = false;
        on(window, 'mousemove', this.winMousemove);
        on(document, 'mouseup', this.winMouseup);
        // 拖拽初始化，并标记位置
        if (this.$el) {
          this.dragRect = offset(this.$el);
        }
        this.eventTempData.x = e.clientX;
        this.eventTempData.y = e.clientY;
        this.eventTempData.translateX = this.eventData.translateX;
        this.eventTempData.translateY = this.eventData.translateY;
        this.isDrag = true;
      }
    },
    winMousemove(e) {
      e.preventDefault();
      e.stopPropagation();
      if (this.isDrag && !this.lock) {
        // 禁止超出拖拽范围
        if (
          this.dragRect.top > getPage(e).pageY ||
          this.dragRect.left > getPage(e).pageX ||
          this.dragRect.top + this.wrapperSize.height < getPage(e).pageY ||
          this.dragRect.left + this.wrapperSize.width < getPage(e).pageX
        ) {
          return;
        }
        const distanceX = e.clientX - this.eventTempData.x;
        const distanceY = e.clientY - this.eventTempData.y;
        this.eventData.translateX = this.eventTempData.translateX + distanceX;
        this.eventData.translateY = this.eventTempData.translateY + distanceY;
        this.$emit('update:view-data', this.$getZoomData());
      }
    },
    winMouseup() {
      this.isDrag = false;
      off(window, 'mousemove', this.winMousemove);
      off(document, 'mouseup', this.winMouseup);
    },
    imgMousewheel(e) {
      if (this.mode === 'adjust' && !this.lock && this.isSuccess) {
        e.preventDefault();
        this.isMoveTransition = false;
        const value = e.wheelDelta || -e.deltaY || -e.detail;
        const delta = Math.max(-1, Math.min(1, value));
        if (delta < 0) {
          this.$zoomOut(e);
        } else {
          this.$zoomIn(e);
        }
      }
    },
    zoom({ e, currentScale, type }) {
      let { ratio } = this.eventData;
      const { scale } = this.eventData;
      const { width, height } = this.imgViewSize;
      const { width: wWidth, height: wHeight } = this.wrapperSize;
      const naturalWidth = this.naturalSize.width;
      if (width && naturalWidth) {
        ratio = (currentScale * width) / naturalWidth;
      }
      currentScale = (ratio * naturalWidth) / width;
      if (currentScale < this.min) {
        currentScale = this.min;
      } else if (currentScale > this.max) {
        currentScale = this.max;
      }
      if (e) {
        const $img = this.$refs.wrapper;
        const { top: iTop, left: iLeft } = offset($img);
        const offsetWidth = width * (currentScale - scale);
        const offsetHeight = height * (currentScale - scale);
        const mouseTop = getPage(e).pageY - iTop;
        const mouseLeft = getPage(e).pageX - iLeft;
        const scaleX = ((width * scale) / 2 - mouseLeft) / (width * scale);
        const scaleY = ((height * scale) / 2 - mouseTop) / (height * scale);
        const translateX = this.eventData.translateX + offsetWidth * scaleX;
        const translateY = this.eventData.translateY + offsetHeight * scaleY;
        const offsetX =
          (wWidth - width * currentScale) / 2 + width * currentScale;
        const offsetY =
          (wHeight - height * currentScale) / 2 + height * currentScale;
        if (
          (-translateX > offsetX ||
            translateX > offsetX ||
            -translateY > offsetY ||
            translateY > offsetY) &&
          type === 'zoomIn'
        ) {
          return;
        }
        this.eventData.translateX = translateX;
        this.eventData.translateY = translateY;
      }
      this.eventData.scale = currentScale;
      this.eventData.ratio = ratio;
      this.$emit('on-zoom', this.$getZoomData());
      this.$emit('update:view-data', this.$getZoomData());
    },
    $getZoomData(defaultVal) {
      const viewData = {
        scale: defaultVal ? 1 : this.eventData.scale,
        ratio: defaultVal ? 1 : this.eventData.ratio,
        translateX: defaultVal ? 0 : this.eventData.translateX,
        translateY: defaultVal ? 0 : this.eventData.translateY,
        transition: false
      };
      return viewData;
    },
    $resetView(original = false) {
      this.eventData = this.$options.data().eventData;
      if (!this.isUseNative) {
        const $imgView = this.$el;
        if ($imgView) {
          this.wrapperSize = size($imgView);
          const { width, height } = this.naturalSize;
          const { width: elWidth, height: elHeight } = this.wrapperSize;
          const whRatio = width / height; // 图片原始宽高比
          const elWhRatio = elWidth / elHeight; // 最大区域宽高比
          const getContainSize = () => {
            let containSize;
            if (width > elWidth) {
              containSize = {
                width: elWidth,
                height: height * (elWidth / width)
              };
            } else if (height > elHeight) {
              containSize = {
                width: width * (elHeight / height),
                height: elHeight
              };
            } else {
              if (width > height) {
                containSize = {
                  width: elWidth,
                  height: height * (elWidth / width)
                };
              } else {
                containSize = {
                  width: width * (elHeight / height),
                  height: elHeight
                };
              }
            }
            return containSize;
          };
          switch (this.mode) {
            case 'cover':
              if (whRatio > 1) {
                this.imgViewSize = {
                  height: elHeight
                };
              } else {
                this.imgViewSize = {
                  width: elWidth
                };
              }
              break;
            case 'adjust':
              if (whRatio >= elWhRatio) {
                if (width > elWidth) {
                  this.imgViewSize = {
                    width: elWidth,
                    height: height * (elWidth / width)
                  };
                } else {
                  this.imgViewSize = {
                    width: width,
                    height: height
                  };
                }
              } else {
                if (height > elHeight) {
                  this.imgViewSize = {
                    width: width * (elHeight / height),
                    height: elHeight
                  };
                } else {
                  this.imgViewSize = {
                    width: width,
                    height: height
                  };
                }
              }
              break;
            case 'contain':
              this.imgViewSize = getContainSize();
              break;
            case 'scale-down': {
              const containSize = getContainSize();
              const isNaturalBig = width > containSize.width;
              if (isNaturalBig) {
                this.imgViewSize = containSize;
              } else {
                this.imgViewSize = {
                  width: width,
                  height: height
                };
              }
              break;
            }
            default:
              this.imgViewSize = {};
              break;
          }
          // fill none use css control
          if (original) {
            this.eventData.scale = width / this.imgViewSize.width;
            this.eventData.ratio = 1;
          } else {
            const viewWidth = this.imgViewSize.width;
            const naturalWidth = width;
            if (viewWidth && naturalWidth) {
              this.eventData.scale = 1;
              this.eventData.ratio = viewWidth / naturalWidth;
            }
          }
          this.eventData.translateX = 0;
          this.eventData.translateY = 0;
        }
      }
      this.$emit('update:view-data', this.$getZoomData());
    },
    $reset() {
      this.resetData();
      this.$emit('visible', true);
    },
    // 缩小
    $zoomOut(e) {
      if (this.mode !== 'adjust' || this.isError) {
        return;
      }
      if (!this.lock) {
        this.zoom({
          e,
          currentScale: this.eventData.scale * (1 - this.radix),
          type: 'zoomOut'
        });
      }
    },
    // 放大
    $zoomIn(e) {
      if (this.mode !== 'adjust' || this.isError) {
        return;
      }
      if (!this.lock) {
        this.zoom({
          e,
          currentScale: this.eventData.scale * (1 + this.radix),
          type: 'zoomIn'
        });
      }
    }
  }
};
</script>
