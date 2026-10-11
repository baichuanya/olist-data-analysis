-- 留存 cohort 分析：按客户首单月份分组，统计该 cohort 后续复购率
USE olist;

SELECT
    DATE_FORMAT(first_ts, '%Y-%m')                    AS cohort,
    COUNT(*)                                          AS cohort_size,
    SUM(frequency > 1)                                AS repeat_cnt,
    ROUND(SUM(frequency > 1) * 100.0 / COUNT(*), 2)   AS repeat_rate
FROM (
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_ts,
        COUNT(DISTINCT o.order_id)      AS frequency
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) t
GROUP BY cohort
ORDER BY cohort;
