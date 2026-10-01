-- ============================================================
-- З05. ELT шаг 3: загрузка фактов
-- Факты грузятся ПОСЛЕ справочников — иначе «сироты» в FK
-- ============================================================

TRUNCATE fact_sales;
TRUNCATE fact_purchases;
TRUNCATE fact_logistics;

-- Колонки CSV совпадают с колонками таблиц 1:1
COPY fact_sales      FROM 'data/raw/sales.csv'      (HEADER, DELIMITER ',');
COPY fact_purchases  FROM 'data/raw/purchases.csv'  (HEADER, DELIMITER ',');
COPY fact_logistics  FROM 'data/raw/logistics.csv'  (HEADER, DELIMITER ',');

