# La Plata Mine

- ID: `com_i`
- Тип: compound
- Общий статус: `REFERENCE_CONFIRMED__GEOMETRY_PENDING`
- Этажей: **4**; точек улик: **10**; логово: **Upper floor**.
- Назначение и история: `PENDING_RESEARCH`; тематическое направление ТЗ не считается подтверждённым описанием оригинала.

## Референсы

- https://hunt.innerpulse.net/maps/#mammons-gulch
- https://hunt.innerpulse.net/maps/3d/mammons-gulch/la-plata-mine/

Координаты, этажи и игровые точки: `CONFIRMED` по числовым данным Hunt Almanac. Перевод в studs: `ADAPTED` (1 м = 3 studs до Studio-калибровки). Архитектурные детали без отдельного просмотра: `PENDING_RESEARCH`.

## География и границы

- Label anchor, source XY: `[969.216, 933.0688]`; Roblox XYZ: `[-164.352, 74.246159, 272.7936]`. Это не центр масс зданий.
- Building bbox source `[minX, minY, maxX, maxY]`: `[917.8112, 909.1072, 1008.5376, 988.9792]`.
- Полигон региона хранится в `assets/mammons-gulch/reference/layout.json`.
- Высотный профиль вне измеренных точек: `PENDING_RESEARCH` до применения heightfield.

## Этажи

| Уровень | Floor, м | Над локальной землёй, м | Cut, м | Статус |
|---|---:|---:|---:|---|
| Ground floor | 52.37 | 0.61 | 53.57 | CONFIRMED |
| Upper floor | 57.39 | 4.41 | 58.59 | CONFIRMED |
| Upper floor 2 | 59.30 | 6.09 | 60.50 | CONFIRMED |
| Upper floor 3 | 65.82 | 8.03 | 67.02 | CONFIRMED |

## Архитектура

Основные здания, вспомогательные сооружения, крыши, материалы и взаимное расположение: `PENDING_RESEARCH`. Greybox не является подтверждением финальной архитектуры.

## Входы, окна и вертикальные маршруты

| Тип | Измеренных точек | Статус |
|---|---:|---|
| Doors | 10 | CONFIRMED positions; назначение проёмов требует просмотра |
| Windows | 18 | CONFIRMED positions; ставни/стекло требуют просмотра |
| Ladders | 3 | CONFIRMED positions; рабочая геометрия не создана |
| Elevators | 1 | CONFIRMED positions; механизм не реализован |
| Stair flights | 50 | CONFIRMED endpoints/width; рабочая геометрия не создана |

Главные/второстепенные входы, пути проникновения, переходы между зданиями и выходы: `PENDING_RESEARCH` до разбора планов и вида по сторонам света.

## Подземные помещения

Связь с `undergroundRegions` и пещерными пустотами: `PENDING_RESEARCH`. Не объявлять подземную сеть завершённой по одним маркерам.

## Тактика и линии обзора

Источник сообщает: **Leans to the defenders**.

- cover on the way in: 80% of the ground 60–200 m out is out of sight of its doors and windows
- about 11 groups of alarm animals round it
- only 6 ways in, easy to hold

Основные/скрытые подходы, позиции защиты, длинные и короткие перестрелки, отступление и проверенные укрытия: `PENDING_RESEARCH`/`PENDING_STUDIO`.

## Игровые точки

- Clue spots по опубликованным floor plans: **10**; сырых clue markers: **12**. Координаты всех маркеров сохранены в `points.json`; при различии значений фильтрация не выдумывается. Активные точки выбирает будущий сервер матча.
- Lair anchor: `[969.26, 933.06, 58.39]`, возможные боссы: Assassin, Bloodskin, Butcher, Scrapbeak, Spider. Модели и AI боссов не входят в этот этап.
- NPC и звуковые ловушки ниже являются диапазонами возможных групп, а не одновременно активными спавнами.

### NPC

| Тип | Диапазон | Среднее |
|---|---:|---:|
| Grunt | 12–78 | среднее 31.9 |
| Armored | 0–14 | среднее 2.3 |
| Hive | 0–8 | среднее 2.0 |
| Hellhound | 0–8 | среднее 0.5 |
| Muzzled Hellhound | 0–3 | среднее 0.1 |
| Immolator | 0–8 | среднее 1.2 |
| Meathead | 0–2 | среднее 0.2 |
| Water Devil | 0–2 | среднее 1.1 |

### Звуковые ловушки

| Тип | Диапазон групп |
|---|---:|
| Bats | 1–3 |
| Caged dogs & chickens | 0–2 |
| Ducks | 2–2 |
| Dying cows | 0–1 |
| Dying horses | 1–2 |
| Ravens | 4–4 |

## Необходимые ассеты

`PENDING_ASSET_RESEARCH`: архитектура, интерьеры, интерактивные объекты, VFX, audio и UI вносятся только после проверки прав и качества.

## Проверка

- Числовой dataset: `CONFIRMED` после unit tests.
- Геометрия, интерьеры, двери, лестницы, коллизии, StreamingEnabled, производительность и визуальное сравнение: `PENDING_STUDIO`.
- Критерии 90/100 не присваиваются на стадии референсов.
