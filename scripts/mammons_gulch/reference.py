import argparse
import hashlib
import html
import json
import re
import struct
import time
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "assets" / "mammons-gulch" / "reference"
DOCS = ROOT / "docs"
BASE_URL = "https://hunt.innerpulse.net"
SCALE = 3.0
HEIGHT_OFFSET = 32.79


def decode_heightfield(payload, metadata):
    grid = metadata["grid"]
    expected = grid * grid * 2
    if len(payload) != expected:
        raise ValueError(f"heightfield size: expected {expected} bytes, got {len(payload)}")
    values = struct.unpack(f"<{grid * grid}H", payload)
    scale = (metadata["zmax"] - metadata["zmin"]) / 65535.0
    heights = []
    for row in range(grid):
        value = 0
        for encoded in values[row * grid:(row + 1) * grid]:
            value = (value + encoded) & 65535
            heights.append(metadata["zmin"] + value * scale)
    return heights


def normalized_to_source(x, y):
    return 512.0 + x * 1.024, 512.0 + (1000.0 - y) * 1.024


def source_to_world(x, y, z):
    return (x - 1024.0) * SCALE, (z - HEIGHT_OFFSET) * SCALE, (1024.0 - y) * SCALE


def world_to_source(position):
    x, y, z = position
    return x / SCALE + 1024.0, 1024.0 - z / SCALE, y / SCALE + HEIGHT_OFFSET


def sample_height(heights, metadata, x, y):
    grid = metadata["grid"]
    step = metadata["stepMetres"]
    origin = metadata["origin"]
    size = metadata["sizeMetres"]
    column = min(grid - 1.0, max(0.0, (x - origin[0]) / step))
    row = min(grid - 1.0, max(0.0, (origin[1] + size - y) / step))
    x0 = int(column)
    y0 = int(row)
    x1 = min(grid - 1, x0 + 1)
    y1 = min(grid - 1, y0 + 1)
    fx = column - x0
    fy = row - y0
    top = heights[y0 * grid + x0] * (1.0 - fx) + heights[y0 * grid + x1] * fx
    bottom = heights[y1 * grid + x0] * (1.0 - fx) + heights[y1 * grid + x1] * fx
    return top * (1.0 - fy) + bottom * fy


def load_layout(path=DATA / "layout.json"):
    with Path(path).open(encoding="utf-8") as source:
        layout = json.load(source)
    if len(layout.get("compounds", [])) != 16:
        raise ValueError("Mammon's Gulch layout must contain 16 compounds")
    return layout


def extract_script_json(html, element_id):
    match = re.search(
        rf'<script type="application/json" id="{element_id}">(.*?)</script>',
        html,
        re.DOTALL,
    )
    if not match:
        raise ValueError(f"missing embedded JSON: {element_id}")
    return json.loads(match.group(1))


class Fetcher:
    def __init__(self, delay=1.05):
        self.delay = delay
        self.last_request = 0.0

    def get(self, url):
        elapsed = time.monotonic() - self.last_request
        if elapsed < self.delay:
            time.sleep(self.delay - elapsed)
        request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = response.read()
        self.last_request = time.monotonic()
        return payload


def rounded(values):
    return [round(float(value), 6) for value in values]


def compound_slug(name):
    return re.sub(r"[^a-z0-9]+", "-", name.lower().replace("'", "")).strip("-")


def parse_compound_summaries(page, expected_count=16):
    summaries = {}
    cards = re.findall(
        r'<a class="cpx-card" href="/maps/3d/mammons-gulch/([^"]+)/"[^>]*data-search="([^"]+)"',
        page,
    )
    for slug, raw_text in cards:
        text = html.unescape(raw_text)
        match = re.search(r"(\d+) storeys? · lair (?:on|in) the ([^·]+) · (\d+) clue spots", text)
        if not match:
            raise ValueError(f"unrecognized compound summary: {slug}")
        floor = match.group(2).strip()
        if floor.startswith("the "):
            floor = floor[4:]
        summaries[slug] = {
            "storeys": int(match.group(1)),
            "lairFloor": floor[:1].upper() + floor[1:],
            "clueSpots": int(match.group(3)),
            "text": text,
        }
    if len(summaries) != expected_count:
        raise ValueError(f"expected {expected_count} compound summaries, got {len(summaries)}")
    return summaries


