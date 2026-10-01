-- ============================================================
-- З05. ELT шаг 4: проверки качества
-- Любая ошибка → ETL останавливается с ненулевым кодом
-- ============================================================

-- ---------- 1. Пустые ключи и суммы ----------

SELECT CASE
    WHEN (SELECT COUNT(*) FROM fact_sales
          WHERE order_id IS NULL OR product_id IS NULL
             OR total_amount IS NULL OR sale_date IS NULL) > 0
    THEN error('CHECK FAILED: fact_sales — пустые ключи/суммы/даты')
    ELSE 1 END;

SELECT CASE
    WHEN (SELECT COUNT(*) FROM fact_logistics
          WHERE order_id IS NULL OR total_amount IS NULL) > 0
    THEN error('CHECK FAILED: fact_logistics — пустые ключи/суммы')
    ELSE 1 END;

-- ---------- 2. Странный диапазон ----------

SELECT CASE
    WHEN (SELECT COUNT(*) FROM fact_sales
          WHERE quantity < 0 OR total_amount < 0) > 0
    THEN error('CHECK FAILED: fact_sales — отрицательные quantity или total_amount')
    ELSE 1 END;

SELECT CASE
    WHEN (SELECT COUNT(*) FROM fact_sales
          WHERE sale_date < DATE '2000-01-01'
             OR sale_date > DATE '2100-01-01') > 0
    THEN error('CHECK FAILED: fact_sales — даты вне диапазона 2000–2100')
    ELSE 1 END;

-- ---------- 3. Дубли ----------
-- Одна позиция заказа (order_id + product_id) не должна встречаться дважды

SELECT CASE
    WHEN (
        SELECT COUNT(*) FROM (
            SELECT order_id, product_id
            FROM fact_sales
            GROUP BY order_id, product_id
            HAVING COUNT(*) > 1
        ) t
    ) > 0
    THEN error('CHECK FAILED: fact_sales — дубли по (order_id, product_id)')
    ELSE 1 END;

-- ---------- 4. «Сироты» ----------
-- В факте есть ключ, которого нет в справочнике

SELECT CASE
    WHEN (
        SELECT COUNT(*)
        FROM fact_sales f
        LEFT JOIN dim_product p ON f.product_id = p.product_id
        WHERE p.product_id IS NULL
    ) > 0
    THEN error('CHECK FAILED: fact_sales — product_id без записи в dim_product')
    ELSE 1 END;

SELECT CASE
    WHEN (
        SELECT COUNT(*)
        FROM fact_logistics l
        LEFT JOIN dim_carrier c ON l.carrier = c.carrier
        WHERE c.carrier IS NULL
    ) > 0
    THEN error('CHECK FAILED: fact_logistics — carrier без записи в dim_carrier')
    ELSE 1 END;

-- ---------- 5. Число строк соответствует сырью ----------

SELECT CASE
    WHEN (SELECT COUNT(*) FROM fact_sales) <> 20000
    THEN error('CHECK FAILED: fact_sales — ожидалось 20000 строк')
    ELSE 1 END;

SELECT CASE
    WHEN (SELECT COUNT(*) FROM fact_purchases) <> 2000
    THEN error('CHECK FAILED: fact_purchases — ожидалось 2000 строк')
    ELSE 1 END;

SELECT CASE
    WHEN (SELECT COUNT(*) FROM fact_logistics) NOT BETWEEN 17000 AND 19000
    THEN error('CHECK FAILED: fact_logistics — ожидалось ~18000 строк')
    ELSE 1 END;

-- ---------- Итог ----------
SELECT 'ALL CHECKS PASSED' AS status;
