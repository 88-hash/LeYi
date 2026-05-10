<template>
  <div class="search-page">
    <div class="page-container">
      <el-breadcrumb separator="/" class="breadcrumb">
        <el-breadcrumb-item :to="{ path: '/home' }">首页</el-breadcrumb-item>
        <el-breadcrumb-item>{{ isFrequentMode ? '常买清单' : '搜索结果' }}</el-breadcrumb-item>
      </el-breadcrumb>

      <section v-if="isFrequentMode" class="frequent-shell leyi-panel">
        <header class="frequent-head">
          <div>
            <h2>常买清单</h2>
            <p>基于你的历史消费行为，自动汇总高频回购商品</p>
          </div>
          <div class="mode-tabs">
            <button
              v-for="tab in frequentTabs"
              :key="tab.value"
              type="button"
              class="mode-tab"
              :class="{ active: frequentTab === tab.value }"
              @click="frequentTab = tab.value"
            >
              {{ tab.label }}
            </button>
          </div>
        </header>

        <p class="source-line">数据来源：{{ frequentSource }}</p>

        <div v-if="displayFrequentList.length > 0" class="frequent-grid">
          <article
            v-for="item in displayFrequentList"
            :key="item.key"
            class="frequent-card"
            @click="goFrequentDetail(item)"
          >
            <div class="frequent-image">
              <img :src="getImageUrl(item.imageUrl)" :alt="item.name" @error="handleImageError">
              <span class="count-badge">回购 {{ item.count }} 次</span>
            </div>
            <div class="frequent-info">
              <h3>{{ item.name }}</h3>
              <p>最近购买：{{ formatDate(item.lastBuyAt) }}</p>
              <div class="frequent-foot">
                <span class="price-number">{{ Number(item.price || 0).toFixed(2) }}</span>
                <el-button type="primary" circle @click.stop="addFrequentToCart(item)">
                  <el-icon><ShoppingCart /></el-icon>
                </el-button>
              </div>
            </div>
          </article>
        </div>

        <div v-else class="empty-wrap leyi-panel">
          <el-empty description="暂无常买商品">
            <template #default>
              <p class="empty-tip">先下几单，系统会自动帮你生成常买清单。</p>
            </template>
          </el-empty>
        </div>
      </section>

      <section v-else class="result-shell leyi-panel">
        <header class="result-head">
          <div>
            <h2>“{{ keyword || '全部' }}” 的搜索结果</h2>
            <p>共找到 {{ total }} 件商品</p>
          </div>
          <div class="sort-tabs">
            <button
              v-for="option in sortOptions"
              :key="option.value"
              type="button"
              class="sort-tab"
              :class="{ active: sortBy === option.value }"
              @click="sortBy = option.value"
            >
              {{ option.label }}
            </button>
          </div>
        </header>

        <div v-if="displayGoodsList.length > 0" class="goods-grid">
          <article
            v-for="goods in displayGoodsList"
            :key="goods.id"
            class="goods-card"
            @click="goDetail(goods.id)"
          >
            <div class="goods-image">
              <img :src="getImageUrl(goods.imageUrl)" :alt="goods.name" @error="handleImageError">
              <span v-if="goods.promotionTag" class="promo-tag">{{ goods.promotionTag }}</span>
            </div>
            <div class="goods-info">
              <p class="goods-name">{{ goods.name }}</p>
              <div class="goods-bottom">
                <span class="price-number">{{ Number(goods.price || 0).toFixed(2) }}</span>
                <el-button type="primary" circle @click.stop="addCart(goods)">
                  <el-icon><ShoppingCart /></el-icon>
                </el-button>
              </div>
            </div>
          </article>
        </div>

        <div v-else class="empty-wrap leyi-panel">
          <el-empty description="未找到相关商品">
            <template #default>
              <p class="empty-tip">你可以试试这些关键词：{{ suggestKeywords.join('、') }}</p>
            </template>
          </el-empty>
        </div>

        <div class="pager-wrap" v-if="total > pageSize">
          <el-pagination
            v-model:current-page="pageNum"
            :page-size="pageSize"
            :total="total"
            layout="prev, pager, next"
            @current-change="fetchSearchGoods"
          />
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import dayjs from 'dayjs'
import { getGoodsList } from '@/api/goods'
import { getOrderList } from '@/api/order'
import { useCartStore } from '@/stores/cart'
import { useUserStore } from '@/stores/user'
import { getImageUrl, handleImageError } from '@/utils/image'

const route = useRoute()
const router = useRouter()
const cartStore = useCartStore()
const userStore = useUserStore()

const keyword = ref('')
const goodsList = ref([])
const frequentList = ref([])
const pageNum = ref(1)
const pageSize = ref(20)
const total = ref(0)
const sortBy = ref('default')
const frequentTab = ref('all')
const frequentSource = ref('订单记录')

