# -*- coding: utf-8 -*-
"""将 Olist 8 张 CSV 导入 MySQL olist 库"""
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine('mysql+pymysql://root:123456@localhost:3306/olist?charset=utf8mb4')

data_dir = r'C:\Users\MAC\Desktop\olist_analysis\brazilian-ecommerce-analytics\src\data'

tables = {
    'customers': 'olist_customers_dataset.csv',
    'sellers': 'olist_sellers_dataset.csv',
    'products': 'olist_products_dataset.csv',
    'product_category_name_translation': 'product_category_name_translation.csv',
    'orders': 'olist_orders_dataset.csv',
    'order_items': 'olist_order_items_dataset.csv',
    'order_payments': 'olist_order_payments_dataset.csv',
    'order_reviews': 'olist_order_reviews_dataset.csv',
}

date_cols = {
    'orders': ['order_purchase_timestamp', 'order_approved_at',
               'order_delivered_carrier_date', 'order_delivered_customer_date',
               'order_estimated_delivery_date'],
    'order_items': ['shipping_limit_date'],
    'order_reviews': ['review_creation_date', 'review_answer_timestamp'],
}

for table, fname in tables.items():
    df = pd.read_csv(f'{data_dir}\\{fname}', encoding='utf-8-sig')
    if table == 'order_reviews':
        df = df.drop_duplicates(subset='review_id', keep='first')
    if table in date_cols:
        for c in date_cols[table]:
            df[c] = pd.to_datetime(df[c], errors='coerce')
    df.to_sql(table, engine, if_exists='append', index=False, chunksize=10000)
    print(f'{table:35s} {len(df):>8d} 行导入完成')

print('全部导入完成')
