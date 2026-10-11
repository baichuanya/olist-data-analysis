# Olist 电商数据分析

基于巴西 Olist 电商平台真实订单数据（约 9.9 万订单，2016–2018）的完整数据分析项目，覆盖数据建模、指标体系、用户分层与差评归因。

## 项目结构

```
olist_analysis/
├── sql/       # 建表、数据质量、核心指标、RFM 分层、留存、差评归因等 SQL 脚本
├── scripts/   # Python 数据导入、分析与可视化脚本
└── charts/    # 分析结果图表（GMV 趋势、评分分布、品类 TOP、购买频次、物流延迟率）
```

## 核心结论

- 核心指标：GMV 1542 万、客单价约 160、复购率 3%
- 用户分层：27% 高价值客户贡献 54% GMV，97% 客户仅购买一次
- 差评归因：1 星差评核心根因为物流延迟（延迟率 36.8% vs 非 1 星 3.4%）

## 环境

- MySQL 8.0
- Python 3.8（pandas、matplotlib、sqlalchemy、pymysql）

## 运行步骤

1. 下载数据集 CSV（见下方数据来源），按 `sql/01_create_tables.sql` 建表。
2. 运行 `scripts/load_data.py` 将 CSV 导入 MySQL。
3. 依次执行 `sql/` 目录下的分析脚本（`02`~`06`）。
4. 运行 `scripts/visualize.py` 生成图表到 `charts/`。

## 数据来源

数据集为 [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)，原始 CSV 可从 [ruan-narici/brazilian-ecommerce-analytics](https://github.com/ruan-narici/brazilian-ecommerce-analytics) 获取。
