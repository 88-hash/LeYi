# 乐逸零食店管理系统

一个完整的线下零食店管理系统，包含顾客端（C端）和店家端（B端）。

## 技术栈

### 前端
- Vue 3 (Composition API + script setup)
- Vite
- Element Plus
- Pinia
- Vue Router
- Axios
- ECharts
- dayjs
- SCSS

### 后端
- Spring Boot 3.2
- MyBatis
- MySQL 8.0
- JWT
- Lombok

## 项目结构

```
乐逸零食店/
├── database/                # 数据库脚本
│   └── init.sql            # 初始化SQL
├── backend/                 # Spring Boot后端
│   ├── pom.xml
│   └── src/
├── frontend-customer/       # 顾客端Vue项目 (端口3000)
│   └── src/
└── frontend-admin/          # 店家端Vue项目 (端口3001)
    └── src/
```

## 快速开始

### 1. 数据库初始化

答辩演示建议按下面两步执行，先建基础库，再导入演示订单与统计数据：

```bash
# 第一步：初始化基础数据
mysql -u root -p < database/init.sql

# 第二步：导入答辩演示数据
mysql -u root -p < database/test_data.sql
```

或者在 MySQL 客户端中依次执行 `database/init.sql` 和 `database/test_data.sql`。

### 2. 后端启动

```bash
cd backend

# 修改数据库连接配置 (如需要)
# 编辑 src/main/resources/application.yml

# Maven打包运行
mvn spring-boot:run

# 或者打包后运行
mvn clean package
java -jar target/leyi-snack-1.0.0.jar
```

后端服务将在 http://localhost:8080 启动

### 3. 前端启动

**顾客端：**
```bash
cd frontend-customer
npm install
npm run dev
```
访问地址：http://localhost:3000

**店家端：**
```bash
cd frontend-admin
npm install
npm run dev
```
访问地址：http://localhost:3001

## 测试账号

### 顾客端
- 手机号：任意11位手机号
- 验证码：点击“获取验证码”后到后端控制台查看 `[LOGIN_CODE]`

### 店家端
- 店长账号：13800000001 / 123456
- 店员账号：13800000002 / 123456

### 顾客端开发登录说明
1. 打开顾客端登录页，输入手机号后点击“获取验证码”
2. 查看后端控制台输出，格式类似：`[LOGIN_CODE] phone=13645673454 code=919184`
3. 将控制台中的 6 位验证码输入登录页后提交登录

### 已有数据库后台账号重置说明
如果你不是用最新 `database/init.sql` 重新建库，而是沿用旧数据库，请执行下面的 SQL，把预置店长/店员账号密码重置为 `123456`：

```sql
UPDATE `admin`
SET `password` = '$2a$10$sq0JnxJBhl9HMviT57r7n.QyQ2JdjrHVgZ1pkxE/7CPZ0gXP3A80O'
WHERE `phone` IN ('13800000001', '13800000002');
```

## 功能模块

### 顾客端（C端）
- ✅ 手机号验证码登录（首次登录自动注册）
- ✅ 商品浏览（分类、搜索、详情）
- ✅ 购物车管理
- ✅ 订单提交（生成取货码）
- ✅ 订单管理（查看、取消）
- ✅ 商品评价
- ✅ 个人中心

### 店家端（B端）
- ✅ 账号密码登录
- ✅ 数据概览（营业额、订单统计、趋势图）
- ✅ 订单核销（输入取货码核销）
- ✅ 订单管理
- ✅ 商品管理（店长专属）
- ✅ 分类管理（店长专属）
- ✅ 店员管理（店长专属）
- ✅ 库存预警
- ✅ 临期商品预警

## 核心业务流程

### 顾客下单流程
1. 登录 → 浏览商品 → 加入购物车
2. 结算 → 提交订单 → 获取取货码
3. 到店报取货码 → 店员核销 → 付款取货
4. 完成后可评价商品

### 店员核销流程
1. 顾客到店报取货码
2. 店员输入取货码查询订单
3. 核对商品信息
4. 确认核销 → 线下收款

## 注意事项

1. 确保MySQL服务已启动，数据库配置正确
2. 后端需要Java 17+环境
3. 前端需要Node.js 16+环境
4. 登录前需要先获取验证码，默认不再提供固定万能验证码
5. 当前仓库不再自带商品演示图片，商品图请在管理端自行上传
6. 上传后的商品图片会真实写入 `backend/uploads/goods/`，并通过 `/uploads/goods/<文件名>` 直接访问

## 配置说明

### 后端配置 (application.yml)
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/leyi_snack
    username: root
    password: 123456

jwt:
  secret: your-secret-key
  expiration: 604800000  # 7天

upload:
  path: uploads
```

### 前端代理配置 (vite.config.js)
```javascript
server: {
  proxy: {
    '/api': {
      target: 'http://localhost:8080',
      changeOrigin: true
    }
  }
}
```

## 订单唯一性升级说明

如果你使用的是旧数据库，而不是重新执行最新的 `database/init.sql`，在升级到当前版本前需要先检查取货码是否重复：

```sql
SELECT verify_code, COUNT(*) AS duplicate_count
FROM `order`
GROUP BY verify_code
HAVING COUNT(*) > 1;
```

如果存在重复取货码，请先为重复记录重新生成新的 6 位取货码，再执行唯一索引升级：

```sql
ALTER TABLE `order`
ADD UNIQUE KEY `uk_verify_code` (`verify_code`);
```

新初始化的数据库直接使用仓库中的最新版 `database/init.sql` 即可，无需额外执行上述 SQL。

## 用户资料升级说明

如果你使用的是旧数据库，在升级到当前版本前需要同步用户资料字段：

```sql
ALTER TABLE `user`
MODIFY COLUMN `avatar` MEDIUMTEXT NULL COMMENT '头像URL',
ADD COLUMN `signature` VARCHAR(80) DEFAULT '' COMMENT '个性签名' AFTER `avatar`;
```

升级后，用户资料接口以 `name + avatar + signature` 作为统一契约，前端不再以本地缓存伪装后端保存成功。

## 答辩图片说明

- 项目默认商品数据不再绑定任何预置图片，避免仓库内旧图与数据库引用不一致
- 如果需要商品图演示，请登录后台“商品管理”自行上传
- 上传成功后，图片文件会真实落地到 `backend/uploads/goods/`
- 上传返回的相对路径会直接保存到数据库，前后端页面都会自动读取并展示



