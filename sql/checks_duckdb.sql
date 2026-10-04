-- ============================================================
-- З03. Проверки после загрузки
-- ============================================================

SELECT 'fact_sales' AS table_name, COUNT(*) AS rows FROM fact_sales
UNION ALL SELECT 'fact_purchases', COUNT(*) FROM fact_purchases
UNION ALL SELECT 'fact_logistics', COUNT(*) FROM fact_logistics
UNION ALL SELECT 'dim_product',    COUNT(*) FROM dim_product
UNION ALL SELECT 'dim_customer',   COUNT(*) FROM dim_customer
UNION ALL SELECT 'dim_supplier',   COUNT(*) FROM dim_supplier
UNION ALL SELECT 'dim_carrier',    COUNT(*) FROM dim_carrier
UNION ALL SELECT 'dim_store',      COUNT(*) FROM dim_store
UNION ALL SELECT 'dim_date',       COUNT(*) FROM dim_date
ORDER BY table_name;

SELECT
    SUM(CASE WHEN order_id IS NULL OR store_id IS NULL OR product_id IS NULL
              OR customer_id IS NULL OR total_amount IS NULL THEN 1 ELSE 0 END) AS bad_sales_keys,
    SUM(CASE WHEN quantity < 0 OR total_amount < 0 THEN 1 ELSE 0 END) AS bad_sales_range,
    SUM(CASE WHEN total_amount <> quantity * price_per_unit THEN 1 ELSE 0 END) AS bad_sales_amount
FROM fact_sales;

SELECT SUM(total_amount) AS revenue, COUNT(*) AS rows FROM fact_sales;

SELECT MIN(sale_date) AS min_date, MAX(sale_date) AS max_date FROM fact_sales;

SELECT COUNT(*) AS sales_without_store
FROM fact_sales f
LEFT JOIN dim_store s ON f.store_id = s.store_id
WHERE s.store_id IS NULL;

SELECT COUNT(*) AS empty_customer_names
FROM dim_customer
WHERE customer_name IS NULL OR region IS NULL;
