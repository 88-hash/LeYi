-- 乐逸零食店答辩演示数据
-- 在执行 init.sql 之后执行此文件
-- 作用：
-- 1. 重建订单/评价/核销演示数据
-- 2. 清空所有预置图片引用，后续图片统一通过管理端上传
-- 3. 让统计页、订单页、核销页保持有数据可演示

USE leyi_snack;
SET NAMES utf8mb4;

SET @day_0 = CURDATE();
SET @day_1 = DATE_SUB(@day_0, INTERVAL 1 DAY);
SET @day_2 = DATE_SUB(@day_0, INTERVAL 2 DAY);
SET @day_3 = DATE_SUB(@day_0, INTERVAL 3 DAY);
SET @day_4 = DATE_SUB(@day_0, INTERVAL 4 DAY);
SET @day_5 = DATE_SUB(@day_0, INTERVAL 5 DAY);
SET @day_6 = DATE_SUB(@day_0, INTERVAL 6 DAY);
SET @day_7 = DATE_SUB(@day_0, INTERVAL 7 DAY);

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE `verify_log`;
TRUNCATE TABLE `comment`;
TRUNCATE TABLE `order_item`;
TRUNCATE TABLE `order`;
TRUNCATE TABLE `cart`;
TRUNCATE TABLE `goods_image`;

DELETE FROM `user` WHERE id > 0;
ALTER TABLE `user` AUTO_INCREMENT = 1;

SET FOREIGN_KEY_CHECKS = 1;

-- 清空所有商品预置图片引用，图片改为后续在管理端自行上传
UPDATE `goods`
SET
    `image_url` = '',
    `is_on_sale` = 1,
    `is_deleted` = 0,
    `stock` = CASE `id`
        WHEN 1 THEN 52
        WHEN 2 THEN 36
        WHEN 3 THEN 42
        WHEN 4 THEN 55
        WHEN 5 THEN 38
        WHEN 6 THEN 24
        WHEN 7 THEN 18
        WHEN 8 THEN 26
        WHEN 9 THEN 88
        WHEN 10 THEN 76
        WHEN 11 THEN 84
        WHEN 12 THEN 5
        WHEN 13 THEN 63
        WHEN 14 THEN 61
        WHEN 15 THEN 18
        WHEN 16 THEN 3
        WHEN 17 THEN 46
        WHEN 18 THEN 9
        WHEN 19 THEN 30
        WHEN 20 THEN 6
        ELSE `stock`
    END,
    `expire_date` = CASE `id`
        WHEN 5 THEN DATE_ADD(@day_0, INTERVAL 25 DAY)
        WHEN 12 THEN DATE_ADD(@day_0, INTERVAL 12 DAY)
        WHEN 15 THEN DATE_ADD(@day_0, INTERVAL 18 DAY)
        WHEN 16 THEN DATE_ADD(@day_0, INTERVAL 7 DAY)
        ELSE `expire_date`
    END;

INSERT INTO `user` (`id`, `phone`, `name`, `avatar`, `signature`, `created_at`) VALUES
(1, '13900000001', '测试用户', '', '爱吃零食，准时取货', '2025-11-20 10:00:00'),
(2, '13900000002', '张小明', '', '下午常来取货', '2025-12-01 10:00:00'),
(3, '13900000003', '李小红', '', '喜欢坚果和饮料', '2025-12-05 14:30:00'),
(4, '13900000004', '王大伟', '', '习惯一次囤一周', '2025-12-10 09:15:00'),
(5, '13900000005', '赵小芳', '', '到店自提更方便', '2025-12-15 16:45:00'),
(6, '13900000006', '刘建国', '', '牛奶和纸品常购', '2025-12-20 11:20:00'),
(7, '13900000007', '陈美丽', '', '喜欢礼盒和零食组合', '2025-12-25 08:30:00'),
(8, '13900000008', '孙强', '', '经常给办公室补货', '2026-01-02 13:00:00'),
(9, '13900000009', '周小雨', '', '偏爱饮品和日用', '2026-01-05 10:30:00'),
(10, '13900000010', '吴大鹏', '', '答辩演示账号', '2026-01-10 15:00:00');

