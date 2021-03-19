<template>
  <div class="h-perpetual-calendar">
    <div class="year-month-operate-bar">
      <calendar-year-month-selector
        ref="calendar-year-month-selector"
        :current-year.sync="currentYear"
        :current-month.sync="currentMonth"
        v-bind="$attrs"
        v-on="$listeners"
      />
      <div
        v-show="!isCurrentMonth"
        class="return-current-month"
        @click="returnCurrentMonth"
      >
        <i class="h-icon-arrow_left" />
        <span>返回本月</span>
      </div>
    </div>
    <table class="calendar-main-content">
      <tbody>
        <tr class="week-wrapper">
          <th v-for="weekday in weekdays" :key="weekday" class="week-day">
            {{ weekday }}
          </th>
        </tr>
        <tr v-for="(week, index) in weekList" :key="index" class="date-wrapper">
          <td
            v-for="(item, i) in week"
            :key="i"
            :class="{
              holiday: item && item.isHoliday,
              today: item && item.isToday,
              checked: item && item.checked,
              'first-lunar-date': item && item.isFirstLunarDate
            }"
            class="date-item"
          >
            <div
              :class="{
                notCurrentMonth: item && !item.isCurrentMonth,
                disabled: isDisabledDate(item),
                readonly: readonly
              }"
              :style="{
                height: `${cellHeight}px`
              }"
              class="date-item-wrapper"
              @click="dateItemClickHandler(item)"
              @mousedown.left="mousedownHandler(item)"
              @mouseup.left="mouseupHandler(item)"
              @mouseenter="mouseenterHandler(item)"
            >
              <!-- 这里支持slot传入模板内容，可自定义样式，不传则采用默认样式 -->
              <slot :item="item">
                <!-- left修饰符代表鼠标左键 -->
                <div class="date-info">
                  <!-- 日期信息 -->
                  <span class="lunar-date">
                    {{ item && item.lunarDate.fmtStr }}
                  </span>
                  <span class="solar-date">
                    {{ item && item.date.getDate() }}
                  </span>
                </div>
                <div class="festival-info">
                  <!-- 节假日信息 -->
                  <span class="festival">
                    {{
                      item && (item.lunarDate.festival || item.lunarDate.Term)
                    }}
                  </span>
                </div>
                <div class="status">
                  <!-- 当前状态信息 -->
                  <span v-ellipsis v-if="item && item.isHoliday">
                    {{ text }}
                  </span>
                  <span v-else class="h-icon-add" />
                </div>
              </slot>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
/**
 * @author: jiangyan6
 * @desc: 日历组件
 */
