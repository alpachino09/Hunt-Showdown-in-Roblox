"""Build the original R15 character and isolated animation test environment."""
import json
from math import sqrt
from pathlib import Path

from generate_lobby import build, item, mesh_part, part, prop, rgb, vec

ROOT = Path(__file__).resolve().parents[1]
CHARACTERS = ROOT / "assets" / "characters"
ASSETS = CHARACTERS / "Veteran"
KIT = json.loads((ASSETS / "kit-layout.json").read_text())
STUDIO = json.loads((ASSETS / "roblox-assets.json").read_text())
for removed in ("Beard", "TempleHair"):
    del KIT[removed]
KIT.update(json.loads((ASSETS / "face-layout.json").read_text()))
STUDIO["parts"].update(json.loads((ASSETS / "face-assets.json").read_text()))
REST = json.loads((ASSETS / "rest-pose.json").read_text())
SEAMS = json.loads((ASSETS / "seam-assets.json").read_text())
SEAM_LAYOUT = json.loads((ASSETS / "seam-layout.json").read_text())

ACCESSORIES = {
    **{name: "Head" for name in ("Ears", "Eyes", "Irises", "EyeSockets", "Nose", "Brow", "ReedBeard",
                                 "Mouth", "HatCrown", "HatBand", "HatBrim", "HatClasp", "ReedHair")},
    **{name: "UpperTorso" for name in ("Vest", "LinenShirt", "VestButtons", "CoatLapels",
        "VestPockets", "TorsoStitch", "Neckerchief", "NeckerchiefKnot", "CrossBodyStrap",
        "StrapKeepers", "StrapStitches")},
    **{name: "LowerTorso" for name in ("WaistBelt", "WaistBuckle", "WaistBuckleCenter",
                                      "DispatchPouch", "PouchFlap", "PouchClasp")},
    **{name: "RightUpperLeg" for name in ("HipHolster", "HolsterEdge", "HolsterStud")},
}
for side in ("Left", "Right"):
    ACCESSORIES.update({
        side + "Thumb": side + "Hand",
        side + "Cuff": side + "LowerArm",
        side + "CuffButton": side + "LowerArm",
        side + "Sole": side + "Foot",
        side + "BootRim": side + "LowerLeg",
        side + "BootUpper": side + "LowerLeg",
        side + "CoatTailStitch": side + "CoatTail",
    })

SOCKETS = {
    "Head": {"HatAttachment": (0, 5.50, .045), "HairAttachment": (0, 5.50, .045),
             "FaceFrontAttachment": (0, 4.92, -.472), "FaceCenterAttachment": (0, 4.94, 0)},
    "UpperTorso": {"BodyBackAttachment": (0, 3.79, .42), "BodyFrontAttachment": (0, 3.79, -.45),
        "LeftCollarAttachment": (-.53,4.19,.02), "RightCollarAttachment": (.53,4.19,.02),
        "NeckAttachment": (0,4.26,-.054)},
    "LowerTorso": {"WaistFrontAttachment": (0,3.02,-.46), "WaistCenterAttachment": (0,3.02,.034),
        "WaistBackAttachment": (0,3.02,.433)},
    "LeftUpperArm": {"LeftShoulderAttachment": (-.99,4.14,.025)},
    "RightUpperArm": {"RightShoulderAttachment": (.99,4.14,.025)},
    "LeftHand": {"LeftGripAttachment": (-1.246,2.694,-.177), "SupportHand": (-1.25,2.7,-.16)},
    "RightHand": {"RightGripAttachment": (1.25,2.698,-.169), "TriggerHand": (1.25,2.7,-.16)},
    "LeftFoot": {"LeftFootAttachment": (-.533,.015,-.15)},
    "RightFoot": {"RightFootAttachment": (.533,.015,-.15)},
    "HumanoidRootPart": {"RootAttachment": tuple(REST["root"])},
}

MATERIAL_CODES = {
    "DullIron": 1088, "WornBrass": 1088, "WeatheredSilver": 1088, "OldBronze": 1088, "BoneButton": 272,
    "Skin": 272, "EyeWhite": 272,
    "BootLeather": 2309, "GloveLeather": 2309, "DarkLeather": 2309, "LeatherEdge": 2309,
}


def cf(position, turned=False):
    matrix = (-1,0,0,0,1,0,0,0,-1) if turned else (1,0,0,0,1,0,0,0,1)
    return vec(position) | {f"R{i//3}{i%3}": value for i,value in enumerate(matrix)}