def make_post(values, category, index, kind, heights, terrain):
    map_x, map_y = values[:2]
    source_x, source_y = normalized_to_source(map_x, map_y)
    source_z = sample_height(heights, terrain, source_x, source_y)
    return {
        "id": f"{kind}_{index + 1:02d}",
        "mapPosition": [map_x, map_y],
        "position": rounded((source_x, source_y, source_z)),
        "worldPosition": rounded(source_to_world(source_x, source_y, source_z)),
        "category": category,
        "positionConfidence": "CONFIRMED",
        "heightConfidence": "APPROXIMATED",
    }


def normalize(map_entry, map3d_entry, meta, terrain_payload, summaries):
    terrain = {
        "grid": meta["grid"],
        "origin": meta["origin"],
        "sizeMetres": meta["size"],
        "stepMetres": meta["step"],
        "zmin": meta["zmin"],
        "zmax": meta["zmax"],
        "encoding": "little-endian uint16 row deltas; cumulative value wraps at 65536; metres = zmin + value * (zmax-zmin) / 65535",
        "heightFile": "terrain.u16",
        "water": meta["water"],
        "undergroundRegions": meta.get("visareas", []),
    }
    heights = decode_heightfield(terrain_payload, terrain)
    plans = {plan["id"]: plan for plan in meta["plans"]}
    raw_points = meta["points"]
    compounds = []
    for source in map_entry["ov"]["compounds"]:
        compound_id = source["id"]
        slug = compound_slug(source["n"])
        summary = summaries[slug]
        plan = plans[compound_id]
        levels = [
            {
                "label": level["label"],
                "floor": level["floor"],
                "cut": level["cut"],
                "ground": level["ground"],
                "floorAboveGround": round(level["floor"] - level["ground"], 3),
                "confidence": "CONFIRMED",
            }
            for level in plan["levels"]
        ]
        lair = next(item for item in raw_points["lair_anchor"] if item[3] == compound_id)
        label_source = normalized_to_source(*source["c"])
        label_z = sample_height(heights, terrain, *label_source)
        bbox = source["bb"]
        min_x, north_y = normalized_to_source(bbox[0], bbox[1])
        max_x, south_y = normalized_to_source(bbox[2], bbox[3])
        details = map3d_entry["details"][compound_id]
        if summary["storeys"] != len(levels):
            raise ValueError(f"storey count mismatch for {slug}")
        compounds.append({
            "id": compound_id,
            "name": source["n"],
            "slug": slug,
            "pointOfInterest": source["poi"],
            "regionPolygon": source["poly"],
            "regionPolygonSource": [rounded(normalized_to_source(*point)) for point in source["poly"]],
            "buildingBoundsNormalized": bbox,
            "buildingBoundsSource": rounded((min_x, south_y, max_x, north_y)),
            "labelAnchor": {
                "map": source["c"],
                "source": rounded(label_source),
                "world": rounded(source_to_world(*label_source, label_z)),
            },
            "storeys": summary["storeys"],
            "levels": levels,
            "clueSpots": summary["clueSpots"],
            "clueMarkersRaw": sum(1 for item in raw_points["clue"] if item[3] == compound_id),
            "publishedSummary": summary["text"],
            "lairFloor": summary["lairFloor"],
            "lairPosition": lair[:3],
            "bossCandidates": source["bosses"],
            "creatureGroups": source["cr"],
            "soundTraps": source["an"],
            "tacticalAssessment": details["plays"],
            "lootRanges": details["lm"]["bh"],
            "referenceLinks": [
                f"{BASE_URL}/maps/#mammons-gulch",
                f"{BASE_URL}/maps/3d/mammons-gulch/{compound_slug(source['n'])}/",
            ],
            "verificationStatus": "REFERENCE_CONFIRMED__GEOMETRY_PENDING",
        })
    posts = {}
    for key, kind in (("ex", "extraction"), ("sp", "spawn"), ("rs", "resupply")):
        raw_categories = meta["posts"][kind]
        posts[kind] = [
            make_post(
                values,
                raw_categories[index][2] if index < len(raw_categories) else None,
                index,
                kind,
                heights,
                terrain,
            )
            for index, values in enumerate(map_entry["ov"][key])
        ]
    posts["resupplyRaw"] = [
        make_post((values[0] * 1000.0, values[1] * 1000.0), values[2], index, "resupply_raw", heights, terrain)
        for index, values in enumerate(meta["posts"]["resupply"])
    ]
    points = {
        key: [
            {
                "position": item[:3],
                "compoundId": item[3],
                "detail": item[4],
            }
            for item in values
        ]
        for key, values in raw_points.items()
    }
    points["stairs"] = [
        {
            "compoundId": plan["id"],
            "from": stair[:3],
            "to": stair[3:6],
            "widthMetres": stair[6],
        }
        for plan in meta["plans"]
        for stair in plan["stairs"]
    ]
    layout = {
        "id": map_entry["id"],
        "slug": map_entry["slug"],
        "name": map_entry["name"],
        "sizeMetres": meta["size"],
        "origin": meta["origin"],
        "mapUnits": 1000,
        "scaleStudsPerMetre": SCALE,
        "heightOffsetMetres": HEIGHT_OFFSET,
        "north": "source Y decreases; Roblox Z decreases",
        "scaleConfidence": "ADAPTED",
        "compounds": compounds,
        "posts": posts,
        "matchRules": map_entry["ov"]["draw"],
    }
    return layout, points, terrain


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def count_for(points, key, compound_id):
    return sum(1 for item in points.get(key, []) if item["compoundId"] == compound_id)


