-- ============================================================
-- З04. Аналитический SQL
-- Три вопроса из паспорта витрины сети «АвтоДеталь»
-- ============================================================

-- ------------------------------------------------------------
-- Вопрос 1: Какой оборот по регионам сети за каждый месяц 2025 года?
-- Тип: GROUP BY (месяц, регион магазина)
-- ------------------------------------------------------------
SELECT
    d.month,
    s.region,
    SUM(f.total_amount) AS revenue
FROM fact_sales f
JOIN dim_store s ON f.store_id = s.store_id
JOIN dim_date  d ON f.sale_date = d.date_id
WHERE d.year = 2025
GROUP BY d.month, s.region
ORDER BY d.month, s.region;

-- ------------------------------------------------------------
-- Вопрос 2: Топ-10 товаров по количеству проданных штук за год
-- Тип: сортировка + LIMIT
-- ------------------------------------------------------------
SELECT
    p.product_name,
    p.brand,
    SUM(f.quantity) AS sold_units
FROM fact_sales f
JOIN dim_product p
  ON f.product_id = p.product_id
 AND p.is_current
GROUP BY p.product_name, p.brand
ORDER BY sold_units DESC
LIMIT 10;

-- ------------------------------------------------------------
-- Вопрос 3: Средняя стоимость доставки по перевозчикам
--           и доля самовывоза
-- Самовывоз — заказ, которого нет в fact_logistics
-- ------------------------------------------------------------
SELECT
    c.carrier,
    c.delivery_type,
    ROUND(AVG(l.total_amount), 2) AS avg_delivery,
    COUNT(*)                      AS shipments
FROM fact_logistics l
JOIN dim_carrier c ON l.carrier = c.carrier
GROUP BY c.carrier, c.delivery_type
ORDER BY avg_delivery DESC;

SELECT
    (SELECT COUNT(*) FROM fact_sales)     AS all_orders,
    (SELECT COUNT(*) FROM fact_logistics) AS shipped_orders,
    ROUND(
        100.0 * (
            (SELECT COUNT(*) FROM fact_sales) - (SELECT COUNT(*) FROM fact_logistics)
        ) / (SELECT COUNT(*) FROM fact_sales),
        2
    ) AS pickup_share_pct;

-- ------------------------------------------------------------
-- Оконная функция: доля категории в обороте сети
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
JOIN dim_product p
  ON f.product_id = p.product_id
 AND f.sale_date >= p.valid_from
 AND (p.valid_to IS NULL OR f.sale_date < p.valid_to)
GROUP BY p.category
ORDER BY category_revenue DESC;

-- ------------------------------------------------------------
-- Оконная функция: место магазина в рейтинге сети по обороту
-- ------------------------------------------------------------
SELECT
    s.store_name,
    s.region,
    SUM(f.total_amount)                           AS revenue,
    RANK() OVER (ORDER BY SUM(f.total_amount) DESC) AS rank_in_network
FROM fact_sales f
JOIN dim_store s ON f.store_id = s.store_id
GROUP BY s.store_name, s.region
ORDER BY rank_in_network;
