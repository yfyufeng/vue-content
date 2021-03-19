/**
 * @desc 文本自动省略指令形式
 * @author chenguanbin
 */
import { addClass, removeClass, on, off } from '@hui-pro/utils';

/**
 * @desc 更新节点的class类
 * @author chenguanbin
 * @param {Document} el 监听的DOM元素
 * @param {Object} binding vue指令对象
 */
const updateCls = (el, binding) => {
  addClass(el, 'h-ellipsis');
  // 处理修饰符
  binding.modifiers.block
    ? addClass(el, 'display-block')
    : removeClass(el, 'display-block');
  binding.modifiers.nonFull
    ? addClass(el, 'non-full')
    : removeClass(el, 'non-full');
};

/**
 * @desc 元素的 mouseenter 事件
 * @author chenguanbin
 * @param {Event} e 事件对象
 */
const hover = e => {
  const t = e.target;
  t.title = t.clientWidth < t.scrollWidth ? t.innerText : '';
};

export default {
  install(Vue) {
    Vue.directive('ellipsis', {
      bind: function(el, binding) {
        updateCls(el, binding);
        on(el, 'mouseenter', hover);
      },
      update: function(el, binding) {
        updateCls(el, binding);
      },
      unbind: function(el) {
        removeClass(el, 'h-ellipsis display-block non-full');
        off(el, 'mouseenter', hover);
      }
    });
  }
};
