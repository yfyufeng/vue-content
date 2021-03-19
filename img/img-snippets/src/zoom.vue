<template>
  <div class="h-img-snippets-zoom">
    <el-button
      class="h-img-snippets-zoom__btn"
      icon="h-icon-zoom_out"
      @click="zoomOut"
    />
    <span class="h-img-snippets-zoom__scale" v-text="text" />
    <el-button class="h-zoom__btn" icon="h-icon-zoom_in" @click="zoomIn" />
  </div>
</template>

<script>
export default {
  name: 'HImgSnippetsZoom',
  props: {
    scale: {
      type: Number,
      default: 1
    }
  },
  computed: {
    text() {
      return `${(this.scale * 100).toFixed(0)}%`;
    }
  },
  methods: {
    zoomOut() {
      this.$emit('zoom-out', this.scale);
    },
    zoomIn() {
      this.$emit('zoom-in', this.scale);
    }
  }
};
</script>
