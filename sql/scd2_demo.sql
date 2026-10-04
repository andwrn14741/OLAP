-- ============================================================
-- З06. История категории в dim_product (SCD2)
-- С 2025-07-01 у четырёх товаров сменилась категория.
-- Старая строка остаётся, новая помечается is_current.
-- Факт попадает в версию так:
--   sale_date >= valid_from
--   AND (valid_to IS NULL OR sale_date < valid_to)
-- ============================================================

-- Две версии одной сущности
SELECT
    product_id,
    product_name,
    category,
    valid_from,
    valid_to,
    is_current
FROM dim_product
WHERE product_id IN (1040, 1044, 1045, 1056)
ORDER BY product_id, valid_from;

-- Щётки: до 1 июля «Аксессуары», с 1 июля «Кузов и оптика»
SELECT
    CASE
        WHEN f.sale_date < DATE '2025-07-01' THEN 'до 1 июля'
        ELSE 'с 1 июля'
    END AS period,
    p.category,
    SUM(f.total_amount) AS revenue,
    SUM(f.quantity)     AS units
FROM fact_sales f
JOIN dim_product p
  ON f.product_id = p.product_id
 AND f.sale_date >= p.valid_from
 AND (p.valid_to IS NULL OR f.sale_date < p.valid_to)
WHERE f.product_id = 1056
GROUP BY 1, 2
ORDER BY 1;

-- Чем SCD1 испортил бы отчёт: вся история получила бы текущую категорию
SELECT
    CASE
        WHEN f.sale_date < DATE '2025-07-01' THEN 'до 1 июля'
        ELSE 'с 1 июля'
    END AS period,
    p.category AS category_if_scd1,
    SUM(f.total_amount) AS revenue
FROM fact_sales f
JOIN dim_product p
  ON f.product_id = p.product_id
 AND p.is_current
WHERE f.product_id = 1056
GROUP BY 1, 2
ORDER BY 1;
