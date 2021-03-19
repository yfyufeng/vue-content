<template>
  <el-form ref="formAAA" :model="testForm" :rules="rules">
    <el-form-item prop="inputTest" content-width="172">
      <el-input
        v-model="testForm.inputTest"
        tips="请输入"
        tips-placement="top-start"
      />
    </el-form-item>
  </el-form>
</template>

<script>
const TYPE = {
  SINGLE: 1,
  MULT: 2
};

export default {
  name: 'DemoTest',

  props: {
    data: {
      type: Object,
      default: null
    },

    form: {
      type: Object,
      default: null
    }
  },
  data() {
    return {
      testForm: {
        inputTest: ''
      },
      type: TYPE.SINGLE,
      TYPE,
      rules: {
        inputTest: [
          {
            required: true,
            message: '请输入最长未刷卡时长',
            trigger: 'blur'
          }
        ]
      }
    };
  },

  watch: {
    form(value) {
      // 获取当前ip控件的ip数组
      // const ip = value[this.data.model];
      // this.ips.start = ip[0];
      // if (ip[1]) {
      //   this.ips.end = ip[1];
      // }
    }
  },

  mounted() {
    // this.$emit("update", '数据1')
  },

  methods: {
    /**
     * @author: zhuxiankang
     * @since: 2019-05-16 19:39:03
     * @description: 校验表单信息
     * @param:
     * @returns:
     */
    // validate() {
    //   return new Promise(resolve => {
    //     this.$refs.form.validate(valid => {
    //       resolve(valid);
    //     });
    //   });
    // }
  }
};
</script>
