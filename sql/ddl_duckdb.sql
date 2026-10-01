-- ============================================================
-- З03. DDL для витрины «розничная продажа автозапчастей»
-- Движок: DuckDB
-- Деньги: DECIMAL(18,2), не FLOAT
-- ============================================================

DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS fact_purchases;
DROP TABLE IF EXISTS fact_logistics;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_supplier;
DROP TABLE IF EXISTS dim_carrier;
DROP TABLE IF EXISTS dim_date;

-- ---------- Измерения ----------

CREATE TABLE dim_product (
    product_id    INTEGER      PRIMARY KEY,
    product_name  VARCHAR      NOT NULL,
    category      VARCHAR
);

CREATE TABLE dim_customer (
    customer_id   VARCHAR      PRIMARY KEY,
    customer_name VARCHAR,
    region        VARCHAR
);

CREATE TABLE dim_supplier (
    supplier_id   VARCHAR      PRIMARY KEY,
    supplier_name VARCHAR,
    country       VARCHAR
);

CREATE TABLE dim_carrier (
    carrier       VARCHAR      PRIMARY KEY,
    delivery_type VARCHAR
);

CREATE TABLE dim_date (
    date_id       DATE         PRIMARY KEY,
    year          INTEGER      NOT NULL,
    month         INTEGER      NOT NULL,
    day           INTEGER      NOT NULL,
    weekday       INTEGER      NOT NULL,
    quarter       INTEGER      NOT NULL
);

-- ---------- Факты ----------

-- Одна строка fact_sales = одна позиция в заказе
CREATE TABLE fact_sales (
    order_id       INTEGER       NOT NULL,
    customer_id    VARCHAR       NOT NULL,
    product_id     INTEGER       NOT NULL,
    product_name   VARCHAR       NOT NULL,   -- денормализация из сырья
    quantity       INTEGER       NOT NULL,
    price_per_unit DECIMAL(18,2) NOT NULL,
    total_amount   DECIMAL(18,2) NOT NULL,
    sale_date      DATE          NOT NULL
);

-- Одна строка fact_purchases = одна позиция в закупке
CREATE TABLE fact_purchases (
    purchase_id    INTEGER       NOT NULL,
    supplier_id    VARCHAR       NOT NULL,
    product_id     INTEGER       NOT NULL,
    product_name   VARCHAR       NOT NULL,
    quantity       INTEGER       NOT NULL,
    price_per_unit DECIMAL(18,2) NOT NULL,
    total_amount   DECIMAL(18,2) NOT NULL,
    purchase_date  DATE          NOT NULL
);

-- Одна строка fact_logistics = одна отгрузка по заказу
CREATE TABLE fact_logistics (
    shipment_id    INTEGER       NOT NULL,
    order_id       INTEGER       NOT NULL,
    carrier        VARCHAR       NOT NULL,
    product_id     INTEGER       NOT NULL,
    product_name   VARCHAR       NOT NULL,
    quantity       INTEGER       NOT NULL,
    price_per_unit DECIMAL(18,2) NOT NULL,
    total_amount   DECIMAL(18,2) NOT NULL,
    shipment_date  DATE          NOT NULL
);
