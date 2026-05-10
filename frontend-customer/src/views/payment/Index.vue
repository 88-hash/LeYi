<template>
  <div class="payment-page">
    <div class="page-container">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item :to="{ path: '/home' }">首页</el-breadcrumb-item>
        <el-breadcrumb-item :to="{ path: '/cart' }">购物车</el-breadcrumb-item>
        <el-breadcrumb-item>模拟付款</el-breadcrumb-item>
      </el-breadcrumb>

      <div v-if="pageReady && cartStore.checkedItems.length > 0" class="payment-shell">
        <section class="payment-main">
          <article class="payment-hero leyi-panel-strong">
            <div class="hero-copy">
             
              <h1>确认本次支付信息</h1>
              <p class="hero-tip">选择微信支付或支付宝支付后确认付款，系统会立即生成订单和取货码。</p>
            </div>
            <div class="hero-amount">
              <span>待支付金额</span>
              <strong>￥{{ cartStore.checkedTotal.toFixed(2) }}</strong>
              <p>共 {{ checkedQuantity }} 件商品，门店现做现备</p>
            </div>
          </article>

          <article class="payment-card leyi-panel-strong">
            <header>
              <el-icon><Wallet /></el-icon>
              支付方式
            </header>
            <div class="payment-methods">
              <button
                v-for="method in paymentMethods"
                :key="method.value"
                type="button"
                class="method-card"
                :class="{ selected: paymentMethod === method.value }"
                @click="paymentMethod = method.value"
              >
                <span class="method-badge" :class="method.value">{{ method.badge }}</span>
                <div class="method-copy">
                  <strong>{{ method.label }}</strong>
                  <p>{{ method.description }}</p>
                </div>
                <span class="method-state">{{ paymentMethod === method.value ? '已选择' : '选择' }}</span>
              </button>
            </div>
          </article>

          <div class="info-grid">
            <article class="payment-card leyi-panel-strong">
              <header>
                <el-icon><Location /></el-icon>
                取货信息
              </header>
              <div class="pickup-info">
                <p><span>顾客姓名</span><strong>{{ displayName }}</strong></p>
                <p><span>联系电话</span><strong>{{ displayPhone }}</strong></p>
                <p><span>取货方式</span><strong>到店自提</strong></p>
                <p><span>取货门店</span><strong>LeYi零食店 - 鞍山市立山区千山中路185号</strong></p>
                <p><span>营业时间</span><strong>09:00 - 22:00</strong></p>
              </div>
            </article>

            <article class="payment-card leyi-panel-strong">
              <header>
                <el-icon><EditPen /></el-icon>
                订单备注
              </header>
              <div class="remark-box">
                <el-input
                  v-model="remark"
                  type="textarea"
                  :rows="4"
                  placeholder="选填，可以告诉店家你的口味偏好、包装需求或到店时间"
                  maxlength="100"
                  show-word-limit
                />
              </div>
            </article>
          </div>

          <article class="payment-card leyi-panel-strong">
            <header>
              <el-icon><Goods /></el-icon>
              商品清单 ({{ cartStore.checkedItems.length }})
            </header>
            <div class="goods-list">
              <article v-for="item in cartStore.checkedItems" :key="item.id" class="goods-row">
                <div class="goods-info">
                  <img :src="getImageUrl(item.goodsImage)" :alt="item.goodsName" @error="handleImageError" />
                  <div>
                    <h3>{{ item.goodsName }}</h3>
                    <p>数量 x {{ item.quantity }}</p>
                  </div>
                </div>
                <div class="goods-price-group">
                  <span>单价 ￥{{ item.goodsPrice?.toFixed(2) }}</span>
                  <strong>小计 ￥{{ (item.goodsPrice * item.quantity).toFixed(2) }}</strong>
                </div>
              </article>
            </div>
          </article>
        </section>

        <aside class="payment-side leyi-panel-strong">
          <h3>付款摘要</h3>
          <div class="summary-row">
            <span>商品金额</span>
            <strong>￥{{ cartStore.checkedTotal.toFixed(2) }}</strong>
          </div>
          <div class="summary-row">
            <span>支付方式</span>
            <strong>{{ selectedMethodLabel }}</strong>
          </div>
          <div class="summary-row">
            <span>取货方式</span>
            <strong>到店自提</strong>
          </div>
          <div class="summary-row">
            <span>订单件数</span>
            <strong>{{ checkedQuantity }} 件</strong>
          </div>

          <div class="summary-total">
            <span>应付金额</span>
            <strong>￥{{ cartStore.checkedTotal.toFixed(2) }}</strong>
          </div>

          <div class="summary-note">
            <p>确认支付后将直接模拟付款成功，并跳转到下单成功页面展示取货码。</p>
          </div>

          <el-button class="pay-btn" type="primary" :loading="loading" @click="handlePay">
            确认支付
          </el-button>
          <button type="button" class="back-btn" @click="goBack">返回购物车</button>
        </aside>
      </div>

      <div v-else-if="pageReady" class="empty-panel leyi-panel-strong">
        <el-empty description="当前没有可支付商品">
          <el-button type="primary" @click="router.push('/cart')">返回购物车</el-button>
        </el-empty>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { createOrder } from '@/api/order'
