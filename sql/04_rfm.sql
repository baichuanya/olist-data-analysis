-- RFM 用户分层：Recency / Frequency / Monetary
USE olist;

-- 分析基准日取数据中最新订单时间
SET @ref_date = (SELECT MAX(order_purchase_timestamp) FROM orders);

-- 计算每个真实客户（customer_unique_id）的 R/F/M，并用 NTILE(4) 打 1-4 分（4 为最优）
WITH rfm AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF(@ref_date, MAX(o.order_purchase_timestamp)) AS recency_days,
        COUNT(DISTINCT o.order_id)                          AS frequency,
        SUM(p.total_paid)                                   AS monetary
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN (
        SELECT order_id, SUM(payment_value) AS total_paid
        FROM order_payments
        GROUP BY order_id
    ) p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
scored AS (
    SELECT
        customer_unique_id,
        recency_days, frequency, monetary,
        NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC)     AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC)      AS m_score
    FROM rfm
)
SELECT
    r_score + f_score + m_score                                  AS total_score,
    COUNT(*)                                                     AS customer_cnt,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)           AS cnt_pct,
    ROUND(SUM(monetary), 0)                                      AS gmv,
    ROUND(SUM(monetary) * 100.0 / SUM(SUM(monetary)) OVER (), 1) AS gmv_pct
FROM scored
GROUP BY total_score
ORDER BY total_score DESC;

-- 购买频次分布（说明「大多数客户只买一次」）
SELECT
    CASE
        WHEN frequency = 1 THEN '1 次'
        WHEN frequency = 2 THEN '2 次'
        WHEN frequency BETWEEN 3 AND 5 THEN '3-5 次'
        ELSE '6 次及以上'
    END                                            AS freq_bucket,
    COUNT(*)                                       AS customer_cnt,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS frequency
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) t
GROUP BY freq_bucket
ORDER BY customer_cnt DESC;
