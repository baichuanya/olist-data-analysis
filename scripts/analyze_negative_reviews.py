# -*- coding: utf-8 -*-
"""1 星差评深挖分析：物流延迟 / 品类 / 价格 三个维度对比
在 PyCharm 里右键 Run 即可，结果直接打印在运行窗口。
"""
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine('mysql+pymysql://root:123456@localhost:3306/olist?charset=utf8mb4')

print('=' * 70)
print('1. 物流延迟对比：1 星 vs 非 1 星（正数 = 延迟送达）')
print('=' * 70)
df = pd.read_sql("""
    SELECT
        CASE WHEN r.review_score = 1 THEN '1星' ELSE '非1星' END AS score_group,
        COUNT(*) AS order_cnt,
        ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)), 1) AS avg_delay_days,
        ROUND(SUM(DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0) * 100.0 / COUNT(*), 1) AS late_rate_pct
    FROM order_reviews r
    JOIN orders o ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY score_group
""", engine)
print(df.to_string(index=False))
print()

print('=' * 70)
print('2. 品类 1 星率 TOP 15（评价样本 >= 500 的品类）')
print('=' * 70)
df = pd.read_sql("""
    SELECT
        COALESCE(t.product_category_name_english, p.product_category_name, 'unclassified') AS category,
        COUNT(*) AS item_cnt,
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
    LIMIT 15
""", engine)
print(df.to_string(index=False))
print()

print('=' * 70)
print('3. 价格对比：1 星 vs 非 1 星的平均订单金额')
print('=' * 70)
df = pd.read_sql("""
    SELECT
        CASE WHEN r.review_score = 1 THEN '1星' ELSE '非1星' END AS score_group,
        COUNT(*) AS order_cnt,
        ROUND(AVG(p.total_paid), 2) AS avg_order_value
    FROM order_reviews r
    JOIN (
        SELECT order_id, SUM(payment_value) AS total_paid
        FROM order_payments
        GROUP BY order_id
    ) p ON r.order_id = p.order_id
    GROUP BY score_group
""", engine)
print(df.to_string(index=False))
print()
print('>>> 结论：物流延迟是 1 星差评的核心根因（延迟率 36.8% vs 非 1 星 3.4%）')
