import math
from pathlib import Path

from .reference import sample_height, source_to_world
from .routes import segment
from .xml import ensure, item, part, string_value

REFERENCE = Path(__file__).resolve().parents[2] / "assets" / "mammons-gulch" / "reference"


def load_hole_mask(path=REFERENCE / "holes.bin"):
    payload = Path(path).read_bytes()
    return [bool(payload[index >> 3] & (128 >> (7 & index))) for index in range(513 * 513)]


def region_levels(region):
    floor = region["z"] - region["h"]
    ceiling = region["z"]
    if ceiling - floor < 3:
        raise ValueError(f"underground region is too short: {region['name']}")
    return floor, ceiling


def polygon_centroid(region):
    points = region["pts"]
    return (
        sum(point[0] for point in points) / len(points),
        sum(point[1] for point in points) / len(points),
    )


def closest_points(first, second):
    best = None
    for first_index, first_point in enumerate(first["pts"]):
        for second_index, second_point in enumerate(second["pts"]):
            distance = math.dist(first_point, second_point)
            if best is None or distance < best[0]:
                best = (distance, first_index, second_index, first_point, second_point)
    return best


def build_graph(regions):
    nodes = [region["name"] for region in regions]
    by_name = {region["name"]: region for region in regions}
    candidates = []
    for first_index, first in enumerate(regions):
        for second in regions[first_index + 1:]:
            distance = closest_points(first, second)[0]
            candidates.append((distance, first["name"], second["name"]))
    candidates.sort()
    parents = {name: name for name in nodes}

    def find(name):
        while parents[name] != name:
            parents[name] = parents[parents[name]]
            name = parents[name]
        return name

    edges = []
    for _, first, second in candidates:
        first_root, second_root = find(first), find(second)
        if first_root == second_root:
            continue
        parents[first_root] = second_root
        edges.append((first, second))
        if len(edges) == len(nodes) - 1:
            break
    if len(edges) != len(nodes) - 1:
        raise ValueError("underground graph is disconnected")
    return nodes, edges


def nearest_hole(region, holes, heights, terrain):
    center_x, center_y = polygon_centroid(region)
    best = None
    for index, present in enumerate(holes):
        if not present:
            continue
        row, column = divmod(index, 513)
        x, y = 512 + column * 2, 1536 - row * 2
        distance = math.dist((center_x, center_y), (x, y))
        if best is None or distance < best[0]:
            best = (distance, x, y)
    if best is None or best[0] > 150:
        return None
    _, x, y = best
    return x, y, sample_height(heights, terrain, x, y)


def render_underground(root, regions, heights, terrain, holes):
    openings = {}
    for region in regions:
        model = item(root, "Model", region["name"])
        string_value(model, "Confidence", "APPROXIMATED")
        floor, ceiling = region_levels(region)
        openings[region["name"]] = []
        xs = [point[0] for point in region["pts"]]
        ys = [point[1] for point in region["pts"]]
        center_x, center_y = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
        width = max(12, (max(xs) - min(xs)) * 3)
        depth = max(12, (max(ys) - min(ys)) * 3)
        center = source_to_world(center_x, center_y, floor)
        part(model, "Floor", (width, 1, depth), (center[0], center[1] - 0.5, center[2]), (66, 62, 55), 896, collide=True)
        roof = source_to_world(center_x, center_y, ceiling)
        part(model, "Roof", (width, 1, depth), (roof[0], roof[1] + 0.5, roof[2]), (61, 58, 53), 896, collide=True)
        for index, first in enumerate(region["pts"]):
            second = region["pts"][(index + 1) % len(region["pts"])]
            start = list(source_to_world(*first, floor + 0.5))
            end = list(source_to_world(*second, floor + 0.5))
            height = max(12, (ceiling - floor - 1) * 3)
            start[1] += height / 2
            end[1] += height / 2
            openings[region["name"]].append((index, start, end, height))
    nodes, edges = build_graph(regions)
    by_name = {region["name"]: region for region in regions}
    skipped = set()
    for first_name, second_name in edges:
        first, second = by_name[first_name], by_name[second_name]
        _, first_index, second_index, first_point, second_point = closest_points(first, second)
        skipped.add((first_name, first_index))
        skipped.add((second_name, second_index))
        floor = min(region_levels(first)[0], region_levels(second)[0])
        start = source_to_world(*first_point, floor)
        end = source_to_world(*second_point, floor)
        segment(root, f"Tunnel_{first_name}_{second_name}", start, end, 12, 1, (66, 60, 51), 896, True)
        roof_start = [start[0], start[1] + 12, start[2]]
        roof_end = [end[0], end[1] + 12, end[2]]
        segment(root, f"TunnelRoof_{first_name}_{second_name}", roof_start, roof_end, 12, 1, (61, 57, 50), 896, True)
    for region in regions:
        name = region["name"]
        model = ensure(root, "Model", name)
        for index, start, end, height in openings[name]:
            if (name, index) in skipped:
                continue
            segment(model, f"Wall_{index + 1:02d}", start, end, 1, height, (63, 59, 52), 896, True)
        entrance = nearest_hole(region, holes, heights, terrain)
        if entrance is None:
            continue
        hole_x, hole_y, hole_z = entrance
        edge = min(region["pts"], key=lambda point: math.dist(point, (hole_x, hole_y)))
        start = source_to_world(*edge, region_levels(region)[0])
        end = source_to_world(hole_x, hole_y, hole_z + 0.25)
        segment(model, "SurfaceEntrance", start, end, 12, 1, (70, 64, 53), 896, True)
    return len(nodes), len(edges)
