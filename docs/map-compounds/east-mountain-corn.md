# East Mountain Corn

- ID: `com_g`
- Тип: compound
- Общий статус: `REFERENCE_CONFIRMED__GEOMETRY_PENDING`
- Этажей: **1**; точек улик: **6**; логово: **Ground floor**.
- Назначение и история: `PENDING_RESEARCH`; тематическое направление ТЗ не считается подтверждённым описанием оригинала.

## Референсы

- https://hunt.innerpulse.net/maps/#mammons-gulch
- https://hunt.innerpulse.net/maps/3d/mammons-gulch/east-mountain-corn/

Координаты, этажи и игровые точки: `CONFIRMED` по числовым данным Hunt Almanac. Перевод в studs: `ADAPTED` (1 м = 3 studs до Studio-калибровки). Архитектурные детали без отдельного просмотра: `PENDING_RESEARCH`.

## География и границы

- Label anchor, source XY: `[1296.384, 1182.6176]`; Roblox XYZ: `[817.152, 17.566986, -475.8528]`. Это не центр масс зданий.
- Building bbox source `[minX, minY, maxX, maxY]`: `[1209.6512, 1123.4304, 1301.504, 1200.128]`.
- Полигон региона хранится в `assets/mammons-gulch/reference/layout.json`.
- Высотный профиль вне измеренных точек: `PENDING_RESEARCH` до применения heightfield.

## Этажи

| Уровень | Floor, м | Над локальной землёй, м | Cut, м | Статус |
|---|---:|---:|---:|---|
| Ground floor | 40.38 | 1.31 | 41.58 | CONFIRMED |

## Архитектура

Основные здания, вспомогательные сооружения, крыши, материалы и взаимное расположение: `PENDING_RESEARCH`. Greybox не является подтверждением финальной архитектуры.

## Входы, окна и вертикальные маршруты

| Тип | Измеренных точек | Статус |
|---|---:|---|
| Doors | 18 | CONFIRMED positions; назначение проёмов требует просмотра |
| Windows | 19 | CONFIRMED positions; ставни/стекло требуют просмотра |
| Ladders | 6 | CONFIRMED positions; рабочая геометрия не создана |
| Elevators | 1 | CONFIRMED positions; механизм не реализован |
| Stair flights | 10 | CONFIRMED endpoints/width; рабочая геометрия не создана |

Главные/второстепенные входы, пути проникновения, переходы между зданиями и выходы: `PENDING_RESEARCH` до разбора планов и вида по сторонам света.

## Подземные помещения

Связь с `undergroundRegions` и пещерными пустотами: `PENDING_RESEARCH`. Не объявлять подземную сеть завершённой по одним маркерам.

## Тактика и линии обзора

Источник сообщает: **Favours the defenders**.

- only 8 ways in, easy to hold
- no high ground overlooks its doorways
- about 10 groups of alarm animals round it

Основные/скрытые подходы, позиции защиты, длинные и короткие перестрелки, отступление и проверенные укрытия: `PENDING_RESEARCH`/`PENDING_STUDIO`.

## Игровые точки

- Clue spots по опубликованным floor plans: **6**; сырых clue markers: **19**. Координаты всех маркеров сохранены в `points.json`; при различии значений фильтрация не выдумывается. Активные точки выбирает будущий сервер матча.
- Lair anchor: `[1296.37, 1182.65, 42.52]`, возможные боссы: Assassin, Bloodskin, Butcher, Scrapbeak, Spider. Модели и AI боссов не входят в этот этап.
- NPC и звуковые ловушки ниже являются диапазонами возможных групп, а не одновременно активными спавнами.

### NPC

| Тип | Диапазон | Среднее |
|---|---:|---:|
| Grunt | 16–70 | среднее 32.9 |
| Armored | 0–9 | среднее 2.0 |
| Hive | 0–10 | среднее 2.8 |
| Hellhound | 0–16 | среднее 1.8 |
| Muzzled Hellhound | 0–7 | среднее 0.3 |
| Immolator | 0–7 | среднее 1.3 |
| Water Devil | 0–1 | среднее 0.5 |

### Звуковые ловушки

| Тип | Диапазон групп |
|---|---:|
| Caged dogs & chickens | 0–2 |
| Ducks | 0–2 |
| Dying cows | 1–3 |
| Dying horses | 1–3 |
| Ravens | 3–4 |

## Необходимые ассеты

Кандидаты: `ph-wood-planks-grey`, `ph-brown-mud-02`. Их статус и оценки находятся в `assets/mammons-gulch/asset-manifest.json`; назначение не равно одобрению или интеграции. Авторская архитектура, интерьеры, интерактивные объекты, VFX, audio и UI по-прежнему требуют референсов и Studio QA.

## Проверка

- Числовой dataset: `CONFIRMED` после unit tests.
- Геометрия, интерьеры, двери, лестницы, коллизии, StreamingEnabled, производительность и визуальное сравнение: `PENDING_STUDIO`.
- Критерии 90/100 не присваиваются на стадии референсов.