INSERT INTO `order` (`id`, `user_id`, `user_phone`, `order_no`, `total_price`, `status`, `verify_code`, `remark`, `created_at`, `verify_time`) VALUES
(1, 2, '13900000002', 'LEDEMO000001', 27.80, 'pending', '123456', '下课后来取', TIMESTAMP(@day_0, '09:15:00'), NULL),
(2, 3, '13900000003', 'LEDEMO000002', 92.50, 'pending', '234567', '礼盒要手提袋', TIMESTAMP(@day_0, '10:30:00'), NULL),
(3, 4, '13900000004', 'LEDEMO000003', 85.70, 'completed', '345678', '饮料帮忙冰一下', TIMESTAMP(@day_0, '11:20:00'), TIMESTAMP(@day_0, '14:30:00')),
(4, 5, '13900000005', 'LEDEMO000004', 84.30, 'completed', '456789', '', TIMESTAMP(@day_0, '12:00:00'), TIMESTAMP(@day_0, '15:10:00')),
(5, 6, '13900000006', 'LEDEMO000005', 65.80, 'pending', '567890', '纸品和洗护分开装', TIMESTAMP(@day_0, '16:10:00'), NULL),
(6, 2, '13900000002', 'LEDEMO000006', 101.90, 'completed', '678901', '', TIMESTAMP(@day_1, '09:10:00'), TIMESTAMP(@day_1, '11:20:00')),
(7, 7, '13900000007', 'LEDEMO000007', 77.90, 'completed', '789012', '', TIMESTAMP(@day_1, '10:50:00'), TIMESTAMP(@day_1, '13:40:00')),
(8, 8, '13900000008', 'LEDEMO000008', 45.60, 'completed', '890123', '办公室分享装', TIMESTAMP(@day_1, '14:20:00'), TIMESTAMP(@day_1, '16:30:00')),
(9, 9, '13900000009', 'LEDEMO000009', 66.90, 'cancelled', '901234', '临时不来店里了', TIMESTAMP(@day_1, '17:00:00'), NULL),
(10, 4, '13900000004', 'LEDEMO000010', 140.90, 'completed', '112233', '', TIMESTAMP(@day_2, '09:40:00'), TIMESTAMP(@day_2, '12:10:00')),
(11, 5, '13900000005', 'LEDEMO000011', 42.20, 'completed', '223344', '', TIMESTAMP(@day_2, '13:10:00'), TIMESTAMP(@day_2, '16:05:00')),
(12, 6, '13900000006', 'LEDEMO000012', 97.00, 'completed', '334455', '晚一点来拿', TIMESTAMP(@day_3, '10:00:00'), TIMESTAMP(@day_3, '13:00:00')),
(13, 7, '13900000007', 'LEDEMO000013', 72.70, 'completed', '445566', '', TIMESTAMP(@day_3, '15:20:00'), TIMESTAMP(@day_3, '17:10:00')),
(14, 8, '13900000008', 'LEDEMO000014', 73.90, 'completed', '556677', '', TIMESTAMP(@day_4, '09:30:00'), TIMESTAMP(@day_4, '12:20:00')),
(15, 9, '13900000009', 'LEDEMO000015', 75.80, 'completed', '667788', '', TIMESTAMP(@day_4, '14:40:00'), TIMESTAMP(@day_4, '18:00:00')),
(16, 10, '13900000010', 'LEDEMO000016', 53.20, 'completed', '778899', '答辩演示样例订单', TIMESTAMP(@day_5, '11:10:00'), TIMESTAMP(@day_5, '13:40:00')),
(17, 3, '13900000003', 'LEDEMO000017', 134.90, 'completed', '889900', '', TIMESTAMP(@day_6, '10:30:00'), TIMESTAMP(@day_6, '13:30:00')),
(18, 2, '13900000002', 'LEDEMO000018', 48.30, 'completed', '990011', '', TIMESTAMP(@day_7, '16:20:00'), TIMESTAMP(@day_7, '18:10:00'));

