-- Вопрос 2. Топ-10 товаров по штукам.
-- is_current: имя не менялось, история категории здесь не нужна.
SELECT
    p.product_name AS product_name,
    p.brand AS brand,
    SUM(f.quantity) AS sold_units
FROM fact_sales AS f
INNER JOIN dim_product AS p
    ON f.product_id = p.product_id AND p.is_current
WHERE {{period}}
GROUP BY p.product_name, p.brand
ORDER BY sold_units DESC
LIMIT 10;
