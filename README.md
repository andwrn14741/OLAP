# Проект OLAP

## Как поднять ClickHouse
cd ~/OLAP && docker compose up -d && ./scripts/init_ch.sh

## Порты
- ClickHouse HTTP: 8123
- ClickHouse native: 9000
- Metabase: 3000

## Где сырьё
data/raw/ — файлы sales.csv, sales2.csv, sales3.csv

### Описание полей sales.csv
- order_id    (int)    — номер заказа
- customer_id (int)    — ID клиента
- product_id  (int)    — ID товара
- quantity    (int)    — количество единиц в заказе
- price       (float)  — цена за единицу
- order_date  (date)   — дата заказа

sales2.csv и sales3.csv имеют аналогичную структуру —
используются для проверки объединения нескольких источников.

## Доказательство, что стенд жив

```
$ curl http://localhost:8123/ping
Ok.

$ curl 'http://localhost:8123/?query=SELECT+1'
1
```

## Данные
ФИО: Ворон Андрей Дмитриевич
Группа: ИИ-231
Домен: розничные продажи
