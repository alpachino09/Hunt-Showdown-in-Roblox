# The Gasworks

- ID: `poi_a`
- Тип: point of interest
- Общий статус: `REFERENCE_CONFIRMED__GEOMETRY_PENDING`
- Этажей: **3**; точек улик: **17**; логово: **Ground floor**.
- Назначение и история: `PENDING_RESEARCH`; тематическое направление ТЗ не считается подтверждённым описанием оригинала.

## Референсы

- https://hunt.innerpulse.net/maps/#mammons-gulch
- https://hunt.innerpulse.net/maps/3d/mammons-gulch/the-gasworks/

Координаты, этажи и игровые точки: `CONFIRMED` по числовым данным Hunt Almanac. Перевод в studs: `ADAPTED` (1 м = 3 studs до Studio-калибровки). Архитектурные детали без отдельного просмотра: `PENDING_RESEARCH`.

## География и границы

- Label anchor, source XY: `[1014.1696, 1496.064]`; Roblox XYZ: `[-29.4912, 14.156629, -1416.192]`. Это не центр масс зданий.
- Building bbox source `[minX, minY, maxX, maxY]`: `[984.1664, 1426.7392, 1039.7696, 1508.0448]`.
- Полигон региона хранится в `assets/mammons-gulch/reference/layout.json`.
- Высотный профиль вне измеренных точек: `PENDING_RESEARCH` до применения heightfield.

## Этажи

| Уровень | Floor, м | Над локальной землёй, м | Cut, м | Статус |
|---|---:|---:|---:|---|
| Ground floor | 40.02 | -1.36 | 41.22 | CONFIRMED |
| Upper floor | 45.95 | 4.48 | 47.15 | CONFIRMED |
| Upper floor 2 | 48.41 | 7.03 | 49.61 | CONFIRMED |

## Архитектура

Основные здания, вспомогательные сооружения, крыши, материалы и взаимное расположение: `PENDING_RESEARCH`. Greybox не является подтверждением финальной архитектуры.

## Входы, окна и вертикальные маршруты

| Тип | Измеренных точек | Статус |
|---|---:|---|
| Doors | 32 | CONFIRMED positions; назначение проёмов требует просмотра |
| Windows | 4 | CONFIRMED positions; ставни/стекло требуют просмотра |
| Ladders | 15 | CONFIRMED positions; рабочая геометрия не создана |
| Elevators | 1 | CONFIRMED positions; механизм не реализован |
| Stair flights | 27 | CONFIRMED endpoints/width; рабочая геометрия не создана |

Главные/второстепенные входы, пути проникновения, переходы между зданиями и выходы: `PENDING_RESEARCH` до разбора планов и вида по сторонам света.

## Подземные помещения

Связь с `undergroundRegions` и пещерными пустотами: `PENDING_RESEARCH`. Не объявлять подземную сеть завершённой по одним маркерам.

## Тактика и линии обзора

Источник сообщает: **Even**.

- 68 noise traps
- high ground 342 m out sees 6 of its doorways
- about 10 groups of alarm animals round it

Основные/скрытые подходы, позиции защиты, длинные и короткие перестрелки, отступление и проверенные укрытия: `PENDING_RESEARCH`/`PENDING_STUDIO`.

## Игровые точки

- Clue spots по опубликованным floor plans: **17**; сырых clue markers: **26**. Координаты всех маркеров сохранены в `points.json`; при различии значений фильтрация не выдумывается. Активные точки выбирает будущий сервер матча.
- Lair anchor: `[1014.21, 1496.06, 41.46]`, возможные боссы: Assassin, Bloodskin, Butcher, Scrapbeak, Spider. Модели и AI боссов не входят в этот этап.
- NPC и звуковые ловушки ниже являются диапазонами возможных групп, а не одновременно активными спавнами.

### NPC

| Тип | Диапазон | Среднее |
|---|---:|---:|
| Grunt | 14–66 | среднее 31.9 |
| Armored | 0–10 | среднее 3.4 |
| Hive | 0–9 | среднее 2.8 |
| Hellhound | 0–8 | среднее 1.8 |
| Muzzled Hellhound | 0–2 | среднее 0.2 |
| Immolator | 0–5 | среднее 0.9 |
| Meathead | 0–1 | среднее 0.1 |
| Water Devil | 0–1 | среднее 0.5 |

### Звуковые ловушки

| Тип | Диапазон групп |
|---|---:|
| Caged dogs & chickens | 0–2 |
| Ducks | 0–2 |
| Dying cows | 0–1 |
| Dying horses | 3–3 |
| Ravens | 4–4 |

## Необходимые ассеты

`PENDING_ASSET_RESEARCH`: архитектура, интерьеры, интерактивные объекты, VFX, audio и UI вносятся только после проверки прав и качества.

## Проверка

- Числовой dataset: `CONFIRMED` после unit tests.
- Геометрия, интерьеры, двери, лестницы, коллизии, StreamingEnabled, производительность и визуальное сравнение: `PENDING_STUDIO`.
- Критерии 90/100 не присваиваются на стадии референсов.
