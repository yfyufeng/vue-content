<template>
  <el-tooltip
    ref="tooltip"
    :disabled="!showTooltip"
    :manual="true"
    placement="top"
    popper-class="h-plan__drag-handle--tooltip"
  >
    <span slot="content">{{ formatValue }}</span>
    <div
      :class="'h-plan__drag-handle ' + 'h-plan__drag-handle--' + align"
      @mousedown="handleMouseDown"
    ></div>
  </el-tooltip>
</template>

<script>
import { pixelToSecond, secondToPixel, timeFormat } from './util.js';
export default {
  props: {
    value: {
      type: Number,
      default: undefined
    },
    active: {
      type: Boolean,
      default: false
    },
    align: {
      type: String,
      default: undefined
    }
  },

  data() {
    return {
      dragging: false,
      start: 0,
      current: 0,
      startPosition: 0
    };
  },

  computed: {
    showTooltip() {
      return this.$parent.$parent.$parent.showTooltip;
    },

    panelWidth() {
      return this.$parent.panelWidth;
    },

    step() {
      return this.$parent.step;
    },

    min() {
      return this.$parent.limitRange[0];
    },

    max() {
      return this.$parent.limitRange[1];
    },

    formatValue() {
      return timeFormat(this.value);
    }
  },

  updated() {
    this.active && this.$refs.tooltip && this.$refs.tooltip.updatePopper();
  },

  methods: {
    displayTooltip() {
      this.$refs.tooltip.showPopper = true;
    },

    hideTooltip() {
      this.$refs.tooltip.showPopper = false;
    },

    handleMouseDown(event) {
      event.cancelBubble = true;
      event.preventDefault();
      this.onDragStart(event);
      window.addEventListener('mousemove', this.onDragging);
      window.addEventListener('mouseup', this.onDragEnd);
      window.addEventListener('contextmenu', this.onDragEnd);
    },

    onDragStart(event) {
      this.dragging = true;
      this.start = event.clientX;
      this.startPosition = secondToPixel(this.value, this.panelWidth);
      this.$emit('dragStart');
    },

    onDragging(event) {
      if (this.dragging) {
        this.current = event.clientX;
        this.setPosition(this.startPosition + this.current - this.start);
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
          this.$emit('dragEnd');
        }, 0);
        window.removeEventListener('mousemove', this.onDragging);
        window.removeEventListener('mouseup', this.onDragEnd);
        window.removeEventListener('contextmenu', this.onDragEnd);
      }
    },

    setPosition(position) {
      let value = pixelToSecond(position, this.panelWidth);
      const steps = Math.round(value / this.step);
      value = steps * this.step;
      value = value > this.max ? this.max : value;
      value = value < this.min ? this.min : value;
      this.$emit('input', value);
    }
  }
};
</script>
