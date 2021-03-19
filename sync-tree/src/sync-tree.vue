<template>
  <sync-tree-container
    ref="treeContainer"
    :loading="loading"
    :node-limit="nodeLimit"
    :search-limit="searchLimit"
    :node-limit-alert="nodeLimitAlert"
    :search-limit-alert="searchLimitAlert"
    :search-input-text="searchInputText"
    :tree-search.sync="treeSearch"
    :before-search="beforeSearch"
    :after-search="afterSearch"
    :count="count"
    :mode="mode"
    :search-count="searchCount"
    :maxlength="searchMaxlength"
    :show-search-input="showSearchInput"
    @handler-search="handlerSearch"
    @handler-init="handlerSearch"
    @clear-search-tree="() => $emit('clear-search-tree')"
  >
    <el-tree
      ref="tree"
      :data="data"
      :props="mapConfig"
      :default-expanded-keys="expandNodes"
      :current-node-key="currentNode"
      :node-key="nodeKey"
      :parent-key="parentKey"
      :show-checkbox="showCheckbox"
      :expand-on-click-node="expandOnClickNode"
      :expand-on-dbclick-node="expandOnDblclickNode"
      :highlight-current="highlightCurrent"
      :move="move"
      :load="asyncLoadData"
      :before-click="beforeNodeClick"
      :before-drag="beforeDrag"
      :before-drop="beforeDrop"
      :accordion="accordion"
      :move-area="moveArea"
      check-strictly
      simple-data
      render-when-expand
      lazy
      @check="checkChange"
      @check-change="(data, node) => $emit('check-change', data, node)"
      @current-change="(data, node) => $emit('current-change', data, node)"
      @node-click="
        (data, node, el, event) => $emit('node-click', data, node, el, event)
      "
      @node-dbclick="
        (data, node, el, event) => $emit('node-dbclick', data, node, el, event)
      "
      @node-contextmenu="
        (event, data, node, el) =>
          $emit('node-contextmenu', event, data, node, el)
      "
      @node-expand="(data, node, el) => $emit('node-expand', data, node, el)"
      @node-collapse="
        (data, node, el) => $emit('node-collapse', data, node, el)
      "
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
      @node-mouseenter="
        (data, node, event) => $emit('node-mouseenter', data, node, event)
      "
      @node-mouseleave="
        (data, node, event) => $emit('node-mouseleave', data, node, event)
      "
    >
      <sync-tree-node
        slot-scope="{ node, data, store }"
        :node="node"
        :data="data"
        :mode="mode"
        :store="store"
        :node-name="mapConfig.label"
        :v-node-title="vNodeTitle"
        :v-node-key="vNodeKey"
        :render-content="renderContent"
        :hide-node-title="hideNodeTitle"
        :tree-search="treeSearch"
        :key-highlight="keyHighlight"
        @append="appendNodes"
      ></sync-tree-node>
    </el-tree>
  </sync-tree-container>
</template>

<script>
/**
 * 非兼容性更新：
 * 1. 树内部会更变传入的data内容，比如初始化勾选状态checked属性，如果传入的data的checked为true但是抛出的却是false，并不代表它初始化的时候没有勾选
 */
import SyncTreeContainer from './sync-tree-container.vue';
import SyncTreeNode from './sync-tree-node.vue';
import _ from 'lodash';

const TYPE_ASYNC = 'async';
const TYPE_SYNC = 'sync';
const TYPE_MIXED = 'mixed';
const TYPE_HIERAR = 'hierarchical';