def generate_compound_doc(compound, points):
    name = compound["name"]
    level_rows = "\n".join(
        f"| {level['label']} | {level['floor']:.2f} | {level['floorAboveGround']:.2f} | {level['cut']:.2f} | CONFIRMED |"
        for level in compound["levels"]
    )
    boss_list = ", ".join(compound["bossCandidates"])
    creatures = "\n".join(
        f"| {item[0]} | {item[1]}–{item[2]} | среднее {item[3]} |" for item in compound["creatureGroups"]
    )
    alarms = "\n".join(f"| {item[0]} | {item[1]}–{item[2]} |" for item in compound["soundTraps"])
    tactics = "\n".join(f"- {item[1]}" for item in compound["tacticalAssessment"][4])
    refs = "\n".join(f"- {link}" for link in compound["referenceLinks"])
    anchor = compound["labelAnchor"]
    bounds = compound["buildingBoundsSource"]
    return f"""# {name}

- ID: `{compound['id']}`
- Тип: {'point of interest' if compound['pointOfInterest'] else 'compound'}
- Общий статус: `REFERENCE_CONFIRMED__GEOMETRY_PENDING`
- Этажей: **{compound['storeys']}**; точек улик: **{compound['clueSpots']}**; логово: **{compound['lairFloor']}**.
- Назначение и история: `PENDING_RESEARCH`; тематическое направление ТЗ не считается подтверждённым описанием оригинала.

## Референсы

{refs}

Координаты, этажи и игровые точки: `CONFIRMED` по числовым данным Hunt Almanac. Перевод в studs: `ADAPTED` (1 м = 3 studs до Studio-калибровки). Архитектурные детали без отдельного просмотра: `PENDING_RESEARCH`.

## География и границы

- Label anchor, source XY: `{anchor['source']}`; Roblox XYZ: `{anchor['world']}`. Это не центр масс зданий.
- Building bbox source `[minX, minY, maxX, maxY]`: `{bounds}`.
- Полигон региона хранится в `assets/mammons-gulch/reference/layout.json`.
- Высотный профиль вне измеренных точек: `PENDING_RESEARCH` до применения heightfield.

## Этажи

| Уровень | Floor, м | Над локальной землёй, м | Cut, м | Статус |
|---|---:|---:|---:|---|
{level_rows}

## Архитектура

Основные здания, вспомогательные сооружения, крыши, материалы и взаимное расположение: `PENDING_RESEARCH`. Greybox не является подтверждением финальной архитектуры.

## Входы, окна и вертикальные маршруты

| Тип | Измеренных точек | Статус |
|---|---:|---|
| Doors | {count_for(points, 'door', compound['id'])} | CONFIRMED positions; назначение проёмов требует просмотра |
| Windows | {count_for(points, 'window', compound['id'])} | CONFIRMED positions; ставни/стекло требуют просмотра |
| Ladders | {count_for(points, 'ladder', compound['id'])} | CONFIRMED positions; рабочая геометрия не создана |
| Elevators | {count_for(points, 'elevator', compound['id'])} | CONFIRMED positions; механизм не реализован |
| Stair flights | {count_for(points, 'stairs', compound['id'])} | CONFIRMED endpoints/width; рабочая геометрия не создана |

Главные/второстепенные входы, пути проникновения, переходы между зданиями и выходы: `PENDING_RESEARCH` до разбора планов и вида по сторонам света.

## Подземные помещения

Связь с `undergroundRegions` и пещерными пустотами: `PENDING_RESEARCH`. Не объявлять подземную сеть завершённой по одним маркерам.

## Тактика и линии обзора

Источник сообщает: **{compound['tacticalAssessment'][1]}**.

{tactics}

Основные/скрытые подходы, позиции защиты, длинные и короткие перестрелки, отступление и проверенные укрытия: `PENDING_RESEARCH`/`PENDING_STUDIO`.

## Игровые точки

- Clue spots по опубликованным floor plans: **{compound['clueSpots']}**; сырых clue markers: **{compound['clueMarkersRaw']}**. Координаты всех маркеров сохранены в `points.json`; при различии значений фильтрация не выдумывается. Активные точки выбирает будущий сервер матча.
- Lair anchor: `{compound['lairPosition']}`, возможные боссы: {boss_list}. Модели и AI боссов не входят в этот этап.
- NPC и звуковые ловушки ниже являются диапазонами возможных групп, а не одновременно активными спавнами.

### NPC

| Тип | Диапазон | Среднее |
|---|---:|---:|
{creatures}

### Звуковые ловушки

| Тип | Диапазон групп |
|---|---:|
{alarms}

## Необходимые ассеты

`PENDING_ASSET_RESEARCH`: архитектура, интерьеры, интерактивные объекты, VFX, audio и UI вносятся только после проверки прав и качества.

## Проверка

- Числовой dataset: `CONFIRMED` после unit tests.
- Геометрия, интерьеры, двери, лестницы, коллизии, StreamingEnabled, производительность и визуальное сравнение: `PENDING_STUDIO`.
- Критерии 90/100 не присваиваются на стадии референсов.
"""


