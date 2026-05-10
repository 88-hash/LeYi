<template>
  <div class="category-page">
    <div class="page-container">
      <el-breadcrumb separator="/" class="breadcrumb">
        <el-breadcrumb-item :to="{ path: '/home' }">首页</el-breadcrumb-item>
        <el-breadcrumb-item>商品分类</el-breadcrumb-item>
      </el-breadcrumb>

      <section class="category-shell leyi-panel">
        <aside class="category-aside">
          <header class="aside-head">
            <h2>商品分类</h2>
            <p>按品类与口味快速筛选</p>
          </header>

          <div class="parent-list">
            <button
              v-for="cat in categories"
              :key="cat.id"
              type="button"
              class="parent-item"
              :class="{ active: activeCategory === cat.id && !activeSubCategory }"
              @click="selectCategory(cat)"
            >
              <span>{{ cat.name }}</span>
              <small>{{ cat.children?.length || 0 }}</small>
            </button>
          </div>

          <div class="sub-section" v-if="activeParent">
            <h3>子分类</h3>
            <div class="sub-list">
              <button
                type="button"
                class="sub-item"
                :class="{ active: !activeSubCategory }"
                @click="selectAllFromParent"
              >
                全部
              </button>
              <button
                v-for="sub in activeSubOptions"
                :key="sub.id"
                type="button"
                class="sub-item"
                :class="{ active: activeSubCategory === sub.id }"
                @click="selectSubCategory(sub.id)"
              >
                {{ sub.name }}
              </button>
            </div>
          </div>

          <div class="aside-promo">
            <p class="promo-label">门店活动</p>
            <p class="promo-copy">自提零食满 99 元，门店再减 10 元</p>
          </div>
        </aside>

        <div class="category-main">
          <header class="main-head">
            <div>
              <h3>{{ activeCategoryLabel }}</h3>
              <p>共 {{ total }} 件在售商品</p>
            </div>
            <div class="sort-bar">
              <button
                v-for="option in sortOptions"
                :key="option.value"
                type="button"
                class="sort-item"
                :class="{ active: sortBy === option.value }"
                @click="sortBy = option.value"
              >
                {{ option.label }}
              </button>
            </div>
          </header>

          <div v-if="displayGoodsList.length > 0" class="goods-grid">
            <article
              v-for="(goods, index) in displayGoodsList"
              :key="goods.id"
              class="goods-card"
              @click="goDetail(goods.id)"
            >
              <div class="goods-image">
                <img :src="getImageUrl(goods.imageUrl)" :alt="goods.name" @error="handleImageError">
                <span v-if="goods.promotionTag" class="goods-badge">{{ goods.promotionTag }}</span>
                <span v-else-if="index < 3" class="goods-badge neutral">精选</span>
              </div>
              <div class="goods-info">
                <p class="goods-name">{{ goods.name }}</p>
                <div class="goods-foot">
                  <span class="price-number">{{ Number(goods.price || 0).toFixed(2) }}</span>
                  <el-button type="primary" circle @click.stop="addCart(goods)">
                    <el-icon><ShoppingCart /></el-icon>
                  </el-button>
                </div>
              </div>
            </article>
          </div>

          <div v-else class="empty-wrap leyi-panel">
            <el-empty description="当前分类暂无在售商品" />
          </div>

          <div class="pager-wrap" v-if="total > pageSize">
            <el-pagination
              v-model:current-page="pageNum"
              :page-size="pageSize"
              :total="total"
              layout="prev, pager, next"
            />
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { getCategoryList, getGoodsList } from '@/api/goods'
import { useCartStore } from '@/stores/cart'
import { useUserStore } from '@/stores/user'
import { getImageUrl, handleImageError } from '@/utils/image'

const router = useRouter()
const route = useRoute()
const cartStore = useCartStore()
const userStore = useUserStore()

const categories = ref([])
const activeCategory = ref(null)
const activeSubCategory = ref(null)
const goodsList = ref([])
const pageNum = ref(1)
const pageSize = ref(16)
const total = ref(0)
const sortBy = ref('default')

const sortOptions = [
  { label: '综合推荐', value: 'default' },
  { label: '销量优先', value: 'sales_desc' },
  { label: '价格从低到高', value: 'price_asc' },
  { label: '价格从高到低', value: 'price_desc' }
]

