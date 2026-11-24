# Исследование Mammon's Gulch

Дата среза: 24.11.2026. Цель — измеримая реконструкция, а не утверждение идентичности без сравнения.

## Источники

- [Crytek: Welcome to Colorado](https://www.huntshowdown.com/news/introducing-hunt-showdown-1896-welcome-to-colorado): 16 комплексов, Колорадо, две горные области, шахты с несколькими входами, железная дорога, вертикальность, водопады, lodge и фермы.
- [Hunt Almanac: Mammon's Gulch](https://hunt.innerpulse.net/maps/mammons-gulch/): состав мест, этажи, логова и диапазоны игровых систем.
- [2D Survey](https://hunt.innerpulse.net/maps/#mammons-gulch): границы, 21 extraction, 42 spawn, 40 основных resupply markers, масштаб и north-up.
- [3D map](https://hunt.innerpulse.net/maps/3d/#mammons-gulch): истинные высоты, здания и sightline методика.
- [La Plata Mine floor plans](https://hunt.innerpulse.net/maps/3d/mammons-gulch/la-plata-mine/): четыре уровня, 10 улик, 28 дверей/окон и логово на Upper floor.
- [Developer terms](https://hunt.innerpulse.net/developers/): публичные read-only данные, credit и ориентир не более одного запроса в секунду.

## Что сохранено

`layout.json` содержит 16 регионов, полигоны, bbox, label anchors, этажи, логова, тактические заметки и candidates постов. `points.json` содержит координаты игровых точек и stair endpoints. `terrain.json` + `terrain.u16` представляют числовые измерения высот, water polygons и underground regions. Источник и SHA-256 исходных ответов записаны в `source.json`.

Это не модели, UV, текстуры, изображения или исходники Crytek. Референсные изображения не переиздаются в репозитории. Названия и игровые активы Hunt принадлежат Crytek; Hunt Almanac — неофициальный справочник.

## Достоверность

- `CONFIRMED`: числовые координаты, высоты, состав комплексов, этажи и точки из проверенного среза.
- `APPROXIMATED`: высота post markers по heightfield, вокселизация Terrain и маршруты, считанные с растровой схемы.
- `ADAPTED`: 3 studs/м, игровые коллизии и последующие технические изменения Roblox.
- `PENDING_RESEARCH`: архитектура/интерьеры, которые ещё не просмотрены с требуемых сторон.
- `PENDING_STUDIO`: проходимость, визуальное качество, производительность и multiplayer.

Отсутствие данных не заполняется предположением. Каждая Compound Specification находится в `docs/map-compounds/`.