const suggestKeywords = ['巧克力', '坚果礼盒', '果干', '薯片', '饮料']

const sortOptions = [
  { label: '综合推荐', value: 'default' },
  { label: '销量优先', value: 'sales_desc' },
  { label: '价格从低到高', value: 'price_asc' },
  { label: '价格从高到低', value: 'price_desc' }
]

const frequentTabs = [
  { label: '全部商品', value: 'all' },
  { label: '最近购买', value: 'recent' },
  { label: '高频回购', value: 'high' }
]

const normalizedKeyword = computed(() => `${keyword.value || ''}`.replace(/\s+/g, ''))
const isFrequentMode = computed(() => normalizedKeyword.value === '常买')

const displayGoodsList = computed(() => goodsList.value)

const displayFrequentList = computed(() => {
  const source = [...frequentList.value]
  if (frequentTab.value === 'recent') {
    return source.sort((a, b) => new Date(b.lastBuyAt || 0) - new Date(a.lastBuyAt || 0))
  }
  if (frequentTab.value === 'high') {
    return source
      .filter((item) => Number(item.count || 0) >= 2)
      .sort((a, b) => Number(b.count || 0) - Number(a.count || 0))
  }
  return source.sort((a, b) => {
    const countDiff = Number(b.count || 0) - Number(a.count || 0)
    if (countDiff !== 0) return countDiff
    return new Date(b.lastBuyAt || 0) - new Date(a.lastBuyAt || 0)
  })
})

const syncKeyword = () => {
  keyword.value = `${route.query.keyword || ''}`.trim()
}

const fetchSearchGoods = async () => {
  if (!keyword.value) {
    goodsList.value = []
    total.value = 0
    return
  }

  try {
    const res = await getGoodsList({
      keyword: keyword.value,
      pageNum: pageNum.value,
      pageSize: pageSize.value,
      isOnSale: 1,
      sort: sortBy.value
    })
    goodsList.value = res.data?.list || []
    total.value = Number(res.data?.total || 0)
  } catch (error) {
    console.error(error)
  }
}

const buildFrequentFromOrders = (orders) => {
  const map = new Map()
  ;(orders || []).forEach((order) => {
    const buyAt = order.createdAt || order.createTime || ''
    ;(order.items || []).forEach((item) => {
      const key = item.goodsId || item.goodsName
      if (!key) return

      if (!map.has(key)) {
        map.set(key, {
          key,
          goodsId: item.goodsId,
          name: item.goodsName || '未命名商品',
          imageUrl: item.goodsImage || item.imageUrl,
          price: Number(item.price || 0),
          count: 0,
          lastBuyAt: buyAt
        })
      }

      const target = map.get(key)
      target.count += Number(item.quantity || 1)
      if (buyAt && new Date(buyAt) > new Date(target.lastBuyAt || 0)) {
        target.lastBuyAt = buyAt
      }
      if (!target.imageUrl && (item.goodsImage || item.imageUrl)) {
        target.imageUrl = item.goodsImage || item.imageUrl
      }
      if (!target.price && item.price) {
        target.price = Number(item.price)
      }
    })
  })

  return [...map.values()]
}

const buildFrequentFromCart = (cartItems) => {
  const map = new Map()
  ;(cartItems || []).forEach((item) => {
    const key = item.goodsId || item.id || item.goodsName
    if (!key) return

    if (!map.has(key)) {
      map.set(key, {
        key,
        goodsId: item.goodsId,
        name: item.goodsName || '未命名商品',
        imageUrl: item.goodsImage || item.imageUrl,
        price: Number(item.goodsPrice || item.price || 0),
        count: 0,
        lastBuyAt: new Date().toISOString()
      })
    }

    const target = map.get(key)
    target.count += Number(item.quantity || 1)
  })

  return [...map.values()]
}

const fetchFrequentList = async () => {
  frequentList.value = []
  frequentSource.value = '订单记录'

  try {
    const orderRes = await getOrderList('')
    const fromOrders = buildFrequentFromOrders(orderRes.data || [])
    if (fromOrders.length > 0) {
      frequentList.value = fromOrders
      frequentSource.value = '订单明细聚合'
      return
    }
  } catch (error) {
    console.warn('frequent list from orders failed', error)
  }

  try {
    await cartStore.fetchCart()
    const fromCart = buildFrequentFromCart(cartStore.cartList)
    if (fromCart.length > 0) {
      frequentList.value = fromCart
      frequentSource.value = '购物车聚合'
      return
    }
  } catch (error) {
    console.warn('frequent list from cart failed', error)
  }

  frequentSource.value = '暂无可用数据'
}

const fetchByMode = async () => {
  syncKeyword()
  if (isFrequentMode.value) {
    await fetchFrequentList()
    return
  }
  await fetchSearchGoods()
}

