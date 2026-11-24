# Machine Gorge

- ID: `com_k`
- Тип: compound
- Общий статус: `REFERENCE_CONFIRMED__GEOMETRY_PENDING`
- Этажей: **3**; точек улик: **19**; логово: **Upper floor**.
- Назначение и история: `PENDING_RESEARCH`; тематическое направление ТЗ не считается подтверждённым описанием оригинала.

## Референсы

- https://hunt.innerpulse.net/maps/#mammons-gulch
- https://hunt.innerpulse.net/maps/3d/mammons-gulch/machine-gorge/

Координаты, этажи и игровые точки: `CONFIRMED` по числовым данным Hunt Almanac. Перевод в studs: `ADAPTED` (1 м = 3 studs до Studio-калибровки). Архитектурные детали без отдельного просмотра: `PENDING_RESEARCH`.

## География и границы

- Label anchor, source XY: `[1457.0496, 946.9952]`; Roblox XYZ: `[1299.1488, 15.458901, 231.0144]`. Это не центр масс зданий.
- Building bbox source `[minX, minY, maxX, maxY]`: `[1409.6384, 940.4416, 1520.0256, 1056.6656]`.
- Полигон региона хранится в `assets/mammons-gulch/reference/layout.json`.
- Высотный профиль вне измеренных точек: `PENDING_RESEARCH` до применения heightfield.

## Этажи

| Уровень | Floor, м | Над локальной землёй, м | Cut, м | Статус |
|---|---:|---:|---:|---|
| Lower ground floor | 38.11 | -0.77 | 39.31 | CONFIRMED |
| Upper ground floor | 39.90 | 1.34 | 41.10 | CONFIRMED |
| Upper floor | 44.11 | 5.55 | 45.31 | CONFIRMED |

## Архитектура

Основные здания, вспомогательные сооружения, крыши, материалы и взаимное расположение: `PENDING_RESEARCH`. Greybox не является подтверждением финальной архитектуры.

## Входы, окна и вертикальные маршруты

| Тип | Измеренных точек | Статус |
|---|---:|---|
| Doors | 11 | CONFIRMED positions; назначение проёмов требует просмотра |
| Windows | 6 | CONFIRMED positions; ставни/стекло требуют просмотра |
| Ladders | 3 | CONFIRMED positions; рабочая геометрия не создана |
| Elevators | 1 | CONFIRMED positions; механизм не реализован |
| Stair flights | 12 | CONFIRMED endpoints/width; рабочая геометрия не создана |

Главные/второстепенные входы, пути проникновения, переходы между зданиями и выходы: `PENDING_RESEARCH` до разбора планов и вида по сторонам света.

## Подземные помещения

Связь с `undergroundRegions` и пещерными пустотами: `PENDING_RESEARCH`. Не объявлять подземную сеть завершённой по одним маркерам.

## Тактика и линии обзора

Источник сообщает: **Even**.

- cover on the way in: 80% of the ground 60–200 m out is out of sight of its doors and windows
- only 6 ways in, easy to hold
- the lair is 35 m inside, through a door and a stair

Основные/скрытые подходы, позиции защиты, длинные и короткие перестрелки, отступление и проверенные укрытия: `PENDING_RESEARCH`/`PENDING_STUDIO`.

## Игровые точки

- Clue spots по опубликованным floor plans: **19**; сырых clue markers: **20**. Координаты всех маркеров сохранены в `points.json`; при различии значений фильтрация не выдумывается. Активные точки выбирает будущий сервер матча.
- Lair anchor: `[1457.09, 947.05, 45.15]`, возможные боссы: Assassin, Bloodskin, Butcher, Scrapbeak, Spider. Модели и AI боссов не входят в этот этап.
- NPC и звуковые ловушки ниже являются диапазонами возможных групп, а не одновременно активными спавнами.

### NPC

| Тип | Диапазон | Среднее |
|---|---:|---:|
| Grunt | 22–72 | среднее 35.6 |
| Armored | 0–8 | среднее 1.5 |
| Hive | 1–10 | среднее 3.0 |
| Hellhound | 0–6 | среднее 1.1 |
| Muzzled Hellhound | 0–3 | среднее 0.2 |
| Immolator | 0–9 | среднее 1.8 |
| Meathead | 0–1 | среднее 0.5 |

### Звуковые ловушки

| Тип | Диапазон групп |
|---|---:|
| Caged dogs & chickens | 0–2 |
| Ducks | 0–2 |
| Dying horses | 2–3 |
| Ravens | 3–4 |

## Необходимые ассеты

`PENDING_ASSET_RESEARCH`: архитектура, интерьеры, интерактивные объекты, VFX, audio и UI вносятся только после проверки прав и качества.

## Проверка

- Числовой dataset: `CONFIRMED` после unit tests.
- Геометрия, интерьеры, двери, лестницы, коллизии, StreamingEnabled, производительность и визуальное сравнение: `PENDING_STUDIO`.
- Критерии 90/100 не присваиваются на стадии референсов.
