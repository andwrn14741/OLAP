-- ============================================================
-- З04. Аналитический SQL
-- Три вопроса из паспорта витрины
-- ============================================================

-- ------------------------------------------------------------
-- Вопрос 1: Какой оборот по категориям товаров за каждый месяц 2025 года?
-- Тип: GROUP BY по двум разрезам (месяц, категория)
-- ------------------------------------------------------------
SELECT
    d.month,
    p.category,
    SUM(f.total_amount) AS revenue
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_date    d ON f.sale_date  = d.date_id
GROUP BY d.month, p.category
ORDER BY d.month, p.category;

-- ------------------------------------------------------------
-- Вопрос 2: Топ-10 товаров по количеству проданных штук за год
-- Тип: сортировка + LIMIT
-- ------------------------------------------------------------
SELECT
    p.product_name,
    SUM(f.quantity) AS sold_units
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.product_name
ORDER BY sold_units DESC
LIMIT 10;

-- ------------------------------------------------------------
-- Вопрос 3: Средняя стоимость доставки по перевозчикам
--           и доля самовывоза
-- Тип: два запроса — GROUP BY + подзапросы
-- ------------------------------------------------------------
SELECT
    carrier,
    ROUND(AVG(total_amount), 2) AS avg_delivery,
    COUNT(*)                    AS shipments
FROM fact_logistics
GROUP BY carrier
ORDER BY avg_delivery DESC;

SELECT
    (SELECT COUNT(DISTINCT order_id) FROM fact_sales)     AS all_orders,
    (SELECT COUNT(DISTINCT order_id) FROM fact_logistics) AS shipped_orders,
    ROUND(100.0 * (1 - 1.0 * (SELECT COUNT(DISTINCT order_id) FROM fact_logistics)
                        / (SELECT COUNT(DISTINCT order_id) FROM fact_sales)), 2)
        AS pickup_share_pct;
-- ------------------------------------------------------------
-- Оконная функция: доля категории в общем обороте
-- SUM() OVER (PARTITION BY ...) — считает итог рядом со строками
-- ------------------------------------------------------------
SELECT
    p.category,
    SUM(f.total_amount)                              AS category_revenue,
    SUM(SUM(f.total_amount)) OVER ()                 AS total_revenue,
    ROUND(
        100.0 * SUM(f.total_amount) / SUM(SUM(f.total_amount)) OVER (),
        2
    )                                                AS share_pct
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.category
ORDER BY category_revenue DESC;

-- ------------------------------------------------------------
-- Оконная функция: рейтинг перевозчиков по средней стоимости доставки
-- RANK() OVER (ORDER BY ...) — присваивает место каждой строке
-- ------------------------------------------------------------
SELECT
    carrier,
    ROUND(AVG(total_amount), 2)                      AS avg_delivery,
    RANK() OVER (ORDER BY AVG(total_amount) DESC)    AS rank_by_avg
FROM fact_logistics
GROUP BY carrier
ORDER BY rank_by_avg;
