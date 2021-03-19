import validator from 'validator';

/**
 * javascript comment
 * @Author: xiangxiao3
 * @Date: 2019-11-04 15:16:23
 * @Desc: TODO: 对传来的数据进行校验
 */
const check = val => {
  return true;
};

/**
 * javascript comment
 * @Author: xiangxiao3
 * @Date: 2019-11-04 15:47:43
 * @Desc: 通用匹配，先判断是否匹配dyValidator，然后匹配validator如果都没有则返回错误
 */
const useValidator = (val, value, dyValidator) => {
  if (val.type === 'dyFunction' && dyValidator) {
    return dyValidator[val.method](value, ...val.args);
  } else if (validator[val.method]) {
    // 这个必须转成string否则无返回值
    return validator[val.method](String(value), ...val.args);
  } else {
    console.error('not match function validator');
    return false;
  }
};

const valData = (val, value, dyValidator) => {
  // 值是纯字符串的形态
  if (Object.prototype.toString.call(value) === '[object String]') {
    return useValidator(val, value, dyValidator);
  }

  // 如果没有key，而且不是对象，一般做dyfunction的验证
  if (Object.prototype.toString.call(value) !== '[object String]' && !val.key) {
    return useValidator(val, value, dyValidator);
  }

  // 如果是对象或者是数字，做一层的解构，再做处理；注意这里只做了一层解构，多层的暂时没考虑 xx
  if (Object.prototype.toString.call(value) === '[object Object]' && val.key) {
    return useValidator(val, value[val.key], dyValidator);
  } else if (
    Object.prototype.toString.call(value) === '[object Array]' &&
    val.key
  ) {
    let boo = true;
    for (const index in value) {
      if (!useValidator(val, value[index][val.key], dyValidator)) {
        boo = false;
        break;
      }
    }
    return boo;
  } else {
    console.error('not match function validator');
    return false;
  }
};

/**
 * javascript comment
 * @Author: xiangxiao3
 * @Date: 2019-11-04 15:17:34
 * @Desc: 根据值进行判断，如果是string则直接判断 ，如果是复杂变量则要进行递归判断
 */
const setValidator = (val, dyValidator) => {
  if (!check(val)) return false;

  return (rule, value, callback) => {
    try {
      if (!valData(val, value, dyValidator)) {
        return callback(new Error(val.message));
      }
      callback();
    } catch (error) {
      console.error('自定义validator方法报错:' + error);
      return callback(new Error(val.message));
    }
  };
};

export default {
  setValidator
};