const activeParent = computed(() => categories.value.find((item) => item.id === activeCategory.value) || null)

const activeSubOptions = computed(() => activeParent.value?.children || [])

const activeCategoryLabel = computed(() => {
  if (!activeParent.value) return '全部商品'
  if (!activeSubCategory.value) return activeParent.value.name
  const sub = activeSubOptions.value.find((item) => item.id === activeSubCategory.value)
  return sub?.name || activeParent.value.name
})

const currentGoodsParams = computed(() => {
  const categoryId = activeSubCategory.value || activeCategory.value
  if (!categoryId) return null

  return {
    categoryId,
    pageNum: pageNum.value,
    pageSize: pageSize.value,
    isOnSale: 1,
    sort: sortBy.value,
    includeChildren: !activeSubCategory.value
  }
})

const displayGoodsList = computed(() => goodsList.value)

const applyRouteCategory = () => {
  if (!categories.value.length) return

  const rawId = Number(route.query.id)
  if (!rawId) {
    const first = categories.value[0]
    if (first) {
      activeCategory.value = first.id
      activeSubCategory.value = null
    }
    return
  }

  const parent = categories.value.find((item) => item.id === rawId)
  if (parent) {
    activeCategory.value = parent.id
    activeSubCategory.value = null
    return
  }

  for (const cat of categories.value) {
    const sub = (cat.children || []).find((item) => item.id === rawId)
    if (sub) {
      activeCategory.value = cat.id
      activeSubCategory.value = sub.id
      return
    }
  }

  const fallback = categories.value[0]
  if (fallback) {
    activeCategory.value = fallback.id
    activeSubCategory.value = null
  }
}

const fetchCategories = async () => {
  try {
    const res = await getCategoryList()
    categories.value = res.data || []
    applyRouteCategory()
    if (categories.value.length > 0) {
      await fetchGoods()
    } else {
      goodsList.value = []
      total.value = 0
    }
  } catch (error) {
    console.error(error)
  }
}

const fetchGoods = async () => {
  if (!currentGoodsParams.value) {
    goodsList.value = []
    total.value = 0
    return
  }

  try {
    const res = await getGoodsList(currentGoodsParams.value)
    goodsList.value = res.data?.list || []
    total.value = Number(res.data?.total || 0)
  } catch (error) {
    console.error(error)
  }
}

const selectCategory = (cat) => {
  const nextId = cat.id
  const currentId = Number(route.query.id) || null

  if (currentId === nextId) {
    if (pageNum.value !== 1) {
      pageNum.value = 1
    }
    return
  }

  router.replace({ path: '/category', query: { id: nextId } })
}

const selectAllFromParent = () => {
  if (!activeParent.value) return
  const nextId = activeParent.value.id
  const currentId = Number(route.query.id) || null

  if (currentId === nextId) {
    if (pageNum.value !== 1) {
      pageNum.value = 1
    }
    return
  }

  router.replace({ path: '/category', query: { id: nextId } })
}

