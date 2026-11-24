from .compounds import pascal_case
from .reference import source_to_world
from .xml import ensure, marker, part

INTERACTIVE_GROUPS = {"door", "window", "ladder", "elevator", "crankgate", "cagegate", "fence", "stairs"}
NPC_GROUPS = {"hellborn", "waterdevil"}
SOUND_GROUPS = {"attractor", "distractor"}


def grouped(parent, name):
    return ensure(parent, "Folder", name)


def render_posts(root, layout):
    for kind, root_name in (("spawn", "SpawnPoints"), ("extraction", "ExtractionPoints")):
        candidates = grouped(ensure(root, "Folder", root_name), "Candidates")
        for post in layout["posts"][kind]:
            marker(candidates, post["id"], post["worldPosition"])
    supply_root = ensure(root, "Folder", "SupplyPoints")
    for post in layout["posts"]["resupply"]:
        marker(grouped(supply_root, "Candidates"), post["id"], post["worldPosition"])
    for post in layout["posts"]["resupplyRaw"]:
        marker(grouped(supply_root, "RawCandidates"), post["id"], post["worldPosition"])
    spawn = layout["posts"]["spawn"][0]
    x, y, z = spawn["worldPosition"]
    development = part(
        ensure(root, "Folder", "SpawnPoints"),
        "DevelopmentSpawn",
        (8, 1, 8),
        (x, y + 0.5, z),
        (98, 123, 139),
        collide=True,
        kind="SpawnLocation",
    )
    from .xml import prop
    prop(development, "bool", "Neutral", "true")
    prop(development, "bool", "AllowTeamChangeOnTouch", "false")


def render_points(root, points):
    for key, values in points.items():
        if key == "clue":
            root_name = "ClueLocations"
        elif key == "lair_anchor":
            root_name = "BossLairs"
        elif key in SOUND_GROUPS:
            root_name = "SoundTraps"
        elif key in INTERACTIVE_GROUPS:
            root_name = "InteractiveObjects"
        elif key in NPC_GROUPS:
            root_name = "NPCSpawnRegions"
        else:
            continue
        group_root = grouped(ensure(root, "Folder", root_name), pascal_case(key))
        for index, point in enumerate(values):
            compound_root = grouped(group_root, pascal_case(point["compoundId"] or "Global"))
            position = source_to_world(*point.get("position", point.get("from", point.get("to"))))
            name = f"{key}_{index + 1:03d}"
            if point.get("detail"):
                name += "_" + pascal_case(str(point["detail"]))
            marker(compound_root, name, position)


def render_markers(root, layout, points):
    render_posts(root, layout)
    render_points(root, points)
