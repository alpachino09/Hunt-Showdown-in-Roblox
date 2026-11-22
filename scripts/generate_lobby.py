"""Build the original station and editable Roblox GUI from deterministic source."""

from math import cos, radians, sin
from pathlib import Path
from random import Random
from xml.etree import ElementTree as xml

OUTPUT = Path(__file__).resolve().parents[1] / "build" / "generated"


def prop(obj, kind, name, value):
    properties = obj.find("Properties")
    node = xml.SubElement(properties, kind, name=name)
    if isinstance(value, dict):
        for key, val in value.items():
            xml.SubElement(node, key).text = str(val)
    else:
        node.text = str(value)


def item(parent, kind, name):
    obj = xml.SubElement(parent, "Item", {"class": kind})
    xml.SubElement(obj, "Properties")
    prop(obj, "string", "Name", name)
    return obj


def vec(xyz):
    return dict(zip(("X", "Y", "Z"), xyz))


def rgb(color):
    return dict(zip(("R", "G", "B"), (v / 255 for v in color)))


def part(parent, name, size, pos, color, material=512, yaw=0, tilt=0,
         shape=1, transparency=0):
    obj = item(parent, "Part", name)
    a, b = radians(yaw), radians(tilt)
    c, s, d, t = cos(a), sin(a), cos(b), sin(b)
    rotation = (c*d, -c*t, s, t, d, 0, -s*d, s*t, c)
    prop(obj, "CoordinateFrame", "CFrame", vec(pos) | {
        f"R{i // 3}{i % 3}": round(n, 8) for i, n in enumerate(rotation)
    })
    prop(obj, "Vector3", "size", vec((1, 1, 1) if shape == 0 else size))
    prop(obj, "Color3uint8", "Color3uint8", (255 << 24) | (color[0] << 16) | (color[1] << 8) | color[2])
    prop(obj, "token", "Material", material)
    prop(obj, "token", "shape", 1 if shape == 0 else shape)
    if shape == 0:
        mesh = item(obj, "SpecialMesh", "Contour")
        prop(mesh, "token", "MeshType", 3)
        prop(mesh, "Vector3", "Scale", vec(size))
    prop(obj, "bool", "Anchored", "true")
    for field in ("CanCollide", "CanTouch", "CanQuery"):
        prop(obj, "bool", field, "false")
    prop(obj, "float", "Transparency", transparency)
    return obj


def light(parent, color, brightness, reach, shadows=True):
    lamp = item(parent, "PointLight", "Light")
    prop(lamp, "Color3", "Color", rgb(color))
    prop(lamp, "float", "Brightness", brightness)
    prop(lamp, "float", "Range", reach)
    prop(lamp, "bool", "Shadows", str(shadows).lower())


def lantern(parent, name, x, y, z, reach):
    metal = (62, 46, 30)
    lamp = item(parent, "Model", name)
    for dy in (0, 0.81):
        part(lamp, "Cap", (.14, .55, .55), (x, y+dy, z), metal, 1088, tilt=90, shape=2)
    for dx in (-.20, .20):
        for dz in (-.20, .20):
            part(lamp, "Cage", (.045, .8, .045), (x+dx, y+.40, z+dz), metal, 1088)
    flame = part(lamp, "Mantle", (.31, .51, .31), (x, y+.39, z), (255, 169, 78), 288, shape=0)
    prop(flame, "bool", "CastShadow", "false")
    light(flame, (255, 167, 89), 1.65, reach)


