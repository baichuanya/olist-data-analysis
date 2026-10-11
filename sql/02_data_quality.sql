-- 数据质量检查：完整性、唯一性、异常值、逻辑一致性
USE olist;

-- 1. 订单时间跨度
SELECT
    MIN(order_purchase_timestamp) AS min_order_time,
    MAX(order_purchase_timestamp) AS max_order_time,
    COUNT(*)                     AS total_orders
FROM orders;

-- 2. 订单状态分布
SELECT
    order_status,
    COUNT(*)                                      AS order_cnt,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS pct
FROM orders
GROUP BY order_status
ORDER BY order_cnt DESC;

-- 3. 订单主键唯一性（期望 0 行）
SELECT COUNT(*) AS dup_orders
FROM (SELECT order_id FROM orders GROUP BY order_id HAVING COUNT(*) > 1) t;

-- 4. 缺失值检查（orders 关键列）
SELECT
    SUM(customer_id IS NULL)                    AS null_customer,
    SUM(order_approved_at IS NULL)              AS null_approved,
    SUM(order_delivered_carrier_date IS NULL)   AS null_carrier,
    SUM(order_delivered_customer_date IS NULL)  AS null_delivered
FROM orders;

-- 5. 负价格 / 负运费（期望 0）
SELECT
    SUM(price < 0)          AS neg_price,
    SUM(freight_value < 0)  AS neg_freight
FROM order_items;

-- 6. 日期逻辑异常：发货早于下单（期望 0）
SELECT COUNT(*) AS carrier_before_purchase
FROM orders
WHERE order_delivered_carrier_date < order_purchase_timestamp;

-- 7. 商品类目缺失（products 表）
SELECT
    SUM(product_category_name IS NULL) AS null_category
FROM products;
