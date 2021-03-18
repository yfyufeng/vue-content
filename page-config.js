export default {
  data () {
    return {
      pageData: [],
      pageTotal: 0,
      pageParams: {
        pageSize: 20,
        pageNo: 1
      },
      pageSizes: [10, 20, 50, 100]
    }
  },
  methods: {
    changePageSize (pageSize) {
      this.pageParams.pageSize = pageSize
      // true 从第一页开始
      this.searchClick()
    },
    changeCurrentPage (pageNo) {
      this.pageParams.pageNo = pageNo
      this.getPageData()
    },
    searchClick () {
      this.pageParams.pageNo === 1 ? this.getPageData() : this.pageParams.pageNo = 1
    },
    searchClear () {
      this.$refs.search.resetFields()
      this.getPageData()
    }
  }
}
