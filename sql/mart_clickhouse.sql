-- ============================================================
-- З09. Сводка под график «оборот по дням и магазинам»
-- Одна строка сводки = один день × один магазин.
-- Мера revenue — та же, что SUM(fact_sales.total_amount).
-- После повторной загрузки факта сводку пересобирают:
--   bash etl/rebuild_mart.sh
-- ============================================================

CREATE TABLE IF NOT EXISTS autoparts.mart_revenue_day_store
(
    sale_date Date,
    store_id UInt32,
    store_name String,
    region String,
    revenue Decimal(18, 2),
    quantity Int64
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(sale_date)
ORDER BY (sale_date, store_id);

TRUNCATE TABLE autoparts.mart_revenue_day_store;

INSERT INTO autoparts.mart_revenue_day_store
SELECT
    f.sale_date,
    s.store_id,
    s.store_name,
    s.region,
    sum(f.total_amount) AS revenue,
    toInt64(sum(f.quantity)) AS quantity
FROM autoparts.fact_sales AS f
INNER JOIN autoparts.dim_store AS s ON f.store_id = s.store_id
GROUP BY f.sale_date, s.store_id, s.store_name, s.region;

-- Сверка: сумма сводки равна эталону по детальным строкам
SELECT
    (SELECT sum(revenue) FROM autoparts.mart_revenue_day_store) AS mart_revenue,
    (SELECT sum(total_amount) FROM autoparts.fact_sales) AS fact_revenue,
    (SELECT sum(revenue) FROM autoparts.mart_revenue_day_store)
        = (SELECT sum(total_amount) FROM autoparts.fact_sales) AS sums_match;
