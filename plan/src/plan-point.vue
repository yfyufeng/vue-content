<template>
  <div
    :style="{ left: `${points[pointIndex]}px` }"
    class="h-plan__point-wrap"
    @click="handleClickPoint"
    @mouseenter="handleMouseEnter"
    @mouseleave="handleMouseLeave"
    @mousedown="handleMouseDown"
  >
    <el-popover
      ref="popover"
      :value="isShowPopover"
      :popper-class="
        isActive && !dragging
          ? 'h-plan__popover--point'
          : 'h-plan__popover--dark h-plan__popover--point'
      "
      placement="top"
      trigger="manual"
    >
      <div v-if="isActive && !dragging" class="h-plan-popover">
        <el-time-select
          v-model="pointTime"
          :picker-options="pickerOptions"
          :editable="false"
          :clearable="false"
          style="width:120px"
        ></el-time-select>
        <div style="text-align: right; margin: 10px 0 0;">
          <el-button size="mini" type="link" @click="save">
            {{ t('h.plan.save') }}
          </el-button>
          <el-button
            size="mini"
            type="text"
            class="h-plan-popover-delbtn"
            @click="destroy"
          >
            {{ t('h.plan.delete') }}
          </el-button>
        </div>
      </div>
      <div v-else style="text-align:center;">{{ parseTime(value.point) }}</div>
    </el-popover>
    <div v-popover:popover :class="[customClass]" class="h-plan__point">
      <div
        :class="{
          'e-anchor-time-nor': !isActive && (!isHover || dragging),
          'e-anchor-time-hover': isActive || (isHover && !dragging)
        }"
        :style="{ color: customColor }"
        class="h-plan__point-icon"
      ></div>
    </div>
  </div>
</template>

<script>
import { timeFormat, minuteToSecond } from './util.js';
import { closest } from '@hui-pro/utils';
import { t } from '@hui-pro/locale';

