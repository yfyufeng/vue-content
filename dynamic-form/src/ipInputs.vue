<template>
  <el-row class="dolphin-ips">
    <el-form ref="form" :model="ips">
      <el-row class="dolphin-ips-type">
        <el-radio-group
          v-model="type"
          :type="data.props && data.props.type ? data.props.type : 'simple'"
          @change="handlerTypeChange"
        >
          <el-radio-button :label="TYPE.SINGLE">
            {{
              (data.props && data.props.simpleText) || t('h.dynamicForm.single')
            }}
          </el-radio-button>
          <el-radio-button :label="TYPE.MULT">
            {{
              (data.props && data.props.multiText) || t('h.dynamicForm.section')
            }}
          </el-radio-button>
        </el-radio-group>
      </el-row>

      <el-col :span="10">
        <el-form-item
          ref="start"
          :rules="ipRule(IPS.START, IPS.END)"
          prop="start"
          class="dolphin-ips-item"
          content-width="172"
        >
          <h-ip-input
            ref="hIpInput"
            v-model="ips.start"
            :tips="data.props.tips || ''"
            :disabled="data.props.disabled || false"
            :tips-placement="tipsPlacement"
            width="172px"
            @input.native="handerIpInput(IPS.START, IPS.END)"
          ></h-ip-input>
        </el-form-item>
      </el-col>
      <el-col v-show="type === TYPE.MULT" :span="2">
        ~
      </el-col>
      <el-col v-if="type === TYPE.MULT" :span="10">
        <el-form-item
          ref="end"
          :rules="ipRule(IPS.END, IPS.START)"
          prop="end"
          class="dolphin-ips-item"
          content-width="172"
        >
          <h-ip-input
            ref="hIpInput"
            v-model="ips.end"
            :tips="data.props.tips || ''"
            :disabled="data.props.disabled || false"
            :tips-placement="tipsPlacement"
            width="172px"
            @input.native="handerIpInput(IPS.END, IPS.START)"
          ></h-ip-input>
        </el-form-item>
      </el-col>
    </el-form>
  </el-row>
</template>

<script>
import { t } from '@hui-pro/locale';
const IPS = {
  START: 'start',
  END: 'end'
};

const TYPE = {
  SINGLE: 1,
  MULT: 2
};

