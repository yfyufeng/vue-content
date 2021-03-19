<template>
  <span>
    <template v-for="(child, index) in childrenData || []">
      <component
        v-if="typeof child === 'object'"
        :key="index"
        :is="child.type"
        v-bind="[child.props]"
      >
        <h-dynamic-form-children
          v-if="child.children"
          :children-data="child.children"
        ></h-dynamic-form-children>
      </component>
      <template v-else>
        {{ child }}
      </template>
    </template>
  </span>
</template>

<script>
export default {
  name: 'HDynamicFormChildren',
  props: {
    childrenData: {
      type: Array,
      default: null
    }
  }
};
</script>
