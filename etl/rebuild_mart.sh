#!/usr/bin/env bash
# З09. Пересчёт сводки день × магазин после загрузки факта.
set -euo pipefail
cd "$(dirname "$0")/.."
docker exec -i olap_clickhouse clickhouse-client --multiquery < sql/mart_clickhouse.sql
