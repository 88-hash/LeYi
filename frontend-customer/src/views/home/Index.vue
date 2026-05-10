<template>
  <div class="home-page">
    <section class="hero-wrap">
      <div class="desktop-container hero-grid">
        <article class="hero-content leyi-panel-strong">
          <p class="hero-tag">LEYi Premium Selection</p>
          <h1>探索 LeYi零食店 的 <span>高级零食体验</span></h1>
          <p class="hero-desc">
            甄选全球高评分零食与礼盒组合，覆盖日常囤货、办公室分享、节日送礼等多元场景。
          </p>
          <div class="hero-actions">
            <el-button type="primary" size="large" @click="router.push('/category')">立即选购</el-button>
            <el-button size="large" @click="router.push('/search?keyword=礼盒')">查看礼盒</el-button>
          </div>
          <div class="hero-kpis">
            <div>
              <strong>1200+</strong>
              <span>在售商品</span>
            </div>
            <div>
              <strong>96%</strong>
              <span>复购满意度</span>
            </div>
            <div>
              <strong>门店自提</strong>
              <span>下单后到店核销，即取即走</span>
            </div>
          </div>
        </article>

        <aside class="hero-visual leyi-panel-strong">
          <img :src="heroVisual" alt="LeYi精选零食" @error="handleImageError" />
          <div class="hero-badge">每周上新</div>
        </aside>
      </div>
    </section>

    <section class="desktop-container section-block">
      <div class="section-head">
        <div>
          <h2 class="leyi-title">精选分类</h2>
          <p class="leyi-subtitle">按口味、场景和饮食偏好快速筛选</p>
        </div>
        <el-button text @click="router.push('/category')">查看全部分类</el-button>
      </div>
      <div class="category-grid">
        <article
          v-for="(cat, index) in displayCategories"
          :key="cat.id || `virtual-${index}`"
          class="category-card leyi-panel"
          :style="{ '--accent': categoryAccent[index % categoryAccent.length] }"
          @click="cat.id && goCategory(cat.id)"
        >
          <span class="category-index">{{ String(index + 1).padStart(2, '0') }}</span>
          <h3>{{ cat.name }}</h3>
          <p>{{ cat.subtitle }}</p>
        </article>
      </div>
    </section>

    <section class="desktop-container section-block">
      <div class="section-head">
        <div>
          <h2 class="leyi-title">当下流行</h2>
          <p class="leyi-subtitle">LeYi 用户累计热销商品</p>
        </div>
      </div>
      <div class="goods-grid">
        <article
          v-for="(goods, index) in goodsList.slice(0, 8)"
          :key="goods.id"
          class="goods-card"
          @click="goDetail(goods.id)"
        >
          <div class="goods-image" :style="{ background: cardPalette[index % cardPalette.length] }">
            <img :src="getImageUrl(goods.imageUrl)" :alt="goods.name" @error="handleImageError" />
            <span v-if="goods.promotionTag" class="promo-tag">{{ goods.promotionTag }}</span>
          </div>
          <div class="goods-info">
            <p class="goods-name">{{ goods.name }}</p>
            <div class="goods-bottom">
              <span class="price-number">{{ goods.price.toFixed(2) }}</span>
              <el-button type="primary" circle @click.stop="addCart(goods)">
                <el-icon><ShoppingCart /></el-icon>
              </el-button>
            </div>
          </div>
        </article>
      </div>
    </section>

    <section class="desktop-container section-block new-arrival-block">
      <div class="section-head">
        <div>
          <h2 class="leyi-title">新品推荐</h2>
          <p class="leyi-subtitle">新到商品与限时系列，持续更新</p>
        </div>
      </div>
      <div class="new-arrival-grid">
        <article
          v-for="goods in newGoodsList"
          :key="goods.id"
          class="arrival-card leyi-panel"
          @click="goDetail(goods.id)"
        >
          <img :src="getImageUrl(goods.imageUrl)" :alt="goods.name" @error="handleImageError" />
          <div class="arrival-meta">
            <h3>{{ goods.name }}</h3>
            <span class="price-number">{{ goods.price.toFixed(2) }}</span>
          </div>
        </article>
      </div>
    </section>

    <section class="desktop-container brand-tail leyi-panel">
      <h3>LeYi零食店 · 让零食消费更有品质感</h3>
      <p>严选标准化仓储与全链路履约，支持购物车合并下单、订单进度追踪与售后保障。</p>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { getCategoryList, getGoodsList } from '@/api/goods'
import { useCartStore } from '@/stores/cart'
import { useUserStore } from '@/stores/user'
import { getImageUrl, handleImageError } from '@/utils/image'

const router = useRouter()
const cartStore = useCartStore()
const userStore = useUserStore()

const categories = ref([])
const goodsList = ref([])
const newGoodsList = ref([])

const heroVisual = '/hero-snacks.svg'

const categoryAccent = ['#f5d94d', '#f5b8d8', '#b8e4f7', '#c9efd7']
const cardPalette = ['#faf2d4', '#f7e9f1', '#e8f4fa', '#ecf7ed']

