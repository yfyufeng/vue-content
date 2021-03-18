import Vue from 'vue'
import Router from 'vue-router'
import store from '@/store'

import routes from '../router.config.js'

Vue.use(Router)
const originalPush = Router.prototype.push
Router.prototype.push = function push (location) {
  return originalPush.call(this, location).catch(err => err)
}
const createRoute = (routes) => {
  return routes.reduce((processedRoutes, currentRoute) => {
    processedRoutes.push(processRouteObj(currentRoute))
    return processedRoutes
  }, [])
}

const processRouteObj = ({ menuCode, breadcrumb, children, component, keepAlive, ...args }) => {
  return Object.assign({
    meta: { menuCode, keepAlive },
    props: {
      breadcrumbObj: {
        content: breadcrumb,
        menuCode: menuCode
      }
    },
    component: () => import(/* webpackInclude: /\.(js|vue)$/ */`@/pages/${component}`),
    children: children ? createRoute(children) : []
  }, args)
}

const router = new Router({
  mode: 'history',
  base: process.env.BASE_URL,
  routes: createRoute(routes)
})

router.beforeEach(async (to, form, next) => {
  const { userInfo: { code } } = store.state
  // 防止死循环跳出
  if (to.path.indexOf('error') > -1) {
    next()
    return
  }

  if (code.includes(`${process.env.VUE_APP_CONTEXT}_${to.meta.menuCode}`) || to.meta.menuCode === '000') {
    next()
  } else if (to.meta.menuCode) {
    // 真实菜单，但无权限
    next({ path: '/error/403' })
  } else {
    // 不属于系统的url，跳转到404页面
    next({ path: '/error/404' })
  }
})

export default router