def generate_docs(layout, points, terrain):
    DOCS.mkdir(parents=True, exist_ok=True)
    compound_dir = DOCS / "map-compounds"
    compound_dir.mkdir(parents=True, exist_ok=True)
    for compound in layout["compounds"]:
        (compound_dir / f"{compound['slug']}.md").write_text(
            generate_compound_doc(compound, points), encoding="utf-8"
        )
    compound_rows = "\n".join(
        f"| [{c['name']}](map-compounds/{c['slug']}.md) | `{c['id']}` | {'POI' if c['pointOfInterest'] else 'Compound'} | {c['storeys']} | {c['clueSpots']} | {c['lairFloor']} | REFERENCE_CONFIRMED__GEOMETRY_PENDING |"
        for c in layout["compounds"]
    )
    (DOCS / "MAP_COMPOUNDS.md").write_text(f"""# Комплексы Mammon's Gulch

Все 16 мест имеют отдельную спецификацию. Числа относятся к референсным данным Hunt Almanac, а не к уже построенной Roblox-геометрии.

| Комплекс | ID | Тип | Этажи | Улики | Логово | Статус |
|---|---|---|---:|---:|---|---|
{compound_rows}

Для каждого комплекса требуются исследование видов по сторонам света, проходимая архитектура, интерьеры, интерактивность, звук, оптимизация, Studio-проверка и отдельный commit. Порядок детализации: La Plata Mine первым; остальные только после стабилизации эталона.
""", encoding="utf-8")
    coordinate_rows = "\n".join(
        f"| {c['name']} | `{c['id']}` | {c['labelAnchor']['map'][0]:.1f}, {c['labelAnchor']['map'][1]:.1f} | {c['labelAnchor']['source'][0]:.2f}, {c['labelAnchor']['source'][1]:.2f} | {c['labelAnchor']['world'][0]:.3f}, {c['labelAnchor']['world'][2]:.3f} | {c['labelAnchor']['world'][1]:.3f} |"
        for c in layout["compounds"]
    )
    (DOCS / "MAP_WORLD_LAYOUT.md").write_text(f"""# География и координаты Mammon's Gulch

## Подтверждённая рамка

- Исходная область: **1024 × 1024 м**; source X = 512…1536, source Y = 512…1536.
- Heightfield: **513 × 513**, шаг 2 м; высоты **{terrain['zmin']:.3f}–{terrain['zmax']:.3f} м**.
- Север: исходный Y уменьшается, Roblox Z уменьшается. Карта не зеркалится.
- Начальная адаптация: **1 м = 3 studs**, мир 3072 × 3072 studs. Статус: `ADAPTED` до замеров времени маршрутов.
- `WorldX = (SourceX - 1024) * 3`; `WorldY = (SourceZ - 32.79) * 3`; `WorldZ = (1024 - SourceY) * 3`.
- Label anchors не являются центрами фундамента или bbox. Границы и полигоны находятся в `layout.json`.

## Позиции комплексов

| Комплекс | ID | Map units | Source X,Y (м) | Roblox X,Z (studs) | Roblox Y по label anchor |
|---|---|---:|---:|---:|---:|
{coordinate_rows}

## Масштаб и движение

| Величина | Значение | Статус |
|---|---:|---|
| Source map | 1024 м | CONFIRMED |
| Roblox map | 3072 studs | ADAPTED |
| Текущий WalkSpeed | 13 studs/s = 4,33 м/с | PROJECT |
| Текущий Sprint | 19 studs/s = 6,33 м/с | PROJECT |
| Референсный Sprint в Hunt Almanac | 5 м/с; после stamina 4,25 м/с | CONFIRMED reference, не новое правило проекта |
| Terrain voxel | 4 studs = 1,333 м | ADAPTED; берега и склоны требуют Studio QA |

Дороги, железная дорога, мосты и высотные связи фиксируются отдельными centerlines с confidence; до этого они не считаются готовыми.
""", encoding="utf-8")
    (DOCS / "MAP_REFERENCE_ANALYSIS.md").write_text(f"""# Исследование Mammon's Gulch

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
""", encoding="utf-8")


