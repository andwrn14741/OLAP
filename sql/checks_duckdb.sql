-- ============================================================
-- З03. Проверки после загрузки
-- ============================================================

-- 1. Число строк в каждой таблице
SELECT 'fact_sales'     AS table_name, COUNT(*) AS rows FROM fact_sales
UNION ALL SELECT 'fact_purchases',  COUNT(*) FROM fact_purchases
UNION ALL SELECT 'fact_logistics',  COUNT(*) FROM fact_logistics
UNION ALL SELECT 'dim_product',     COUNT(*) FROM dim_product
UNION ALL SELECT 'dim_customer',    COUNT(*) FROM dim_customer
UNION ALL SELECT 'dim_supplier',    COUNT(*) FROM dim_supplier
UNION ALL SELECT 'dim_carrier',     COUNT(*) FROM dim_carrier
UNION ALL SELECT 'dim_date',        COUNT(*) FROM dim_date
ORDER BY table_name;

-- 2. Пустые ключи в фактах
SELECT 'fact_sales.order_id NULL'      AS check_name, COUNT(*) AS bad FROM fact_sales WHERE order_id IS NULL
UNION ALL SELECT 'fact_sales.product_id NULL',    COUNT(*) FROM fact_sales WHERE product_id IS NULL
UNION ALL SELECT 'fact_logistics.order_id NULL',  COUNT(*) FROM fact_logistics WHERE order_id IS NULL;

-- 3. Главная метрика — оборот
SELECT SUM(total_amount) AS revenue, COUNT(*) AS rows FROM fact_sales;

-- 4. Диапазон дат
SELECT MIN(sale_date) AS min_date, MAX(sale_date) AS max_date FROM fact_sales;
