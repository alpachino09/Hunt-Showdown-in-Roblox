# Библиотека ассетов

| Ассет | Источник | Использование |
|---|---|---|
| Железнодорожный пост, мебель, лампы | Оригинальная процедурная геометрия в `scripts/generate_lobby.py`, встроенные материалы Roblox | Сцена лобби |
| Элиас Рид | Авторский временный манекен из деталей Roblox. Геометрия в `scripts/generate_lobby.py`, анимация в `src/client/StationView.luau` | Витрина охотника |
| Меню лобби | Исходник интерфейса в `scripts/generate_lobby.py`, встроенные шрифты Roblox | Лобби |
| Перегон, шахтная контора, рельсы, лес | Оригинальная карта из `scripts/generate_lobby.py`, встроенные материалы Roblox | Игровой прототип |

Сборка не требует сторонних Roblox Asset ID. Для будущих внешних материалов фиксировать источник, автора, права использования, идентификатор Roblox и путь к разрешённому исходнику.

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

Пакет движений [Universal Animation Library Standard](https://opengameart.org/content/universal-animation-library), Quaternius, CC0 1.0. Исходный GLB и адаптация девяти клипов сохранены в `assets/animations/Locomotion`. [Лицензия CC0](https://creativecommons.org/publicdomain/zero/1.0/)

Винтовка на стенде использует пять авторских мешей реквизита из комплекта витрины `HunterSet.glb`. Короткий реквизит собран из декоративных деталей Roblox в `scripts/generate_hunter_lab.py`. Всё используется как визуальные объекты.

`VeteranSeams.glb` и `VeteranFace.glb` содержат авторские штанины и вставки с весами, а также бороду и волосы. Для ткани повторно использованы карты Fabric012. Карты, размеры и идентификаторы импортированных мешей указаны в `roblox-assets.json`, `seam-assets.json` и `face-assets.json`.
