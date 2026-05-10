-- 乐逸零食店数据库初始化脚本
-- MySQL 8.0

CREATE DATABASE IF NOT EXISTS leyi_snack DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE leyi_snack;

-- 1. 顾客表
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '用户ID',
    `phone` VARCHAR(20) NOT NULL UNIQUE COMMENT '手机号',
    `name` VARCHAR(50) DEFAULT '' COMMENT '昵称',
    `avatar` MEDIUMTEXT COMMENT '头像URL',
    `signature` VARCHAR(80) DEFAULT '' COMMENT '个性签名',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX `idx_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='顾客表';

-- 2. 管理员表（店长/店员）
DROP TABLE IF EXISTS `admin`;
CREATE TABLE `admin` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '管理员ID',
    `name` VARCHAR(50) NOT NULL COMMENT '姓名',
    `phone` VARCHAR(20) NOT NULL UNIQUE COMMENT '手机号',
    `password` VARCHAR(255) NOT NULL COMMENT '密码(加密)',
    `role` VARCHAR(20) NOT NULL DEFAULT 'clerk' COMMENT '角色: manager-店长, clerk-店员',
    `is_deleted` TINYINT(1) DEFAULT 0 COMMENT '是否删除',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX `idx_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理员表';

-- 3. 商品分类表
DROP TABLE IF EXISTS `category`;
CREATE TABLE `category` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '分类ID',
    `parent_id` BIGINT DEFAULT 0 COMMENT '父分类ID，0表示一级分类',
    `name` VARCHAR(50) NOT NULL COMMENT '分类名称',
    `sort` INT DEFAULT 0 COMMENT '排序值',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品分类表';

