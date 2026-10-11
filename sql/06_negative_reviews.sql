-- 深挖：为什么 1 星评价占比异常高（11.5%）
USE olist;

-- 0. 先确认：一个订单是否有多条评价（review_id 去重后 order 是否唯一）
SELECT
    COUNT(*)                            AS review_cnt,
    COUNT(DISTINCT order_id)            AS distinct_order,
    COUNT(*) - COUNT(DISTINCT order_id) AS multi_review_orders
FROM order_reviews;

-- 1. 物流延迟对比：1 星 vs 非 1 星（正数 = 延迟送达）
SELECT
    CASE WHEN r.review_score = 1 THEN '1星' ELSE '非1星' END AS score_group,
    COUNT(*)                                        AS order_cnt,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)), 1) AS avg_delay_days,
    SUM(DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0)       AS late_orders,
    ROUND(SUM(DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0) * 100.0 / COUNT(*), 1) AS late_rate_pct
FROM order_reviews r
JOIN orders o ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY score_group;

-- 2. 品类维度的 1 星率（item 粒度，只看评价样本 >= 500 的品类）
SELECT
    COALESCE(t.product_category_name_english, p.product_category_name, 'unclassified') AS category,
    COUNT(*)                                   AS item_cnt,
    SUM(r.review_score = 1)                    AS one_star_cnt,
    ROUND(SUM(r.review_score = 1) * 100.0 / COUNT(*), 1) AS one_star_rate_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
JOIN orders o ON oi.order_id = o.order_id
JOIN order_reviews r ON oi.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY category
HAVING item_cnt >= 500
ORDER BY one_star_rate_pct DESC
LIMIT 15;

-- 3. 价格段对比：1 星 vs 非 1 星的平均订单金额
SELECT
    CASE WHEN r.review_score = 1 THEN '1星' ELSE '非1星' END AS score_group,
    COUNT(*)                       AS order_cnt,
    ROUND(AVG(p.total_paid), 2)    AS avg_order_value
FROM order_reviews r
JOIN (
    SELECT order_id, SUM(payment_value) AS total_paid
    FROM order_payments
    GROUP BY order_id
) p ON r.order_id = p.order_id
GROUP BY score_group;
