<template>
  <div class="sync-tree-container">
    <div class="sync-tree-search">
      <!-- 搜索框 -->
      <el-input
        v-model="treeSearch"
        :placeholder="searchInputText"
        :clear-icon-click="clearSearchTreeAction"
        clearable
        @keyup.enter.native="delSearchTreeAction"
      >
        <i
          slot="suffix"
          class="el-input__icon h-icon-search"
          @click="searchTreeAction"
        />
      </el-input>
    </div>
    <div v-loading="loading" class="sync-tree-main">
      <!-- 展开时，数据量超过1000 -->
      <div
        v-show="count > nodeLimit && mode === 'init'"
        style="margin-bottom: 8px"
      >
        <el-alert
          :title="nodeLimitAlert"
          :closable="false"
          type="warning"
          simple
        ></el-alert>
      </div>
      <!-- 搜索时，数据量超过500 -->
      <div
        v-show="searchCount >= searchLimit && mode === 'search'"
        style="margin-bottom: 8px"
      >
        <el-alert
          :title="searchLimitAlert"
          :closable="false"
          type="warning"
          simple
        ></el-alert>
      </div>
      <div
        :class="{
          'show-tips':
            (count > nodeLimit && mode === 'init') ||
            (searchCount >= searchLimit && mode === 'search')
        }"
        class="sync-tree-content"
      >
        <el-tree
          v-if="toggleTree"
          ref="tree"
          :data="data"
          :before-click="beforeNodeClick"
          :before-drag="beforeDrag"
          :before-drop="beforeDrop"
          :current-node-key="currentNode"
          :node-key="nodeKey"
          :parent-key="parentKey"
          :show-checkbox="showCheckbox"
          :highlight-current="highlightCurrent"
          :move="move"
          :check-strictly="true"
          :load="asyncLoadData"
          :render-content="renderTreeContent"
          :default-expanded-keys="expandNodes"
          :expand-on-click-node="expandOnClickNode"
          :props="map"
          simple-data
          lazy
          move-area="outter"
          @check-change="checkChange"
          @check="(data, status) => $emit('check', data, status)"
          @current-change="(data, node) => $emit('current-change', data, node)"
          @node-click="(data, node, el) => $emit('node-click', data, node, el)"
          @node-expand="
            (data, node, el) => $emit('node-expand', data, node, el)
          "
          @node-collapse="nodeCollapse"
          @node-drag="
            (event, data, node, el) => $emit('node-drag', event, data, node, el)
          "
          @node-drop="
            (event, data, node, targetNode, position, el) =>
              $emit('node-drop', event, data, node, targetNode, position, el)
          "
          @node-drag-move="
            (event, data, node, tree) =>
              $emit('node-drag-move', event, data, node, tree)
          "
        ></el-tree>
      </div>
    </div>
  </div>
</template>

<script>
/**
 * @author xuzilong
 * @date 2018-04-13 16:34:12
 * @desc 异步树组件
 *
 * @注意
 * HUI Pro中的异步树组件是从common中迁移过来的，可能与2019年内弃用，请慎重使用（届时会有新的树渲染优化方案）
 */
