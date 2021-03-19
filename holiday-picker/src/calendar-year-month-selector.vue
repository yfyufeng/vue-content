<template>
  <div class="h-year-month-selector">
    <el-button
      :class="{
        disabled: disabledPrevYear
      }"
      icon="h-icon-angles_left_sm"
      class="prev-year"
      @click="prevYear"
    ></el-button>
    <el-button
      :class="{
        disabled: disabledPrevMonth
      }"
      icon="h-icon-angle_left_sm"
      @click="prevMonth"
    ></el-button>
    <span class="year-month-value">
      <span class="year-view">
        <el-date-picker
          key="year-picker"
          ref="picker"
          v-model="yearMonth"
          :editable="false"
          :clearable="false"
          :picker-options="pickerOptions"
          :unlink="false"
          v-bind="$attrs"
          class="picker year-picker important"
          align="center"
          type="year"
          v-on="$listeners"
          @change="yearDateChangeHandler('year', $event)"
        />
        {{ currentYear }}年
      </span>
      <span class="month-view">
        <el-date-picker
          key="month-picker"
          ref="picker"
          v-model="yearMonth"
          :editable="false"
          :clearable="false"
          :picker-options="pickerOptions"
          :unlink="false"
          v-bind="$attrs"
          class="picker month-picker important"
          align="center"
          type="month"
          v-on="$listeners"
          @change="yearDateChangeHandler('month', $event)"
        />
        {{ currentMonth + 1 }}月
      </span>
    </span>
    <el-button
      :class="{
        disabled: disabledNextMonth
      }"
      icon="h-icon-angle_right_sm"
      @click="nextMonth"
    ></el-button>
    <el-button
      :class="{
        disabled: disabledNextYear
      }"
      icon="h-icon-angles_right_sm"
      class="next-year"
      @click="nextYear"
    ></el-button>
  </div>
</template>

<script>
/**
 * @author: jiangyan6
 * @desc: 日历上方，年月切换的组件
 */
export default {
  name: 'CalendarYearMonthSelector',
  props: {
    currentYear: {
      type: Number,
      default: undefined
    },
    currentMonth: {
      type: Number,
      default: undefined
    }
  },
  data() {
    return {
      pickerType: 'year', // 用于标记当前日历选择器的类型，y-年份选择，m-月份选择
      yearMonth: new Date() // 这里不能用空字符串，因为要赋值给hui的datePicker，旧版本的datePicker赋值空字符串会报错
    };
  },
  computed: {
    pickerOptions() {
      if (this.$attrs['picker-options']) {
        return this.$attrs['picker-options'];
      } else {
        return {
          disabledDate(time) {
            return (
              time.getTime() > new Date(2100, 11, 31) ||
              time.getTime() < new Date(1900, 1, 1)
            );
          }
        };
      }
    },
    // 切换到上一年的禁用条件
    disabledPrevYear() {
      const date = new Date(this.yearMonth);
      date.setFullYear(date.getFullYear() - 1);
      return (
        (this.currentYear === 1900 && this.currentMonth === 1) ||
        this.pickerOptions.disabledDate(date)
      );
    },
    // 切换到下一年的禁用条件
    disabledNextYear() {
      const date = new Date(this.yearMonth);
      date.setFullYear(date.getFullYear() + 1);
      return (
        (this.currentYear === 2100 && this.currentMonth === 11) ||
        this.pickerOptions.disabledDate(date)
      );
    },
    disabledPrevMonth() {
      const date = new Date(this.yearMonth);
      date.setMonth(date.getMonth() - 1);
      return (
        (this.currentYear === 1900 && this.currentMonth === 1) ||
        this.pickerOptions.disabledDate(new Date(date))
      );
    },
    // 切换到下一月的禁用条件
    disabledNextMonth() {
      const date = new Date(this.yearMonth);
      date.setMonth(date.getMonth() + 1);
      return (
        (this.currentYear === 2100 && this.currentMonth === 11) ||
        this.pickerOptions.disabledDate(new Date(date))
      );
    }
  },
  watch: {
    currentYear: 'dateChangeHandler',
    currentMonth: 'dateChangeHandler'
  },
  methods: {
    // 日期选择器中选择日期变化时，要更新currentYear和currentMonth
    yearDateChangeHandler(type, dateInfo) {
      const date = new Date(dateInfo);
      if (date.getFullYear() === 1900 && date.getMonth() < 1) {
        // 不能选择1900年的一月份，因为农历只查表查到了1900年1月份，阳历对应的是二月份
        this.$emit('update:currentYear', 1900);
        this.$emit('update:currentMonth', 1);
        return;
      }
      // 用对象声明不同type类型的处理方法
      const handlerMap = {
        year: () => {
          this.$emit('update:currentYear', date.getFullYear());
        },
        month: () => {
          // 月份变化可能引起年份变化
          this.$emit('update:currentYear', date.getFullYear());
          this.$emit('update:currentMonth', date.getMonth());
        }
      };
      // 基于传入的type类型，调用对应的处理函数
      handlerMap[type] && handlerMap[type]();
    },
    // 这里要计算一下真正的年月，主要是用来转换(2019，-1)为(2018,12)
    getTureYearMonth(y, m) {
      const dateObj = new Date(y, m);
      const trueY = dateObj.getFullYear();
      const trueM = dateObj.getMonth();
      return {
        y: trueY,
        m: trueM
      };
    },
    // 切换到上一年
    prevYear() {
      // 最早可以切换到1900年2月，再往前禁止跳转，因为阴历只能支持到1900年
      if (this.disabledPrevYear) {
        return;
      }
      this.$emit('update:currentYear', this.currentYear - 1);
    },
    // 切换到下一年
    nextYear() {
      // 最晚可以切换到2100年12月，再往后禁止跳转，因为阴历只能支持到2100年
      if (this.disabledNextYear) {
        return;
      }
      this.$emit('update:currentYear', this.currentYear + 1);
    },
    // 切换到上个月
    prevMonth() {
      // 最早可以切换到1900年2月，再往前禁止跳转，因为阴历只能支持到1900年
      if (this.disabledPrevMonth) {
        return;
      }
      // 如果月份小于等于0（0-11）了，说明需要切换年份了，比如2019年0月实际应该是2018年12月
      if (this.currentMonth <= 0) {
        const trueYM = this.getTureYearMonth(
          this.currentYear,
          this.currentMonth - 1
        );
        this.$emit('update:currentYear', trueYM.y);
        this.$emit('update:currentMonth', trueYM.m);
        return;
      }
      // 否则正常抛出月份更新事件即可
      this.$emit('update:currentMonth', this.currentMonth - 1);
    },
    // 切换到下个月
    nextMonth() {
      // 最晚可以切换到2100年12月，再往后禁止跳转，因为阴历只能支持到2100年
      if (this.disabledNextMonth) {
        return;
      }
      // 如果月份大于等于11（0-11）了，说明需要切换年份了，比如2019年13月实际应该是2020年1月
      if (this.currentMonth >= 11) {
        const trueYM = this.getTureYearMonth(
          this.currentYear,
          this.currentMonth + 1
        );
        this.$emit('update:currentYear', trueYM.y);
        this.$emit('update:currentMonth', trueYM.m);
        return;
      }
      this.$emit('update:currentMonth', this.currentMonth + 1);
    },
    // 当传入的年月变化时，同步修改datepicker的值
    dateChangeHandler() {
      this.yearMonth = new Date(this.currentYear, this.currentMonth);
    }
  }
};
</script>
