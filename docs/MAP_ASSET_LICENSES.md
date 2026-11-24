# Лицензии и происхождение ассетов карты

Дата проверки: 24.11.2026. Нормативная запись для каждого кандидата находится в `assets/mammons-gulch/asset-manifest.json` и содержит десять критериев оценки, источник, автора, лицензию, разрешённые действия, путь, модификации, security status и примечания.

## Правила по источникам

### Poly Haven и ambientCG

[Poly Haven license](https://polyhaven.com/license) и [ambientCG license](https://docs.ambientcg.com/license/) подтверждают CC0: коммерческое использование, изменение, встраивание в Roblox, хранение raw files и повторное распространение разрешены. Авторство не обязательно, но сохраняется в manifest. Публичный API используется без превышения ограничений; страница сайта и её оформление не копируются как ассет.

### Fab Standard License

[Fab EULA](https://www.fab.com/eula) разрешает коммерческие/частные проекты, модификацию, совместимые инструменты (не только Unreal) и распространение проекта с встроенным содержимым. Для Roblox результат должен быть встроен в игру, без намеренного извлечения конечными пользователями.

Запрещено standalone redistribution/перепродажа контента. Поэтому FBX/JPG/GLB из Fab не публикуются как исходники в GitHub. Допускается приватное хранилище для фактических collaborators по EULA, но текущий публичный репозиторий таким хранилищем не считается. Для скачивания требуется завершить бесплатную transaction и соблюсти выбранный tier; Reference-Only не заменяет исходный формат. Покупки не выполняются.

### Roblox Creator Store

`free` и `verifiedCreatorsOnly` не доказывают права оригинального автора или безопасность. До использования нужны проверка страницы, происхождения, разрешённого способа применения, всех скриптов/remotes/зависимостей и владельца назначения. Cross-owner inventory insert требует отдельного согласия пользователя. На текущем подэтапе insert_asset не вызывался.

### Hunt Almanac и Crytek

Числовые измерения задокументированы в `assets/mammons-gulch/reference/source.json` и `ASSET_LIBRARY.md`. [Hunt Almanac developer terms](https://hunt.innerpulse.net/developers/) требуют credit и разумную частоту запросов. Это не разрешение копировать модели/текстуры Crytek. Оригинальные игровые ассеты не включаются.

## Реестр

`Разрешения`: **CC0** включает commercial/modify/Roblox/raw Git/redistribution; **Fab embedded** исключает raw public redistribution; **none** означает отсутствие разрешения на использование до новой проверки.

| Ассет и ссылка | Автор | Лицензия / права | Локальный путь и модификации | Статус |
|---|---|---|---|---|
| [Grey Outpost Forest Set](https://polyhaven.com/a/rock_moss_set_01) | Kless Gyzen, Rob Tuytel, Rico Cilliers и др. | CC0 | `assets/lobby/ForestSet.glb`; существующая сборка мешей/материалов | approved_for_reuse |
| [Tree Small 02](https://polyhaven.com/a/tree_small_02) | Rico Cilliers | CC0 | `assets/lobby/ForestTree.glb`; существующий dead-tree вариант без листвы | approved_for_reuse |
| [Old Mine](https://www.fab.com/listings/dc4dc139-f3a3-4375-875f-d1831506953e) | Quixel Megascans | Fab Standard / embedded | Пути нет; модификаций нет; raw source не коммитить | license_verified__download_and_qa_pending |
| [Wild West Bank](https://www.fab.com/listings/9f84812a-596c-4562-aa9d-636fdf309fad) | Jen Abbott | Fab Standard / none для проекта | Нет файла/модификаций; цена и low-poly стиль | rejected_price_and_style |
| [Coastal Cliff 01](https://polyhaven.com/a/coastal_cliff_01) | Rob Tuytel, Rico Cilliers | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Coastal Cliff 02](https://polyhaven.com/a/coastal_cliff_02) | Rob Tuytel | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Rock Face 01](https://polyhaven.com/a/rock_face_01) | Dario Barresi | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Namaqualand Cliff 01](https://polyhaven.com/a/namaqualand_cliff_01) | Jenelle van Heerden, Rico Cilliers | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Pine Tree 01](https://polyhaven.com/a/pine_tree_01) | Rob Tuytel, Rico Cilliers | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Fir Tree 01](https://polyhaven.com/a/fir_tree_01) | Rob Tuytel, Rico Cilliers | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Dead Tree Trunk](https://polyhaven.com/a/dead_tree_trunk) | Rob Tuytel | CC0 | Отдельного файла нет; уже представлен в ForestSet | source_verified__qa_pending |
| [Modular Wooden Pier](https://polyhaven.com/a/modular_wooden_pier) | Rico Cilliers | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Wooden Crate 01](https://polyhaven.com/a/wooden_crate_01) | James Ray Cock | CC0 | Отдельного файла нет; проверить повторное использование ForestSet | source_verified__qa_pending |
| [Wooden Barrels 01](https://polyhaven.com/a/wooden_barrels_01) | James Ray Cock | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Wooden Lantern 01](https://polyhaven.com/a/wooden_lantern_01) | James Ray Cock | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Wooden Ladder](https://polyhaven.com/a/wooden_ladder) | Miroslav Turura | CC0 | Нет файла/модификаций; traversal будет авторским | source_verified__qa_pending |
| [Wood Planks Grey](https://polyhaven.com/a/wood_planks_grey) | Dario Barresi, Charlotte Baglioni | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Wood Peeling Paint Weathered](https://polyhaven.com/a/wood_peeling_paint_weathered) | Rob Tuytel, Dimitrios Savva | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Rock Face 03 texture](https://polyhaven.com/a/rock_face_03) | Dario Barresi, Rico Cilliers | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Wood Siding 013](https://ambientcg.com/a/WoodSiding013) | ambientCG / Lennart Demes | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Rusty Metal 02](https://polyhaven.com/a/rusty_metal_02) | Rob Tuytel | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Rusty Corrugated Iron](https://polyhaven.com/a/rusty_corrugated_iron) | Charlotte Baglioni | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Metal Grate Rusty](https://polyhaven.com/a/metal_grate_rusty) | Rob Tuytel, Dimitrios Savva | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Brown Mud 02](https://polyhaven.com/a/brown_mud_02) | Rob Tuytel | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Rocky Gravel](https://polyhaven.com/a/rocky_gravel) | Dario Barresi, Dimitrios Savva | CC0 | Нет файла/модификаций | source_verified__qa_pending |
| [Ponderosa Pine Tree Pack](https://create.roblox.com/store/asset/130515502281374) | Letaij; первоначальный автор не установлен | Не подтверждено / none | Нет файла/модификаций; не вставлено | rights_and_security_review_pending |
| [Rusty Pipe Kit](https://create.roblox.com/store/asset/121694135617761) | Rikilife794; первоначальный автор не установлен | Не подтверждено / none | Нет файла/модификаций; не вставлено | rights_and_security_review_pending |
| [Western Building search result](https://create.roblox.com/store/asset/5262171134) | acornndies; первоначальный автор не установлен | Не подтверждено / none | Нет файла/модификаций; не вставлено | rejected_unverified_and_unreviewed |

## Обновление

При фактическом импорте добавить конкретный файл/Asset ID, SHA-256 источника, дату, полный список модификаций, лицензионные notices и результат script/security audit. Нельзя менять статус на `approved` при отсутствии локального файла и проверенной лицензии; это закреплено `tests/unit/test_mammons_gulch_assets.py`.
