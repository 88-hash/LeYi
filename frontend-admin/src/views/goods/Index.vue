<template>
  <div class="goods-page">
    <div class="page-card">
      <div class="card-header">
        <div class="filter-row">
          <el-select v-model="filters.categoryId" placeholder="商品分类" clearable style="width: 150px">
            <el-option-group v-for="cat in categories" :key="cat.id" :label="cat.name">
              <el-option v-for="sub in cat.children" :key="sub.id" :label="sub.name" :value="sub.id" />
            </el-option-group>
          </el-select>
          <el-select v-model="filters.isOnSale" placeholder="上架状态" clearable style="width: 120px">
            <el-option label="已上架" :value="1" />
            <el-option label="已下架" :value="0" />
          </el-select>
          <el-input v-model="filters.keyword" placeholder="搜索商品名称/条码" style="width: 200px" clearable />
          <el-button type="primary" @click="fetchGoods">搜索</el-button>
        </div>
        <el-button type="primary" @click="router.push('/goods/add')">
          <el-icon><Plus /></el-icon> 新增商品
        </el-button>
      </div>
      <div class="card-body">
        <el-table :data="goodsList" v-loading="loading" border>
          <el-table-column label="商品图片" width="80">
            <template #default="{ row }">
              <img
                :src="resolveImageUrl(row.imageUrl)"
                alt="商品图片"
                class="goods-thumb"
                @error="handleImageError"
              />
            </template>
          </el-table-column>
          <el-table-column prop="name" label="商品名称" min-width="150" />
          <el-table-column prop="categoryName" label="分类" width="100" />
          <el-table-column prop="price" label="价格" width="100">
            <template #default="{ row }">¥{{ row.price?.toFixed(2) }}</template>
          </el-table-column>
          <el-table-column prop="stock" label="库存" width="80">
            <template #default="{ row }">
              <span :class="{ 'text-danger': row.stock < row.safetyStock }">{{ row.stock }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="barCode" label="条码" width="130" />
          <el-table-column prop="isOnSale" label="状态" width="80">
            <template #default="{ row }">
              <el-tag :type="row.isOnSale ? 'success' : 'info'">{{ row.isOnSale ? '上架' : '下架' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="200" fixed="right">
            <template #default="{ row }">
              <el-button type="primary" text size="small" @click="router.push(`/goods/edit/${row.id}`)">编辑</el-button>
              <el-button :type="row.isOnSale ? 'warning' : 'success'" text size="small" @click="handleToggleSale(row)">
                {{ row.isOnSale ? '下架' : '上架' }}
              </el-button>
              <el-button type="danger" text size="small" @click="handleDelete(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
        
        <el-pagination
          v-model:current-page="pagination.pageNum"
          v-model:page-size="pagination.pageSize"
          :total="pagination.total"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next"
          @change="fetchGoods"
          style="margin-top: 16px; justify-content: flex-end"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getGoodsList, getCategoryList, updateGoodsSale, deleteGoods } from '@/api'

const router = useRouter()
const loading = ref(false)
const goodsList = ref([])
const categories = ref([])
const filters = reactive({ categoryId: null, isOnSale: null, keyword: '' })
const pagination = reactive({ pageNum: 1, pageSize: 10, total: 0 })
const ADMIN_PLACEHOLDER = '/placeholder.svg'

onMounted(async () => {
  const res = await getCategoryList()
  categories.value = res.data || []
  fetchGoods()
})

const fetchGoods = async () => {
  loading.value = true
  try {
    const res = await getGoodsList({
      categoryId: filters.categoryId,
      isOnSale: filters.isOnSale,
      keyword: filters.keyword,
      pageNum: pagination.pageNum,
      pageSize: pagination.pageSize
    })
    goodsList.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

const resolveImageUrl = (value) => {
  const imageUrl = `${value || ''}`.trim()
  return imageUrl || ADMIN_PLACEHOLDER
}

const handleImageError = (event) => {
  const target = event?.target
  if (!target || target.dataset.fallbackApplied === 'true') {
    return
  }
  target.dataset.fallbackApplied = 'true'
  target.src = ADMIN_PLACEHOLDER
}

const handleToggleSale = async (row) => {
  const newStatus = row.isOnSale ? 0 : 1
  await ElMessageBox.confirm(`确定${newStatus ? '上架' : '下架'}该商品吗？`, '提示')
  try {
    await updateGoodsSale(row.id, newStatus)
    ElMessage.success('操作成功')
    row.isOnSale = newStatus
  } catch (e) {
    console.error(e)
  }
}

const handleDelete = async (row) => {
  await ElMessageBox.confirm('确定删除该商品吗？', '提示', { type: 'warning' })
  try {
    await deleteGoods(row.id)
    ElMessage.success('删除成功')
    fetchGoods()
  } catch (e) {
    console.error(e)
  }
}
</script>

<style lang="scss" scoped>
.filter-row {
  display: flex;
  gap: 12px;
}

.text-danger {
  color: #ea4335;
  font-weight: 600;
}

.goods-thumb {
  width: 50px;
  height: 50px;
  border-radius: 4px;
  object-fit: cover;
  display: block;
  background: #f5f5f5;
}
</style>