const displayCategories = computed(() => {
  const source = categories.value.slice(0, 4).map((item) => ({
    ...item,
    subtitle: '点击查看该分类在售商品'
  }))

  while (source.length < 4) {
    source.push({
      id: null,
      name: ['爆款零食', '进口专栏', '低糖系列', '办公室囤货'][source.length],
      subtitle: '分类数据加载中'
    })
  }

  return source
})

onMounted(async () => {
  try {
    const catRes = await getCategoryList()
    categories.value = catRes.data || []

    const goodsRes = await getGoodsList({ pageNum: 1, pageSize: 12, isOnSale: 1, sort: 'sales_desc' })
    goodsList.value = goodsRes.data?.list || []

    const newRes = await getGoodsList({ pageNum: 1, pageSize: 4, isOnSale: 1 })
    newGoodsList.value = newRes.data?.list || []
  } catch (error) {
    console.error(error)
  }
})

const goCategory = (id) => {
  router.push({ path: '/category', query: { id } })
}

const goDetail = (id) => {
  router.push(`/goods/${id}`)
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
</script>

<style lang="scss" scoped>
.home-page {
  padding-bottom: var(--space-12);
}

.hero-wrap {
  padding-top: var(--space-8);
}

.hero-grid {
  display: grid;
  grid-template-columns: 1.3fr 1fr;
  gap: var(--space-6);
}

.hero-content {
  padding: var(--space-12);
  background: linear-gradient(135deg, #fffef8 0%, #f9f9f3 100%);
}

.hero-tag {
  display: inline-flex;
  align-items: center;
  padding: 0 0.65rem;
  height: 1.6rem;
  border-radius: var(--radius-pill);
  background: rgba(238, 205, 43, 0.22);
  color: #665307;
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
}

.hero-content h1 {
  margin: var(--space-4) 0 var(--space-4);
  font-size: clamp(2rem, 2.55vw, 3rem);
  line-height: 1.15;
  letter-spacing: -0.02em;
}

.hero-content h1 span {
  color: #7a6412;
}

.hero-desc {
  margin: 0;
  color: var(--color-muted);
  line-height: 1.65;
  max-width: 36rem;
}

.hero-actions {
  margin-top: var(--space-8);
  display: flex;
  align-items: center;
  gap: var(--space-4);
}

.hero-kpis {
  margin-top: var(--space-10);
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--space-4);
}

.hero-kpis strong {
  display: block;
  font-size: 1.35rem;
  font-weight: 800;
}

.hero-kpis span {
  color: var(--color-muted);
  font-size: 0.82rem;
}

.hero-visual {
  position: relative;
  overflow: hidden;
  min-height: 34rem;
}

.hero-visual img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.hero-badge {
  position: absolute;
  left: var(--space-5);
  top: var(--space-5);
  height: 1.8rem;
  padding: 0 0.8rem;
  border-radius: var(--radius-pill);
  background: rgba(24, 24, 24, 0.78);
  color: #fff;
  display: inline-flex;
  align-items: center;
  font-size: 0.76rem;
  font-weight: 700;
}

.section-block {
  margin-top: var(--space-12);
}

.section-head {
  margin-bottom: var(--space-6);
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
}

.category-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: var(--space-4);
}

.category-card {
  padding: var(--space-6);
  border-top: 4px solid var(--accent);
  cursor: pointer;
  transition: transform 0.16s ease;
}

.category-card:hover {
  transform: translateY(-3px);
}

.category-index {
  color: var(--color-muted);
  font-weight: 700;
  font-size: 0.82rem;
}

.category-card h3 {
  margin: var(--space-2) 0 var(--space-2);
  font-size: 1.1rem;
  font-weight: 700;
}

.category-card p {
  margin: 0;
  color: var(--color-muted);
  font-size: 0.84rem;
}

:deep(.goods-grid .el-button.is-circle) {
  width: 2.2rem;
  height: 2.2rem;
  padding: 0;
}

.new-arrival-block {
  margin-top: var(--space-12);
}

.new-arrival-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: var(--space-4);
}

.arrival-card {
  padding: var(--space-4);
  cursor: pointer;
}

.arrival-card img {
  width: 100%;
  height: 13rem;
  border-radius: var(--radius-lg);
  object-fit: cover;
  display: block;
}

.arrival-meta {
  margin-top: var(--space-4);
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--space-3);
}

.arrival-meta h3 {
  margin: 0;
  font-size: 0.95rem;
  line-height: 1.4;
  font-weight: 700;
}

.brand-tail {
  margin-top: var(--space-12);
  padding: var(--space-10);
  text-align: center;
  background: linear-gradient(120deg, #f8f8f4 0%, #fffef7 65%, #f6f2df 100%);
}

.brand-tail h3 {
  margin: 0;
  font-size: 1.4rem;
  font-weight: 800;
}

.brand-tail p {
  margin: var(--space-4) auto 0;
  max-width: 54rem;
  color: var(--color-muted);
}
</style>
