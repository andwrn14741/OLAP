#!/usr/bin/env python3
"""Воспроизводимое сырьё сети магазинов автозапчастей «АвтоДеталь».

Запуск из корня репозитория:

    python3 scripts/generate_raw.py

Seed зафиксирован: повторный запуск перезаписывает те же CSV.
Главный факт — около 65 000 строк продаж за 2025 год.
"""

from __future__ import annotations

import csv
import random
from datetime import date, timedelta
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

SEED = 42
N_SALES = 65_000
N_PURCHASES = 6_500
N_CUSTOMERS = 2_400
PICKUP_RATE = 0.10
SCD2_CUTOVER = date(2025, 7, 1)
YEAR_START = date(2025, 1, 1)
YEAR_END = date(2025, 12, 31)

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"

# product_id, name, category, brand, list price (розница, руб. за штуку)
PRODUCTS: list[tuple[int, str, str, str, str]] = [
    (1001, "Тормозные колодки передние", "Тормозная система", "Bosch", "3400.00"),
    (1002, "Тормозные колодки задние", "Тормозная система", "Bosch", "2800.00"),
    (1003, "Тормозные диски передние", "Тормозная система", "Brembo", "6200.00"),
    (1004, "Тормозные диски задние", "Тормозная система", "Brembo", "5400.00"),
    (1005, "Тормозная жидкость DOT-4", "Тормозная система", "Лукойл", "450.00"),
    (1006, "Тормозная жидкость DOT-5.1", "Тормозная система", "Bosch", "890.00"),
    (1007, "Суппорт тормозной", "Тормозная система", "TRW", "7800.00"),
    (1008, "Датчик износа колодок", "Тормозная система", "Bosch", "650.00"),
    (1009, "Масляный фильтр", "Фильтры", "Mann", "520.00"),
    (1010, "Воздушный фильтр", "Фильтры", "Mann", "740.00"),
    (1011, "Фильтр салона", "Фильтры", "Mann", "680.00"),
    (1012, "Топливный фильтр", "Фильтры", "Mann", "910.00"),
    (1013, "Фильтр АКПП", "Фильтры", "Mann", "1400.00"),
    (1014, "Свечи зажигания", "Зажигание", "NGK", "380.00"),
    (1015, "Катушка зажигания", "Зажигание", "Bosch", "2900.00"),
    (1016, "Высоковольтные провода", "Зажигание", "Bremi", "1600.00"),
    (1017, "Стартер", "Зажигание", "Valeo", "8900.00"),
    (1018, "Генератор", "Зажигание", "Valeo", "12400.00"),
    (1019, "Амортизатор передний", "Подвеска", "KYB", "5400.00"),
    (1020, "Амортизатор задний", "Подвеска", "KYB", "4800.00"),
    (1021, "Стойка стабилизатора", "Подвеска", "Lemforder", "980.00"),
    (1022, "Сайлентблок рычага", "Подвеска", "Lemforder", "760.00"),
    (1023, "Шаровая опора", "Подвеска", "Lemforder", "1450.00"),
    (1024, "Рычаг подвески", "Подвеска", "Lemforder", "4200.00"),
    (1025, "Пружина подвески", "Подвеска", "KYB", "3100.00"),
    (1026, "Ступичный подшипник", "Подвеска", "SKF", "2700.00"),
    (1027, "Опора амортизатора", "Подвеска", "Lemforder", "1600.00"),
    (1028, "Ремень ГРМ", "Двигатель", "Gates", "1800.00"),
    (1029, "Ролик натяжителя ГРМ", "Двигатель", "Gates", "1400.00"),
    (1030, "Помпа водяная", "Двигатель", "Hepu", "3600.00"),
    (1031, "Прокладка ГБЦ", "Двигатель", "Elring", "2200.00"),
    (1032, "Сальник коленвала", "Двигатель", "Elring", "480.00"),
    (1033, "Термостат", "Двигатель", "Gates", "1100.00"),
    (1034, "Комплект сцепления", "Двигатель", "Sachs", "9800.00"),
    (1035, "Датчик коленвала", "Двигатель", "Bosch", "1900.00"),
    (1036, "Радиатор охлаждения", "Система охлаждения", "Luzar", "7400.00"),
    (1037, "Радиатор кондиционера", "Система охлаждения", "Luzar", "6900.00"),
    (1038, "Патрубок радиатора", "Система охлаждения", "Gates", "620.00"),
    (1039, "Бачок расширительный", "Система охлаждения", "Luzar", "1400.00"),
    (1040, "Антифриз G12", "Масла и жидкости", "Лукойл", "560.00"),
    (1041, "Вентилятор охлаждения", "Система охлаждения", "Luzar", "4300.00"),
    (1042, "Аккумулятор 60Ah", "Электрика", "Bosch", "7200.00"),
    (1043, "Аккумулятор 75Ah", "Электрика", "Varta", "9100.00"),
    (1044, "Лампы H4", "Электрика", "Osram", "420.00"),
    (1045, "Лампы H7", "Электрика", "Osram", "390.00"),
    (1046, "Реле", "Электрика", "Bosch", "280.00"),
    (1047, "Предохранители набор", "Электрика", "Bosch", "190.00"),
    (1048, "Датчик ABS", "Электрика", "Bosch", "2100.00"),
    (1049, "Бензонасос", "Электрика", "Bosch", "5600.00"),
    (1050, "Моторное масло 5W-40", "Масла и жидкости", "Лукойл", "680.00"),
    (1051, "Моторное масло 5W-30", "Масла и жидкости", "Газпромнефть", "720.00"),
    (1052, "Масло АКПП", "Масла и жидкости", "Лукойл", "890.00"),
    (1053, "Жидкость ГУР", "Масла и жидкости", "Лукойл", "540.00"),
    (1054, "Фара передняя", "Кузов и оптика", "TYC", "6400.00"),
    (1055, "Зеркало боковое", "Кузов и оптика", "TYC", "3200.00"),
    (1056, "Щётки стеклоочистителя", "Аксессуары", "Bosch", "780.00"),
    (1057, "ШРУС наружный", "Трансмиссия", "GKN", "4100.00"),
    (1058, "Пыльник ШРУС", "Трансмиссия", "GKN", "540.00"),
    (1059, "Диск сцепления", "Трансмиссия", "Sachs", "4500.00"),
    (1060, "Рулевой наконечник", "Рулевое управление", "Lemforder", "1300.00"),
    (1061, "Рулевая тяга", "Рулевое управление", "Lemforder", "1800.00"),
    (1062, "Насос ГУР", "Рулевое управление", "ZF", "11200.00"),
    (1063, "Коврики салона", "Аксессуары", "Novline", "2400.00"),
    (1064, "Компрессор кондиционера", "Система охлаждения", "Denso", "16800.00"),
]