export default {
  name: 'SyncTree',
  props: {
    map: {
      // 配置选项的映射关系，和HUI-tree组件相同
      type: Object,
      default: function() {
        return {
          children: 'children',
          label: 'name',
          isLeaf: 'leaf',
          icon: 'iconSkin',
          disabled: 'chkDisabled',
          selectable: 'selectable'
        };
      }
    },
    type: {
      // 异步树类型： async - 异步（后台每次返回一层数据）； sync - 同步（后台一次返回所有数据）；mixed - 混合（后台返回的数据中，可能存在多层）
      type: String,
      default: 'async'
    },
    nodeKey: {
      // tree上的node-key
      type: String,
      default: 'id'
    },
    parentKey: {
      // tree上的parent-key
      type: String,
      default: 'pId'
    },
    pageSize: {
      // 每页的分页数据
      type: Number,
      default: 100
    },
    setTreeData: {
      // 设置树节点数据（return一个promise对象）
      type: Function,
      default: function() {
        return new Promise(resolve => {
          resolve([]);
        });
      }
    },
    setSearchData: {
      // 设置搜索时树节点数据（return一个promise对象）
      type: Function,
      default: null
    },
    currentNodeKey: {
      // 默认选中的节点的key
      type: String,
      default: ''
    },
    nodeLimit: {
      // 展示节点的数量限制
      type: Number,
      default: 1000
    },
    nodeLimitAlert: {
      // 展示节点数量限制上限的提示
      type: String,
      default: '当前查看数据量较大，流畅度会有所下降，建议使用搜索。'
    },
    searchInputText: {
      // 搜索框中placeholder的提示
      type: String,
      default: '搜索'
    },
    searchLimit: {
      // 搜索节点的数量限制
      type: Number,
      default: 500
    },
    searchLimitAlert: {
      // 搜索节点数量限制上限的提示
      type: String,
      default: '搜索结果过多，仅展示前500条，建议缩小搜索范围。'
    },
    beforeClick: {
      // 点击前的回调
      type: Function,
      default: null
    },
    beforeSearch: {
      // 点击搜索之前回调
      type: Function,
      default: null
    },
    afterSearch: {
      // 点击搜索之后回调
      type: Function,
      default: null
    },
    vNodeTitle: {
      // 虚拟节点的title文字
      type: String,
      default: '更多'
    },
    keyHighlight: {
      // 是否开启节点高亮
      type: Boolean,
      default: true
    },
    showCheckbox: {
      // 是否展示选择框
      type: Boolean,
      default: false
    },
    checkStrictly: {
      // 是否父子不联动
      type: Boolean,
      default: false
    },
    hideNodeTitle: {
      // 不显示节点上的title
      type: Boolean,
      default: false
    },
    autoLoad: {
      // 是否初始化的时候自动加载树
      type: Boolean,
      default: true
    },
    loading: {
      // 是否处于加载状态
      type: Boolean,
      default: false
    },
    expandOnClickNode: {
      // 是否在点击节点的时候展开或者收缩节点
      type: Boolean,
      default: false
    },
    // collapseRemoveNodes属性存在勾选混乱的bug，暂时不推荐使用
    collapseRemoveNodes: {
      // 是否收起的时候移除节点下的所有子节点
      type: Boolean,
      default: false
    },
    defaultSelectCurrent: {
      // 是否默认选中节点（不传current-node-key将默认选中根节点）
      type: Boolean,
      default: true
    },
    highlightCurrent: {
      // 是否高亮当前选中节点，默认值是 true。
      type: Boolean,
      default: true
    },
    linkedExpandKey: {
      // 联动展开的key（展开其上级所有父级节点，必须在type=mixed混合类型下生效）
      type: String,
      default: ''
    },
    renderContent: {
      type: Function,
      default: null
    },
    move: {
      type: Boolean,
      default: false
    },
    beforeDrag: {
      type: Function,
      default: null
    },
    beforeDrop: {
      type: Function,
      default: null
    },
    hasOriginalChecked: {
      // 是否含有初始化勾选的节点（data中有数据的checked为true）（为了优化性能）
      type: Boolean,
      default: true
    }
  },
  data() {
    return {
      currentNode: '',
      wholeData: [], // 完整的数据（应用树的时候会用到）
      data: [], // 传入树组件的节点
      expandNodes: [], // 展开的节点
      count: 0, // 树节点的总量计算
      searchCount: 0, // 搜索时，树节点的总量计算
      treeSearch: '', // 搜索关键字
      mode: 'init', // 当前模式  init：初始化模式；  search：搜索模式
      checkedData: [],
      cacheData: [],
      disabledData: [],
      toggleTree: true,
      initChecked: [] // 初始化被勾选的节点
    };
  },
  computed: {
    nodeName() {
      return this.map.label || 'name';
    }
  },
  mounted() {
    if (!this.autoLoad) return;
    this.initialize();
  },
  methods: {
    async initialize() {
      await this.loadRootTree();
      const currentObj =
        this.data.find(item => item[this.nodeKey] === this.currentNode) ||
        this.data[0] ||
        {};
      // 不加nextTick在IE下会拿不到node
      this.$nextTick(() => {
        const node = this.$refs.tree.getNode(currentObj);
        this.$emit('init-select', currentObj, node);
      });
    },
    loadRootTree() {
      return new Promise(async resolve => {
        const [nodeKey, parentKey] = [this.nodeKey, this.parentKey];
        // 初始化获取页面数据
        const listData = await this.setTreeData({
          pageNo: 1,
          pageSize: this.pageSize,
          parentId: null
        });
        // 兼容以前同步的版本（list格式的版本）
        this.wholeData = Array.isArray(listData) ? listData : listData.rows;
        for (const item of this.wholeData) {
          // handlerCheck 用于获取节点时的性能优化，减少数据遍历。只有在勾选时的，如果操作的是叶子节点，那么就会设置
          item.handlerCheck = false;
          // linkchecked 用于初始化有节点被勾选时，联动去掉默认的checked时用的。这样让数据带上这个标记，就不会每次操作勾选都会进入递归遍历
          item.linkchecked = false;
          item.expanded = !!item.leaf;
          if (typeof item.chkDisabled === 'undefined') {
            item.chkDisabled = false;
          }
          if (
            this.disabledData.map(item => item[nodeKey]).includes(item[nodeKey])
          ) {
            item.checked = false;
          }
        }

        if (this.type === 'mixed') {
          this.cacheData = [];
          this.cacheData.push(...this.wholeData);

          this.data = this.wholeData;
          if (this.linkedExpandKey) {
            const targetNode = this.cacheData.find(
              item => item[nodeKey] === this.linkedExpandKey
            );
            this._setParentsProperty(this.cacheData, targetNode, 'open', true);
          }
        } else {
          this.data = this.wholeData.filter(
            node =>
              !node[parentKey] ||
              node[parentKey] === '0' ||
              node[parentKey] === '-1'
          );
        }

        // 获取初始化展开的节点
        this.expandNodes = this.data
          .filter(node => node.open)
          .map(node => node[nodeKey]);
        // 设置初始化选中的节点
        this.currentNode = this.defaultSelectCurrent
          ? this.currentNodeKey || (this.data[0] && this.data[0][nodeKey])
          : '';
        this.initChecked = this.data.filter(node => node.checked);
        this.checkedData.push(...this.initChecked);
        this.setCheckedKeys(
          this.data
            .filter(item => item.checked && !item.chkDisabled)
            .map(item => item[this.nodeKey])
        );
        // 插入虚拟节点
        if (!Array.isArray(listData) && !listData.lastPage) {
          this.data.push(this._createVNode('root'));
        }
        // 累加[展开节点]计数
        this.count = this.data.length;
        resolve();
      });
    },
    async asyncLoadData(treeNode, resolve) {
      const [nodeKey, parentKey] = [this.nodeKey, this.parentKey];
      let [res] = [this.nodeKey, this.parentKey];
      // 首次进入时，会加载一般父节点为undefined的情况
      const parentId = treeNode.data[nodeKey];
      if (!parentId) return resolve([]);

      const pageSize = treeNode.data.loadAll ? 99999 : this.pageSize;
      if (this.showCheckbox) {
        res = this._filterPageData(1, pageSize, parentId);
      } else {
        res = await this.setTreeData({
          pageNo: 1,
          pageSize,
          parentId: parentId
        });
        // 格式化数据，让它能够兼容同步树的版本
        res = Array.isArray(res) ? { rows: res, lastPage: true } : res;
      }

      let nextNodes = [];
      nextNodes.push(...res.rows);

      const checkedData = res.rows.filter(
        item => item.checked && !item.chkDisabled
      );
      this.initChecked.push(...checkedData);
      this.checkedData.push(...checkedData);
      this.checkedData = [...new Set(this.checkedData)];

      if (this.type === 'mixed') {
        const cacheChildren = this.cacheData.filter(
          item => item[parentKey] === parentId
        );
        nextNodes.push(...cacheChildren);
        // 去重
        nextNodes = [...new Set(nextNodes)];
        this.cacheData.push(...res.rows);
        if (this.linkedExpandKey) {
          const targetNode = this.cacheData.find(
            item => item[nodeKey] === this.linkedExpandKey
          );
          this._setParentsProperty(this.cacheData, targetNode, 'open', true);
        }
      }

      // 插入虚拟节点
      if (!res.lastPage) {
        nextNodes.push(this._createVNode(parentId));
      } else {
        treeNode.data.expanded = true;
      }

      const gapTime = nextNodes.length / 60;
      // 设置延迟，有一个等待展开的动画效果
      setTimeout(() => {
        // 累加子节点数
        const includeInitChecked = this.initChecked.find(
          item => item[nodeKey] === parentId
        );
        // 这里的逻辑比较复杂，简单来说，想要在加载的时候就获取勾选需要满足4个条件
        // 1） 父节点被勾选
        // 2） 非不联动模式
        // 3） 不包含在被初始化勾选的节点列表中 （如果操作过该节点，节点会从initChecked列表中被删除）
        // 4） 子节点非禁用
        if (
          this.checkedData.find(item => item[nodeKey] === parentId) &&
          !this.checkStrictly &&
          !includeInitChecked
        ) {
          this.checkedData.push(...res.rows.filter(item => !item.chkDisabled));
        }
        if (treeNode.data.checked) {
          const _node = this.checkedData.find(
            item => item[nodeKey] === parentId
          );
          if (_node) {
            _node.handlerCheck = true;
          }
        }
        resolve(nextNodes);
        setTimeout(() => {
          const treeStore = this.$refs.tree;
          const openNodes = nextNodes.filter(item => item.open);
          for (const item of openNodes) {
            treeStore.getNode(item).expand();
          }
        }, 500);
        this.setCheckedKeys(this.checkedData.map(item => item[nodeKey]));
      }, gapTime);
    },
    /**
     * @author: xuzilong
     * @date: 2018-04-04 14:19:26
     * @desc: 重新树节点内容
     */
    renderTreeContent(h, { node, data, store }) {
      if (node.key.indexOf('$loadmore') !== -1) {
        // 虚拟节点渲染
        return (
          <span
            class='load-more__btn'
            title={this.vNodeTitle}
            onClick={() =>
              this.append(
                node.parent.store,
                node.parent.data,
                data,
                node.parent
              )
            }
          >
            · · · · · ·
          </span>
        );
      } else {
        if (this.renderContent) {
          return this.renderContent(h, { node, data, store });
        } else {
          const attrs = this.hideNodeTitle
            ? {}
            : { title: data[this.nodeName] };
          // 正常节点渲染
          return h('span', { class: 'el-tree-node__label', attrs: attrs }, [
            ...this.highlightSearchWord(h, data[this.nodeName])
          ]);
        }
      }
    },
    /**
     * @author: xuzilong
     * @date: 2018-04-16 09:38:05
     * @desc: 关键字高亮逻辑
     */
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
    /**
     * @author: xuzilong
     * @date: 2018-04-04 14:19:16
     * @desc: 插入异步节点的函数
     * @param: store 节点的store
     * @param: parentData 父节点的数据
     * @param: vData 虚拟节点的数据
     */
    async append(store, parentData, vData) {
      let [res] = [this.nodeKey];
      const [nodeKey] = [this.nodeKey];
      const pageNo = vData.pageNo + 1;
      if (this.showCheckbox) {
        res = this._filterPageData(pageNo, this.pageSize, parentData[nodeKey]);
      } else {
        res = await this.setTreeData({
          pageSize: this.pageSize,
          pageNo,
          parentId: parentData[nodeKey]
        });
        res = Array.isArray(res) ? { rows: res, lastPage: true } : res;
      }
      this.count += res.rows.length;

      if (this.type === 'mixed') {
        this.cacheData.push(...res.rows);
      }

      // 遍历插入新获取的节点
      for (const value of res.rows) {
        store.append(value, parentData);
      }

      // 移除本次操作的虚拟节点
      store.remove(vData);
      // 不为最后一页（还有节点），插入新的虚拟节点
      if (!res.lastPage) {
        store.append(
          this._createVNode(parentData[nodeKey], pageNo),
          parentData
        );
      }

      // // 设置节点的勾选状态
      if (this.showCheckbox) {
        var isParentChecked = this.$refs.tree
          .getCheckedNodes()
          .find(item => item[nodeKey] === parentData[nodeKey]);
      }
      this.$nextTick(() => {
        if (isParentChecked && !this.checkStrictly) {
          this.checkedData.push(...res.rows);
        }
        this.setCheckedKeys(this.checkedData.map(item => item[nodeKey]));
      });
    },

    checkChange(data, isChecked, child) {
      const nodeKey = this.nodeKey;
      this.$emit('check-change', data, isChecked, child);

      const includeData = this.checkedData.find(
        item => item[nodeKey] === data[nodeKey]
      );
      if ((includeData && isChecked) || (!includeData && !isChecked)) return;

      if (this.checkStrictly) {
        this._handlerCheckedData(data, isChecked);
        data.handlerCheck = isChecked;
        return;
      }
      const node = this.$refs.tree.getNode(data);
      this._handlerCheckedData(data, isChecked);
      this._handlerInitCheckedData(data);
      const childNodes = node.childNodes.filter(
        item => item.data[nodeKey].indexOf('$loadmore') === -1
      );

      // 在手动操作的节点上给tag，方便在getAllChecked时优化数据
      // 无论当前节点是否勾选，只要我操作过，并且操作的是叶子节点，就把handlerCheck置为true
      // data.handlerCheck = data.leaf
      data.handlerCheck = true;
      if (!data.linkchecked && this.hasOriginalChecked) {
        this._setChildrenProperty(this.wholeData, data, 'checked', false);
      }

      for (const cNode of childNodes) {
        // if (cNode.data.chkDisabled) continue;
        this._recordChildNodesByParent(cNode, isChecked);
      }
      this.setCheckedKeys(this.checkedData.map(item => item[nodeKey]));
    },
    _recordChildNodesByParent(parentNode, isChecked) {
      this._handlerCheckedData(parentNode.data, isChecked);
      for (const node of parentNode.childNodes.filter(
        item => item.data[this.nodeKey].indexOf('$loadmore') === -1
      )) {
        // if (node.data.chkDisabled) continue;
        this._recordChildNodesByParent(node, isChecked);
      }
    },
    _handlerCheckedData(data, isChecked) {
      if (isChecked) {
        if (
          !this.checkedData.find(
            item => item[this.nodeKey] === data[this.nodeKey]
          ) &&
          data[this.nodeKey].indexOf('$loadmore') === -1 &&
          data.chkDisabled === false
        ) {
          this.checkedData.push(data);
        }
      } else {
        const index = this.checkedData.findIndex(
          item => item[this.nodeKey] === data[this.nodeKey]
        );
        if (index >= 0) {
          this.checkedData.splice(index, 1);
        }
      }
    },
    _handlerInitCheckedData(data) {
      const index = this.initChecked.findIndex(
        item => item[this.nodeKey] === data[this.nodeKey]
      );
      if (index > -1) {
        this.initChecked.splice(index, 1);
      }
    },

    /**
     * @author: xuzilong
     * @date: 2018-04-21 14:44:45
     * @desc: 收起事件
     * @desc: 在展示模式下，每次收起的时候，需要回收被收起的节点。下载展开会重新进行子节点加载
     * @desc: TODO: 由于勾选树的扩展，如果每次收起回收节点，很难处理勾选的缓存和状态，所以这个属性目前只支持单选
     */
    nodeCollapse(data, node, el) {
      if (this.mode === 'init' && this.collapseRemoveNodes) {
        node.loaded = false;
        setTimeout(() => {
          node.childNodes = [];
          this.$emit('node-collapse', data, node, el);
        }, 300);
      } else {
        this.$emit('node-collapse', data, node, el);
      }
    },
    beforeNodeClick(data, node) {
      const callback = this.beforeClick ? this.beforeClick(data, node) : true;
      return callback && data[this.nodeKey].indexOf('$loadmore') === -1;
    },

    /**
     * @author: xuzilong
     * @date: 2018-05-17 19:23:42
     * @desc: 创建虚拟节点
     */
    _createVNode(idStr, pageNo = 1, leaf = true) {
      return {
        [this.nodeKey]: idStr + '$loadmore',
        pageNo,
        leaf
      };
    },
    /**
     * @author: xuzilong
     * @date: 2018-04-19 16:48:16
     * @desc: （前端）分页获取数据
     */
    _filterPageData(pageNo, pageSize = this.pageSize, pId = null) {
      const nodes = this.wholeData.filter(node => node[this.parentKey] === pId);
      const sliceLength = Math.min(nodes.length, pageNo * pageSize);
      const lastPage = nodes.length <= pageNo * pageSize;
      return {
        lastPage,
        rows: nodes.slice((pageNo - 1) * pageSize, sliceLength)
      };
    },
    /**
     * @author: xuzilong
     * @date: 2018-05-14 17:05:24
     * @desc: 调整父级节点属性（递归设置）
     * @param: list:整个数据；data:目标节点；key:要设置的属性名；value:要设置的值
     */
    _setParentsProperty(list, data, key, value) {
      const parentData = list.find(
        item => item[this.nodeKey] === data[this.parentKey]
      );
      if (parentData[key] === value) return;

      if (parentData) {
        parentData[key] = value;
        this._setParentsProperty(list, parentData, key, value);
      }
    },
    /**
     * @author: xuzilong
     * @date: 2018-05-26 13:22:36
     * @desc: 调整子级节点属性（递归设置）
     */
    _setChildrenProperty(list, data, key, value) {
      data[key] = value;
      data['link' + key] = true;
      const children = list.filter(
        item => item[this.parentKey] === data[this.nodeKey]
      );
      for (const d of children) {
        d[key] = value;
        d['link' + key] = true;
        this._handlerInitCheckedData(d);
        if (!d.leaf) {
          this._setChildrenProperty(list, d, key, value);
        }
      }
    },

    clearSearchTreeAction() {
      this.treeSearch = '';
      this.toggleTree = false;
      this.$nextTick(() => {
        this.toggleTree = true;
        this.$nextTick(() => {
          this.searchTreeAction();
        });
      });
    },
    delSearchTreeAction() {
      const treeSearch = this.treeSearch.trim() === '' ? '' : this.treeSearch;
      if (treeSearch) {
        this.searchTreeAction();
      } else {
        this.toggleTree = false;
        this.$nextTick(() => {
          this.toggleTree = true;
          this.$nextTick(() => {
            this.searchTreeAction();
          });
        });
      }
    },
    async searchTreeAction() {
      // 搜索前的回调
      if (this.beforeSearch && this.beforeSearch()) return;
      const [nodeKey, parentKey] = [this.nodeKey, this.parentKey];
      this.treeSearch = this.treeSearch.trim() === '' ? '' : this.treeSearch;
      // 切换树的懒加载和非懒加载模式
      this.$refs.tree.$data.store.lazy = !this.treeSearch;
      this.mode = this.treeSearch ? 'search' : 'init';
      if (this.treeSearch) {
        let _setSearchData = this.setSearchData
          ? await this.setSearchData(this.treeSearch)
          : await this.setTreeData({ keyWord: this.treeSearch });
        _setSearchData = Array.isArray(_setSearchData)
          ? _setSearchData
          : _setSearchData.rows;
        this.wholeData = this.data = _setSearchData;
        this.expandNodes = _setSearchData.map(node => node[nodeKey]);
        this.searchCount = _setSearchData.length;
        this.checkedData = this.data.filter(item => item.checked);
        this.setCheckedKeys(this.checkedData.map(item => item[nodeKey]));
        for (const item of this.wholeData) {
          item.handlerCheck = false;
          item.expanded = true;
        }
        const keyList = this.disabledData.map(item => item[nodeKey]);
        this.pullNodes(keyList);
        const currentObj =
          this.data.filter(
            node =>
              !node[parentKey] ||
              node[parentKey] === '0' ||
              node[parentKey] === '-1'
          )[0] ||
          this.data[0] ||
          {};
        this.$nextTick(() => {
          const node = this.$refs.tree.getNode(currentObj);
          this.$emit('init-select', currentObj, node);
          // 搜索后的回调
          this.afterSearch && this.afterSearch();
        });
      } else {
        this.checkedData = [];
        await this.loadRootTree();
        const keyList = this.disabledData.map(item => item[nodeKey]);
        this.pullNodes(keyList);
        const currentObj =
          this.data.filter(
            node =>
              !node[parentKey] ||
              node[parentKey] === '0' ||
              node[parentKey] === '-1'
          )[0] ||
          this.data[0] ||
          {};
        this.$nextTick(() => {
          const node = this.$refs.tree.getNode(currentObj);
          this.$emit('init-select', currentObj, node);
          // 搜索后的回调
          this.afterSearch && this.afterSearch();
        });
      }
    },

    refresh(callback) {
      this.mode = 'init';
      this.treeSearch = '';
      this.wholeData = [];
      this.data = [];
      this.expandNodes = [];
      this.checkedData = [];
      this.disabledData = [];
      this.cacheData = [];
      this.$refs.tree.$data.store.lazy = true;
      this.setCheckedKeys([]);
      this.initialize();
      this.$nextTick(() => {
        callback && callback();
      });
    },
    getAllChecked() {
      const keyStr = this.nodeKey;
      let checkedList = [];

      // 对是否含有初始化勾选节点做了一层判断处理
      // 之前一次性能优化，统一改为else，但是后来发现else的处理逻辑对初始化勾选的点存在问题
      // 那么为了应急处理，就做了分支判断
      if (this.hasOriginalChecked) {
        checkedList.push(...this.checkedData.filter(item => !item.chkDisabled));
        const getNodesByParent = id => {
          for (const node of this.wholeData.filter(
            item =>
              item[this.parentKey] === id &&
              !item.handlerCheck &&
              !item.chkDisabled
          )) {
            checkedList.push(node);
            if (!node.leaf) {
              getNodesByParent(node[keyStr]);
            }
          }
        };

        if (!this.checkStrictly) {
          for (const node of this.checkedData.filter(item => !item.expanded)) {
            // getNodesByParent(node[keyStr])
            const includeInitChecked = this.initChecked.find(
              item => item[keyStr] === node[keyStr]
            );
            if (!includeInitChecked) {
              getNodesByParent(node[keyStr]);
            }
          }
        }
      } else {
        checkedList = this.checkedData.filter(item => !item.chkDisabled);
        const checkedIdSet = new Set(checkedList.map(item => item[keyStr]));
        // 如果父子联动，加入已选父的子节的
        if (!this.checkStrictly) {
          // 调整获取节点逻辑 edited by zhubincong
          let beforeSize;
          let afterSize;
          do {
            beforeSize = checkedIdSet.size;
            for (const node of this.wholeData) {
              if (
                checkedIdSet.has(node[this.parentKey]) &&
                !checkedIdSet.has(node[keyStr]) &&
                !node.handlerCheck &&
                !node.chkDisabled
              ) {
                checkedList.push(node);
                checkedIdSet.add(node[keyStr]);
              }
            }
            afterSize = checkedIdSet.size;
          } while (beforeSize !== afterSize);
        }
      }

      // 这种操作为为了照顾初始化被选中，但是又没有被加载到页面上的节点（逻辑太特么绕了）
      const initCheckedData = this.wholeData.filter(
        item => item.checked && !item.chkDisabled
      );
      checkedList.push(...initCheckedData);

      const list = [...new Set(checkedList)];
      return list;
    },
    /**
     * @author: xuzilong
     * @date: 2018-05-03 10:05:57
     * @desc: 抽取勾选的（或传入的节点）
     * @param: {Array} keys 抽取节点的key值集合
     */
    pullNodes(keys) {
      let nodes;
      const keyStr = this.nodeKey;
      if (keys) {
        nodes = this.wholeData.filter(item => keys.includes(item[keyStr]));
        // TODO: 这里有个BUG，目前不能确定是HUI的问题还是我的问题
        // 根节点直接去设置data的chkDisabled是无效的，必须通过node中的data里的chkDisabled去设置
        const rootNode = nodes.find(
          item =>
            !item[this.parentKey] ||
            item[this.parentKey] === '0' ||
            item[this.parentKey] === '-1'
        );
        if (rootNode) {
          this.$refs.tree.getNode(rootNode).data.chkDisabled = true;
          this.$refs.tree.getNode(rootNode).data.checked = false;
        }
      } else {
        nodes = this.getAllChecked();
        for (let i = 0; i < nodes.length; i++) {
          const index = this.checkedData.findIndex(chkItem => chkItem[keyStr]);
          this.checkedData.splice(index, 1);
        }
        this.setCheckedKeys([]);
      }

      for (const item of nodes) {
        item.chkDisabled = true;
        item.checked = false;

        this.disabledData.push(item);
      }

      this.disabledData = [...new Set(this.disabledData)];

      return nodes;
    },
    /**
     * @author: xuzilong
     * @date: 2018-05-03 10:06:51
     * @desc: 还原被抽取的节点
     */
    pushNodes(keys) {
      if (keys.length === 0) return;
      const keyStr = this.nodeKey;
      const treeStore = this.$refs.tree;
      for (const data of this.wholeData) {
        if (keys.includes(data[keyStr])) {
          const node = treeStore.getNode(data[keyStr]);
          if (node) {
            node.data.chkDisabled = false;
            data.chkDisabled = false;
          } else {
            data.chkDisabled = false;
          }
        }
      }
      this.disabledData = this.disabledData.filter(
        item => !keys.includes(item[keyStr])
      );
    },
    getCheckedNodes() {
      const nodes = this.$refs.tree.getCheckedNodes(...arguments);
      return nodes.filter(
        item => item[this.nodeKey].indexOf('$loadmore') === -1
      );
    },
    setCheckedNodes() {
      this.$refs.tree.setCheckedNodes(...arguments);
    },
    getCheckedKeys() {
      const nodes = this.$refs.tree.getCheckedKeys(...arguments);
      return nodes.filter(item => item.indexOf('$loadmore') === -1);
    },
    setCheckedKeys() {
      this.$refs.tree.setCheckedKeys(...arguments);
    },
    setChecked() {
      this.$refs.tree.setChecked(...arguments);
    },
    setSelected() {
      this.$refs.tree.setSelected(...arguments);
    },
    filter() {
      this.$refs.tree.filter(...arguments);
    }
  }
};
</script>
