# Исследование ассетов Mammon's Gulch

Дата проверки: 24.11.2026. Полная машиночитаемая запись: `assets/mammons-gulch/asset-manifest.json`.

## Метод

Просмотрены страницы и изображения Fab Old Mine и Wild West Bank, Fab EULA, Poly Haven license и списки моделей/материалов через публичный API, ambientCG license и API. Выполнены read-only поиски Creator Store `modular mine`, `western warehouse`, `industrial pipes`, `pine tree`, `rock cliff` с фильтром free/verified creators. Ничего не скачано и не вставлено в Studio на этом подэтапе.

Оценка `null` означает отсутствие достаточной проверки. Не вычисляется средний балл из незаполненных критериев. Существующие ForestSet/ForestTree имеют оценки по фактически пройденному ранее импорту; их `referenceFit` для Mammon's Gulch ещё не определён.

## Сравнение основных категорий

| Категория | Варианты | Текущее решение |
|---|---|---|
| Крупные скалы | Coastal Cliff 01/02, Rock Face 01, Namaqualand Cliff 01 | Все CC0, но геология и размер не подтверждены. Сравнить 3–4 силуэта в одном Studio-кадре до выбора. |
| Сосны и хвойные | Pine Tree 01, Fir Tree 01, существующий Tree Small 02, Creator Ponderosa | Приоритет CC0 Poly Haven. Ponderosa не вставляется: не установлен оригинальный автор и не проверен код. Нужны варианты кроны и LOD. |
| Шахтные модули | Old Mine, Creator `modular mine`, авторские модули по floor plans | Old Mine — сильный визуальный кандидат (8/10 referenceFit по странице), но требует transaction, локального FBX QA, оптимизации и запрета raw redistribution. Creator-результаты содержали не относящиеся к делу или неясные модели. |
| Западные склады/здания | Wild West Bank, Creator `western warehouse`, авторская реконструкция | Wild West Bank отклонён: EUR 2,20 и low-poly фасад. Creator-результаты нерелевантны/непроверены. Основной путь — измеренная архитектура с отдельными CC0 материалами и props. |
| Промышленные предметы | Old Mine, Creator rusty pipes, Poly Haven barrels/crates/lantern/ladder/cart | Сначала CC0 props и проверенные части Old Mine. Сторонние Roblox-модели только после provenance + descendant audit. |
| Деревянные материалы | Wood Planks Grey, Wood Peeling Paint Weathered, ambientCG Wood Siding 013 | Сравнить при одинаковой плотности текселей в day/sunset/interior. Не делать все поверхности одинаково выветренными. |
| Металл | Rusty Metal 02, Rusty Corrugated Iron, Metal Grate Rusty | Отдельные материалы для конструкций, листов и решёток; collision/alpha/audio задаёт проект. |
| Грунт | Brown Mud 02, Rocky Gravel, существующий Brown Mud Leaves 01 | Проверить влажность, tiling и масштаб у воды/дорог/рельсов. |

## Назначение по комплексам

Это список исследования, а не разрешение расставлять объекты без референса. ID соответствуют manifest.

| Комплекс | Первичные кандидаты | Обязательная авторская часть |
|---|---|---|
| Blackthorn Stockyard | ph-wooden-crate-01, ph-wooden-barrels-01, ph-brown-mud-02 | Загоны, ворота, стойла и внутренние маршруты по плану |
| The Gasworks | fab-old-mine, ph-rusty-metal-02, ph-metal-grate-rusty | Подтверждённые резервуары, трубопроводы и платформы |
| Terminus Railyard | ph-modular-wooden-pier, ph-wooden-crate-01, ph-rocky-gravel | Пути, стрелки, вагоны и погрузочная геометрия |
| Grizzly Lodge | ph-pine-tree-01, ph-fir-tree-01, ph-wood-planks-grey | Деревянная архитектура, террасы и интерьеры |
| O'Donovan Stone | ph-rock-face-01, ph-coastal-cliff-01, ph-rocky-gravel | Каменные рабочие уровни и механизмы |
| Monteros Malt | ph-wooden-barrels-01, ph-wood-peeling-paint-weathered | Производственные корпуса и зерновое оборудование |
| East Mountain Corn | ph-wood-planks-grey, ph-brown-mud-02 | Кукурузные поля и фермерские постройки; готовый кукурузный ассет ещё не выбран |
| Deadfall Timber | ph-dead-tree-trunk, ph-tree-small-02-existing, ph-wood-planks-grey | Штабели, пилорама и проходы |
| La Plata Mine | fab-old-mine, ph-rock-face-01, ph-wooden-lantern-01, ph-wooden-ladder | Эталонные этажи, шахта, соединения, коллизии и интерактивность |
| Split River Mill | ph-modular-wooden-pier, ph-wooden-lantern-01, ph-brown-mud-02 | Мосты, мельничное оборудование и водные переходы |
| Machine Gorge | fab-old-mine, ph-metal-grate-rusty, ph-rusty-corrugated-iron | Многоуровневые машины и связи через ущелье |
| Preston Oil | ph-rusty-metal-02, ph-metal-grate-rusty | Исторические вышки, насосы и резервуары; современные нефтяные модели не принимать |
| Kingfisher Foundry | fab-old-mine, ph-rusty-metal-02, ph-wooden-crate-01 | Печи, литейные пространства и производственные корпуса |
| Oro Gordo Mine | fab-old-mine, ph-rock-face-01, ph-wooden-lantern-01 | Подземные выработки, лифты и маршруты |
| Graystone Pit | ph-coastal-cliff-02, ph-rock-face-01, ph-rocky-gravel | Ступени карьера и грузовое оборудование |
| Miner's Folly | fab-old-mine, ph-pine-tree-01, ph-wood-planks-grey | Многоуровневые настилы и горные тропы |

## Технические gates перед производством

1. Подтвердить конкретную лицензию, автора, дату, разрешённые действия и локальный путь в manifest.
2. Скачивать только публично разрешённый файл или использовать доступную учётную запись без обхода авторизации. Не покупать ассеты.
3. Для Fab хранить исходный пакет вне публичного Git; в репозитории фиксировать Asset IDs и инструкции восстановления, не standalone raw content.
4. В Blender проверить transforms, scale, pivot, normals, UV, topology, материальные слоты и исходную триангулляцию. Для новых 3D-операций применять Blender QA навыки.
5. В Roblox отделить геометрию/материалы от сторонних Scripts, LocalScripts, ModuleScripts, RemoteEvents и загрузчиков. Описание «no scripts» не заменяет inspect.
6. Подготовить упрощённые коллизии, LOD/RenderFidelity и разумные размеры текстур. Не переносить 8K по умолчанию.
7. Сравнить один представительный ассет в La Plata Mine при дневном, вечернем, пасмурном и внутреннем свете. Только после этого производить семейство.
8. Записать фактические изменения, Roblox IDs, визуальные captures и измерения памяти/FPS; обновить оценки, которые были `null`.

## Текущий статус

Библиотека исследования готова для выбора эталона. Ни один новый внешний ассет не считается интегрированным или production-ready на этом подэтапе. Разрешены к повторному использованию только ранее проверенные `forest-set-existing` и `ph-tree-small-02-existing`, с учётом их отличия от живой кроны сосен.
