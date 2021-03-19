<template>
  <div
    :class="[`h-img-snippets-btn-group--theme-${theme}`]"
    class="h-img-snippets-btn-group"
  >
    <slot />
  </div>
</template>

<script>
export default {
  name: 'HImgSnippetsBtnGroup',
  props: {
    theme: {
      type: String,
      default: 'light',
      validator(value) {
        return ['light', 'light-gray', 'transparent'].includes(value);
      }
    }
  }
};
</script>
