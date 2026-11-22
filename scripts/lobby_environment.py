"""Construct the forest outpost from reusable meshes and authored timberwork."""
import json
from math import atan2, degrees, sqrt
from pathlib import Path
from random import Random


ASSETS = json.loads((Path(__file__).resolve().parents[1] /
                     "assets/lobby/forest-assets.json").read_text())


def render_forest(stage, item, part, prop, lantern, rgb):
    def mesh(group, asset, name, position, scale=1, yaw=0, lean=0, tint=(255, 255, 255)):
        source = ASSETS[asset]
        if isinstance(scale, (int, float)):
            scale = (scale,) * 3
        size = tuple(d * s for d, s in zip(source["size"], scale))
        obj = part(group, name, size, position, tint, yaw=yaw, tilt=lean)
        obj.set("class", "MeshPart")
        prop(obj, "ContentId", "MeshId", {"url": source["mesh"]})
        prop(obj, "token", "CollisionFidelity", 2)
        surface = item(obj, "SurfaceAppearance", "ScannedMaterial")
        for key in ("ColorMap", "NormalMap", "RoughnessMap", "MetalnessMap"):
            if key in source:
                prop(surface, "ContentId", key, {"url": source[key]})
        prop(surface, "Color3", "Color", rgb(tint))
        return obj

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
    trees = [(-8, -5, 15), (9, -6, 14), (13.4, -7, 18), (-10.7, -16, 18), (6.9, -15, 17),
             (-1.7, -17, 14), (18.7, -16, 20), (-18, -15, 21), (4, -27, 23)]
    for _ in range(47):
        trees.append((rng.uniform(-55, 54), rng.uniform(-108, -25), rng.uniform(9, 26)))
    for i, (tx, tz, height) in enumerate(trees):
        close = i < 15
        y = .2 if tz > -69 else -.65
        drift_x, drift_z = rng.uniform(-1.3, 1.3), rng.uniform(-.7, .7)
        bark = shade((61, 56, 47), rng.randint(-12, 13))
        trunk = item(forest, "Model", f"Snag{i + 1:02d}")
        waist = (tx + drift_x * .42, y + height * .45, tz)
        apex = (tx + drift_x, y + height, tz + drift_z)
        beam(trunk, "TrunkBase", (tx, y, tz), waist, .055 * height, bark, 1296, True)
        beam(trunk, "TaperedTrunk", waist, apex, .038 * height, bark, 1296, True)
        for s in (-1, 1):
            factor = rng.uniform(.56, .76)
            source = (tx + drift_x * factor, y + height * factor, tz + drift_z * .46)
            end = (source[0] + s * height * .20, source[1] + height * .17, tz + rng.uniform(-2, 2))
            beam(trunk, "BrokenLimb", source, end, height * .017, bark, 1296, True)
            if close:
                mesh(trunk, "SnagBranches", "ForkedBough", end,
                     (height * .59, height * .50, height * .45), -s * 33, -s * 24,
                     shade((120, 116, 101), rng.randint(-7, 8)))
                beam(trunk, "ExposedRoot", (tx, y + .6, tz), (tx + s * 1.9, y, tz + s), .27,
                     bark, 1296, True)

    distant = item(environment, "Model", "BackgroundRidge")
    for i in range(9):
        x = -77 + i * 19
        part(distant, "ForestRidge", (42, rng.uniform(5, 13), 22), (x, -1, -93 + rng.uniform(-10, 5)),
             (62, 60, 52), 896, rng.uniform(-30, 30), shape=0)
