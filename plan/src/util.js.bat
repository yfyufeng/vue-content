const daySecond = 86400;
const numToDouble = value => (value < 10 ? '0' + value : value);

export const pixelToSecond = (value, totalPixel) =>
  (value * daySecond) / totalPixel;
export const secondToPixel = (value, totalPixel) =>
  (value * totalPixel) / daySecond;
export const timeFormat = value => {
  // 时间调整 23:59 代替 24:00
  value = value === 86400 ? 86340 : value;
  const hour = numToDouble(parseInt(value / 3600, 10));
  const min = numToDouble(parseInt((value % 3600) / 60, 10));
  return hour + ':' + min;
};

/**
 * @desc 分钟转为秒
 * @author chenguanbin
 * @param {String} value 分钟数据
 */
export const minuteToSecond = value => {
  const time = value.split(':');
  return parseInt(time[0], 10) * 3600 + parseInt(time[1], 10) * 60;
};

export const secondToDate = value => {
  // 时间调整 23:59 代替 24:00
  value = value === 86400 ? 86340 : value;
  const hour = numToDouble(parseInt(value / 3600, 10));
  const min = numToDouble(parseInt((value % 3600) / 60, 10));
  return new Date(2018, 1, 1, hour, min);
};

export const timeToSecond = value => {
  const date = new Date(value);
  return date.getHours() * 3600 + date.getMinutes() * 60;
};

/**
 * @desc 23:59 时输出第59秒
 * @author chenguanbin
 * @param {second} 秒数
 * @return 23:59 时输出第59秒，其他时间直接输出不转换
 */
export const second2Value = second => {
  // 86340秒，就是23:59，此时返回第59秒
  if (second >= 86340 && second < 86400) return second - (second % 60) + 59;
  return second;
};
