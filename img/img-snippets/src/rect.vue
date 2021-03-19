<template>
  <div
    v-if="show"
    ref="rect"
    :style="{
      width: `${rect[props.width] * 100}%`,
      height: `${rect[props.height] * 100}%`,
      top: `${rect[props.top] * 100}%`,
      left: `${rect[props.left] * 100}%`
    }"
    :class="[
      `h-img-snippets-rect--${type}`,
      {
        'is-hide': hideSlot
      }
    ]"
    class="h-img-snippets-rect"
  >
    <slot v-if="!hideSlot" />
  </div>
</template>

<script>
import { merge, size, isNull } from '@hui-pro/utils';
export default {
  name: 'HImgSnippetsRect',
  props: {
    type: {
      type: String,
      default: 'danger',
      validator(value) {
        return (
          ['primary', 'danger', 'warning', 'success', 'info'].indexOf(value) !==
          -1
        );
      }
    },
    rect: {
      type: Object,
      default: () => {
        return {
          width: 0,
          height: 0,
          top: 0,
          left: 0
        };
      }
    },
    rectProps: {
      type: Object,
      default: () => {
        return {};
      }
    },
    limitData: {
      type: Object,
      default: () => {
        return {};
      }
    }
  },
  data() {
    return {
      props: {
        height: 'height',
        width: 'width',
        left: 'left',
        top: 'top'
      },
      limit: {
        hideSlotWidth: 24,
        hideSlotHeight: 24
      },
      hide: false
    };
  },
  computed: {
    show() {
      return (
        !isNull(this.rect) &&
        this.rect[this.props.width] &&
        this.rect[this.props.height]
      );
    },
    hideSlot() {
      const $rect = this.$refs.rect;
      if (!$rect) {
        return false;
      }
      const rectSize = size($rect);
      return (
        rectSize.width < this.limit.hideSlotWidth ||
        rectSize.height < this.limit.hideSlotHeight
      );
    }
  },
  created() {
    this.props = merge(this.props, this.rectProps);
    this.limit = merge(this.limit, this.limitData);
  }
};
</script>
