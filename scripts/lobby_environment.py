"""Construct the forest outpost from reusable meshes and authored timberwork."""
import json
from math import atan2, cos, degrees, radians, sin, sqrt
from pathlib import Path
from random import Random


ASSET_ROOT = Path(__file__).resolve().parents[1] / "assets" / "lobby"
ASSETS = json.loads((ASSET_ROOT / "forest-assets.json").read_text())
TREES = json.loads((ASSET_ROOT / "tree-assets.json").read_text())


def render_forest(stage, item, part, prop, lantern, rgb, mesh_part):
    def mesh(group, asset, name, position, scale=1, yaw=0, tint=(255, 255, 255)):
        source = ASSETS[asset]
        if isinstance(scale, (int, float)):
            scale = (scale,) * 3
        size = tuple(d * s for d, s in zip(source["size"], scale))
        return mesh_part(group, name, source, size, position, tint, yaw=yaw)

    def beam(parent, name, a, b, width, color, material=528, cylinder=False):
        vx, vy, vz = (b[i] - a[i] for i in range(3))
        length = sqrt(vx * vx + vy * vy + vz * vz)
        center = tuple((a[i] + b[i]) / 2 for i in range(3))
        azimuth = degrees(atan2(-vz, vx))
        elevation = degrees(atan2(vy, sqrt(vx * vx + vz * vz)))
        return part(parent, name, (length, width, width), center, color, material,
                    azimuth, elevation, shape=2 if cylinder else 1)

    def shade(base, amount):
        return tuple(max(0, min(255, channel + amount)) for channel in base)

    environment = item(stage, "Folder", "Environment")
    ground = item(environment, "Model", "TerrainDetails")
    mesh(ground, "MuddyTrail", "LeafLitterAndMud", (0, .60, -37), tint=(142, 135, 119))
    part(ground, "UnderlyingBank", (165, 2, 190), (0, -1.75, -72), (52, 48, 36), 1280)
    rng = Random(1896)
    props = item(environment, "Model", "TracksideProps")
    for index, (x, y, z, size, yaw) in enumerate([
        (-2.6, .22, 1.25, .45, 9), (6.7, .45, .4, .56, -18), (8.1, .68, -3.6, .87, 101),
        (8.9, .68, -4.1, .48, 84), (.2, .31, -2.85, .29, -80),
        (4.7, .30, -4.4, .23, 28), (-5.2, .52, -12, .98, 38),
        (11.0, .93, -17.7, 1.15, -28), (-7.9, .59, -.35, .63, 43),
    ]):
        mesh(props, "MossRockA" if index % 2 else "MossRockB", "MossyStone",
             (x, y, z), size, yaw, tint=(148, 147, 131))
    mesh(props, "SplitStump", "StumpAtTrail", (6.0, .58, -3.9), 1.58, -20, tint=(151, 139, 126))
    mesh(props, "FallenTrunk", "Windfall", (12.8, .77, -10.1), 2.4, 21, tint=(165, 152, 132))
    for x, y, z, scale, yaw in [(9.8, .89, -11.3, 3.8, 16), (8.2, .65, -10.3, 2.7, -7),
                                 (10.1, 1.95, -11.3, 2.55, 10)]:
        mesh(props, "FreightCrate", "SignalFreight", (x, y, z), scale, yaw, tint=(147, 129, 109))
    lantern(props, "SignalLamp", 8.0, 1.1, -8.7, 14)
    lantern(props, "GateLamp", 7.5, 1.6, 3.6, 11)
    part(props, "GateLampPedestal", (.52, 1.28, .60), (7.5, .95, 3.6), (68, 55, 42), 528)
    part(props, "SignalLampPost", (.36, .93, .41), (8.0, .62, -8.7), (62, 52, 41), 528)
    helpers = item(stage, "Model", "LightingHelpers")
    bounce = part(helpers, "CloudBounce", (1, 1, 1), (1.1, 4.7, 6.6),
                  (100, 107, 106), transparency=1)
    reflection = item(bounce, "PointLight", "SoftFill")
    prop(reflection, "Color3", "Color", rgb((186, 199, 209)))
    prop(reflection, "float", "Brightness", .79)
    prop(reflection, "float", "Range", 13)
    prop(reflection, "bool", "Shadows", "false")
    for _ in range(47):
        depth = rng.uniform(-38, 4)
        side = rng.choice((-1, 1))
        x = (rng.uniform(4.9, 12.3) if side == 1 else -rng.uniform(2.4, 15)) + .025 * depth
        mesh(ground, "DryBrush", "DeadUnderstory", (x, rng.uniform(.40, .74), depth),
             rng.uniform(.32, 1.26), rng.uniform(-180, 180), tint=(127, 119, 99))

    architecture = item(environment, "Model", "SignalHutAndFence")
    x, z = 14.0, -24.0
    timber = (75, 63, 49)
    for index in range(15):
        dx = -4.5 + index * .62
        if 3 <= index <= 6:
            continue
        height = 5.0 + rng.uniform(-.08, .07)
        part(architecture, "WeatheredSiding", (.58, height, .18),
             (x + dx, height / 2 + .31, z), shade(timber, rng.randint(-11, 9)), 528,
             tilt=rng.uniform(-1, 1))
    for side in (-1, 1):
        for index in range(10):
            part(architecture, "ReturnWallBoard", (.18, 5.0, .63),
                 (x + side * 4.5, 2.81, z - .33 - index * .63),
                 shade(timber, rng.randint(-10, 8)), 528)
        for end in (z, z - 6.4):
            part(architecture, "CornerUpright", (.34, 5.4, .32), (x + side * 4.53, 2.79, end),
                 (55, 43, 34), 528)
        for index in range(14):
            part(architecture, "RoofShingle", (.54, .12, 5.2),
                 (x + side * 2.28, 6.39 + rng.uniform(-.03, .03), z + .3 - index * .51),
                 shade((54, 49, 41), rng.randint(-9, 8)), 528, tilt=-side * 24)
        beam(architecture, "GableRake", (x, 7.52, z + .6), (x + side * 4.92, 5.40, z + .6),
             .20, (75, 63, 52))
    for index in range(12):
        y = 5.35 + index * .17
        width = 8.8 * (1 - (y - 5.35) / 2.12)
        part(architecture, "GableBoard", (width, .165, .14), (x, y, z),
             shade(timber, rng.randint(-6, 6)), 528)
    part(architecture, "ShadowedInterior", (8.7, 4.8, .2), (x, 2.63, z - 2.3), (28, 26, 23), 528)
    for i, (px, pz) in enumerate([(-14, -8), (-10.8, -9.8), (-7.3, -11.8), (-3.8, -13.6),
                                 (1, -15.2), (4.5, -16.3), (8.0, -17.0)]):
        height = rng.uniform(1.9, 2.7)
        beam(architecture, "FenceUpright", (px, .15, pz), (px+.13, height, pz-.08), .24,
             shade(timber, rng.randint(-9, 6)))
        if i and i != 4:
            for rail in (1.05, 1.85):
                beam(architecture, "SplitRail", (previous[0], rail, previous[1]),
                     (px, rail + rng.uniform(-.23, .08), pz), .15, (66, 56, 43))
        previous = (px, pz)

    forest = item(environment, "Model", "Forest")
    trees = [
        (-7.5, -4, 2.9), (9.4, -5.8, 3.1), (14.9, -7.4, 2.85), (-10.7, -16, 2.6),
        (7.0, -17, 2.9), (-1.4, -19, 2.3), (18.7, -16, 3.2), (-18, -15, 2.5),
        (3.1, -31, 2.85), (21.5, -28, 3.3), (-14.5, -29, 2.5),
    ]
    for i in range(23):
        band, index = divmod(i, 8)
        trees.append((-39 + index * 10 + rng.uniform(-4, 5) + band*3,
                      -37 - band * 19 + rng.uniform(-7, 5), rng.uniform(2.3, 3.55)))
    for i, (tx, tz, scale) in enumerate(trees):
        trunk = item(forest, "Model", f"WeatheredTree{i + 1:02d}")
        yaw = rng.uniform(-180, 180)
        c, s = cos(radians(yaw)), sin(radians(yaw))
        bark = shade((146, 137, 116), rng.randint(-13, 10) + min(12, i))
        for name, source in TREES.items():
            dx, dy, dz = (v * scale for v in source["offset"])
            x, z = tx + c*dx + s*dz, tz - s*dx + c*dz
            size = tuple(v * scale for v in source["size"])
            obj = mesh_part(trunk, name, source, size,
                            (x, .10 + 2.14 * scale + dy, z), bark, yaw=yaw)
            if i >= 11:
                prop(obj, "bool", "CastShadow", "false")
        if i < 7:
            mesh(trunk, "SnagBranches", "GroundTwigs", (tx + .4, .67, tz + .45),
                 3.1, yaw, tint=bark)

    distant = item(environment, "Model", "BackgroundRidge")
    for i in range(9):
        x = -77 + i * 19
        part(distant, "ForestRidge", (42, rng.uniform(5, 13), 22), (x, -1, -93 + rng.uniform(-10, 5)),
             (62, 60, 52), 896, rng.uniform(-30, 30), shape=0)