const selectSubCategory = (subId) => {
  const currentId = Number(route.query.id) || null

  if (currentId === subId) {
    if (pageNum.value !== 1) {
      pageNum.value = 1
    }
    return
  }

  router.replace({ path: '/category', query: { id: subId } })
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

watch(
  () => route.query.id,
  () => {
    applyRouteCategory()
    if (pageNum.value !== 1) {
      pageNum.value = 1
      return
    }
    fetchGoods()
  }
)

watch(pageNum, () => {
  fetchGoods()
})

watch(sortBy, () => {
  if (pageNum.value !== 1) {
    pageNum.value = 1
    return
  }
  fetchGoods()
})

onMounted(fetchCategories)
</script>

<style lang="scss" scoped>
.category-shell {
  display: grid;
  grid-template-columns: 18.5rem minmax(0, 1fr);
  gap: var(--space-6);
  padding: var(--space-6);
}

.category-aside {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.aside-head h2 {
  margin: 0;
  font-size: 1.25rem;
  line-height: 1.2;
  font-weight: 800;
}

.aside-head p {
  margin: 0.35rem 0 0;
  color: var(--color-muted);
  font-size: 0.84rem;
}

.parent-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  max-height: 22rem;
  overflow-y: auto;
  padding-right: 0.3rem;
}

.parent-item {
  height: 2.5rem;
  padding: 0 0.8rem;
  border-radius: var(--radius-lg);
  border: 1px solid rgba(24, 24, 24, 0.12);
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: pointer;
  color: #2f2f2f;
  font-size: 0.84rem;
  font-weight: 700;
  transition: border-color 0.16s ease, background 0.16s ease;
}

.parent-item small {
  color: var(--color-muted);
}

.parent-item.active {
  background: rgba(238, 205, 43, 0.2);
  border-color: rgba(238, 205, 43, 0.9);
  color: #261f08;
}

.sub-section h3 {
  margin: 0;
  font-size: 0.92rem;
  font-weight: 700;
}

.sub-list {
  margin-top: 0.7rem;
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.sub-item {
  height: 1.9rem;
  padding: 0 0.65rem;
  border-radius: var(--radius-pill);
  border: 1px solid rgba(24, 24, 24, 0.12);
  background: #fff;
  font-size: 0.78rem;
  font-weight: 600;
  cursor: pointer;
}

.sub-item.active {
  background: #1f1f1f;
  color: #fff;
  border-color: #1f1f1f;
}

.aside-promo {
  margin-top: auto;
  border-radius: var(--radius-xl);
  background: linear-gradient(135deg, #f6f3e1 0%, #faf9f3 100%);
  border: 1px solid rgba(24, 24, 24, 0.1);
  padding: var(--space-5);
}

.promo-label {
  margin: 0;
  font-size: 0.72rem;
  font-weight: 800;
  letter-spacing: 0.08em;
  color: #8a741a;
  text-transform: uppercase;
}

.promo-copy {
  margin: 0.45rem 0 0;
  font-size: 0.82rem;
  color: #3f3f3f;
  line-height: 1.55;
}

.category-main {
  min-width: 0;
}

.main-head {
  margin-bottom: var(--space-5);
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--space-4);
}

.main-head h3 {
  margin: 0;
  font-size: clamp(1.22rem, 1.35vw, 1.6rem);
  font-weight: 800;
}

.main-head p {
  margin: 0.25rem 0 0;
  color: var(--color-muted);
  font-size: 0.84rem;
}

.sort-bar {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.sort-item {
  height: 2rem;
  padding: 0 0.75rem;
  border-radius: var(--radius-pill);
  border: 1px solid rgba(24, 24, 24, 0.12);
  background: #fff;
  color: #4f4f4f;
  font-size: 0.76rem;
  font-weight: 700;
  cursor: pointer;
}

.sort-item.active {
  background: rgba(238, 205, 43, 0.23);
  color: #261f08;
  border-color: rgba(238, 205, 43, 0.9);
}

.goods-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: clamp(0.95rem, 1.1vw, 1.3rem);
}

.goods-card {
  border-radius: var(--radius-lg);
  background: #fff;
  border: 1px solid rgba(24, 24, 24, 0.08);
  box-shadow: var(--shadow-xs);
  overflow: hidden;
  cursor: pointer;
  transition: transform 0.18s ease, box-shadow 0.18s ease;
}

.goods-card:hover {
  transform: translateY(-3px);
  box-shadow: var(--shadow-md);
}

.goods-image {
  position: relative;
  aspect-ratio: 1 / 1;
  background: #f4f4f4;
}

.goods-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.goods-badge {
  position: absolute;
  left: 0.65rem;
  top: 0.65rem;
  padding: 0 0.5rem;
  height: 1.45rem;
  border-radius: var(--radius-pill);
  background: rgba(24, 24, 24, 0.85);
  color: #fff;
  font-size: 0.68rem;
  font-weight: 700;
  display: inline-flex;
  align-items: center;
}

.goods-badge.neutral {
  background: rgba(238, 205, 43, 0.9);
  color: #1f1f1f;
}

.goods-info {
  padding: var(--space-4);
}

.goods-name {
  margin: 0;
  min-height: 2.8rem;
  font-size: 0.9rem;
  line-height: 1.45;
  font-weight: 700;
  color: #242424;
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
  overflow: hidden;
}

.goods-foot {
  margin-top: var(--space-4);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

:deep(.goods-foot .el-button.is-circle) {
  width: 2.15rem;
  height: 2.15rem;
  padding: 0;
}

.empty-wrap {
  padding: var(--space-10) var(--space-6);
}

.pager-wrap {
  margin-top: var(--space-8);
  display: flex;
  justify-content: center;
}
</style>