# С 1 июля 2025 категория в справочнике меняется. История — в products.csv (З06).
SCD2_NEW_CATEGORY = {
    1040: "Система охлаждения",
    1044: "Кузов и оптика",
    1045: "Кузов и оптика",
    1056: "Кузов и оптика",
}

# Расходники продаются чаще агрегатов.
FAST_MOVERS = {
    1005, 1009, 1010, 1011, 1014, 1040, 1044, 1045, 1046, 1047,
    1050, 1051, 1056, 1001, 1002,
}

STORES: list[tuple[int, str, str, str, str]] = [
    (1, "АвтоДеталь Химки", "Химки", "Центральный", "Гипермаркет"),
    (2, "АвтоДеталь Москва Юг", "Москва", "Центральный", "Гипермаркет"),
    (3, "АвтоДеталь Москва Восток", "Москва", "Центральный", "Магазин"),
    (4, "АвтоДеталь Подольск", "Подольск", "Центральный", "Магазин"),
    (5, "АвтоДеталь Тула", "Тула", "Центральный", "Магазин"),
    (6, "АвтоДеталь Воронеж", "Воронеж", "Центральный", "Гипермаркет"),
    (7, "АвтоДеталь Ярославль", "Ярославль", "Центральный", "Магазин"),
    (8, "АвтоДеталь Рязань", "Рязань", "Центральный", "Пункт выдачи"),
    (9, "АвтоДеталь Тверь", "Тверь", "Центральный", "Магазин"),
    (10, "АвтоДеталь Белгород", "Белгород", "Центральный", "Магазин"),
    (11, "АвтоДеталь СПб Север", "Санкт-Петербург", "Северо-Западный", "Гипермаркет"),
    (12, "АвтоДеталь СПб Юг", "Санкт-Петербург", "Северо-Западный", "Магазин"),
    (13, "АвтоДеталь Калининград", "Калининград", "Северо-Западный", "Магазин"),
    (14, "АвтоДеталь Великий Новгород", "Великий Новгород", "Северо-Западный", "Пункт выдачи"),
    (15, "АвтоДеталь Мурманск", "Мурманск", "Северо-Западный", "Магазин"),
    (16, "АвтоДеталь Ростов", "Ростов-на-Дону", "Южный", "Гипермаркет"),
    (17, "АвтоДеталь Краснодар", "Краснодар", "Южный", "Гипермаркет"),
    (18, "АвтоДеталь Волгоград", "Волгоград", "Южный", "Магазин"),
    (19, "АвтоДеталь Сочи", "Сочи", "Южный", "Магазин"),
    (20, "АвтоДеталь Астрахань", "Астрахань", "Южный", "Пункт выдачи"),
    (21, "АвтоДеталь Ставрополь", "Ставрополь", "Северо-Кавказский", "Магазин"),
    (22, "АвтоДеталь Махачкала", "Махачкала", "Северо-Кавказский", "Магазин"),
    (23, "АвтоДеталь Казань", "Казань", "Приволжский", "Гипермаркет"),
    (24, "АвтоДеталь Нижний Новгород", "Нижний Новгород", "Приволжский", "Гипермаркет"),
    (25, "АвтоДеталь Самара", "Самара", "Приволжский", "Магазин"),
    (26, "АвтоДеталь Уфа", "Уфа", "Приволжский", "Магазин"),
    (27, "АвтоДеталь Пермь", "Пермь", "Приволжский", "Магазин"),
    (28, "АвтоДеталь Саратов", "Саратов", "Приволжский", "Пункт выдачи"),
    (29, "АвтоДеталь Ижевск", "Ижевск", "Приволжский", "Магазин"),
    (30, "АвтоДеталь Екатеринбург", "Екатеринбург", "Уральский", "Гипермаркет"),
    (31, "АвтоДеталь Челябинск", "Челябинск", "Уральский", "Магазин"),
    (32, "АвтоДеталь Тюмень", "Тюмень", "Уральский", "Магазин"),
    (33, "АвтоДеталь Магнитогорск", "Магнитогорск", "Уральский", "Пункт выдачи"),
    (34, "АвтоДеталь Новосибирск", "Новосибирск", "Сибирский", "Гипермаркет"),
    (35, "АвтоДеталь Красноярск", "Красноярск", "Сибирский", "Магазин"),
    (36, "АвтоДеталь Омск", "Омск", "Сибирский", "Магазин"),
    (37, "АвтоДеталь Иркутск", "Иркутск", "Сибирский", "Магазин"),
    (38, "АвтоДеталь Барнаул", "Барнаул", "Сибирский", "Пункт выдачи"),
    (39, "АвтоДеталь Владивосток", "Владивосток", "Дальневосточный", "Гипермаркет"),
    (40, "АвтоДеталь Хабаровск", "Хабаровск", "Дальневосточный", "Магазин"),
    (41, "АвтоДеталь Южно-Сахалинск", "Южно-Сахалинск", "Дальневосточный", "Пункт выдачи"),
]

