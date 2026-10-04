-- ============================================================
-- З07. Витрина сети «АвтоДеталь» в ClickHouse
-- Движок MergeTree. Деньги — Decimal(18, 2), не Float.
-- ORDER BY — порядок хранения и пропуск блоков, не уникальный ключ.
-- PARTITION BY — куски по месяцу, отдельно от порядка внутри куска.
-- ============================================================

CREATE DATABASE IF NOT EXISTS autoparts;

DROP TABLE IF EXISTS autoparts.fact_sales;
DROP TABLE IF EXISTS autoparts.fact_purchases;
DROP TABLE IF EXISTS autoparts.fact_logistics;
DROP TABLE IF EXISTS autoparts.dim_product;
DROP TABLE IF EXISTS autoparts.dim_customer;
DROP TABLE IF EXISTS autoparts.dim_supplier;
DROP TABLE IF EXISTS autoparts.dim_carrier;
DROP TABLE IF EXISTS autoparts.dim_store;
DROP TABLE IF EXISTS autoparts.dim_date;

CREATE TABLE autoparts.dim_store
(
    store_id UInt32,
    store_name String,
    city String,
    region String,
    store_format String
)
ENGINE = MergeTree
ORDER BY store_id;

CREATE TABLE autoparts.dim_product
(
    product_sk UInt32,
    product_id UInt32,
    product_name String,
    category String,
    brand String,
    valid_from Date,
    valid_to Nullable(Date),
    is_current Bool
)
ENGINE = MergeTree
ORDER BY (product_id, valid_from);

CREATE TABLE autoparts.dim_customer
(
    customer_id String,
    customer_name String,
    customer_type String,
    region String
)
ENGINE = MergeTree
ORDER BY customer_id;

CREATE TABLE autoparts.dim_supplier
(
    supplier_id String,
    supplier_name String,
    country String
)
ENGINE = MergeTree
ORDER BY supplier_id;

CREATE TABLE autoparts.dim_carrier
(
    carrier String,
    delivery_type String
)
ENGINE = MergeTree
ORDER BY carrier;

CREATE TABLE autoparts.dim_date
(
    date_id Date,
    year UInt16,
    month UInt8,
    day UInt8,
    weekday UInt8,
    quarter UInt8
)
ENGINE = MergeTree
ORDER BY date_id;

-- Отчёты режут продажи по дате, затем по магазину.
CREATE TABLE autoparts.fact_sales
(
    order_id UInt64,
    customer_id String,
    store_id UInt32,
    product_id UInt32,
    product_name String,
    quantity Int32,
    price_per_unit Decimal(18, 2),
    total_amount Decimal(18, 2),
    sale_date Date
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(sale_date)
ORDER BY (sale_date, store_id, product_id);

CREATE TABLE autoparts.fact_purchases
(
    purchase_id UInt64,
    supplier_id String,
    product_id UInt32,
    product_name String,
    quantity Int32,
    price_per_unit Decimal(18, 2),
    total_amount Decimal(18, 2),
    purchase_date Date
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(purchase_date)
ORDER BY (purchase_date, supplier_id, product_id);

CREATE TABLE autoparts.fact_logistics
(
    shipment_id UInt64,
    order_id UInt64,
    carrier String,
    product_id UInt32,
    product_name String,
    quantity Int32,
    price_per_unit Decimal(18, 2),
    total_amount Decimal(18, 2),
    shipment_date Date
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(shipment_date)
ORDER BY (shipment_date, carrier, order_id);