INSERT INTO `order_item` (`id`, `order_id`, `goods_id`, `goods_name`, `goods_image`, `price`, `quantity`, `subtotal`, `is_commented`) VALUES
(1, 1, 1, '奥利奥原味夹心饼干', '', 12.90, 1, 12.90, 0),
(2, 1, 5, '乐事薯片原味', '', 7.90, 1, 7.90, 0),
(3, 1, 9, '可口可乐', '', 3.50, 2, 7.00, 0),
(4, 2, 7, '三只松鼠坚果礼盒', '', 89.00, 1, 89.00, 0),
(5, 2, 9, '可口可乐', '', 3.50, 1, 3.50, 0),
(6, 3, 8, '百草味每日坚果', '', 59.90, 1, 59.90, 1),
(7, 3, 12, '农夫山泉NFC橙汁', '', 10.90, 2, 21.80, 0),
(8, 3, 13, '康师傅冰红茶', '', 4.00, 1, 4.00, 0),
(9, 4, 15, '蒙牛纯牛奶', '', 65.00, 1, 65.00, 1),
(10, 4, 5, '乐事薯片原味', '', 7.90, 2, 15.80, 0),
(11, 4, 11, '雪碧', '', 3.50, 1, 3.50, 0),
(12, 5, 17, '维达抽纸', '', 29.90, 1, 29.90, 0),
(13, 5, 18, '清风卷纸', '', 35.90, 1, 35.90, 0),
(14, 6, 7, '三只松鼠坚果礼盒', '', 89.00, 1, 89.00, 1),
(15, 6, 1, '奥利奥原味夹心饼干', '', 12.90, 1, 12.90, 0),
(16, 7, 16, '伊利安慕希酸奶', '', 69.90, 1, 69.90, 1),
(17, 7, 13, '康师傅冰红茶', '', 4.00, 2, 8.00, 0),
(18, 8, 3, '徐福记酥心糖', '', 15.80, 2, 31.60, 1),
(19, 8, 9, '可口可乐', '', 3.50, 4, 14.00, 0),
(20, 9, 8, '百草味每日坚果', '', 59.90, 1, 59.90, 0),
(21, 9, 10, '百事可乐', '', 3.50, 2, 7.00, 0),
(22, 10, 15, '蒙牛纯牛奶', '', 65.00, 2, 130.00, 1),
(23, 10, 12, '农夫山泉NFC橙汁', '', 10.90, 1, 10.90, 0),
(24, 11, 5, '乐事薯片原味', '', 7.90, 3, 23.70, 1),
(25, 11, 9, '可口可乐', '', 3.50, 3, 10.50, 0),
(26, 11, 13, '康师傅冰红茶', '', 4.00, 2, 8.00, 0),
(27, 12, 7, '三只松鼠坚果礼盒', '', 89.00, 1, 89.00, 1),
(28, 12, 14, '统一绿茶', '', 4.00, 2, 8.00, 0),
(29, 13, 17, '维达抽纸', '', 29.90, 2, 59.80, 1),
(30, 13, 19, '舒肤佳香皂', '', 12.90, 1, 12.90, 0),
(31, 14, 8, '百草味每日坚果', '', 59.90, 1, 59.90, 1),
(32, 14, 11, '雪碧', '', 3.50, 4, 14.00, 0),
(33, 15, 20, '海飞丝洗发水', '', 39.90, 1, 39.90, 1),
(34, 15, 18, '清风卷纸', '', 35.90, 1, 35.90, 0),
(35, 16, 6, '品客薯片原味', '', 14.90, 2, 29.80, 1),
(36, 16, 10, '百事可乐', '', 3.50, 3, 10.50, 0),
(37, 16, 1, '奥利奥原味夹心饼干', '', 12.90, 1, 12.90, 0),
(38, 17, 15, '蒙牛纯牛奶', '', 65.00, 1, 65.00, 1),
(39, 17, 16, '伊利安慕希酸奶', '', 69.90, 1, 69.90, 0),
(40, 18, 4, '阿尔卑斯棒棒糖', '', 8.50, 3, 25.50, 1),
(41, 18, 5, '乐事薯片原味', '', 7.90, 2, 15.80, 0),
(42, 18, 9, '可口可乐', '', 3.50, 2, 7.00, 0);