import calendar from './calendar.js';
import CalendarYearMonthSelector from './calendar-year-month-selector.vue';
export default {
  name: 'HHolidayPicker',
  components: {
    CalendarYearMonthSelector
  },
  props: {
    // 设置一周的第一天
    firstDayOfWeek: {
      type: Number,
      default: 7
    },
    // 当前的节假日列表（用于回显）
    holidayList: {
      type: Array,
      default: function() {
        return [];
      }
    },
    // 开放接口，可以自定义文字内容
    text: {
      type: String,
      default: '休'
    },
    // 开放只读配置，只读模式只能看，不能进行操作
    readonly: {
      type: Boolean,
      default: false
    },
    // 日历单元格高度，默认111px
    cellHeight: {
      type: Number,
      default: 111
    },
    // 默认展示年份
    defaultCurrentYear: {
      type: Number,
      default: new Date().getFullYear()
    },
    // 默认展示月份
    defaultCurrentMonth: {
      type: Number,
      default: new Date().getMonth()
    }
  },
  data() {
    return {
      dateList: [], // 用于存放7 * 6个日期对象
      currentDateObj: new Date(), // 当前时间
      currentYear: this.defaultCurrentYear, // 当前日历展示的年
      currentMonth: this.defaultCurrentMonth, // 当前日历展示的月
      currentDate: new Date().getDate(), // 当前日历展示的日
      isMultiSelect: false, // 是否正在多选状态标识
      selectedStartItem: '', // 多选的开始日期
      selectedEndItem: '' // 多选的截止日期
    };
  },
  computed: {
    // 日历表头的星期
    weekdays() {
      const weekDate = {
        1: '星期一',
        2: '星期二',
        3: '星期三',
        4: '星期四',
        5: '星期五',
        6: '星期六',
        0: '星期日'
      };
      const res = [];
      // 向res中压入7个日期，根据firstDayOfWeek的不同，压入顺序有所不同
      for (let i = 0; i < 7; i++) {
        res.push(weekDate[(this.firstDayOfWeek + i) % 7]);
      }
      return res;
    },
    // 把数据源的42个日期转成二维数组，按周来分，共6周，以便在视图上按周显示
    weekList() {
      const res = [];
      for (let i = 0; i < this.dateList.length / 7; i++) {
        res.push(this.dateList.slice(i * 7, (i + 1) * 7));
      }
      return res;
    },
    // 当前假期列表，基于传入的holidayList
    currentHolidayList() {
      const res = new Set(this.holidayList);
      // 这里是为了在鼠标抬起后再刷新节假日列表（效果就是鼠标拖动时节假日不会变，只是更新选中状态，而在鼠标抬起时进行节假日列表刷新）
      if (!this.isMultiSelect) {
        this.selectedItems.forEach(item => {
          if (res.has(item)) {
            res.delete(item);
          } else {
            res.add(item);
          }
        });
      }
      return res;
    },
    // 多选时已被选中的日期列表
    selectedItems() {
      return calendar.getDateArrBetween(
        this.selectedStartItem,
        this.selectedEndItem
      );
    },
    // currentMonth是否当前月份，用于控制返回本月按钮的可见性
    isCurrentMonth() {
      const realCurrentMonth = new Date().getMonth();
      const realCurrentYear = new Date().getFullYear();
      return (
        this.currentYear === realCurrentYear &&
        this.currentMonth === realCurrentMonth
      );
    },
    // 切换到上一月禁用条件
    disabledPrevMonth() {
      const date = new Date(this.currentYear, this.currentMonth);
      date.setMonth(date.getMonth() - 1);
      return (
        (this.currentYear === 1900 && this.currentMonth === 1) ||
        (this.$attrs['picker-options'] &&
          this.$attrs['picker-options'].disabledDate(new Date(date)))
      );
    },
    // 切换到下一月的禁用条件
    disabledNextMonth() {
      const date = new Date(this.currentYear, this.currentMonth);
      date.setMonth(date.getMonth() + 1);
      return (
        (this.currentYear === 2100 && this.currentMonth === 11) ||
        (this.$attrs['picker-options'] &&
          this.$attrs['picker-options'].disabledDate(new Date(date)))
      );
    }
  },
  watch: {
    // 监听当前年份和月份的变化，并重新加载日历数据
    currentMonth(val) {
      // 月份变化时，抛出事件,并将年月转化成自然年月
      this.$emit('calendarChange', this.currentYear, this.currentMonth + 1);
      this.initDateList();
    },
    currentYear(val) {
      // 年份变化时，抛出事件,并将年月转化成自然年月
      this.$emit('calendarChange', this.currentYear, this.currentMonth + 1);
      this.initDateList();
    },
    currentHolidayList() {
      // 监听currentHolidayList的变化，节假日改变后要刷新日历中所有日期的状态
      this.initDateList();
    },
    selectedItems() {
      this.initDateList();
    }
  },
  created() {
    this.initDateList();
  },
  methods: {
    // 初始化某年某月的日历面板数据，默认是当前月的面板数据
    initDateList(year = this.currentYear, month = this.currentMonth) {
      // 先清空数组
      this.dateList = [];
      // 计算出当月第一天是星期几，星期日到星期一原本对应0-6，这里调整成星期一到星期日对应1-7
      const currentMonthFirstDay = calendar.getFirstDateDay(year, month) || 7;
      // 计算当月第一天应该在this.dateList数组中的下标
      let num = 0;
      // 下面对num的计算值后面加上||7的意思是，把0123456的结果调整为7123456，这样num即代表本月第一日应该在this.dateList数组中的下标
      if (currentMonthFirstDay > this.firstDayOfWeek) {
        num = (currentMonthFirstDay - this.firstDayOfWeek) % 7 || 7;
      } else {
        num = (currentMonthFirstDay - this.firstDayOfWeek + 7) % 7 || 7;
      }
      // 在当月第一天之前，都是上个月的日期
      let index = num; // 这里用于计数的变量要单独存一分，因为循环中会修改这个数值，而这个数值后面还要用的。
      while (index > 0) {
        // 最后一个参数-1代表是上个月
        this.dateList.push(this.createCalendarItem(year, month, 1 - index, -1));
        index--;
      }
      // 查询一个月有多少天，并向dateList中压入对应天数的数据
      const currentMonthDayNum = calendar.getMonthDayNum(year, month);
      // 日期从一号开始
      for (let i = 1; i <= currentMonthDayNum; i++) {
        // 存入该月的日期数据
        this.dateList.push(this.createCalendarItem(year, month, i, 0)); // 最后一个参数0代表是当前月
      }
      // 剩下的是下个月的日期
      for (let i = 1; i <= 42 - (currentMonthDayNum + num); i++) {
        this.dateList.push(
          // 最后一个参数1代表是下个月
          this.createCalendarItem(year, month, currentMonthDayNum + i, 1)
        );
      }
    },
    // 创建日历中的日期对象
    createCalendarItem(y, m, d, flag) {
      const calendarItem = {
        checked: false
      };
      calendarItem.date = new Date(y, m, d);
      // 获取阳历日期对应的阴历日期
      calendarItem.lunarDate = calendar.solar2lunar(y, m + 1, d);
      // 阴历1900年1月1日前的日期不再显示，直接返回null
      if (
        calendarItem.lunarDate.lYear <= 1900 &&
        calendarItem.lunarDate.lMonth < 1
      ) {
        return null;
      }
      if (calendarItem.lunarDate.lDay === 1) {
        // 如果是阴历的初一，那么直接显示该月的阴历月份，同时标记为阴历月份的第一天
        calendarItem.lunarDate.fmtStr =
          calendarItem.lunarDate.IMonthCn + calendarItem.lunarDate.IDayCn;
        calendarItem.isFirstLunarDate = true;
      } else {
        // 如果不是阴历的初一，那么正常显示阴历的日期
        calendarItem.lunarDate.fmtStr = calendarItem.lunarDate.IDayCn;
        calendarItem.isFirstLunarDate = false;
      }
      // 设置阳历的日期字符串，复用阴历日期中携带的阳历年月日属性
      calendarItem.solarDateStr = `${calendarItem.lunarDate.cYear}-${
        calendarItem.lunarDate.cMonth < 10
          ? '0' + calendarItem.lunarDate.cMonth
          : calendarItem.lunarDate.cMonth
      }-${calendarItem.lunarDate.cDay}`;
      // 判断是否今日，复用计算阴历日期中的属性（阴历日期中包含了isToday属性）
      calendarItem.isToday = calendarItem.lunarDate.isToday;
      // 判断是否被设置为放假日
      const nowItemDateFormatStr = calendar.formatDateToString(
        new Date(y, m, d),
        '-'
      );
      calendarItem.isHoliday = this.currentHolidayList.has(
        nowItemDateFormatStr
      );
      // 判断多选时是否被选中
      calendarItem.checked =
        this.isMultiSelect && this.selectedItems.includes(nowItemDateFormatStr);
      // 判断当前日期是否上个月或者下个月或者是当月
      calendarItem.isPrevMonth = flag === -1;
      calendarItem.isNextMonth = flag === 1;
      calendarItem.isCurrentMonth = flag === 0;
      return calendarItem;
    },
    // 点击某个日期时，切换该日期的选中状态
    dateItemClickHandler(item) {
      if (this.isNotAvailable(item)) {
        return;
      }
      // 先判断点击的日期是否是当月，不是当月要跳转到上月或者下月
      if (
        item.isPrevMonth &&
        !(this.currentYear === 1900 && this.currentMonth === 1)
      ) {
        // 如果月份小于等于0（0-11）了，说明需要切换年份了，比如2019年0月实际应该是2018年12月
        if (this.currentMonth <= 0) {
          const trueYM = this.getTureYearMonth(
            this.currentYear,
            this.currentMonth - 1
          );
          this.currentYear = trueYM.y;
          this.currentMonth = trueYM.m;
          return;
        }
        this.currentMonth = this.currentMonth - 1;
      } else if (
        item.isNextMonth &&
        !(this.currentYear === 2100 && this.currentMonth === 11)
      ) {
        // 如果月份大于等于11（0-11）了，说明需要切换年份了，比如2019年13月实际应该是2020年1月
        if (this.currentMonth >= 11) {
          const trueYM = this.getTureYearMonth(
            this.currentYear,
            this.currentMonth + 1
          );
          this.currentYear = trueYM.y;
          this.currentMonth = trueYM.m;
          return;
        }
        this.currentMonth = this.currentMonth + 1;
      }
      // 抛出事件，并传递当前操作的日期对象以及变更后的holidayList
      const eventParams = {
        dateItem: item,
        holidayList: Array.from(this.currentHolidayList)
      };
      this.$emit('dateClick', eventParams);
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
    // 返回当前年月
    returnCurrentMonth() {
      this.currentYear = this.currentDateObj.getFullYear();
      this.currentMonth = this.currentDateObj.getMonth();
      this.initDateList();
    },
    // 鼠标按下时，修改当前多选状态标识，后续mouseenter处理事件基于该标识去做后续操作
    mousedownHandler(item) {
      if (this.isNotAvailable(item)) {
        return;
      }
      // 修改标识，进入多选状态
      this.isMultiSelect = true;
      // 设置当前日期为多选列表的开始日期和结束日期（意思就是按下按钮即把当前日期算作选择日期）
      this.selectedStartItem = calendar.formatDateToString(item.date, '-');
      this.selectedEndItem = calendar.formatDateToString(item.date, '-');
    },
    // 鼠标移入时，更新多选列表的结束日期
    mouseenterHandler(item) {
      if (this.isNotAvailable(item)) {
        return;
      }
      // 判断是否处于多选状态，不在多选状态时不执行后续逻辑
      if (!this.isMultiSelect) {
        return;
      }
      // 设置当前日期为多选列表的结束日期
      this.selectedEndItem = calendar.formatDateToString(item.date, '-');
    },
    // 鼠标抬起时，修改当前多选状态标识，后续mouseenter处理事件基于该标识去做后续操作
    mouseupHandler(item) {
      if (this.isNotAvailable(item)) {
        return;
      }
      // 修改标识，结束多选状态
      this.isMultiSelect = false;
      // 通知父级组件，节假日已经改变
      this.$emit('update:holidayList', Array.from(this.currentHolidayList));
      // 抛出dateChange时间
      this.$emit('dateChange', Array.from(this.currentHolidayList));
      // 抛出当前节假日信息后，立即清空多选的开始日期和截止日期，避免holidayList变化后，导致重新计算出现错误
      this.selectedStartItem = '';
      this.selectedEndItem = '';
    },
    // 判断传入日期是否在禁用的范围内
    isDisabledDate(item) {
      return (
        (this.currentYear === 1900 && this.currentMonth === 1) ||
        (this.currentYear === 2100 && this.currentMonth === 11) ||
        (this.$attrs['picker-options'] &&
          this.$attrs['picker-options'].disabledDate(new Date(item.date)))
      );
    },
    // 封装一个方法，用于判断传入的日期item能否被操作
    isNotAvailable(item) {
      // 如果是只读模式，那么不进行任何操作
      if (this.readonly) {
        return true;
      }
      if (!item) {
        return true;
      }
      // 如果是禁用的日期，那么不作任何操作
      if (this.isDisabledDate(item)) {
        return true;
      }
      // 判断是否超出日期限制范围，超出则不再进行任何操作
      if (
        (item.isPrevMonth && this.disabledPrevMonth) ||
        (item.isNextMonth && this.disabledNextMonth)
      ) {
        return true;
      }
      return false;
    }
  }
};
</script>