def set_bool(node, name, value):
    flag = node.find(f"./Properties/bool[@name='{name}']")
    if flag is None:
        prop(node, "bool", name, str(value).lower())
    else:
        flag.text = str(value).lower()


def rig(root, name="Veteran", profile=None):
    profile = profile or {}
    if profile:
        folder = CHARACTERS / name
        layout = json.loads((folder / "layout.json").read_text())
        custom = json.loads((folder / "roblox-assets.json").read_text())
    else:
        layout, custom = {}, {}
    width = profile.get("width", 1)
    omitted = set(profile.get("omit", []))
    kit = {key: data for key, data in (KIT | layout).items() if key not in omitted}
    textures = STUDIO["parts"] | custom
    palette = profile.get("palette", {})
    anchors = ACCESSORIES | profile.get("anchors", {})

    def scaled(values):
        return (values[0]*width, values[1], values[2])

    model = item(root, "Model", name)
    costume = item(model, "Folder", "Costume")
    body_names = {end for _,end,_ in REST["joints"].values()}
    items = {}
    offsets = profile.get("offsets", {})
    centers = {
        mesh_name: tuple(value + offset for value, offset in zip(mesh["position"], offsets.get(mesh_name, (0, 0, 0))))
        for mesh_name, mesh in kit.items()
    }

    root_name = "HumanoidRootPart"
    centers[root_name] = REST["root"]
    root_part = part(model, root_name, scaled((1.82, 2, .96)), REST["root"], (130,128,116), transparency=1)
    items[root_name] = root_part
    root_part.set("referent", name + "Root")
    prop(model, "Ref", "PrimaryPart", root_part.get("referent"))
    set_bool(root_part, "Anchored", False)
    set_bool(root_part, "CanCollide", True)
    set_bool(root_part, "CanQuery", True)
    set_bool(root_part, "CastShadow", False)

    for mesh_name, mesh in kit.items():
        reference = textures[mesh_name]
        source = {"mesh": reference["mesh"], "size": mesh["size"]}
        if "textureSet" in reference:
            source.update(STUDIO["maps"][reference["textureSet"]])
        if "ColorMap" in reference:
            source["ColorMap"] = reference["ColorMap"]
        material = MATERIAL_CODES.get(mesh["surface"], 272)
        is_body = mesh_name in body_names
        tint = palette.get(mesh_name, palette.get(mesh["surface"], mesh["color"]))
        if reference.get("textureSet") == "Fabric":
            tint = tuple(round(v*.81+38) for v in tint)
        elif reference.get("textureSet") == "Leather":
            gain, lift = profile.get("leatherTint", (.40, 158))
            tint = tuple(round(v*gain+lift) for v in tint)
        node = mesh_part(model if is_body else costume, mesh_name, source, scaled(mesh["size"]), scaled(centers[mesh_name]),
                         tint, material=material, yaw=180)
        node.set("referent", name + "_" + mesh_name)
        items[mesh_name] = node
        set_bool(node, "Anchored", False)
        set_bool(node, "Massless", True)
        if is_body:
            set_bool(node, "CanQuery", True)
        if mesh_name.endswith(("UpperLeg", "LowerLeg")):
            node.find("./Properties/float[@name='Transparency']").text = "1"

    def local_frame(name, point):
        delta = [a-b for a,b in zip(point, centers[name])]
        turned = name != root_name
        if turned:
            delta[0] *= -1
            delta[2] *= -1
        return cf(scaled(delta), turned)

    def socket(parent, name, point):
        marker = item(items[parent], "Attachment", name)
        prop(marker, "CoordinateFrame", "CFrame", local_frame(parent, point))

    def refs(node, parent, child):
        prop(node, "Ref", "Part0", items[parent].get("referent"))
        prop(node, "Ref", "Part1", items[child].get("referent"))

    def motor(name, parent, child, point, attachments=False):
        joint = item(items[child], "Motor6D", name)
        refs(joint, parent, child)
        for key, target in (("C0", parent), ("C1", child)):
            prop(joint, "CoordinateFrame", key, local_frame(target, point))
            if attachments:
                socket(target, name + "RigAttachment", point)

    for joint, (parent, child, point) in REST["joints"].items():
        motor(joint, parent, child, point, attachments=True)
    for side, sign in (("Left", -1), ("Right", 1)):
        if side + "CoatTail" in items:
            motor(side + "Hem", "LowerTorso", side + "CoatTail", (sign*.50,3.00,.077))
    for child, parent in anchors.items():
        if child not in items:
            continue
        weld = item(items[child], "Weld", child + "Mount")
        refs(weld, parent, child)
        prop(weld, "CoordinateFrame", "C0", local_frame(parent, centers[child]))
        prop(weld, "CoordinateFrame", "C1", local_frame(child, centers[child]))
    for parent, sockets in SOCKETS.items():
        for attachment, point in sockets.items():
            socket(parent, attachment, point)

    for side in ("Left", "Right"):
        for joint in ("Knee", "Elbow"):
            mesh_name = side + joint + "Cloth"
            kind = mesh_name if joint == "Knee" else "ElbowCloth"
            parent, _, pivot = REST["joints"][side + joint]
            source = SEAMS[kind] | STUDIO["maps"]["Fabric"]
            dx, dy, dz = source["center"]
            center = (pivot[0]-dx, pivot[1]+dy, pivot[2]-dz)
            surface = SEAM_LAYOUT[kind]
            tint = palette.get(surface["surface"], surface["color"])
            tint = tuple(round(v*.81+38) for v in tint)
            wrap = mesh_part(costume, mesh_name, source, scaled(source["size"]), scaled(center), tint, material=272, yaw=180)
            wrap.set("referent", name + "_" + mesh_name)
            items[mesh_name] = wrap
            set_bool(wrap, "Anchored", False)
            set_bool(wrap, "Massless", True)
            set_bool(wrap, "HasSkinnedMesh", True)
            weld = item(wrap, "Weld", "ClothMount")
            refs(weld, parent, mesh_name)
            prop(weld, "CoordinateFrame", "C0", local_frame(parent, center))
            prop(weld, "CoordinateFrame", "C1", cf((0,0,0), True))
            anchor = item(wrap, "Bone", kind + "Parent")
            prop(anchor, "CoordinateFrame", "CFrame", cf(scaled((-dx,-dy,-dz))))
            for label in ("Bend", "Fold"):
                bone = item(anchor, "Bone", kind + label)
                x, y, z, *matrix = source[label.lower()]
                basis = vec((x,y,z)) | {f"R{i//3}{i%3}": value for i,value in enumerate(matrix)}
                prop(bone, "CoordinateFrame", "CFrame", basis)

    humanoid = item(model, "Humanoid", "Humanoid")
    prop(humanoid, "token", "RigType", 1)
    prop(humanoid, "token", "DisplayDistanceType", 2)
    prop(humanoid, "float", "HipHeight", 1.93)
    prop(humanoid, "float", "WalkSpeed", 13)
    prop(humanoid, "bool", "BreakJointsOnDeath", "false")
    item(humanoid, "Animator", "Animator")


