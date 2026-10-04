#!/usr/bin/env bash
# З07. Загрузка витрины в ClickHouse и сверка с DuckDB.
# Повторный запуск пересоздаёт таблицы и не удваивает факт.
set -euo pipefail

cd "$(dirname "$0")/.."

DUCKDB="${DUCKDB:-$HOME/.duckdb/cli/latest/duckdb}"
CH_HTTP="${CH_HTTP:-http://localhost:8123}"

echo "Waiting for ClickHouse at $CH_HTTP ..."
for i in $(seq 1 60); do
  if curl -sf "$CH_HTTP/ping" >/dev/null; then
    break
  fi
  sleep 1
  if [[ $i -eq 60 ]]; then
    echo "ClickHouse не ответил. Запущен ли docker compose?" >&2
    exit 1
  fi
done

echo "DDL"
docker exec -i olap_clickhouse clickhouse-client --multiquery < sql/ddl_clickhouse.sql

echo "LOAD"
docker exec -i olap_clickhouse clickhouse-client --multiquery < sql/load_clickhouse.sql

ch_query() {
  docker exec -i olap_clickhouse clickhouse-client --query "$1"
}

dk_query() {
  "$DUCKDB" data/olap.duckdb -csv -noheader -c "$1"
}

echo "RECONCILE"
fail=0
norm_money() {
  python3 -c 'from decimal import Decimal; import sys; print(f"{Decimal(sys.argv[1]):.2f}")' "$1"
}

compare() {
  local name="$1"
  local ch_sql="$2"
  local dk_sql="$3"
  local as_money="${4:-0}"
  local ch_val dk_val
  ch_val="$(ch_query "$ch_sql")"
  dk_val="$(dk_query "$dk_sql")"
  if [[ "$as_money" == "1" ]]; then
    ch_val="$(norm_money "$ch_val")"
    dk_val="$(norm_money "$dk_val")"
  fi
  if [[ "$ch_val" == "$dk_val" ]]; then
    echo "OK  $name  $ch_val"
  else
    echo "DIFF $name  clickhouse=$ch_val duckdb=$dk_val" >&2
    fail=1
  fi
}

compare "fact_sales.rows" \
  "SELECT count() FROM autoparts.fact_sales" \
  "SELECT COUNT(*) FROM fact_sales"
compare "fact_sales.revenue" \
  "SELECT toString(sum(total_amount)) FROM autoparts.fact_sales" \
  "SELECT SUM(total_amount)::VARCHAR FROM fact_sales" \
  1
compare "fact_purchases.rows" \
  "SELECT count() FROM autoparts.fact_purchases" \
  "SELECT COUNT(*) FROM fact_purchases"
compare "fact_logistics.rows" \
  "SELECT count() FROM autoparts.fact_logistics" \
  "SELECT COUNT(*) FROM fact_logistics"
compare "dim_product.rows" \
  "SELECT count() FROM autoparts.dim_product" \
  "SELECT COUNT(*) FROM dim_product"
compare "dim_store.rows" \
  "SELECT count() FROM autoparts.dim_store" \
  "SELECT COUNT(*) FROM dim_store"

if [[ $fail -ne 0 ]]; then
  echo "Сверка DuckDB и ClickHouse не сошлась" >&2
  exit 1
fi

echo "MART"
bash etl/rebuild_mart.sh

echo "ClickHouse load OK"
