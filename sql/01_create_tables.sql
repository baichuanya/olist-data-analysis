-- Olist 巴西电商数据集建表脚本
-- 数据库：olist，字符集 utf8mb4

CREATE DATABASE IF NOT EXISTS olist DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE olist;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS product_category_name_translation;

-- 客户表
CREATE TABLE customers (
    customer_id            VARCHAR(40) NOT NULL,
    customer_unique_id     VARCHAR(40),
    customer_zip_code_prefix VARCHAR(10),
    customer_city          VARCHAR(60),
    customer_state         VARCHAR(2),
    PRIMARY KEY (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 卖家表
CREATE TABLE sellers (
    seller_id              VARCHAR(40) NOT NULL,
    seller_zip_code_prefix VARCHAR(10),
    seller_city            VARCHAR(60),
    seller_state           VARCHAR(2),
    PRIMARY KEY (seller_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 商品表
CREATE TABLE products (
    product_id                 VARCHAR(40) NOT NULL,
    product_category_name      VARCHAR(60),
    product_name_lenght        INT,
    product_description_lenght INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT,
    PRIMARY KEY (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 类目名称翻译表（葡语 -> 英语）
CREATE TABLE product_category_name_translation (
    product_category_name         VARCHAR(60) NOT NULL,
    product_category_name_english VARCHAR(60),
    PRIMARY KEY (product_category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 订单表
CREATE TABLE orders (
    order_id                       VARCHAR(40) NOT NULL,
    customer_id                    VARCHAR(40),
    order_status                   VARCHAR(20),
    order_purchase_timestamp       DATETIME,
    order_approved_at              DATETIME,
    order_delivered_carrier_date   DATETIME,
    order_delivered_customer_date  DATETIME,
    order_estimated_delivery_date  DATETIME,
    PRIMARY KEY (order_id),
    KEY idx_customer (customer_id),
    KEY idx_status (order_status),
    KEY idx_purchase_ts (order_purchase_timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 订单明细表（一个订单可含多个商品）
CREATE TABLE order_items (
    order_id            VARCHAR(40) NOT NULL,
    order_item_id       INT NOT NULL,
    product_id          VARCHAR(40),
    seller_id           VARCHAR(40),
    shipping_limit_date DATETIME,
    price               DECIMAL(10,2),
    freight_value       DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    KEY idx_product (product_id),
    KEY idx_seller (seller_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 支付表（一个订单可分多期/多方式支付）
CREATE TABLE order_payments (
    order_id             VARCHAR(40) NOT NULL,
    payment_sequential   INT NOT NULL,
    payment_type         VARCHAR(20),
    payment_installments INT,
    payment_value        DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 评价表
CREATE TABLE order_reviews (
    review_id              VARCHAR(40) NOT NULL,
    order_id               VARCHAR(40),
    review_score           INT,
    review_comment_title   TEXT,
    review_comment_message TEXT,
    review_creation_date   DATETIME,
    review_answer_timestamp DATETIME,
    PRIMARY KEY (review_id),
    KEY idx_order (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
