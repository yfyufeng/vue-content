<template>
  <div
    :style="style"
    class="h-plan__wrapper"
    @mousedown="handleMouseDown"
    @mousemove="handleMouseMove"
    @mouseleave="handleMouseLeave"
  >
    <!-- 时间段 -->
    <template v-if="planGroup.type === 'range'">
      <range
        v-for="(item, index) in value"
        :key="index"
        :ref="`range${index}`"
        v-model="value[index]"
        :index="index"
        :limit-range="getLimitRange(index)"
        @destroy="removeRange(index)"
        @timeerror="timeerror"
        @setCol="setCol"
      >
        <template v-if="$slots.popover" slot="popover">
          <slot name="popover" />
        </template>
      </range>
    </template>
    <!-- 时间点 -->
    <template v-if="planGroup.type === 'point'">
      <el-popover
        ref="popover"
        :value="isShowPopover"
        :width="80"
        placement="top"
        trigger="manual"
        popper-class="h-plan__popover--dark h-plan__popover--point"
      >
        {{ cursorTime }}
      </el-popover>
      <div
        v-popover:popover
        :style="{ left: `${cursors[cursorIndex]}px` }"
        class="h-plan__point-cursor"
      ></div>
      <point
        v-for="(item, index) in value"
        :key="index"
        :ref="`point${index}`"
        v-model="value[index]"
        @updateActivePoint="updateActivePoint"
        @dragging="dragPoint"
        @destroy="removeRange(index)"
      ></point>
    </template>
  </div>
</template>

<script>
import { throttle, offset } from '@hui-pro/utils';
import Range from './plan-range.vue';
import Point from './plan-point.vue';
import { pixelToSecond, timeFormat, second2Value } from './util.js';

