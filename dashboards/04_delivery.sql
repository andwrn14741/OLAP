-- Вопрос 3. Средняя стоимость доставки по перевозчикам.
-- Фильтр «Период» режет shipment_date, не дату заказа.
-- Отгрузки 1–4 января 2026 к заказам конца декабря в период 2025 года не входят,
-- поэтому среднее здесь чуть ниже, чем в sql/analytics.sql без фильтра дат.
SELECT
    c.carrier AS carrier,
    c.delivery_type AS delivery_type,
    round(avg(l.total_amount), 2) AS avg_delivery,
    count() AS shipments
FROM fact_logistics AS l
INNER JOIN dim_carrier AS c ON l.carrier = c.carrier
WHERE {{period}}
GROUP BY c.carrier, c.delivery_type
ORDER BY avg_delivery DESC;