export default {
  name: 'PlanPoint',
  inject: ['planGroup', 'plan'],
  props: {
    value: {
      type: Object,
      default() {
        return {};
      }
    }
  },
  data() {
    return {
      t,
      pointTime: timeFormat(this.value.point), // 时间点的值
      pointAmount: 288, // 所有时间点的数量，共 288 个
      intervalSecond: 300, // 时间间隔为 5 分钟，就是 300 秒
      isHover: false,
      isActive: false,
      forceHidePopover: false, // 强制隐藏popover，默认为false，为了解决popover隐藏时，会从日期控件变成字符串的问题，就先隐藏popover
      dragging: false,
      startX: null, // 开始拖拽时的鼠标X轴坐标
      startPoint: null // 开始拖拽时的时间点数据
    };
  },
  computed: {
    // 是否禁用编辑
    disabled() {
      if (this.plan.disabled !== undefined) return this.plan.disabled;
      return this.planGroup.disabled;
    },
    // 时间模板保存的，所有时间点的数据
    parentVaule() {
      return this.$parent.value;
    },
    // 时间模板是否有其他节点正在拖拽
    pointDraging() {
      return this.$parent.pointDraging;
    },
    // 所有时间点
    points() {
      return this.$parent.points;
    },
    // 当前时间点的编号
    pointIndex() {
      return this.value.point / this.intervalSecond;
    },
    // 当前时间模板，激活的时间点数据
    activePoint() {
      return this.$parent.activePoint;
    },
    // 给模板添加类
    customClass() {
      const customRangeClass = this.$parent.$parent.customRangeClass || {};
      return customRangeClass[this.value.type] || '';
    },
    // 时间点颜色
    customColor() {
      const customRangeColor = this.$parent.$parent.customRangeColor || {};
      return customRangeColor[this.value.type] || '';
    },
    // 是否显示popover
    isShowPopover() {
      if (this.forceHidePopover) return false;
      return this.isHover || this.isActive || this.dragging;
    },
    // 时间控件的 pickerOptions 参数
    pickerOptions() {
      const ranges = [];
      let tempPoint = 0;
      // 遍历时间点集合
      for (let i = 0; i < this.pointAmount; i++) {
        const point = i * this.intervalSecond;
        // 若时间点已经存在，而且不是自身时间点
        if (
          this.parentVaule.find(item => {
            return item.point === point;
          }) &&
          point !== this.value.point
        ) {
          // 添加时间片段
          if (point !== tempPoint) {
            ranges.push(
              `${timeFormat(tempPoint)} - ${timeFormat(
                (i - 1) * this.intervalSecond
              )}`
            );
          }
          tempPoint = (i + 1) * this.intervalSecond;
        }
      }
      // 如果末尾还有时间为添加，添加时间片段
      if (tempPoint !== (this.pointAmount - 1) * this.intervalSecond) {
        ranges.push(
          `${timeFormat(tempPoint)} - ${timeFormat(
            (this.pointAmount - 1) * this.intervalSecond
          )}`
        );
      }
      return {
        start: '00:00',
        end: '23:55',
        step: '00:05',
        range: ranges
      };
    }
  },

  watch: {
    // 监控时间模板中，激活的时间点
    activePoint(point) {
      // 判断激活的时间点是否是自身
      if (point === this.value.point) {
        this.pointTime = timeFormat(this.value.point);
        // 显示时设置400ms的延时，保证 hover 的 popover 完全消失后再展示
        setTimeout(() => {
          this.isActive = true;
        }, 400);
      } else {
        // 隐藏时设置 200ms 的延时，保证 popover 隐藏后，再切换里面的元素
        setTimeout(() => {
          this.isActive = false;
          this.forceHidePopover = false;
        }, 200);
      }
    }
  },

  created() {
    if (typeof window !== 'undefined') {
      !this.disabled && document.addEventListener('click', this.handleCancel);
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

  methods: {
    /**
     * @desc 格式化时间
     * @author chenguanbin
     * @param {Number} val 时间数据
     */
    parseTime(val) {
      return timeFormat(val);
    },

    /**
     * @desc 点击时间点
     * @author chenguanbin
     */
    handleClickPoint() {
      if (this.disabled) return;
      this.isHover = false;
      this.$emit('updateActivePoint', this.value.point);
    },

    /**
     * @desc 鼠标进入时间点
     * @author chenguanbin
     */
    handleMouseEnter() {
      if (this.pointDraging) return;
      this.isHover = true;
    },

    /**
     * @desc 鼠标离开时间点
     * @author chenguanbin
     */
    handleMouseLeave() {
      if (this.pointDraging) return;
      this.isHover = false;
    },

    /**
     * @desc 鼠标点击页面上任意位置
     * @author chenguanbin
     * @param {Object} event 事件对象
     */
    handleCancel(event) {
      const $pointWrapClick = closest(event.target, '.h-plan__point-wrap'); // 被点击节点的计划模板
      const $wrapClick = closest(event.target, '.h-plan'); // 被点击节点的计划模板
      const $wrapThis = closest(this.$el, '.h-plan'); // 当前时间点的计划模板
      // 如果当前时间点未激活
      if (!this.isActive) return;
      // 在时间点上点击，且点击的时间点和当前时间点在一个容器里
      if ($pointWrapClick && $wrapClick === $wrapThis) return;
      // 先强制隐藏 popover
      this.forceHidePopover = true;
      this.$emit('updateActivePoint', -1);
    },

    /**
     * @desc 点击保存按钮
     * @author chenguanbin
     */
    save() {
      this.value.point = minuteToSecond(this.pointTime);
      this.$emit('updateActivePoint', -1);
    },

    /**
     * @desc 点击删除按钮
     * @author chenguanbin
     */
    destroy() {
      this.$emit('destroy');
      this.$emit('updateActivePoint', -1);
    },

    /**
     * @desc 鼠标点击时间点，未松开
     * @author chenguanbin
     * @param {Object} event 事件对象
     */
    handleMouseDown(event) {
      event.preventDefault();
      event.cancelBubble = true;
      if (this.disabled) return;

      this.onDragStart(event);
      document.addEventListener('mousemove', this.onDragging);
      document.addEventListener('mouseup', this.onDragEnd);
      document.addEventListener('contextmenu', this.onDragEnd);
    },

    /**
     * @desc 开始拖拽
     * @author chenguanbin
     * @param {Object} event 事件对象
     */
    onDragStart(event) {
      this.dragging = true;
      this.startX = event.clientX;
      this.startPoint = this.points[this.pointIndex];
      this.$emit('dragging', true);
    },

    /**
     * @desc 鼠标在页面上移动，拖拽时间点
     * @author chenguanbin
     * @param {Object} event 事件对象
     */
    onDragging(event) {
      if (!this.dragging) return;

      // 鼠标距离时间模板左侧的距离
      const mouseLeft = this.startPoint + (event.clientX - this.startX);

      for (let i = 0; i < this.pointAmount; i++) {
        // 判断鼠标是否移动到时间点上，左右各增加 1px 来组成判断区域
        if (
          mouseLeft >= this.points[i] - 1 &&
          mouseLeft <= this.points[i] + 1
        ) {
          const point = i * this.intervalSecond;
          // 若找到的时间点不存在，则移动自身到目标时间点位置
          if (
            !this.parentVaule.find(item => {
              return item.point === point;
            })
          ) {
            this.value.point = point;
            this.$nextTick(() => {
              this.$refs.popover.updatePopper();
            });
          }
          break;
        }
      }
    },

    /**
     * @desc 拖拽时间点结束
     * @author chenguanbin
     */
    onDragEnd() {
      if (!this.dragging) return;

      this.dragging = false;
      this.isHover = false;
      this.$emit('dragging', false);
      document.removeEventListener('mousemove', this.onDragging);
      document.removeEventListener('mouseup', this.onDragEnd);
      document.removeEventListener('contextmenu', this.onDragEnd);
    }
  }
};
</script>
