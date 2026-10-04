#!/usr/bin/env bash
# Драйвер ClickHouse для Metabase 0.52. Кладётся в каталог плагинов стенда.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p metabase/plugins
dest="metabase/plugins/clickhouse.metabase-driver.jar"
if [[ -f "$dest" ]]; then
  echo "already present: $dest"
  exit 0
fi
curl -fsSL -o "$dest" \
  https://github.com/ClickHouse/metabase-clickhouse-driver/releases/download/1.52.0/clickhouse.metabase-driver.jar
echo "saved $dest"
