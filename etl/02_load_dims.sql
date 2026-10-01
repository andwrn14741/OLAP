-- ============================================================
-- З05. ELT шаг 2: загрузка справочников
-- Справочники грузятся ДО фактов — иначе в факте будут «сироты»
-- ============================================================

-- Очистка: повторный запуск ETL не должен удваивать строки
TRUNCATE dim_product;
TRUNCATE dim_customer;
TRUNCATE dim_supplier;
TRUNCATE dim_carrier;
TRUNCATE dim_date;

-- ---------- dim_product ----------
-- Источник: sales.csv. Для каждого product_id берём одно имя (MIN),
-- категорию назначаем через CASE по названию товара.
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
FROM read_csv_auto('data/raw/sales.csv', header=true)
GROUP BY product_id;

-- ---------- dim_customer ----------
-- Источник: sales.csv, уникальные customer_id
INSERT INTO dim_customer (customer_id, customer_name, region)
SELECT DISTINCT customer_id, NULL, NULL
FROM read_csv_auto('data/raw/sales.csv', header=true);

-- ---------- dim_supplier ----------
-- Источник: purchases.csv
INSERT INTO dim_supplier (supplier_id, supplier_name, country)
SELECT DISTINCT supplier_id, NULL, NULL
FROM read_csv_auto('data/raw/purchases.csv', header=true);

-- ---------- dim_carrier ----------
-- Источник: logistics.csv
INSERT INTO dim_carrier (carrier, delivery_type)
SELECT DISTINCT carrier, NULL
FROM read_csv_auto('data/raw/logistics.csv', header=true);

-- ---------- dim_date ----------
-- Все даты из трёх файлов, разложенные на год/месяц/день/день недели/квартал
INSERT INTO dim_date (date_id, year, month, day, weekday, quarter)
SELECT DISTINCT
    d::DATE                                AS date_id,
    EXTRACT(YEAR    FROM d)::INTEGER       AS year,
    EXTRACT(MONTH   FROM d)::INTEGER       AS month,
    EXTRACT(DAY     FROM d)::INTEGER       AS day,
    EXTRACT(ISODOW  FROM d)::INTEGER       AS weekday,   -- 1 = Пн, 7 = Вс
    EXTRACT(QUARTER FROM d)::INTEGER       AS quarter
FROM (
    SELECT sale_date     AS d FROM read_csv_auto('data/raw/sales.csv',     header=true)
    UNION
    SELECT purchase_date AS d FROM read_csv_auto('data/raw/purchases.csv', header=true)
    UNION
    SELECT shipment_date AS d FROM read_csv_auto('data/raw/logistics.csv', header=true)
) t;
