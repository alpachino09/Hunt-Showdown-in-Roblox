# Mammon’s Gulch — Research and Playable Geography Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Создать в отдельной ветке восстановимый из исходников макет Mammon’s Gulch с подтверждёнными позициями всех 16 комплексов, измеренным рельефом, водой, маршрутами, железной дорогой, подземным каркасом и реальной проверкой в Roblox Studio.

**Architecture:** Не заменять текущие Lobby, Expedition, Rush и охотников. Новый `MammonsGulch-Development` Place собирается через Rojo; числовые референсные измерения, генераторы и Luau-конфигурации являются источником истины, а `build/` остаётся воспроизводимым результатом. Рельеф строится из задокументированной сетки высот отдельным Studio-инструментом, не монолитным скриптом всей карты.

**Tech Stack:** Python 3 standard library, Roblox Luau, Rojo 7.7.1, StyLua 2.6.0, Selene 0.32.0, Luau LSP 1.70.1, Lune 0.11.1, Roblox Studio 0.748 MCP или локальный stdio-адаптер без новых зависимостей.

**Spec:** ТЗ этапа 3 из запроса пользователя; `PROJECT_PLAN.md`, `GAME_DESIGN.md`, `ARCHITECTURE.md`, `AGENTS.md`.

## Global Constraints

- Рабочая ветка: `feature/03-mammons-gulch-map`, от текущего чистого `feature/02-premium-hunters` (`e58f0b258b42eb3cd1c96263ae78247ec8a6280b`), чтобы сохранить последних охотников; перед ветвлением выполнить безопасный `git fetch origin` и повторно сверить refs.
- Никаких force-push, публикации Experience, покупок или удаления существующих карт/лобби/охотников.
- Исходная область по Hunt Almanac: 1024 × 1024 м; terrain grid 513 × 513, шаг 2 м, высоты 32,79–116,733 м; север вверху исходной карты и в отрицательную сторону Roblox Z.
- Начальная калибровка: 1 м = 3 studs; мир 3072 × 3072 studs; `WorldY = (SourceZ - 32.79) * 3`. Это **ADAPTED** до измерения маршрутов; существующие скорости 13/19 studs/s дают 4,33/6,33 м/с.
- Статусы `CONFIRMED`, `APPROXIMATED`, `ADAPTED` обязательны для геометрии и маршрутов. Нет подтверждения — нет утверждения идентичности.
- Не коммитить исходные текстуры/модели Crytek, изображения референсов или Fab source packages. Сохранять только необходимые фактические числовые измерения, авторские производные данные и разрешённые ассеты с происхождением.
- Fab Standard License не считать CC0: исходные пакеты Fab не помещать в GitHub; до скачивания проверить условия и доступ без обхода авторизации.
- Все значимые игровые изменения впоследствии подтверждает сервер; этот пакет не меняет награды, экономику или оружие.
- После каждой задачи: проверка, обновление соответствующих документов, отдельный commit, push, проверка SHA через `git ls-remote origin refs/heads/feature/03-mammons-gulch-map`.

## Review Focus

- Неправильная ориентация/зеркалирование карты — тест углов и четырёх контрольных комплексов в Task 2, Studio north-up capture в Task 8.
- Рельеф, маркеры и вода используют разные начала координат — единые pure conversion functions и тесты высот/позиций в Tasks 2, 4, 5.
- Недоступные дороги/тоннели из-за воксельного шага и коллизий — raycast/Character checks в Task 8; никакого перехода к детализации при критическом дефекте.
- Streaming удаляет опору или мост перед игроком — реальные переходы в Solo и двух клиентах в Task 8, persistent критические модели при необходимости.
- Неподтверждённые ассеты или сторонний код попадают в сборку — manifest/license gate и descendant Script audit в Task 3; сеть/загрузчики не выполнять.

---

### Task 1: Baseline, branch and Studio inventory

