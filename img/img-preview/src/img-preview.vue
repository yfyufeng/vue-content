<script>
import Vue from 'vue';
import Dialog from './dialog.vue';
import ImgCarousel from '@hui-pro/img-carousel/src/img-carousel.vue';
import { isNull, merge, on, off, size } from '@hui-pro/utils';

export default {
  name: 'HImgPreview',
  props: {
    ...ImgCarousel.props,
    theme: {
      type: String,
      default: 'dark',
      validator(value) {
        return ['light', 'dark'].includes(value);
      }
    },
    showAlbum: {
      type: Boolean,
      default: false
    },
    autoReset: {
      type: Boolean,
      default: true
    },
    imgCarouselProps: {
      type: Object,
      default: () => {
        return {};
      }
    },
    albumProps: {
      type: Object,
      default: () => {
        return {};
      }
    },
    visible: {
      type: Boolean,
      default: false
    },
    /**
     * rewrite props
     */
    singleHideBtn: {
      type: Boolean,
      default: true
    }
  },
  data() {
    return {
      instance: null,
      transformOrigin: null,
      isShow: false
    };
  },
  watch: {
    visible(val) {
      if (val) {
        this.$open();
      } else {
        this.$close();
      }
    }
  },
  created() {
    this.props = merge(this.props, this.dataProps);
  },
  mounted() {
    if (!this.$isServer) {
      on(document.documentElement, 'mousedown', this.getMousePosition);
    }
  },
  destroyed() {
    if (!this.$isServer) {
      off(document.documentElement, 'mousedown', this.getMousePosition);
    }
    if (!isNull(this.instance)) {
      this.instance.$destroy();
    }
  },
  methods: {
    getMousePosition(e) {
      if (!this.isShow) {
        const winSize = size(window);
        const left = winSize.width < 1920 ? 0 : (winSize.width - 1920) / 2;
        const top = winSize.height < 1080 ? 0 : (winSize.height - 1080) / 2;
        this.transformOrigin = `${e.clientX - left}px ${e.clientY - top}px`;
      }
    },
    $open() {
      this.isShow = true;
      if (isNull(this.instance)) {
        const self = this;
        const DialogCtor = Vue.extend(
          Object.assign({}, Dialog, {
            beforeCreate() {
              this.$parent = self;
              this.$slots = this.$parent.$slots;
              this.$scopedSlots = this.$parent.$scopedSlots;
            }
          })
        );
        this.instance = new DialogCtor();
        this.instance.$mount();
        this.instance.$on('emit-proxy', function() {
          const name = arguments[0];
          const args = [...arguments].splice(1, arguments.length);
          switch (name) {
            case 'on-open':
              self.$emit('update:visible', true);
              break;
            case 'on-close':
              self.$emit('update:visible', false);
              break;
            case 'current-index':
              self.$emit('update:current-index', ...args);
              break;
            case 'view-data':
              self.$emit('update:view-data', ...args);
              break;
            default:
              self.$emit(...arguments);
              break;
          }
        });
      }
      this.instance.$open({
        transformOrigin: this.transformOrigin
      });
    },
    $close() {
      this.isShow = false;
      this.instance.$close();
    },
    $prev() {
      this.instance.$prev();
    },
    $next() {
      this.instance.$next();
    },
    $selected(index) {
      this.instance.$selected(index);
    },
    $reset() {
      this.instance.$reset();
    },
    $resetImgView() {
      this.instance.$resetImgView();
    },
    $zoomOut() {
      this.instance.$zoomOut();
    },
    $zoomIn() {
      this.instance.$zoomIn();
    },
    $update() {
      this.instance.$update();
    }
  },
  render() {
    return null;
  }
};
</script>
