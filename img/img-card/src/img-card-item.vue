<template>
  <el-col :span="span" class="h-card-warpper">
    <slot></slot>
  </el-col>
</template>

<script>
export default {
  name: 'HImgCardItem',
  inject: ['item'],
  data() {
    return {};
  },
  computed: {
    span() {
      return this.item.span;
    }
  }
};
</script>
