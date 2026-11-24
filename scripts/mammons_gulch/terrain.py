import base64
import json
import struct
from pathlib import Path

from .reference import DATA, decode_heightfield

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "build" / "generated" / "MammonsGulchTerrainData.luau"
NO_WATER = 65535


def point_in_polygon(x, y, points):
    inside = False
    for index, first in enumerate(points):
        second = points[(index + 1) % len(points)]
        x1, y1 = first
        x2, y2 = second
        cross = (x - x1) * (y2 - y1) - (y - y1) * (x2 - x1)
        if abs(cross) < 1e-9 and min(x1, x2) - 1e-9 <= x <= max(x1, x2) + 1e-9 and min(y1, y2) - 1e-9 <= y <= max(y1, y2) + 1e-9:
            return True
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            inside = not inside
    return inside


def build_water_levels(heights, metadata, water):
    grid = metadata["grid"]
    origin = metadata["origin"]
    size = metadata["sizeMetres"]
    step = metadata["stepMetres"]
    levels = [NO_WATER] * (grid * grid)
    for region in water:
        level = region["z"]
        points = region["pts"]
        min_x = min(point[0] for point in points)
        max_x = max(point[0] for point in points)
        min_y = min(point[1] for point in points)
        max_y = max(point[1] for point in points)
        first_column = max(0, int((min_x - origin[0]) // step))
        last_column = min(grid - 1, int((max_x - origin[0]) // step) + 1)
        first_row = max(0, int((origin[1] + size - max_y) // step))
        last_row = min(grid - 1, int((origin[1] + size - min_y) // step) + 1)
        for row in range(first_row, last_row + 1):
            source_y = origin[1] + size - row * step
            for column in range(first_column, last_column + 1):
                index = row * grid + column
                source_x = origin[0] + column * step
                if heights[index] < level and point_in_polygon(source_x, source_y, points):
                    levels[index] = max(levels[index] if levels[index] != NO_WATER else -1e9, level)
    return levels


def pack_u16_levels(levels, zmin, zmax):
    values = []
    for level in levels:
        if level == NO_WATER:
            values.append(NO_WATER)
        else:
            values.append(round((level - zmin) / (zmax - zmin) * 65535))
    return struct.pack(f"<{len(values)}H", *values)


def generate_terrain_data(output=OUTPUT):
    metadata = json.loads((DATA / "terrain.json").read_text(encoding="utf-8"))
    raw_heights = (DATA / "terrain.u16").read_bytes()
    heights = decode_heightfield(raw_heights, metadata)
    water_levels = build_water_levels(heights, metadata, metadata["water"])
    water_payload = pack_u16_levels(water_levels, metadata["zmin"], metadata["zmax"])
    source = f"""return {{
    grid = {metadata['grid']},
    origin = {{ {metadata['origin'][0]}, {metadata['origin'][1]} }},
    sizeMetres = {metadata['sizeMetres']},
    stepMetres = {metadata['stepMetres']},
    zmin = {metadata['zmin']},
    zmax = {metadata['zmax']},
    studsPerMetre = 3,
    heightOffsetMetres = 32.79,
    heightData = \"{base64.b64encode(raw_heights).decode('ascii')}\",
    waterData = \"{base64.b64encode(water_payload).decode('ascii')}\",
    holesData = \"{base64.b64encode((DATA / 'holes.bin').read_bytes()).decode('ascii')}\",
    undergroundJson = {json.dumps(json.dumps(metadata['undergroundRegions'], ensure_ascii=False))},
}}
"""
    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(source, encoding="utf-8")
    return output


def main():
    output = generate_terrain_data()
    print(f"Generated {output.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
