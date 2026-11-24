# Graystone Pit

- ID: `com_m`
- Тип: compound
- Общий статус: `REFERENCE_CONFIRMED__GEOMETRY_PENDING`
- Этажей: **2**; точек улик: **9**; логово: **Ground floor**.
- Назначение и история: `PENDING_RESEARCH`; тематическое направление ТЗ не считается подтверждённым описанием оригинала.

## Референсы

- https://hunt.innerpulse.net/maps/#mammons-gulch
- https://hunt.innerpulse.net/maps/3d/mammons-gulch/graystone-pit/

Координаты, этажи и игровые точки: `CONFIRMED` по числовым данным Hunt Almanac. Перевод в studs: `ADAPTED` (1 м = 3 studs до Studio-калибровки). Архитектурные детали без отдельного просмотра: `PENDING_RESEARCH`.

## География и границы

- Label anchor, source XY: `[1208.32, 641.536]`; Roblox XYZ: `[552.96, 69.0784, 1147.392]`. Это не центр масс зданий.
- Building bbox source `[minX, minY, maxX, maxY]`: `[1157.7344, 552.5504, 1247.3344, 708.3008]`.
- Полигон региона хранится в `assets/mammons-gulch/reference/layout.json`.
- Высотный профиль вне измеренных точек: `PENDING_RESEARCH` до применения heightfield.

## Этажи

| Уровень | Floor, м | Над локальной землёй, м | Cut, м | Статус |
|---|---:|---:|---:|---|
| Ground floor | 45.32 | 0.30 | 46.52 | CONFIRMED |
| Upper floor | 55.74 | 2.60 | 56.94 | CONFIRMED |

## Архитектура

Основные здания, вспомогательные сооружения, крыши, материалы и взаимное расположение: `PENDING_RESEARCH`. Greybox не является подтверждением финальной архитектуры.

## Входы, окна и вертикальные маршруты

| Тип | Измеренных точек | Статус |
|---|---:|---|
| Doors | 6 | CONFIRMED positions; назначение проёмов требует просмотра |
| Windows | 4 | CONFIRMED positions; ставни/стекло требуют просмотра |
| Ladders | 6 | CONFIRMED positions; рабочая геометрия не создана |
| Elevators | 4 | CONFIRMED positions; механизм не реализован |
| Stair flights | 53 | CONFIRMED endpoints/width; рабочая геометрия не создана |

Главные/второстепенные входы, пути проникновения, переходы между зданиями и выходы: `PENDING_RESEARCH` до разбора планов и вида по сторонам света.

## Подземные помещения

Связь с `undergroundRegions` и пещерными пустотами: `PENDING_RESEARCH`. Не объявлять подземную сеть завершённой по одним маркерам.

## Тактика и линии обзора

Источник сообщает: **Leans to the defenders**.

- cover on the way in: 98% of the ground 60–200 m out is out of sight of its doors and windows
- no high ground overlooks its doorways
- only 1 way in, easy to hold

Основные/скрытые подходы, позиции защиты, длинные и короткие перестрелки, отступление и проверенные укрытия: `PENDING_RESEARCH`/`PENDING_STUDIO`.

## Игровые точки

- Clue spots по опубликованным floor plans: **9**; сырых clue markers: **12**. Координаты всех маркеров сохранены в `points.json`; при различии значений фильтрация не выдумывается. Активные точки выбирает будущий сервер матча.
- Lair anchor: `[1208.29, 641.5, 45.73]`, возможные боссы: Assassin, Bloodskin, Butcher, Scrapbeak, Spider. Модели и AI боссов не входят в этот этап.
- NPC и звуковые ловушки ниже являются диапазонами возможных групп, а не одновременно активными спавнами.

### NPC

| Тип | Диапазон | Среднее |
|---|---:|---:|
| Grunt | 14–44 | среднее 22.6 |
| Armored | 0–4 | среднее 0.6 |
| Hive | 1–6 | среднее 1.8 |
| Hellhound | 0–4 | среднее 0.2 |
| Muzzled Hellhound | 0–2 | среднее 0.0 |
| Immolator | 0–4 | среднее 0.7 |
| Meathead | 0–4 | среднее 0.5 |

### Звуковые ловушки

| Тип | Диапазон групп |
|---|---:|
| Bats | 1–2 |
| Caged dogs & chickens | 0–2 |
| Ducks | 0–1 |
| Dying horses | 1–2 |
| Ravens | 4–4 |

## Необходимые ассеты

Кандидаты: `ph-coastal-cliff-02`, `ph-rock-face-01`, `ph-rocky-gravel`. Их статус и оценки находятся в `assets/mammons-gulch/asset-manifest.json`; назначение не равно одобрению или интеграции. Авторская архитектура, интерьеры, интерактивные объекты, VFX, audio и UI по-прежнему требуют референсов и Studio QA.

## Проверка

- Числовой dataset: `CONFIRMED` после unit tests.
- Геометрия, интерьеры, двери, лестницы, коллизии, StreamingEnabled, производительность и визуальное сравнение: `PENDING_STUDIO`.
- Критерии 90/100 не присваиваются на стадии референсов.
