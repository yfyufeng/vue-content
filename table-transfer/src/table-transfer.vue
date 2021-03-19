<template>
  <div class="h-table-transfer">
    <div
      :class="[
        'h-table-transfer__be-right',
        isShowLeftTip ? 'show-tip' : '',
        btnType
      ]"
    >
      <!-- 左侧列表标题 -->
      <h3>
        <span class="ellipsis">
          {{ leftTableTitle || t('h.tableTransfer.leftTableTitle') }}
        </span>
        <span
          v-if="!bigDataMode"
          style="display:inline-block; vertical-align: middle;"
        >
          ({{ leftChecked }}/{{ leftTotal }})
        </span>
        <el-checkbox
          v-if="isShowCheckBox"
          v-model="checked"
          style="float: right;"
          @change="checkChanged"
          @click.native="checkClick"
        >
          {{ checkText }}
        </el-checkbox>
        <template v-if="!isShowCheckBox && $scopedSlots['leftAddition']">
          <slot name="leftAddition"></slot>
        </template>
      </h3>
      <!-- 左侧搜索框 -->
      <!-- 如果传入了自定义的slot内容，那么按照传入的内容进行渲染，并把内部的筛选和清空处理方法暴露出去，以便外部调用 -->
      <template v-if="$scopedSlots['leftSearchBar']">
        <slot
          :leftFilter="filterLeftData"
          :leftClearFilter="leftClearIconClick"
          name="leftSearchBar"
        ></slot>
      </template>
      <template v-else>
        <el-input
          v-model.trim="leftTable.searchWord"
          :placeholder="leftTableInputPh || t('h.tableTransfer.tableInputPh')"
          :on-icon-click="filterLeftData"
          :clear-icon-click="leftClearIconClick"
          clearable
          suffix-icon="h-icon-search"
          @keyup.enter.native="filterLeftData"
        />
      </template>
      <el-alert
        v-if="isShowLeftTip"
        :title="t('h.tableTransfer.largeDataLeftTip')"
        :closable="false"
        type="info"
        show-icon
        class="alert-tip"
        simple
      />
      <!-- 左侧列表 -->
      <el-table
        ref="leftTable"
        v-loading="leftTableTableLoading"
        :cell-style="cellClass"
        :enable-virtual-scroll="leftEnableVirtualScroll"
        :data="leftTable.data"
        :span-method="rowLeftSpan"
        :element-loading-text="
          leftTableLoadingText || t('h.tableTransfer.leftTableLoadingText')
        "
        :empty-text="
          leftTableEmptyText || t('h.tableTransfer.leftTableEmptyText')
        "
        :row-key="rowKey"
        force-scroll
        show-overflow-title
        style="flex:1;width:100%;margin-top:8px;"
        @select="checkLeftRow"
        @select-all="selectAll($event, 'leftTable')"
        @row-click="rowClick($event, 'leftTable')"
        @expand-click="expandClick"
        @sort-change="leftTableSortChange"
        @filter-change="leftTableFilterChange"
      >
        <el-table-column
          :selectable="disabledLeftTableCheckbox"
          type="selection"
          width="35"
        />
        <slot name="leftTableColumn" />
        <template slot="empty">
          <slot name="empty" />
        </template>
      </el-table>
    </div>
    <!-- 移动按钮 -->
    <div :class="['h-table-transfer__operation', btnType]">
      <div class="h-table-transfer__operation-group">
        <el-button
          :class="btnType"
          :disabled="
            moveToRightButtonFlag
              ? moveToRightButtonFlag()
              : !leftTable.checkedRows.length
          "
          icon-border="h-icon-angle_right_sm"
          @click="moveToRight"
        >
          {{ btnType === 'text' ? t('h.tableTransfer.right') : '' }}
        </el-button>
        <br />
        <el-button
          :class="btnType"
          :disabled="
            moveToLeftButtonFlag
              ? moveToLeftButtonFlag()
              : !rightTable.checkedRows.length
          "
          icon-border="h-icon-angle_left_sm"
          @click="moveToLeft"
        >
          {{ btnType === 'text' ? t('h.tableTransfer.left') : '' }}
        </el-button>
      </div>
    </div>
    <div
      :class="[
        'h-table-transfer__right',
        isShowRightTip ? 'show-tip' : '',
        btnType
      ]"
    >
      <!-- 右侧列表标题 -->
      <h3>
        <span class="ellipsis">
          {{ rightTableTitle || t('h.tableTransfer.rightTableTitle') }}
        </span>
        <span
          v-if="!bigDataMode"
          style="display:inline-block; vertical-align: middle;"
        >
          ({{ rightChecked }}/{{ rightTotal }})
        </span>
        <span v-else style="display:inline-block; vertical-align: middle;">
          ({{ rightTotal }})
        </span>
        <template v-if="$scopedSlots['rightAddition']">
          <slot name="rightAddition"></slot>
        </template>
      </h3>
      <!-- 右侧搜索框 -->
      <!-- 如果传入了自定义的slot内容，那么按照传入的内容进行渲染，并把内部的筛选和清空处理方法暴露出去，以便外部调用 -->
      <template v-if="$scopedSlots['rightSearchBar']">
        <slot
          :rightFilter="filterRightData"
          :rightClearFilter="rightClearIconClick"
          name="rightSearchBar"
        ></slot>
      </template>
      <!-- 如果没有传入自定义的slot内容，那么按照默认的内容进行渲染 -->
      <template v-else>
        <el-input
          v-model.trim="rightTable.searchWord"
          :placeholder="rightTableInputPh || t('h.tableTransfer.tableInputPh')"
          :on-icon-click="filterRightData"
          :clear-icon-click="rightClearIconClick"
          clearable
          suffix-icon="h-icon-search"
          @keyup.enter.native="filterRightData"
        />
      </template>
      <el-alert
        v-if="isShowRightTip"
        :title="t('h.tableTransfer.largeDataRightTip')"
        :closable="false"
        type="info"
        show-icon
        class="alert-tip"
        simple
      />
      <!-- 右侧列表 -->
      <el-table
        ref="rightTable"
        :data="rightTable.data"
        :cell-style="cellClass"
        :enable-virtual-scroll="rightEnableVirtualScroll"
        :row-key="rowKey"
        :empty-text="
          rightTableEmptyText || t('h.tableTransfer.rightTableEmptyText')
        "
        :span-method="rowRightSpan"
        force-scroll
        show-overflow-title
        style="flex:1;width:100%;margin-top: 8px;"
        @row-click="rowClick($event, 'rightTable')"
        @filter-change="rightTableFilterChange"
        @sort-change="rightTableSortChange"
        @select-all="selectAll($event, 'rightTable')"
        @select="checkRightRow"
      >
        <el-table-column
          :selectable="disabledRightTableCheckbox"
          type="selection"
          width="35"
        />
        <slot name="rightTableColumn" />
        <template slot="empty">
          <slot name="empty" />
        </template>
      </el-table>
    </div>
  </div>
