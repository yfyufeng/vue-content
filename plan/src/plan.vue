<template>
  <div
    :class="{
      'is-disabled': disabled,
      'h-point-plan': planGroup.type === 'point'
    }"
    :style="planStyle"
    class="h-plan"
    @mouseenter="handleMouseEnter"
    @mouseleave="handleMouseLeave"
  >
    <!-- 计划模板左侧放置标签，须自定义 -->
    <div
      :style="labelStyle"
      :title="labelTitle"
      class="h-plan__label"
      @mouseenter="hoverLabel"
    >
      <slot name="label"></slot>
    </div>
    <!-- 计划模板右侧放置操作按钮，须自定义 -->
    <div :style="actionStyle" class="h-plan__action">
      <transition name="el-fade-in-linear">
        <div v-if="!disabled" class="h-plan__action-btns">
          <slot name="action"></slot>
        </div>
      </transition>
    </div>
    <!-- 时间轴面板 -->
    <timebar v-model="value" @timeerror="timeerror" @setCol="setCol">
      <template v-if="$slots.popover" slot="popover">
        <slot name="popover" />
      </template>
    </timebar>
  </div>
</template>

<script>
import Timebar from './plan-timebar.vue';
import { dispatch, broadcast } from '@hui-pro/utils';
export default {
  name: 'HPlan',
  inject: ['planGroup'],
  provide() {
    return {
      plan: this
    };
  },

  components: {
    Timebar
  },

  props: {
    value: {
      type: Array,
      default() {
        return [];
      }
    },
    labelWidth: {
      type: String,
      default: ''
    },
    actionWidth: {
      type: String,
      default: ''
    },
    disabled: {
      type: Boolean,
      default: undefined
    },
    step: {
      type: Number,
      default: 15
    },
    pointStep: {
      type: Number,
      default: 15
    },
    showTooltip: {
      type: Boolean,
      default: true
    },
    showPopover: {
      type: Boolean,
      default: true
    },
    customRangeClass: {
      type: Object,
      default() {
        return {};
      }
    },
    customRangeColor: {
      type: Object,
      default() {
        return {};
      }
    },
    currentType: {
      type: [Number, String],
      default: undefined
    },
    maxRangeCount: {
      type: Number,
      default: undefined
    }
  },

  data() {
    return {
      labelTitle: '',
      result: [],
      activeCol: 0
    };
  },

  computed: {
    planStyle() {
      const labelWidth = this.labelWidth || this.planGroup.labelWidth;
      const actionWidth = this.actionWidth || this.planGroup.actionWidth;
      return {
        paddingLeft: labelWidth ? parseInt(labelWidth) + 'px' : 0,
        paddingRight: actionWidth ? parseInt(actionWidth) + 'px' : 0
      };
    },

    panelWidth() {
      return this.planGroup.panelWidth;
    },

    labelStyle() {
      const labelWidth = this.labelWidth || this.planGroup.labelWidth;
      return labelWidth
        ? {
            width: parseInt(labelWidth) + 'px'
          }
        : null;
    },

    actionStyle() {
      const actionWidth = this.actionWidth || this.planGroup.actionWidth;
      return actionWidth
        ? {
            width: parseInt(actionWidth) + 'px'
          }
        : null;
    }
  },
  methods: {
    hidePopver() {
      broadcast(this, 'PlanRange', 'hidePopver');
    },
    setCol(col) {
      this.activeCol = col;
      this.$emit('focus', col);
    },
    handleMouseEnter(event) {
      this.$emit('mouseenter', event);
      dispatch(this, 'HPlanGroup', 'plan-hover', this.$el);
    },

    hoverLabel(event) {
      const t = event.target;
      this.labelTitle = t.scrollWidth > t.offsetWidth ? t.innerText : '';
    },

    /**
     * @Author: xiangxiao3
     * @Date: 2018-06-20 17:35:16
     * @Desc: 填写时间错误
     */
    timeerror() {
      this.$emit('timeerror');
    },

    handleMouseLeave(event) {
      this.$emit('mouseleave', event);
    }
  }
};
</script>
