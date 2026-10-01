#!/usr/bin/env bash
# ============================================================
# З05. ELT: точка входа
# Запуск: bash etl/run_etl.sh
# ============================================================

set -euo pipefail

# Переходим в корень репозитория (на уровень выше etl/)
cd "$(dirname "$0")/.."

DUCKDB="$HOME/.duckdb/cli/latest/duckdb"
DB="data/olap.duckdb"

echo "[$(date +%T)] ETL START"

echo "[$(date +%T)] 01: DDL"
"$DUCKDB" "$DB" < etl/01_ddl.sql

echo "[$(date +%T)] 02: dims"
"$DUCKDB" "$DB" < etl/02_load_dims.sql

echo "[$(date +%T)] 03: facts"
"$DUCKDB" "$DB" < etl/03_load_facts.sql

echo "[$(date +%T)] 04: checks"
"$DUCKDB" "$DB" < etl/04_checks.sql

echo "[$(date +%T)] ETL DONE"
