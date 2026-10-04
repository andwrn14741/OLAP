-- ============================================================
-- З05. ELT шаг 2: справочники
-- Справочники грузятся до фактов, иначе в факте будут «сироты».
-- Повторный запуск начинается с TRUNCATE и не удваивает строки.
-- ============================================================

TRUNCATE dim_product;
TRUNCATE dim_customer;
TRUNCATE dim_supplier;
TRUNCATE dim_carrier;
TRUNCATE dim_store;
TRUNCATE dim_date;

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

-- SCD2: в справочник попадают и закрытая, и текущая версия.
INSERT INTO dim_product (
    product_sk, product_id, product_name, category, brand,
    valid_from, valid_to, is_current
)
SELECT
    ROW_NUMBER() OVER (ORDER BY product_id, valid_from) AS product_sk,
    product_id,
    product_name,
    category,
    brand,
    valid_from::DATE,
    NULLIF(valid_to, '')::DATE,
    COALESCE(valid_to, '') = '' AS is_current
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
);

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

INSERT INTO dim_date (date_id, year, month, day, weekday, quarter)
SELECT DISTINCT
    d::DATE                                      AS date_id,
    EXTRACT(YEAR    FROM d::DATE)::INTEGER       AS year,
    EXTRACT(MONTH   FROM d::DATE)::INTEGER       AS month,
    EXTRACT(DAY     FROM d::DATE)::INTEGER       AS day,
    EXTRACT(ISODOW  FROM d::DATE)::INTEGER       AS weekday,
    EXTRACT(QUARTER FROM d::DATE)::INTEGER       AS quarter
FROM (
    SELECT sale_date::VARCHAR     AS d FROM read_csv_auto('data/raw/sales.csv', header = true)
    UNION
    SELECT purchase_date::VARCHAR AS d FROM read_csv_auto('data/raw/purchases.csv', header = true)
    UNION
    SELECT shipment_date::VARCHAR AS d FROM read_csv_auto('data/raw/logistics.csv', header = true)
) t
WHERE d IS NOT NULL AND d <> '';
