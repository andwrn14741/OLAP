-- ============================================================
-- З03. Загрузка сырья data/raw/ в DuckDB
-- Запуск из корня репозитория, после sql/ddl_duckdb.sql:
--   duckdb data/olap.duckdb < sql/load_duckdb.sql
-- Повторный запуск очищает таблицы и заливает их заново.
-- ============================================================

TRUNCATE fact_sales;
TRUNCATE fact_purchases;
TRUNCATE fact_logistics;
TRUNCATE dim_product;
TRUNCATE dim_customer;
TRUNCATE dim_supplier;
TRUNCATE dim_carrier;
TRUNCATE dim_store;
TRUNCATE dim_date;

-- Справочники раньше фактов: иначе в факте остаются ссылки в никуда.

INSERT INTO dim_store (store_id, store_name, city, region, store_format)
SELECT store_id, store_name, city, region, store_format
FROM read_csv(
    'data/raw/stores.csv',
    header = true,
    columns = {
        'store_id': 'INTEGER',
        'store_name': 'VARCHAR',
        'city': 'VARCHAR',
        'region': 'VARCHAR',
        'store_format': 'VARCHAR'
    }
);

-- Текущая категория. Полная история версий лежит в products.csv и грузится на З06.
INSERT INTO dim_product (product_id, product_name, category, brand)
SELECT product_id, product_name, category, brand
FROM read_csv(
    'data/raw/products.csv',
    header = true,
    columns = {
        'product_id': 'INTEGER',
        'product_name': 'VARCHAR',
        'category': 'VARCHAR',
        'brand': 'VARCHAR',
        'valid_from': 'VARCHAR',
        'valid_to': 'VARCHAR'
    }
)
WHERE COALESCE(valid_to, '') = '';

INSERT INTO dim_customer (customer_id, customer_name, customer_type, region)
SELECT customer_id, customer_name, customer_type, region
FROM read_csv(
    'data/raw/customers.csv',
    header = true,
    columns = {
        'customer_id': 'VARCHAR',
        'customer_name': 'VARCHAR',
        'customer_type': 'VARCHAR',
        'region': 'VARCHAR'
    }
);

INSERT INTO dim_supplier (supplier_id, supplier_name, country)
SELECT supplier_id, supplier_name, country
FROM read_csv(
    'data/raw/suppliers.csv',
    header = true,
    columns = {
        'supplier_id': 'VARCHAR',
        'supplier_name': 'VARCHAR',
        'country': 'VARCHAR'
    }
);

INSERT INTO dim_carrier (carrier, delivery_type)
SELECT carrier, delivery_type
FROM read_csv(
    'data/raw/carriers.csv',
    header = true,
    columns = {
        'carrier': 'VARCHAR',
        'delivery_type': 'VARCHAR'
    }
);

INSERT INTO fact_sales (
    order_id, customer_id, store_id, product_id, product_name,
    quantity, price_per_unit, total_amount, sale_date
)
SELECT
    order_id, customer_id, store_id, product_id, product_name,
    quantity, price_per_unit, total_amount, sale_date
FROM read_csv(
    'data/raw/sales.csv',
    header = true,
    columns = {
        'order_id': 'INTEGER',
        'customer_id': 'VARCHAR',
        'store_id': 'INTEGER',
        'product_id': 'INTEGER',
        'product_name': 'VARCHAR',
        'quantity': 'INTEGER',
        'price_per_unit': 'DECIMAL(18,2)',
        'total_amount': 'DECIMAL(18,2)',
        'sale_date': 'DATE'
    }
);

INSERT INTO fact_purchases (
    purchase_id, supplier_id, product_id, product_name,
    quantity, price_per_unit, total_amount, purchase_date
)
SELECT
    purchase_id, supplier_id, product_id, product_name,
    quantity, price_per_unit, total_amount, purchase_date
FROM read_csv(
    'data/raw/purchases.csv',
    header = true,
    columns = {
        'purchase_id': 'INTEGER',
        'supplier_id': 'VARCHAR',
        'product_id': 'INTEGER',
        'product_name': 'VARCHAR',
        'quantity': 'INTEGER',
        'price_per_unit': 'DECIMAL(18,2)',
        'total_amount': 'DECIMAL(18,2)',
        'purchase_date': 'DATE'
    }
);

INSERT INTO fact_logistics (
    shipment_id, order_id, carrier, product_id, product_name,
    quantity, price_per_unit, total_amount, shipment_date
)
SELECT
    shipment_id, order_id, carrier, product_id, product_name,
    quantity, price_per_unit, total_amount, shipment_date
FROM read_csv(
    'data/raw/logistics.csv',
    header = true,
    columns = {
        'shipment_id': 'INTEGER',
        'order_id': 'INTEGER',
        'carrier': 'VARCHAR',
        'product_id': 'INTEGER',
        'product_name': 'VARCHAR',
        'quantity': 'INTEGER',
        'price_per_unit': 'DECIMAL(18,2)',
        'total_amount': 'DECIMAL(18,2)',
        'shipment_date': 'DATE'
    }
);

INSERT INTO dim_date (date_id, year, month, day, weekday, quarter)
SELECT DISTINCT
    d                                          AS date_id,
    EXTRACT(YEAR    FROM d)::INTEGER           AS year,
    EXTRACT(MONTH   FROM d)::INTEGER           AS month,
    EXTRACT(DAY     FROM d)::INTEGER           AS day,
    EXTRACT(ISODOW  FROM d)::INTEGER           AS weekday,
    EXTRACT(QUARTER FROM d)::INTEGER           AS quarter
FROM (
    SELECT sale_date     AS d FROM fact_sales
    UNION
    SELECT purchase_date AS d FROM fact_purchases
    UNION
    SELECT shipment_date AS d FROM fact_logistics
) t;
