# La Plata Mine — Phase C Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Превратить La Plata Mine из ReferenceMassing в первый полноценный эталонный комплекс с измеренной архитектурой, четырьмя уровнями, интерьерами, шахтами, рабочими дверями/лестницами/подъёмником, PBR, освещением, звуком, оптимизацией и визуальной проверкой в Studio.

**Architecture:** Не менять текущие Lobby/Expedition/Rush и остальные compounds. Внутри `Workspace/Maps/MammonsGulch/Compounds/LaPlataMine` создать отдельные `ReferencePlan`, `Buildings`, `Interiors`, `Underground`, `InteractiveObjects` подмодули; генерируемая структурная геометрия и визуальные MeshParts разделяются от collision proxies и серверного кода. Референсные RLE/points — только числовые измерения, не модели/текстуры Crytek.

**Tech Stack:** Python 3 standard library, Luau, Rojo, Roblox Studio MCP, Blender при фактическом создании mesh/PBR, существующие Rokit tools и tests.

**Spec:** ТЗ этапа 3; `docs/map-compounds/la-plata-mine.md`; `docs/MAP_RECONSTRUCTION.md`; `docs/MAP_UNDERGROUND.md`; `docs/MAP_QUALITY_REPORT.md`.

## Global Constraints

- Продолжать `feature/03-mammons-gulch-map`; перед изменениями проверить status/fetch. После каждой задачи — checks, docs, commit, push, remote SHA.
- `CONFIRMED` только при наличии референса; `APPROXIMATED` для производной геометрии; `ADAPTED` для Roblox scale/collision.
- Не импортировать модели/текстуры Crytek и не публиковать Fab raw source. Новые ассеты проходят manifest/license/script audit.
- Не оставлять пустые интерьеры, декоративные лестницы, неправильные двери или заблокированные шахты.
- Не переходить к другим 15 комплексам, пока La Plata не стабилизирована эталоном. Не объявлять полную идентичность без визуального сравнения.

## Review Focus

- RLE накапливает signed deltas по строкам/уровням — golden decode tests до генерации геометрии.
- Door/window markers не должны быть заложены стеной — endpoint/raycast tests на каждом уровне.
- Stair endpoints должны соединять реальные этажи — collision и Humanoid route tests.
- Terrain holes не должны засыпаться повторной генерацией — повторный apply + underground checks.
- Серверные двери/подъёмник должны быть синхронизированы и защищены от spam/conflicts — Lune + два клиента.

---

### Task 1: La Plata reference capture and parser

**Files:**
- Create: `scripts/mammons_gulch/la_plata_reference.py`, `assets/mammons-gulch/reference/la-plata-plan.json`, `docs/map-compounds/la-plata-mine.md` update, `tests/unit/test_la_plata_reference.py`.

**Interfaces:**
- Produces: `decode_plan(payload, entry)`, `load_la_plata_plan()`, normalized levels/walls/floors/stairs/doors/windows/ladders/elevator/clue/lair data с source coordinates.

- [x] Написать failing golden test для RLE: `o = word & 4095`, `material = word >> 12`, накопление signed Int16 deltas ×0.05 + 512, отдельные `fo/fn`.
- [x] Запустить RED, реализовать parser по `floorplan.js`, не импортировать изображения как ассеты.
- [x] Сохранить source URL/hash, 4 levels, `Ground 52.37 / Upper 57.39 / Upper2 59.30 / Upper3 65.82`, 50 stair records, 10 doors, 18 windows, 3 ladders, 1 elevator, lair Upper floor и raw/published clue counts.
- [x] Получить floor-plan captures для четырёх уровней и общий 3D view; сохранить только сделанные Studio captures в docs, внешние изображения остаются ссылками.
- [x] Tests/checks/docs/commit `docs(map): analyze La Plata Mine floor plans`, push/SHA.

### Task 2: Production modular kit and license gate

**Files:**
- Create: `scripts/mammons_gulch/la_plata_kit.py`, `assets/mammons-gulch/la-plata/` sources/manifest, `docs/MAP_ASSET_RESEARCH.md`, `docs/MAP_ASSET_LICENSES.md`, `ASSET_LIBRARY.md`.

