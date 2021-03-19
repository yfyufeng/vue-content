<template>
  <div
    :style="{ width: `${width}px`, height: `${height}px` }"
    class="h-img-snippets-upload-btn"
  >
    <div
      :class="{ 'is-full': $slots.default }"
      class="h-img-snippets-upload-btn__container"
    >
      <template v-if="$slots.default">
        <slot />
        <div
          :class="{ 'is-show': showOverly }"
          class="h-img-snippets-upload-btn__overly"
          @mouseenter="handleMouseenter"
          @mouseleave="handleMouseleave"
        >
          <div class="btn-group">
            <slot v-if="$slots.btnGroup" name="btnGroup" />
            <template v-else>
              <i class="h-icon-reset" @click="resetClick" />
              <i class="h-icon-delete" @click="deleteClick" />
            </template>
          </div>
        </div>
      </template>
      <template v-else>
        <i class="h-icon-add" />
        <div
          :title="text"
          class="h-img-snippets-upload-btn__text"
          v-text="text"
        />
      </template>
    </div>
  </div>
</template>

<script>
import { t } from '@hui-pro/locale';
export default {
  name: 'HImgSnippetsUploadBtn',
  props: {
    text: {
      type: String,
      default: () => t('h.imgSnippets.upload')
    },
    width: {
      type: Number,
      default: null
    },
    height: {
      type: Number,
      default: null
    }
  },
  data: function() {
    return {
      t,
      showOverly: false
    };
  },
  methods: {
    resetClick() {
      this.$emit('reset');
    },
    deleteClick() {
      this.$emit('delete');
    },
    handleMouseenter() {
      this.showOverly = true;
    },
    handleMouseleave() {
      this.showOverly = false;
    }
  }
};
</script>
