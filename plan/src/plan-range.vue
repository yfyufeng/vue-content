<template>
  <div :style="rangeStyle" class="h-plan__range-wrap">
    <el-popover
      ref="popover"
      :value="isShowPopover"
      :disabled="!showPopover"
      :width="popoverWidth"
      :popper-class="disabled ? 'h-plan__popover--dark' : ''"
      placement="top"
      trigger="manual"
      @show="handlePopoverShow"
      @hide="handlePopoverHide"
    >
      <template v-if="$slots.popover">
        <slot :index="index" name="popover" />
      </template>
      <div v-if="!disabled && !$slots.popover" class="h-plan__popover">
        <div class="h-plan__popover--time">
          <el-time-picker
            ref="startTime"
            v-model="startTime"
            :editable="false"
            :clearable="false"
            :picker-options="pickerOptions"
            :unlink="planGroup.timepickerUnlink"
            format="HH:mm"
          />
          <span class="h-plan__popover--dividing" />
          <el-time-picker
            ref="endTime"
            v-model="endTime"
            :editable="false"
            :clearable="false"
            :picker-options="pickerOptions"
            :unlink="planGroup.timepickerUnlink"
            format="HH:mm"
          />
        </div>
        <div class="h-plan__popover--action">
          <el-button
            size="mini"
            type="link"
            :disabled="startTime >= endTime"
            @click="save"
          >
            {{ t('h.plan.save') }}
          </el-button>
          <el-button size="mini" type="text" @click="destroy">
            {{ t('h.plan.delete') }}
          </el-button>
        </div>
      </div>
      <div v-if="disabled && !$slots.popover" style="text-align:center;">
        {{ parseTime(startTime) }} - {{ parseTime(endTime) }}
      </div>
    </el-popover>
    <div
      v-popover:popover
      :class="['h-plan__range', isActive ? 'is-active' : '', customClass]"
      :style="{ 'background-color': customColor }"
      @mousedown="handleMouseDown"
      @mouseenter="handleMouseEnter"
      @mouseleave="handleMouseLeave"
    >
      <span v-if="showText" ref="planText" class="h-plan__text">
        {{ value.text }}
      </span>
      <drag-handle
        v-if="!disabled"
        ref="firstDragHandle"
        v-model="value.from"
        :align="firstAlign"
        :active="isActive"
        @dragStart="handleDragStart"
        @dragEnd="handleDragEnd"
      />
      <drag-handle
        v-if="!disabled"
        ref="secondDragHandle"
        v-model="value.to"
        :align="secondAlign"
        :active="isActive"
        @dragStart="handleDragStart"
        @dragEnd="handleDragEnd"
      />
    </div>
  </div>
</template>

<script>
import { merge, closest, dispatch } from '@hui-pro/utils';
import DragHandle from './plan-range-draghandle.vue';
import { t } from '@hui-pro/locale';

import {
  pixelToSecond,
  secondToPixel,
  timeFormat,
  timeToSecond,
  secondToDate,
  second2Value
} from './util.js';

