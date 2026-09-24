# Учебный стенд OLAP

**Стек:** ClickHouse + Metabase (Docker) · DuckDB — локально у студента.

## Быстрый старт

```bash
cd Учебные материалы/_stand
docker compose up -d
chmod +x scripts/init_ch.sh
./scripts/init_ch.sh   # DDL + sample CSV → retail_dw (обязательный шаг)
```

> ClickHouse **не** инициализирует схему из `docker-entrypoint-initdb.d`. Без `init_ch.sh` контейнер пустой.

Проверка ClickHouse:

```bash
curl http://localhost:8123/ping
# → Ok.

docker exec -it olap_clickhouse clickhouse-client \
  --query "SELECT sum(amount) FROM retail_dw.fact_sales"
```

Metabase: http://localhost:3000 (первый вход — мастер настройки).

### Подключение Metabase → ClickHouse

1. Скачайте ClickHouse-драйвер для Metabase (clickhouse-jdbc / официальный partner driver под вашу версию MB) в `metabase/plugins/`.  
2. `docker compose restart metabase`.  
3. Add database: host `clickhouse`, port `8123`, database `retail_dw`, user `default`, пароль пустой (учебный стенд).

Если драйвер не поднят на паре — сдавайте SQL через `clickhouse-client`; Metabase догоните на P10.

## DuckDB (локально)

```bash
pip install duckdb   # или uv add duckdb
python scripts/duckdb_smoke.py
```

## Порты

| Сервис | Порт |
|--------|------|
| ClickHouse HTTP | 8123 |
| ClickHouse native | 9000 |
| Metabase | 3000 |

## Остановка

```bash
docker compose down
# с данными: docker compose down -v
```

## Домен данных

Розничные продажи `retail_dw`: `dim_store`, `dim_product`, `dim_date`, `fact_sales`.  
Тот же CSV — в DuckDB на ранних практиках.