export default {
  name: 'SyncTree',
  components: { SyncTreeContainer, SyncTreeNode },
  props: {
    map: {
      // 配置选项的映射关系，和HUI-tree组件相同
      type: Object,
      default: function() {
        return {};
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
    nodeTypeValues: {
      type: Object,
      default: function() {
        return {};
      }
    },
    rootParentKey: {
      type: [String, Number],
      default: null
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
      },
      required: true
    },
    setSearchData: {
      // 设置搜索时树节点数据（return一个promise对象）
      type: Function,
      default: null
    },
    vNodeKey: {
      // 虚拟节点的标识
      type: String,
      default: '$loadmore'
    },
    vNodeTitle: {
      // 虚拟节点的title文字
      type: String,
      default: '更多'
    },
    nodeLimit: {
      // 展示节点的数量限制
      type: Number,
      default: 1000
    },
    searchLimit: {
      // 搜索节点的数量限制
      type: Number,
      default: 500
    },
    searchText: {
      // 搜索文本
      type: String,
      default: ''
    },
    nodeLimitAlert: {
      // 展示节点数量限制上限的提示
      type: String,
      default: '当前查看数据量较大，流畅度会有所下降，建议使用搜索。'
    },
    searchLimitAlert: {
      // 搜索节点数量限制上限的提示
      type: String,
      default: '搜索结果过多，仅展示前500条，建议缩小搜索范围。'
    },
    searchInputText: {
      // 搜索框中placeholder的提示
      type: String,
      default: '搜索'
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
    defaultSelectCurrent: {
      // 是否默认选中节点（不传current-node-key将默认选中根节点）
      type: Boolean,
      default: true
    },
    linkedExpandKey: {
      // 联动展开的key（展开其上级所有父级节点，必须在type=mixed混合类型下生效）
      type: String,
      default: ''
    },
    currentNodeKey: {
      // 默认选中的节点的key
      type: String,
      default: ''
    },
    renderContent: {
      // 自定义渲染函数
      type: Function,
      default: null
    },
    hideNodeTitle: {
      // 不显示节点上的title
      type: Boolean,
      default: false
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
    showSearchInput: {
      type: Boolean,
      default: true
    },
    checkStrictly: {
      // 是否父子不联动
      type: Boolean,
      default: false
    },
    beforeSearch: {
      // 搜索前钩子
      type: Function,
      default: null
    },
    afterSearch: {
      // 搜索后钩子
      type: Function,
      default: null
    },
    expandOnClickNode: {
      // 是否在点击节点的时候展开或者收缩节点
      type: Boolean,
      default: false
    },
    expandOnDblclickNode: {
      type: Boolean,
      default: true
    },
    highlightCurrent: {
      // 是否高亮当前选中节点，默认值是 true。
      type: Boolean,
      default: true
    },
    move: {
      type: Boolean,
      default: false
    },
    beforeClick: {
      type: Function,
      default: null
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
    },
    accordion: {
      type: Boolean,
      default: false
    },
    moveArea: {
      type: String,
      default: 'outter'
    },
    disabledInherit: {
      // 是否继承禁用状态。
      // 继承禁用解释：
      // 父节点未加载子节点，操作父节点勾选并pullNodes后
      // 展开加载子节点，此时子节点默认会继承父节点的禁用状态
      type: Boolean,
      default: true
    },
    nodeTypeKey: {
      type: String,
      default: 'nodeType'
    },
    afterLoadmore: {
      type: Function,
      default: null
    },
    afterLoad: {
      type: Function,
      default: null
    },
    searchMaxlength: {
      type: Number,
      default: null
    },
    disabledWithChecked: {
      // 禁用和勾选是并存
      // （原来的逻辑中，禁用的节点是不能被勾选的，但确实存在禁用节点需要勾选的逻辑）
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      data: [],
      wholeData: [],
      expandNodes: [],
      cacheData: [],
      disabledData: [],
      levelData: {},
      currentNode: '',
      treeSearch: '',
      mode: 'init',
      count: 0,
      searchCount: 0
    };
  },
  computed: {
    mapConfig() {
      return Object.assign(
        {},
        {
          children: 'children',
          label: 'name',
          isLeaf: 'leaf',
          icon: 'iconSkin',
          disabled: 'chkDisabled',
          selectable: 'selectable'
        },
        this.map
      );
    },
    nodeTypeValuesX() {
      return Object.assign(
        {},
        {
          singleNode: 'singleNode',
          subTree: 'subTree'
        },
        this.nodeTypeValues
      );
    }
  },
  watch: {
    searchText(val) {
      this.$refs.treeContainer.treeSearchText = val;
    },
    treeSearch(val) {
      this.$emit('update:searchText', val);
    }
  },
  mounted() {
    if (!this.autoLoad) return;

    this.init();
  },
  methods: {
    async init() {
      await this.loadRootTree();

      const { data, nodeKey, currentNode } = this;

      const currentObj =
        data.find(item => item[nodeKey] === currentNode) || data[0] || {};

      // 不加nextTick在IE下会拿不到node
      this.$nextTick(() => {
        const node = this.$refs.tree.getNode(currentObj);
        this.$emit('init-select', currentObj, node);
      });
    },
    loadRootTree() {
      // eslint-disable-next-line
      return new Promise(async resolve => {
        const { nodeKey } = this;

        // 初始化获取页面数据
        const listData = await this._getData(true);

        // 设置初始化展开的节点
        this.expandNodes = this.data
          .filter(node => node.open)
          .map(node => node[nodeKey]);

        // 设置初始化选中的节点
        if (this.defaultSelectCurrent) {
          this.currentNode =
            this.currentNodeKey || (this.data[0] && this.data[0][nodeKey]);
        }

        // 插入虚拟节点
        if (!listData.lastPage) {
          this.data.push(this._createVNode('root'));
        }

        // 勾选初始化checked的节点
        this._setInitChecked(this.data);

        resolve(this.data);
      });
    },
    async asyncLoadData(treeNode, resolve) {
      const { nodeKey, afterLoad } = this;
      // 首次进入时，会加载一般父节点为undefined的情况
      const parentId = treeNode.data[nodeKey];
      if (!parentId) return resolve([]);

      const parentIsChecked = treeNode.checked;

      const pageSize = treeNode.data.loadAll ? 999999 : this.pageSize;
      const res = await this._getData(false, parentId, 1, pageSize);

      const nextNodes = [];
      nextNodes.push(...res.rows);

      // 插入虚拟节点
      if (!res.lastPage) {
        nextNodes.push(this._createVNode(parentId));
      } else {
        treeNode.expandAll = true;
      }

      const gapTime = nextNodes.length / 60;
      // 设置延迟，有一个等待展开的动画效果
      setTimeout(() => {
        resolve(nextNodes);
        setTimeout(() => {
          const treeStore = this.$refs.tree;
          const openNodes = nextNodes.filter(item => item.open);
          for (const item of openNodes) {
            treeStore.getNode(item).expand();
          }
        }, 500);

        // 勾选初始化checked的节点
        this._setInitChecked(nextNodes, treeNode);

        // 如果父节点处于勾选，那展开之后子节点也全部勾选
        const { setChecked } = this.$refs.tree;
        if (parentIsChecked) {
          setChecked(treeNode.data, true, false);
          // 如果父节点是初始化就勾选了的，那么子节点就不应该再勾选了
          !this.checkStrictly &&
            treeNode.data.handled &&
            this._setDataCheckedByParent(treeNode, res.rows);
        }

        // TODO：这里有个bug
        // 父节点的勾选状态会莫名其妙的消失了
        if (treeNode.data.checked) {
          setChecked(treeNode.data, true, false);
        }

        // 禁用联动的节点（如果存在穿梭/抽取）
        !this.checkStrictly &&
          this._setChildDisabledByParent(treeNode, res.rows);

        afterLoad && afterLoad(treeNode.data);
      }, gapTime);
    },
    async appendNodes(store, parentData, vData) {
      const { nodeKey, pageSize, afterLoadmore, afterLoad } = this;
      const parentNode = this.$refs.tree.getNode(parentData);
      const pageNo = vData.pageNo + 1;
      const res = await this._getData(
        false,
        parentData[nodeKey],
        pageNo,
        pageSize
      );

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
      } else {
        parentNode.expandAll = true;
      }

      // 勾选初始化checked的节点
      this._setInitChecked(res.rows, parentNode);

      !this.checkStrictly &&
        parentNode.checked &&
        parentNode.data.handled &&
        this._setDataCheckedByParent(parentNode, res.rows);

      !this.checkStrictly &&
        this._setChildDisabledByParent(parentNode, res.rows);

      afterLoadmore && afterLoadmore(parentData);
      afterLoad && afterLoad(parentData);
    },
    checkChange(data, checkDatas, isChecked) {
      this.$emit('check', data, checkDatas, isChecked);

      if (this.checkStrictly) return;

      const { getNode } = this.$refs.tree;

      const node = getNode(data);

      // 如果是取消勾选，直接取消初始化勾选的状态
      node.data.handled = true;
      this._setChildCheckedByParent(node, isChecked);
    },
    async beforeNodeClick(data, node) {
      if (node.selectable === false) return false;

      const callback = this.beforeClick
        ? await this.beforeClick(data, node)
        : true;
      return callback && !data[this.nodeKey].includes(this.vNodeKey);
    },
    search(text) {
      const $treeContainer = this.$refs.treeContainer;
      if (text) {
        $treeContainer.treeSearchText = text;
      }

      $treeContainer.searchTreeAction();
    },
    async handlerSearch(text) {
      const { nodeKey, parentKey, treeSearch } = this;

      let searchList;
      this.cacheData = [];
      this.levelData = {};
      this.count = this.searchCount = 0;

      if (text === '') {
        this.mode = 'init';
        this.$refs.tree.$data.store.lazy = true;
        searchList = await this.loadRootTree();
      } else {
        this.mode = 'search';
        this.$refs.tree.$data.store.lazy = false;
        searchList = this.setSearchData
          ? await this.setSearchData(treeSearch)
          : await this.setTreeData({ keyWord: treeSearch });
        searchList = Array.isArray(searchList) ? searchList : searchList.rows;
        this.wholeData = this.data = searchList;
        this.expandNodes = searchList.map(node => node[nodeKey]);
        this.searchCount = searchList.length;

        this.$nextTick(() => {
          this.setCheckedKeys(
            this.wholeData
              .filter(item => item.checked)
              .map(item => item[nodeKey])
          );
        });
      }

      const currentObj =
        searchList.find(node => this._isRoot(node[parentKey])) || {};

      this.$nextTick(() => {
        const node = this.$refs.tree.getNode(currentObj);
        this.$emit('init-select', currentObj, node);
        this.pullNodes(this.disabledData.map(item => item[nodeKey]));
        // 搜索后的回调
        this.afterSearch && this.afterSearch(searchList, text);
      });
    },
    refresh(callback) {
      this.mode = 'init';
      this.wholeData = [];
      this.data = [];
      this.expandNodes = [];
      this.cacheData = [];
      this.levelData = {};

      const $child = this._findChildComponentByName(this, 'SyncTreeContainer');
      $child.treeSearchText = '';

      this.$refs.tree.$data.store.lazy = true;
      this.setCheckedKeys([]);
      this.init();
      this.$nextTick(() => {
        callback && callback();
      });
    },
    /**
     * @author xuzilong
     * @desc 通过组件名找到子组件
     */
    _findChildComponentByName(context, componentName) {
      const childrens = context.$children;
      let children = null;

      if (childrens.length) {
        for (const child of childrens) {
          const name = child.$options.name;

          if (name === componentName) {
            children = child;
            break;
          } else {
            children = this._findChildComponentByName(child, componentName);
            if (children) break;
          }
        }
      }
      return children;
    },
    /**
     * @author xuzilong
     * @desc 勾选初始化checked的节点
     * @param {Array} datas 总数据（需要筛选出checked的节点）
     */
    _setInitChecked(datas, parentNode) {
      const parentHandled = parentNode && parentNode.data.handled;

      const { setChecked, getNode } = this.$refs.tree;
      const { disabled } = this.mapConfig;
      for (const data of datas) {
        if (data[disabled] && !this.disabledWithChecked) continue;

        const checkNode = getNode(data);
        if (parentHandled) {
          // 如果父节点经过操作，子节点不仅不会被勾选，还会继承父节点操作的状态
          checkNode.data.handled = true;
        }

        if (data.checked && !parentHandled) {
          setChecked(data, true, false);
        } else {
          setChecked(data, false, false);
        }
      }
    },
    /**
     * @author xuzilong
     * @desc 设置某父节点的所有子节点处于勾选状态（联动勾选的逻辑）
     * @param {Node} 节点的node
     * @param {Boolean} 是否勾选
     * @param {Array} 需要操作的目标数组
     */
    _setChildCheckedByParent(node, isChecked) {
      const { setChecked } = this.$refs.tree;
      const { disabled } = this.mapConfig;

      const setChilrenChecked = node => {
        for (const cNode of node.childNodes) {
          // handled代表是否经过操作
          // 经过操作的点，它未加载的子节点的状态就应该继承自它
          cNode.data.handled = true;
          (!cNode.data[disabled] || this.disabledWithChecked) &&
            cNode.checked !== isChecked &&
            setChecked(cNode.data, isChecked);
          !cNode.isLeaf && setChilrenChecked(cNode);
        }
      };

      setChilrenChecked(node);
    },
    /**
     * @author xuzilong
     * @desc 设置新加载的子节点处于勾选状态
     * @param {Node} 节点的node
     * @param {Array} 需要操作的目标数组
     */
    _setDataCheckedByParent(node, targetArr) {
      const { setChecked } = this.$refs.tree;
      const { disabled } = this.mapConfig;
      const { nodeKey } = this;
      const keys = targetArr.map(item => item[nodeKey]);

      for (const cNode of node.childNodes) {
        if (keys.includes(cNode.data[nodeKey])) {
          cNode.data.handled = true;
          (!cNode.data[disabled] || this.disabledWithChecked) &&
            setChecked(cNode.data, true, false);
        }
      }
    },
    /**
     * @author xuzilong
     * @desc 展开子节点时，联动禁用逻辑
     * @param {Node} 节点的node
     * @param {Array} 需要操作的目标数组
     */
    _setChildDisabledByParent(node, targetArr) {
      const { disabled } = this.mapConfig;
      const { data } = node;
      if (
        !this.disabledInherit ||
        !data[disabled] ||
        !data.handled ||
        data.initDisabled
      )
        return;
      const { nodeKey } = this;
      const keys = targetArr.map(item => item[nodeKey]);

      for (const cNode of node.childNodes) {
        if (keys.includes(cNode.data[nodeKey])) {
          cNode.data[disabled] = true;
          cNode.data.handled = true;
        }
      }
    },
    /**
     * @author xuzilong
     * @desc 获取数据
     * @desc 那数据分为3种情形:
     * 1. 加载根节点（首次获取）（pageNo为1，pId为空）
     * 2. 展开节点时加载       （pageNo为1）
     * 3. 点击···的时候加载    （pageNo不为1）
     * @param {Boolean} isRoot 是否是首次加载
     * @param {String} parentId 父节点的id
     */
    _getData(isRoot, parentId, pageNo = 1, pageSize = this.pageSize) {
      // eslint-disable-next-line
      return new Promise(async resolve => {
        const { nodeKey, parentKey, type } = this;
        const { disabled } = this.mapConfig;

        let res = {};

        if (isRoot) {
          // 【首次加载数据】
          let listData = await this.setTreeData({
            pageNo,
            pageSize,
            parentId: null
          });
          // 兼容以前同步的版本（list格式的版本）
          listData = this._checkArray(listData);
          this.wholeData = listData.rows;
          this.wholeData.forEach(item => {
            item.handled = false; // 代表节点是否经过操作或是联动操作
            item.initDisabled = item[disabled];
          });
          res.rows = this.data = this.wholeData.filter(node =>
            this._isRoot(node[parentKey])
          );

          res.lastPage = listData.lastPage;

          if (type === TYPE_MIXED) {
            this.cacheData = [];
            this.cacheData.push(...this.wholeData);
            this.data = this.wholeData;

            if (this.linkedExpandKey) {
              const targetNode = this.cacheData.find(
                item => item[nodeKey] === this.linkedExpandKey
              );
              this._setParentsProperty(
                this.cacheData,
                targetNode,
                'open',
                true
              );
            }
          }
        } else {
          // 【非首次加载数据】
          if (type === TYPE_SYNC) {
            // 同步：从data缓存中拿
            res = this._filterPageData(pageNo, pageSize, parentId);
          } else if (type === TYPE_HIERAR) {
            // 分层：第一页从后台获取，之后全从缓存中拿
            if (pageNo === 1) {
              const listData = await this.setTreeData({
                pageNo,
                pageSize: 999999,
                parentId
              });
              const list = this._toArray(listData);
              list.forEach(item => {
                item.initDisabled = item[disabled];
              });
              this.levelData[parentId] = list;
              this.wholeData.push(...list);
            }
            const arr = this.levelData[parentId];
            res = this._filterLeveData(pageNo, pageSize, arr);
          } else {
            // 非同步：从后台分页获取
            const listData = await this.setTreeData({
              pageNo,
              pageSize,
              parentId
            });
            res = this._checkArray(listData);
            res.rows.forEach(item => {
              item.initDisabled = item[disabled];
            });

            // 混合：从后台获取完后还要从缓存中拿一次
            if (type === TYPE_MIXED) {
              let nextNodes = [];
              nextNodes.push(...res.rows);
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
                this._setParentsProperty(
                  this.cacheData,
                  targetNode,
                  'open',
                  true
                );
              }

              res.rows = nextNodes;
            }
          }
        }

        // 累加[展开节点]计数
        this.count += res.rows.length;

        resolve(res);
      });
    },
    /**
     * @author xuzilong
     * @desc 从某个父节点的子集下分页获取数据
     */

    _filterLeveData(pageNo, pageSize = this.pageSize, nodes) {
      const sliceLength = Math.min(nodes.length, pageNo * pageSize);
      const lastPage = nodes.length <= pageNo * pageSize;
      return {
        lastPage,
        rows: nodes.slice((pageNo - 1) * pageSize, sliceLength)
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
     * @author xuzilong
     * @desc 判断是否是根节点
     */
    _isRoot(key) {
      return !key || key === '0' || key === '-1' || key === this.rootParentKey;
    },
    /**
     * @author: xuzilong
     * @desc: 创建虚拟节点
     * @example {id: 'abc$loadmore', pageNo: 1, leaf: true}
     */
    _createVNode(idStr, pageNo = 1, leaf = true) {
      return {
        [this.nodeKey]: idStr + this.vNodeKey,
        pageNo,
        leaf
      };
    },
    /**
     * @author: xuzilong
     * @desc: 数组检查（兼容以前同步的版本（list格式的版本））
     */
    _checkArray(target) {
      if (Array.isArray(target)) {
        console.warn('请使用正确的数据格式：{ rows: [...], lastPage: ... }');
        return { rows: target, lastPage: true };
      } else {
        return target;
      }
    },
    /**
     * @author xuzilong
     * @desc 转换为数组
     */
    _toArray(target) {
      return Array.isArray(target) ? target : target.rows;
    },
    /**
     * @author: xuzilong
     * @date: 2018-05-14 17:05:24
     * @desc: 调整父级节点属性（递归设置）
     * @param: list:整个数据；data:目标节点；key:要设置的属性名；value:要设置的值
     */
    _setParentsProperty(list, data, key, value) {
      const { nodeKey, parentKey } = this;
      const parentData = list.find(item => item[nodeKey] === data[parentKey]);

      if (parentData[key] === value) return;

      if (parentData) {
        parentData[key] = value;
        this._setParentsProperty(list, parentData, key, value);
      }
    },
    /**
     * @author xuzilong
     * @desc 获取操作过的节点
     */
    getHandleChecked() {
      const renderNodes =
        this.mode === 'search'
          ? this.wholeData
          : this.getAllLoadedDataWithHierar();
      const { nodeKey, parentKey, nodeTypeKey } = this;
      const { singleNode, subTree } = this.nodeTypeValuesX;

      let add = [];
      let del = [];
      const { getNode } = this.$refs.tree;

      // 当初始化checked为false但是处于勾选状态的，即为新增项
      // 当初始化checked为true但是不处于勾选状态的，即为删除项
      for (const data of renderNodes) {
        const node = getNode(data[nodeKey]);
        const pNode = getNode(data[parentKey] || '');

        data[nodeTypeKey] = data[nodeTypeKey] || singleNode;

        // 如果是叶子节点，则认为它不包含下级
        if (!data.checked) {
          if (
            (node && node.checked) ||
            (!node && pNode && pNode.checked && pNode.data.handled)
          ) {
            add.push(data);
          }
        } else if (data.checked) {
          if (
            (node && !node.checked) ||
            (!node && pNode && !pNode.checked && pNode.data.handled)
          ) {
            del.push(data);
          }
        }

        // 如果节点包含下级，并且被操作过
        // 那么它如果处于勾选状态，就被加入add
        // 如果处于非勾选状态，就被加入del
        // 这是由于它的子集并未加载，需要让后台联动加上/去掉它的子集
        if (
          data[nodeTypeKey] === subTree &&
          ((node && data.handled) || (!node && pNode && pNode.data.handled))
        ) {
          if ((node && node.checked) || (!node && pNode && pNode.checked)) {
            add.push(data);
          } else if (
            (node && !node.checked) ||
            (!node && pNode && !pNode.checked)
          ) {
            del.push(data);
          }
        }
      }

      add = _.uniqBy(add, nodeKey);
      del = _.uniqBy(del, nodeKey);

      return { add, del };
    },
    /**
     * @author xuzilong
     * @desc 获取所有渲染过的节点
     */
    getAllRenderNodes() {
      const renderNodes = [];
      const traverse = function(node) {
        node.childNodes.forEach(child => {
          renderNodes.push(child);

          traverse(child);
        });
      };

      traverse(this.$refs.tree.root);

      return renderNodes;
    },
    /**
     * @author xuzilong
     * @desc 从levelData中获取已经加载过的节点
     */
    getAllLoadedDataWithHierar() {
      const { levelData, nodeKey, nodeTypeKey } = this;
      const { getNode } = this.$refs.tree;
      const { singleNode, subTree } = this.nodeTypeValuesX;
      const { isLeaf } = this.mapConfig;
      const loadedData = [];
      const traverse = data => {
        const arr = levelData[data[nodeKey]];
        if (arr) {
          for (const item of arr) {
            const n = getNode(item);
            if (n) {
              item[nodeTypeKey] = n.loaded || n.isLeaf ? singleNode : subTree;
              loadedData.push(item);
              traverse(item);
            } else {
              item[nodeTypeKey] = item[isLeaf] ? singleNode : subTree;
              loadedData.push(item);
            }
          }
        }
      };

      for (const node of this.$refs.tree.root.childNodes) {
        const data = node.data;
        data[nodeTypeKey] = node.loaded || node.isLeaf ? singleNode : subTree;
        loadedData.push(data);
        traverse(data);
      }

      return loadedData;
    },
    getAllChecked() {
      const { getNode } = this.$refs.tree;
      const { nodeKey, parentKey, checkStrictly, levelData, wholeData } = this;
      const { isLeaf, disabled } = this.mapConfig;
      const handlerCheckData = this.getCheckedNodes();
      let allData = [];

      const getNodesByParent = id => {
        for (const _data of wholeData.filter(
          item => item[parentKey] === id && !item.handled && !item[disabled]
        )) {
          allData.push(_data);
          if (!_data[isLeaf]) {
            getNodesByParent(_data[nodeKey]);
          }
        }
      };

      const getNodesFormLeveldata = id => {
        const arr = levelData[id];
        if (!arr) return;
        for (const _data of arr) {
          !_data.handled && allData.push(_data);
        }
      };

      if (this.type === TYPE_ASYNC) {
        // 如果是异步加载，直接返回页面上的勾选的节点即可
        return handlerCheckData;
      } else if (this.type === TYPE_HIERAR) {
        // 如果是分层加载，还需要找到这层下子节点是否勾选
        for (const d of handlerCheckData) {
          allData.push(d);

          const node = getNode(d);
          if (!checkStrictly && d.handled && !node.isLeaf && !node.expandAll) {
            getNodesFormLeveldata(d[nodeKey]);
          }
        }
        return allData;
      }

      for (const d of handlerCheckData) {
        allData.push(d);

        const node = getNode(d);
        !checkStrictly && !node.expandAll && getNodesByParent(d[nodeKey]);
      }

      // 当存在初始化勾选的节点，需要额外处理
      if (this.hasOriginalChecked) {
        // 向上找渲染出来的父节点，如果父节点没有被操作过，那么加入该节点
        const checkParentHandled = (data, targetData) => {
          const p = this.wholeData.find(
            item => item[nodeKey] === data[parentKey]
          );
          if (!p) return;
          const pNode = getNode(p);
          if (!pNode) {
            checkParentHandled(p, targetData);
          } else if (pNode && !p.handled) {
            allData.push(targetData);
          }
        };

        for (const wD of this.wholeData) {
          if (wD.checked && !wD.handled) {
            checkParentHandled(wD, wD);
          }
        }

        allData = _.uniqBy(allData, nodeKey);
      }

      return allData;
    },
    pullNodes(keys) {
      const { setChecked } = this.$refs.tree;
      const { disabled } = this.mapConfig;
      const { nodeKey } = this;
      let nodeData;
      if (keys) {
        nodeData = this.wholeData.filter(item => keys.includes(item[nodeKey]));
      } else {
        nodeData = this.getAllChecked();
      }

      for (const item of nodeData) {
        item[disabled] = true;
        !this.disabledWithChecked && setChecked(item, false, false);

        this.disabledData.push(item);
      }

      this.disabledData = _.uniqBy(this.disabledData, nodeKey);

      return nodeData;
    },
    pullAllLoadedNodes() {
      const { disabled } = this.mapConfig;
      const nodeData = this.getAllLoadedDataWithHierar();
      const disabledData = [];

      for (const item of nodeData) {
        item[disabled] = true;
        disabledData.push(item);
      }

      this.disabledData = disabledData;

      return disabledData;
    },
    pushNodes(keys) {
      const { nodeKey } = this;
      const { getNode } = this.$refs.tree;

      if (keys && keys.length === 0) {
        return;
      } else if (!keys) {
        keys = this.disabledData.map(item => item[nodeKey]);
      }

      if (this.type === TYPE_HIERAR) {
        for (const key of keys) {
          const node = getNode(key);
          if (node) {
            node.data.chkDisabled = false;
          }
        }
      } else {
        for (const data of this.wholeData) {
          if (keys.includes(data[nodeKey])) {
            const node = getNode(data[nodeKey]);
            if (node) {
              node.data.chkDisabled = false;
              data.chkDisabled = false;
            } else {
              data.chkDisabled = false;
            }
          }
        }
      }
      this.disabledData = this.disabledData.filter(
        item => !keys.includes(item[nodeKey])
      );
    },
    getCheckedNodes() {
      const { nodeKey, vNodeKey } = this;
      const nodes = this.$refs.tree.getCheckedNodes(...arguments);
      return nodes.filter(item => !item[nodeKey].includes(vNodeKey));
    },
    getCheckedKeys() {
      const { vNodeKey } = this;
      const nodes = this.$refs.tree.getCheckedKeys(...arguments);
      return nodes.filter(item => !item.includes(vNodeKey));
    },
    setSelected() {
      this.$refs.tree.setSelected(...arguments);
    },
    filter() {
      this.$refs.tree.filter(...arguments);
    },
    setCheckedKeys() {
      this.$refs.tree.setCheckedKeys(...arguments);
    },
    setCurrentKey() {
      this.$refs.tree.setCurrentKey(...arguments);
    },
    setCurrentNode() {
      this.$refs.tree.setCurrentKey(...arguments);
    },
    getSelectedNode() {
      return this.$refs.tree.getSelectedNode(...arguments);
    },
    getSelectedKey() {
      return this.$refs.tree.getSelectedKey(...arguments);
    },
    resizeScrollbar() {
      this.$refs.tree.resizeScrollbar(...arguments);
    },
    getNode() {
      return this.$refs.tree.getNode(...arguments);
    },
    expandNode() {
      this.$refs.tree.expandNode(...arguments);
    },
    collapseNode() {
      this.$refs.tree.collapseNode(...arguments);
    },
    remove() {
      this.$refs.tree.remove(...arguments);
    },
    append() {
      this.$refs.tree.append(...arguments);
    },
    reload() {
      this.$refs.tree.reload(...arguments);
    },
    insertBefore() {
      this.$refs.tree.insertBefore(...arguments);
    },
    insertAfter() {
      this.$refs.tree.insertAfter(...arguments);
    }
  }
};
</script>
