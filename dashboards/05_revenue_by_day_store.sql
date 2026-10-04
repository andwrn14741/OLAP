-- График оборота сети по дням.
-- Считается из сводки З09: одна строка сводки = день × магазин,
-- здесь магазины свёрнуты в один день, чтобы график не упирался в лимит строк.
SELECT
    sale_date,
    SUM(revenue) AS revenue
FROM mart_revenue_day_store
WHERE {{period}}
GROUP BY sale_date
ORDER BY sale_date;
