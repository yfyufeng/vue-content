/* * @Author: jiangyan6 * @Date: 2018-12-06 15:27:49 * @Last Modified by:
jiangyan6 * @Last Modified time: 2018-12-06 18:53:48 * @Desc: 图片裁切 */
<template>
  <transition name="dialog-fade">
    <div v-if="visible" class="h-img-cropper">
      <!-- 关闭按钮 -->
      <div class="close-btn" @click="closeSelf">
        <img :src="closeNormal" :alt="t('h.imgCropper.close')" />
      </div>
      <!-- 图片图层 -->
      <div id="img-wrapper" class="img-wrapper">
        <img
          ref="previewImg"
          :src="url"
          :style="imgStyle"
          :alt="t('h.imgCropper.previewImg')"
          @load="updateImgSize"
        />
        <div class="img-modal"></div>
      </div>
      <!-- 裁切框图层 -->
      <div
        :style="{
          width: `${Number(size.width) + 1}px`,
          height: `${Number(size.height) + 1}px`
        }"
        class="cropper-wrapper"
      >
        <img
          :src="url"
          :style="imgStyle"
          :alt="t('h.imgCropper.previewImg')"
          @dragstart.prevent
        />
      </div>
      <!-- 用于操作的面板，跟预览图完全重合，且在预览图上方 -->
      <div
        id="operate-pannel"
        ref="operate-pannel"
        :style="imgStyle"
        class="operate-pannel"
      ></div>
      <!-- 操作按钮部分 -->
      <div class="operate-wrapper">
        <el-button type="primary" @click="saveHandler">
          {{ t('h.imgCropper.confirm') }}
        </el-button>
        <el-button @click="cancelHandler">
          {{ t('h.imgCropper.cancel') }}
        </el-button>
      </div>
      <canvas
        ref="canvas"
        :width="size.width"
        :height="size.height"
        :style="{ width: `${size.width}px`, height: `${size.height}px` }"
      >
        >
      </canvas>
    </div>
  </transition>
</template>

