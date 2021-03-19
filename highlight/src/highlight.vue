<script>
export default {
  name: 'HHighlight',
  functional: true,
  props: {
    highlightKey: {
      type: [String, Number],
      default: ''
    },
    color: {
      type: String,
      default: ''
    },
    // 默认不区分大小写
    notCaseInsensitive: {
      type: Boolean,
      default: false
    }
  },
  render(h, ctx) {
    const { highlightKey, color, notCaseInsensitive } = ctx.props;
    const { text } = ctx.children[0];
    const matchOperatorsRe = /[|\\{}()[\]^$+*?.]/g;
    const key = (highlightKey + '').replace(matchOperatorsRe, '\\$&');
    const reg = new RegExp(key, 'ig');
    const strArr = key
      ? text
          .split(notCaseInsensitive ? key : reg)
          .join('*-*-*|*-*-*')
          .split('*-*-*')
      : [text];

    const keys = text.match(reg);
    return (
      <span>
        {strArr.map(item => {
          if (item === '|') {
            return (
              <span class='h-highlight' style={{ color }}>
                {notCaseInsensitive ? key : keys.shift()}
              </span>
            );
          } else {
            return item;
          }
        })}
      </span>
    );
  }
};
</script>