</template>
<script>
/**
 * @author zhangxin14
 * @date 2017/12/7
 * @desc 表格穿梭框
 *
 * @author jiangyan6
 * @date 2018/10/13
 * @desc 扩展了表格穿梭框的搜索功能，目前可以支持自定义搜索区域内容，
 * 自定义搜索区域内容通过slot传入，slot有如下两个：
 * leftSearchBar：左侧表格的搜索区域内容
 * rightSearchBar：右侧表格的搜索区域内容
 *
 * 这两个slot都有slot-scope属性，会把穿梭框内部的搜索和清空处理函数的钩子暴露出来，
 * 由slot中的内容决定何时调用这些钩子函数，这些钩子函数包括以下几个：
 * leftFilter：左侧列表搜索处理函数（这里只是调用搜索的钩子函数，真正的处理逻辑在leftFilterHandler中）
 * leftClearFilter：左侧列表清空搜索处理函数
 * rightFilter：右侧列表搜索处理函数（这里只是调用搜索的钩子函数，真正的处理逻辑在rightFilterHandler中）
 * rightClearFilter：右侧列表清空搜索处理函数
 *
 * 当传入slot自定义的内容时，需要自行处理搜索逻辑和清空逻辑，需要在transfer组件上传入以下属性：
 * leftFilterHandler：左侧表格搜索的处理逻辑，参数item：当前项，各属性与table的数据源一致
 * rightFilterHandler：右侧表格搜索的处理逻辑，参数item：当前项，各属性与table的数据源一致
 */
import { listToTableTreeData, cloneObj, diff } from './utils';
import _ from 'lodash';
import { t } from '@hui-pro/locale';
const LOAD_MORE = 'loadMore';

