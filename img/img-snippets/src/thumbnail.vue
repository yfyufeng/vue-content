<template>
  <h-img-view
    v-if="!original && show"
    v-bind="imgViewCtor.$props"
    :src="thumbSrc"
    :empty-size="emptySize"
    :style="wrapperStyle"
    class="h-img-snippets-thumbnail"
  >
    <slot v-if="$slots.default" />
  </h-img-view>
  <div
    v-else-if="original && show"
    ref="originalWrapper"
    :class="{
      [`h-img-view--bg-${bg}`]: true
    }"
    :style="wrapperStyle"
    class="h-img-snippets-thumbnail__original-wrapper"
  >
    <slot v-if="$slots.default" />
    <div v-if="!isError" :style="imgWrapperStyle">
      <img
        ref="originalImg"
        :src="imgUrl"
        :style="imgStyle"
        class="h-img-snippets-thumbnail__original-img"
        alt=""
        @load="onSuccess"
        @error="onError"
      />
    </div>
    <h-empty v-else :size="emptySize">
      <h-empty-error-image />
    </h-empty>
  </div>
</template>

<script>
import Vue from 'vue';
import ImgView from '@hui-pro/img-view/src/img-view.vue';
import {
  on,
  off,
  merge,
  isEmpty,
  isEqual,
  size,
  base64Url2blobUrl
} from '@hui-pro/utils';
import emptySvg from '@hui-pro/empty/src/assets/svg.common.js';

const { ErrorImage } = emptySvg;

export default {
  name: 'HImgSnippetsThumbnail',
  components: {
    HImgView: ImgView,
    HEmptyErrorImage: ErrorImage
  },
  props: {
    ...ImgView.props,
    imgUrl: {
      type: String,
      default: null
    },
    rect: {
      type: Object,
      default: null
    },
    rectProps: {
      type: Object,
      default: () => {
        return {};
      }
    },
    mode: {
      type: String,
      default: 'cover'
    },
    original: {
      type: Boolean,
      default: false
    },
    emptySize: {
      type: String,
      default: 'xs'
    },
    size: {
      type: Object,
      default: () => {
        return {
          width: 0,
          height: 0
        };
      }
    }
  },
  data() {
    return {
      props: {
        height: 'height',
        width: 'width',
        left: 'left',
        top: 'top'
      },
      thumbSrc: null,
      imgViewCtor: {},
      imgSize: {
        width: 0,
        height: 0
      },
      isError: false
    };
  },
  computed: {
    show() {
      return !isEmpty(this.rect);
    },
    wrapperStyle() {
      const { width, height } = this.size;
      if (width && height) {
        return {
          width: `${width}px`,
          height: `${height}px`
        };
      }
      return null;
    },
    imgWrapperStyle() {
      const { width, height } = this.size;
      let scale = 0;
      let areaSize = {
        width: 0,
        height: 0
      };
      const $wrapper = this.$refs.originalWrapper;
      if (width && height) {
        areaSize = this.size;
      } else if ($wrapper) {
        areaSize = size($wrapper);
      }
      const { width: imgWidth, height: imgHeight } = this.imgSize;
      const { width: areaWidth, height: areaHeight } = areaSize;
      const rectWidth = this.rect[this.props.width] || 0;
      const rectHeight = this.rect[this.props.height] || 0;
      if (imgHeight && rectHeight && areaHeight) {
        const whRatio = (imgWidth * rectWidth) / (imgHeight * rectHeight); // 图片宽高比
        const maxWhRatio = areaWidth / areaHeight;
        if (whRatio >= maxWhRatio) {
          scale = areaWidth ? areaWidth / (imgWidth * rectWidth) : 0;
        } else {
          scale = areaHeight ? areaHeight / (imgHeight * rectHeight) : 0;
        }
      }
      return {
        overflow: 'hidden',
        width: `${imgWidth * rectWidth}px`,
        height: `${imgHeight * rectHeight}px`,
        transform: `scale(${scale})`,
        flexShrink: 0,
        position: 'absolute',
        left: `${-(imgWidth * rectWidth - areaWidth) / 2}px`,
        top: `${-(imgHeight * rectHeight - areaHeight) / 2}px`
      };
    },
    imgStyle() {
      const { width, height } = this.imgSize;
      return {
        transform: `translate(${-width *
          (this.rect[this.props.left] || 0)}px,${-height *
          (this.rect[this.props.top] || 0)}px)`
      };
    }
  },
  watch: {
    imgUrl(newVal, oldVal) {
      if (newVal !== oldVal) {
        this.init();
      }
    },
    rect(newVal, oldVal) {
      if (!isEqual(newVal, oldVal)) {
        this.init();
      }
    }
  },
  created() {
    const ImgViewCtor = Vue.extend(ImgView);
    this.imgViewCtor = new ImgViewCtor({
      propsData: this.$props
    });
    this.props = merge(this.props, this.rectProps);
  },
  mounted() {
    this.init();
  },
  methods: {
    init() {
      if (!this.original && this.show) {
        const imgNode = new Image();
        imgNode.setAttribute('crossOrigin', 'Anonymous');
        on(imgNode, 'load', this.base64Success.bind(this, imgNode));
        on(imgNode, 'error', this.base64Error.bind(this, imgNode));
        imgNode.src = this.imgUrl;
      } else {
        this.thumbSrc = this.imgUrl;
      }
    },
    base64Success(imgNode) {
      const $canvas = document.createElement('canvas');
      $canvas.width = imgNode.width * this.rect[this.props.width];
      $canvas.height = imgNode.height * this.rect[this.props.height];
      const ctx = $canvas.getContext('2d');
      ctx.drawImage(
        imgNode,
        imgNode.width * this.rect[this.props.left],
        imgNode.height * this.rect[this.props.top],
        imgNode.width * this.rect[this.props.width],
        imgNode.height * this.rect[this.props.height],
        0,
        0,
        $canvas.width,
        $canvas.height
      );
      this.thumbSrc = base64Url2blobUrl($canvas.toDataURL('image/png'));
      off(imgNode, 'load', this.base64Success);
    },
    base64Error(imgNode) {
      off(imgNode, 'error', this.base64Error);
    },
    onSuccess() {
      if (this.$refs.originalImg) {
        const $img = this.$refs.originalImg;
        this.imgSize = {
          width: $img.naturalWidth,
          height: $img.naturalHeight
        };
      }
    },
    onError() {
      this.isError = true;
    }
  }
};
</script>
