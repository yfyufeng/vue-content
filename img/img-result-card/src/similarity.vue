<template>
  <span
    v-if="percent !== null"
    :class="{
      [`h-image-result-card-group-similarity--${bg}`]: true,
      'h-image-result-card-group-similarity': true
    }"
  >
    <div class="h-image-result-card-group-similarity--inner">
      <span
        class="h-image-result-card-group-similarity--primary-text"
        v-text="primaryText"
      />
      <span
        class="h-image-result-card-group-similarity--sub"
        v-text="subText"
      />
      <span>%</span>
    </div>
  </span>
</template>

<script>
export default {
  // name: 'SwSimilarity',
  props: {
    percent: {
      type: Number,
      default: 100
    },
    bg: {
      type: String,
      default: 'danger',
      validator: function(value) {
        return ['info', 'danger', 'warning', 'success'].indexOf(value) !== -1;
      }
    }
  },
  computed: {
    primaryText: function() {
      const textArr = (this.percent + '').split('.');
      return textArr.length === 1 ? this.percent : `${textArr[0]}.`;
    },
    subText: function() {
      const textArr = (this.percent + '').split('.');
      return textArr.length === 1 ? '' : `${textArr[1]}`;
    }
  }
};
</script>
