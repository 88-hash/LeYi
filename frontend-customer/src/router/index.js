import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    component: () => import('@/views/layout/Index.vue'),
    redirect: '/login',
    children: [
      {
        path: 'home',
        name: 'Home',
        component: () => import('@/views/home/Index.vue'),
        meta: { title: '首页' }
      },
      {
        path: 'category',
        name: 'Category',
        component: () => import('@/views/category/Index.vue'),
        meta: { title: '分类' }
      },
      {
        path: 'cart',
        name: 'Cart',
        component: () => import('@/views/cart/Index.vue'),
        meta: { title: '购物车', requireAuth: true }
      },
      {
        path: 'mine',
        name: 'Mine',
        component: () => import('@/views/mine/Index.vue'),
        meta: { title: '个人中心', requireAuth: true }
      },
      {
        path: 'profile',
        name: 'Profile',
        component: () => import('@/views/profile/Index.vue'),
        meta: { title: '个人资料', requireAuth: true }
      },
      {
        path: 'goods/:id',
        name: 'GoodsDetail',
        component: () => import('@/views/goods/Detail.vue'),
        meta: { title: '商品详情' }
      },
      {
        path: 'search',
        name: 'Search',
        component: () => import('@/views/search/Index.vue'),
        meta: { title: '搜索' }
      },
      {
        path: 'checkout',
        name: 'Checkout',
        redirect: '/payment',
        meta: { requireAuth: true }
      },
      {
        path: 'payment',
        name: 'Payment',
        component: () => import('@/views/payment/Index.vue'),
        meta: { title: '模拟付款', requireAuth: true }
      },
      {
        path: 'order/success',
        name: 'OrderSuccess',
        component: () => import('@/views/order/Success.vue'),
        meta: { title: '下单成功', requireAuth: true }
      },
      {
        path: 'orders',
        name: 'Orders',
        component: () => import('@/views/order/List.vue'),
        meta: { title: '我的订单', requireAuth: true }
      },
      {
        path: 'order/:id',
        name: 'OrderDetail',
        component: () => import('@/views/order/Detail.vue'),
        meta: { title: '订单详情', requireAuth: true }
      },
      {
        path: 'comments',
        name: 'MyComments',
        component: () => import('@/views/comment/List.vue'),
        meta: { title: '我的评价', requireAuth: true }
      },
      {
        path: 'comment/:orderItemId',
        name: 'Comment',
        component: () => import('@/views/comment/Add.vue'),
        meta: { title: '发表评价', requireAuth: true }
      }
    ]
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/Index.vue'),
    meta: { title: '登录' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  document.title = to.meta.title ? `${to.meta.title} - LeYi零食店` : 'LeYi零食店'

  const token = localStorage.getItem('token')
  if (to.meta.requireAuth && !token) {
    next({ name: 'Login', query: { redirect: to.fullPath } })
  } else {
    next()
  }
})

export default router