-- 4. 商品表
DROP TABLE IF EXISTS `goods`;
CREATE TABLE `goods` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '商品ID',
    `category_id` BIGINT NOT NULL COMMENT '分类ID（二级分类）',
    `name` VARCHAR(100) NOT NULL COMMENT '商品名称',
    `price` DECIMAL(10,2) NOT NULL COMMENT '价格',
    `stock` INT DEFAULT 0 COMMENT '库存',
    `safety_stock` INT DEFAULT 10 COMMENT '安全库存（预警阈值）',
    `bar_code` VARCHAR(50) DEFAULT '' COMMENT '条形码',
    `image_url` VARCHAR(255) DEFAULT '' COMMENT '主图URL',
    `description` TEXT COMMENT '商品描述',
    `promotion_tag` VARCHAR(50) DEFAULT '' COMMENT '促销标签',
    `is_on_sale` TINYINT(1) DEFAULT 1 COMMENT '是否上架: 1-上架, 0-下架',
    `is_deleted` TINYINT(1) DEFAULT 0 COMMENT '是否删除',
    `expire_date` DATE DEFAULT NULL COMMENT '保质期截止日期',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    CONSTRAINT `chk_goods_stock_non_negative` CHECK (`stock` >= 0),
    CONSTRAINT `chk_goods_safety_stock_non_negative` CHECK (`safety_stock` >= 0),
    INDEX `idx_category_id` (`category_id`),
    INDEX `idx_bar_code` (`bar_code`),
    INDEX `idx_is_on_sale` (`is_on_sale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品表';

-- 5. 商品轮播图表
DROP TABLE IF EXISTS `goods_image`;
CREATE TABLE `goods_image` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '图片ID',
    `goods_id` BIGINT NOT NULL COMMENT '商品ID',
    `image_url` VARCHAR(255) NOT NULL COMMENT '图片URL',
    `sort` INT DEFAULT 0 COMMENT '排序值',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX `idx_goods_id` (`goods_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品轮播图表';

-- 6. 购物车表
DROP TABLE IF EXISTS `cart`;
CREATE TABLE `cart` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '购物车ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `goods_id` BIGINT NOT NULL COMMENT '商品ID',
    `quantity` INT DEFAULT 1 COMMENT '数量',
    `is_checked` TINYINT(1) DEFAULT 1 COMMENT '是否选中',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    CONSTRAINT `chk_cart_quantity_positive` CHECK (`quantity` > 0),
    UNIQUE KEY `uk_user_goods` (`user_id`, `goods_id`),
    INDEX `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='购物车表';

-- 7. 订单主表
DROP TABLE IF EXISTS `order`;
CREATE TABLE `order` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '订单ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `user_phone` VARCHAR(20) NOT NULL COMMENT '用户手机号',
    `order_no` VARCHAR(50) NOT NULL UNIQUE COMMENT '订单编号',
    `total_price` DECIMAL(10,2) NOT NULL COMMENT '订单总价',
    `status` VARCHAR(20) DEFAULT 'pending' COMMENT '订单状态: pending-待取货, completed-已完成, cancelled-已取消',
    `verify_code` VARCHAR(10) NOT NULL COMMENT '取货码(6位数字)',
    `remark` VARCHAR(255) DEFAULT '' COMMENT '备注',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `verify_time` DATETIME DEFAULT NULL COMMENT '核销时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    CONSTRAINT `chk_order_total_price_non_negative` CHECK (`total_price` >= 0),
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_order_no` (`order_no`),
    UNIQUE KEY `uk_verify_code` (`verify_code`),
    INDEX `idx_status` (`status`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单主表';

-- 8. 订单明细表
DROP TABLE IF EXISTS `order_item`;
CREATE TABLE `order_item` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '明细ID',
    `order_id` BIGINT NOT NULL COMMENT '订单ID',
    `goods_id` BIGINT NOT NULL COMMENT '商品ID',
    `goods_name` VARCHAR(100) NOT NULL COMMENT '商品名称(冗余)',
    `goods_image` VARCHAR(255) DEFAULT '' COMMENT '商品图片(冗余)',
    `price` DECIMAL(10,2) NOT NULL COMMENT '商品单价',
    `quantity` INT NOT NULL COMMENT '购买数量',
    `subtotal` DECIMAL(10,2) NOT NULL COMMENT '小计金额',
    `is_commented` TINYINT(1) DEFAULT 0 COMMENT '是否已评价',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    CONSTRAINT `chk_order_item_quantity_positive` CHECK (`quantity` > 0),
    CONSTRAINT `chk_order_item_subtotal_non_negative` CHECK (`subtotal` >= 0),
    INDEX `idx_order_id` (`order_id`),
    INDEX `idx_goods_id` (`goods_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单明细表';

-- 9. 商品评价表
DROP TABLE IF EXISTS `comment`;
CREATE TABLE `comment` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '评价ID',
    `order_item_id` BIGINT NOT NULL COMMENT '订单明细ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `user_phone` VARCHAR(20) NOT NULL COMMENT '用户手机号',
    `goods_id` BIGINT NOT NULL COMMENT '商品ID',
    `goods_name` VARCHAR(100) DEFAULT '' COMMENT '商品名称(冗余)',
    `rating` INT NOT NULL COMMENT '评分(1-5星)',
    `content` VARCHAR(500) DEFAULT '' COMMENT '评价内容',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY `uk_order_item` (`order_item_id`),
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_goods_id` (`goods_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品评价表';

-- 10. 核销日志表
DROP TABLE IF EXISTS `verify_log`;
CREATE TABLE `verify_log` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '日志ID',
    `order_id` BIGINT NOT NULL COMMENT '订单ID',
    `order_no` VARCHAR(50) NOT NULL COMMENT '订单编号',
    `admin_id` BIGINT NOT NULL COMMENT '操作管理员ID',
    `admin_name` VARCHAR(50) DEFAULT '' COMMENT '操作管理员姓名',
    `action` VARCHAR(20) NOT NULL COMMENT '操作类型: verify-核销, cancel-取消',
    `remark` VARCHAR(255) DEFAULT '' COMMENT '备注',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
    INDEX `idx_order_id` (`order_id`),
    INDEX `idx_admin_id` (`admin_id`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='核销日志表';

-- 插入初始数据

-- 默认店长账号 (密码: 123456)
INSERT INTO `admin` (`name`, `phone`, `password`, `role`) VALUES 
('店长', '13800000001', '$2a$10$sq0JnxJBhl9HMviT57r7n.QyQ2JdjrHVgZ1pkxE/7CPZ0gXP3A80O', 'manager'),
('店员小王', '13800000002', '$2a$10$sq0JnxJBhl9HMviT57r7n.QyQ2JdjrHVgZ1pkxE/7CPZ0gXP3A80O', 'clerk');

-- 商品分类数据
INSERT INTO `category` (`id`, `parent_id`, `name`, `sort`) VALUES 
(1, 0, '零食', 1),
(2, 0, '饮料', 2),
(3, 0, '日用', 3),
(4, 1, '饼干', 1),
(5, 1, '糖果', 2),
(6, 1, '薯片', 3),
(7, 1, '坚果', 4),
(8, 2, '碳酸饮料', 1),
(9, 2, '果汁', 2),
(10, 2, '茶饮', 3),
(11, 2, '乳制品', 4),
(12, 3, '纸巾', 1),
(13, 3, '洗护用品', 2);

-- 商品数据
INSERT INTO `goods` (`category_id`, `name`, `price`, `stock`, `safety_stock`, `bar_code`, `image_url`, `description`, `promotion_tag`, `is_on_sale`, `expire_date`) VALUES 
(4, '奥利奥原味夹心饼干', 12.90, 50, 10, '6901668001015', '', '经典奥利奥夹心饼干，香脆可口', '', 1, '2026-06-30'),
(4, '趣多多曲奇饼干', 9.90, 35, 10, '6901668002015', '', '趣多多巧克力曲奇饼干', '第二件半价', 1, '2026-05-15'),
(5, '徐福记酥心糖', 15.80, 40, 10, '6902083801234', '', '徐福记新年酥心糖混合装', '', 1, '2026-08-20'),
(5, '阿尔卑斯棒棒糖', 8.50, 60, 15, '6923644212345', '', '阿尔卑斯混合口味棒棒糖', '', 1, '2026-12-01'),
(6, '乐事薯片原味', 7.90, 45, 10, '6924743912345', '', '乐事原味薯片，酥脆美味', '', 1, '2026-04-10'),
(6, '品客薯片原味', 14.90, 25, 8, '5053990101234', '', '品客原味薯片罐装', '', 1, '2026-07-25'),
(7, '三只松鼠坚果礼盒', 89.00, 20, 5, '6940763412345', '', '三只松鼠混合坚果大礼包', '限时特惠', 1, '2026-03-15'),
(7, '百草味每日坚果', 59.90, 30, 8, '6921168512345', '', '百草味每日坚果25袋装', '', 1, '2026-05-20'),
(8, '可口可乐', 3.50, 100, 20, '6901939612345', '', '可口可乐经典罐装330ml', '', 1, '2026-09-30'),
(8, '百事可乐', 3.50, 80, 20, '6901268612345', '', '百事可乐罐装330ml', '', 1, '2026-09-30'),
(8, '雪碧', 3.50, 90, 20, '6901939621234', '', '雪碧柠檬味汽水330ml', '', 1, '2026-09-30'),
(9, '农夫山泉NFC橙汁', 10.90, 40, 10, '6921168509876', '', '农夫山泉100%NFC橙汁', '', 1, '2026-02-28'),
(10, '康师傅冰红茶', 4.00, 70, 15, '6920152412345', '', '康师傅冰红茶500ml', '', 1, '2026-08-15'),
(10, '统一绿茶', 4.00, 65, 15, '6925303712345', '', '统一绿茶饮料500ml', '', 1, '2026-08-15'),
(11, '蒙牛纯牛奶', 65.00, 25, 8, '6907992512345', '', '蒙牛纯牛奶250ml*24盒', '', 1, '2026-03-01'),
(11, '伊利安慕希酸奶', 69.90, 20, 5, '6907992612345', '', '伊利安慕希原味酸奶205g*12', '', 1, '2026-02-15'),
(12, '维达抽纸', 29.90, 50, 10, '6901068812345', '', '维达抽纸软包3层100抽*24包', '', 1, NULL),
(12, '清风卷纸', 35.90, 40, 10, '6901068912345', '', '清风卷纸4层140g*27卷', '', 1, NULL),
(13, '舒肤佳香皂', 12.90, 35, 10, '6903148112345', '', '舒肤佳纯白清香型香皂125g*3', '', 1, NULL),
(13, '海飞丝洗发水', 39.90, 25, 8, '6903148212345', '', '海飞丝去屑洗发水400ml', '', 1, NULL);

-- 添加测试用户
INSERT INTO `user` (`phone`, `name`, `avatar`, `signature`) VALUES 
('13900000001', '测试用户', '', '');







