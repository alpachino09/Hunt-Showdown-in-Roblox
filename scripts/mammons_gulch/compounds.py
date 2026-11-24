import json
import math

from .reference import sample_height, source_to_world
from .xml import billboard, ensure, folder, marker, part, string_value

PALETTE = [
    (142, 133, 112), (126, 139, 133), (139, 129, 119), (118, 135, 119),
    (137, 137, 128), (118, 132, 139), (141, 134, 112), (127, 121, 112),
    (136, 128, 137), (122, 136, 130), (127, 133, 141), (141, 132, 119),
    (132, 127, 115), (126, 137, 125), (133, 130, 140), (137, 126, 124),
]
FOLDERS = (
    "Buildings", "Interiors", "Props", "Entrances", "Doors", "Windows",
    "Ladders", "Cover", "AIWaypoints", "AudioZones",
)


def pascal_case(name):
    return "".join(part for part in "".join(character if character.isalnum() else " " for character in name).split() if part)


def render_compound(parent, compound, heights, terrain, color):
    model = folder(parent, pascal_case(compound["name"]), "Model")
    string_value(model, "SourceId", compound["id"])
    for name in FOLDERS:
        folder(model, name)
    bounds = compound["buildingBoundsSource"]
    min_x, min_y, max_x, max_y = bounds
    center_x = (min_x + max_x) / 2
    center_y = (min_y + max_y) / 2
    ground_samples = [
        sample_height(heights, terrain, x, y)
        for x, y in (
            (min_x, min_y), (min_x, max_y), (max_x, min_y),
            (max_x, max_y), (center_x, center_y),
        )
    ]
    base_y = (min(ground_samples) - 32.79) * 3
    height = max(9, compound["storeys"] * 9)
    width = max(6, (max_x - min_x) * 3)
    depth = max(6, (max_y - min_y) * 3)
    center = source_to_world(center_x, center_y, min(ground_samples))
    massing = folder(ensure(model, "Folder", "Buildings"), "ReferenceMassing", "Model")
    string_value(massing, "Confidence", "APPROXIMATED")
    part(
        massing,
        "MeasuredBoundsGreybox",
        (width, height, depth),
        (center[0], base_y + height / 2, center[2]),
        color,
        collide=True,
    )
    region = ensure(model, "Folder", "RegionBoundary")
    polygon = compound["regionPolygonSource"]
    for index, start in enumerate(polygon):
        end = polygon[(index + 1) % len(polygon)]
        dx = (end[0] - start[0]) * 3
        dz = (1024 - end[1]) * 3 - (1024 - start[1]) * 3
        length = math.sqrt(dx * dx + dz * dz)
        if length < 0.01:
            continue
        middle_x = (start[0] + end[0]) / 2
        middle_y = (start[1] + end[1]) / 2
        ground = sample_height(heights, terrain, middle_x, middle_y)
        position = source_to_world(middle_x, middle_y, ground + 0.25)
        yaw = math.degrees(math.atan2(-dz, dx))
        part(region, f"Edge_{index + 1:02d}", (length, 0.35, 0.35), position, color, yaw=yaw)
    return model


def render_compounds(root, layout, heights, terrain, debug_root):
    compounds_root = ensure(root, "Folder", "Compounds")
    labels = ensure(debug_root, "Folder", "CompoundLabels")
    for index, compound in enumerate(layout["compounds"]):
        model = render_compound(compounds_root, compound, heights, terrain, PALETTE[index])
        label_position = compound["labelAnchor"]["world"]
        label = marker(labels, compound["id"], (label_position[0], label_position[1] + 30, label_position[2]))
        billboard(label, compound["name"])


def lua_string(value):
    return json.dumps(value, ensure_ascii=False)


def lua_array(values):
    return "{ " + ", ".join(f"{value:.6f}" for value in values) + " }"


def render_definitions(layout):
    lines = ["--!strict", "", "local ordered = {"]
    for compound in layout["compounds"]:
        world = compound["labelAnchor"]["world"]
        source_z = world[1] / 3 + 32.79
        source = compound["labelAnchor"]["source"] + [source_z]
        lines.extend([
            "    {",
            f"        id = {lua_string(compound['id'])},",
            f"        name = {lua_string(compound['name'])},",
            f"        slug = {lua_string(compound['slug'])},",
            f"        pointOfInterest = {str(compound['pointOfInterest']).lower()},",
            f"        storeys = {compound['storeys']},",
            f"        clueSpots = {compound['clueSpots']},",
            f"        clueMarkersRaw = {compound['clueMarkersRaw']},",
            f"        lairFloor = {lua_string(compound['lairFloor'])},",
            f"        sourceAnchor = {lua_array(source)},",
            f"        worldPosition = {lua_array(world)},",
            f"        buildingBoundsSource = {lua_array(compound['buildingBoundsSource'])},",
            f"        verificationStatus = {lua_string(compound['verificationStatus'])},",
            "    },",
        ])
    lines.extend([
        "}",
        "",
        "local byId = {}",
        "for _, definition in ordered do",
        "    byId[definition.id] = definition",
        "end",
        "",
        "return {",
        "    ordered = ordered,",
        "    byId = byId,",
        "}",
        "",
    ])
    return "\n".join(lines)