def station(root):
    stage = item(root, "Model", "Station")
    room = item(stage, "Model", "RailwayOffice")
    rng = Random(301)
    wood = (55, 40, 33)
    iron = (38, 43, 46)
    for i in range(30):
        shade = rng.randrange(-9, 9)
        part(room, "Floorboard", (.72, .24, 21), (-10.8+i*.74, -.12, 0),
             tuple(v+shade for v in (75, 56, 44)), 528)
    # Separate framing leaves an actual window opening at the right of the back wall.
    for center, width, bottom, top in ((-3, 16, 0, 9), (9, 4, 0, 9),
                                       (6, 2, 0, 3.2), (6, 2, 6.7, 9)):
        for row in range(round((top-bottom)/.38)):
            shade = rng.randrange(-6, 6)
            part(room, "Wallboard", (width, .36, .27), (center, bottom+row*.38+.18, -6.8),
                 tuple(v+shade for v in wood), 528)
    for x in (-10.7, -5.3, -.25, 5, 7, 10.7):
        part(room, "WallPost", (.38, 8.8, .5), (x, 4.4, -6.5), (83, 61, 44), 528)
    for x in (-11, 11):
        part(room, "SideWall", (.32, 9, 19), (x, 4.5, 1.8), wood, 528)
    part(room, "Ceiling", (22, .3, 19), (0, 9, 1.8), (37, 29, 24), 528)
    for z in (-6, -2, 2, 6):
        part(room, "Rafter", (22, .37, .55), (0, 8.71, z), (83, 61, 44), 528)

    window = item(room, "Model", "SignalWindow")
    for y in (3.22, 5, 6.7):
        part(window, "Sash", (2.22, .14, .4), (6, y, -6.58), wood, 528)
    for x in (5, 6, 7):
        part(window, "Mullion", (.12, 3.45, .37), (x, 4.96, -6.55), wood, 528)
    through = part(window, "Moonlight", (1, 1, 1), (6, 5.9, -6.2), iron, transparency=1)
    light(through, (121, 177, 196), 1.55, 24)
    part(room, "NightSkyBackdrop", (27, 12, .2), (0, 6, -13.9), (27, 46, 61), 288)
    for i in range(12):
        x, z = rng.uniform(1, 10), rng.uniform(-13.4, -9)
        part(room, "TreeTrunk", (.16, 9, .16), (x, 3, z), (18, 25, 31), 512)
        for y, w in ((4.0, 1.3), (5.1, 1.12), (6.0, .8)):
            part(room, "PineSilhouette", (w, 2.15, .28), (x, y, z), (18, 25, 31), tilt=-15)

    props = item(stage, "Model", "StationFurnishings")
    part(props, "DispatchDesk", (5.7, .24, 1.65), (-2.5, 2.75, -4.45), (104, 75, 55), 528)
    for x in (-5.15, .15):
        part(props, "DeskPedestal", (.38, 2.64, 1.5), (x, 1.32, -4.45), wood, 528)
    for x, z, angle in [(-3.95, -4.7, 12), (-2.55, -4.6, 75), (-1.45, -4.2, 8)]:
        part(props, "DispatchSheet", (.62, .027, .41), (x, 2.89, z), (191, 156, 107), yaw=angle)
    for x, y, z in [(7.6, .61, -4), (9.16, .49, -5.1), (8.03, 1.65, -4.25)]:
        part(props, "FreightCrate", (1.6, 1.02, 1.25), (x, y, z), (83, 63, 46), 528)
        for dx in (-.61, .61):
            part(props, "CrateBrace", (.15, 1.05, 1.3), (x+dx, y, z), (113, 88, 59), 528)
    for y in (3.15, 3.9, 4.65):
        part(props, "DispatchShelf", (3.6, .13, .72), (-2.6, y, -6.19), wood, 528)
        for i in range(7):
            part(props, "Logbook", (.18, .36+rng.random()*.11, .28), (-3.88+i*.29, y+.27, -6.01),
                 rng.choice(((85, 68, 44), (92, 39, 34), (67, 74, 63))), tilt=rng.randint(-8, 8))
    lantern(props, "DeskLantern", -.13, 2.88, -4.16, 14)
    lantern(props, "FreightLantern", 8.18, 2.2, -4.21, 15)
    fill = part(props, "CameraFill", (1, 1, 1), (3.5, 5.5, 3.7), iron, transparency=1)
    light(fill, (255, 213, 177), .82, 17, shadows=False)

    markers = item(stage, "Folder", "CameraMarkers")
    part(markers, "Eye", (1, 1, 1), (.0, 4.25, 9.9), iron, transparency=1)
    part(markers, "Focus", (1, 1, 1), (.85, 3.3, -.25), iron, transparency=1)

    hunter = item(stage, "Model", "DisplayHunter")
    x, z = 3.75, -.35
    coat, leather, skin, fabric = (61, 57, 49), (65, 42, 32), (128, 102, 83), (57, 57, 57)
    for side in (-1, 1):
        dx = x+side*.32
        part(hunter, "Trousers", (.52, 1.55, .55), (dx, 1.03, z), fabric, tilt=side*4, shape=0)
        part(hunter, "BootShaft", (.42, .79, .47), (dx, .56, z), leather, shape=0)
        part(hunter, "Boot", (.44, .35, .76), (dx, .19, z+.10), leather, shape=0)
    upper = item(hunter, "Model", "UpperBody")
    part(upper, "LongCoat", (1.38, 2.05, .89), (x, 2.18, z), coat, shape=0)
    part(upper, "Shoulders", (1.73, .98, .84), (x, 2.91, z), coat, shape=0)
    part(upper, "Vest", (.59, 1.18, .32), (x, 2.64, z+.29), (79, 74, 62), shape=0)
    for i in range(4):
        part(upper, "BrassButton", (.065, .065, .045), (x, 2.34+i*.2, z+.45), (138, 105, 60), 1088, shape=0)
    for side in (-1, 1):
        part(upper, "Lapel", (.21, .68, .11), (x+side*.36, 2.9, z+.34), leather, tilt=-side*19, shape=0)
    part(upper, "Belt", (1.15, .17, .62), (x, 2.03, z), leather)
    part(upper, "Buckle", (.25, .16, .061), (x, 2.03, z+.34), (143, 112, 75), 1088)
    for side, name in ((-1, "LeftSleeve"), (1, "RightSleeve")):
        arm = item(upper, "Model", name)
        dx = x+side*.78
        part(arm, "CoatSleeve", (.47, 1.24, .51), (dx, 2.42, z), coat, tilt=side*9, shape=0)
        part(arm, "Cuff", (.35, .22, .34), (dx+side*.07, 1.94, z+.07), leather, shape=0)
        part(arm, "Glove", (.32, .42, .36), (dx+side*.08, 1.72, z+.07), (82, 62, 49), shape=0)
    head = item(upper, "Model", "Head")
    part(head, "Scarf", (.75, .38, .71), (x, 3.40, z+.07), (105, 49, 42), shape=0)
    part(head, "Face", (.69, .85, .67), (x, 3.72, z+.03), skin, shape=0)
    part(head, "Nose", (.17, .24, .23), (x, 3.68, z+.36), skin, shape=0)
    part(head, "Beard", (.59, .31, .48), (x, 3.48, z+.13), (67, 43, 36), shape=0)
    for side in (-1, 1):
        part(head, "EyeShadow", (.13, .047, .064), (x+side*.155, 3.77, z+.309), (53, 41, 37), shape=0)
    part(head, "HatBrim", (.12, 1.21, 1.33), (x, 4.03, z+.01), (56, 44, 38), tilt=90, shape=2)
    part(head, "HatCrown", (.44, .81, .88), (x, 4.245, z-.01), (57, 44, 37), tilt=90, shape=2)
    part(head, "HatBand", (.105, .83, .90), (x, 4.135, z-.01), (118, 80, 58), tilt=90, shape=2)