SUPPLIERS = [
    ("SUP-01", "Bosch GmbH", "Германия"),
    ("SUP-02", "Mann+Hummel", "Германия"),
    ("SUP-03", "NGK Spark Plug", "Япония"),
    ("SUP-04", "Denso", "Япония"),
    ("SUP-05", "Valeo", "Франция"),
    ("SUP-06", "SKF", "Швеция"),
    ("SUP-07", "Лукойл", "Россия"),
    ("SUP-08", "Газпромнефть Смазочные материалы", "Россия"),
    ("SUP-09", "Gates", "США"),
    ("SUP-10", "ZF Friedrichshafen", "Германия"),
    ("SUP-11", "Luzar", "Россия"),
    ("SUP-12", "Osram", "Германия"),
]

CARRIERS = [
    ("СДЭК", "курьер"),
    ("Деловые линии", "сборный груз"),
    ("ПЭК", "сборный груз"),
    ("Почта России", "почта"),
    ("Байкал Сервис", "сборный груз"),
]
CARRIER_WEIGHTS = [30, 25, 20, 15, 10]

SURNAMES = [
    "Иванов", "Петров", "Сидоров", "Кузнецов", "Смирнов", "Попов", "Соколов",
    "Лебедев", "Козлов", "Новиков", "Морозов", "Волков", "Алексеев", "Павлов",
    "Семёнов", "Голубев", "Виноградов", "Богданов", "Воробьёв", "Фёдоров",
    "Михайлов", "Беляев", "Тарасов", "Белов", "Комаров", "Орлов", "Киселёв",
    "Макаров", "Андреев", "Ковалёв", "Ильин", "Гусев", "Титов", "Кузьмин",
]
FIRST_NAMES = [
    "Алексей", "Дмитрий", "Сергей", "Андрей", "Иван", "Павел", "Никита",
    "Егор", "Максим", "Артём", "Олег", "Игорь", "Роман", "Денис", "Кирилл",
]
STO_NAMES = [
    "Форсаж", "Мотор", "Питон", "Гараж 24", "Север", "Колесо", "Поршень",
    "Подъёмник", "Трасса", "Ключ", "Ресурс", "Бокс", "Мастер", "Двигатель",
]
WHOLESALE_NAMES = [
    "АвтоСнаб", "ЗапчастьОпт", "РегионДеталь", "ТехПоставка", "ДрайвТрейд",
    "МоторЛайн", "СервисПартс", "АльянсАвто",
]