import { useCartStore } from '@/stores/cart'
import { useUserStore } from '@/stores/user'
import { getImageUrl, handleImageError } from '@/utils/image'

const router = useRouter()
const cartStore = useCartStore()
const userStore = useUserStore()

const loading = ref(false)
const pageReady = ref(false)
const remark = ref('')
const paymentMethod = ref('wechat')

const paymentMethods = [
  {
    value: 'wechat',
    badge: '微',
    label: '微信支付',
    description: '推荐使用微信完成本次模拟付款'
  },
  {
    value: 'alipay',
    badge: '支',
    label: '支付宝支付',
    description: '使用支付宝完成本次模拟付款'
  }
]

const checkedQuantity = computed(() => {
  return cartStore.checkedItems.reduce((sum, item) => sum + item.quantity, 0)
})

const selectedMethodLabel = computed(() => {
  const matched = paymentMethods.find((item) => item.value === paymentMethod.value)
  return matched?.label || '微信支付'
})

const displayName = computed(() => userStore.userInfo.name || 'LeYi会员')
const displayPhone = computed(() => userStore.userInfo.phone || '未绑定')

watch(remark, (value) => {
  if (value) {
    sessionStorage.setItem('checkout.remark', value)
  } else {
    sessionStorage.removeItem('checkout.remark')
  }
})

onMounted(async () => {
  remark.value = sessionStorage.getItem('checkout.remark') || ''

  try {
    await cartStore.fetchCart()
  } catch (error) {
    console.error(error)
  } finally {
    if (cartStore.checkedItems.length === 0) {
      sessionStorage.removeItem('checkout.remark')
      remark.value = ''
    }
    pageReady.value = true
  }
})

const handlePay = async () => {
  if (cartStore.checkedItems.length === 0) {
    ElMessage.warning('当前没有可支付商品')
    router.replace('/cart')
    return
  }

  loading.value = true
  try {
    const res = await createOrder(remark.value.trim())
    sessionStorage.removeItem('checkout.remark')
    await cartStore.fetchCart()
    router.replace({
      path: '/order/success',
      query: {
        orderNo: res.data.orderNo,
        verifyCode: res.data.verifyCode
      }
    })
  } catch (error) {
    console.error(error)
  } finally {
    loading.value = false
  }
}

const goBack = () => {
  router.push('/cart')
}
</script>

<style lang="scss" scoped>
.payment-shell {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 22rem;
  gap: var(--space-6);
  align-items: start;
}

