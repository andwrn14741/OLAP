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
