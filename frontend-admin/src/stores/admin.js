import { defineStore } from 'pinia'
import { ref } from 'vue'
import { adminLogin } from '@/api'

const readStoredAdminInfo = () => {
  try {
    return JSON.parse(localStorage.getItem('adminInfo') || '{}')
  } catch {
    localStorage.removeItem('adminInfo')
    localStorage.removeItem('adminToken')
    return {}
  }
}

export const useAdminStore = defineStore('admin', () => {
  const token = ref(localStorage.getItem('adminToken') || '')
  const adminInfo = ref(readStoredAdminInfo())

  const login = async (phone, password) => {
    const res = await adminLogin({ phone, password })
    token.value = res.data.token
    adminInfo.value = res.data.admin
    localStorage.setItem('adminToken', res.data.token)
    localStorage.setItem('adminInfo', JSON.stringify(res.data.admin))
    return res.data
  }

  const logout = () => {
    token.value = ''
    adminInfo.value = {}
    localStorage.removeItem('adminToken')
    localStorage.removeItem('adminInfo')
  }

  const isManager = () => adminInfo.value.role === 'manager'

  return {
    token,
    adminInfo,
    login,
    logout,
    isManager
  }
})



