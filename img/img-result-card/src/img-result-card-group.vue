<template>
  <div
    :class="{
      'h-image-result-card-group': true,
      'h-image-result-card-group--choosed': isChoosed && choosable,
      'h-image-result-card-group--active': active
    }"
  >
    <div v-if="similar" class="h-image-result-card-group__similar">
      <similarity :bg="similarBg" :percent="similarValue" />
    </div>
    <div class="h-image-result-card-group__item">
      <div
        v-if="choosable"
        :class="{
          'h-image-result-card-group__item-choosable': true,
          'h-image-result-card-group__item-choosable--active': isChoosed
        }"
        @click="chooseHandle"
      ></div>
      <div class="h-image-result-card-group__item-card">
        <slot></slot>
      </div>
      <div v-if="$slots.extra" class="h-image-result-card-group__item-extra">
        <slot name="extra"></slot>
      </div>
    </div>
  </div>
</template>

<script>
import Similarity from './similarity.vue';
export default {
  name: 'HImgResultCardGroup',
  components: {
    Similarity
  },
  props: {
    choosable: {
      type: Boolean,
      default: false
    },
    active: {
      type: Boolean,
      default: false
    },
    isChoosed: {
      type: Boolean,
      default: false
    },
    similar: {
      type: Boolean,
      default: false
    },
    similarValue: {
      type: Number,
      default: 0
    },
    similarBg: {
      type: String,
      default: 'danger'
    }
  },
  methods: {
    chooseHandle() {
      this.$emit('choose', this.data);
    }
  }
};
</script>