def dim2(x_scale, x_offset, y_scale, y_offset):
    return dict(zip(("XS", "XO", "YS", "YO"), (x_scale, x_offset, y_scale, y_offset)))


def frame(parent, kind, name, size, pos, color=(16, 15, 14), alpha=1):
    obj = item(parent, kind, name)
    prop(obj, "UDim2", "Size", dim2(*size))
    prop(obj, "UDim2", "Position", dim2(*pos))
    prop(obj, "Color3", "BackgroundColor3", rgb(color))
    prop(obj, "float", "BackgroundTransparency", alpha)
    prop(obj, "int", "BorderSizePixel", 0)
    return obj


def label(parent, name, value, x, y, w, h, size, color, font=3, wrap=False, button=False):
    obj = frame(parent, "TextButton" if button else "TextLabel", name,
                (0, w, 0, h), (0, x, 0, y))
    prop(obj, "string", "Text", value)
    prop(obj, "float", "TextSize", size)
    prop(obj, "Color3", "TextColor3", rgb(color))
    prop(obj, "token", "Font", font)
    prop(obj, "token", "TextXAlignment", 0)
    if wrap:
        prop(obj, "bool", "TextWrapped", "true")
        prop(obj, "token", "TextYAlignment", 0)
    if button:
        prop(obj, "bool", "AutoButtonColor", "false")
    return obj