def roster(root):
    folder = item(root, "Folder", "HunterRoster")
    rig(folder)
    for profile_path in sorted(CHARACTERS.glob("*/profile.json")):
        profile = json.loads(profile_path.read_text())
        rig(folder, profile_path.parent.name, profile)
    refs = [obj.get("referent") for obj in folder.iter("Item") if "referent" in obj.attrib]
    assert len(refs) == len(set(refs)), "Hunter roster contains repeated XML referents"


def arena(root):
    model = item(root, "Model", "CharacterQualityLab")

    def solid(name, size, position, color, material=800, tilt=0):
        obj = part(model, name, size, position, color, material, tilt=tilt)
        set_bool(obj, "CanCollide", True)
        set_bool(obj, "CanQuery", True)
        return obj

    solid("MainFloor", (72, 1, 80), (0, -.5, -12), (77, 79, 80), 800)
    solid("Ramp", (14, .55, 5.0), (-11.4, 1.38, -8.0), (97, 97, 90), 528, tilt=13)
    solid("RampDeck", (8,.60,5),(-.8,2.90,-8.0),(84,84,81),528)
    for index in range(7):
        height = (1+index)*.38
        solid(f"StairTread{index+1}",(4.5,height,1.4),(9,height*.5,-8-index*1.4),
              (95+index*3,93+index*3,85+index*2),528)
    solid("Landing",(4.5,2.66,5.6),(9,1.33,-19.9),(107,101,94),528)
    solid("LowBeam", (3.5,.46,.54), (18,.23,7), (112,91,66), 528)
    solid("CargoCrate", (2.1,1.3,1.2), (18,.65,2.9), (92,75,54), 528)
    solid("CameraPlatform", (5,.18,5), (-19,.09,11), (86,82,74), 528)
    for i in range(10):
        part(model, "DistanceMarker", (3.1,.014,.042), (0, .009, 11-i*4),
             (154,136,101), 272)
    part(model, "Spawn", (1,1,1), (0,REST["root"][1]+.04,11),(100,88,71), transparency=1)


