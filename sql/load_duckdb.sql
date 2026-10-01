-- ============================================================
-- З03. Загрузка сырья из data/raw/ в таблицы DuckDB
-- Запуск: duckdb data/olap.duckdb < sql/load_duckdb.sql
-- ============================================================

-- Идемпотентность: очищаем таблицы перед загрузкой,
-- чтобы повторный запуск не удваивал строки
TRUNCATE fact_sales;
TRUNCATE fact_purchases;
TRUNCATE fact_logistics;
TRUNCATE dim_product;
TRUNCATE dim_customer;
TRUNCATE dim_supplier;
TRUNCATE dim_carrier;
TRUNCATE dim_date;

-- Факты
COPY fact_sales      FROM 'data/raw/sales.csv'      (HEADER, DELIMITER ',');
COPY fact_purchases  FROM 'data/raw/purchases.csv'  (HEADER, DELIMITER ',');
COPY fact_logistics  FROM 'data/raw/logistics.csv'  (HEADER, DELIMITER ',');

-- dim_product — из fact_sales + назначенные категории
INSERT INTO dim_product (product_id, product_name, category)
SELECT
    product_id,
    MIN(product_name) AS product_name,
    CASE
        WHEN MIN(product_name) LIKE 'Тормозные колодки%'    THEN 'Тормозная система'
        WHEN MIN(product_name) = 'Тормозная жидкость DOT-4' THEN 'Тормозная система'
        WHEN MIN(product_name) IN ('Масляный фильтр', 'Воздушный фильтр') THEN 'Фильтры'
        WHEN MIN(product_name) IN ('Свечи зажигания', 'Генератор', 'Стартер') THEN 'Зажигание'
        WHEN MIN(product_name) LIKE 'Амортизатор%'           THEN 'Подвеска'
        WHEN MIN(product_name) IN ('Ремень ГРМ', 'Помпа водяная', 'Радиатор охлаждения') THEN 'Двигатель'
        WHEN MIN(product_name) LIKE 'Аккумулятор%'           THEN 'Электрика'
        WHEN MIN(product_name) IN ('Лампы H4', 'Лампы H7')   THEN 'Электрика'
        WHEN MIN(product_name) IN ('Моторное масло 5W-40', 'Антифриз G12') THEN 'Жидкости'
        WHEN MIN(product_name) = 'Щётки стеклоочистителя'    THEN 'Аксессуары'
        ELSE 'Прочее'
    END AS category
FROM fact_sales
GROUP BY product_id;

-- dim_customer — из fact_sales
INSERT INTO dim_customer (customer_id, customer_name, region)
SELECT DISTINCT customer_id, NULL, NULL
FROM fact_sales;

-- dim_supplier — из fact_purchases
INSERT INTO dim_supplier (supplier_id, supplier_name, country)
SELECT DISTINCT supplier_id, NULL, NULL
FROM fact_purchases;

-- dim_carrier — из fact_logistics
INSERT INTO dim_carrier (carrier, delivery_type)
SELECT DISTINCT carrier, NULL
FROM fact_logistics;

-- dim_date — все даты из трёх фактов
INSERT INTO dim_date (date_id, year, month, day, weekday, quarter)
SELECT DISTINCT
    d::DATE                                AS date_id,
    EXTRACT(YEAR    FROM d)::INTEGER       AS year,
    EXTRACT(MONTH   FROM d)::INTEGER       AS month,
    EXTRACT(DAY     FROM d)::INTEGER       AS day,
    EXTRACT(ISODOW  FROM d)::INTEGER       AS weekday,
    EXTRACT(QUARTER FROM d)::INTEGER       AS quarter
FROM (
    SELECT sale_date     AS d FROM fact_sales
    UNION
    SELECT purchase_date AS d FROM fact_purchases
    UNION
    SELECT shipment_date AS d FROM fact_logistics
) t;
