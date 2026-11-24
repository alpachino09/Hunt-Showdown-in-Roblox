# O'Donovan Stone

- ID: `com_e`
- Тип: compound
- Общий статус: `REFERENCE_CONFIRMED__GEOMETRY_PENDING`
- Этажей: **4**; точек улик: **13**; логово: **Upper ground floor**.
- Назначение и история: `PENDING_RESEARCH`; тематическое направление ТЗ не считается подтверждённым описанием оригинала.

## Референсы

- https://hunt.innerpulse.net/maps/#mammons-gulch
- https://hunt.innerpulse.net/maps/3d/mammons-gulch/odonovan-stone/

Координаты, этажи и игровые точки: `CONFIRMED` по числовым данным Hunt Almanac. Перевод в studs: `ADAPTED` (1 м = 3 studs до Studio-калибровки). Архитектурные детали без отдельного просмотра: `PENDING_RESEARCH`.

## География и границы

- Label anchor, source XY: `[897.4336, 1117.4912]`; Roblox XYZ: `[-379.6992, 54.638843, -280.4736]`. Это не центр масс зданий.
- Building bbox source `[minX, minY, maxX, maxY]`: `[877.7728, 1102.4384, 948.0192, 1161.6256]`.
- Полигон региона хранится в `assets/mammons-gulch/reference/layout.json`.
- Высотный профиль вне измеренных точек: `PENDING_RESEARCH` до применения heightfield.

## Этажи

| Уровень | Floor, м | Над локальной землёй, м | Cut, м | Статус |
|---|---:|---:|---:|---|
| Lower ground floor | 51.55 | -0.42 | 52.75 | CONFIRMED |
| Upper ground floor | 55.26 | 1.33 | 56.46 | CONFIRMED |
| Upper floor | 59.38 | 3.53 | 60.58 | CONFIRMED |
| Upper floor 2 | 67.09 | 10.32 | 68.29 | CONFIRMED |

## Архитектура

Основные здания, вспомогательные сооружения, крыши, материалы и взаимное расположение: `PENDING_RESEARCH`. Greybox не является подтверждением финальной архитектуры.

## Входы, окна и вертикальные маршруты

| Тип | Измеренных точек | Статус |
|---|---:|---|
| Doors | 23 | CONFIRMED positions; назначение проёмов требует просмотра |
| Windows | 20 | CONFIRMED positions; ставни/стекло требуют просмотра |
| Ladders | 5 | CONFIRMED positions; рабочая геометрия не создана |
| Elevators | 0 | CONFIRMED positions; механизм не реализован |
| Stair flights | 55 | CONFIRMED endpoints/width; рабочая геометрия не создана |

Главные/второстепенные входы, пути проникновения, переходы между зданиями и выходы: `PENDING_RESEARCH` до разбора планов и вида по сторонам света.

## Подземные помещения

Связь с `undergroundRegions` и пещерными пустотами: `PENDING_RESEARCH`. Не объявлять подземную сеть завершённой по одним маркерам.

## Тактика и линии обзора

Источник сообщает: **Favours the attackers**.

- 4 hunting towers see into its doorways
- cover on the way in: 67% of the ground 60–200 m out is out of sight of its doors and windows
- about 10 groups of alarm animals round it

Основные/скрытые подходы, позиции защиты, длинные и короткие перестрелки, отступление и проверенные укрытия: `PENDING_RESEARCH`/`PENDING_STUDIO`.

## Игровые точки

- Clue spots по опубликованным floor plans: **13**; сырых clue markers: **18**. Координаты всех маркеров сохранены в `points.json`; при различии значений фильтрация не выдумывается. Активные точки выбирает будущий сервер матча.
- Lair anchor: `[897.4, 1117.51, 55.26]`, возможные боссы: Assassin, Bloodskin, Butcher, Scrapbeak, Spider. Модели и AI боссов не входят в этот этап.
- NPC и звуковые ловушки ниже являются диапазонами возможных групп, а не одновременно активными спавнами.

### NPC

| Тип | Диапазон | Среднее |
|---|---:|---:|
| Grunt | 10–58 | среднее 24.2 |
| Armored | 0–11 | среднее 1.9 |
| Hive | 0–6 | среднее 2.0 |
| Hellhound | 0–12 | среднее 1.1 |
| Muzzled Hellhound | 0–6 | среднее 0.2 |
| Immolator | 0–6 | среднее 0.9 |
| Meathead | 0–2 | среднее 0.1 |
| Water Devil | 0–2 | среднее 0.9 |

### Звуковые ловушки

| Тип | Диапазон групп |
|---|---:|
| Bats | 1–3 |
| Caged dogs & chickens | 0–2 |
| Ducks | 0–2 |
| Dying cows | 1–1 |
| Dying horses | 1–2 |
| Ravens | 3–3 |

## Необходимые ассеты

Кандидаты: `ph-rock-face-01`, `ph-coastal-cliff-01`, `ph-rocky-gravel`. Их статус и оценки находятся в `assets/mammons-gulch/asset-manifest.json`; назначение не равно одобрению или интеграции. Авторская архитектура, интерьеры, интерактивные объекты, VFX, audio и UI по-прежнему требуют референсов и Studio QA.

## Проверка

- Числовой dataset: `CONFIRMED` после unit tests.
- Геометрия, интерьеры, двери, лестницы, коллизии, StreamingEnabled, производительность и визуальное сравнение: `PENDING_STUDIO`.
- Критерии 90/100 не присваиваются на стадии референсов.
