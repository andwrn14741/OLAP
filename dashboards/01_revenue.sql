-- Карточка «Валовой оборот».
-- {{period}} — фильтр дашборда по fact_sales.sale_date.
-- При периоде 2025-01-01 .. 2025-12-31 число совпадает с sql/canonical_metric.sql.
SELECT SUM(total_amount) AS revenue
FROM fact_sales
WHERE {{period}};