def refresh():
    fetcher = Fetcher()
    urls = {
        "maps": f"{BASE_URL}/maps/",
        "maps3d": f"{BASE_URL}/maps/3d/",
        "compoundsPage": f"{BASE_URL}/maps/mammons-gulch/",
    }
    map_payload = fetcher.get(urls["maps"])
    map3d_payload = fetcher.get(urls["maps3d"])
    compounds_payload = fetcher.get(urls["compoundsPage"])
    maps = extract_script_json(map_payload.decode("utf-8"), "mapdata")
    maps3d = extract_script_json(map3d_payload.decode("utf-8"), "map3d")
    summaries = parse_compound_summaries(compounds_payload.decode("utf-8"))
    map_entry = next(item for item in maps if item["slug"] == "mammons-gulch")
    map3d_entry = next(item for item in maps3d["maps"] if item["slug"] == "mammons-gulch")
    version = map3d_entry["v"]
    urls["meta"] = f"{BASE_URL}/map3d/colorado/meta.json?v={version}"
    urls["terrain"] = f"{BASE_URL}/map3d/colorado/terrain.d16?v={version}"
    urls["apiIndex"] = f"{BASE_URL}/api/v1/index.json"
    meta_payload = fetcher.get(urls["meta"])
    terrain_payload = fetcher.get(urls["terrain"])
    api_payload = fetcher.get(urls["apiIndex"])
    meta = json.loads(meta_payload)
    api = json.loads(api_payload)
    layout, points, terrain = normalize(map_entry, map3d_entry, meta, terrain_payload, summaries)
    DATA.mkdir(parents=True, exist_ok=True)
    (DATA / "terrain.u16").write_bytes(terrain_payload)
    write_json(DATA / "layout.json", layout)
    write_json(DATA / "points.json", points)
    write_json(DATA / "terrain.json", terrain)
    payloads = {
        "maps": map_payload,
        "maps3d": map3d_payload,
        "compoundsPage": compounds_payload,
        "meta": meta_payload,
        "terrain": terrain_payload,
        "apiIndex": api_payload,
    }
    write_json(DATA / "source.json", {
        "checkedAt": datetime.now(timezone.utc).isoformat(),
        "gameVersion": api.get("game_version") or api.get("gameVersion") or api.get("game", {}).get("version"),
        "credit": "Hunt Almanac (hunt.innerpulse.net), unofficial fan reference; Hunt: Showdown 1896 and game assets are © Crytek.",
        "usageReference": f"{BASE_URL}/developers/",
        "requestPolicy": "sequential requests, at least 1.05 seconds between starts",
        "contentPolicy": "numeric reference measurements only; no original images, textures, models or geometry files republished",
        "sources": {
            key: {"url": urls[key], "sha256": hashlib.sha256(payload).hexdigest()}
            for key, payload in payloads.items()
        },
    })
    generate_docs(layout, points, terrain)
    print(f"Saved {len(layout['compounds'])} compounds, {len(points)} point groups, {terrain['grid']}² heights")


def main(argv=None):
    parser = argparse.ArgumentParser(description="Refresh Mammon's Gulch numeric reference measurements")
    parser.parse_args(argv)
    refresh()


if __name__ == "__main__":
    main()
