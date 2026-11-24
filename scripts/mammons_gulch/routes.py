import json
import math
from pathlib import Path

from .reference import sample_height, source_to_world
from .xml import ensure, item, prop, part, string_value, vec

REFERENCE = Path(__file__).resolve().parents[2] / "assets" / "mammons-gulch" / "reference"


def load_routes(path=REFERENCE / "routes.json"):
    with Path(path).open(encoding="utf-8") as source:
        return json.load(source)


def validate_routes(data):
    ids = set()
    for group in ("roads", "railways", "bridges"):
        for route in data[group]:
            if route["id"] in ids:
                raise ValueError(f"duplicate route id: {route['id']}")
            ids.add(route["id"])
            if route["widthMetres"] < 3:
                raise ValueError(f"widthMetres below playable minimum: {route['id']}")
            if route["confidence"] not in ("APPROXIMATED", "ADAPTED"):
                raise ValueError(f"unverified confidence: {route['id']}")
            if len(route["points"]) < 2:
                raise ValueError(f"route needs two endpoints: {route['id']}")
            for x, y in route["points"]:
                if not all(isinstance(value, (int, float)) and math.isfinite(value) for value in (x, y)):
                    raise ValueError(f"non-finite route point: {route['id']}")
                if not (512 <= x <= 1536 and 512 <= y <= 1536):
                    raise ValueError(f"route point outside map: {route['id']}")


def segment(parent, name, start, end, width, thickness, color, material=512, collide=True):
    direction = [end[index] - start[index] for index in range(3)]
    length = math.sqrt(sum(value * value for value in direction))
    if length < 0.001:
        return None
    right = [value / length for value in direction]
    back = [right[2], 0, -right[0]]
    back_length = math.sqrt(back[0] ** 2 + back[2] ** 2)
    if back_length < 0.001:
        back = [0, 0, 1]
    else:
        back = [value / back_length for value in back]
    up = [
        back[1] * right[2] - back[2] * right[1],
        back[2] * right[0] - back[0] * right[2],
        back[0] * right[1] - back[1] * right[0],
    ]
    center = [(start[index] + end[index]) / 2 for index in range(3)]
    obj = item(parent, "Part", name)
    prop(obj, "CoordinateFrame", "CFrame", vec(center) | {
        "R00": right[0], "R01": up[0], "R02": back[0],
        "R10": right[1], "R11": up[1], "R12": back[1],
        "R20": right[2], "R21": up[2], "R22": back[2],
    })
    prop(obj, "Vector3", "size", vec((length, thickness, width)))
    packed = (255 << 24) | (color[0] << 16) | (color[1] << 8) | color[2]
    prop(obj, "Color3uint8", "Color3uint8", packed)
    prop(obj, "token", "Material", material)
    for field in ("Anchored",):
        prop(obj, "bool", field, "true")
    for field in ("CanCollide", "CanQuery"):
        prop(obj, "bool", field, str(collide).lower())
    prop(obj, "bool", "CanTouch", "false")
    return obj


def route_positions(points, heights, terrain):
    return [source_to_world(x, y, sample_height(heights, terrain, x, y) + 0.25) for x, y in points]


def render_road(route, parent, heights, terrain, railway=False):
    model = item(parent, "Model", route["id"])
    string_value(model, "Confidence", route["confidence"])
    positions = route_positions(route["points"], heights, terrain)
    width = route["widthMetres"] * 3
    for index, (start, end) in enumerate(zip(positions, positions[1:])):
        prefix = f"Segment_{index + 1:02d}"
        segment(model, prefix, start, end, width, 0.8, (93, 91, 82), 896, True)
        if not railway:
            continue
        dx, dz = end[0] - start[0], end[2] - start[2]
        horizontal = math.sqrt(dx * dx + dz * dz)
        if horizontal < 0.001:
            continue
        offset = (dz / horizontal, 0, -dx / horizontal)
        for side in (-1, 1):
            shift = [value * side * 3 for value in offset]
            rail_start = [start[axis] + shift[axis] + (0.6 if axis == 1 else 0) for axis in range(3)]
            rail_end = [end[axis] + shift[axis] + (0.6 if axis == 1 else 0) for axis in range(3)]
            segment(model, f"Rail_{side}_{index + 1:02d}", rail_start, rail_end, 0.35, 0.3, (79, 77, 70), 1088, False)
        distance = math.sqrt(sum((end[axis] - start[axis]) ** 2 for axis in (0, 2)))
        steps = max(1, int(distance // 15))
        for step in range(steps):
            alpha = (step + 0.5) / steps
            position = [start[axis] + (end[axis] - start[axis]) * alpha for axis in range(3)]
            position[1] += 0.45
            yaw = math.degrees(math.atan2(-(end[2] - start[2]), end[0] - start[0]))
            part(model, f"Sleeper_{index + 1:02d}_{step + 1:02d}", (1.8, 0.25, 9), position, (83, 66, 48), 528, yaw=yaw)


def render_bridge(route, parent, heights, terrain):
    model = item(parent, "Model", route["id"])
    string_value(model, "Confidence", route["confidence"])
    positions = route_positions(route["points"], heights, terrain)
    width = route["widthMetres"] * 3
    for index, (start, end) in enumerate(zip(positions, positions[1:])):
        segment(model, f"Deck_{index + 1:02d}", start, end, width, 1.2, (100, 82, 60), 528, True)
        dx, dz = end[0] - start[0], end[2] - start[2]
        horizontal = math.sqrt(dx * dx + dz * dz)
        if horizontal < 0.001:
            continue
        offset = (dz / horizontal, 0, -dx / horizontal)
        for side in (-1, 1):
            shift = [value * side * (width / 2 - 0.5) for value in offset]
            rail_start = [start[axis] + shift[axis] + (3.6 if axis == 1 else 0) for axis in range(3)]
            rail_end = [end[axis] + shift[axis] + (3.6 if axis == 1 else 0) for axis in range(3)]
            segment(model, f"Guard_{side}_{index + 1:02d}", rail_start, rail_end, 0.5, 1.2, (85, 70, 52), 528, True)
        count = max(1, int(horizontal // 45))
        for pier in range(count + 1):
            alpha = pier / count
            position = [start[axis] + (end[axis] - start[axis]) * alpha for axis in range(3)]
            source_x, source_y, _ = (position[0] / 3 + 1024, 1024 - position[2] / 3, 0)
            ground = (sample_height(heights, terrain, source_x, source_y) - 32.79) * 3
            depth = position[1] - ground - 0.6
            if depth > 1:
                part(model, f"Pier_{index + 1:02d}_{pier:02d}", (2, depth, 2), (position[0], ground + depth / 2, position[2]), (83, 68, 51), 528, collide=True)


def render_routes(root, data, heights, terrain):
    validate_routes(data)
    for route in data["roads"]:
        render_road(route, ensure(root, "Folder", "Roads"), heights, terrain)
    for route in data["railways"]:
        render_road(route, ensure(root, "Folder", "Railways"), heights, terrain, railway=True)
    for route in data["bridges"]:
        render_bridge(route, ensure(root, "Folder", "Bridges"), heights, terrain)
