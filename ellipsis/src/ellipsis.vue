<script>
export default {
  name: 'HEllipsis',
  props: {
    tag: {
      type: String,
      default: 'div'
    },
    clazz: {
      type: [String, Object, Array],
      default: undefined
    },
    title: {
      type: String,
      default: ''
    },
    block: {
      type: Boolean,
      default: false
    },
    nonFull: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      labelTitle: ''
    };
  },
  methods: {
    /**
     * @desc 元素的mouseenter事件
     * @author chenguanbin
     * @param {Event} e 事件对象
     */
    hover(e) {
      const t = e.target;
      this.labelTitle =
        t.clientWidth < t.scrollWidth ? this.title || t.innerText : '';
      // 调用传入的 mouseenter 事件
      this.$listeners &&
        this.$listeners.mouseenter &&
        this.$listeners.mouseenter(e);
    },

    /**
     * @desc 格式化clazz参数
     * @author chenguanbin
     */
    parseClazz() {
      const clazz = this.clazz;
      if (!clazz) return '';
      // 字符串
      if (typeof clazz === 'string') return clazz;
      if (typeof clazz === 'object') {
        // 数组
        if (Array.isArray(clazz)) return clazz.join(' ');
        // 对象
        else {
          const arr = [];
          for (const key of Object.keys(clazz)) {
            clazz[key] && arr.push(key);
          }
          return arr.join(' ');
        }
      }
    }
  },
  render(h) {
    const cls = this.parseClazz() || '';
    return h(
      this.tag,
      {
        attrs: {
          class: `h-ellipsis ${cls}`,
          title: this.labelTitle
        },
        style: {
          display: this.block ? 'block' : '',
          width: this.nonFull ? 'auto' : '',
          maxWidth: this.nonFull ? '100%' : ''
        },
        on: Object.assign({}, this.$listeners, {
          mouseenter: this.hover
        })
      },
      this.$slots.default
    );
  }
};
</script>
