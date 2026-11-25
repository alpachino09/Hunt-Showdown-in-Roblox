import argparse
import hashlib
import json
import struct
from datetime import datetime, timezone

from .reference import (
    BASE_URL,
    DATA,
    Fetcher,
    extract_script_json,
    load_layout,
    rounded,
    write_json,
)

OUTPUT = DATA / "la-plata-plan.json"
PAGE_URL = f"{BASE_URL}/maps/3d/mammons-gulch/la-plata-mine/"
MARK_TYPES = ("lair_anchor", "clue", "door", "window", "ladder")
MATERIAL_NAMES = ("plain", "wood", "brick", "stone", "metal", "rock", "roof", "stairs", "earth")


def decode_runs(words, offset, count):
    end = offset + count
    if offset < 0 or count < 0 or end > len(words):
        raise ValueError("truncated floor-plan run range")
    runs = []
    while offset < end:
        header = words[offset] & 0xFFFF
        point_count = header & 4095
        material = header >> 12
        offset += 1
        if offset + point_count * 2 > end:
            raise ValueError("truncated floor-plan points")
        x = 0
        y = 0
        points = []
        for _ in range(point_count):
            x += words[offset]
            y += words[offset + 1]
            points.append([round(x * 0.05 + 512.0, 6), round(y * 0.05 + 512.0, 6)])
            offset += 2
        runs.append({"points": points, "material": material})
    return runs


def decode_plan(payload, entry):
    if len(payload) % 2:
        raise ValueError("floor-plan payload must contain Int16 values")
    words = struct.unpack(f"<{len(payload) // 2}h", payload)
    levels = []
    for level in entry["levels"]:
        decoded = dict(level)
        decoded["walls"] = decode_runs(words, level.get("o", 0), level.get("n", 0))
        decoded["floors"] = (
            decode_runs(words, level["fo"], level["fn"]) if level.get("fn", 0) else []
        )
        levels.append(decoded)
    return {"id": entry["id"], "levels": levels}


def plan_bounds(walls):
    points = [point for wall in walls for point in wall["points"]]
    if not points:
        raise ValueError("a floor plan must have at least one measured wall point")
    xs = [point[0] for point in points]
    ys = [point[1] for point in points]
    return rounded((min(xs) - 3, min(ys) - 3, max(xs) + 3, max(ys) + 3))


def normalize_plan(payload, entry, bundle, published_clue_count):
    decoded = decode_plan(payload, entry)
    bounds = plan_bounds([wall for level in decoded["levels"] for wall in level["walls"]])
    stairs = [
        {
            "id": f"stair_{index + 1:02d}",
            "from": rounded(stair[:3]),
            "to": rounded(stair[3:6]),
            "widthMetres": stair[6],
            "confidence": "CONFIRMED",
        }
        for index, stair in enumerate(entry["stairs"])
    ]
    point_groups = {
        kind: [
            {
                "id": f"{kind}_{index + 1:02d}",
                "position": rounded(point[:3]),
                "variant": point[3] if len(point) > 3 else "",
                "confidence": "CONFIRMED",
            }
            for index, point in enumerate(points)
        ]
        for kind, points in bundle["pts"].items()
    }
    levels = []
    for index, level in enumerate(decoded["levels"]):
        next_floor = decoded["levels"][index + 1]["floor"] if index + 1 < len(decoded["levels"]) else None
        minimum_z = level["floor"] - 0.6
        maximum_z = next_floor - 0.6 if next_floor is not None else float("inf")
        marks = {
            kind: [
                dict(point)
                for point in point_groups.get(kind, [])
                if bounds[0] <= point["position"][0] <= bounds[2]
                and bounds[1] <= point["position"][1] <= bounds[3]
                and minimum_z <= point["position"][2] < maximum_z
            ]
            for kind in MARK_TYPES
        }
        level_stairs = [stair for stair in stairs if minimum_z <= stair["from"][2] < maximum_z]
        arriving_stairs = [
            stair for stair in stairs
            if not minimum_z <= stair["from"][2] < maximum_z
            and minimum_z <= stair["to"][2] - 0.3 < maximum_z
        ]
        levels.append({
            "id": f"level_{index}",
            "label": level["label"],
            "floor": level["floor"],
            "cut": level["cut"],
            "ground": level["ground"],
            "floorAboveGround": round(level["floor"] - level["ground"], 3),
            "top": next_floor if next_floor is not None else level["floor"] + 3.2,
            "topConfidence": "APPROXIMATED",
            "bounds": plan_bounds(level["walls"]),
            "walls": [
                {
                    "id": f"wall_{wall_index + 1:03d}",
                    **wall,
                    "materialName": MATERIAL_NAMES[wall["material"]],
                    "isStructural": wall["material"] != 7,
                    "confidence": "CONFIRMED",
                }
                for wall_index, wall in enumerate(level["walls"])
            ],
            "floors": [
                {"id": f"floor_{floor_index + 1:03d}", **floor, "confidence": "CONFIRMED"}
                for floor_index, floor in enumerate(level["floors"])
            ],
            "wallStatus": "CONFIRMED_CUT_CONTOURS__FULL_HEIGHT_ADAPTED",
            "floorStatus": "CONFIRMED_UP_FACING_SAMPLES",
            "marks": marks,
            "hasLair": bool(marks["lair_anchor"]),
            "stairs": level_stairs,
            "arrivingStairs": arriving_stairs,
        })
    return {
        "id": decoded["id"],
        "name": "La Plata Mine",
        "scale": "source metres; convert using the existing ADAPTED 3 studs/m transform",
        "bounds": bounds,
        "ground": bundle["ground"],
        "buildingBounds": bundle["box"],
        "materials": list(MATERIAL_NAMES),
        "levels": levels,
        "stairs": stairs,
        "pointGroups": point_groups,
        "clueMarkersRaw": len(point_groups.get("clue", [])),
        "clueSpotsPublished": published_clue_count,
        "lairFloor": next(level["label"] for level in levels if level["hasLair"]),
        "verificationStatus": "REFERENCE_PLAN_CONFIRMED__ARCHITECTURE_PENDING",
    }


