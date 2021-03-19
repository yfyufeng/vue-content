<template>
  <component
    :is="formType"
    ref="form"
    :model="form"
    :rules="rules"
    v-bind="formConfig"
    @submit.native.prevent
  >
    <slot name="prepend"></slot>
    <!-- eslint-disable -->
    <component
      :is="itemType"
      v-for="item in renderData.filter(item => !item.hide)"
      :key="item.model"
      :prop="item.model"
      :show="item.defaultShow === undefined ? true : item.defaultShow"
      :label="
        showLabel
          ? item.showLabel === undefined || item.showLabel
            ? item.label
            : ''
          : ''
      "
      :class="[item.class ? item.class : '',
        (item.type === FORM_TYPE.IP_INPUTS || item.type.indexOf('multi-') !== -1) && item.props && item.props.required ? 'is-required is-required-right' : '']"
      :description-render="_descriptionRender(item)"
      v-bind="item"
    >
      <component
        v-if="item.type.indexOf('el-') !== -1 || item.type.indexOf('h-') !== -1"
        :width="
          item.props && item.props.width
            ? item.props.width
            : formType === 'el-form' && item.type === 'h-ip-input'
            ? '172px'
            : '100%'
        "
        :is="item.type"
        :label="item.label"
        v-model.trim="form[item.model]"
        :ref="item.model"
        :pwd-strength.sync="form[item.pwdStrength]"
        :title="(item.props && item.props.title) || ''"
        v-bind="filterProp(item)"
        :formData="form"
        @data-change="dataChange"
        @keyup.enter.native="handleInputEnter(item)"
      >
        <!-- 这里设置key会报错 -->
        <template v-for="sl in item.slots" :slot="sl.name">
          <h-dynamic-form-children
            v-if="sl.children"
            :children-data="sl.children"
          ></h-dynamic-form-children>
        </template>
        <!-- formData 和 data-change这里给密码校验做了特殊处理，相当恶心 -->
        <h-dynamic-form-children
          v-if="item.children"
          :children-data="item.children"
        ></h-dynamic-form-children>
      </component>

      <component
        v-else-if="item.type === 'ip-inputs' || item.type.indexOf('multi-') !== -1"
        :is="item.type"
        :ref="'dynamic-' + item.model"
        :data="item"
        :multiValue.sync="form[item.model]"
        @extendFormChange="extendFormChange"
        :form="form">
      </component>

      <component v-else :is="item.type" v-bind="item.props ? [item.props] : []">{{ item.content }}</component>
    </component>

    <slot name="append"></slot>

    <template slot="pageSearchAction">
      <slot name="pageSearchAction" />
    </template>
  </component>
</template>

<script>
import validation from './validator.js';
import { t } from '@hui-pro/locale';
const FORM_TYPE = {
  INPUT: 'el-input', // 输入框
  SELECT: 'el-select', // 选择器
  CHECKBOX: 'el-checkbox-group', // 复选框
  RADIO: 'el-radio', // 单选框
  RADIO_GROUP: 'el-radio-group', // 单选框
  SWITCH: 'el-switch', // 开关,
  PWD_INPUT: 'h-pwd-input', // 密码输入框
  ENCRYPT_PASSWORD: 'h-encrypt-password', // 密码输入框
  CHECKBOX_GINGLE: 'el-checkbox', // 单个复选框
  IP_INPUT: 'h-ip-input', // IP输入框
  IP_INPUTS: 'ip-inputs'
};

const FORM_DEFAULT = {
  'el-input': '',
  'el-select': '',
  'el-checkbox': '',
  'el-checkbox-group': [],
  'el-radio': '',
  'el-radio-group': [],
  'el-switch': false,
  'h-pwd-input': '',
  'h-ip-input': '',
  'ip-inputs': []
};

