# Плагины Metabase

Сюда кладётся драйвер ClickHouse для образа Metabase 0.52:

```bash
bash scripts/fetch_ch_driver.sh
docker compose restart metabase
```

Файл `clickhouse.metabase-driver.jar` — релиз 1.52.0. Остальные jar в этом каталоге Metabase может создать сам, в git они не входят.
