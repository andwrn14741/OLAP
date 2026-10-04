-- Вопрос 3. Средняя стоимость доставки по перевозчикам.
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
