# Проект OLAP

Учебный проект по OLAP. Домен: **федеральная сеть магазинов автозапчастей «АвтоДеталь»**
(41 точка в 8 регионах, розница, СТО и опт).

- ФИО: Ворон Андрей Дмитриевич
- Группа: ИИ-231

## Как поднять ClickHouse

> В методичке стенд лежит в папке `Стенд/`. В этом репозитории `docker-compose.yml` — в корне проекта.

```bash
cd ~/OLAP
docker compose up -d
./scripts/init_ch.sh
```

`init_ch.sh` поднимает учебный sample курса `retail_dw`. Боевая витрина сети появится в базе `autoparts` на З07.

## Порты

- ClickHouse HTTP: 8123
- ClickHouse native: 9000
- Metabase: 3000

## Проверка стенда

```bash
curl http://localhost:8123/ping
curl 'http://localhost:8123/?query=SELECT+1'
docker compose ps
```

Ожидаемо: `Ok.`, затем `1`, оба контейнера в состоянии Up.

## DuckDB

```bash
curl https://install.duckdb.org | sh
~/.duckdb/cli/latest/duckdb :memory: "SELECT 42 AS answer"
```

Ожидаемо: `42`.

Витрина:

```bash
cd ~/OLAP
~/.duckdb/cli/latest/duckdb data/olap.duckdb < sql/ddl_duckdb.sql
~/.duckdb/cli/latest/duckdb data/olap.duckdb < sql/load_duckdb.sql
~/.duckdb/cli/latest/duckdb data/olap.duckdb < sql/checks_duckdb.sql
```

Повторная загрузка начинается с `TRUNCATE` и не удваивает продажи.

## ELT (З05)

```bash
bash etl/run_etl.sh
```

Скрипт делает четыре шага:

1. **DDL** — создаёт таблицы (`etl/01_ddl.sql`).
2. **Справочники** — магазины, товары, клиенты, поставщики, перевозчики, календарь (`etl/02_load_dims.sql`).
3. **Факты** — продажи, закупки, отгрузки (`etl/03_load_facts.sql`).
4. **Проверки** — пустые ключи, диапазоны, дубли, «сироты», сверка числа строк с CSV (`etl/04_checks.sql`).

Любая проверка через `error()` возвращает ненулевой код. `run_etl.sh` использует `set -e`, поэтому ETL останавливается.

Повторный запуск перезаписывает данные. Доказательство двух прогонов: `etl/idempotency_log.txt`.

Эталон оборота: `sql/canonical_metric.sql`. Зафиксированное число: **788 793 643.00**.

## SCD2 (З06)

`dim_product` хранит историю категории. С 1 июля 2025 антифриз G12, лампы H4/H7 и щётки стеклоочистителя переведены в другую категорию: старая строка закрывается, новая становится текущей.

```bash
~/.duckdb/cli/latest/duckdb data/olap.duckdb < sql/scd2_demo.sql
```

Факт связывается с версией на дату продажи: `sale_date >= valid_from` и `valid_to` пустой либо позже даты продажи. Если взять только `is_current`, январские щётки ошибочно попадут в новую категорию.

## Где сырьё

`data/raw/` — CSV сети «АвтоДеталь» за 2025 год. Файлы воспроизводятся командой `python3 scripts/generate_raw.py` (seed 42).

| Файл | Строк | Смысл |
|---|---|---|
| sales.csv | 65 000 | продажи клиентам, главный факт |
| logistics.csv | 58 484 | отгрузки; около 10% заказов — самовывоз |
| purchases.csv | 6 500 | закупки у поставщиков |
| customers.csv | 2 400 | розница, СТО и опт |
| products.csv | 68 | каталог, включая историю категории для З06 |
| stores.csv | 41 | магазины сети |
| suppliers.csv | 12 | поставщики |
| carriers.csv | 5 | перевозчики |

Папка `data/raw/` примонтирована в контейнер как `/var/lib/clickhouse/user_files`.

### sales.csv — продажи

- order_id — ID заказа
- customer_id — ID клиента
- store_id — ID магазина сети
- product_id — ID товара
- product_name — наименование
- quantity — количество штук
- price_per_unit — розничная цена за штуку
- total_amount — сумма позиции, равна quantity × price_per_unit
- sale_date — дата продажи

### purchases.csv — закупки

- purchase_id, supplier_id, product_id, product_name
- quantity, price_per_unit, total_amount, purchase_date

### logistics.csv — логистика

- shipment_id, order_id, carrier, product_id, product_name
- quantity, price_per_unit (тариф доставки за штуку), total_amount, shipment_date

### Справочники

- stores.csv — store_id, store_name, city, region, store_format
- products.csv — product_id, product_name, category, brand, valid_from, valid_to
- customers.csv — customer_id, customer_name, customer_type, region
- suppliers.csv — supplier_id, supplier_name, country
- carriers.csv — carrier, delivery_type

Пустой `valid_to` означает текущую версию товара.