.payment-main {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.payment-hero {
  padding: var(--space-7);
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--space-5);
  background:
    radial-gradient(circle at top right, rgba(238, 205, 43, 0.22), transparent 34%),
    linear-gradient(135deg, #fffef7, #fff);
}

.hero-tag {
  margin: 0;
  display: inline-flex;
  height: 1.7rem;
  align-items: center;
  padding: 0 0.7rem;
  border-radius: var(--radius-pill);
  background: rgba(238, 205, 43, 0.2);
  color: #6f5b00;
  font-size: 0.76rem;
  font-weight: 700;
}

.hero-copy h1 {
  margin: var(--space-4) 0 var(--space-2);
  font-size: clamp(1.8rem, 2.3vw, 2.3rem);
  font-weight: 800;
  letter-spacing: -0.02em;
}

.hero-tip {
  margin: 0;
  max-width: 32rem;
  color: var(--color-muted);
  line-height: 1.7;
}

.hero-amount {
  min-width: 13rem;
  padding: var(--space-5);
  border-radius: var(--radius-xl);
  background: rgba(24, 24, 24, 0.96);
  color: #fff;
  box-shadow: 0 16px 32px rgba(24, 24, 24, 0.16);
}

.hero-amount span {
  display: block;
  font-size: 0.82rem;
  color: rgba(255, 255, 255, 0.72);
}

.hero-amount strong {
  display: block;
  margin-top: var(--space-2);
  font-size: 2rem;
  font-weight: 800;
  letter-spacing: -0.03em;
}

.hero-amount p {
  margin: var(--space-3) 0 0;
  color: rgba(255, 255, 255, 0.72);
  font-size: 0.8rem;
}

.payment-card {
  overflow: hidden;
}

.payment-card > header {
  height: 3.1rem;
  padding: 0 var(--space-6);
  display: flex;
  align-items: center;
  gap: 0.45rem;
  border-bottom: 1px solid rgba(24, 24, 24, 0.1);
  font-size: 0.95rem;
  font-weight: 700;
  background: #fbfbf8;
}

.payment-methods {
  padding: var(--space-6);
  display: grid;
  gap: var(--space-4);
}

.method-card {
  width: 100%;
  padding: var(--space-5);
  border-radius: var(--radius-lg);
  border: 1px solid rgba(24, 24, 24, 0.12);
  background: #fff;
  display: flex;
  align-items: center;
  gap: var(--space-4);
  text-align: left;
  cursor: pointer;
  transition: border-color 0.2s ease, transform 0.2s ease, box-shadow 0.2s ease;
}

.method-card:hover {
  border-color: rgba(238, 205, 43, 0.7);
  transform: translateY(-1px);
}

.method-card.selected {
  border-color: rgba(238, 205, 43, 0.9);
  background: linear-gradient(135deg, rgba(238, 205, 43, 0.16), rgba(238, 205, 43, 0.06));
  box-shadow: 0 14px 28px rgba(238, 205, 43, 0.14);
}

.method-badge {
  width: 2.9rem;
  height: 2.9rem;
  border-radius: 0.95rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 1rem;
  font-weight: 800;
  flex-shrink: 0;
}

.method-badge.wechat {
  background: linear-gradient(135deg, #21c168, #169c52);
}

.method-badge.alipay {
  background: linear-gradient(135deg, #3d9eff, #1477f2);
}

.method-copy {
  flex: 1;
  min-width: 0;
}

.method-copy strong {
  display: block;
  font-size: 0.98rem;
}

.method-copy p {
  margin: 0.35rem 0 0;
  color: var(--color-muted);
  font-size: 0.82rem;
}

.method-state {
  font-size: 0.82rem;
  font-weight: 700;
  color: #6f5b00;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--space-5);
}

.pickup-info,
.remark-box,
.goods-list {
  padding: var(--space-6);
}

.pickup-info p {
  margin: 0 0 var(--space-3);
  display: grid;
  grid-template-columns: 5.3rem minmax(0, 1fr);
  gap: var(--space-3);
  align-items: flex-start;
}

.pickup-info p:last-child {
  margin-bottom: 0;
}

.pickup-info span {
  color: var(--color-muted);
  font-size: 0.82rem;
}

.pickup-info strong {
  font-size: 0.9rem;
  line-height: 1.55;
}

.goods-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.goods-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  padding: var(--space-4);
  border-radius: var(--radius-lg);
  border: 1px solid rgba(24, 24, 24, 0.08);
  background: #fff;
}

.goods-info {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  min-width: 0;
}

.goods-info img {
  width: 4.6rem;
  height: 4.6rem;
  border-radius: var(--radius-md);
  object-fit: cover;
  flex-shrink: 0;
}

.goods-info h3 {
  margin: 0;
  font-size: 0.92rem;
  font-weight: 700;
  line-height: 1.5;
}

.goods-info p {
  margin: 0.35rem 0 0;
  color: var(--color-muted);
  font-size: 0.8rem;
}

.goods-price-group {
  text-align: right;
  flex-shrink: 0;
}

.goods-price-group span {
  display: block;
  color: var(--color-muted);
  font-size: 0.8rem;
}

.goods-price-group strong {
  display: block;
  margin-top: 0.35rem;
  font-size: 0.98rem;
  font-weight: 800;
}

.payment-side {
  position: sticky;
  top: 8.7rem;
  padding: var(--space-6);
}

.payment-side h3 {
  margin: 0 0 var(--space-5);
  font-size: 1.05rem;
  font-weight: 700;
}

.summary-row {
  height: 2.2rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 0.85rem;
}

.summary-row span {
  color: var(--color-muted);
}

.summary-total {
  margin-top: var(--space-4);
  padding-top: var(--space-4);
  border-top: 1px solid rgba(24, 24, 24, 0.1);
  display: flex;
  align-items: baseline;
  justify-content: space-between;
}

.summary-total strong {
  font-size: 1.4rem;
  font-weight: 800;
  letter-spacing: -0.03em;
}

.summary-note {
  margin-top: var(--space-4);
  padding: var(--space-4);
  border-radius: var(--radius-lg);
  background: #fbfbf8;
  border: 1px solid rgba(24, 24, 24, 0.08);
}

.summary-note p {
  margin: 0;
  color: var(--color-muted);
  font-size: 0.8rem;
  line-height: 1.65;
}

.pay-btn {
  width: 100%;
  margin-top: var(--space-5);
  height: 2.8rem;
}

.back-btn {
  width: 100%;
  height: 2.6rem;
  margin-top: var(--space-3);
  border: 1px solid rgba(24, 24, 24, 0.12);
  background: #fff;
  border-radius: var(--radius-md);
  font-weight: 600;
  cursor: pointer;
}

.empty-panel {
  padding: var(--space-16);
}

@media (max-width: 960px) {
  .payment-shell,
  .info-grid {
    grid-template-columns: 1fr;
  }

  .payment-hero {
    flex-direction: column;
  }

  .hero-amount {
    width: 100%;
    min-width: 0;
  }

  .payment-side {
    position: static;
  }

  .goods-row {
    flex-direction: column;
    align-items: flex-start;
  }

  .goods-price-group {
    width: 100%;
    text-align: left;
  }
}
</style>
