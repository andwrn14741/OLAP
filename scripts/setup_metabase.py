#!/usr/bin/env python3
"""З10. Собирает дашборд Metabase поверх ClickHouse.

Запуск, когда контейнеры уже Up и драйвер лежит в metabase/plugins:

    python3 scripts/setup_metabase.py

Логин стенда печатается в конце. Это учебный пароль, не секрет продакшена.
"""

from __future__ import annotations

import json
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = "http://localhost:3000/api"
EMAIL = "andrej.voron@olap.local"
PASSWORD = "Avtodetal-2025"
SITE = "АвтоДеталь"
DB_NAME = "АвтоДеталь ClickHouse"
DASHBOARD_NAME = "Сеть АвтоДеталь"
PERIOD = "2025-01-01~2025-12-31"

CARDS = [
    ("01_revenue.sql", "Валовой оборот", "scalar", "fact_sales", "sale_date", {}),
    (
        "02_revenue_by_region_month.sql",
        "Оборот по регионам и месяцам",
        "bar",
        "fact_sales",
        "sale_date",
        {"graph.dimensions": ["month", "region"], "graph.metrics": ["revenue"]},
    ),
    (
        "03_top_products.sql",
        "Топ-10 товаров по штукам",
        "table",
        "fact_sales",
        "sale_date",
        {},
    ),
    (
        "04_delivery.sql",
        "Средняя доставка по перевозчикам",
        "bar",
        "fact_logistics",
        "shipment_date",
        {"graph.dimensions": ["carrier"], "graph.metrics": ["avg_delivery"]},
    ),
    (
        "05_revenue_by_day_store.sql",
        "Оборот по дням и магазинам",
        "line",
        "mart_revenue_day_store",
        "sale_date",
        {
            "graph.dimensions": ["sale_date"],
            "graph.metrics": ["revenue"],
            "graph.x_axis.scale": "timeseries",
        },
    ),
]


def request(method: str, path: str, payload: dict | None = None, token: str | None = None):
    data = None if payload is None else json.dumps(payload).encode()
    headers = {"Content-Type": "application/json"}
    if token:
        headers["X-Metabase-Session"] = token
    req = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=120) as response:
            body = response.read().decode()
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode()
        raise SystemExit(f"{method} {path} -> {exc.code} {detail}") from exc


def wait_ready() -> None:
    for _ in range(90):
        try:
            request("GET", "/health")
            return
        except (SystemExit, urllib.error.URLError, TimeoutError, ConnectionError):
            time.sleep(2)
    raise SystemExit("Metabase не ответил на /api/health")


def session() -> str:
    props = request("GET", "/session/properties")
    setup_token = props.get("setup-token")
    if setup_token:
        created = request(
            "POST",
            "/setup",
            {
                "token": setup_token,
                "user": {
                    "email": EMAIL,
                    "password": PASSWORD,
                    "first_name": "Андрей",
                    "last_name": "Ворон",
                    "site_name": SITE,
                },
                "prefs": {
                    "site_name": SITE,
                    "site_locale": "ru",
                    "allow_tracking": False,
                },
            },
        )
        return created["id"]
    logged = request("POST", "/session", {"username": EMAIL, "password": PASSWORD})
    return logged["id"]


def field_id(metadata: dict, table_name: str, field_name: str) -> int:
    for table in metadata["tables"]:
        if table["name"] != table_name:
            continue
        for field in table["fields"]:
            if field["name"] == field_name:
                return field["id"]
    raise SystemExit(f"нет поля {table_name}.{field_name}")


