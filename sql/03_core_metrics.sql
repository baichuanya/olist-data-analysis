-- 核心业务指标：GMV、客单价、月度趋势、复购率、取消率、评分
USE olist;

-- 1. GMV / 订单量 / 客单价（仅统计已交付订单；支付先聚合再 JOIN，避免多期支付重复计费）
SELECT
    COUNT(*)                                AS delivered_orders,
    ROUND(SUM(p.total_paid), 2)             AS gmv,
    ROUND(SUM(p.total_paid) / COUNT(*), 2)  AS aov
FROM orders o
JOIN (
    SELECT order_id, SUM(payment_value) AS total_paid
    FROM order_payments
    GROUP BY order_id
) p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered';

-- 2. 月度 GMV 趋势 + 环比（窗口函数 LAG）
WITH monthly AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS ym,
        COUNT(*)                                          AS orders,
        SUM(p.total_paid)                                 AS gmv
    FROM orders o
    JOIN (
        SELECT order_id, SUM(payment_value) AS total_paid
        FROM order_payments
        GROUP BY order_id
    ) p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY ym
)
SELECT
    ym,
    orders,
    ROUND(gmv, 0)                                                  AS gmv,
    ROUND(gmv * 100.0 / LAG(gmv) OVER (ORDER BY ym) - 100, 1)     AS mom_pct
FROM monthly
ORDER BY ym;

-- 3. 复购率（用 customer_unique_id 识别真实客户，同一客户多单算复购）
SELECT
    ROUND(SUM(is_repeat) * 100.0 / COUNT(*), 2) AS repurchase_rate
FROM (
    SELECT
        c.customer_unique_id,
        CASE WHEN COUNT(DISTINCT o.order_id) > 1 THEN 1 ELSE 0 END AS is_repeat
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) t;

-- 4. 取消率
SELECT
    ROUND(SUM(order_status = 'canceled') * 100.0 / COUNT(*), 2) AS cancel_rate
FROM orders;

-- 5. 平均评分与评分分布
SELECT
    ROUND(AVG(review_score), 2) AS avg_score,
    COUNT(*)                    AS review_cnt
FROM order_reviews;

SELECT
    review_score,
    COUNT(*) AS cnt,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM order_reviews), 1) AS pct
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;
