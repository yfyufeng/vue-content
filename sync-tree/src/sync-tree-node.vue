<script>
export default {
  name: 'SyncTreeNode',
  props: {
    mode: {
      type: String,
      default: ''
    },
    node: {
      type: Object,
      default: null
    },
    data: {
      type: Object,
      default: null
    },
    store: {
      type: Object,
      default: null
    },
    vNodeTitle: {
      type: String,
      default: ''
    },
    vNodeKey: {
      type: String,
      default: ''
    },
    renderContent: {
      type: Function,
      default: null
    },
    hideNodeTitle: {
      type: Boolean,
      default: false
    },
    nodeName: {
      type: String,
      default: ''
    },
    treeSearch: {
      type: String,
      default: ''
    },
    keyHighlight: {
      type: Boolean,
      default: true
    }
  },
  methods: {
    highlightSearchWord(h, name) {
      if (this.treeSearch && this.mode === 'search' && this.keyHighlight) {
        // 支持大小写模糊搜索
        // specialCharts：特殊字符集合，这些字符不能直接塞进正则里，需要先转译
        const specialCharts = [
          '(',
          ')',
          "'",
          '\\',
          '$',
          '*',
          '+',
          '[',
          ']',
          '?',
          '^',
          '{',
          '}',
          '|',
          '.'
        ];
        let wordStr = '';
        for (let i = 0, len = this.treeSearch.length; i < len; i++) {
          if (specialCharts.includes(this.treeSearch[i])) {
            wordStr += '\\' + this.treeSearch[i];
          } else {
            wordStr += this.treeSearch[i];
          }
        }
        const wordReg = new RegExp(wordStr, 'ig');
        const keyWordArr = name.match(wordReg);
        return name.split(wordReg).reduce((all, item, index, arr) => {
          item && all.push(h('span', {}, item));
          if (index !== arr.length - 1) {
            all.push(
              h(
                'span',
                {
                  class: 'tree-high-light'
                },
                keyWordArr.shift()
              )
            );
          }
          return all;
        }, []);
      } else {
        return [h('span', {}, name)];
      }
    },
    append() {
      this.$emit('append', ...arguments);
    }
  },
  render(h) {
    const { node, data, store, vNodeTitle, vNodeKey, nodeName } = this;

    if (node.key.includes(vNodeKey)) {
      // 虚拟节点渲染
      return (
        <span
          class='load-more__btn'
          title={vNodeTitle}
          onClick={() =>
            this.append(node.parent.store, node.parent.data, data, node.parent)
          }
        >
          · · · · · ·
        </span>
      );
    } else {
      if (this.renderContent) {
        return this.renderContent(h, { node, data, store });
      } else {
        const attrs = this.hideNodeTitle ? {} : { title: data[nodeName] };
        // 正常节点渲染
        return h('span', { class: 'el-tree-node__label', attrs }, [
          ...this.highlightSearchWord(h, data[nodeName])
        ]);
      }
    }
  }
};
</script>
