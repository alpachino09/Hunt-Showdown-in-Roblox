# Oro Gordo Mine

- ID: `com_j`
- Тип: compound
- Общий статус: `REFERENCE_CONFIRMED__GEOMETRY_PENDING`
- Этажей: **4**; точек улик: **18**; логово: **Lower tunnels**.
- Назначение и история: `PENDING_RESEARCH`; тематическое направление ТЗ не считается подтверждённым описанием оригинала.

## Референсы

- https://hunt.innerpulse.net/maps/#mammons-gulch
- https://hunt.innerpulse.net/maps/3d/mammons-gulch/oro-gordo-mine/

Координаты, этажи и игровые точки: `CONFIRMED` по числовым данным Hunt Almanac. Перевод в studs: `ADAPTED` (1 м = 3 studs до Studio-калибровки). Архитектурные детали без отдельного просмотра: `PENDING_RESEARCH`.

## География и границы

- Label anchor, source XY: `[1090.048, 876.2368]`; Roblox XYZ: `[198.144, 98.956736, 443.2896]`. Это не центр масс зданий.
- Building bbox source `[minX, minY, maxX, maxY]`: `[1071.7184, 846.6432, 1168.0768, 922.0096]`.
- Полигон региона хранится в `assets/mammons-gulch/reference/layout.json`.
- Высотный профиль вне измеренных точек: `PENDING_RESEARCH` до применения heightfield.

## Этажи

| Уровень | Floor, м | Над локальной землёй, м | Cut, м | Статус |
|---|---:|---:|---:|---|
| Ground floor | 52.47 | -0.10 | 53.67 | CONFIRMED |
| Lower tunnels | 61.01 | -18.61 | 62.21 | CONFIRMED |
| Tunnels | 66.79 | -26.21 | 67.99 | CONFIRMED |
| Upper tunnels | 68.80 | -26.06 | 70.00 | CONFIRMED |

## Архитектура

Основные здания, вспомогательные сооружения, крыши, материалы и взаимное расположение: `PENDING_RESEARCH`. Greybox не является подтверждением финальной архитектуры.

## Входы, окна и вертикальные маршруты

| Тип | Измеренных точек | Статус |
|---|---:|---|
| Doors | 24 | CONFIRMED positions; назначение проёмов требует просмотра |
| Windows | 14 | CONFIRMED positions; ставни/стекло требуют просмотра |
| Ladders | 8 | CONFIRMED positions; рабочая геометрия не создана |
| Elevators | 5 | CONFIRMED positions; механизм не реализован |
| Stair flights | 44 | CONFIRMED endpoints/width; рабочая геометрия не создана |

Главные/второстепенные входы, пути проникновения, переходы между зданиями и выходы: `PENDING_RESEARCH` до разбора планов и вида по сторонам света.

## Подземные помещения

Связь с `undergroundRegions` и пещерными пустотами: `PENDING_RESEARCH`. Не объявлять подземную сеть завершённой по одним маркерам.

## Тактика и линии обзора

Источник сообщает: **Leans to the defenders**.

- cover on the way in: 83% of the ground 60–200 m out is out of sight of its doors and windows
- 55 noise traps
- only 10 ways in, easy to hold

Основные/скрытые подходы, позиции защиты, длинные и короткие перестрелки, отступление и проверенные укрытия: `PENDING_RESEARCH`/`PENDING_STUDIO`.

## Игровые точки

- Clue spots по опубликованным floor plans: **18**; сырых clue markers: **22**. Координаты всех маркеров сохранены в `points.json`; при различии значений фильтрация не выдумывается. Активные точки выбирает будущий сервер матча.
- Lair anchor: `[1090.02, 876.29, 64.81]`, возможные боссы: Assassin, Bloodskin, Butcher, Scrapbeak, Spider. Модели и AI боссов не входят в этот этап.
- NPC и звуковые ловушки ниже являются диапазонами возможных групп, а не одновременно активными спавнами.

### NPC

| Тип | Диапазон | Среднее |
|---|---:|---:|
| Grunt | 10–70 | среднее 28.3 |
| Armored | 0–14 | среднее 3.5 |
| Hive | 1–8 | среднее 2.4 |
| Hellhound | 0–10 | среднее 1.3 |
| Muzzled Hellhound | 0–4 | среднее 0.2 |
| Immolator | 0–5 | среднее 1.1 |
| Meathead | 0–2 | среднее 0.6 |

### Звуковые ловушки

| Тип | Диапазон групп |
|---|---:|
| Bats | 2–4 |
| Caged dogs & chickens | 0–2 |
| Dying horses | 1–2 |
| Ravens | 4–4 |

## Необходимые ассеты

`PENDING_ASSET_RESEARCH`: архитектура, интерьеры, интерактивные объекты, VFX, audio и UI вносятся только после проверки прав и качества.

## Проверка

- Числовой dataset: `CONFIRMED` после unit tests.
- Геометрия, интерьеры, двери, лестницы, коллизии, StreamingEnabled, производительность и визуальное сравнение: `PENDING_STUDIO`.
- Критерии 90/100 не присваиваются на стадии референсов.
