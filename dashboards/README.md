# Дашборд «Сеть АвтоДеталь»

Источник — ClickHouse, база `autoparts`. Файл DuckDB к дашборду не подключён.

1. `docker compose up -d`
2. `bash scripts/fetch_ch_driver.sh` и `docker compose restart metabase`, если драйвера ещё нет
3. `bash etl/load_clickhouse.sh`
4. `python3 scripts/setup_metabase.py`
5. Открыть http://localhost:3000 , логин `andrej.voron@olap.local`, пароль `Avtodetal-2025`

Фильтр «Период» стоит на всех виджетах. Для сверки с эталоном оставьте `2025-01-01` … `2025-12-31`.

| Файл | Виджет |
|---|---|
| `01_revenue.sql` | карточка валового оборота, текст SQL |
| `02_revenue_by_region_month.sql` | оборот по регионам и месяцам |
| `03_top_products.sql` | топ-10 товаров |
| `04_delivery.sql` | средняя доставка по перевозчикам |
| `05_revenue_by_day_store.sql` | оборот по дням из сводки `mart_revenue_day_store` |
