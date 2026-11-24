# Рельеф и вода Mammon's Gulch

## Studio-результат применения и восстановления

- Первый `apply()` создал **338 регионов за 40,84 с**; повторный из Git-данных — **338 за 41,08 с**. Оба завершились `ok=true`, локальный Place сохранён после восстановления.
- Solo Play с ожиданием потоковой загрузки: Blackthorn 36,159 / ожидалось 32,111; Monteros Malt 16,661 / 12,684; La Plata 78,559 / 74,246. Все отклонения в допуске 5 studs.
- Контрольная вода: `Water`, 8 / 4,89 studs; допуск тот же. Отклонения связаны с 4-stud вокселизацией и локальным уклоном, не сменой координат.
- [Общий кадр Terrain в Studio](images/map/mammons-gulch-terrain-overview.jpg).

## Исходные измерения

- Область: 1024 × 1024 м; 513 × 513 опорных высот с шагом 2 м.
- `terrain.u16`: little-endian row-delta. Значение накапливается в пределах каждой строки по модулю 65536, затем `height = zmin + value * (zmax-zmin)/65535`.
- Диапазон: 32,79–116,733 м. Контрольные наземные высоты Blackthorn и Monteros Malt проверены unit tests и Studio self-test.
- Преобразование: 1 м = 3 studs, `WorldY = (SourceZ - 32.79) * 3`, север в `-Z`. Статус масштаба: `ADAPTED`.

## Studio-реализация

`ServerStorage/MammonsGulchStudio/TerrainBuilder` вызывается только в Studio. Payload `MammonsGulchTerrainData.luau` генерируется из отслеживаемых данных и остаётся в ServerStorage, не реплицируясь клиентам.

- Воксель: 4 studs; координатная сетка X/Z = −1536…1536, Y = −16…260.
- Регион: 64 × 64 × 64 вокселя; 338 регионов с `task.wait()` между записью.
- `Terrain:WriteVoxels(region, 4, materials, occupancy)` создаёт occupancy по высоте пересечения вокселя с рельефом, а не твёрдые колонны от базы до поверхности. Второй аргумент `resolution` обязателен в текущем API.
- Материалы greybox: Grass/Ground для пологих низин, Slate для средних склонов, Rock для крутых и высоких участков. Это не финальная PBR-раскладка.
- Water polygons превращаются в ближайшую опорную сетку. Вода ставится только выше рельефа и не выше уровня соответствующего водоёма; нет единой водной плоскости на всю карту.
- Base64 декодируется проектным кодом, поскольку проверенный Studio 0.748 не предоставляет `HttpService:Base64Decode`. `selfTest()` проверяет decoder и три контрольные высоты.

## Достоверность

- `CONFIRMED`: исходные высоты, полигоны воды, координаты и row-delta decoding.
- `APPROXIMATED`: вокселизация склонов/берегов, nearest-grid вода, slope-materials, высоты post markers по heightfield.
- `ADAPTED`: 3 studs/м, границы Y и технические материалы greybox.
- `PENDING_STUDIO`: полная проходимость, визуальные сравнения, StreamingEnabled и multiplayer.

## Восстановление

```sh
python3 scripts/generate_mammons_gulch.py
rojo build places/mammons-gulch.project.json -o build/MammonsGulch-Development.rbxl
```

В Studio Edit через MCP:

```luau
local builder = require(game:GetService("ServerStorage").MammonsGulchStudio.TerrainBuilder)
assert(builder.selfTest())
builder.apply()
```

`apply()` вызывает `Terrain:Clear()` только в отдельном development Place и затем детерминированно создаёт рельеф заново. Он не должен вызываться в опубликованном матче. Проверка повторного применения обязательна.

## Проверки

`tests/studio/MammonsGulchTerrainCheck.client.luau` выполняет raycast только против Terrain для Blackthorn, Monteros Malt и La Plata с допуском 5 studs на вокселизацию. Фактические результаты применения, raycast и кадры добавляются после Studio-прогона; статические тесты не считаются заменой Studio QA.