**Files:**
- Create: `docs/superpowers/plans/2026-11-24-mammons-gulch-geography.md` (копия этого плана)
- Create: `scripts/studio_mcp.py` только если встроенные Roblox MCP tools недоступны в сессии
- Modify: `DEVELOPMENT_PROGRESS.md`, `NEXT_STEPS.md`, `CHANGELOG.md`, `TEST_REPORT.md`

**Interfaces:**
- Produces: задокументированный baseline SHA, Roblox Studio version/place, владельцы subtree, доступный способ `list_roblox_studios` / inspect / execute / capture.

- [ ] Выполнить `git fetch origin`, `git status --short --branch`, сверить все local/remote heads; переключиться на новую ветку от подтверждённого текущего SHA.
- [ ] Запустить `./scripts/check.sh` до изменений и сохранить фактический результат; не исправлять посторонние системы в этой задаче.
- [ ] Инвентаризировать Studio: открытые place, Explorer, `Workspace`, `ServerStorage`, `ReplicatedStorage`, Scripts/LocalScripts/ModuleScripts, текущие Output warnings. Studio процесс и StudioMCP уже обнаружены; отсутствие MCP tools в сессии не считать отсутствием сервера.
- [ ] При необходимости реализовать минимальный newline-JSON-RPC stdio client к `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`; сначала `initialize` и `tools/list`, затем только read-only inventory. Не подключаться к недоверенным местам.
- [ ] Зафиксировать границы: `scripts/generate_lobby.py` владеет текущим ExpeditionMap/RushMap; `default.project.json` — Lobby; `places/expedition.project.json` — Expedition; новые файлы не перезаписывают их.
- [ ] Обновить документы только фактами аудита, проверить diff, commit `docs(map): record project and Studio baseline`, push и сверить SHA.

### Task 2: Verified reference dataset and coordinate system

**Files:**
- Create: `scripts/mammons_gulch/reference.py`
- Create: `assets/mammons-gulch/reference/source.json`
- Create: `assets/mammons-gulch/reference/layout.json`
- Create: `assets/mammons-gulch/reference/points.json`
- Create: `assets/mammons-gulch/reference/terrain.json` + компактный `terrain.u16`
- Create: `tests/unit/test_mammons_gulch_reference.py`
- Create: `docs/MAP_REFERENCE_ANALYSIS.md`, `docs/MAP_WORLD_LAYOUT.md`, `docs/MAP_COMPOUNDS.md`, `docs/map-compounds/*.md`
- Modify: `ASSET_LIBRARY.md`, `DEVELOPMENT_PROGRESS.md`, `NEXT_STEPS.md`, `CHANGELOG.md`

**Interfaces:**
- Produces: `load_layout()`, `decode_heightfield()`, `source_to_world(x, y, z)`; 16 stable IDs (`com_a`…`poi_c`), source polygons/bboxes/centres, 21 extraction, 42 spawn, 40 named resupply candidates (59 raw records разделить по типам, не смешивать), точки дверей/окон/лестниц/улик/логов по фактическим группам.

- [ ] Написать failing tests: 16 уникальных комплексов; размер 1024; grid 513; min/max высот; отсутствие NaN; преобразование NW `(512,1536)` → Roblox `(-1536,-1536)` X/Z и SE `(1536,512)` → `(1536,1536)`; label anchor La Plata из `c=[446.5,588.8]` → `X=-164.352`, `Z=274.0224` studs (не путать label anchor с центром bbox); round-trip ошибка < 0.001.
- [ ] Запустить tests и подтвердить FAIL до реализации.
- [ ] Получать публичные `mapdata`, `meta.json`, `terrain.d16` не чаще одного запроса/с, фиксировать URL, game build, дату, SHA-256. Декодировать `height = zmin + uint16 * (zmax-zmin)/65535`; не сохранять веб-изображения, meshes или текстуры.
- [ ] Нормализовать только фактические координаты, высоты, границы, water polygons и gameplay markers. Источник Hunt Almanac указать рядом с данными и во всех производных документах.
- [ ] Создать индекс и 16 отдельных Compound Specification со всеми полями ТЗ; заполнить только подтверждённые этажи, clue counts, lair level и тактические наблюдения. Остальное явно `PENDING_RESEARCH`, не выдумывать.
- [ ] Прогнать `python3 -m unittest tests/unit/test_mammons_gulch_reference.py` и `./scripts/check.sh`; commit `docs(map): analyze original Mammon's Gulch layout`, push и сверить SHA.

