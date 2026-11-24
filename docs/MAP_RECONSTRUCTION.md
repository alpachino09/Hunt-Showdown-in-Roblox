# Восстановление Mammon's Gulch из исходников

## Источник истины

Отслеживаются Git:

- числовые измерения в `assets/mammons-gulch/reference/`;
- Python-генераторы в `scripts/mammons_gulch/` и `scripts/generate_mammons_gulch.py`;
- Luau-координаты в `src/shared/mammons-gulch/`;
- Rojo Place в `places/mammons-gulch.project.json`;
- авторские модели, материалы и разрешённые ассеты в `assets/`.

`build/` не является исходником и игнорируется Git. Изменения, сделанные только в открытом Studio и не перенесённые в эти файлы, не считаются сохранёнными.

## Сборка

В macOS с установленным Rokit:

```sh
./scripts/check.sh
```

Или только генерация и сборка:

```sh
export PATH="$HOME/.rokit/bin:$PATH"
python3 scripts/generate_mammons_gulch.py
rojo build places/mammons-gulch.project.json -o build/MammonsGulch-Development.rbxl
```

Проверяемые выходы:

- `build/generated/MammonsGulch.rbxmx`;
- `src/shared/mammons-gulch/CompoundDefinitions.luau` (детерминированный отслеживаемый output, проверяется повторной генерацией);
- `build/MammonsGulch-Development.rbxl`;
- `build/mammons-gulch.sourcemap.json`.

## Структура и владельцы

- `Workspace/Maps/MammonsGulch` принадлежит файловому генератору, не редактируется вручную в Studio.
- `Compounds` содержит измеренные region boundaries и `ReferenceMassing` с `Confidence=APPROXIMATED`. Это greybox, не финальные здания.
- Глобальные Spawn/Extraction/Supply/Clue/Boss/Interactive markers создаются один раз в корневых папках. Внутри compounds нет дублирующих gameplay-папок.
- 42 кандидата спавна не активируются одновременно. `SpawnPoints/DevelopmentSpawn` — единственный SpawnLocation для development Place; `Host.server.luau` назначает его игрокам.
- Настоящий `Workspace.Terrain` создаётся отдельным Studio-инструментом из `terrain.u16` и `build/generated/MammonsGulchTerrainData.luau`, а не XML-файлом. `places/mammons-gulch/studio/TerrainBuilder.luau` вызывается через MCP только в development Place. Подробности в `docs/MAP_TERRAIN.md`.
- `Roads`, `Railways`, `Bridges` создаются из `reference/routes.json` модулем `routes.py`; confidence каждой centerline сохраняется в модели. `Underground` создаётся из visareas модулем `underground.py`; маска `reference/holes.bin` добавляется в TerrainData и применяется повторно через TerrainBuilder. Подземные ограничения описаны в `docs/MAP_UNDERGROUND.md`.
- Текущие Lobby, ExpeditionMap, RushMap, охотники и их файлы остаются собственностью прежних генераторов и не перезаписываются.

## Детерминизм и восстановление

Повторный `python3 scripts/generate_mammons_gulch.py` должен дать байт-идентичные `MammonsGulch.rbxmx` и `CompoundDefinitions.luau` при неизменных входных данных. Это проверяется `tests/unit/test_mammons_gulch_generation.py`.

Для обновления числового среза используется `python3 scripts/mammons_gulch/reference.py`. Он выполняет сетевые запросы последовательно, обновляет данные и генерируемую референсную документацию. Для локальной регенерации документов без сети можно вызвать `generate_docs` с сохранёнными JSON.

## Ограничения текущего результата

Rojo-сборка подтверждает только корректность упаковки. Проходимость, визуальное качество, рельеф, маршруты, StreamingEnabled и multiplayer проверяются отдельно в Studio. До этих проверок не допускается утверждение о готовой или идентичной карте.
