-- ============================================================
-- З07. Полная перезагрузка autoparts из data/raw
-- Повторный запуск: ddl дропает таблицы, затем этот файл вставляет заново.
-- CSV смонтированы в /var/lib/clickhouse/user_files.
-- Деньги читаются как строки и приводятся к Decimal, чтобы не поймать Float.
-- ============================================================

INSERT INTO autoparts.dim_store
SELECT
    toUInt32(store_id),
    store_name,
    city,
    region,
    store_format
FROM file(
    'stores.csv',
    'CSVWithNames',
    'store_id String, store_name String, city String, region String, store_format String'
);

INSERT INTO autoparts.dim_product
SELECT
    toUInt32(row_number() OVER (ORDER BY toUInt32(product_id), toDate(valid_from))),
    toUInt32(product_id),
    product_name,
    category,
    brand,
    toDate(valid_from),
    if(valid_to = '', CAST(NULL AS Nullable(Date)), toDate(valid_to)),
    valid_to = ''
FROM file(
    'products.csv',
    'CSVWithNames',
    'product_id String, product_name String, category String, brand String, valid_from String, valid_to String'
);

INSERT INTO autoparts.dim_customer
SELECT
    customer_id,
    customer_name,
    customer_type,
    region
FROM file(
    'customers.csv',
    'CSVWithNames',
    'customer_id String, customer_name String, customer_type String, region String'
);

INSERT INTO autoparts.dim_supplier
SELECT supplier_id, supplier_name, country
FROM file(
    'suppliers.csv',
    'CSVWithNames',
    'supplier_id String, supplier_name String, country String'
);

INSERT INTO autoparts.dim_carrier
SELECT carrier, delivery_type
FROM file(
    'carriers.csv',
    'CSVWithNames',
    'carrier String, delivery_type String'
);

INSERT INTO autoparts.fact_sales
SELECT
    toUInt64(order_id),
    customer_id,
    toUInt32(store_id),
    toUInt32(product_id),
    product_name,
    toInt32(quantity),
    CAST(price_per_unit AS Decimal(18, 2)),
    CAST(total_amount AS Decimal(18, 2)),
    toDate(sale_date)
FROM file(
    'sales.csv',
    'CSVWithNames',
    'order_id String, customer_id String, store_id String, product_id String, product_name String, quantity String, price_per_unit String, total_amount String, sale_date String'
);

INSERT INTO autoparts.fact_purchases
SELECT
    toUInt64(purchase_id),
    supplier_id,
    toUInt32(product_id),
    product_name,
    toInt32(quantity),
    CAST(price_per_unit AS Decimal(18, 2)),
    CAST(total_amount AS Decimal(18, 2)),
    toDate(purchase_date)
FROM file(
    'purchases.csv',
    'CSVWithNames',
    'purchase_id String, supplier_id String, product_id String, product_name String, quantity String, price_per_unit String, total_amount String, purchase_date String'
);

INSERT INTO autoparts.fact_logistics
SELECT
    toUInt64(shipment_id),
    toUInt64(order_id),
    carrier,
    toUInt32(product_id),
    product_name,
    toInt32(quantity),
    CAST(price_per_unit AS Decimal(18, 2)),
    CAST(total_amount AS Decimal(18, 2)),
    toDate(shipment_date)
FROM file(
    'logistics.csv',
    'CSVWithNames',
    'shipment_id String, order_id String, carrier String, product_id String, product_name String, quantity String, price_per_unit String, total_amount String, shipment_date String'
);

INSERT INTO autoparts.dim_date
SELECT DISTINCT
    d,
    toUInt16(toYear(d)),
    toUInt8(toMonth(d)),
    toUInt8(toDayOfMonth(d)),
    toUInt8(toDayOfWeek(d)),
    toUInt8(toQuarter(d))
FROM
(
    SELECT sale_date AS d FROM autoparts.fact_sales
    UNION DISTINCT
    SELECT purchase_date FROM autoparts.fact_purchases
    UNION DISTINCT
    SELECT shipment_date FROM autoparts.fact_logistics
);
