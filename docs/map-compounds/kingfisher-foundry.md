# Kingfisher Foundry

- ID: `com_l`
- Тип: compound
- Общий статус: `REFERENCE_CONFIRMED__GEOMETRY_PENDING`
- Этажей: **2**; точек улик: **20**; логово: **Ground floor**.
- Назначение и история: `PENDING_RESEARCH`; тематическое направление ТЗ не считается подтверждённым описанием оригинала.

## Референсы

- https://hunt.innerpulse.net/maps/#mammons-gulch
- https://hunt.innerpulse.net/maps/3d/mammons-gulch/kingfisher-foundry/

Координаты, этажи и игровые точки: `CONFIRMED` по числовым данным Hunt Almanac. Перевод в studs: `ADAPTED` (1 м = 3 studs до Studio-калибровки). Архитектурные детали без отдельного просмотра: `PENDING_RESEARCH`.

## География и границы

- Label anchor, source XY: `[933.0688, 656.1792]`; Roblox XYZ: `[-272.7936, 56.599025, 1103.4624]`. Это не центр масс зданий.
- Building bbox source `[minX, minY, maxX, maxY]`: `[889.7536, 622.2848, 978.1248, 736.768]`.
- Полигон региона хранится в `assets/mammons-gulch/reference/layout.json`.
- Высотный профиль вне измеренных точек: `PENDING_RESEARCH` до применения heightfield.

## Этажи

| Уровень | Floor, м | Над локальной землёй, м | Cut, м | Статус |
|---|---:|---:|---:|---|
| Ground floor | 51.87 | -0.18 | 53.07 | CONFIRMED |
| Upper floor | 56.90 | 4.89 | 58.10 | CONFIRMED |

## Архитектура

Основные здания, вспомогательные сооружения, крыши, материалы и взаимное расположение: `PENDING_RESEARCH`. Greybox не является подтверждением финальной архитектуры.

## Входы, окна и вертикальные маршруты

| Тип | Измеренных точек | Статус |
|---|---:|---|
| Doors | 24 | CONFIRMED positions; назначение проёмов требует просмотра |
| Windows | 10 | CONFIRMED positions; ставни/стекло требуют просмотра |
| Ladders | 9 | CONFIRMED positions; рабочая геометрия не создана |
| Elevators | 0 | CONFIRMED positions; механизм не реализован |
| Stair flights | 38 | CONFIRMED endpoints/width; рабочая геометрия не создана |

Главные/второстепенные входы, пути проникновения, переходы между зданиями и выходы: `PENDING_RESEARCH` до разбора планов и вида по сторонам света.

## Подземные помещения

Связь с `undergroundRegions` и пещерными пустотами: `PENDING_RESEARCH`. Не объявлять подземную сеть завершённой по одним маркерам.

## Тактика и линии обзора

Источник сообщает: **Leans to the attackers**.

- 55 noise traps
- no hunting tower sees into it

Основные/скрытые подходы, позиции защиты, длинные и короткие перестрелки, отступление и проверенные укрытия: `PENDING_RESEARCH`/`PENDING_STUDIO`.

## Игровые точки

- Clue spots по опубликованным floor plans: **20**; сырых clue markers: **21**. Координаты всех маркеров сохранены в `points.json`; при различии значений фильтрация не выдумывается. Активные точки выбирает будущий сервер матча.
- Lair anchor: `[933.12, 656.17, 51.9]`, возможные боссы: Assassin, Bloodskin, Butcher, Scrapbeak, Spider. Модели и AI боссов не входят в этот этап.
- NPC и звуковые ловушки ниже являются диапазонами возможных групп, а не одновременно активными спавнами.

### NPC

| Тип | Диапазон | Среднее |
|---|---:|---:|
| Grunt | 14–90 | среднее 35.4 |
| Armored | 0–14 | среднее 2.4 |
| Hive | 0–11 | среднее 3.2 |
| Hellhound | 0–18 | среднее 1.4 |
| Muzzled Hellhound | 0–6 | среднее 0.2 |
| Immolator | 0–10 | среднее 1.3 |
| Meathead | 0–2 | среднее 0.2 |
| Water Devil | 0–2 | среднее 1.0 |

### Звуковые ловушки

| Тип | Диапазон групп |
|---|---:|
| Caged dogs & chickens | 0–2 |
| Ducks | 0–2 |
| Dying horses | 1–2 |
| Ravens | 4–4 |

## Необходимые ассеты

Кандидаты: `fab-old-mine`, `ph-rusty-metal-02`, `ph-wooden-crate-01`. Их статус и оценки находятся в `assets/mammons-gulch/asset-manifest.json`; назначение не равно одобрению или интеграции. Авторская архитектура, интерьеры, интерактивные объекты, VFX, audio и UI по-прежнему требуют референсов и Studio QA.

## Проверка

- Числовой dataset: `CONFIRMED` после unit tests.
- Геометрия, интерьеры, двери, лестницы, коллизии, StreamingEnabled, производительность и визуальное сравнение: `PENDING_STUDIO`.
- Критерии 90/100 не присваиваются на стадии референсов.
