-- Вопрос 1. Оборот по регионам сети и месяцам.
SELECT
    d.month AS month,
    s.region AS region,
    SUM(f.total_amount) AS revenue
FROM fact_sales AS f
INNER JOIN dim_store AS s ON f.store_id = s.store_id
INNER JOIN dim_date AS d ON f.sale_date = d.date_id
WHERE {{period}}
GROUP BY d.month, s.region
ORDER BY d.month, s.region;