const goDetail = (id) => {
  router.push(`/goods/${id}`)
}

const goFrequentDetail = (item) => {
  if (item.goodsId) {
    router.push(`/goods/${item.goodsId}`)
    return
  }
  router.push({ path: '/search', query: { keyword: item.name } })
}

const addCart = async (goods) => {
  if (!userStore.isLoggedIn()) {
    router.push('/login')
    return
  }

  try {
    await cartStore.addToCart(goods.id, 1)
    ElMessage.success('已加入购物车')
  } catch (error) {
    console.error(error)
  }
}

const addFrequentToCart = async (item) => {
  if (!userStore.isLoggedIn()) {
    router.push('/login')
    return
  }

  if (!item.goodsId) {
    ElMessage.warning('该商品暂不支持一键加购')
    return
  }

  try {
    await cartStore.addToCart(item.goodsId, 1)
    ElMessage.success('已加入购物车')
  } catch (error) {
    console.error(error)
  }
}

const formatDate = (value) => {
  if (!value) return '暂无记录'
  return dayjs(value).isValid() ? dayjs(value).format('YYYY-MM-DD') : '暂无记录'
}

watch(
  () => route.query.keyword,
  async () => {
    pageNum.value = 1
    sortBy.value = 'default'
    frequentTab.value = 'all'
    await fetchByMode()
  }
)

watch(sortBy, async () => {
  if (isFrequentMode.value) {
    return
  }
  if (pageNum.value !== 1) {
    pageNum.value = 1
    return
  }
  await fetchSearchGoods()
})

onMounted(fetchByMode)
</script>

<style lang="scss" scoped>
.result-shell,
.frequent-shell {
  padding: var(--space-6);
}

.result-head,
.frequent-head {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--space-5);
  margin-bottom: var(--space-5);
}

.result-head h2,
.frequent-head h2 {
  margin: 0;
  font-size: clamp(1.3rem, 1.6vw, 1.75rem);
  font-weight: 800;
  letter-spacing: -0.01em;
}

.result-head p,
.frequent-head p {
  margin: 0.35rem 0 0;
  color: var(--color-muted);
  font-size: 0.86rem;
}

.sort-tabs,
.mode-tabs {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.sort-tab,
.mode-tab {
  height: 2rem;
  padding: 0 0.8rem;
  border-radius: var(--radius-pill);
  border: 1px solid rgba(24, 24, 24, 0.12);
  background: #fff;
  color: #4a4a4a;
  font-size: 0.76rem;
  font-weight: 700;
  cursor: pointer;
}

.sort-tab.active,
.mode-tab.active {
  background: rgba(238, 205, 43, 0.23);
  border-color: rgba(238, 205, 43, 0.92);
  color: #231d09;
}

.source-line {
  margin: 0 0 var(--space-5);
  color: var(--color-muted);
  font-size: 0.8rem;
}

.frequent-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: clamp(0.95rem, 1.1vw, 1.35rem);
}

.frequent-card {
  border-radius: var(--radius-lg);
  border: 1px solid rgba(24, 24, 24, 0.08);
  background: #fff;
  overflow: hidden;
  box-shadow: var(--shadow-xs);
  cursor: pointer;
  transition: transform 0.16s ease, box-shadow 0.16s ease;
}

.frequent-card:hover {
  transform: translateY(-3px);
  box-shadow: var(--shadow-md);
}

.frequent-image {
  position: relative;
  aspect-ratio: 1 / 1;
  background: #f4f4f4;
}

.frequent-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.count-badge {
  position: absolute;
  top: 0.65rem;
  right: 0.65rem;
  height: 1.4rem;
  padding: 0 0.5rem;
  border-radius: var(--radius-pill);
  background: rgba(34, 31, 16, 0.86);
  color: #fff;
  font-size: 0.66rem;
  font-weight: 700;
  display: inline-flex;
  align-items: center;
}

.frequent-info {
  padding: var(--space-4);
}

.frequent-info h3 {
  margin: 0;
  min-height: 2.8rem;
  font-size: 0.9rem;
  line-height: 1.45;
  font-weight: 700;
  color: #242424;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.frequent-info p {
  margin: 0.35rem 0 0;
  color: var(--color-muted);
  font-size: 0.76rem;
}

.frequent-foot {
  margin-top: var(--space-4);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

:deep(.frequent-foot .el-button.is-circle),
:deep(.goods-bottom .el-button.is-circle) {
  width: 2.15rem;
  height: 2.15rem;
  padding: 0;
}

.empty-wrap {
  padding: var(--space-10) var(--space-6);
}

.empty-tip {
  margin: 0.25rem 0 0;
  color: var(--color-muted);
  font-size: 0.82rem;
}

.pager-wrap {
  margin-top: var(--space-8);
  display: flex;
  justify-content: center;
}
</style>