def load_la_plata_plan(path=OUTPUT):
    with path.open(encoding="utf-8") as source:
        plan = json.load(source)
    if plan.get("id") != "com_i" or len(plan.get("levels", [])) != 4:
        raise ValueError("expected the four-level La Plata Mine plan")
    return plan


def refresh(fetcher=None):
    fetcher = fetcher or Fetcher()
    page_payload = fetcher.get(PAGE_URL)
    page = extract_script_json(page_payload.decode("utf-8"), "cp3d")
    entry = page["plan"]["entry"]
    plan_url = BASE_URL + page["plan"]["url"]
    bundle_url = BASE_URL + page["bundle"]
    decoder_url = BASE_URL + page["floorplan"]
    materials_url = BASE_URL + page["materials"]
    plan_payload = fetcher.get(plan_url)
    bundle_payload = fetcher.get(bundle_url)
    decoder_payload = fetcher.get(decoder_url)
    materials_payload = fetcher.get(materials_url)
    bundle = json.loads(bundle_payload)
    compound = next(item for item in load_layout()["compounds"] if item["id"] == "com_i")
    if [level["floor"] for level in entry["levels"]] != [level["floor"] for level in compound["levels"]]:
        raise ValueError("La Plata floor heights differ between reference snapshots")
    plan = normalize_plan(plan_payload, entry, bundle, compound["clueSpots"])
    if plan["lairFloor"] != compound["lairFloor"]:
        raise ValueError("La Plata lair floor differs from the published compound summary")
    plan["lairApproaches"] = page.get("ways", [])
    plan["checkedAt"] = datetime.now(timezone.utc).isoformat()
    plan["referenceLinks"] = [PAGE_URL, f"{BASE_URL}/developers/"]
    plan["sources"] = {
        key: {"url": url, "sha256": hashlib.sha256(payload).hexdigest()}
        for key, url, payload in (
            ("page", PAGE_URL, page_payload),
            ("plan", plan_url, plan_payload),
            ("bundle", bundle_url, bundle_payload),
            ("decoder", decoder_url, decoder_payload),
            ("materials", materials_url, materials_payload),
        )
    }
    write_json(OUTPUT, plan)
    print(
        f"Saved {len(plan['levels'])} levels, {len(plan['stairs'])} stairs, "
        f"{plan['clueMarkersRaw']} raw / {plan['clueSpotsPublished']} published clue markers"
    )
    return plan


def main(argv=None):
    parser = argparse.ArgumentParser(description="Capture measured La Plata Mine floor plans")
    parser.add_argument("--refresh", action="store_true", help="fetch a new numerical reference snapshot")
    args = parser.parse_args(argv)
    plan = refresh() if args.refresh or not OUTPUT.exists() else load_la_plata_plan()
    if not args.refresh:
        print(f"La Plata Mine: {len(plan['levels'])} levels; {plan['verificationStatus']}")


if __name__ == "__main__":
    main()