export default {
  name: 'PlanTimebar',
  inject: ['planGroup', 'plan'],
  components: {
    Range,
    Point
  },
  props: {
    value: {
      type: Array,
      default() {
        return [];
      }
    }
  },
  data() {
    return {
      drawing: false,
      startX: null,
      startOffsetX: null,
      currentOffsetX: null,
      handleDragging: false,
      wrapperOffset: {}, // 当前模板相对于屏幕左上角的距离
      cursors: [], // 所有光标的集合，以 15 分钟为一个跨度
      cursorAmount: 96, // 所有光标的数量，共 96 个
      cursorIndex: -1, // 当前鼠标所在位置，在 cursors 中对应的编号
      points: [], // 时间点的集合，以 5 分钟为一个跨度
      pointAmount: 288, // 所有时间点的数量，共 288 个
      intervalSecond: 900, // 时间间隔为 15 分钟，就是 900 秒
      isShowPopover: false, // 是否显示 popover
      pointTimer: null, // 计时器，鼠标在停止移动 300ms 后显示 popover
      activePoint: -1, // 当前激活的时间点，主要给 plan-point 控件使用
      pointDraging: false // 是否正在拖拽时间点
    };
  },
  computed: {
    style() {
      const labelWidth = this.planGroup.labelWidth || this.plan.labelWidth;
      const actionWidth = this.planGroup.actionWidth || this.plan.actionWidth;
      return {
        left: labelWidth || 0,
        right: actionWidth || 0,
        cursor: this.handleDragging ? 'e-resize' : 'pointer'
      };
    },

    // 是否禁用编辑
    disabled() {
      if (this.plan.disabled !== undefined) return this.plan.disabled;
      return this.planGroup.disabled;
    },

    // 排序后的数据副本拷贝，计算范围限制用到
    sortData() {
      const dataCopy = JSON.parse(JSON.stringify(this.value));
      return dataCopy.sort((item1, item2) => {
        return item1.from - item2.from;
      });
    },

    // 时间轴像素长度
    panelWidth() {
      return this.plan.panelWidth;
    },

    // 步距配置项以分钟为单位，须转换为秒进行计算
    step() {
      return this.plan.step * 60;
    },

    currentType() {
      return this.plan.currentType;
    },

    maxRangeCount() {
      return this.plan.maxRangeCount;
    },

    // 鼠标移动到时间点时，显示的时间
    cursorTime() {
      if (this.cursorIndex === -1) return ' ';
      return timeFormat(this.cursorIndex * this.intervalSecond);
    }
  },

  watch: {
    // 监控控件宽度变化，变化后实时改变点集合的数值
    panelWidth(newVal) {
      if (this.planGroup.type !== 'point' || newVal <= 0) return;

      // 获取光标集合的值
      const cursors = [];
      for (let i = 0; i < this.cursorAmount; i++) {
        cursors.push(newVal * (i / this.cursorAmount));
      }
      this.cursors = cursors;

      // 获取时间点集合的值
      const points = [];
      for (let i = 0; i < this.pointAmount; i++) {
        points.push(newVal * (i / this.pointAmount));
      }
      this.points = points;

      // 解决时间点模板默认隐藏情况下，hover 和点击错位的问题
      this.wrapperOffset = offset(this.$el);
    },

    // 监控鼠标位置的变化
    cursorIndex() {
      this.isShowPopover = false;
      clearTimeout(this.pointTimer);
      this.pointTimer = setTimeout(() => {
        if (this.cursorIndex !== -1) {
          this.isShowPopover = true;
        }
      }, 300);
    }
  },
  mounted() {
    // 获取当前模板相对于屏幕左上角的距离
    this.wrapperOffset = offset(this.$el);
    // 拖动边框，改变时间轴大小时，改变鼠标的手势
    this.$on('handle-drag-start', () => {
      this.handleDragging = true;
    });
    this.$on('handle-drag-end', () => {
      this.handleDragging = false;
    });
  },

  methods: {
    // 删除时段
    removeRange(index) {
      this.value.splice(index, 1);
    },

    /**
     * @Author: xiangxiao3
     * @Date: 2018-06-20 17:34:43
     * @Desc: 填写时间错误
     */
    timeerror() {
      this.$emit('timeerror');
    },
    setCol(col) {
      this.$emit('setCol', col);
    },
    // 计算时段的大小范围限制
    getLimitRange(i) {
      const limitRange = [];
      this.sortData.forEach((item, index) => {
        if (this.value[i].from === item.from) {
          limitRange.push(index > 0 ? this.sortData[index - 1].to : 0);
          limitRange.push(
            this.sortData[index + 1] ? this.sortData[index + 1].from : 86400
          );
        }
      });
      return limitRange;
    },

    handleMouseDown(event) {
      event.preventDefault();
      if (this.disabled) return;
      if (event.target.className === 'h-plan__range-wrap') return;
      // 判断是事件段还是时间点
      if (this.planGroup.type === 'range') {
        if (
          (this.maxRangeCount && this.value.length < this.maxRangeCount) ||
          !this.maxRangeCount
        ) {
          this.onDrawStart(event);
          window.addEventListener('mousemove', this.onDrawing);
          window.addEventListener('mouseup', this.onDrawEnd);
          window.addEventListener('contextmenu', this.onDrawEnd);
        }
      } else if (this.planGroup.type === 'point') {
        // 点击的位置不在 15 分钟的间距上，或者点击的位置已经存在时间点
        if (this.cursorIndex === -1 || this.isExistPoint(this.cursorIndex))
          return;
        this.value.push({
          type: this.currentType,
          point: this.cursorIndex * this.intervalSecond
        });
      }
    },

    onDrawStart(event) {
      this.drawing = true;
      this.startX = event.clientX;
      this.startOffsetX = this.currentOffsetX = event.offsetX;
      let startValue =
        Math.round(
          pixelToSecond(this.currentOffsetX, this.panelWidth) / this.step
        ) * this.step;
      // 解决几个像素的偏差缺陷，现象是点击在计划模板之外的区域可能会成功绘制模板
      if (startValue < 0) startValue = 0;
      if (startValue > 86400) startValue = 86400;
      this.value.push({
        type: this.currentType,
        from: startValue,
        to: second2Value(startValue)
      });
    },

    onDrawing(event) {
      if (this.drawing) {
        const last = this.value.length - 1;
        this.currentOffsetX = event.clientX - this.startX + this.startOffsetX;
        const $newRange = this.$refs['range' + last];
        $newRange && $newRange[0].startHandleDrag(this.currentOffsetX);
      }
    },

    onDrawEnd() {
      if (this.drawing) {
        /*
         * 防止在 mouseup 后立即触发 click，导致滑块有几率产生一小段位移
         * 不使用 preventDefault 是因为 mouseup 和 click 没有注册在同一个 DOM 上
         */
        setTimeout(() => {
          this.drawing = false;
          const $newRange = this.$refs['range' + last];
          $newRange && $newRange[0] && $newRange[0].hideTooltip();
          $newRange && $newRange[0] && $newRange[0].stopHandleDrag();
        }, 0);
        const last = this.value.length - 1;
        const newValue = this.value[last];
        if (Math.abs(newValue.to - newValue.from) < 60) {
          this.value.pop();
        } else if (newValue.from > newValue.to) {
          const transfer = newValue.from;
          newValue.from = newValue.to;
          newValue.to = transfer;
        }

        window.removeEventListener('mousemove', this.onDrawing);
        window.removeEventListener('mouseup', this.onDrawEnd);
        window.removeEventListener('contextmenu', this.onDrawEnd);
      }
    },

    /**
     * @desc 鼠标在时间模板上移动的事件
     * @author chenguanbin
     * @param {Object} event 事件对象
     */
    handleMouseMove(event) {
      // 不是时间点模板，或者模板被禁用编辑，或者时间点正在拖拽中
      if (this.planGroup.type !== 'point' || this.disabled || this.pointDraging)
        return;

      // 每16ms触发一次滚动
      throttle(() => {
        // 鼠标相对于事件模板左侧的距离
        const mouseLeft = event.clientX - this.wrapperOffset.left;
        let index = -1;
        // 遍历光标集合
        for (let i = 0; i < this.cursorAmount; i++) {
          // 判断鼠标是否在光标响应区域内，左右各增加 3px 的响应区域，共7px
          if (
            mouseLeft >= this.cursors[i] - 3 &&
            mouseLeft <= this.cursors[i] + 3
          ) {
            index = i;
            break;
          }
        }
        // 如果当前位置已经存在时间点，则不显示光标
        if (this.isExistPoint(index)) return;
        this.cursorIndex = index;
      })();
    },

    /**
     * @desc 鼠标离开时间模板的事件
     * @author chenguanbin
     * @param {Object} event 事件对象
     */
    handleMouseLeave() {
      this.cursorIndex = -1;
    },

    /**
     * @desc 判断当前光标位置是否存在时间点
     * @author chenguanbin
     * @param {Number} cursorIndex 光标编号
     */
    isExistPoint(cursorIndex) {
      return !!this.value.find(
        item => item.point / this.intervalSecond === cursorIndex
      );
    },

    /**
     * @desc 响应时间点的 updateActivePoint 事件
     * @author chenguanbin
     * @param {Number} point 时间点数据
     */
    updateActivePoint(point) {
      this.activePoint = point;
    },

    /**
     * @desc 响应时间点的 dragPoint 事件
     * @author chenguanbin
     * @param {Boolean} draging 是否正在拖拽
     */
    dragPoint(draging) {
      this.isShowPopover = false;
      this.pointDraging = draging;
    }
  }
};
</script>
