-- ============================================================
-- З05. ELT шаг 3: факты
-- Факты грузятся после справочников.
-- TRUNCATE перед вставкой: второй прогон не удваивает продажи.
-- ============================================================

TRUNCATE fact_sales;
TRUNCATE fact_purchases;
TRUNCATE fact_logistics;

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
