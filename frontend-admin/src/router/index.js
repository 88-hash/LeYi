import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/Index.vue'),
    meta: { title: '登录' }
  },
  {
    path: '/',
    component: () => import('@/views/layout/Index.vue'),
    redirect: '//login',
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/dashboard/Index.vue'),
        meta: { title: '数据概览', icon: 'DataLine' }
      },
      {
        path: 'verify',
        name: 'Verify',
        component: () => import('@/views/verify/Index.vue'),
        meta: { title: '订单核销', icon: 'Finished' }
      },
      {
        path: 'orders',
        name: 'Orders',
        component: () => import('@/views/order/Index.vue'),
        meta: { title: '订单管理', icon: 'List' }
      },
      {
        path: 'goods',
        name: 'Goods',
        component: () => import('@/views/goods/Index.vue'),
        meta: { title: '商品管理', icon: 'Goods', roles: ['manager'] }
      },
      {
        path: 'goods/add',
        name: 'GoodsAdd',
        component: () => import('@/views/goods/Edit.vue'),
        meta: { title: '新增商品', roles: ['manager'] }
      },
      {
        path: 'goods/edit/:id',
        name: 'GoodsEdit',
        component: () => import('@/views/goods/Edit.vue'),
        meta: { title: '编辑商品', roles: ['manager'] }
      },
      {
        path: 'category',
        name: 'Category',
        component: () => import('@/views/category/Index.vue'),
        meta: { title: '分类管理', icon: 'Menu', roles: ['manager'] }
      },
      {
        path: 'staff',
        name: 'Staff',
        component: () => import('@/views/staff/Index.vue'),
        meta: { title: '店员管理', icon: 'User', roles: ['manager'] }
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

const readStoredAdminInfo = () => {
  try {
    return JSON.parse(localStorage.getItem('adminInfo') || '{}')
  } catch {
    localStorage.removeItem('adminInfo')
    localStorage.removeItem('adminToken')
    return {}
  }
}

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('adminToken')
  const adminInfo = readStoredAdminInfo()
  
  if (to.path === '/login') {
    next()
  } else if (!token) {
    next('/login')
  } else if (to.meta.roles && !to.meta.roles.includes(adminInfo.role)) {
    next('/dashboard')
  } else {
    next()
  }
})

export default router



