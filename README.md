# Проект OLAP

Учебный проект по OLAP. Домен: **розничная продажа автомобильных запчастей**.

## Как поднять ClickHouse

> В методичке стенд лежит в папке `Стенд/`, в этом репозитории `docker-compose.yml` — в корне проекта.

```bash
cd ~/OLAP
docker compose up -d
./scripts/init_ch.sh
```

## Порты
- ClickHouse HTTP: 8123
- ClickHouse native: 9000
- Metabase: 3000

## Проверка стенда

```bash
curl http://localhost:8123/ping          # → Ok.
curl 'http://localhost:8123/?query=SELECT+1'  # → 1
docker compose ps                        # оба контейнера Up
```

## DuckDB (smoke)

```bash
curl https://install.duckdb.org | sh
~/.duckdb/cli/latest/duckdb :memory: "SELECT 42 AS answer"
```
Ожидаемо: `42`.

## Где сырьё
`data/raw/` — 3 CSV, домен: розничная продажа автомобильных запчастей.

| Файл | Строк | Смысл |
|---|---|---|
| purchases.csv | 2 000 | Закупки у поставщиков |
| sales.csv | 20 000 | Продажи клиентам (главный факт) |
| logistics.csv | ~18 000 | Отгрузки; ~10% заказов — самовывоз |

Папка `data/raw/` примонтирована в контейнер как `/var/lib/clickhouse/user_files`, поэтому файлы доступны ClickHouse без ручного копирования.

### purchases.csv — закупки
- purchase_id     (int)   — ID закупки
- supplier_id     (str)   — ID поставщика
- product_id      (int)   — ID товара
- product_name    (str)   — наименование товара
- quantity        (int)   — количество штук
- price_per_unit  (float) — закупочная цена за штуку
- total_amount    (float) — общая сумма закупки
- purchase_date   (date)  — дата закупки

### sales.csv — продажи
- order_id        (int)   — ID заказа
- customer_id     (str)   — ID клиента
- product_id      (int)   — ID товара
- product_name    (str)   — наименование товара
- quantity        (int)   — количество штук
- price_per_unit  (float) — розничная цена за штуку
- total_amount    (float) — общая сумма продажи
- sale_date       (date)  — дата продажи

### logistics.csv — логистика
- shipment_id     (int)   — ID отгрузки
- order_id        (int)   — ID связанного заказа (FK на sales.order_id)
- carrier         (str)   — перевозчик
- product_id      (int)   — ID товара
- product_name    (str)   — наименование товара
- quantity        (int)   — количество штук
- price_per_unit  (float) — стоимость доставки за единицу
- total_amount    (float) — общая сумма доставки
- shipment_date   (date)  — дата отгрузки

## Доказательство, что стенд жив

```
$ curl http://localhost:8123/ping
Ok.

$ curl 'http://localhost:8123/?query=SELECT+1'
1
```

Чтение сырья изнутри контейнера:

```
$ docker exec olap_clickhouse clickhouse-client --query \
    "SELECT count() FROM file('/var/lib/clickhouse/user_files/sales.csv', CSVWithNames)"
20000
```

## Данные
- ФИО: Ворон Андрей Дмитриевич
- Группа: ИИ-231
- Домен: розничная продажа автомобильных запчастей



## DuckDB — витрина (З03)

### Создание таблиц

```bash
cd ~/OLAP
~/.duckdb/cli/latest/duckdb data/olap.duckdb < sql/ddl_duckdb.sql


## ELT (З05)

Загрузка одной командой:

```bash
bash etl/run_etl.sh
```

Скрипт делает четыре шага:

1. **DDL** — создаёт таблицы (`etl/01_ddl.sql`).
2. **Справочники** — `dim_product`, `dim_customer`, `dim_supplier`, `dim_carrier`, `dim_date` (`etl/02_load_dims.sql`).
3. **Факты** — `fact_sales`, `fact_purchases`, `fact_logistics` (`etl/03_load_facts.sql`).
4. **Проверки** — пустые ключи, диапазоны, дубли, «сироты», число строк (`etl/04_checks.sql`).

**Остановка при ошибке.** Любая проверка через `error()` возвращает ненулевой код; `run_etl.sh` использует `set -e`, поэтому ETL прерывается.

**Повторная загрузка.** Каждый шаг начинается с `TRUNCATE` затронутых таблиц. Повторный запуск `run_etl.sh` перезаписывает данные, не удваивая их.

**Доказательство:** `etl/idempotency_log.txt` — два прогона подряд; `COUNT(*)` и `SUM(total_amount)` совпадают.