def money(value: Decimal) -> Decimal:
    return value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def money_str(value: Decimal) -> str:
    return f"{money(value):.2f}"


def write_csv(path: Path, header: list[str], rows: list[list[object]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(header)
        writer.writerows(rows)


def random_date(rng: random.Random) -> date:
    span = (YEAR_END - YEAR_START).days
    return YEAR_START + timedelta(days=rng.randrange(span + 1))


def build_products() -> list[list[str]]:
    rows: list[list[str]] = []
    for product_id, name, category, brand, _price in PRODUCTS:
        if product_id in SCD2_NEW_CATEGORY:
            rows.append([
                product_id, name, category, brand,
                "2024-01-01", SCD2_CUTOVER.isoformat(),
            ])
            rows.append([
                product_id, name, SCD2_NEW_CATEGORY[product_id], brand,
                SCD2_CUTOVER.isoformat(), "",
            ])
        else:
            rows.append([product_id, name, category, brand, "2024-01-01", ""])
    return rows


FORMAT_WEIGHT = {"Гипермаркет": 8, "Магазин": 3, "Пункт выдачи": 1}
CITY_BOOST = {
    "Москва": 2.2,
    "Санкт-Петербург": 1.7,
    "Казань": 1.3,
    "Новосибирск": 1.25,
    "Екатеринбург": 1.25,
    "Краснодар": 1.2,
    "Нижний Новгород": 1.15,
}


def store_weight(store: tuple[int, str, str, str, str]) -> float:
    _store_id, _name, city, _region, store_format = store
    return FORMAT_WEIGHT[store_format] * CITY_BOOST.get(city, 1.0)


def region_weights() -> tuple[list[str], list[float]]:
    totals: dict[str, float] = {}
    for store in STORES:
        totals[store[3]] = totals.get(store[3], 0.0) + store_weight(store)
    regions = list(totals)
    return regions, [totals[region] for region in regions]


def build_customers(rng: random.Random) -> list[list[str]]:
    regions, weights = region_weights()
    rows: list[list[str]] = []
    for index in range(1, N_CUSTOMERS + 1):
        customer_id = f"CUST-{index:04d}"
        region = rng.choices(regions, weights=weights, k=1)[0]
        roll = rng.randrange(100)
        if roll < 60:
            name = f"{rng.choice(SURNAMES)} {rng.choice(FIRST_NAMES)}"
            customer_type = "розница"
        elif roll < 90:
            name = f"СТО «{rng.choice(STO_NAMES)}» {region.split()[0]}"
            customer_type = "СТО"
        else:
            name = f"ООО «{rng.choice(WHOLESALE_NAMES)}»"
            customer_type = "опт"
        rows.append([customer_id, name, customer_type, region])
    return rows


def pick_product(rng: random.Random) -> tuple[int, str, str, str, Decimal]:
    if rng.randrange(100) < 55:
        pool = [item for item in PRODUCTS if item[0] in FAST_MOVERS]
    else:
        pool = PRODUCTS
    product_id, name, category, brand, price = rng.choice(pool)
    return product_id, name, category, brand, Decimal(price)


def build_sales(
    rng: random.Random,
    customers: list[list[str]],
) -> list[list[object]]:
    customers_by_region: dict[str, list[str]] = {}
    customer_type = {row[0]: row[2] for row in customers}
    for customer_id, _name, _kind, region in customers:
        customers_by_region.setdefault(region, []).append(customer_id)
    store_ids = [store[0] for store in STORES]
    store_region = {store[0]: store[3] for store in STORES}
    weights = [store_weight(store) for store in STORES]

    rows: list[list[object]] = []
    for order_id in range(1, N_SALES + 1):
        store_id = rng.choices(store_ids, weights=weights, k=1)[0]
        region = store_region[store_id]
        if rng.randrange(100) < 85 and customers_by_region.get(region):
            customer_id = rng.choice(customers_by_region[region])
        else:
            customer_id = rng.choice(customers_by_region[rng.choice(list(customers_by_region))])
        product_id, name, _category, _brand, list_price = pick_product(rng)
        kind = customer_type[customer_id]
        if kind == "розница":
            quantity = rng.randint(1, 4)
        elif kind == "СТО":
            quantity = rng.randint(2, 12)
        else:
            quantity = rng.randint(8, 40)
        noise = Decimal(rng.randrange(92, 109)) / Decimal(100)
        price = money(list_price * noise)
        total = money(price * quantity)
        rows.append([
            order_id,
            customer_id,
            store_id,
            product_id,
            name,
            quantity,
            money_str(price),
            money_str(total),
            random_date(rng).isoformat(),
        ])
    return rows


def build_purchases(rng: random.Random) -> list[list[object]]:
    supplier_ids = [row[0] for row in SUPPLIERS]
    rows: list[list[object]] = []
    for purchase_id in range(1, N_PURCHASES + 1):
        product_id, name, _category, _brand, list_price_raw = rng.choice(PRODUCTS)
        list_price = Decimal(list_price_raw)
        quantity = rng.randint(20, 400)
        discount = Decimal(rng.randrange(55, 73)) / Decimal(100)
        price = money(list_price * discount)
        total = money(price * quantity)
        rows.append([
            purchase_id,
            rng.choice(supplier_ids),
            product_id,
            name,
            quantity,
            money_str(price),
            money_str(total),
            random_date(rng).isoformat(),
        ])
    return rows


def build_logistics(rng: random.Random, sales: list[list[object]]) -> list[list[object]]:
    carriers = [row[0] for row in CARRIERS]
    rows: list[list[object]] = []
    shipment_id = 1
    for sale in sales:
        if rng.randrange(100) < int(PICKUP_RATE * 100):
            continue
        order_id, _customer, _store, product_id, name, quantity = sale[:6]
        sale_day = date.fromisoformat(str(sale[8]))
        shipped = sale_day + timedelta(days=rng.randint(1, 4))
        tariff = money(Decimal(rng.randrange(80, 450)))
        total = money(tariff * int(quantity))
        rows.append([
            shipment_id,
            order_id,
            rng.choices(carriers, weights=CARRIER_WEIGHTS, k=1)[0],
            product_id,
            name,
            quantity,
            money_str(tariff),
            money_str(total),
            shipped.isoformat(),
        ])
        shipment_id += 1
    return rows


def main() -> None:
    rng = random.Random(SEED)
    RAW.mkdir(parents=True, exist_ok=True)

    products = build_products()
    customers = build_customers(rng)
    sales = build_sales(rng, customers)
    purchases = build_purchases(rng)
    logistics = build_logistics(rng, sales)

    write_csv(
        RAW / "products.csv",
        ["product_id", "product_name", "category", "brand", "valid_from", "valid_to"],
        products,
    )
    write_csv(
        RAW / "stores.csv",
        ["store_id", "store_name", "city", "region", "store_format"],
        [list(row) for row in STORES],
    )
    write_csv(
        RAW / "customers.csv",
        ["customer_id", "customer_name", "customer_type", "region"],
        customers,
    )
    write_csv(
        RAW / "suppliers.csv",
        ["supplier_id", "supplier_name", "country"],
        [list(row) for row in SUPPLIERS],
    )
    write_csv(
        RAW / "carriers.csv",
        ["carrier", "delivery_type"],
        [list(row) for row in CARRIERS],
    )
    write_csv(
        RAW / "sales.csv",
        [
            "order_id", "customer_id", "store_id", "product_id", "product_name",
            "quantity", "price_per_unit", "total_amount", "sale_date",
        ],
        sales,
    )
    write_csv(
        RAW / "purchases.csv",
        [
            "purchase_id", "supplier_id", "product_id", "product_name",
            "quantity", "price_per_unit", "total_amount", "purchase_date",
        ],
        purchases,
    )
    write_csv(
        RAW / "logistics.csv",
        [
            "shipment_id", "order_id", "carrier", "product_id", "product_name",
            "quantity", "price_per_unit", "total_amount", "shipment_date",
        ],
        logistics,
    )

    print(f"products={len(products)} stores={len(STORES)} customers={len(customers)}")
    print(f"suppliers={len(SUPPLIERS)} carriers={len(CARRIERS)}")
    print(f"sales={len(sales)} purchases={len(purchases)} logistics={len(logistics)}")
    print(f"total_rows={len(products) + len(STORES) + len(customers) + len(SUPPLIERS) + len(CARRIERS) + len(sales) + len(purchases) + len(logistics)}")


if __name__ == "__main__":
    main()
