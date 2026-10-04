# Сеть «АвтоДеталь» · OLAP

Федеральная сеть магазинов автозапчастей: 41 точка, 8 регионов, продажи 2025 года.
ФИО: Ворон Андрей Дмитриевич · Группа: ИИ-231

Одна строка `fact_sales` = одна позиция заказа в магазине сети.
Главная мера = валовой оборот `SUM(fact_sales.total_amount)` = **788 793 643.00** за 2025 год.

## Как поднять

1. Стенд. Из корня репозитория: `docker compose up -d`, затем `bash scripts/fetch_ch_driver.sh` и `docker compose restart metabase`.
2. Данные. `bash etl/run_etl.sh` кладёт витрину в DuckDB. `bash etl/load_clickhouse.sh` пересоздаёт её в ClickHouse (база `autoparts`) и пересчитывает сводку. Повтор не удваивает строки: таблицы очищаются перед вставкой.
3. Эталон метрики. `sql/canonical_metric.sql` — оборот за 2025-01-01 … 2025-12-31. В ClickHouse: `docker exec -i olap_clickhouse clickhouse-client --database autoparts < sql/canonical_metric.sql`.
4. Дашборд. `python3 scripts/setup_metabase.py`, затем http://localhost:3000 . Логин `andrej.voron@olap.local`, пароль `Avtodetal-2025`. Дашборд «Сеть АвтоДеталь», фильтр «Период» = весь 2025 год.
5. Если что-то красное. ETL останавливается на `error()` в `etl/04_checks.sql`. Сверка DuckDB и ClickHouse печатается в конце `etl/load_clickhouse.sh` и лежит в `etl/ch_reconcile_log.txt`. Расхождение карточки и SQL — `notes/z11_sverka.md`.

Порты: ClickHouse HTTP 8123, native 9000, Metabase 3000.

`./scripts/init_ch.sh` поднимает учебный sample курса `retail_dw`. Наша витрина — база `autoparts`, её грузит шаг 2.

## Как данные доходят до экрана

Исходные CSV в `data/raw/` → `etl/run_etl.sh` (сначала справочники, потом факты, потом проверки) → те же таблицы в ClickHouse, `fact_sales` лежит по `(sale_date, store_id, product_id)` и режется по месяцу → эталон `sql/canonical_metric.sql` → карточка «Валовой оборот» с тем же периодом. Одна строка факта = позиция заказа в магазине. Главная мера = валовой оборот, возвратов в сырье нет.

## Сырьё

`data/raw/` воспроизводится командой `python3 scripts/generate_raw.py` (seed 42). Папка смонтирована в ClickHouse как `/var/lib/clickhouse/user_files`.

| Файл | Строк | Смысл |
|---|---|---|
| sales.csv | 65 000 | продажи, главный факт |
| logistics.csv | 58 484 | отгрузки; около 10% заказов — самовывоз |
| purchases.csv | 6 500 | закупки у поставщиков |
| customers.csv | 2 400 | розница, СТО, опт |
| products.csv | 68 | каталог и история категории |
| stores.csv | 41 | магазины сети |
| suppliers.csv | 12 | поставщики |
| carriers.csv | 5 | перевозчики |

### sales.csv

order_id, customer_id, store_id, product_id, product_name, quantity, price_per_unit, total_amount, sale_date.
`total_amount` = quantity × price_per_unit.

### purchases.csv

purchase_id, supplier_id, product_id, product_name, quantity, price_per_unit, total_amount, purchase_date.

### logistics.csv

shipment_id, order_id, carrier, product_id, product_name, quantity, price_per_unit (тариф доставки за штуку), total_amount, shipment_date.

### Справочники

- stores.csv — store_id, store_name, city, region, store_format
- products.csv — product_id, product_name, category, brand, valid_from, valid_to
- customers.csv — customer_id, customer_name, customer_type, region
- suppliers.csv — supplier_id, supplier_name, country
- carriers.csv — carrier, delivery_type

Пустой `valid_to` — текущая версия товара. С 2025-07-01 категория сменилась у антифриза G12, ламп H4/H7 и щёток. Демо: `sql/scd2_demo.sql`.

Модель: `passport.md`, рисунок: `star_schema.md`, отказы: `cut.md`, чеклист сдачи: `checklist.md`.
