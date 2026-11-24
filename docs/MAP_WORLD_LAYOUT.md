# География и координаты Mammon's Gulch

## Подтверждённая рамка

- Исходная область: **1024 × 1024 м**; source X = 512…1536, source Y = 512…1536.
- Heightfield: **513 × 513**, шаг 2 м; высоты **32.790–116.733 м**.
- Север: исходный Y уменьшается, Roblox Z уменьшается. Карта не зеркалится.
- Начальная адаптация: **1 м = 3 studs**, мир 3072 × 3072 studs. Статус: `ADAPTED` до замеров времени маршрутов.
- `WorldX = (SourceX - 1024) * 3`; `WorldY = (SourceZ - 32.79) * 3`; `WorldZ = (1024 - SourceY) * 3`.
- Label anchors не являются центрами фундамента или bbox. Границы и полигоны находятся в `layout.json`.

## Позиции комплексов

| Комплекс | ID | Map units | Source X,Y (м) | Roblox X,Z (studs) | Roblox Y по label anchor |
|---|---|---:|---:|---:|---:|
| Blackthorn Stockyard | `com_a` | 162.6, 106.2 | 678.50, 1427.25 | -1036.493, -1209.754 | 32.113 |
| Monteros Malt | `com_b` | 517.4, 276.4 | 1041.82, 1252.97 | 53.453, -686.899 | 12.684 |
| Terminus Railyard | `com_c` | 871.7, 104.2 | 1404.62, 1429.30 | 1141.862, -1215.898 | 39.622 |
| Grizzly Lodge | `com_d` | 78.9, 329.4 | 592.79, 1198.69 | -1293.619, -524.083 | 60.367 |
| O'Donovan Stone | `com_e` | 376.4, 408.7 | 897.43, 1117.49 | -379.699, -280.474 | 54.639 |
| Split River Mill | `com_f` | 592.0, 465.2 | 1118.21, 1059.64 | 282.624, -106.906 | 29.508 |
| East Mountain Corn | `com_g` | 766.0, 345.1 | 1296.38, 1182.62 | 817.152, -475.853 | 17.567 |
| Deadfall Timber | `com_h` | 108.6, 644.3 | 623.21, 876.24 | -1202.381, 443.290 | 77.222 |
| La Plata Mine | `com_i` | 446.5, 588.8 | 969.22, 933.07 | -164.352, 272.794 | 74.246 |
| Oro Gordo Mine | `com_j` | 564.5, 644.3 | 1090.05, 876.24 | 198.144, 443.290 | 98.957 |
| Machine Gorge | `com_k` | 922.9, 575.2 | 1457.05, 947.00 | 1299.149, 231.014 | 15.459 |
| Kingfisher Foundry | `com_l` | 411.2, 859.2 | 933.07, 656.18 | -272.794, 1103.462 | 56.599 |
| Graystone Pit | `com_m` | 680.0, 873.5 | 1208.32, 641.54 | 552.960, 1147.392 | 69.078 |
| The Gasworks | `poi_a` | 490.4, 39.0 | 1014.17, 1496.06 | -29.491, -1416.192 | 14.157 |
| Preston Oil | `poi_b` | 137.3, 891.3 | 652.60, 623.31 | -1114.214, 1202.074 | 61.788 |
| Miner's Folly | `poi_c` | 890.2, 788.4 | 1423.56, 728.68 | 1198.694, 885.965 | 52.453 |

## Масштаб и движение

| Величина | Значение | Статус |
|---|---:|---|
| Source map | 1024 м | CONFIRMED |
| Roblox map | 3072 studs | ADAPTED |
| Текущий WalkSpeed | 13 studs/s = 4,33 м/с | PROJECT |
| Текущий Sprint | 19 studs/s = 6,33 м/с | PROJECT |
| Референсный Sprint в Hunt Almanac | 5 м/с; после stamina 4,25 м/с | CONFIRMED reference, не новое правило проекта |
| Terrain voxel | 4 studs = 1,333 м | ADAPTED; берега и склоны требуют Studio QA |

Дороги, железная дорога, мосты и высотные связи фиксируются отдельными centerlines с confidence; до этого они не считаются готовыми.

## Текущий файловый макет

`places/mammons-gulch.project.json` создаёт отдельный development Place. Все 16 compounds находятся в `Workspace/Maps/MammonsGulch/Compounds` на координатах из таблицы. Region boundaries повторяют исходные полигоны; `ReferenceMassing` использует измеренные bbox и число этажей, но не подтверждённые фасады. Его статус — `APPROXIMATED`, не финальная архитектура.

Глобальные gameplay markers находятся в корневых папках и не дублируются внутри compounds. Из 42 спавнов только один `DevelopmentSpawn` активен для QA. Восстановление и владельцы описаны в `docs/MAP_RECONSTRUCTION.md`.

## Транспортный каркас

`reference/routes.json` содержит `western_spine`, `central_spine`, `eastern_spine`, `west_east_links`, `northern_links`, `main_north_south_rail`, `kingfisher_trestle` и `northern_river_bridge`. Все centerlines имеют `APPROXIMATED`, а не выдуманный `CONFIRMED`. Сегмент `kingfisher_trestle` дополнительно опирается на измеренные metal boxes; его идентификатор исправлен после визуальной проверки.

Solo Play подтвердил collision дороги, railbed, deck и underground floor. [Кадр](images/map/mammons-gulch-routes-overview.jpg). Точная геометрия троп, вагонов и полная оригинальная топология шахт остаются последующей детализацией.
