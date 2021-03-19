<template>
  <div ref="imgCard" class="h-img-card">
    <div
      :class="{ hasPagination: $slots.pagination }"
      class="h-img-card-content"
    >
      <el-scrollbar ref="scrollbar" wrap-class="h-img-scrollbar">
        <slot v-if="$slots.custom" name="custom"></slot>
        <h-img-card-item v-for="(item, index) in picList" v-else :key="index">
          <div
            :class="{ active: item.active }"
            class="h-card-content"
            @click="clickImgBox(item)"
            @mouseover="mouseover($event, item)"
            @mouseout="mouseout($event, item)"
          >
            <template>
              <slot :row="item" :index="index"></slot>
            </template>
          </div>
        </h-img-card-item>
      </el-scrollbar>
    </div>
    <div v-if="$slots.pagination" class="h-img-pagination">
      <slot name="pagination"></slot>
    </div>
  </div>
</template>

<script>
/* * @Author: zhengjie7 * @Date: 2019-03-16 14:53:35 * @Last Modified by:
zhengjie7 * @Last Modified time: 2019-03-19 10:30:12 * 卡片的展示页面布局的封装
* 图片比例1:1 * n ≤750px，采用col-md-8(3等分) * 750＜n ≤1216px,
采用col-lg-6(4等分) * 1216＜n ≤ 1680px，采用col-xl-4(6等分) * n＞1680 px
，采用col-xxl-3(8等分) * 图片比例16:9 * n ≤750px，采用col-md-12(2等分) * 750＜n
≤1216px, 采用col-lg-8(3等分) * 1216＜n ≤ 1680px，采用col-xl-6(4等分) * n＞1680
px ，采用col-xxl-4(6等分) */
import { on, off } from '@hui-pro/utils';
export default {
  name: 'HImgCard',
  props: {
    picList: {
      type: Array,
      default: () => {
        return [];
      }
    },
    cardRatio: {
      type: String,
      default: '16:9'
    },
    customSpan: {
      // 支持用户自定义栅格比
      type: Object,
      default: null
    }
  },
  provide() {
    return {
      item: this
    };
  },
  data() {
    return {
      img: null,
      span: 6
    };
  },
  mounted() {
    this.changeSpan();
    on(window, 'resize', this.changeSpan);
  },
  beforeDestroy() {
    off(window, 'resize', this.changeSpan);
  },
  methods: {
    // 自适应处理
    changeSpan() {
      if (!this.img) {
        this.img = window.getComputedStyle(this.$refs.imgCard);
      }

      // 支持用户自定义栅格比
      // edit by xuzilong.
      if (this.customSpan) {
        const { xs, sm, md, lg } = this.customSpan;
        if (parseInt(this.img.width) <= 750) {
          this.span = xs || 8;
        } else if (parseInt(this.img.width) <= 1216) {
          this.span = sm || 6;
        } else if (parseInt(this.img.width) <= 1680) {
          this.span = md || 4;
        } else if (parseInt(this.img.width) <= 1920) {
          this.span = lg || 3;
        } else {
          // 兼容大于1920下的问题
          this.span = lg || 3;
        }
        return;
      }

      // 根据图片不同比例，不同的适配
      if (this.cardRatio === '1:1') {
        if (parseInt(this.img.width) <= 750) {
          this.span = 8;
        } else if (parseInt(this.img.width) <= 1216) {
          this.span = 6;
        } else if (parseInt(this.img.width) <= 1680) {
          this.span = 4;
        } else if (parseInt(this.img.width) <= 1920) {
          this.span = 3;
        } else {
          // 兼容大于1920下的问题
          this.span = 3;
        }
      } else if (this.cardRatio === '16:9') {
        if (parseInt(this.img.width) <= 750) {
          this.span = 12;
        } else if (parseInt(this.img.width) <= 1216) {
          this.span = 8;
        } else if (parseInt(this.img.width) <= 1680) {
          this.span = 6;
        } else if (parseInt(this.img.width) <= 1920) {
          this.span = 4;
        } else {
          // 兼容大于1920下的问题
          this.span = 4;
        }
      }
    },
    // 卡片点击
    clickImgBox(item) {
      this.$emit('clickImgBox', item);
    },
    mouseover(event, item) {
      this.$emit('mouseover', event, item);
    },
    mouseout(event, item) {
      this.$emit('mouseout', event, item);
    }
  }
};
</script>