<script>
import closeNormal from '../theme/img/closed_nor.svg';
import closeHover from '../theme/img/closed_hor.svg';
import closePress from '../theme/img/closed_press.svg';
import { on, off } from '@hui-pro/utils';
import { t } from '@hui-pro/locale';
const MAX_SCALE = 5; // 图片最大放大倍数
const MIN_SCALE = 1; // 图片最小缩小倍数
export default {
  name: 'HImgCropper',
  props: {
    // 要剪裁的图片url
    url: {
      type: String,
      required: true
    },
    // 剪裁区域的宽高,Object类型，width:宽度，height:高度，单位px
    size: {
      type: Object,
      default: function() {
        return {
          width: 300,
          height: 300
        };
      }
    },
    visible: {
      type: Boolean,
      default() {
        return false;
      }
    }
  },
  data() {
    return {
      t, // 多语言翻译方法
      // 关闭图片的url
      closeNormal,
      closeHover,
      closePress,
      cropperWidth: 0, // 本地缓存裁切区域尺寸的宽度
      cropperHeight: 0, // 本地缓存裁切区域尺寸的高度
      imgNaturalWidth: 0, // 图片原始宽度
      imgNaturalHeight: 0, // 图片原始高度
      imgScale: 1, // 图片的缩放尺寸
      dragTempData: {
        srcX: 0, // 原鼠标clientX值
        srcY: 0, // 原鼠标clientY值
        srcTranslateX: 0, // 原图片translateX值
        srcTranslateY: 0, // 原图片translateY值
        nowTranslateX: 0, // 当前图片translateX值
        nowTranslateY: 0, // 当前图片translateY值
        rectTop: 0, // 原图片rectTop值
        rectRight: 0, // 原图片rectRight值
        rectBottom: 0, // 原图片rectBottom值
        rectLeft: 0 // 原图片rectLeft值
      }
    };
  },
  computed: {
    // 基于剪裁区域的宽高比例和图片的宽高比例计算图片的宽高（保证图片的最小边占满容器）
    imgStyle() {
      // 计算剪裁区域的宽高比
      const cropperRatio = this.size.width / this.size.height;
      // 计算剪裁原图的宽高比
      const imgRatio = this.imgNaturalWidth / this.imgNaturalHeight;
      return {
        width:
          imgRatio > cropperRatio
            ? `${parseInt(this.cropperHeight * this.imgScale * imgRatio)}px`
            : `${parseInt(this.cropperWidth * this.imgScale)}px`,
        height:
          imgRatio < cropperRatio
            ? `${parseInt(this.cropperWidth * this.imgScale) / imgRatio}px`
            : `${parseInt(this.cropperHeight * this.imgScale)}px`,
        transform: `translate(-50%, -50%) translateX(${this.dragTempData.nowTranslateX}px) translateY(${this.dragTempData.nowTranslateY}px)`
      };
    },
    // 预览图片可偏移的极限
    limitTranslate() {
      // 初始化X轴、Y轴的偏移范围
      const X = [0, 0];
      const Y = [0, 0];
      // 根据图片缩放状态计算X轴、Y轴的偏移范围
      const actualWidth = parseInt(this.imgStyle.width);
      const actualHeight = parseInt(this.imgStyle.height);
      // 这里实际上偏移范围的上下限总是一对相反数
      X[0] = -parseInt((actualWidth - this.size.width) / 2);
      X[1] = parseInt((actualWidth - this.size.width) / 2);
      Y[0] = -parseInt((actualHeight - this.size.height) / 2);
      Y[1] = parseInt((actualHeight - this.size.height) / 2);
      return {
        X,
        Y
      };
    }
  },
  watch: {
    visible(val) {
      if (val) {
        // 挂载完成时，把组件html渲染到body中
        document.body.appendChild(this.$el);
        this.$nextTick(() => {
          // 启用滚轮缩放
          this.enableScale();
          // 启用拖拽
          this.enableDrag();
        });
      } else {
        this.destroySelf();
      }
    }
  },
  created() {
    // 先缓存外部传入的剪裁区域尺寸
    this.saveCropperSize();
  },
  /*
   * @Author: jiangyan6
   * @Date: 2019-07-22 17:01:52
   * @Desc: @NOTE:这里由于可能出现一个页面存在多个实例的情况，所以不在
   * mounted钩子中绑定事件，因为可能存在id或者其他dom标识冲突。改为在watch中
   * 通过监测visible的值，如果是true，那么在dom中插入相关dom并绑定事件，如果
   * 为false那么移除绑定事件，并移除相关dom。
   * @param:
   * @return:
   */
  mounted() {
    // 挂载完成时，把组件html渲染到body中
    // document.body.appendChild(this.$el);
    // 启用滚轮缩放
    // this.enableScale();
    // 启用拖拽
    // this.enableDrag();
  },
  // 这里暂时用不到这里，而是通过watch属性visible去调用销毁方法
  destroyed() {
    this.destroySelf();
  },
  methods: {
    // 更新图片的默认尺寸
    updateImgSize() {
      this.imgNaturalWidth = this.$refs.previewImg.naturalWidth;
      this.imgNaturalHeight = this.$refs.previewImg.naturalHeight;
    },
    // 缓存传入的剪裁区域尺寸
    saveCropperSize() {
      this.cropperWidth = this.size.width;
      this.cropperHeight = this.size.height;
    },
    // 启用缩放滚轮
    enableScale() {
      on(
        // document.querySelector('#operate-pannel'),
        this.$refs['operate-pannel'],
        'mousewheel',
        this.scaleHandler
      );
      on(
        // document.querySelector('#operate-pannel'),
        this.$refs['operate-pannel'],
        'DOMMouseScroll',
        this.scaleHandler
      );
    },
    // 缩放的处理方法
    scaleHandler(e) {
      e.preventDefault();
      // 滚轮事件中，chrome、ie、Firefox下判断方向的属性
      const delta = e.deltaY || -e.wheelDelta || e.detail;
      if (delta > 0) {
        // 缩小
        this.zoom(-1);
      }
      if (delta < 0) {
        // 放大
        this.zoom(1);
      }
    },
    // 缩放的处理方法
    zoom(number) {
      if (number > 0) {
        // 放大，达到极限放大倍数时停止
        if (this.imgScale >= MAX_SCALE) {
          return;
        }
        this.imgScale += 0.2;
      } else if (number < 0) {
        // 缩小
        if (this.imgScale <= MIN_SCALE) {
          return;
        }
        this.imgScale -= 0.2;
      }
      // 修正偏移量
      this.correctTranslate();
    },
    // 删除滚轮缩放的处理事件
    removeScale() {
      if (!document.querySelector('#operate-pannel')) return;
      off(
        document.querySelector('#operate-pannel'),
        'mousewheel',
        this.scaleHandler
      );
      off(
        document.querySelector('#operate-pannel'),
        'DOMMouseScroll',
        this.scaleHandler
      );
    },
    // 启用拖拽
    enableDrag() {
      // 监听鼠标按下事件
      on(
        document.querySelector('#operate-pannel'),
        'mousedown',
        this.mousedownHandler
      );
      // 监听鼠标离开预览区域跟鼠标抬起时的处理方法一样
      on(
        document.querySelector('#operate-pannel'),
        'mouseleave',
        this.mouseupHandler
      );
    },
    // 鼠标按下时，监听mousemove事件和mouseup事件
    mousedownHandler(e) {
      // 记录拖拽前，鼠标的位置
      this.dragTempData.srcX = e.clientX;
      this.dragTempData.srcY = e.clientY;
      // 记录拖拽前，图片的偏移位置
      this.dragTempData.srcTranslateX = this.dragTempData.nowTranslateX;
      this.dragTempData.srcTranslateY = this.dragTempData.nowTranslateY;
      // 记录拖拽前，图片容器的rect信息
      const rect = e.target.getBoundingClientRect();
      this.dragTempData.rectTop = rect.top;
      this.dragTempData.rectRight = rect.right;
      this.dragTempData.rectBottom = rect.bottom;
      this.dragTempData.rectLeft = rect.left;
      // 鼠标按下时监听鼠标移动事件
      on(
        document.querySelector('#operate-pannel'),
        'mousemove',
        this.mousemoveHandler
      );
      // 鼠标按下时监听鼠标抬起事件
      on(
        document.querySelector('#operate-pannel'),
        'mouseup',
        this.mouseupHandler
      );
    },
    // 鼠标抬起的处理方法
    mouseupHandler() {
      // 鼠标抬起时移除监听鼠标移动的方法
      off(
        document.querySelector('#operate-pannel'),
        'mousemove',
        this.mousemoveHandler
      );
      // 鼠标抬起时移除监听鼠标抬起的方法
      off(
        document.querySelector('#operate-pannel'),
        'mouseup',
        this.mouseupHandler
      );
    },
    // 鼠标移动事件处理方法
    mousemoveHandler(e) {
      // 禁止浏览器默认对图片的拖拽处理
      e.preventDefault();
      // 计算此次移动的偏移量
      const diffX = e.clientX - this.dragTempData.srcX;
      const diffY = e.clientY - this.dragTempData.srcY;
      // 在图片的原偏移量数据上追加此次鼠标移动的偏移量
      this.dragTempData.nowTranslateX = this.dragTempData.srcTranslateX + diffX;
      this.dragTempData.nowTranslateY = this.dragTempData.srcTranslateY + diffY;
      // 修正偏移量
      this.correctTranslate();
    },
    // 修正偏移量
    correctTranslate() {
      // 判断偏移量是否超出了限制（图片不允许偏移出剪裁区域）
      if (this.dragTempData.nowTranslateX > this.limitTranslate.X[1]) {
        this.dragTempData.nowTranslateX = this.limitTranslate.X[1];
      } else if (this.dragTempData.nowTranslateX < this.limitTranslate.X[0]) {
        this.dragTempData.nowTranslateX = this.limitTranslate.X[0];
      }
      if (this.dragTempData.nowTranslateY > this.limitTranslate.Y[1]) {
        this.dragTempData.nowTranslateY = this.limitTranslate.Y[1];
      } else if (this.dragTempData.nowTranslateY < this.limitTranslate.Y[0]) {
        this.dragTempData.nowTranslateY = this.limitTranslate.Y[0];
      }
    },
    // 删除拖拽处理事件
    removeDrag() {
      if (!document.querySelector('#operate-pannel')) return;
      // 清除监听鼠标按下事件
      on(
        document.querySelector('#operate-pannel'),
        'mousedown',
        this.mousedownHandler
      );
      // 清除监听鼠标离开预览区事件
      on(
        document.querySelector('#operate-pannel'),
        'mouseleave',
        this.mouseupHandler
      );
    },
    // 销毁自身，先清除事件，再移除dom
    destroySelf() {
      // 清除绑定的缩放处理事件
      this.removeScale();
      // 清除绑定的拖拽处理事件
      this.removeDrag();
      // 销毁前，清除追加到dom中的节点
      this.$el.parentNode && this.$el.parentNode.removeChild(this.$el);
    },
    // 向外发送点击关闭按钮的事件
    closeSelf() {
      this.$emit('update:visible', false);
    },
    // 点击保存时的处理方法
    saveHandler() {
      // 抛出成功事件，并传递截取后的参数和预览图
      const cropInfo = {
        naturalImgWidth: this.imgNaturalWidth,
        naturalImgHeight: this.imgNaturalHeight,
        imgWidth: parseInt(this.imgStyle.width),
        imgHeight: parseInt(this.imgStyle.height),
        scale: parseFloat(
          parseInt(this.imgStyle.width) / parseInt(this.imgNaturalWidth)
        ),
        transform: this.imgStyle.transform,
        x:
          (parseInt(this.imgStyle.width) - this.size.width) / 2 -
          this.dragTempData.nowTranslateX,
        y:
          (parseInt(this.imgStyle.height) - this.size.width) / 2 -
          this.dragTempData.nowTranslateY,
        cropWidth: this.size.width,
        cropHeight: this.size.height
      };
      const canvas = this.$refs.canvas;
      this.context = canvas.getContext('2d');
      // 初始化背景图片
      // this.img.crossOrigin = ''

      this.context.drawImage(
        this.$refs.previewImg,
        cropInfo.x / cropInfo.scale,
        cropInfo.y / cropInfo.scale,
        this.size.width / cropInfo.scale,
        this.size.height / cropInfo.scale,
        0,
        0,
        this.size.width,
        this.size.height
      );
      cropInfo.base64 = this.$refs.canvas.toDataURL('image/jpg');
      this.$emit('crop-complete', cropInfo);
      // 关闭蒙版
      this.closeSelf();
    },
    // 点击取消时的处理方法
    cancelHandler() {
      // 关闭蒙版
      this.closeSelf();
    }
  }
};
</script>