### Task 3: Asset research, license gate and reusable manifest

**Files:**
- Create: `docs/MAP_ASSET_RESEARCH.md`, `docs/MAP_ASSET_LICENSES.md`, `assets/mammons-gulch/asset-manifest.json`
- Create: `tests/unit/test_mammons_gulch_assets.py`
- Modify: `ASSET_LIBRARY.md`, `DEVELOPMENT_PROGRESS.md`, `NEXT_STEPS.md`, `CHANGELOG.md`

**Interfaces:**
- Produces: manifest entries с category/source/author/license/date/allowed actions/local path/modifications/status/scores; `pending` assets не имеют пути сборки.

- [ ] Написать failing tests на обязательные provenance fields, запрет `approved` без license/source и запрет непроверенных исполняемых компонентов.
- [ ] Проверить кандидатов Old Mine и Wild West Bank на Fab, Poly Haven models/textures, ambientCG и существующий CC0 `ForestSet.glb`; сравнить минимум несколько вариантов для cliffs, pines, modular mine, western warehouses и industrial props.
- [ ] Для Old Mine зафиксировать: бесплатно, 61 asset, FBX/JPG, Fab Standard License; отдельно проверить полный EULA, Roblox embedding, модификацию и запрет raw redistribution. Не скачивать при необходимости недоступной авторизации.
- [ ] Оценивать по 10 критериям только после фактического просмотра/технической проверки; незаполненные критерии оставить `null`, а не присваивать выдуманные баллы.
- [ ] Прогнать tests/checks; commit `assets(map): document licensed environment candidates`, push и сверить SHA. В этом пакете не интегрировать тяжёлые ассеты до визуального эталона.

### Task 4: Separate Rojo place, shared world contract and 16-compound blockout

**Files:**
- Create: `places/mammons-gulch.project.json`, `places/mammons-gulch/server/Host.server.luau`, `places/mammons-gulch/client/.gitkeep`, `places/mammons-gulch/studio/TerrainBuilder.luau`
- Create: `src/shared/mammons-gulch/World.luau`, `src/shared/mammons-gulch/CompoundDefinitions.luau`
- Create: `scripts/generate_mammons_gulch.py`, `scripts/mammons_gulch/xml.py`, `compounds.py`, `routes.py`, `markers.py`
- Create: `tests/unit/MammonsGulchLayout.luau`, `tests/unit/test_mammons_gulch_generation.py`
- Modify: `scripts/build.sh`, `scripts/check.sh`, `ARCHITECTURE.md`, `docs/MAP_WORLD_LAYOUT.md`, `docs/MAP_RECONSTRUCTION.md`

**Interfaces:**
- Produces: `World.sourceToWorld(x: number, y: number, z: number): Vector3`, `World.worldToSource(position: Vector3): (number, number, number)`, `CompoundDefinitions.ordered`, generated `build/generated/MammonsGulch.rbxmx`, server-only terrain data module.

- [ ] Написать failing Luau/Python tests на scale conversion, 16 definitions, соответствие IDs/positions reference JSON, XML parse и отсутствие executable descendants в импортированной geometry.
- [ ] Подтвердить FAIL, затем реализовать pure World module и генератор определений из Task 2 без ручного дублирования координат.
- [ ] Создать `Workspace/Maps/MammonsGulch` с подразделами из ТЗ и `Compounds/<PascalCaseId>`; границы использовать из исходных polygons, centers/bboxes — из данных, никаких позиций «на глаз» или круга.
- [ ] Для blockout создавать измеренные compound pads и простые massing volumes с marker labels; это одноразовые greybox Parts, не финальные здания. Все Building/Interior статусы остаются `PENDING`/`APPROXIMATED`.
- [ ] Подготовить отдельный Place с `StreamingEnabled=true`, Realistic day Lighting и одним безопасным development spawn; 42 candidate spawns остаются невидимыми markers, не активными SpawnLocations.
- [ ] Встроить новый build/check без изменения существующих outputs; прогнать tests и `./scripts/check.sh`; commit `feat(map): create world terrain blockout`, push и сверить SHA.