def ensure_database(token: str) -> tuple[int, dict]:
    existing = request("GET", "/database", token=token)
    items = existing["data"] if isinstance(existing, dict) else existing
    for item in items:
        if item["name"] == DB_NAME:
            database_id = item["id"]
            break
    else:
        created = request(
            "POST",
            "/database",
            {
                "engine": "clickhouse",
                "name": DB_NAME,
                "details": {
                    "host": "clickhouse",
                    "port": 8123,
                    "user": "default",
                    "password": "",
                    "dbname": "autoparts",
                    "ssl": False,
                    "scan-all-databases": False,
                },
            },
            token=token,
        )
        database_id = created["id"]
    request("POST", f"/database/{database_id}/sync_schema", {}, token=token)
    metadata = None
    for _ in range(40):
        metadata = request("GET", f"/database/{database_id}/metadata", token=token)
        names = {table["name"] for table in metadata.get("tables", [])}
        if "fact_sales" in names and "mart_revenue_day_store" in names:
            return database_id, metadata
        time.sleep(1.5)
    raise SystemExit(f"схема не досинхронизировалась: {metadata}")


def template_tag(field: int) -> dict:
    return {
        "period": {
            "id": "c0ffee00-0000-4000-8000-000000000001",
            "name": "period",
            "display-name": "Период",
            "type": "dimension",
            "dimension": ["field", field, None],
            "widget-type": "date/all-options",
            "required": True,
            "default": PERIOD,
        }
    }


def ensure_card(token: str, database_id: int, metadata: dict, spec: tuple) -> int:
    filename, title, display, table_name, field_name, visualization = spec
    query = (ROOT / "dashboards" / filename).read_text(encoding="utf-8")
    cards = request("GET", "/card", token=token)
    for card in cards:
        if card["name"] == title:
            return card["id"]
    created = request(
        "POST",
        "/card",
        {
            "name": title,
            "display": display,
            "visualization_settings": visualization,
            "dataset_query": {
                "type": "native",
                "database": database_id,
                "native": {
                    "query": query,
                    "template-tags": template_tag(field_id(metadata, table_name, field_name)),
                },
            },
        },
        token=token,
    )
    return created["id"]


def ensure_dashboard(token: str, card_ids: list[int]) -> int:
    boards = request("GET", "/dashboard", token=token)
    for board in boards:
        if board["name"] == DASHBOARD_NAME:
            return board["id"]
    created = request(
        "POST",
        "/dashboard",
        {"name": DASHBOARD_NAME, "description": "Продажи, доставка и магазины сети «АвтоДеталь»."},
        token=token,
    )
    dashboard_id = created["id"]
    parameter_id = "period"
    # Карточка на всю ширину, топ-10 таблицей повыше, графики сеткой 2×2.
    slots = [
        (0, 0, 18, 4),
        (4, 9, 9, 8),
        (4, 0, 9, 8),
        (12, 9, 9, 6),
        (12, 0, 9, 6),
    ]
    dashcards = []
    for index, card_id in enumerate(card_ids):
        row, col, size_x, size_y = slots[index]
        dashcards.append(
            {
                "id": -(index + 1),
                "card_id": card_id,
                "row": row,
                "col": col,
                "size_x": size_x,
                "size_y": size_y,
                "parameter_mappings": [
                    {
                        "parameter_id": parameter_id,
                        "card_id": card_id,
                        "target": ["dimension", ["template-tag", "period"]],
                    }
                ],
            }
        )
    request(
        "PUT",
        f"/dashboard/{dashboard_id}",
        {
            "parameters": [
                {
                    "id": parameter_id,
                    "name": "Период",
                    "slug": "period",
                    "type": "date/all-options",
                    "default": PERIOD,
                }
            ],
            "dashcards": dashcards,
        },
        token=token,
    )
    return dashboard_id


def main() -> None:
    wait_ready()
    token = session()
    database_id, metadata = ensure_database(token)
    card_ids = [ensure_card(token, database_id, metadata, spec) for spec in CARDS]
    dashboard_id = ensure_dashboard(token, card_ids)
    print(f"database_id={database_id}")
    print(f"dashboard_id={dashboard_id}")
    print(f"cards={card_ids}")
    print(f"open http://localhost:3000/dashboard/{dashboard_id}")
    print(f"login {EMAIL} / {PASSWORD}")


if __name__ == "__main__":
    main()
