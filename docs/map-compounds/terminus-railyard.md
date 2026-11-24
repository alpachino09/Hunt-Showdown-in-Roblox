# Terminus Railyard

- ID: `com_c`
- Тип: compound
- Общий статус: `REFERENCE_CONFIRMED__GEOMETRY_PENDING`
- Этажей: **2**; точек улик: **18**; логово: **Ground floor**.
- Назначение и история: `PENDING_RESEARCH`; тематическое направление ТЗ не считается подтверждённым описанием оригинала.

## Референсы

- https://hunt.innerpulse.net/maps/#mammons-gulch
- https://hunt.innerpulse.net/maps/3d/mammons-gulch/terminus-railyard/

Координаты, этажи и игровые точки: `CONFIRMED` по числовым данным Hunt Almanac. Перевод в studs: `ADAPTED` (1 м = 3 studs до Studio-калибровки). Архитектурные детали без отдельного просмотра: `PENDING_RESEARCH`.

## География и границы

- Label anchor, source XY: `[1404.6208, 1429.2992]`; Roblox XYZ: `[1141.8624, 39.621717, -1215.8976]`. Это не центр масс зданий.
- Building bbox source `[minX, minY, maxX, maxY]`: `[1203.6096, 1366.8352, 1442.6112, 1464.6272]`.
- Полигон региона хранится в `assets/mammons-gulch/reference/layout.json`.
- Высотный профиль вне измеренных точек: `PENDING_RESEARCH` до применения heightfield.

## Этажи

| Уровень | Floor, м | Над локальной землёй, м | Cut, м | Статус |
|---|---:|---:|---:|---|
| Ground floor | 48.10 | -0.18 | 49.30 | CONFIRMED |
| Upper floor | 52.14 | 3.94 | 53.34 | CONFIRMED |

## Архитектура

Основные здания, вспомогательные сооружения, крыши, материалы и взаимное расположение: `PENDING_RESEARCH`. Greybox не является подтверждением финальной архитектуры.

## Входы, окна и вертикальные маршруты

| Тип | Измеренных точек | Статус |
|---|---:|---|
| Doors | 48 | CONFIRMED positions; назначение проёмов требует просмотра |
| Windows | 33 | CONFIRMED positions; ставни/стекло требуют просмотра |
| Ladders | 9 | CONFIRMED positions; рабочая геометрия не создана |
| Elevators | 2 | CONFIRMED positions; механизм не реализован |
| Stair flights | 43 | CONFIRMED endpoints/width; рабочая геометрия не создана |

Главные/второстепенные входы, пути проникновения, переходы между зданиями и выходы: `PENDING_RESEARCH` до разбора планов и вида по сторонам света.

## Подземные помещения

Связь с `undergroundRegions` и пещерными пустотами: `PENDING_RESEARCH`. Не объявлять подземную сеть завершённой по одним маркерам.

## Тактика и линии обзора

Источник сообщает: **Favours the attackers**.

- 37 ways in, too many to hold
- open ground round it: only 28% of the ground 60–200 m out is out of sight of its doors and windows
- 55 noise traps

Основные/скрытые подходы, позиции защиты, длинные и короткие перестрелки, отступление и проверенные укрытия: `PENDING_RESEARCH`/`PENDING_STUDIO`.

## Игровые точки

- Clue spots по опубликованным floor plans: **18**; сырых clue markers: **19**. Координаты всех маркеров сохранены в `points.json`; при различии значений фильтрация не выдумывается. Активные точки выбирает будущий сервер матча.
- Lair anchor: `[1404.59, 1429.3, 48.15]`, возможные боссы: Assassin, Bloodskin, Butcher, Scrapbeak, Spider. Модели и AI боссов не входят в этот этап.
- NPC и звуковые ловушки ниже являются диапазонами возможных групп, а не одновременно активными спавнами.

### NPC

| Тип | Диапазон | Среднее |
|---|---:|---:|
| Grunt | 6–72 | среднее 33.6 |
| Armored | 0–20 | среднее 4.1 |
| Hive | 0–15 | среднее 4.2 |
| Hellhound | 0–28 | среднее 3.1 |
| Muzzled Hellhound | 0–7 | среднее 0.4 |
| Immolator | 0–8 | среднее 1.4 |
| Meathead | 0–2 | среднее 0.1 |

### Звуковые ловушки

| Тип | Диапазон групп |
|---|---:|
| Caged dogs & chickens | 0–2 |
| Ducks | 0–1 |
| Dying cows | 1–2 |
| Dying horses | 1–2 |
| Ravens | 3–3 |

## Необходимые ассеты

`PENDING_ASSET_RESEARCH`: архитектура, интерьеры, интерактивные объекты, VFX, audio и UI вносятся только после проверки прав и качества.

## Проверка

- Числовой dataset: `CONFIRMED` после unit tests.
- Геометрия, интерьеры, двери, лестницы, коллизии, StreamingEnabled, производительность и визуальное сравнение: `PENDING_STUDIO`.
- Критерии 90/100 не присваиваются на стадии референсов.