### Task 5: Terrain, mountains, valleys and water at measured elevations

**Files:**
- Modify: `places/mammons-gulch/studio/TerrainBuilder.luau`
- Create: `places/mammons-gulch/studio/TerrainData.luau` как воспроизводимый generator output, если размер уместен; иначе generated server-only `build/generated/MammonsGulchTerrainData.rbxmx`
- Create: `scripts/mammons_gulch/terrain.py`
- Create: `tests/unit/test_mammons_gulch_terrain.py`, `tests/studio/MammonsGulchTerrainCheck.client.luau`
- Create: `docs/MAP_TERRAIN.md`
- Modify: `docs/MAP_WORLD_LAYOUT.md`, `docs/MAP_RECONSTRUCTION.md`, `TEST_REPORT.md`, `DEVELOPMENT_PROGRESS.md`, `NEXT_STEPS.md`, `CHANGELOG.md`

**Interfaces:**
- Consumes: terrain grid/water polygons из Task 2 и `World.sourceToWorld`.
- Produces: `TerrainBuilder.apply(): ()`, идемпотентно заменяющий только owned terrain в development Place; height/water sampling для Studio checks.

- [ ] Написать failing tests на 16-bit decoding, bilinear sampling, water level polygons, высоту La Plata control samples и границы occupancy; подтвердить FAIL.
- [ ] Реализовать chunked `Terrain:WriteVoxels` с шагом 4 studs, slope/height materials для greybox, твёрдый base ниже минимальной высоты и корректным Y offset; не создавать один гигантский MeshPart.
- [ ] Применить water polygons на их измеренных `z` с Terrain water; не заливать единой плоскостью всю карту. Отметить вокселизацию берегов как `APPROXIMATED`.
- [ ] Применить в Studio Edit через MCP, сохранить локальный `build/MammonsGulch-Development.rbxl`, затем доказать восстановление: очистить только owned terrain и повторно применить из Git-данных.
- [ ] Проверить raycasts на контрольных точках, отсутствие провалов и непроходимых невидимых выступов; записать фактические измерения и ограничения.
- [ ] Прогнать checks; отдельные commits `feat(map): build measured mountain terrain` и `feat(map): reconstruct river levels and banks`, push/SHA после каждого.

### Task 6: Roads, railway, bridges and underground macro-routes

**Files:**
- Create: `assets/mammons-gulch/reference/routes.json`
- Create: `scripts/mammons_gulch/railway.py`, `underground.py`
- Modify: `scripts/mammons_gulch/routes.py`, `scripts/generate_mammons_gulch.py`
- Create: `docs/MAP_UNDERGROUND.md`, `docs/MAP_INTERACTABLES.md`
- Create: `tests/unit/test_mammons_gulch_routes.py`, `tests/studio/MammonsGulchRouteCheck.client.luau`
- Modify: `docs/MAP_WORLD_LAYOUT.md`, `docs/MAP_RECONSTRUCTION.md`, `TEST_REPORT.md`, `DEVELOPMENT_PROGRESS.md`, `NEXT_STEPS.md`, `CHANGELOG.md`

**Interfaces:**
- Produces: named route centerlines в source metres, rail segments, bridge endpoints, underground nodes/edges и entrances; всё имеет confidence + reference links.

