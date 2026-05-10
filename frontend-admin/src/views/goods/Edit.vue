<template>
  <div class="goods-edit-page">
    <div class="page-card">
      <div class="card-header">
        <h3>{{ isEdit ? '编辑商品' : '新增商品' }}</h3>
      </div>
      <div class="card-body">
        <el-form :model="form" :rules="rules" ref="formRef" label-width="100px" style="max-width: 600px">
          <el-form-item label="商品名称" prop="name">
            <el-input v-model="form.name" placeholder="请输入商品名称" />
          </el-form-item>

          <el-form-item label="商品分类" prop="categoryId">
            <el-cascader
              v-model="categoryPath"
              :options="categories"
              :props="{ value: 'id', label: 'name', children: 'children' }"
              placeholder="请选择分类"
              @change="handleCategoryChange"
            />
          </el-form-item>

          <el-form-item label="商品价格" prop="price">
            <el-input-number v-model="form.price" :min="0" :precision="2" :step="0.1" />
          </el-form-item>

          <el-form-item label="库存数量" prop="stock">
            <el-input-number v-model="form.stock" :min="0" />
          </el-form-item>

          <el-form-item label="安全库存">
            <el-input-number v-model="form.safetyStock" :min="0" />
          </el-form-item>

          <el-form-item label="商品条码">
            <el-input v-model="form.barCode" placeholder="请输入商品条码" />
          </el-form-item>

          <el-form-item label="商品主图">
            <el-upload
              class="image-uploader"
              :show-file-list="false"
              :http-request="handleUpload"
              accept="image/png,image/jpeg"
            >
              <img v-if="form.imageUrl" :src="form.imageUrl" class="uploaded-image" @error="handlePreviewError" />
              <el-icon v-else class="upload-icon"><Plus /></el-icon>
            </el-upload>
          </el-form-item>

          <el-form-item label="促销标签">
            <el-input v-model="form.promotionTag" placeholder="如：第二件半价" />
          </el-form-item>

          <el-form-item label="保质期至">
            <el-date-picker v-model="form.expireDate" type="date" placeholder="选择日期" value-format="YYYY-MM-DD" />
          </el-form-item>

          <el-form-item label="商品描述">
            <el-input v-model="form.description" type="textarea" :rows="4" placeholder="请输入商品描述" />
          </el-form-item>

          <el-form-item label="上架状态">
            <el-switch v-model="form.isOnSale" :active-value="1" :inactive-value="0" />
          </el-form-item>

          <el-form-item>
            <el-button @click="router.back()">取消</el-button>
            <el-button type="primary" @click="handleSubmit" :loading="submitting">保存</el-button>
          </el-form-item>
        </el-form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { addGoods, getCategoryList, getGoodsDetail, updateGoods, uploadFile } from '@/api'

const route = useRoute()
const router = useRouter()

const isEdit = computed(() => !!route.params.id)
const formRef = ref()
const submitting = ref(false)
const categories = ref([])
const categoryPath = ref([])
const ADMIN_PLACEHOLDER = '/placeholder.svg'

const form = reactive({
  id: null,
  name: '',
  categoryId: null,
  price: 0,
  stock: 0,
  safetyStock: 10,
  barCode: '',
  imageUrl: '',
  promotionTag: '',
  expireDate: '',
  description: '',
  isOnSale: 1
})

const rules = {
  name: [{ required: true, message: '请输入商品名称', trigger: 'blur' }],
  categoryId: [{ required: true, message: '请选择商品分类', trigger: 'change' }],
  price: [{ required: true, message: '请输入商品价格', trigger: 'blur' }]
}

onMounted(async () => {
  const res = await getCategoryList()
  categories.value = res.data || []

  if (isEdit.value) {
    const goodsRes = await getGoodsDetail(route.params.id)
    const goods = goodsRes.data.goods
    Object.assign(form, goods)

    for (const cat of categories.value) {
      const sub = cat.children?.find(item => item.id === goods.categoryId)
      if (sub) {
        categoryPath.value = [cat.id, sub.id]
        break
      }
    }
  }
})

const handleCategoryChange = (val) => {
  form.categoryId = val ? val[val.length - 1] : null
}

const handleUpload = async ({ file }) => {
  try {
    const res = await uploadFile(file)
    form.imageUrl = res.data
    ElMessage.success('上传成功')
  } catch (e) {
    console.error(e)
    ElMessage.error(e?.message || '上传失败')
  }
}

const handlePreviewError = (event) => {
  const target = event?.target
  if (!target || target.dataset.fallbackApplied === 'true') {
    return
  }
  target.dataset.fallbackApplied = 'true'
  target.src = ADMIN_PLACEHOLDER
}

const handleSubmit = async () => {
  await formRef.value.validate()
  submitting.value = true
  try {
    if (isEdit.value) {
      await updateGoods(form)
    } else {
      await addGoods(form)
    }
    ElMessage.success('保存成功')
    router.back()
  } catch (e) {
    console.error(e)
  } finally {
    submitting.value = false
  }
}
</script>

<style lang="scss" scoped>
.image-uploader {
  :deep(.el-upload) {
    border: 1px dashed #d9d9d9;
    border-radius: 8px;
    cursor: pointer;
    width: 120px;
    height: 120px;
    display: flex;
    align-items: center;
    justify-content: center;

    &:hover {
      border-color: #1a73e8;
    }
  }

  .uploaded-image {
    width: 120px;
    height: 120px;
    object-fit: cover;
    border-radius: 8px;
  }

  .upload-icon {
    font-size: 28px;
    color: #8c939d;
  }
}
</style>
