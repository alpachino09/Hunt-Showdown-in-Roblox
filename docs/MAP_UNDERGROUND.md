# Подземные системы Mammon's Gulch

## Исходные данные

- `holes.bin`: 32 897 байт, 1445 отверстий в сетке 513 × 513. Бит `128 >> (7 & index)`, padding после последней ячейки игнорируется.
- `undergroundRegions`: 21 `visarea` с исходными polygons, верхним уровнем `z` и высотой `h`. Для greybox floor = `z-h`, ceiling = `z`.
- `points.json` содержит ladders, elevators, doors, windows и stairs. Эти данные не означают, что вся исходная сеть уже реконструирована.

## Реализация

- TerrainBuilder декодирует `holesData` и убирает occupancy в ячейках отверстий. Это предотвращает сплошную засыпку шахт Terrain.
- Каждый region получает collision floor, roof и стены по исходному polygon. Bbox используется только для размеров floor/roof и является `APPROXIMATED`.
- Граф строится по ближайшим точкам polygons и минимальному остовному дереву: 21 node, 20 edges, все узлы связаны. Связи являются геометрической реконструкцией, а не заявлением оригинальных соединений.
- Поверхностные входы выбираются по ближайшей hole cell в пределах 150 м. При отсутствии подходящей ячейки вход не создаётся.
- Стандартная ширина тоннеля — 12 studs, высота соединения — 12 studs. Это `ADAPTED` для встречного движения двух R15, а не подтверждённый размер оригинала.

## Достоверность

- `CONFIRMED`: polygons, z/h, hole mask и координаты игровых точек.
- `APPROXIMATED`: rectangular floor/roof, остовный граф соединений, выбор входов и связанные коллизии.
- `ADAPTED`: ширина 12 studs и Roblox collision policy.
- `PENDING_RESEARCH`: точная маршрутная топология оригинальных шахт, все подземные комнаты и оригинальные материалы.
- `PENDING_STUDIO`: проходимость двух игроков, реверберация, отсутствие просветов наружной сцены и StreamingEnabled.

## Восстановление

`render_underground` вызывается из `scripts/mammons_gulch/generate.py` и создаёт `Workspace/Maps/MammonsGulch/Underground`. `holesData` добавляется в `MammonsGulchTerrainData.luau`. Для изменения Terrain повторно применяется `TerrainBuilder.apply()` после сборки Place. Полная последовательность задокументирована в `docs/MAP_RECONSTRUCTION.md` и `docs/MAP_TERRAIN.md`.

## Studio-результат

- Terrain и все 21 regions/20 tunnels загружены в development Place. `carveHoles()` выполнен для 1445 ячеек; повторный raycast центра hole cell вернул `air`.
- Первичная 6-stud carve оставила твёрдый остаток на границе вокселей. Она заменена 12-stud carve; это зафиксировано как `ADAPTED`, а не размер оригинального прохода.
- Solo Play подтвердил collision underground floor, road, railbed, `kingfisher_trestle.Deck_01` и отсутствие Terrain в центре hole cell.
- Пролёт изначально ошибочно назван `la_plata_trestle`; визуальная проверка выявила район Kingfisher и идентификатор исправлен. Неверное название больше не используется.
- Проверка двух клиентов, звук и реверберация ещё не выполнялись.

## Следующие проверки

Пройти от поверхности до underground floor и обратно, проверить два клиента в одном тоннеле, отсутствие провалов и невидимых стен, двери/лестницы/elevators, точечный звук и реверберацию. Эти системы не считаются завершёнными по наличию greybox.