export default {
  name: 'IpInputs',

  props: {
    data: {
      type: Object,
      default: null
    },

    tipsPlacement: {
      type: String,
      default: 'top'
    },

    ip: {
      type: Array,
      default: null
    },

    form: {
      type: Object,
      default: null
    }
  },
  data() {
    return {
      t,
      ips: {
        start: '',
        end: ''
      },
      type: TYPE.SINGLE,
      TYPE,
      IPS
    };
  },

  watch: {
    // 用户复制黏贴的行为
    'ips.start'() {
      this.handerIpInput(IPS.START, IPS.END);
    },

    'ips.end'() {
      this.handerIpInput(IPS.END, IPS.START);
    },

    form: {
      handler(value) {
        // 获取当前ip控件的ip数组
        let ip = value[this.data.model];
        // 若获取到的值不是数组，先转为数组
        if (ip && !Array.isArray(ip)) {
          ip = ip.split(',');
        }
        this.ips.start = ip[0] || '';
        if (ip[1]) {
          this.ips.end = ip[1];
          this.type = this.TYPE.MULT;
        }
      },
      immediate: true
    }
  },

  created() {
    this.$emit('extendFormChange', this.data, { ipsType: this.type });
  },

  methods: {
    /**
     * @author: zhuxiankang
     * @since: 2019-05-16 15:47:30
     * @description: ip规则校验
     * @param: {String} current 当前表单信息
     *         {String} refercne 对应的项
     * @returns:
     */
    ipRule(current, reference) {
      const rule = [];

      rule.push({
        validator: (rule, value, callback) => {
          const { ips } = this;

          const currentIp = ips[current].split('.');
          const referenceIp = ips[reference].split('.');
          const startIp = ips.start.split('.');
          const endIp = ips.end.split('.');

          // 是否是空的IP地址
          if (this.isIpEmpty(currentIp)) {
            return callback(new Error(this.t('h.dynamicForm.requiredTips')));
          } else if (!this.isIpFull(currentIp)) {
            // 是否是完整的IP地址
            return callback(new Error(this.t('h.dynamicForm.ipErr')));
          } else if (this.type === TYPE.MULT) {
            if (
              this.isIpFull(referenceIp) &&
              Number(startIp[3] > Number(endIp[3]))
            ) {
              return callback(new Error(this.t('h.dynamicForm.ipNumberErr')));
            }
          }
          return callback();
        },
        trigger: 'blur'
      });
      return rule;
    },

    /**
     * @description: IP地址是否为空
     * @param:  {Array} ips 切割后的IP数组
     * @returns:
     */
    isIpEmpty(ips) {
      // IP地址分为4段
      const IP_LENGTH = 4;
      // 默认当前IP填写完整
      let isEmpty = true;
      for (let i = 0; i < IP_LENGTH; i++) {
        if (ips[i]) {
          isEmpty = false;
          break;
        }
      }
      return isEmpty;
    },

    /**
     * @author: zhuxiankang
     * @since: 2019-06-05 10:19:01
     * @description: IP地址是否填写完整
     * @param:  {Array} ips 切割后的IP数组
     * @returns:
     */
    isIpFull(ips) {
      // IP地址分为4段
      const IP_LENGTH = 4;
      // 默认当前IP填写完整
      let isFull = true;
      for (let i = 0; i < IP_LENGTH; i++) {
        if (!ips[i]) {
          isFull = false;
          break;
        }
      }
      return isFull;
    },

    /**
     * @author: zhuxiankang
     * @since: 2019-05-16 16:41:22
     * @description: 失去焦点时触发校验,手动校验起始或者截止类型
     * @param: {String} ref 当前操作项的对应操作项
     *          {String} type 当前校验项
     * @returns:
     */
    validateIp(current, reference) {
      const { ips } = this;
      const currentIp = ips[current].split('.');
      const referenceIp = ips[reference].split('.');

      if (currentIp.length < 4 || referenceIp.length < 4) {
        return;
      }

      this.$nextTick(() => {
        // // 如果当前校验项未通过校验，则不需要对对应项进行校验处理
        // if (this.isItemRuleErr(current)) return
        // 对对应项进行校验处理
        this.$refs.form.validateField(reference);
      });
    },

    /**
     * @author: zhuxiankang
     * @since: 2019-05-16 16:06:58
     * @description: 起始IP地址输入变化监听
     * @param: {String} current 当前表单信息
     *         {String} refercne 对应的项
     * @returns:
     */
    handerIpInput(current, reference) {
      const { ips } = this;
      let currentIp = ips[current];
      let referenceIp = ips[reference];
      currentIp = currentIp.split('.');
      referenceIp = referenceIp.split('.');
      for (let i = 0; i < 3; i++) {
        referenceIp[i] = currentIp[i];
      }
      this.ips[reference] = referenceIp.join('.');

      this.emitIpData();

      if (this.type !== TYPE.MULT) return;
      this.validateIp(current, reference);
      this.validateIp(reference, current);
    },

    /**
     * @author: zhuxiankang
     * @since: 2019-05-24 17:19:09
     * @description: 设置表单信息
     * @param:
     * @returns:
     */
    emitIpData() {
      const { ips } = this;

      if (this.type !== TYPE.MULT) {
        this.$emit('update:multiValue', [ips.start]);
      } else if (ips.start === ips.end) {
        this.$emit('update:multiValue', [ips.start]);
      } else {
        this.$emit('update:multiValue', [ips.start, ips.end]);
      }
    },

    /**
     * @author: zhuxiankang
     * @since: 2019-04-23 09:33:08
     * @description: 当前表单项校验是否通过
     * @param: {String} ref 表单项
     * @returns:
     */
    isItemRuleErr(ref) {
      return this.$refs[ref].$el.className.includes('is-error');
    },

    /**
     * @author: zhuxiankang
     * @since: 2019-05-16 19:59:50
     * @description: 当前区间类型变化
     * @param:
     * @returns:
     */
    handlerTypeChange(value) {
      this.$emit('extendFormChange', this.data, { ipsType: value });
      if (value === TYPE.SINGLE) {
        this.$emit('update:multiValue', [this.ips.start]);
        if (!this.ips.start) return;
        this.$refs.form.validateField(IPS.START);
      } else {
        this.emitIpData();
      }
    },

    /**
     * @author: zhuxiankang
     * @since: 2019-05-16 19:39:03
     * @description: 校验表单信息
     * @param:
     * @returns:
     */
    validate() {
      return new Promise(resolve => {
        this.$refs.form.validate(valid => {
          resolve(valid);
        });
      });
    }
  }
};
</script>

<style lang="scss">
.dolphin-ips {
  .dolphin-ips-item {
    margin-bottom: 0;
  }
}

.dolphin-ips-type {
  margin-bottom: 12px;
}
</style>
