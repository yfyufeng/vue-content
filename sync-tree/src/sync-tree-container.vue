<template>
  <div class="sync-tree-container">
    <div v-if="showSearchInput" class="sync-tree-search">
      <!-- 搜索框 -->
      <el-input
        v-model="treeSearchText"
        :placeholder="searchInputText"
        :clear-icon-click="clearSearchTreeAction"
        :maxlength="maxlength"
        clearable
        @keyup.enter.native="searchTreeAction"
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
        />
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
        />
      </div>
      <div :class="{ 'show-tips': showTips }" class="sync-tree-content">
        <slot></slot>
      </div>
    </div>
  </div>
</template>

<script>
/**
 * @author: xuzilong
 * @desc: 异步树的外层容器，用于放一些提示和输入框
 */
export default {
  name: 'SyncTreeContainer',
  props: {
    loading: {
      type: Boolean,
      default: false
    },
    nodeLimit: {
      type: Number,
      default: 1000
    },
    searchLimit: {
      type: Number,
      default: 500
    },
    mode: {
      type: String,
      default: 'init'
    },
    nodeLimitAlert: {
      type: String,
      default: ''
    },
    searchLimitAlert: {
      type: String,
      default: ''
    },
    searchInputText: {
      type: String,
      default: ''
    },
    count: {
      type: Number,
      default: 0
    },
    searchCount: {
      type: Number,
      default: 0
    },
    beforeSearch: {
      type: Function,
      default: null
    },
    maxlength: {
      type: Number,
      default: null
    },
    showSearchInput: {
      type: Boolean,
      default: true
    }
  },
  data() {
    return {
      treeSearchText: ''
    };
  },
  computed: {
    // 是否展示tips
    showTips() {
      return (
        (this.count > this.nodeLimit && this.mode === 'init') ||
        (this.searchCount >= this.searchLimit && this.mode === 'search')
      );
    }
  },
  watch: {
    treeSearchText(val) {
      this.$emit('update:treeSearch', val);
    }
  },
  methods: {
    clearSearchTreeAction() {
      this.treeSearchText = '';
      this.searchTreeAction();

      this.$emit('clear-search-tree');
    },
    searchTreeAction() {
      if (this.beforeSearch && !this.beforeSearch(this.treeSearchText))
        return false;

      if (this.treeSearchText.trim() !== '') {
        this.$emit('handler-search', this.treeSearchText);
      } else {
        this.$emit('handler-init', '');
      }
    }
  }
};
</script>
