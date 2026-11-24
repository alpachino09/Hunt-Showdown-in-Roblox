# Blackthorn Stockyard

- ID: `com_a`
- Тип: compound
- Общий статус: `REFERENCE_CONFIRMED__GEOMETRY_PENDING`
- Этажей: **2**; точек улик: **23**; логово: **Ground floor**.
- Назначение и история: `PENDING_RESEARCH`; тематическое направление ТЗ не считается подтверждённым описанием оригинала.

## Референсы

- https://hunt.innerpulse.net/maps/#mammons-gulch
- https://hunt.innerpulse.net/maps/3d/mammons-gulch/blackthorn-stockyard/

Координаты, этажи и игровые точки: `CONFIRMED` по числовым данным Hunt Almanac. Перевод в studs: `ADAPTED` (1 м = 3 studs до Studio-калибровки). Архитектурные детали без отдельного просмотра: `PENDING_RESEARCH`.

## География и границы

- Label anchor, source XY: `[678.5024, 1427.2512]`; Roblox XYZ: `[-1036.4928, 32.113226, -1209.7536]`. Это не центр масс зданий.
- Building bbox source `[minX, minY, maxX, maxY]`: `[633.9584, 1388.6464, 754.5856, 1530.7776]`.
- Полигон региона хранится в `assets/mammons-gulch/reference/layout.json`.
- Высотный профиль вне измеренных точек: `PENDING_RESEARCH` до применения heightfield.

## Этажи

| Уровень | Floor, м | Над локальной землёй, м | Cut, м | Статус |
|---|---:|---:|---:|---|
| Ground floor | 43.24 | -0.29 | 44.44 | CONFIRMED |
| Upper floor | 47.28 | 3.75 | 48.48 | CONFIRMED |

## Архитектура

Основные здания, вспомогательные сооружения, крыши, материалы и взаимное расположение: `PENDING_RESEARCH`. Greybox не является подтверждением финальной архитектуры.

## Входы, окна и вертикальные маршруты

| Тип | Измеренных точек | Статус |
|---|---:|---|
| Doors | 24 | CONFIRMED positions; назначение проёмов требует просмотра |
| Windows | 8 | CONFIRMED positions; ставни/стекло требуют просмотра |
| Ladders | 9 | CONFIRMED positions; рабочая геометрия не создана |
| Elevators | 0 | CONFIRMED positions; механизм не реализован |
| Stair flights | 13 | CONFIRMED endpoints/width; рабочая геометрия не создана |

Главные/второстепенные входы, пути проникновения, переходы между зданиями и выходы: `PENDING_RESEARCH` до разбора планов и вида по сторонам света.

## Подземные помещения

Связь с `undergroundRegions` и пещерными пустотами: `PENDING_RESEARCH`. Не объявлять подземную сеть завершённой по одним маркерам.

## Тактика и линии обзора

Источник сообщает: **Even**.

- the lair is open to the ground outside
- no hunting tower sees into it
- 45 noise traps

Основные/скрытые подходы, позиции защиты, длинные и короткие перестрелки, отступление и проверенные укрытия: `PENDING_RESEARCH`/`PENDING_STUDIO`.

## Игровые точки

- Clue spots по опубликованным floor plans: **23**; сырых clue markers: **23**. Координаты всех маркеров сохранены в `points.json`; при различии значений фильтрация не выдумывается. Активные точки выбирает будущий сервер матча.
- Lair anchor: `[678.52, 1427.21, 43.65]`, возможные боссы: Assassin, Bloodskin, Butcher, Scrapbeak, Spider. Модели и AI боссов не входят в этот этап.
- NPC и звуковые ловушки ниже являются диапазонами возможных групп, а не одновременно активными спавнами.

### NPC

| Тип | Диапазон | Среднее |
|---|---:|---:|
| Grunt | 14–58 | среднее 25.8 |
| Armored | 0–7 | среднее 1.3 |
| Hive | 0–6 | среднее 1.3 |
| Hellhound | 0–12 | среднее 1.0 |
| Muzzled Hellhound | 0–6 | среднее 0.2 |
| Immolator | 0–6 | среднее 0.7 |
| Meathead | 0–1 | среднее 0.5 |
| Water Devil | 0–1 | среднее 0.5 |

### Звуковые ловушки

| Тип | Диапазон групп |
|---|---:|
| Caged dogs & chickens | 0–1 |
| Ducks | 0–2 |
| Dying cows | 2–4 |
| Ravens | 4–4 |

## Необходимые ассеты

Кандидаты: `ph-wooden-crate-01`, `ph-wooden-barrels-01`, `ph-brown-mud-02`. Их статус и оценки находятся в `assets/mammons-gulch/asset-manifest.json`; назначение не равно одобрению или интеграции. Авторская архитектура, интерьеры, интерактивные объекты, VFX, audio и UI по-прежнему требуют референсов и Studio QA.

## Проверка

- Числовой dataset: `CONFIRMED` после unit tests.
- Геометрия, интерьеры, двери, лестницы, коллизии, StreamingEnabled, производительность и визуальное сравнение: `PENDING_STUDIO`.
- Критерии 90/100 не присваиваются на стадии референсов.