export default {
  name: 'HDynamicForm',

  props: {
    // 表单模式
    formType: {
      type: String,
      default: 'el-form'
    },

    // 表单项模式
    itemType: {
      type: String,
      default: 'el-form-item'
    },

    // 表单项配置数据
    data: {
      type: Array,
      required: true,
      default: undefined
    },

    // 是否显示文本label
    showLabel: {
      type: Boolean,
      default: true
    },

    // 表单配置
    formConfig: {
      type: Object,
      default() {
        return {
          labelPosition: 'top'
        };
      }
    },

    // 自定义项的表单规则
    pluginRules: {
      type: Object,
      default: null
    }
  },

  data() {
    return {
      t,
      FORM_TYPE,
      form: {},
      extendForm: {}, // 内部额外表单字段，用来做ip区间等组件，根据单个和区间来做联动的功能
      rules: {},
      renderData: [], // 根据联动实时变化的渲染信息
      isSetDating: false,
      isUpdated: false // 是否是初始化，也就是是否Updated过
    };
  },

  computed: {
    formNew() {
      return JSON.parse(JSON.stringify(this.form));
    }
  },

  watch: {
    data: {
      deep: true,
      immediate: true,
      handler(value) {
        try {
          if (!value) return;
          this.renderData = JSON.parse(JSON.stringify(value));
          this._initForm();
          this._setFormRenderData();
          this.$nextTick(() => {
            if (value.length > 0) {
              this.$emit('form-init');
            }
          });
        } catch (err) {
          console.error(err);
        }
      }
    },

    formNew: {
      deep: true,
      immediate: true,
      handler(newValue, oldValue) {
        const changeField = [];
        if (newValue && oldValue) {
          for (const key in newValue) {
            if (
              JSON.stringify(newValue[key]) !== JSON.stringify(oldValue[key])
            ) {
              changeField.push(key);
            }
          }
        }
        this.$emit('form-change', newValue, changeField);
      }
    }
  },

  destroyed() {
    this.renderData = [];
  },
  updated() {
    this.isSetDating = false;
    this.isUpdated = true;
  },

  methods: {
    // @description: 动态表单渲染初始化
    // ------------------------------------------------------------------------------------------------

    /**
     * @Desc:   过滤特殊字段
     * @Parm:   {Object} item 当前需要渲染的表单项数据
     */
    filterProp(item) {
      for (const prop in item.props || {}) {
        if (prop === 'pwdStrength') {
          delete item.props[prop];
        }
      }
      return [item.props];
    },

    /**
     * @Desc:   表单项根据order字段排序
     * @Parm:   {Object} item 当前需要渲染的表单项数据
     */
    compare(order) {
      return function(a, b) {
        return a[order] - b[order];
      };
    },

    /**
     * @Author: zhuxiankang
     * @Date:   2019-03-25 19:40:10
     * @Desc:   渲染表单的描述信息
     * @Parm:   {Object} item 当前需要渲染的表单项数据
     */
    _descriptionRender(item) {
      let { description } = item.props || {};
      if (!description) return;
      if (typeof description === 'string' || !description.length) {
        description = [description];
      }
      description = description.map(d => {
        return <div>{d}</div>;
      });
      return () => {
        return <div> {description} </div>;
      };
    },

    // @description: 动态表单初始化
    // ------------------------------------------------------------------------------------------------

    /**
     * @Author: zhuxiankang
     * @Date:   2019-03-25 18:49:56
     * @Desc:   初始化表单
     * @Parm:
     */
    _initForm() {
      const { data } = this;
      if (!data || !data.length) {
        console.warn(
          "the prop 'data' is not provided in dynamic-form component!"
        );
        return;
      }

      // 清空表单信息
      this.form = {};
      // 清空校验规则
      this.rules = {};

      for (const item of data) {
        // 数字类型或字符串类型转换成字符串类型进行v-if匹配
        item.type += '';
        // IE下有Bug，暂时标记一下
        if (item.props) {
          item.props.placeholder = item.props.placeholder || ' ';
        }
        // 设置表单项的初始值
        this._initFormItem(item);
        // 设置表单项的校验规则
        this.rules[item.model] = this._initItemRule(item);
        // 设置表单项的联动规则监听事件
        this._initItemLinkage(item);
      }
    },

    /**
     * @Author: zhuxiankang
     * @Date:   2019-03-26 10:44:12
     * @Desc:   初始化表单项(目前的联动规则只考虑输入框和单选框)
     * @Parm:   {Object} item 表单项的数据
     */
    _initFormItem(item) {
      const { model, defaultValue } = item;
      const { form } = this;

      if (
        item.type.indexOf('el-') !== -1 ||
        item.type.indexOf('h-') !== -1 ||
        item.type === FORM_TYPE.IP_INPUTS ||
        item.type.indexOf('multi-') !== -1
      ) {
        // 多选器时，先判断children，再处理，其他情况都先判断defaultValue设置初始值
        if (
          [
            FORM_TYPE.RADIO_GROUP,
            FORM_TYPE.SELECT,
            FORM_TYPE.CHECKBOX
          ].includes(item.type)
        ) {
          this._initItemSelectValue(item);
          /* eslint-disable-next-line */
        } else if (item.hasOwnProperty('defaultValue')) {
          this.$set(form, model, JSON.parse(JSON.stringify(defaultValue)));
        } else {
          if (this.formType !== 'h-page-search') {
            console.warn(item.type + '组件缺少defaultValue设置');
          }
          switch (item.type) {
            // 开关
            case FORM_TYPE.SWITCH:
              this.$set(
                form,
                model,
                (item.props && item.props.inactiveValue) || false
              );
              break;

            default:
              this.$set(form, model, FORM_DEFAULT[item.type]);
              break;
          }
        }
      }

      // 特殊组件处理，如输入框的级联处理，密码设置密码强度的初始值
      if ([FORM_TYPE.INPUT, FORM_TYPE.IP_INPUT].includes(item.type)) {
        // this._setItemLinkage(item, defaultValue || '');
      } else if (
        item.type === FORM_TYPE.PWD_INPUT ||
        (item.type === FORM_TYPE.ENCRYPT_PASSWORD && item.pwdStrength)
      ) {
        this.$set(form, item.pwdStrength, 0);
      }

      // 放开级联的组件要求，switch等组件的值正好是Boolean值
      if (defaultValue === false || defaultValue) {
        this._setItemLinkage(
          item,
          defaultValue === false || defaultValue ? defaultValue : ''
        );
      }
    },

    /**
     * @Author: zhuxiankang
     * @Date:   2019-03-26 11:00:22
     * @Desc:   初始化单选框表单项的值
     * @Parm:   {Object} item 表单项的数据
     *          {Boolean} multiple 是否是多选
     */
    _initItemSelectValue(item) {
      const { children, model } = item;

      // 设置默认值
      this.$set(
        this.form,
        model,
        item.defaultValue || (item.props && item.props.multiple ? [] : '')
      );

      if (!children || !children.length) {
        console.warn(
          `the 'children' with model '${model}' must be array in dynamic-form component!`
        );
      }

      // const child = children[0];
      // const childValue = child.props.value && child.props.value || '';

      // 如果是单选框，初始化的时候设置联动项
      // if (item.props && !item.props.multiple && item.defaultValue) {
      //   this._setItemLinkage(item, item.defaultValue);
      // }
    },

    /**
     * @Author: zhuxiankang
     * @Date:   2019-03-27 19:08:55
     * @Desc:   初始化表单项的校验规则
     * @Parm:   {Object} item 表单项的数据
     */
    _initItemRule(item) {
      if (
        item.type === FORM_TYPE.IP_INPUTS ||
        item.type.indexOf('multi-') !== -1
      )
        return [];

      let rules = [];
      const { regular, minlength, tips, validators } = item.props || {};
      const TRIGGER_BLUR = 'blur';

      // 由于动态表单还存在部分项是数组或者对象，扩展一下非空判断
      if (item.props && item.props.required) {
        const requiredRegular = {
          type: item.props.regularType || 'string',
          message:
            item.props.requiredTips || this.t('h.dynamicForm.requiredTips'),
          required: true,
          trigger: TRIGGER_BLUR
        };
        if (
          item.props.regularType &&
          (item.props.regularType === 'array' ||
            item.props.regularType === 'object')
        ) {
          // 日后若将校验字段抽离出来，则可设置字段一一对应，无需再转化
          const allFields = ['regularLen', 'regularOptions', 'regularFields'];
          allFields.forEach(field => {
            if (item.props[field]) {
              // 先转化成校验工具需要的字段
              const itemField = field.split('regular')[1].toLowerCase();
              requiredRegular[itemField] = item.props[field];
            }
          });
        } else {
          requiredRegular.transform = function(value) {
            return String(value);
          };
        }
        rules.push(requiredRegular);
      }

      if (regular || minlength) {
        rules.push({
          validator: (rule, value, callback) => {
            // 密码输入框中的密码是回显密码，则通过校验
            if (
              item.type === FORM_TYPE.PWD_INPUT &&
              value === ((item.props && item.props.echoPassword) || '********')
            ) {
              return callback();
            }
            if (
              value &&
              (!new RegExp(regular).test(value) ||
                String(value).length < minlength)
            ) {
              return callback(new Error(tips));
            }
            return callback();
          },
          trigger: TRIGGER_BLUR
        });
      }

      if (validators && validators.length > 0) {
        for (const index in validators) {
          rules.push({
            validator: validation.setValidator(
              validators[index],
              this.$dyValidator
            ),
            trigger: 'change'
          });
        }
      }

      // 判断是否有用户自定义的校验
      if (this.pluginRules && item.model && this.pluginRules[item.model]) {
        const rule = this.pluginRules[item.model];
        if (Array.isArray(this.pluginRules[item.model])) {
          rules = [...rules, ...rule];
        } else {
          rules.push(this.pluginRules[item.model]);
        }
      }

      return rules;
    },

    // @description: 动态表单联动
    // ------------------------------------------------------------------------------------------------

    /**
     * @author: zhuxiankang
     * @since: 2019-06-03 13:45:27
     * @description: 初始化表单的联动规则监听事件
     * @param: {Object} item 表单项的数据
     * @returns:
     */
    _initItemLinkage(item) {
      // 判断表单项是否需要联动
      if (!item.cascades || !item.cascades.length || item.cascadeField) return;
      this.$nextTick(() => {
        // 监听需要联动的表单项
        this.$refs[item.model] &&
          this.$refs[item.model][0].$on('change', value =>
            this.handlerItemLinkageChange(item.cascades, value)
          );
      });
    },

    /**
     * @author: zhuxiankang
     * @since: 2019-06-03 19:13:39
     * @description: 设置表单的联动规则
     * @param: {Object} item 表单项的渲染数据
     * @param: {String} value 表单项的数据
     * @returns:
     */
    _setItemLinkage(item, value) {
      // 判断表单项是否需要联动
      if (!item.cascades || !item.cascades.length) return;
      this.handlerItemLinkageChange(item.cascades, value);
    },

    /**
     * @author: zhuxiankang
     * @since: 2019-06-03 15:55:08
     * @description: 动态表单联动渲染数据变化监听
     * @param: {Object} cascades 当前变化的表单项联动信息
     *         {String} value 当前变化的表单项数据
     * @returns:
     */
    handlerItemLinkageChange(cascades, value) {
      // 根据联动值匹配需要更改的表单项
      // 若是cascade数据里有指定根据什么数据进行联动，则根据指定数据联动，否则默认根据当前组件的value进行联动（此操作比较恶心，偏业务性）
      const cascade = cascades.find(item =>
        item.fieldModel
          ? item.value === this.extendForm[item.fieldModel]
          : item.value === value
      );
      if (!cascade || !cascade.fields || !cascade.fields.length) return;
      // 重新设置表单渲染项
      this._setFormRenderData(cascade.fields);
    },

    /**
     * @author: zhuxiankang
     * @since: 2019-06-03 14:04:04
     * @description: 设置表单的动态渲染数据信息
     * @param:  {Array} data 需要渲染的表单信息
     *          {Array} fields 因为联动需要重新渲染的表单项信息集合
     * @returns:
     */
    _setFormRenderData(fields) {
      try {
        // 需要注意联动字段cascades永远不会变化，因此可以随意改动renderData渲染值
        let copyData = JSON.parse(JSON.stringify(this.renderData));

        // 更新被联动的表单项信息
        if (fields && fields.length) {
          for (const field of fields) {
            // let findField = copyData.find(item => item.model === field.model)
            const findFieldIndex = copyData.findIndex(
              item => item.model === field.model
            );
            if (findFieldIndex === -1) continue;
            const findField = copyData[findFieldIndex];
            this._setFormItemLinkageValue(field, findField);
            this._deepObjectMerge(copyData[findFieldIndex], field);
            // 联动后组件 hide 为 true 时，原有的 change 事件会失效，当 hide 变回 false 时，需要重新绑定一下
            if (findField.cascades && !field.hide) {
              this._initItemLinkage(findField);
              // 重新设置 change 事件后，不会立刻根据当前数据触发 change 事件，需要手动处理一下联动
              this.$nextTick(() => {
                this._setItemLinkage(findField, this.form[findField.model]);
              });
            }
          }
        }

        copyData = copyData.sort(this.compare('order'));

        // 渲染联动后的表单信息
        this.renderData = copyData;

        // 重新设置校验规则
        this._setFormItemLinkageRules();
      } catch (err) {
        console.error(err);
      }
    },

    /**
     * @author: zhuxiankang
     * @since: 2019-06-10 18:54:07
     * @description: 设置联动的默认显示值
     * @param: {Object} field 表单的联动渲染信息
     *         {Object} findField 原有基础的表单渲染信息
     * @returns:
     */
    _setFormItemLinkageValue(field, findField) {
      const { form } = this;
      const { model } = field;

      // 后端强行要改变用户选择的数据行为
      /* eslint-disable-next-line */
      if (field.hasOwnProperty('defaultValue')) {
        const originalValue = this.form[field.model];
        // 组件渲染完成后，用户主动的行为才能更改级联更改defaultValue的值，防止数据级联是由setForm引起的，导致回填数据被级联的defaultValue覆盖
        if (!this.isSetDating) {
          this.$set(
            form,
            model,
            JSON.parse(JSON.stringify(field.defaultValue))
          );
          // 因此类业务场景少见，先用此方法，后续重新封装的diff算法因为耗性能，也要做配置是否开启
          // 此方法也有一定极端场景下的问题，比如选项A时，输入框是一个校验规则，选项B时，校验规则是另一个，此时重新主动触发的校验规则还停留在上一次
          // 目前因这两类场景叠加的情况不存在，故先用此方法，后续若有此类需求，再封装一个diff算法比较联动前后两次数据的变化，然后主动触发变动数据的校验
          if (
            this.isUpdated &&
            !findField.hide &&
            field.defaultValue !== originalValue
          ) {
            this.autoValidateField(findField);
          }
        }
      }
      // 若是级联更改了select的children，不需要默认选中第一项，故先注释此部分内容
      // else {
      //   const children = field.children;

      //   // 如果是下拉框
      //   if (
      //     findField.type === FORM_TYPE.SELECT &&
      //     children &&
      //     children.length
      //   ) {
      //     // 判断用户的原来选择的项是否仍然在新的下拉框信息中
      //     const findChild = children.find(
      //       child => child.value === this.form[model]
      //     );
      //     // 如果用户原来的选择项在新的下拉框信息中不存在，则默认选中第一项
      //     if (!findChild) {
      //       this.$set(form, model, field.children[0].props.value);
      //     }
      //   }
      // }
    },

    /**
     * @author: zhuxiankang
     * @since: 2019-06-10 19:00:43
     * @description: 重新设置联动后的校验规则（覆盖默认的校验规则）
     * @param:
     * @returns:
     */
    _setFormItemLinkageRules() {
      for (const item of this.renderData) {
        // 设置表单项的校验规则
        this.rules[item.model] = this._initItemRule(item);
      }
    },

    /**
     * @description: 深度合并对象
     * @param:
     * @returns:
     */
    _deepObjectMerge(FirstOBJ, SecondOBJ) {
      for (var key in SecondOBJ) {
        FirstOBJ[key] =
          FirstOBJ[key] && FirstOBJ[key].toString() === '[object Object]'
            ? this._deepObjectMerge(FirstOBJ[key], SecondOBJ[key])
            : (FirstOBJ[key] = SecondOBJ[key]);
      }
      return FirstOBJ;
    },

    /**
     * @Desc:   联动和回填数据时需要重新触发校验规则，防止当前组件校验规则停留在上一次的状态
     * @Parm:   {Object} item 当前需要渲染的表单项数据
     */
    autoValidateField(itemData) {
      this.$nextTick(() => {
        /* eslint-disable-next-line */
        if (this.rules.hasOwnProperty(itemData.model) &&
          itemData.type === FORM_TYPE.INPUT &&
          !itemData.hide
        ) {
          this.$refs.form.validateField(itemData.model);
        }
      });
    },

    // @description: 表单事件处理
    // ------------------------------------------------------------------------------------------------

    /**
     * @Desc:   input控件，点击回车时，抛出回调
     * @Parm:   {Object} item 当前需要渲染的表单项数据
     */
    handleInputEnter(item) {
      if (item.type === 'el-input' || item.type === 'h-ip-input') {
        this.$emit('form-keyup-enter', item, this.form[item.model]);
      }
    },

    // @description: 动态表单对外API
    // ------------------------------------------------------------------------------------------------

    /**
     * @Author: zhuxiankang
     * @Date:   2019-03-26 14:23:04
     * @Desc:   获取表单信息
     * @Parm:
     */
    getForm() {
      // 获取页面操作的字段信息
      const form = JSON.parse(JSON.stringify(this.form));

      // 需要隐藏的字段信息传输初始化的值
      for (const field of this.renderData) {
        if (field.hide && !field.commitEvenHide) {
          // this._initFormItem(field);
          delete form[field.model];
        }
      }

      // 返回处理后的字段信息值
      // const hideForm = JSON.parse(JSON.stringify(this.form));

      // 还原页面操作的字段信息
      // this.form = form;

      return form;
    },

    /**
     * @Author: zhuxiankang
     * @Date:   2019-03-26 14:23:34
     * @Desc:   设置表单信息
     * @Parm:   {Object} from 表单信息
     */
    setForm(form) {
      this.form = form;
      // 除select外很多组件手动更改value值并不能引起change变化，因此主动设置一下级联
      for (var i in form) {
        const itemData = this.data.find(item => item.model === i);
        // select、radio-group控件数据变化会自动引起change事件，若这里再次触发联动，会导致回填数据被defaultValue覆盖
        if (
          itemData &&
          itemData.type !== 'el-select' &&
          itemData.type !== 'el-radio-group' &&
          itemData.cascades &&
          !itemData.cascadeField
        ) {
          this._setItemLinkage(itemData, form[i]);
        }
        // 当静态页面涉及到业务非编辑时，因为某些原因在页面初始化时用到此方法，可能会出现一进入页面，就报校验问题，体验不好，先隐去
        // this.autoValidateField(itemData);
      }
      this.isSetDating = true;
    },

    /**
     * @Author: zhuxiankang
     * @Date:   2019-03-26 14:20:42
     * @Desc:   设置表单项信息
     * @Parm:   {String} key 表单属性
     *          {String} value 表单值
     */
    setFormItem(key, value) {
      this.$set(this.form, key, value);
      const itemData = this.data.find(item => item.model === key);
      // select、radio-group控件数据变化会自动引起change事件，若这里再次触发联动，会导致回填数据被defaultValue覆盖
      if (
        itemData &&
        itemData.type !== 'el-select' &&
        itemData.type !== 'el-radio-group' &&
        itemData.cascades &&
        !itemData.cascadeField
      ) {
        this._setItemLinkage(itemData, value);
      }
      // 当静态页面涉及到业务非编辑时，因为某些原因在页面初始化时用到此方法，可能会出现一进入页面，就报校验问题，体验不好，先隐去
      // this.autoValidateField(itemData);
    },

    /**
     * @Author: zhuxiankang
     * @Date:   2019-03-26 14:21:54
     * @Desc:   获取表单项信息
     * @Parm:   {String} key 表单属性
     */
    getFormItem(key) {
      return this.form[key];
    },

    /**
     * @Author: zhuxiankang
     * @Date:   2019-03-27 20:46:02
     * @Desc:   获取当前动态表单组件的注册引用信息
     * @Parm:
     */
    getFormRef() {
      return this.$refs.form;
    },

    /**
     * @author: zhuxiankang
     * @since: 2019-04-09 16:12:28
     * @description: 对整个表单的校验信息进行重置，移除所有校验结果
     * @param:
     * @returns:
     */
    resetFields() {
      this.$refs.form.resetFields();

      // 调用自定义控件的重置表单方法
      const { $refs } = this;
      for (const refKey in $refs) {
        if (
          refKey.indexOf('dynamic-') > -1 &&
          $refs[refKey] &&
          $refs[refKey][0]
        ) {
          // 如果该自定义控件存在 resetFields 则调用
          if ($refs[refKey][0].resetFields) {
            $refs[refKey][0].resetFields();
          }
        }
      }
    },

    /**
     * @author: zhuxiankang
     * @since: 2019-04-28 19:32:55
     * @description: 移除所有的表单校验信息，搜索表单无此方法
     * @param:
     * @returns:
     */
    resetValidates() {
      this.$refs.form.resetValidates && this.$refs.form.resetValidates();

      // 调用自定义控件的重置表单方法
      const { $refs } = this;
      for (const refKey in $refs) {
        if (
          refKey.indexOf('dynamic-') > -1 &&
          $refs[refKey] &&
          $refs[refKey][0]
        ) {
          // 如果该自定义控件存在 resetValidates 则调用
          if ($refs[refKey][0].resetValidates) {
            $refs[refKey][0].resetValidates();
          }
        }
      }
    },

    /**
     * @author: zhuxiankang
     * @since: 2019-04-13 09:47:12
     * @description: 对整个表单进行校验
     * @param:
     * @returns:
     */
    validate() {
      const { $refs } = this;

      return new Promise(resolve => {
        $refs.form.validate(async valid => {
          let childValids = true;
          for (const refKey in $refs) {
            if (
              refKey.indexOf('dynamic-') > -1 &&
              $refs[refKey] &&
              $refs[refKey][0]
            ) {
              let childValidResult = true;
              if ($refs[refKey][0].validate) {
                childValidResult = await $refs[refKey][0].validate();
              } else {
                childValidResult = await this.itemValidate($refs, refKey);
              }
              childValids = childValidResult && childValids;
            }
          }
          resolve(valid && childValids);
        });
      });
    },
    itemValidate($refs, refKey) {
      return new Promise(resolve => {
        const itemChildRefs = $refs[refKey][0].$refs;
        const itemChildRef = Object.keys(itemChildRefs)[0];
        itemChildRefs[itemChildRef].validate(valid => {
          resolve(valid);
        });
      });
    },
    dataChange(obj) {
      Object.assign(this.form, obj);
    },

    // @description: 动态表单一些非常规事件
    // ------------------------------------------------------------------------------------------------

    /**
     * @description: 自定义组件抛出额外数据变化的事件，如ip-inputs组件，需要根据单个还是区间进行联动（此操作比较恶心，偏业务性）
     * @param:
     * @returns:
     */
    extendFormChange(item, val) {
      if (!item.cascades || !item.cascades.length || !item.cascadeField) return;

      Object.assign(this.extendForm, val);
      this.handlerItemLinkageChange(item.cascades);
    }
  }
};
</script>
