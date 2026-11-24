# Preston Oil

- ID: `poi_b`
- Тип: point of interest
- Общий статус: `REFERENCE_CONFIRMED__GEOMETRY_PENDING`
- Этажей: **2**; точек улик: **15**; логово: **Upper floor**.
- Назначение и история: `PENDING_RESEARCH`; тематическое направление ТЗ не считается подтверждённым описанием оригинала.

## Референсы

- https://hunt.innerpulse.net/maps/#mammons-gulch
- https://hunt.innerpulse.net/maps/3d/mammons-gulch/preston-oil/

Координаты, этажи и игровые точки: `CONFIRMED` по числовым данным Hunt Almanac. Перевод в studs: `ADAPTED` (1 м = 3 studs до Studio-калибровки). Архитектурные детали без отдельного просмотра: `PENDING_RESEARCH`.

## География и границы

- Label anchor, source XY: `[652.5952, 623.3088]`; Roblox XYZ: `[-1114.2144, 61.787741, 1202.0736]`. Это не центр масс зданий.
- Building bbox source `[minX, minY, maxX, maxY]`: `[555.3152, 527.1552, 738.7136, 712.3968]`.
- Полигон региона хранится в `assets/mammons-gulch/reference/layout.json`.
- Высотный профиль вне измеренных точек: `PENDING_RESEARCH` до применения heightfield.

## Этажи

| Уровень | Floor, м | Над локальной землёй, м | Cut, м | Статус |
|---|---:|---:|---:|---|
| Ground floor | 51.45 | -0.70 | 52.65 | CONFIRMED |
| Upper floor | 56.95 | 3.37 | 58.15 | CONFIRMED |

## Архитектура

Основные здания, вспомогательные сооружения, крыши, материалы и взаимное расположение: `PENDING_RESEARCH`. Greybox не является подтверждением финальной архитектуры.

## Входы, окна и вертикальные маршруты

| Тип | Измеренных точек | Статус |
|---|---:|---|
| Doors | 23 | CONFIRMED positions; назначение проёмов требует просмотра |
| Windows | 9 | CONFIRMED positions; ставни/стекло требуют просмотра |
| Ladders | 14 | CONFIRMED positions; рабочая геометрия не создана |
| Elevators | 1 | CONFIRMED positions; механизм не реализован |
| Stair flights | 34 | CONFIRMED endpoints/width; рабочая геометрия не создана |

Главные/второстепенные входы, пути проникновения, переходы между зданиями и выходы: `PENDING_RESEARCH` до разбора планов и вида по сторонам света.

## Подземные помещения

Связь с `undergroundRegions` и пещерными пустотами: `PENDING_RESEARCH`. Не объявлять подземную сеть завершённой по одним маркерам.

## Тактика и линии обзора

Источник сообщает: **Favours the defenders**.

- no hunting tower sees into it
- 48 noise traps
- only 13 ways in, easy to hold

Основные/скрытые подходы, позиции защиты, длинные и короткие перестрелки, отступление и проверенные укрытия: `PENDING_RESEARCH`/`PENDING_STUDIO`.

## Игровые точки

- Clue spots по опубликованным floor plans: **15**; сырых clue markers: **18**. Координаты всех маркеров сохранены в `points.json`; при различии значений фильтрация не выдумывается. Активные точки выбирает будущий сервер матча.
- Lair anchor: `[652.6, 623.32, 57.61]`, возможные боссы: Assassin, Bloodskin, Butcher, Scrapbeak, Spider. Модели и AI боссов не входят в этот этап.
- NPC и звуковые ловушки ниже являются диапазонами возможных групп, а не одновременно активными спавнами.

### NPC

| Тип | Диапазон | Среднее |
|---|---:|---:|
| Grunt | 12–62 | среднее 30.3 |
| Armored | 0–8 | среднее 1.6 |
| Hive | 0–6 | среднее 1.6 |
| Hellhound | 0–8 | среднее 0.4 |
| Muzzled Hellhound | 0–2 | среднее 0.1 |
| Immolator | 0–2 | среднее 0.1 |
| Meathead | 0–2 | среднее 0.2 |
| Water Devil | 0–2 | среднее 0.9 |

### Звуковые ловушки

| Тип | Диапазон групп |
|---|---:|
| Caged dogs & chickens | 0–2 |
| Ducks | 0–2 |
| Dying cows | 0–1 |
| Dying horses | 1–2 |
| Ravens | 4–4 |

## Необходимые ассеты

`PENDING_ASSET_RESEARCH`: архитектура, интерьеры, интерактивные объекты, VFX, audio и UI вносятся только после проверки прав и качества.

## Проверка

- Числовой dataset: `CONFIRMED` после unit tests.
- Геометрия, интерьеры, двери, лестницы, коллизии, StreamingEnabled, производительность и визуальное сравнение: `PENDING_STUDIO`.
- Критерии 90/100 не присваиваются на стадии референсов.
