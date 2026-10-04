-- ============================================================
-- З05. ELT шаг 4: проверки качества
-- Любая ошибка вызывает error() и обрывает run_etl.sh (set -e).
-- ============================================================

-- 1. Пустые ключи и суммы

SELECT CASE
    WHEN (
        SELECT COUNT(*) FROM fact_sales
        WHERE order_id IS NULL OR customer_id IS NULL OR store_id IS NULL
           OR product_id IS NULL OR total_amount IS NULL OR sale_date IS NULL
    ) > 0
    THEN error('CHECK FAILED: fact_sales — пустые ключи, суммы или даты')
    ELSE 1 END;

SELECT CASE
    WHEN (
        SELECT COUNT(*) FROM fact_purchases
        WHERE purchase_id IS NULL OR supplier_id IS NULL
           OR product_id IS NULL OR total_amount IS NULL
    ) > 0
    THEN error('CHECK FAILED: fact_purchases — пустые ключи или суммы')
    ELSE 1 END;

SELECT CASE
    WHEN (
        SELECT COUNT(*) FROM fact_logistics
        WHERE shipment_id IS NULL OR order_id IS NULL
           OR carrier IS NULL OR total_amount IS NULL
    ) > 0
    THEN error('CHECK FAILED: fact_logistics — пустые ключи или суммы')
    ELSE 1 END;

SELECT CASE
    WHEN (
        SELECT COUNT(*) FROM dim_customer
        WHERE customer_name IS NULL OR region IS NULL OR customer_type IS NULL
    ) > 0
    THEN error('CHECK FAILED: dim_customer — пустые имя, тип или регион')
    ELSE 1 END;

-- 2. Странный диапазон

SELECT CASE
    WHEN (
        SELECT COUNT(*) FROM fact_sales
        WHERE quantity < 0 OR total_amount < 0 OR price_per_unit < 0
    ) > 0
    THEN error('CHECK FAILED: fact_sales — отрицательные количество или деньги')
    ELSE 1 END;

SELECT CASE
    WHEN (
        SELECT COUNT(*) FROM fact_sales
        WHERE sale_date < DATE '2024-01-01' OR sale_date > DATE '2026-12-31'
    ) > 0
    THEN error('CHECK FAILED: fact_sales — дата вне 2024–2026')
    ELSE 1 END;

SELECT CASE
    WHEN (
        SELECT COUNT(*) FROM fact_sales
        WHERE total_amount <> quantity * price_per_unit
    ) > 0
    THEN error('CHECK FAILED: fact_sales — total_amount не равен quantity * price_per_unit')
    ELSE 1 END;

-- 3. Дубли. Одна строка факта = одна позиция заказа (order_id, product_id).

SELECT CASE
    WHEN (
        SELECT COUNT(*) FROM (
            SELECT order_id, product_id
            FROM fact_sales
            GROUP BY order_id, product_id
            HAVING COUNT(*) > 1
        )
    ) > 0
    THEN error('CHECK FAILED: fact_sales — дубли по (order_id, product_id)')
    ELSE 1 END;

-- 4. Сироты

SELECT CASE
    WHEN (
        SELECT COUNT(*) FROM fact_sales f
        WHERE (
            SELECT COUNT(*)
            FROM dim_product p
            WHERE p.product_id = f.product_id
              AND f.sale_date >= p.valid_from
              AND (p.valid_to IS NULL OR f.sale_date < p.valid_to)
        ) <> 1
    ) > 0
    THEN error('CHECK FAILED: fact_sales — на дату продажи нет ровно одной версии товара')
    ELSE 1 END;

SELECT CASE
    WHEN (
        SELECT COUNT(*) FROM (
            SELECT product_id
            FROM dim_product
            GROUP BY product_id
            HAVING SUM(CASE WHEN is_current THEN 1 ELSE 0 END) <> 1
        )
    ) > 0
    THEN error('CHECK FAILED: dim_product — у товара не ровно одна текущая версия')
    ELSE 1 END;

SELECT CASE
    WHEN (
        SELECT COUNT(*)
        FROM fact_sales f
        LEFT JOIN dim_store s ON f.store_id = s.store_id
        WHERE s.store_id IS NULL
    ) > 0
    THEN error('CHECK FAILED: fact_sales — store_id нет в dim_store')
    ELSE 1 END;

SELECT CASE
    WHEN (
        SELECT COUNT(*)
        FROM fact_sales f
        LEFT JOIN dim_customer c ON f.customer_id = c.customer_id
        WHERE c.customer_id IS NULL
    ) > 0
    THEN error('CHECK FAILED: fact_sales — customer_id нет в dim_customer')
    ELSE 1 END;

SELECT CASE
    WHEN (
        SELECT COUNT(*)
        FROM fact_sales f
        LEFT JOIN dim_date d ON f.sale_date = d.date_id
        WHERE d.date_id IS NULL
    ) > 0
    THEN error('CHECK FAILED: fact_sales — sale_date нет в dim_date')
    ELSE 1 END;

SELECT CASE
    WHEN (
        SELECT COUNT(*)
        FROM fact_purchases f
        LEFT JOIN dim_supplier s ON f.supplier_id = s.supplier_id
        WHERE s.supplier_id IS NULL
    ) > 0
    THEN error('CHECK FAILED: fact_purchases — supplier_id нет в dim_supplier')
    ELSE 1 END;

SELECT CASE
    WHEN (
        SELECT COUNT(*)
        FROM fact_logistics l
        LEFT JOIN dim_carrier c ON l.carrier = c.carrier
        WHERE c.carrier IS NULL
    ) > 0
    THEN error('CHECK FAILED: fact_logistics — carrier нет в dim_carrier')
    ELSE 1 END;

SELECT CASE
    WHEN (
        SELECT COUNT(*)
        FROM fact_logistics l
        LEFT JOIN fact_sales s ON l.order_id = s.order_id
        WHERE s.order_id IS NULL
    ) > 0
    THEN error('CHECK FAILED: fact_logistics — order_id нет в fact_sales')
    ELSE 1 END;

-- 5. Число строк совпадает с сырьём, а не с зашитой константой

SELECT CASE
    WHEN (SELECT COUNT(*) FROM fact_sales)
       <> (SELECT COUNT(*) FROM read_csv_auto('data/raw/sales.csv', header = true))
    THEN error('CHECK FAILED: fact_sales — число строк не совпало с sales.csv')
    ELSE 1 END;

SELECT CASE
    WHEN (SELECT COUNT(*) FROM fact_purchases)
       <> (SELECT COUNT(*) FROM read_csv_auto('data/raw/purchases.csv', header = true))
    THEN error('CHECK FAILED: fact_purchases — число строк не совпало с purchases.csv')
    ELSE 1 END;

SELECT CASE
    WHEN (SELECT COUNT(*) FROM fact_logistics)
       <> (SELECT COUNT(*) FROM read_csv_auto('data/raw/logistics.csv', header = true))
    THEN error('CHECK FAILED: fact_logistics — число строк не совпало с logistics.csv')
    ELSE 1 END;

SELECT CASE
    WHEN (SELECT COUNT(*) FROM dim_store) <> 41
    THEN error('CHECK FAILED: dim_store — ожидался 41 магазин сети')
    ELSE 1 END;

SELECT 'ALL CHECKS PASSED' AS status;