export default {
  name: 'PlanRange',
  inject: ['planGroup', 'plan'],
  components: {
    DragHandle
  },
  props: {
    index: {
      type: Number,
      default() {
        return 0;
      }
    },
    value: {
      type: Object,
      default() {
        return {};
      }
    },
    limitRange: {
      type: Array,
      default() {
        return [];
      }
    }
  },
  data() {
    return {
      t,
      isActive: false,
      dragging: false,
      handleDragging: false,
      startX: null,
      currentX: null,
      startMinValue: null,
      startMaxValue: null,
      startTime: null,
      endTime: null,
      clickOnTime: false
    };
  },
  computed: {
    // 是否显示文字
    showText() {
      if (this.value.text) {
        // 宽度小于70就不显示文字
        return this.rangeWidth > 70;
      } else {
        return false;
      }
    },
    disabled() {
      if (this.plan.disabled !== undefined) return this.plan.disabled;
      return this.planGroup.disabled;
    },

    panelWidth() {
      // 计划模板左右各有一个像素的边框，这里减去两个像素
      return this.$parent.$parent.panelWidth - 2;
    },

    popoverWidth() {
      return this.disabled ? 120 : 244;
    },

    isShowPopover() {
      return this.isActive && !this.dragging && !this.handleDragging;
    },

    showPopover() {
      return this.$parent.$parent.showPopover;
    },

    rangeStyle() {
      return {
        width: this.rangeWidth + 'px',
        left: this.rangeLeft + 'px',
        cursor: this.handleDragging ? 'e-resize' : 'pointer'
      };
    },

    rangeWidth() {
      const width = secondToPixel(
        this.maxValue - this.minValue,
        this.panelWidth
      );
      return Math.floor(width);
    },

    rangeLeft() {
      let left = secondToPixel(this.minValue, this.panelWidth);
      // 最小值不允许出现负数
      if (left < 0) left = 0;
      return left;
    },

    minValue() {
      let min = Math.min(this.value.from, this.value.to);
      if (min % 10 !== 0) min -= 59;
      return min;
    },

    maxValue() {
      let max = Math.max(this.value.from, this.value.to);
      if (max % 10 !== 0) max -= 59;
      return max;
    },

    firstAlign() {
      return this.value.from < this.value.to ? 'left' : 'right';
    },

    secondAlign() {
      return this.firstAlign === 'left' ? 'right' : 'left';
    },

    step() {
      return this.$parent.step;
    },

    customClass() {
      const customRangeClass = this.$parent.$parent.customRangeClass || {};
      return customRangeClass[this.value.type] || '';
    },

    // 时间段颜色
    customColor() {
      const customRangeColor = this.$parent.$parent.customRangeColor || {};
      return customRangeColor[this.value.type] || '';
    },

    pickerOptions() {
      const startTime = timeFormat(this.limitRange[0]);
      const endTime = timeFormat(this.limitRange[1]);
      return {
        selectableRange: `${startTime}:00 - ${endTime}:00`
      };
    }
  },
  watch: {
    // 监听disabled属性，为true时绑定点击事件，点击后关闭popover
    disabled(val) {
      !val
        ? document.addEventListener('click', this.handleCancel)
        : document.removeEventListener('click', this.handleCancel);
    },

    minValue(val) {
      this.startTime = secondToDate(val);
    },

    maxValue(val) {
      this.endTime = secondToDate(val);
    }
  },
  created() {
    if (typeof window !== 'undefined') {
      !this.disabled && document.addEventListener('click', this.handleCancel);
      document.addEventListener('mousedown', this.handleMousedown);
      document.addEventListener('mouseup', this.handleMouseup);
    }
  },

  destroyed() {
    if (typeof window !== 'undefined') {
      document.removeEventListener('click', this.handleCancel);
    }
  },

  updated() {
    this.isActive && this.$refs.popover && this.$refs.popover.updatePopper();
  },
  mounted() {
    // 监听plan控件hover事件
    this.$on('hidePopver', this.hidePopver);
  },
  methods: {
    // 隐藏popver
    hidePopver() {
      this.$refs.popover.doClose();
    },
    // 返回这一行的第几个时间条信息
    handlePopoverShow() {
      if (this.isActive) {
        // 给当前列到plan里
        this.$emit('setCol', this.index);
      }
      this.startTime = secondToDate(this.value.from);
      this.endTime = secondToDate(this.value.to);
    },

    handlePopoverHide() {
      // 移除 popover 的同时隐藏开始时间和结束时间下拉框
      if (this.$refs.startTime) this.$refs.startTime.pickerVisible = false;
      if (this.$refs.endTime) this.$refs.endTime.pickerVisible = false;
    },

    parseTime(val) {
      return timeFormat(timeToSecond(val));
    },

    // 键盘删除事件
    keyHandle(val) {
      if (typeof window !== 'undefined') {
        if (val) {
          document.addEventListener('keyup', this.handleKeyUp);
        } else {
          document.removeEventListener('keyup', this.handleKeyUp);
        }
      }
    },

    startHandleDrag(val) {
      this.isActive = true;
      this.handleDragging = true;
      this.displayTooltip();
      this.$refs.secondDragHandle.setPosition(val);
    },

    stopHandleDrag() {
      this.handleDragging = false;
      this.isActive = true;
    },

    handleKeyUp(event) {
      if (event.keyCode === 8 || event.keyCode === 46) {
        this.destroy();
      }
    },

    handleCancel() {
      if (!this.dragging && !this.handleDragging && !this.clickOnTime) {
        this.isActive = false;
      }
      this.clickOnTime = false;
    },

    handleMousedown(event) {
      if (closest(event.target, '.el-time-panel')) {
        this.clickOnTime = true;
      }
    },

    handleMouseup(event) {
      if (closest(event.target, '.el-time-panel')) {
        this.clickOnTime = true;
      }
    },

    handleDragStart() {
      this.displayTooltip();
      this.handleDragging = true;
      dispatch(this, 'PlanTimebar', 'handle-drag-start');
    },

    handleDragEnd() {
      const { value } = this;
      this.hideTooltip();
      this.handleDragging = false;
      // to的值会加59，只要保证他们只在1分钟以内，就是相同的时间
      if (Math.abs(value.to - value.from) < 60) {
        this.$emit('destroy');
      } else if (value.from > value.to) {
        const temp = value.from;
        value.from = value.to;
        value.to = temp;
        // 移除左侧值的59秒
        if (value.from % 10 !== 0) value.from -= 59;
        this.$emit('input', {
          from: value.from,
          to: second2Value(value.to),
          type: value.type
        });
      }
      dispatch(this, 'PlanTimebar', 'handle-drag-end');
    },

    displayTooltip() {
      this.$refs.firstDragHandle && this.$refs.firstDragHandle.displayTooltip();
      this.$refs.secondDragHandle &&
        this.$refs.secondDragHandle.displayTooltip();
    },

    hideTooltip() {
      this.$refs.firstDragHandle && this.$refs.firstDragHandle.hideTooltip();
      this.$refs.secondDragHandle && this.$refs.secondDragHandle.hideTooltip();
    },

    handleMouseEnter() {
      if (this.disabled) {
        this.isActive = true;
      }
    },

    handleMouseLeave() {
      if (this.disabled) {
        this.isActive = false;
      }
    },

    handleMouseDown(event) {
      this.isActive = true;
      event.preventDefault();
      event.cancelBubble = true;
      if (!this.disabled) {
        this.onDragStart(event);
        document.addEventListener('mousemove', this.onDragging);
        document.addEventListener('mouseup', this.onDragEnd);
        document.addEventListener('contextmenu', this.onDragEnd);
      }
    },

    onDragStart() {
      this.dragging = true;
      this.startX = event.clientX;
      this.startMinValue = this.minValue;
      this.startMaxValue = this.maxValue;
    },

    onDragging(event) {
      if (this.dragging) {
        this.currentX = event.clientX;
        this.setPosition();
      }
    },

    onDragEnd() {
      if (this.dragging) {
        /*
         * 防止在 mouseup 后立即触发 click，导致滑块有几率产生一小段位移
         * 不使用 preventDefault 是因为 mouseup 和 click 没有注册在同一个 DOM 上
         */
        setTimeout(() => {
          this.dragging = false;
        }, 0);

        this.hideTooltip();

        document.removeEventListener('mousemove', this.onDragging);
        document.removeEventListener('mouseup', this.onDragEnd);
        document.removeEventListener('contextmenu', this.onDragEnd);
      }
    },

    setPosition() {
      let diff = pixelToSecond(this.currentX - this.startX, this.panelWidth);
      const steps = Math.round(diff / this.step);
      const { startMinValue, startMaxValue, limitRange } = this;

      diff = steps * this.step;
      diff =
        startMinValue + diff < limitRange[0]
          ? limitRange[0] - startMinValue
          : diff;
      diff =
        startMaxValue + diff > limitRange[1]
          ? limitRange[1] - startMaxValue
          : diff;
      if (startMinValue !== startMaxValue) {
        this.$emit(
          'input',
          merge(this.value, {
            from: startMinValue + diff,
            to: second2Value(startMaxValue + diff)
          })
        );
      }
      if (!diff) return;
      this.displayTooltip();
    },

    save() {
      const { startTime, endTime, limitRange } = this;
      if (!startTime || !endTime) return;
      const time1 = timeToSecond(startTime);
      const time2 = timeToSecond(endTime);
      if (time1 < time2) {
        this.$emit(
          'input',
          merge(this.value, {
            from: Math.max(time1, limitRange[0]),
            to: second2Value(Math.min(time2, limitRange[1]))
          })
        );
      } else {
        // 时间大小判断错误
        this.$emit('timeerror');
      }
      this.isActive = false;
    },

    destroy() {
      this.isActive = false;
      this.$emit('destroy');
    }
  }
};
</script>
