# Библиотека ассетов

| Ассет | Источник | Использование |
|---|---|---|
| Железнодорожный пост, мебель, лампы | Оригинальная процедурная геометрия в `scripts/generate_lobby.py`, встроенные материалы Roblox | Сцена лобби |
| Элиас Рид | Авторский временный манекен из деталей Roblox. Геометрия в `scripts/generate_lobby.py`, анимация в `src/client/StationView.luau` | Витрина охотника |
| Меню лобби | Исходник интерфейса в `scripts/generate_lobby.py`, встроенные шрифты Roblox | Лобби |
| Перегон, шахтная контора, рельсы, лес | Оригинальная карта из `scripts/generate_lobby.py`, встроенные материалы Roblox | Игровой прототип |

Импортированные модели используют ID, привязанные к перечисленным исходникам. Для внешних материалов фиксируются источник, автор, права использования, идентификатор Roblox и путь к разрешённому исходнику.

## Лесная застава

Подготовленный комплект с геометрией, UV и картами материалов хранится в `assets/lobby/ForestSet.glb`. Исходники имеют лицензию [CC0 Poly Haven](https://polyhaven.com/license). Комплект содержит следующие адаптации.

| Объект | Модель и автор | Треугольники |
|---|---|---:|
| FallenTrunk | [Dead Tree Trunk](https://polyhaven.com/a/dead_tree_trunk), Rob Tuytel | 3199 |
| SplitStump | [Tree Stump 01](https://polyhaven.com/a/tree_stump_01), Rob Tuytel | 2199 |
| MossRockA, MossRockB | [Rock Moss Set 01](https://polyhaven.com/a/rock_moss_set_01), Kless Gyzen | 999 каждый |
| DryBrush | [Dry Branches Medium 01](https://polyhaven.com/a/dry_branches_medium_01), Rico Cilliers | 1499 |
| SnagBranches | [Dead Quiver Branch 01](https://polyhaven.com/a/dead_quiver_branch_01), Greg Zaal и Jenelle van Heerden | 1400 |
| FreightCrate | [Wooden Crate 01](https://polyhaven.com/a/wooden_crate_01), James Ray Cock | 2600 |
| MuddyTrail | Авторский рельеф, материал [Brown Mud Leaves 01](https://polyhaven.com/a/brown_mud_leaves_01), Rob Tuytel | 7938 |
| ForestTree1, ForestTree2 | [Tree Small 02](https://polyhaven.com/a/tree_small_02), Rico Cilliers, CC0 | 4249 + 4250 |

`ForestTree.glb` сохраняет ствол и ветви с картами материалов. Листва исключена для силуэта сухостоя. Связь между деталями и их Roblox ID хранится в `tree-assets.json`.

## Витрина Элиаса Рида

Анатомическая сетка лица адаптирована из [MakeHuman HM08](https://github.com/makehumancommunity/makehuman/blob/master/makehuman/data/3dobjs/base.obj), [CC0](https://github.com/makehumancommunity/makehuman/blob/master/LICENSE.md). Пальто, жилет, ремни, сапоги, головной убор и сценический реквизит смоделированы для «Серой заставы». В `HunterSet.glb` 32 меша, 13 440 треугольников. Отдельные Roblox ID хранятся в `hunter-assets.json`. Для лица использована CC0-карта [Old Caucasian Male из MakeHuman System Assets](https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html). Из атласа оставлены только участки, используемые сеткой головы. Ткань адаптирована из [Fabric012, ambientCG](https://ambientcg.com/view?id=Fabric012), CC0, Lennart Demes. Карты ткани и лица встроены в GLB и заведены в `SurfaceAppearance`. Кожа сапог, дерево и металл реквизита используют встроенные материалы Roblox.

## Игровой R15-ветеран

В `assets/characters/Veteran` хранится оригинальная стилизованная геометрия, ремни и голова. Пакет `VeteranStudio.glb` объединяет 64 меша с шестью запечёнными текстурами до 1024 px. Ткань использует адаптированные карты [Fabric012, ambientCG, CC0](https://ambientcg.com/view?id=Fabric012). Перчатки, сапоги и ремни используют карты [Fabric Leather 01, Poly Haven, Rob Tuytel, CC0](https://polyhaven.com/a/fabric_leather_01).

Пакет движений Quaternius, CC0 1.0. Исходный GLB и адаптация двенадцати клипов сохранены в `assets/animations/Locomotion`. В их числе три клипа взаимодействия для стенда. [Universal Animation Library Standard](https://opengameart.org/content/universal-animation-library) · [Лицензия CC0](https://creativecommons.org/publicdomain/zero/1.0/)

Винтовка на стенде использует пять авторских мешей реквизита из комплекта витрины `HunterSet.glb`. Короткий реквизит собран из декоративных деталей Roblox в `scripts/generate_hunter_lab.py`. Всё используется как визуальные объекты.

`VeteranSeams.glb` и `VeteranFace.glb` содержат авторские штанины и вставки с весами, а также бороду и волосы. Для ткани повторно использованы карты Fabric012. Карты, размеры и идентификаторы импортированных мешей указаны в `roblox-assets.json`, `seam-assets.json` и `face-assets.json`.

Для Марты Вейл подготовлен авторский пакет `assets/characters/Tracker/FrontierTracker.glb` с 21 мешем и 5312 треугольниками. Лицо, причёска, кепи, короткие полы куртки и комплект карты смоделированы в Blender. Совместимые части рига, обувь и материалы наследуются из комплекта Элиаса. Импортированные идентификаторы хранятся рядом с GLB в `roblox-assets.json`.

`assets/characters/Marshal/ExMarshal.glb` содержит 21 авторский меш и 6292 треугольника. У Шоу отдельные лицо, шляпа, накидка, длинные полы плаща и знак горной службы. Повторно использованы карты ткани и кожи Элиаса. Идентификаторы и параметры посадки записаны в папке `Marshal`.

`assets/characters/Occult/OccultHunter.glb` содержит 15 авторских мешей и 4304 треугольника. Для Смотрителя сделаны дождевой капюшон с простроченным краем, кожаная полумаска, бронзовые знаки и поясная сумка. Плащ повторно использует карты Fabric012, маска и сумка используют Fabric Leather 01.

## Числовые референсы Mammon's Gulch

`assets/mammons-gulch/reference` содержит измерения положения, высот, границ и игровых точек из [Hunt Almanac](https://hunt.innerpulse.net/maps/mammons-gulch/) для игровой сборки 2.9.1.39. Условия использования данных и требование указания источника: [Developer terms](https://hunt.innerpulse.net/developers/). URL и SHA-256 ответов зафиксированы в `source.json`.

Это числовые референсные данные, а не готовые модели или текстуры. Оригинальные изображения, меши, UV, карты материалов и исходники Crytek в репозиторий не включены. Права на Hunt: Showdown и его игровые ассеты принадлежат Crytek; Hunt Almanac является неофициальным справочником.