- [ ] Написать failing tests на валидные endpoints, ширину проходов, связность underground graph и отсутствие неподтверждённого `CONFIRMED`.
- [ ] Векторизовать главные дороги/тропы/рельсы по high-res Survey и In-game виду; сохранить control points и `APPROXIMATED` там, где нет исходного вектора. Не использовать случайную генерацию.
- [ ] Построить проходимые greybox roads/railbed/мосты с реальными коллизиями; декоративные rails не заменяют опорную геометрию.
- [ ] Использовать `holes.bin`/`visareas`/floor-plan evidence для крупных подземных пустот; построить связный каркас La Plata/Oro Gordo и подтверждённые соединения, не утверждая полную сеть при нехватке данных.
- [ ] Запустить route unit tests, static checks и Studio walk/raycast checks; отдельные commits для roads, railway и underground, push/SHA после каждого.

### Task 7: Debug inspection, sightlines and measurable route validation

**Files:**
- Create: `places/mammons-gulch/client/Debug.client.luau`, `places/mammons-gulch/server/Debug.server.luau`
- Create: `src/shared/mammons-gulch/DebugConfig.luau`
- Create: `tests/studio/MammonsGulchDebugCheck.client.luau`
- Create: `docs/MAP_OPTIMIZATION.md`
- Modify: `places/mammons-gulch.project.json`, `docs/MAP_RECONSTRUCTION.md`, `TEST_REPORT.md`

**Interfaces:**
- Produces: Studio-only teleport, bounds/spawn/clue/extraction/height/distance/sightline/collision/streaming overlays; production entry point не регистрирует их.

- [ ] Написать failing checks: debug запрещён вне Studio/разрешённого режима; нет enemy tracking; нет общедоступного Remote для произвольного телепорта.
- [ ] Реализовать минимальный debug UI/controls существующими Roblox Instances и серверную валидацию Studio-only teleport; визуализацию линий делать локальной и удаляемой.
- [ ] Проверить сценарии проходимости ТЗ на макете, включая дальний переход, несколько уровней, подземный маршрут, узкий тоннель двумя клиентами, streaming, высотные sightlines и мосты/склоны. Двери/карта/компас ещё не объявлять готовыми.
- [ ] Измерить средний FPS, frame time p95, память Studio, время загрузки, counts parts/lights/particles; не выдавать отсутствующий 1% low за измеренный.
- [ ] Зафиксировать результаты, commit `test(map): validate geography and traversal`, push и сверить SHA.

### Task 8: Real Studio captures, correction pass and phase gate

**Files:**
- Create: `docs/images/map/mammons-gulch-*.png` или `.jpg` только из реального Studio
- Create: `docs/MAP_QUALITY_REPORT.md`
- Modify: `docs/MAP_REFERENCE_ANALYSIS.md`, `docs/MAP_WORLD_LAYOUT.md`, `docs/MAP_TERRAIN.md`, `docs/MAP_UNDERGROUND.md`, `docs/MAP_OPTIMIZATION.md`, `TEST_REPORT.md`, `DEVELOPMENT_PROGRESS.md`, `NEXT_STEPS.md`, `CHANGELOG.md`

**Interfaces:**
- Produces: повторяемые camera markers и фактический список отклонений/дефектов; gate для начала La Plata detail plan.

- [ ] Захватить north-up overview, общий perspective и одинаковые ракурсы ключевых районов/La Plata через Studio MCP `screen_capture` (не браузерные изображения вместо игры).
- [ ] Сравнить с референсами по позициям, силуэтам, высотам, воде, дорогам, railway и проходимости; исправить обнаруженные ошибки и повторить затронутые проверки.
- [ ] Выставить честные оценки макета без автоматических 90/100; финальные здания, интерьеры, интерактивность, UI, звук и полная погода остаются незавершёнными.
- [ ] Выполнить полный `./scripts/check.sh`, Studio Solo и доступный двухклиентный тест, очистить временные Scripts/markers не входящие в authored debug system, проверить clean `git status` после commit.
- [ ] Commit `test(map): validate all compound positions`, push, проверить remote SHA. PR в `main` на этом промежуточном этапе не создавать; следующий план — La Plata Mine, Phase C, только после отсутствия критических дефектов макета.