INSERT INTO `comment` (`order_item_id`, `user_id`, `user_phone`, `goods_id`, `goods_name`, `rating`, `content`, `created_at`) VALUES
(6, 4, '13900000004', 8, '百草味每日坚果', 5, '坚果新鲜，办公室分着吃很方便。', TIMESTAMP(@day_0, '17:10:00')),
(9, 5, '13900000005', 15, '蒙牛纯牛奶', 5, '日期很好，家里人都喜欢喝。', TIMESTAMP(@day_0, '18:00:00')),
(14, 2, '13900000002', 7, '三只松鼠坚果礼盒', 5, '礼盒很适合送人，包装也体面。', TIMESTAMP(@day_1, '16:00:00')),
(16, 7, '13900000007', 16, '伊利安慕希酸奶', 4, '口感浓郁，早餐配面包很合适。', TIMESTAMP(@day_1, '18:20:00')),
(18, 8, '13900000008', 3, '徐福记酥心糖', 5, '甜度刚好，老少都能吃。', TIMESTAMP(@day_1, '19:00:00')),
(22, 4, '13900000004', 15, '蒙牛纯牛奶', 5, '补货很快，到店就能直接拿。', TIMESTAMP(@day_2, '18:00:00')),
(24, 5, '13900000005', 5, '乐事薯片原味', 4, '经典口味，追剧必备。', TIMESTAMP(@day_2, '19:10:00')),
(27, 6, '13900000006', 7, '三只松鼠坚果礼盒', 5, '礼盒分量足，适合全家分享。', TIMESTAMP(@day_3, '18:20:00')),
(29, 7, '13900000007', 17, '维达抽纸', 5, '纸张柔软，家庭常备很实用。', TIMESTAMP(@day_3, '19:00:00')),
(31, 8, '13900000008', 8, '百草味每日坚果', 4, '每天一小包，携带方便。', TIMESTAMP(@day_4, '18:30:00')),
(33, 9, '13900000009', 20, '海飞丝洗发水', 5, '去屑效果不错，回购款。', TIMESTAMP(@day_4, '19:10:00')),
(35, 10, '13900000010', 6, '品客薯片原味', 4, '答辩演示买来摆拍也挺合适。', TIMESTAMP(@day_5, '15:00:00')),
(38, 3, '13900000003', 15, '蒙牛纯牛奶', 5, '冷藏后口感更好，常备单品。', TIMESTAMP(@day_6, '17:40:00')),
(40, 2, '13900000002', 4, '阿尔卑斯棒棒糖', 4, '口味多，拿来分享不错。', TIMESTAMP(@day_7, '19:00:00'));

INSERT INTO `verify_log` (`order_id`, `order_no`, `admin_id`, `admin_name`, `action`, `remark`, `created_at`) VALUES
(3, 'LEDEMO000003', 1, '店长', 'verify', '顾客现场取货', TIMESTAMP(@day_0, '14:30:00')),
(4, 'LEDEMO000004', 2, '店员小王', 'verify', '核对手机号后完成核销', TIMESTAMP(@day_0, '15:10:00')),
(6, 'LEDEMO000006', 1, '店长', 'verify', '礼盒订单已领取', TIMESTAMP(@day_1, '11:20:00')),
(7, 'LEDEMO000007', 2, '店员小王', 'verify', '饮品组合订单已领取', TIMESTAMP(@day_1, '13:40:00')),
(8, 'LEDEMO000008', 1, '店长', 'verify', '办公室团购订单已领取', TIMESTAMP(@day_1, '16:30:00')),
(9, 'LEDEMO000009', 1, '店长', 'cancel', '顾客临时取消到店', TIMESTAMP(@day_1, '17:30:00')),
(10, 'LEDEMO000010', 2, '店员小王', 'verify', '牛奶饮品订单已领取', TIMESTAMP(@day_2, '12:10:00')),
(11, 'LEDEMO000011', 1, '店长', 'verify', '零食饮料订单已领取', TIMESTAMP(@day_2, '16:05:00')),
(12, 'LEDEMO000012', 2, '店员小王', 'verify', '礼盒绿茶订单已领取', TIMESTAMP(@day_3, '13:00:00')),
(13, 'LEDEMO000013', 1, '店长', 'verify', '日用品订单已领取', TIMESTAMP(@day_3, '17:10:00')),
(14, 'LEDEMO000014', 2, '店员小王', 'verify', '坚果汽水订单已领取', TIMESTAMP(@day_4, '12:20:00')),
(15, 'LEDEMO000015', 1, '店长', 'verify', '洗护纸品订单已领取', TIMESTAMP(@day_4, '18:00:00')),
(16, 'LEDEMO000016', 2, '店员小王', 'verify', '答辩演示订单已领取', TIMESTAMP(@day_5, '13:40:00')),
(17, 'LEDEMO000017', 1, '店长', 'verify', '乳制品订单已领取', TIMESTAMP(@day_6, '13:30:00')),
(18, 'LEDEMO000018', 2, '店员小王', 'verify', '零食汽水订单已领取', TIMESTAMP(@day_7, '18:10:00'));

SELECT '答辩演示数据导入完成' AS message;
SELECT CONCAT('用户数: ', COUNT(*)) AS info FROM `user`;
SELECT CONCAT('订单数: ', COUNT(*)) AS info FROM `order`;
SELECT CONCAT('订单项数: ', COUNT(*)) AS info FROM `order_item`;
SELECT CONCAT('评价数: ', COUNT(*)) AS info FROM `comment`;
SELECT CONCAT('核销日志数: ', COUNT(*)) AS info FROM `verify_log`;
