# -*- coding: utf-8 -*-
"""Olist 分析可视化：出 4 张关键图，保存到 charts/"""
import os
import pandas as pd
import matplotlib
matplotlib.use('Agg')
matplotlib.rcParams['font.sans-serif'] = ['SimHei', 'Microsoft YaHei']
matplotlib.rcParams['axes.unicode_minus'] = False
import matplotlib.pyplot as plt
from sqlalchemy import create_engine

engine = create_engine('mysql+pymysql://root:123456@localhost:3306/olist?charset=utf8mb4')
out_dir = r'C:\Users\MAC\Desktop\olist_analysis\charts'
os.makedirs(out_dir, exist_ok=True)

# ---------- 1. 月度 GMV 趋势 ----------
df = pd.read_sql("""
    SELECT o.order_purchase_timestamp AS ts, p.total_paid
    FROM orders o
    JOIN (SELECT order_id, SUM(payment_value) AS total_paid
          FROM order_payments GROUP BY order_id) p
      ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
""", engine)
df['ym'] = df['ts'].dt.to_period('M').astype(str)
gmv = df.groupby('ym')['total_paid'].sum()
plt.figure(figsize=(10, 4))
plt.plot(gmv.index, gmv.values, marker='o', color='#2b6cb0')
plt.title('月度 GMV 趋势')
plt.ylabel('GMV (BRL)')
plt.xticks(rotation=45)
plt.grid(alpha=0.3)
plt.tight_layout()
plt.savefig(os.path.join(out_dir, '1_monthly_gmv.png'), dpi=110)
plt.close()

# ---------- 2. 评分分布 ----------
df = pd.read_sql("SELECT review_score, COUNT(*) AS cnt FROM order_reviews GROUP BY review_score", engine)
plt.figure(figsize=(6, 4))
bars = plt.bar(df['review_score'], df['cnt'], color=['#c53030', '#dd6b20', '#d69e2e', '#38a169', '#2f855a'])
plt.title('评价评分分布')
plt.xlabel('评分')
plt.ylabel('评价数')
for b, v in zip(bars, df['cnt']):
    plt.text(b.get_x() + b.get_width()/2, v, f'{v/1000:.0f}k', ha='center', va='bottom', fontsize=8)
plt.tight_layout()
plt.savefig(os.path.join(out_dir, '2_review_score.png'), dpi=110)
plt.close()

# ---------- 3. 品类销售 TOP 10 ----------
df = pd.read_sql("""
    SELECT COALESCE(t.product_category_name_english, p.product_category_name, '未分类') AS category,
           SUM(oi.price) AS revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY category
    ORDER BY revenue DESC
    LIMIT 10
""", engine)
df = df.iloc[::-1]
plt.figure(figsize=(8, 5))
plt.barh(df['category'], df['revenue'], color='#3182ce')
plt.title('销售额 TOP 10 品类')
plt.xlabel('销售额 (BRL)')
plt.tight_layout()
plt.savefig(os.path.join(out_dir, '3_top_categories.png'), dpi=110)
plt.close()

# ---------- 4. 购买频次分布 ----------
df = pd.read_sql("""
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS frequency
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
""", engine)
freq = pd.cut(df['frequency'], bins=[0, 1, 2, 5, 100], labels=['1 次', '2 次', '3-5 次', '6 次及以上']).value_counts().sort_index()
plt.figure(figsize=(7, 4))
bars = plt.bar(freq.index, freq.values, color='#2c5282')
plt.title('客户购买频次分布')
plt.ylabel('客户数')
for b, v in zip(bars, freq.values):
    plt.text(b.get_x() + b.get_width()/2, v, f'{v/1000:.0f}k', ha='center', va='bottom', fontsize=9)
plt.tight_layout()
plt.savefig(os.path.join(out_dir, '4_frequency.png'), dpi=110)
plt.close()

# ---------- 5. 1星 vs 非1星 物流延迟率对比 ----------
df = pd.read_sql("""
    SELECT CASE WHEN r.review_score = 1 THEN '1星' ELSE '非1星' END AS grp,
           SUM(DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0) * 100.0 / COUNT(*) AS late_rate
    FROM order_reviews r
    JOIN orders o ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY grp
""", engine)
df = df.set_index('grp')
plt.figure(figsize=(5, 4))
bars = plt.bar(df.index, df['late_rate'], color=['#2f855a', '#c53030'])
plt.title('物流延迟率：1星 vs 非1星')
plt.ylabel('延迟率 (%)')
for b, v in zip(bars, df['late_rate']):
    plt.text(b.get_x() + b.get_width()/2, v, f'{v:.1f}%', ha='center', va='bottom', fontsize=11)
plt.tight_layout()
plt.savefig(os.path.join(out_dir, '5_late_rate.png'), dpi=110)
plt.close()

print('5 张图已保存到', out_dir)
for f in sorted(os.listdir(out_dir)):
    print('  -', f)