**Interfaces:**
- Produces: reusable wall/floor/roof/beam/stair/trim/lantern/prop meshes с UV, pivots, dimensions, collision proxy и Roblox Asset IDs.

- [ ] Написать failing asset schema/geometry tests: pivot/scale/normals/UV/LOD/rights обязательны; placeholder Parts не считаются production assets.
- [ ] Применить `blender-core`, `blender-asset-qa`, `blender-export-pipelines`, `asset-optimization` при фактической генерации; не использовать недоступные инструменты вслепую.
- [ ] Выбрать CC0 материалы/ props из manifest. Old Mine использовать только при доступной transaction и без raw source в GitHub; иначе создать авторские modular meshes.
- [ ] Выполнить один in-context style target в La Plata при day/sunset/interior перед массовым производством; записать оценки без null-to-high подмены.
- [ ] Tests/checks/docs/commit `assets(map): build La Plata modular kit`, push/SHA.

### Task 3: Measured architecture and accessible interiors

**Files:**
- Create: `scripts/mammons_gulch/la_plata_architecture.py`, `places/mammons-gulch/studio/LaPlataBuilder.luau`, `docs/map-compounds/la-plata-mine.md`, `tests/unit/test_la_plata_architecture.py`, `tests/studio/LaPlataArchitectureCheck.client.luau`.

**Interfaces:**
- Produces: `build_la_plata()` с named floor groups, wall openings, roofs, stairs, interiors и `VerificationStatus` metadata.

- [ ] Написать failing tests: все 4 levels, stair endpoints, door/window gaps, floor connectivity, отсутствие generic одинаковых домов и executable third-party code.
- [ ] Строить floor/wall geometry из decoded RLE и floors polygons, не из одного большого mesh или пустого фасада. Использовать production modular meshes и отдельные collision proxies.
- [ ] Разместить мебель/рабочее оборудование по назначению и reference evidence, без музейной симметрии; отметить неподтверждённые props как ADAPTED.
- [ ] Studio Solo Play: пройти каждый уровень, дверной проём, лестницу, крышу и внутренние маршруты; получить одинаковые captures с reference angles.
- [ ] Tests/checks/docs/commit `feat(map): build La Plata Mine architecture`, push/SHA.

### Task 4: La Plata underground refinement

**Files:**
- Modify: `scripts/mammons_gulch/underground.py`, `places/mammons-gulch/studio/TerrainBuilder.luau`, `docs/MAP_UNDERGROUND.md`.
- Create: `scripts/mammons_gulch/la_plata_underground.py`, `tests/unit/test_la_plata_underground.py`, `tests/studio/LaPlataUndergroundCheck.client.luau`.

**Interfaces:**
- Produces: region-specific floors/walls/ceilings, supported stairs/lifts, connected surface↔underground routes без потери существующих holes.

- [ ] Написать failing tests на 21 region graph, openings, headroom и доступные входы.
- [ ] Заменить generic rectangular detail в La Plata на измеренные region polygons и stair evidence; оставить ADAPTED width только при необходимости двух R15.
- [ ] Повторно применить TerrainBuilder с hole mask и проверить Air, коллизии, отсутствие просветов, воду и восстановление.
- [ ] Solo Play surface→mine→surface, узкий тоннель двумя клиентами, NPC navigation readiness без создания боссов/AI.
- [ ] Tests/checks/docs/commit `feat(map): refine La Plata underground`, push/SHA.

### Task 5: Server-authoritative interactives

**Files:**
- Create: `src/shared/mammons-gulch/interactables/Definitions.luau`, `places/mammons-gulch/server/Interactables.server.luau`, `InteractablesService.luau`, `places/mammons-gulch/client/Interactables.client.luau`.
- Create: `docs/MAP_INTERACTABLES.md` update, `tests/unit/MammonsGulchInteractables.luau`, `tests/studio/LaPlataInteractablesCheck.client.luau`.

**Interfaces:**
- Produces: tag/attribute-driven door/window/ladder/elevator configs, ProximityPrompt input, validated RemoteEvent requests и replicated states.