def lobby(root):
    ui = item(root, "ScreenGui", "Lobby")
    prop(ui, "bool", "ResetOnSpawn", "false")
    prop(ui, "int", "DisplayOrder", 1)
    shade = frame(ui, "Frame", "Shade", (.7, 0, 1, 0), (0, 0, 0, 0), (13, 12, 11), .06)
    gradient = item(shade, "UIGradient", "Fade")
    prop(gradient, "NumberSequence", "Transparency", "0 0 0 0.50 0.08 0 1 1 0 ")
    body = frame(ui, "Frame", "Menu", (0, 420, 0, 568), (0, 56, .5, 0))
    prop(body, "Vector2", "AnchorPoint", {"X": 0, "Y": .5})
    scale = item(body, "UIScale", "ResponsiveScale")
    prop(scale, "float", "Scale", 1)

    gold, pale, muted = (211, 160, 91), (240, 226, 201), (177, 158, 134)
    label(body, "Kicker", "КЕДРОВЫЙ ОКРУГ     /     1896", 0, 0, 420, 24, 16, gold, 4)
    label(body, "Title", "Серая застава", 0, 28, 420, 65, 55, pale, 15)
    frame(body, "Frame", "Rule", (0, 402, 0, 1), (0, 0, 0, 113), (112, 85, 53), 0)
    tabs = frame(body, "Frame", "Tabs", (0, 410, 0, 160), (0, 0, 0, 130))
    for i, (key, title) in enumerate([
        ("Briefing", "Экспедиция"), ("Hunter", "Охотник"),
        ("Recruitment", "Набор"), ("Equipment", "Экипировка"),
        ("Roster", "Отряд"), ("Progression", "Прогресс"),
        ("Store", "Снабжение"), ("Settings", "Настройки"),
    ]):
        tab = label(tabs, key, "   " + title, (i % 2)*207, (i//2)*38, 195, 32, 20, muted,
                    button=True)
        prop(tab, "float", "BackgroundTransparency", .16)
    frame(body, "Frame", "DetailsRule", (0, 402, 0, 1), (0, 0, 0, 295), (112, 85, 53), 0)
    details = frame(body, "Frame", "Details", (0, 405, 0, 230), (0, 0, 0, 312))
    label(details, "Heading", "", 0, 0, 400, 48, 37, pale, 15)
    label(details, "Summary", "", 0, 61, 375, 90, 21, pale, wrap=True)
    toggle = label(details, "ToggleIdle", "", 0, 173, 293, 34, 20, pale, button=True)
    prop(toggle, "Color3", "BackgroundColor3", rgb((72, 51, 32)))
    prop(toggle, "float", "BackgroundTransparency", .08)
    prop(toggle, "bool", "Visible", "false")
    for name, y in (("Primary", 144), ("Secondary", 181)):
        action = label(details, name, "", 0, y, 375, 33, 19, pale, button=True)
        prop(action, "Color3", "BackgroundColor3", rgb((72, 51, 32)))
        prop(action, "float", "BackgroundTransparency", .08)
        prop(action, "bool", "Visible", "false")
    label(body, "Footer", "ЖЕЛЕЗНОДОРОЖНЫЙ ПОСТ", 0, 539, 411, 38, 15, gold, wrap=True)


def build(name, author):
    root = xml.Element("roblox", version="4")
    author(root)
    for index, element in enumerate(root.iter("Item")):
        element.set("referent", f"RBX{index}")
    xml.indent(root, "  ")
    xml.ElementTree(root).write(OUTPUT / f"{name}.rbxmx", encoding="utf-8", xml_declaration=True)


def expedition(root, fast=False):
    world = item(root, "Model", "RushMap" if fast else "ExpeditionMap")
    x = 220
    rng = Random(1896)
    earth, wood, rock = (65, 66, 50), (73, 53, 40), (53, 57, 59)

    def solid(parent, name, size, pos, shade, material=512, yaw=0):
        node = part(parent, name, size, (x + pos[0], pos[1], pos[2]), shade, material, yaw)
        for key in ("CanQuery", "CanCollide"):
            node.find(f"./Properties/bool[@name='{key}']").text = "true"
        return node

    half_x, half_z = (36, 57) if fast else (64, 82)
    solid(world, "Ground", (2*half_x, 2, 2*half_z), (0, -1, 0), earth, 1280)
    for px in (-half_x-1, half_x+1):
        solid(world, "Ridge", (5, 10, 2*half_z+5), (px, 4, 0), rock, 896)
    for pz in (-half_z-2, half_z+2):
        solid(world, "Ridge", (2*half_x+7, 10, 5), (0, 4, pz), rock, 896)

    for i in range(17 if fast else 34):
        px = rng.choice((-1, 1)) * rng.uniform(15, half_x-5)
        pz = rng.uniform(-half_z+4, half_z-5)
        height = rng.uniform(6.5, 11.5)
        solid(world, "PineTrunk", (.52, height, .54), (px, height / 2, pz), wood, 528)
        for j in range(3):
            crown = item(world, "WedgePart", "PineCrown")
            spread = 4.7 - j * .8
            prop(crown, "Vector3", "Size", vec((spread, 4.6, spread)))
            prop(crown, "Vector3", "Position", vec((x + px, height - 1 + j * 1.55, pz)))
            prop(crown, "Color3uint8", "Color3uint8", 4281155635)
            prop(crown, "bool", "Anchored", "true")
            prop(crown, "bool", "CanCollide", "false")
            prop(crown, "bool", "CanQuery", "false")

    for i in range(11 if fast else 20):
        z = 15 + i * 3.5
        solid(world, "Sleeper", (5, .18, .64), (-2, .08, z), wood, 528)
    for px in (-3.2, -.8):
        solid(world, "Track", (.16, .22, 42 if fast else 75), (px, .24, 33 if fast else 48), (70, 73, 70), 1088)

    shed = item(world, "Model", "MineOffice")
    solid(shed, "Back", (28, 8, .6), (0, 4, -52), wood, 528)
    solid(shed, "Roof", (30, .55, 21), (0, 8.3, -42), rock, 1088)
    for px in (-14, 14):
        solid(shed, "Side", (.6, 8, 20), (px, 4, -42), wood, 528)
    for px in (-9, 9):
        solid(shed, "Front", (10, 8, .6), (px, 4, -32), wood, 528)
    for px, pz, angle in ((-11, 23, 19), (8, 9, -24), (-5, -18, 6), (17, -22, 35), (5, -48, 21)):
        solid(world, "Cover", (3.8, 2.4, 2.3), (px, 1.2, pz), wood, 528, angle)
    lantern(world, "OfficeLamp", x - 8, 1.6, -36, 19)
    escape_z = 39 if fast else 68
    lantern(world, "ExitLamp", x - 3, 1.6, escape_z, 20)

    markers = item(world, "Folder", "Markers")
    fields = {
        "Spawn": (0, 3.5, 27 if fast else 53), "Clue1": (-8, 1.1, 24), "Clue2": (11, 1.1, 9),
        "Clue3": (-3, 1.1, -16), "Warden": (0, 2, -44),
        "Drifter": (9, 2, -11), "Escape": (-3, 1.25, escape_z),
    }
    for name, (px, py, pz) in fields.items():
        part(markers, name, (.4, .4, .4), (x+px, py, pz), rock, transparency=1)


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    build("Station", station)
    build("Lobby", lobby)
    build("ExpeditionMap", expedition)
    build("RushMap", lambda root: expedition(root, fast=True))
