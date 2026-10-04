-- ============================================================
-- З08. Те же аналитические вопросы в ClickHouse
-- База autoparts. Синтаксис совпадает с sql/analytics.sql,
-- префикс базы нужен, чтобы запрос не попал в default.
-- ============================================================

-- Эталон главной метрики. Условие то же, что в sql/canonical_metric.sql.
-- Ожидается 788793643.00
SELECT SUM(total_amount) AS revenue
FROM autoparts.fact_sales
WHERE sale_date >= '2025-01-01'
  AND sale_date <= '2025-12-31';

-- Вопрос 1. Оборот по регионам сети за каждый месяц 2025
SELECT
    d.month,
    s.region,
    SUM(f.total_amount) AS revenue
FROM autoparts.fact_sales AS f
INNER JOIN autoparts.dim_store AS s ON f.store_id = s.store_id
INNER JOIN autoparts.dim_date AS d ON f.sale_date = d.date_id
WHERE d.year = 2025
GROUP BY d.month, s.region
ORDER BY d.month, s.region;

-- Вопрос 2. Топ-10 товаров по штукам. is_current, чтобы SCD2 не удвоил строки
SELECT
    p.product_name,
    p.brand,
    SUM(f.quantity) AS sold_units
FROM autoparts.fact_sales AS f
INNER JOIN autoparts.dim_product AS p
    ON f.product_id = p.product_id AND p.is_current
GROUP BY p.product_name, p.brand
ORDER BY sold_units DESC
LIMIT 10;

-- Вопрос 3. Средняя доставка и доля самовывоза
SELECT
    c.carrier,
    c.delivery_type,
    round(avg(l.total_amount), 2) AS avg_delivery,
    count() AS shipments
FROM autoparts.fact_logistics AS l
INNER JOIN autoparts.dim_carrier AS c ON l.carrier = c.carrier
GROUP BY c.carrier, c.delivery_type
ORDER BY avg_delivery DESC;

SELECT
    (SELECT count() FROM autoparts.fact_sales) AS all_orders,
    (SELECT count() FROM autoparts.fact_logistics) AS shipped_orders,
    round(
        100.0 * (
            (SELECT count() FROM autoparts.fact_sales)
            - (SELECT count() FROM autoparts.fact_logistics)
        ) / (SELECT count() FROM autoparts.fact_sales),
        2
    ) AS pickup_share_pct;

-- Окно: доля категории с версией товара на дату продажи.
-- Условие SCD2 стоит в WHERE, а sale_date остаётся в подзапросе:
-- иначе ClickHouse выкидывает колонку из JOIN ON и запрос падает.
SELECT
    category,
    sum(total_amount) AS category_revenue,
    sum(sum(total_amount)) OVER () AS total_revenue,
    round(100.0 * sum(total_amount) / sum(sum(total_amount)) OVER (), 2) AS share_pct
FROM
(
    SELECT
        p.category AS category,
        f.total_amount AS total_amount,
        f.sale_date AS sale_date
    FROM autoparts.fact_sales AS f
    INNER JOIN autoparts.dim_product AS p ON f.product_id = p.product_id
    WHERE f.sale_date >= p.valid_from
      AND (isNull(p.valid_to) OR f.sale_date < p.valid_to)
) AS matched
GROUP BY category
ORDER BY category_revenue DESC;

-- Окно: место магазина в сети
SELECT
    s.store_name,
    s.region,
    SUM(f.total_amount) AS revenue,
    rank() OVER (ORDER BY SUM(f.total_amount) DESC) AS rank_in_network
FROM autoparts.fact_sales AS f
INNER JOIN autoparts.dim_store AS s ON f.store_id = s.store_id
GROUP BY s.store_name, s.region
ORDER BY rank_in_network;

-- Партиции fact_sales: один месяц = один кусок
SELECT
    partition,
    sum(rows) AS rows
FROM system.parts
WHERE database = 'autoparts' AND table = 'fact_sales' AND active
GROUP BY partition
ORDER BY partition;
