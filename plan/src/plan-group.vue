<template>
  <div
    class="h-plan-group"
    @mouseover="handleMouseOver"
    @mouseleave="handleMouseLeave"
  >
    <!-- 面板/画线 -->
    <div
      :class="{ 'h-plan__point-panel-wrap': type === 'point' }"
      :style="timelineStyle"
      class="h-plan-group__panel-wrap"
    >
      <div class="h-plan-group__panel">
        <template v-for="(item, index) in interval">
          <div :key="index" class="h-plan-group__tickline"></div>
        </template>
      </div>
    </div>
    <!-- 时间轴 -->
    <div :style="timelineStyle" class="h-plan-group__timeline-wrap">
      <!-- 计划模板左侧放置标签，须自定义 -->
      <div v-if="$slots.label" :style="labelStyle" class="h-plan-group__label">
        <slot name="label"></slot>
      </div>
      <!-- 计划模板右侧放置操作按钮，须自定义 -->
      <div
        v-if="$slots.action"
        :style="actionStyle"
        class="h-plan-group__action"
      >
        <slot name="action"></slot>
      </div>
      <ul class="h-plan-group__timeline">
        <template v-for="(item, index) in interval">
          <li v-if="index % 2 === 0" :key="index" class="h-plan-group__scale">
            <span class="h-plan-group__scale-label">
              {{ (Array(2).join('0') + index).slice(-2) }}
            </span>
            <span
              v-if="index + 2 === interval"
              class="h-plan-group__scale-label h-plan-group__scale-label--last"
            >
              {{ (Array(2).join('0') + (index + 2)).slice(-2) }}
            </span>
          </li>
        </template>
      </ul>
    </div>
    <!-- 计划hover效果 -->
    <div
      v-show="showPlanHover"
      :style="{
        top: planHoverTop + 'px',
        right: parseInt(actionWidth) + 'px',
        height: planHoverHeight + 'px'
      }"
      class="h-plan-group__hover"
    ></div>
    <!-- 计划组 -->
    <el-scrollbar
      v-if="maxHeight"
      :wrap-style="`max-height: ${parseInt(maxHeight) - 25}px;`"
      @on-scrolling="handleScroll"
    >
      <slot></slot>
    </el-scrollbar>
    <slot v-else></slot>
  </div>
</template>

<script>
import { throttle, on, off, offset, closest } from '@hui-pro/utils';
export default {
  name: 'HPlanGroup',
  provide() {
    return {
      planGroup: this
    };
  },
  props: {
    // 控件类型，'range': 时间段  'point': 时间点
    type: {
      type: String,
      default: 'range'
    },
    labelWidth: {
      type: String,
      default: '0'
    },
    actionWidth: {
      type: String,
      default: '0'
    },
    fit: {
      type: Boolean,
      default: true
    },
    disabled: {
      type: Boolean,
      default: undefined
    },
    // 最大高度，设置后会自动加载滚动条控件
    maxHeight: {
      type: [String, Number],
      default: undefined
    },
    // HUI 时间选择器 unlink 属性
    timepickerUnlink: {
      type: Boolean,
      default: false
    }
  },

  data() {
    return {
      interval: 24, // 时间轴划分多少大格
      panelWidth: 0,
      showPlanHover: false,
      planHoverTop: 25, // hover 元素 top 值
      planHoverHeight: 40, // hover 元素高度
      scrollTimer: null // 滚动计时器
    };
  },

  computed: {
    timelineStyle() {
      return {
        paddingLeft: parseInt(this.labelWidth) + 'px',
        paddingRight: parseInt(this.actionWidth) + 'px'
      };
    },
    labelStyle() {
      const labelWidth = this.labelWidth;
      return labelWidth
        ? {
            width: parseInt(labelWidth) + 'px'
          }
        : null;
    },
    actionStyle() {
      const actionWidth = this.actionWidth;
      return actionWidth
        ? {
            width: parseInt(actionWidth) + 'px'
          }
        : null;
    }
  },

  mounted() {
    this.setWidth();
    this.bindEvents();
    this.$ready = true;
    // 监听plan控件hover事件
    this.$on('plan-hover', this.handleHoverPlan);
  },

  destroyed() {
    // 组件销毁，一并移除绑定的resize事件
    if (this.windowResizeListener)
      off(this.$el, 'resize', this.windowResizeListener);
  },

  methods: {
    // 计算元素宽度
    setWidth() {
      this.panelWidth = this.$el.clientWidth
        ? this.$el.clientWidth -
          parseInt(this.labelWidth) -
          parseInt(this.actionWidth)
        : 0;
    },

    // 绑定窗口resize事件
    bindEvents() {
      if (this.fit) {
        // throttle可避免窗口变化时，执行太多次回调函数
        this.windowResizeListener = throttle(() => {
          if (this.$ready) this.setWidth();
        }, 50);
        on(this.$el, 'resize', this.windowResizeListener);
      }
    },

    handleMouseOver(event) {
      if (this.disabled) return;
      if (
        closest(event.target, '.h-plan:not(.is-disabled)') !== null &&
        closest(event.target, '.h-plan__action') === null
      ) {
        this.showPlanHover = true;
      } else {
        this.showPlanHover = false;
      }
    },

    handleMouseLeave() {
      this.showPlanHover = false;
    },

    handleHoverPlan($plan) {
      const { top } = offset($plan, this.$el);
      if (top > 25) {
        this.planHoverTop = top;
        this.planHoverHeight = 40;
      } else {
        this.planHoverTop = 25;
        this.planHoverHeight = 40 - (25 - top);
      }
    },

    /**
     * @author chenguanbin
     * @date 2019-09-19 18:40:50
     * @desc 滚动条滚动事件
     * @param {Number} scrollTop 滚动距离
     */
    handleScroll({ scrollTop }) {
      this.showPlanHover = false;
      this._setScrollTimer();
    },

    /**
     * @author chenguanbin
     * @date 2019-09-19 18:41:43
     * @desc 滚动计时器
     */
    _setScrollTimer() {
      clearTimeout(this.scrollTimer);
      this.scrollTimer = setTimeout(() => {
        this.showPlanHover = true;
      }, 100);
    }
  }
};
</script>
