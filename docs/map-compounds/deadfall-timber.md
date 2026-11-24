# Deadfall Timber

- ID: `com_h`
- Тип: compound
- Общий статус: `REFERENCE_CONFIRMED__GEOMETRY_PENDING`
- Этажей: **2**; точек улик: **12**; логово: **Ground floor**.
- Назначение и история: `PENDING_RESEARCH`; тематическое направление ТЗ не считается подтверждённым описанием оригинала.

## Референсы

- https://hunt.innerpulse.net/maps/#mammons-gulch
- https://hunt.innerpulse.net/maps/3d/mammons-gulch/deadfall-timber/

Координаты, этажи и игровые точки: `CONFIRMED` по числовым данным Hunt Almanac. Перевод в studs: `ADAPTED` (1 м = 3 studs до Studio-калибровки). Архитектурные детали без отдельного просмотра: `PENDING_RESEARCH`.

## География и границы

- Label anchor, source XY: `[623.2064, 876.2368]`; Roblox XYZ: `[-1202.3808, 77.221901, 443.2896]`. Это не центр масс зданий.
- Building bbox source `[minX, minY, maxX, maxY]`: `[590.848, 859.5456, 669.7984, 959.7952]`.
- Полигон региона хранится в `assets/mammons-gulch/reference/layout.json`.
- Высотный профиль вне измеренных точек: `PENDING_RESEARCH` до применения heightfield.

## Этажи

| Уровень | Floor, м | Над локальной землёй, м | Cut, м | Статус |
|---|---:|---:|---:|---|
| Ground floor | 57.17 | -0.58 | 58.37 | CONFIRMED |
| Upper floor | 62.24 | 3.56 | 63.44 | CONFIRMED |

## Архитектура

Основные здания, вспомогательные сооружения, крыши, материалы и взаимное расположение: `PENDING_RESEARCH`. Greybox не является подтверждением финальной архитектуры.

## Входы, окна и вертикальные маршруты

| Тип | Измеренных точек | Статус |
|---|---:|---|
| Doors | 18 | CONFIRMED positions; назначение проёмов требует просмотра |
| Windows | 16 | CONFIRMED positions; ставни/стекло требуют просмотра |
| Ladders | 5 | CONFIRMED positions; рабочая геометрия не создана |
| Elevators | 0 | CONFIRMED positions; механизм не реализован |
| Stair flights | 19 | CONFIRMED endpoints/width; рабочая геометрия не создана |

Главные/второстепенные входы, пути проникновения, переходы между зданиями и выходы: `PENDING_RESEARCH` до разбора планов и вида по сторонам света.

## Подземные помещения

Связь с `undergroundRegions` и пещерными пустотами: `PENDING_RESEARCH`. Не объявлять подземную сеть завершённой по одним маркерам.

## Тактика и линии обзора

Источник сообщает: **Leans to the defenders**.

- cover on the way in: 65% of the ground 60–200 m out is out of sight of its doors and windows
- no high ground overlooks its doorways
- only 10 ways in, easy to hold

Основные/скрытые подходы, позиции защиты, длинные и короткие перестрелки, отступление и проверенные укрытия: `PENDING_RESEARCH`/`PENDING_STUDIO`.

## Игровые точки

- Clue spots по опубликованным floor plans: **12**; сырых clue markers: **17**. Координаты всех маркеров сохранены в `points.json`; при различии значений фильтрация не выдумывается. Активные точки выбирает будущий сервер матча.
- Lair anchor: `[623.2, 876.26, 58.81]`, возможные боссы: Assassin, Bloodskin, Butcher, Scrapbeak, Spider. Модели и AI боссов не входят в этот этап.
- NPC и звуковые ловушки ниже являются диапазонами возможных групп, а не одновременно активными спавнами.

### NPC

| Тип | Диапазон | Среднее |
|---|---:|---:|
| Grunt | 8–88 | среднее 33.1 |
| Armored | 0–17 | среднее 3.2 |
| Hive | 0–11 | среднее 2.9 |
| Hellhound | 0–10 | среднее 0.6 |
| Muzzled Hellhound | 0–5 | среднее 0.1 |
| Immolator | 0–9 | среднее 1.2 |
| Meathead | 0–2 | среднее 0.4 |
| Water Devil | 0–1 | среднее 0.5 |

### Звуковые ловушки

| Тип | Диапазон групп |
|---|---:|
| Caged dogs & chickens | 0–2 |
| Dying cows | 1–2 |
| Dying horses | 1–2 |
| Ravens | 4–4 |

## Необходимые ассеты

`PENDING_ASSET_RESEARCH`: архитектура, интерьеры, интерактивные объекты, VFX, audio и UI вносятся только после проверки прав и качества.

## Проверка

- Числовой dataset: `CONFIRMED` после unit tests.
- Геометрия, интерьеры, двери, лестницы, коллизии, StreamingEnabled, производительность и визуальное сравнение: `PENDING_STUDIO`.
- Критерии 90/100 не присваиваются на стадии референсов.