- [ ] Написать failing tests на type/distance/line-of-sight/rate limit/rapid conflict/dead or streamed character; нет arbitrary Instance outcome от клиента.
- [ ] Реализовать hinged doors с правильными pivots/collision, shutters/glass, рабочие ladders и один elevator с ограничителями и passenger policy. Не использовать неизвестные сторонние Scripts.
- [ ] Solo Play и два клиента: открыть/закрыть, одновременные запросы, respawn, streaming, звук и cleanup.
- [ ] Tests/checks/docs/commit `feat(map): implement La Plata interactives`, push/SHA.

### Task 6: Materials, lighting, audio and weather context

**Files:**
- Create: `src/shared/mammons-gulch/Materials.luau`, `SurfaceAudio.luau`, `EnvironmentPresets.luau`.
- Create: `places/mammons-gulch/client/LaPlataAtmosphere.client.luau`, `docs/MAP_LIGHTING.md`, `docs/MAP_AUDIO.md`, `tests/unit/MammonsGulchEnvironment.luau`, `tests/studio/LaPlataAtmosphereCheck.client.luau`.

**Interfaces:**
- Produces: shared material/surface classification, local positional ambience, underground reverb/occlusion и согласованный server-selected preset.

- [ ] Написать failing tests на известные/unknown materials, каждый пресет, underground zone transitions и отсутствие глобальной одинаковой реверберации.
- [ ] Применить PBR SurfaceAppearance/MaterialVariant с одинаковой плотностью текселей, без чрезмерного Bloom/ярких шахт.
- [ ] Добавить lanterns, interior/exterior light contrast, water/wood/metal/earth sound profiles и точечные ambience zones. Не создавать полный AI животных/боссов.
- [ ] Проверить Clear Day/Overcast/Sunset/Fog/Rain/Night при реальных captures и Output, измерить lights/particles и нагрузку.
- [ ] Tests/checks/docs/commit `feat(map): light and sound La Plata Mine`, push/SHA.

### Task 7: Performance, tactical and visual acceptance

**Files:**
- Create: `docs/images/map/la-plata-*.jpg`, `docs/MAP_QUALITY_REPORT.md` update, `docs/MAP_OPTIMIZATION.md`, `TEST_REPORT.md`.
- Modify: `scripts/mammons_gulch/la_plata_*.py` только по найденным дефектам.

**Interfaces:**
- Produces: повторяемые reference cameras, measured performance и gate к следующему комплексу.

- [ ] Выполнить сценарии A–D: главный вход, обход, вертикальный уровень и отступление; проверить sightlines и укрытия.
- [ ] Провести Solo Play и два клиента на реальных маршрутах, включая streaming/коллизии/двери/лестницы/elevator; не заявлять 12 игроков.
- [ ] Измерить FPS, p95, memory, loading, active parts/lights/particles и сравнить с 60,07 FPS / 18,25 мс макета. Не уменьшать видимые ключевые силуэты без профильной причины.
- [ ] Получить согласованные captures с reference angles и выставить фактические scores без автоматического 90/100.
- [ ] Tests/checks/docs/commit `test(map): validate La Plata Mine quality`, push/SHA.

### Task 8: Restore, integrate and prepare next compound

**Files:**
- Modify: `docs/MAP_RECONSTRUCTION.md`, `ARCHITECTURE.md`, `DEVELOPMENT_PROGRESS.md`, `NEXT_STEPS.md`, `CHANGELOG.md`, `BUG_TRACKER.md`.
- Create: следующий compound plan только после La Plata acceptance.

**Interfaces:**
- Produces: восстановление La Plata из Git-источников без Studio-only edits и gate для Split River Mill (следующий в заданном списке после La Plata).

- [ ] Удалить только временные QA scripts/placeholders; сохранить authored debug system и существующие охотники/лобби.
- [ ] Полностью пересобрать и переоткрыть Place, повторить критические tests, обновить документы/quality status и remote SHA.
- [ ] Не создавать PR в main до завершения этапа 3; начать следующий комплекс только если нет критических дефектов La Plata.
- [ ] Провести whole-branch review; без subagent явно записать self-review, исправить Critical/Important через RED→GREEN и продолжить.