export default {
  name: 'HTableTransfer',
  props: {
    // 如果是树表格，则数据中必须有`leaf`字段，表示是否是子节点
    isTableTree: {
      type: Boolean,
      default: false
    },
    leftEnableVirtualScroll: {
      type: Boolean,
      default: false
    },
    rightEnableVirtualScroll: {
      type: Boolean,
      default: false
    },
    // 启用大数据模式之后，穿梭框不显示已选数量和总数
    // 后台数据只展示1000条，且搜索需要使用自定义搜索（需要在业务代码中处理）
    bigDataMode: {
      type: Boolean,
      default: false
    },
    // 右移时触发方法
    moveRightAction: {
      type: Function,
      default: () => new Promise(resolve => resolve())
    },
    // 左移时触发方法
    moveLeftAction: {
      type: Function,
      default: () => new Promise(resolve => resolve())
    },
    btnType: {
      type: String,
      default: 'normal'
    },
    // 一页加载多少条数据
    loadNum: {
      type: Number,
      default: 500
    },
    // 右侧表格数据
    rightTableData: {
      type: Array,
      default() {
        return [];
      }
    },
    // 左侧表格数据
    leftTableData: {
      type: Array,
      default() {
        return [];
      }
    },
    // 节点所属组织字段
    belongField: {
      type: String,
      default: 'belongArea'
    },
    // 当前选中的树节点id
    treeNodeId: {
      type: String,
      default: '',
      required: true
    },
    // 行数据的id名称
    rowKey: {
      type: String,
      required: true
    },
    parentKey: {
      type: String,
      default: 'pId'
    },
    // 表格里面列的名称
    nameKey: {
      type: [String, Array],
      required: true
    },
    cacheRightData: {
      type: Boolean,
      default: true
    },
    checkText: {
      type: String,
      default: '包含下级人员'
    },
    isShowCheckBox: {
      type: Boolean,
      default: false
    },
    leftTableTitle: {
      type: String,
      default: ''
    },
    leftTableInputPh: {
      type: String,
      default: ''
    },
    leftTableLoadingText: {
      type: String,
      default: ''
    },
    leftTableEmptyText: {
      type: String,
      default: ''
    },
    rightTableTitle: {
      type: String,
      default: ''
    },
    rightTableInputPh: {
      type: String,
      default: ''
    },
    rightTableEmptyText: {
      type: String,
      default: ''
    },
    sortKey: {
      type: String,
      default: 'sortId'
    },
    /**
     * @author jiangyan6
     * @date 2018/10/13
     * 新增属性，用于传入自定义的过滤规则
     */
    leftFilterHandler: {
      type: Function,
      default: null
    },
    rightFilterHandler: {
      type: Function,
      default: null
    },
    /**
     * @author lvzhongsong
     * @date 2020/5/8
     * 新增属性，用于传入自定义的过滤规则
     */
    moveToLeftButtonFlag: {
      type: Function,
      default: null
    },
    moveToRightButtonFlag: {
      type: Function,
      default: null
    }
  },
  data() {
    return {
      t,
      // 左侧列表的相关数据
      leftTable: {
        data: [],
        pageNo: 0,
        searchWord: '',
        checked: [], // 缓存勾选的状态
        searchCacheData: [],
        isCheckAll: false, // 是否勾选了全选
        checkedRows: [] // 被勾选的数据
        // unCheckedRows: [] // 只要在全选之后，去勾选的才会被缓存起来，主要为了优化性能
      },
      // 右侧列表的相关数据
      rightTable: {
        data: [],
        pageNo: 0,
        searchWord: '',
        checked: [],
        isCheckAll: false,
        searchCacheData: [],
        checkedRows: [] // 被勾选的数据
        // unCheckedRows: [] // 只要在全选之后，去勾选的才会被缓存起来
      },
      isShowLeftTip: false,

      checked: false, // 是否勾选包含下级
      getCacheTableData: null,
      leftTableTableLoading: false
    };
  },

  computed: {
    // 左侧表格可勾选总数
    leftTotal() {
      if (!this.isTableTree) return this.leftTable.searchCacheData.length;
      return this.getChildrenNodes(
        listToTableTreeData(
          this.parentKey,
          this.rowKey,
          this.leftTable.searchCacheData,
          this.belongField,
          this.treeNodeId,
          this.sortKey
        )
      ).length;
    },

    // 左侧表格已选中的数量
    leftChecked() {
      if (!this.isTableTree) return this.leftTable.checkedRows.length;
      // 没有勾选过全选时，页面上显示的勾选数量就是勾选的数量
      // 勾选过全选时，需要根据所有节点计算出子节点的数量
      return this.isCheckAll
        ? this.leftTable.checkedRows.length
        : this.getChildrenNodes(this.leftTable.checkedRows, true).length;
    },

    // 右侧表格可勾选总数
    rightTotal() {
      return this.rightTable.searchCacheData.length;
    },

    // 右侧表格已选中的数量
    rightChecked() {
      return this.rightTable.checkedRows.length;
    },

    // 是否展示右侧数据过多的提示
    isShowRightTip() {
      return this.rightTable.data.length > this.loadNum * 2;
    },

    // 支持多列的搜索
    searchKeys() {
      return Array.isArray(this.nameKey) ? this.nameKey : [this.nameKey];
    }
  },

  watch: {
    rightTableData: {
      immediate: true,
      handler(val, oldVal) {
        // 是否缓右侧列表数据
        // 右侧列表作为独立的数据源，与左侧表格选中无关，只和外部传入有关
        const cloneRightTableData = val.concat(
          (this.cacheRightData && oldVal) || []
        );
        this.rightTable.searchWord = '';
        this.rightTable.checkedRows = [];
        this.rightTable.data = this.loadMore(
          cloneRightTableData,
          true,
          'rightTable'
        );
        this.rightTable.searchCacheData = cloneRightTableData;
        this.getCacheTableData = this.updateData(
          this.leftTableData,
          cloneRightTableData
        );
      }
    },

    leftTableData: {
      immediate: true,
      handler(val) {
        const { rightTableCacheData } = this.getCacheTableData();
        // 参数是对象，是引用关系，如果不进行一份拷贝，会导致死循环
        // 标记节点所属组织，默认排序
        const cloneLeftTableData = val.concat().map((item, index) => {
          item[this.belongField] = item[this.belongField] || this.treeNodeId;
          item.sortId = index;
          return item;
        });
        const leftData = diff(
          cloneLeftTableData,
          rightTableCacheData,
          this.rowKey
        );
        this.leftTable.searchWord = '';
        this.leftTable.checkedRows = [];
        this.leftTable.data = this.loadMore(leftData);
        this.leftTable.searchCacheData = leftData;
        this.getCacheTableData = this.updateData(leftData, rightTableCacheData);
      }
    }
  },

  updated() {
    this.updateLoadMoreStyle();
  },

  methods: {
    // cacheData中的数据都是`list`，不是树结构的数据
    // 更新数据，两侧数据发生变化之后，缓存数据
    updateData(...arg) {
      const [leftTableCacheData, rightTableCacheData] = arg;
      return () => ({
        leftTableCacheData,
        rightTableCacheData
      });
    },

    // 外部调用方法，去除额外的参数
    getCacheData() {
      const {
        leftTableCacheData,
        rightTableCacheData
      } = this.getCacheTableData();
      return {
        leftTableCacheData: leftTableCacheData.map(item =>
          _.omit(item, ['sortId', 'belongArea'])
        ),
        rightTableCacheData: rightTableCacheData.map(item =>
          _.omit(item, ['sortId', 'belongArea'])
        )
      };
    },

    leftClearIconClick() {
      this.$nextTick(() => {
        this.filterLeftData();
      });
    },

    rightClearIconClick() {
      this.$nextTick(() => {
        this.filterRightData();
      });
    },

    expandClick(expanded, row) {
      const {
        leftTableCacheData,
        rightTableCacheData
      } = this.getCacheTableData();
      const { _data } = this.$refs.leftTable.store.states;
      const cloneData = cloneObj(leftTableCacheData);
      // 展开上一步操作的节点
      for (const item of cloneData) {
        if (item[this.rowKey] === row[this.rowKey]) {
          item.open = expanded;
          break;
        }
      }
      this.getCacheTableData = this.updateData(cloneData, rightTableCacheData);
      this.isShowLeftTip = _data.length > this.loadNum * 2;
      this.$emit('expand-click', expanded, row);
    },

    /**
     * @description: 设置全选
     * @author: zhangxin14
     * @since: 2018-05-04 14:23:53
     */
    selectAll(selection, tableType) {
      this.$emit('select-change', selection);
      if (
        selection.length === 0 ||
        selection.findIndex(item => item.type === LOAD_MORE) > -1
      ) {
        this[tableType].isCheckAll = false;
        this[tableType].checkedRows = [];
        return;
      }
      if (
        selection.length !== this[tableType].data.length &&
        this[tableType].data.length === this[tableType].searchCacheData.length
      ) {
        this[tableType].isCheckAll = false;
        for (const row of selection) {
          this.getCheckedRows(selection, row, tableType);
        }
        return;
      }
      this[tableType].isCheckAll = true;
      const {
        leftTableCacheData,
        rightTableCacheData
      } = this.getCacheTableData();
      const leftData = this[tableType].searchCacheData.length
        ? this[tableType].searchCacheData
        : leftTableCacheData;
      const rightData = this[tableType].searchCacheData.length
        ? this[tableType].searchCacheData
        : rightTableCacheData;
      const cacheData = tableType === 'leftTable' ? leftData : rightData;
      // 全选之后，将所有子节点添加到checkrows
      this[tableType].checkedRows =
        this.isTableTree && tableType === 'leftTable'
          ? this.getChildrenNodes(cacheData)
          : cloneObj(cacheData);
    },

    rowClick(row, tableType) {
      if (row.type === LOAD_MORE) {
        // const {
        //   leftTableCacheData,
        //   rightTableCacheData
        // } = this.getCacheTableData();
        // const cacheData =
        //   tableType === 'leftTable' ? leftTableCacheData : rightTableCacheData;
        // const loadData = this[tableType].searchWord
        //   ? this[tableType].searchCacheData
        //   : cacheData;
        // @fix 姜炎6： 这里原逻辑会导致在自定义搜索区域时，搜索后的加载更多报错，
        const loadData = this[tableType].searchCacheData;
        const nextPageData = this.loadMore(loadData, false, tableType);
        this[tableType].data.pop();
        this[tableType].data.push(...nextPageData);
        this.$nextTick(() => {
          if (this[tableType].isCheckAll) {
            for (const row of nextPageData) {
              this.$refs[tableType].toggleRowSelection(row, true);
            }
          }
        });
      }
    },

    rightTableFilterChange(filters) {
      this.rightTable.checkedRows = [];
      this.rightTable.isCheckAll = false;
      this.$refs.rightTable.clearSelection();
      this.$emit('right-table-filter-change', filters);
    },

    leftTableFilterChange(filters) {
      this.leftTable.checkedRows = [];
      this.leftTable.isCheckAll = false;
      this.$refs.leftTable.clearSelection();
      this.$emit('left-table-filter-change', filters);
    },

    leftTableSortChange(sortObj) {
      this.$emit('left-table-sort-change', sortObj);
    },

    rightTableSortChange(sortObj) {
      this.$emit('right-table-sort-change', sortObj);
    },

    /**
     * @description: 加载左侧列表数据
     * @author: zhangxin14
     * @since: 2018-05-03 10:46:35
     */
    loadMore(
      loadData,
      firstPage = true,
      tableType = 'leftTable',
      expanded = false
    ) {
      let pageResult;
      const [displayLoadMoreField] = this.searchKeys;
      this[tableType].pageNo = firstPage ? 0 : this[tableType].pageNo;
      if (this.isTableTree && tableType === 'leftTable') {
        const treeTableData = listToTableTreeData(
          this.parentKey,
          this.rowKey,
          loadData,
          this.belongField,
          this.sortKey,
          expanded
        );
        // 数据没有超过500条，直接返回数据
        if (treeTableData.length < this.loadNum) {
          return treeTableData;
        } else {
          this[tableType].pageNo += 1;
          pageResult = treeTableData.slice(
            firstPage ? 0 : this[tableType].data.length - 1,
            this[tableType].pageNo * this.loadNum
          );
          if (this[tableType].pageNo * this.loadNum < treeTableData.length) {
            pageResult.push({
              [this.parentKey]: this.treeNodeId,
              [displayLoadMoreField]: t('h.tableTransfer.loadMore'),
              type: LOAD_MORE
            });
          }
          return pageResult;
        }
      }
      // 数据没有超过500条，直接返回数据
      if (loadData.length < this.loadNum) {
        // 左侧列表需要排序，右侧列表不需要排序
        return tableType === 'leftTable'
          ? loadData.sort((a, b) => a[this.sortKey] - b[this.sortKey])
          : loadData;
      }
      this[tableType].pageNo += 1;
      // 普通列表，根据分页截取响应数据
      pageResult = loadData.slice(
        firstPage ? 0 : this[tableType].data.length - 1,
        this[tableType].pageNo * this.loadNum
      );
      // 左侧列表需要排序，右侧列表不需要排序
      tableType === 'leftTable' &&
        pageResult.sort((a, b) => a[this.sortKey] - b[this.sortKey]);
      if (this[tableType].pageNo * this.loadNum < loadData.length) {
        pageResult.push({
          [Array.isArray(this.nameKey) ? this.nameKey[0] : this.nameKey]: t(
            'h.tableTransfer.loadMore'
          ),
          type: LOAD_MORE
        });
      }
      return pageResult;
    },

    /**
     * @description: 勾选发生化时触发事件
     * @author: zhangxin14
     * @since: 2018-05-03 09:53:59
     */
    checkChanged(value, event) {
      this.$emit('check-changed', value, event);
    },

    /**
     * @description: 勾选发生前触发事件，可以调用event.preventDefault()等一些魔改操作阻止勾选，仅在特殊场景下使用
     * @example       let ele = event.currentTarget
                      event.preventDefault()
                      this.$confirm('要继续吗？', {
                        confirmButtonText: '要',
                        cancelButtonText: '不要',
                        type: 'warning'
                      }).then(() => {
                        ele.querySelector('input').click()
                      })
    * @author zhubincong
    * @since 2019-01-03 15:09:13
    */
    checkClick(event) {
      // 一次勾选会触发2次click事件，第二次的target是input，不需要捕获
      if (event.target.tagName !== 'INPUT') {
        this.$emit('before-check', !this.checked, event);
      }
    },

    /**
     * @description: 合并单元格
     * @author: zhangxin14
     * @since: 2018-06-14 11:43:56
     */
    rowSpanMethod(soltName, row, columnIndex) {
      if (row.type === LOAD_MORE) {
        if (columnIndex === 1) {
          return {
            colspan:
              this.$slots[soltName].filter(item => {
                return item.tag && item.tag.includes('ElTableColumn');
              }).length + 1,
            rowspan: 1
          };
        } else {
          return {
            rowspan: 0,
            colspan: 0
          };
        }
      }
    },

    rowLeftSpan({ row, columnIndex }) {
      return this.rowSpanMethod('leftTableColumn', row, columnIndex);
    },

    rowRightSpan({ row, columnIndex }) {
      return this.rowSpanMethod('rightTableColumn', row, columnIndex);
    },

    /**
     * @desc:
     * 左侧列表前端本地做搜索过滤
     * @date: 2017/11/27 17:24
     * @author: zhangxin14
     *
     * @date 2018/10/13
     * @author jiangyan6
     * 修改过滤方法，支持外部传入自定义搜索规则
     */
    filterLeftData() {
      if (!this.isTableTree) {
        const { leftTableCacheData } = this.getCacheTableData();
        let searchResult;
        if (this.leftFilterHandler) {
          // 传入了自定义的搜索规则，则使用传入的规则
          searchResult = leftTableCacheData.filter(this.leftFilterHandler);
        } else {
          // 没有传入自定义的搜索规则，则使用默认的规则
          searchResult = !this.leftTable.searchWord
            ? leftTableCacheData
            : leftTableCacheData.filter(item => {
                return this.searchKeys.some(
                  key =>
                    item[key] &&
                    item[key]
                      .toLocaleLowerCase()
                      .includes(this.leftTable.searchWord.toLocaleLowerCase())
                );
              });
        }
        // 缓存搜索数据，用于加载更多
        this.leftTable.searchCacheData = searchResult;
        // hack: 解决全选之后，点击搜索按钮，勾选状态无法重置
        this.leftTable.data = [];
        this.$nextTick(_ => {
          this.leftTable.data = this.loadMore(searchResult);
        });
      }

      if (this.isTableTree) {
        this.filterTableTreeData();
      }
      this.leftTable.isCheckAll = false;
      this.leftTable.checkedRows = [];
      this.$emit('left-table-search');
    },

    /**
     * @Author: zhangxin14
     * @Date: 2018-03-28 11:40:52
     * @Desc: 过滤树结构的数据，查询结果可以包含父节点或者只含子节点
     */
    filterTableTreeData() {
      const { leftTableCacheData } = this.getCacheTableData();
      let result;
      if (this.leftFilterHandler) {
        // 传入了自定义的搜索规则，则使用传入的规则
        result = leftTableCacheData.filter(this.leftFilterHandler);
      } else {
        result = !this.leftTable.searchWord
          ? leftTableCacheData
          : leftTableCacheData.filter(item => {
              return (
                this.searchKeys.some(
                  key =>
                    item[key] &&
                    item[key]
                      .toLocaleLowerCase()
                      .includes(this.leftTable.searchWord.toLocaleLowerCase())
                ) && item.leaf
              );
            });
      }

      const cloneResult = cloneObj(result);
      const searchResult = this.findRootNode(this.leftTableData, cloneResult);
      this.leftTable.searchCacheData = searchResult;
      // note：有搜索关键字时，展开树节点
      // 但是如果是自定义搜索的情况下，没有办法取到搜索关键字，所以会不生效
      // magic code：通过ref的方式修改searchWord可以解决
      this.leftTable.data = this.loadMore(
        searchResult,
        true,
        'leftTable',
        !!this.leftTable.searchWord
        // leftTableCacheData.length !== searchResult.length
      );
    },

    /**
     * @Author: zhangxin14
     * @Date: 2018-03-28 11:10:43
     * @Desc: 根据某个节点，找到其父节点，为拼接出一个完整的树结构
     */
    findRootNode(leftTableCacheData, childNodesWithParent) {
      const parentNodes = leftTableCacheData.filter(item =>
        item[this.belongField].includes(item[this.parentKey])
      );
      const allParentGroupNodes = _.groupBy(parentNodes, this.rowKey);
      // 所有字节的父节点集合
      const childNodes = childNodesWithParent.filter(item => item.leaf);
      const childNodePid = childNodes.map(item => item[this.parentKey]);
      // 父节点去重
      const uniquePids = [...new Set(childNodePid)];
      // 根据父节点找出子节点
      return uniquePids.reduce((preValue, curValue) => {
        if (allParentGroupNodes[curValue]) {
          preValue.push(allParentGroupNodes[curValue][0]);
          preValue.push(
            ...childNodes.filter(item => item[this.parentKey] === curValue)
          );
        }
        return preValue;
      }, []);
    },

    /**
     * @desc: 右侧列表前端本地做搜索过滤
     * @date: 2017/11/27 17:24
     * @author: zhangxin14
     * @params:
     *
     * @date 2018/10/13
     * @author jiangyan6
     * 修改过滤方法，支持外部传入自定义搜索规则
     */
    filterRightData() {
      const { rightTableCacheData } = this.getCacheTableData();
      let searchResult;
      if (this.rightFilterHandler) {
        // 传入了自定义的搜索规则，则使用传入的规则
        searchResult = rightTableCacheData.filter(this.rightFilterHandler);
      } else {
        // 没有传入自定义的搜索规则，则使用默认的规则
        searchResult = !this.rightTable.searchWord
          ? rightTableCacheData
          : rightTableCacheData.filter(item => {
              return this.searchKeys.some(
                key =>
                  item[key] &&
                  item[key]
                    .toLocaleLowerCase()
                    .includes(this.rightTable.searchWord.toLocaleLowerCase())
              );
            });
      }
      // 缓存搜索数据，用于加载更多
      this.rightTable.searchCacheData = searchResult;
      // hack: 解决全选之后，点击搜索按钮，勾选状态无法重置
      this.rightTable.data = [];
      this.$nextTick(_ => {
        this.rightTable.data = this.loadMore(searchResult, true, 'rightTable');
      });
      this.rightTable.isCheckAll = false;
      this.rightTable.checkedRows = [];
    },

    checkLeftRow(selection, row) {
      this.getCheckedRows(selection, row, 'leftTable');
      if (this.isTableTree) {
        this.checkChildrenNode(selection, row, 'leftTable');
      }

      this.$emit('select-change', selection);
    },

    /**
     * @desc: 已选择的已添加的数据
     * @date: 2017/11/27 17:25
     * @author: zhangxin14
     */
    checkRightRow(selection, row) {
      this.getCheckedRows(selection, row, 'rightTable');

      this.$emit('right-select-change', selection);
    },

    /**
     * @description: 处理勾选
     * @author: zhangxin14
     * @since: 2018-06-28 09:41:48
     */
    getCheckedRows(selection, row, tableType) {
      // 普通列表
      if (!this.isTableTree) {
        // 非全选状态下，当前勾选的就是勾选的节点
        if (!this[tableType].isCheckAll) {
          this[tableType].checkedRows = selection;
        } else {
          // 全选状态下
          // 去勾选，只排除去勾选的数据
          if (!selection.includes(row)) {
            const rowPos = this[tableType].checkedRows.findIndex(
              item => item[this.rowKey] === row[this.rowKey]
            );
            this[tableType].checkedRows.splice(rowPos, 1);
          } else {
            this[tableType].checkedRows.push(row);
          }
        }
      } else {
        // 树表格
        // 因为勾选全选时，将所有的子节点添加到了checkrows中，
        // 勾选的节点也可能是父节点
        // 所以这里需要根据父节点获取子节点，全部对子节点进行操作
        const allCheckNodes = this.getChildrenNodes(selection);
        const childNodes = this.getChildrenNodes([row]);
        // 非全选，按照正常的勾选数量来计算
        if (!this[tableType].isCheckAll) {
          this[tableType].checkedRows = selection;
        } else {
          for (const node of childNodes) {
            // 全选状态下
            // 去勾选，只排除去勾选的数据
            if (!allCheckNodes.includes(node)) {
              const rowPos = this[tableType].checkedRows.findIndex(
                item => item[this.rowKey] === node[this.rowKey]
              );
              this[tableType].checkedRows.splice(rowPos, 1);
            } else {
              // 勾选父节点时，当前父节点下已有已经勾选的子节点时
              // 子节点会被重复添加，所以这边要做去重处理，并删除缓存的未勾选节点
              if (
                !_.some(this[tableType].checkedRows, [
                  this.rowKey,
                  node[this.rowKey]
                ])
              ) {
                this[tableType].checkedRows.push(node);
              }
            }
          }
        }
      }
    },

    /**
     * @Author: zhangxin14
     * @Date: 2018-03-28 10:56:01
     * @Desc: 勾选节点时，联动其子节点的勾选状态
     */
    checkChildNodes(tableRef = 'leftTable', row, isChecked) {
      const { _data, selectable } = this.$refs[tableRef].store.states;
      // fix bug 树表格组件的处理处理后，导致selection中的数据与这边选中后参数中返回的数据不一致，
      // 所以需要从`table`的`store`中取，才能正确设置勾选状态
      // 将子节点设置为勾选状态
      if (row.children) {
        for (const item of row.children) {
          for (const data of _data) {
            // 判断当前行是否是禁用状态
            if (selectable(data) && item[this.rowKey] === data[this.rowKey]) {
              this.$refs[tableRef].toggleRowSelection(data, isChecked);
            }
          }
          if (item.children) {
            this.checkChildNodes(tableRef, item, isChecked);
          }
        }
      }
    },

    /**
     * @Author: zhangxin14
     * @Date: 2018-03-28 10:56:24
     * @Desc: 勾选节点时，联动其父节点的勾选状态
     */
    checkParentNodes(tableRef = 'leftTable', row, selection) {
      const { leftTableCacheData } = this.getCacheTableData();
      // 当前节点所有的兄弟节点数量
      const totalNodes = leftTableCacheData.filter(
        item => item[this.parentKey] === row[this.parentKey]
      ).length;
      // 已经选中的节点数量
      const hasCheckedNodes = selection.filter(
        item => item[this.parentKey] === row[this.parentKey]
      ).length;
      const [statesData] = this.$refs[tableRef].store.states._data.filter(
        item => item[this.rowKey] === row[this.parentKey]
      );
      if (statesData) {
        // 子节点全部勾选后，父节点联动勾选
        if (
          totalNodes !== 0 &&
          hasCheckedNodes !== 0 &&
          totalNodes === hasCheckedNodes
        ) {
          this.$refs[tableRef].toggleRowSelection(statesData, true);
        } else {
          this.$refs[tableRef].toggleRowSelection(statesData, false);
        }
        if (statesData[this.parentKey] !== this.treeNodeId) {
          this.checkParentNodes(
            (tableRef = 'leftTable'),
            statesData,
            selection
          );
        }
      }
    },

    /**
     * @desc: 树表格中，勾选父节点联动选中子节点
     * @date: 2017/12/4 17:34
     * @author: zhangxin14
     * @params:
     */
    checkChildrenNode(selection, row) {
      // 勾父选节点时; 父节点操作时与子节点有联动
      if (selection.indexOf(row) > -1) {
        if (row.$extra && row.$extra.expanded && row.children) {
          this.checkChildNodes('leftTable', row, true);
        }
        this.checkParentNodes('leftTable', row, selection, true);
      }
      // 取消勾选父节点时; 父节点操作时与子节点有联动
      if (selection.indexOf(row) < 0) {
        this.checkChildNodes('leftTable', row, false);
        this.checkParentNodes('leftTable', row, selection, false);
      }
    },

    // 禁用勾选框
    disabledLeftTableCheckbox(row) {
      if (this.isTableTree) {
        const childrenNodes = this.getChildrenNodes([row]);
        return (!row.leaf && childrenNodes.length) || row.leaf;
      }
      return row.type !== LOAD_MORE;
    },

    disabledRightTableCheckbox(row) {
      return row.type !== LOAD_MORE;
    },

    // 获取某个节点下的子节点
    // 存在两种情况：
    // 情况1 `hasExtra = false` : 单纯获取某个节点下的所有子节点，不管改节点是否展开，只要是该节点的子节点都会返回
    // 情况2 `hasExtra = true` : 跟当前节点的展开状态有关，如果改节点是不展开的，和情况1相投，如果是节点展开的，指获取当前节点
    getChildrenNodes(checkedNode = [], hasExtra = false) {
      if (!checkedNode.length) return checkedNode;
      let result = [];
      let i = 0;
      const len = checkedNode.length;
      for (; i < len; i++) {
        const curNode = checkedNode[i];
        if (curNode.leaf) {
          result.push(curNode);
          continue;
        }
        // 展开节点但是不需要包括父节点
        if (hasExtra && curNode.$extra && curNode.$extra.expanded) continue;

        result = curNode.children ? result.concat(curNode.children) : result;
      }
      return result;
    },

    moveToRightOperation(diffNode, rightData) {
      // 将移动前的勾选状态缓存起来
      this.leftTable.checkedRows = [];
      this.leftTable.isCheckAll = false;
      this.getCacheTableData = this.updateData(diffNode, rightData);
      this.filterLeftData();
      this.filterRightData();
      this.$emit('move-right', diffNode, rightData);
    },

    /**
     * @desc: 向右侧表格移动数据，如果数据都做diff处理，性能消耗太大
     * @date: 2017/11/27 17:25
     * @author: zhangxin14
     */
    moveToRight() {
      // 将左侧的子节点中去除将要添加到右侧的节点
      const leftCheckedWithChild = this.isTableTree
        ? this.getChildrenNodes(this.leftTable.checkedRows, true)
        : this.leftTable.checkedRows;
      const {
        leftTableCacheData,
        rightTableCacheData
      } = this.getCacheTableData();
      // 勾选过全选，注意：这边是勾选过全选，ischeckAll就是true，去掉一个后，全选框虽然非勾选，但也是true
      // 只有通过全选框去勾选才isCheckAll的值为false
      this.rightTable.isCheckAll = false;
      const leftRemainNodes = diff(
        leftTableCacheData,
        leftCheckedWithChild,
        this.rowKey
      );
      const shouldMoveToRightNodes = this.isTableTree
        ? leftCheckedWithChild
        : this.leftTable.checkedRows;

      const rightData = this.isTableTree
        ? [...leftCheckedWithChild, ...rightTableCacheData].filter(
            item => item.leaf
          )
        : [...this.leftTable.checkedRows, ...rightTableCacheData];
      this.moveRightAction(
        this.leftTable.checkedRows,
        leftTableCacheData,
        rightTableCacheData
      )
        .then(() => {
          // 操作一定数量之后的数据之后，给予提示
          if (shouldMoveToRightNodes.length > this.loadNum * 2) {
            this.$confirm(
              t('h.tableTransfer.largeDataTip', [this.loadNum * 2]),
              {
                confirmButtonText: t('h.tableTransfer.sure'),
                cancelButtonText: t('h.tableTransfer.cancel'),
                type: 'info'
              }
            ).then(() => {
              this.moveToRightOperation(leftRemainNodes, rightData);
            });
          } else {
            this.moveToRightOperation(leftRemainNodes, rightData);
          }
        })
        .catch(() => {});
    },

    /**
     * @desc: 向左侧表格移动数据
     * @date: 2017/11/27 17:25
     * @author: zhangxin14
     */
    moveToLeft() {
      // 未勾选的数据
      const {
        leftTableCacheData,
        rightTableCacheData
      } = this.getCacheTableData();
      let leftData;
      this.leftTable.isCheckAll = false;

      const rightRemainNodes = diff(
        rightTableCacheData,
        this.rightTable.checkedRows,
        this.rowKey
      );

      // 将右侧移动的子节点和左侧的已存在的子节点合并,右侧移动到左侧时，右侧节点需要属于当前选中的区域
      const belongCurNodeItems = this.rightTable.checkedRows.filter(item => {
        const itemBelongAreas = item[this.belongField];
        const itemBelong =
          typeof itemBelongAreas === 'string'
            ? itemBelongAreas
            : itemBelongAreas[itemBelongAreas.length - 1];
        return this.checked
          ? item[this.belongField].includes(this.treeNodeId)
          : itemBelong === this.treeNodeId;
      });
      this.rightTable.checkedRows = [];
      this.rightTable.isCheckAll = false;
      if (this.isTableTree) {
        // 根据子节点找出父节点
        // 如果左侧数据中已有父节点则不需要再加过去了
        leftData = this.findRootNode(this.leftTableData, [
          ...belongCurNodeItems,
          ...leftTableCacheData
        ]);
      } else {
        leftData = [...belongCurNodeItems, ...leftTableCacheData];
      }
      this.moveLeftAction(
        belongCurNodeItems,
        leftTableCacheData,
        rightTableCacheData
      )
        .then(() => {
          // 重新渲染两个表格的数据
          this.getCacheTableData = this.updateData(leftData, rightRemainNodes);
          this.filterLeftData();
          this.filterRightData();
          this.$emit('move-left', leftData, rightRemainNodes);
        })
        .catch(() => {});
    },

    /**
     * @Author: xiangxiao3
     * @Date: 2020-09-07 20:21:08
     * @Desc: 更新更多按钮的样式
     */
    updateLoadMoreStyle() {
      const TR_SELECTOR = '.el-table tbody tr:last-child';
      const { _data } = this.$refs.leftTable.store.states;
      const loadMoreTrElem = document.querySelectorAll(TR_SELECTOR);
      const loadMoreText = t('h.tableTransfer.loadMore');

      this.isShowLeftTip = _data.length > this.loadNum * 2;
      // 加载更多样式
      // 不显示checkbox，且合并的单元格需要居中显示，且需要是手型
      Array.from(loadMoreTrElem).map(node => {
        if (node.innerText.includes(loadMoreText)) {
          node.childNodes[0].style.paddingRight = this.isTableTree
            ? '72px'
            : '48px';
          node.style.cursor = 'pointer';
          node.style.textAlign = 'center';
        }
      });
    },
    /**
     * @Author: xiangxiao3
     * @Date: 2020-09-11 17:49:27
     * @Desc:  更多文字居中处理
     */
    cellClass({ row, column, rowIndex, columnIndex }) {
      if (row.label === t('h.tableTransfer.loadMore')) {
        return {
          textAlign: 'center'
        };
      }
    }
  }
};
</script>