def motion(root, names=None):
    folder = item(root, "Folder", "VeteranMotion")
    path = ROOT / "assets" / "animations" / "Locomotion" / "veteran-motion.json"
    data = json.loads(path.read_text())
    joint_list = item(folder, "StringValue", "Joints")
    prop(joint_list, "string", "Value", json.dumps(data["joints"], separators=(",", ":")))
    for name, clip in data["clips"].items():
        if names is not None and name not in names:
            continue
        encoded = json.dumps(clip, separators=(",", ":"))
        assert len(encoded) < 200_000, f"{name} exceeds the Studio StringValue limit"
        value = item(folder, "StringValue", name)
        prop(value, "string", "Value", encoded)


def props(root):
    folder = item(root, "Folder", "HunterProps")

    def mount(name):
        model = item(folder, "Model", name)
        anchor = part(model, "Mount", (.15, .15, .15), (0, 0, 0), (0, 0, 0), transparency=1)
        anchor.set("referent", name + "Mount")
        prop(model, "Ref", "PrimaryPart", anchor.get("referent"))
        prop(anchor, "bool", "CastShadow", "false")
        set_bool(anchor, "Anchored", False)
        set_bool(anchor, "Massless", True)
        return model, anchor

    def link(node, anchor):
        set_bool(node, "Anchored", False)
        set_bool(node, "Massless", True)
        node.set("referent", anchor.get("referent") + node.find("./Properties/string[@name='Name']").text)
        weld = item(node, "Weld", "PropMount")
        prop(weld, "Ref", "Part0", anchor.get("referent"))
        prop(weld, "Ref", "Part1", node.get("referent"))
        pose = node.find("./Properties/CoordinateFrame[@name='CFrame']")
        prop(weld, "CoordinateFrame", "C0", {c.tag: c.text for c in pose})

    def normalize(vector):
        length = sqrt(sum(v*v for v in vector))
        return tuple(v/length for v in vector)

    def dot(a, b):
        return sum(x*y for x, y in zip(a,b))

    def cross(a, b):
        return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])

    def point(world):
        offset = tuple((v-o)*.88 for v, o in zip(world, grip))
        return tuple(dot(offset, axis) for axis in axes)

    longarm, anchor = mount("Rifle")
    source = json.loads((ROOT / "assets" / "lobby" / "hunter-assets.json").read_text())
    grip = (.388, 2.242, .641)
    forward = normalize((-1.206, 1.099, .119))
    right = normalize(cross(forward, (.67, .74, 0)))
    axes = (right, cross(right, forward), tuple(-v for v in forward))
    for name, tint, surface in [
        ("Stock", (87, 46, 28), 512), ("DarkSpine", (59, 63, 64), 1088),
        ("Forewood", (73, 42, 29), 512), ("Binding", (120, 100, 67), 1088),
        ("HeelCap", (53, 56, 57), 1088),
    ]:
        ref = source[name]
        x, y, z = ref["offset"]
        node = mesh_part(longarm, name, ref, tuple(v*.88 for v in ref["size"]), point((-x,y,-z)),
                         tint, material=surface)
        pose = node.find("./Properties/CoordinateFrame[@name='CFrame']")
        for row, axis in enumerate(axes):
            for col, value in enumerate(axis):
                pose.find(f"R{row}{col}").text = str(value * (-1 if col != 1 else 1))
        link(node, anchor)
    support = item(anchor, "Attachment", "Support")
    prop(support, "CoordinateFrame", "CFrame", cf(point((-.19, 2.72, .67))))

    sidearm, anchor = mount("Pistol")
    for name, size, pos, tint, surf, tilt in [
        ("Handle", (.134,.265,.15), (0,-.018,.028), (75,38,25), 512, -14),
        ("Frame", (.141,.154,.28), (0,.115,-.081), (57,59,63), 1088, 0),
        ("Breech", (.18,.17,.159), (0,.126,-.105), (77,78,76), 1088, 0),
        ("Spine", (.101,.093,.34), (0,.173,-.31), (58,61,63), 1088, 0),
        ("Cap", (.13,.065,.105), (0,.161,-.49), (45,48,51), 1088, 0),
        ("Sight", (.034,.030,.037), (0,.223,-.431), (125,111,80), 1088, 0),
    ]:
        link(part(sidearm, name, size, pos, tint, material=surf, tilt=tilt), anchor)


if __name__ == "__main__":
    build("HunterRoster", roster)
    build("HunterLab", arena)
    build("VeteranMotion", motion)
    build("VeteranIdleMotion", lambda root: motion(root, {"Idle"}))
    build("HunterProps", props)
