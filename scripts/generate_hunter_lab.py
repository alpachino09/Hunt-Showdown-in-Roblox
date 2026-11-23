"""Build the original R15 character and isolated animation test environment."""
import json
from pathlib import Path

from generate_lobby import build, item, mesh_part, part, prop, rgb, vec

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "characters" / "Veteran"
KIT = json.loads((ASSETS / "kit-layout.json").read_text())
STUDIO = json.loads((ASSETS / "roblox-assets.json").read_text())
REST = json.loads((ASSETS / "rest-pose.json").read_text())

ACCESSORIES = {
    **{name: "Head" for name in ("Ears", "Eyes", "Irises", "EyeSockets", "Nose", "Brow", "Beard",
                                 "Mouth", "HatCrown", "HatBand", "HatBrim", "HatClasp", "TempleHair")},
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
    "DullIron": 1088, "WornBrass": 1088, "BoneButton": 272, "Skin": 272, "EyeWhite": 272,
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


def rig(root):
    model = item(root, "Model", "Veteran")
    costume = item(model, "Folder", "Costume")
    body_names = {end for _,end,_ in REST["joints"].values()}
    items = {}
    centers = {name: mesh["position"] for name, mesh in KIT.items()}

    root_name = "HumanoidRootPart"
    centers[root_name] = REST["root"]
    root_part = part(model, root_name, (1.82, 2, .96), REST["root"], (130,128,116), transparency=1)
    items[root_name] = root_part
    root_part.set("referent", "VeteranRoot")
    prop(model, "Ref", "PrimaryPart", "VeteranRoot")
    set_bool(root_part, "Anchored", False)
    set_bool(root_part, "CanCollide", True)
    set_bool(root_part, "CanQuery", True)
    set_bool(root_part, "CastShadow", False)

    for name, mesh in KIT.items():
        reference = STUDIO["parts"][name]
        source = {"mesh": reference["mesh"], "size": mesh["size"]}
        if "textureSet" in reference:
            source.update(STUDIO["maps"][reference["textureSet"]])
        if "ColorMap" in reference:
            source["ColorMap"] = reference["ColorMap"]
        material = MATERIAL_CODES.get(mesh["surface"], 272)
        is_body = name in body_names
        tint = mesh["color"]
        if reference.get("textureSet") == "Fabric":
            tint = tuple(round(v*.81+38) for v in tint)
        elif reference.get("textureSet") == "Leather":
            tint = tuple(round(v*.40+158) for v in tint)
        node = mesh_part(model if is_body else costume, name, source, mesh["size"], mesh["position"],
                         tint, material=material, yaw=180)
        node.set("referent", "Veteran_" + name)
        items[name] = node
        set_bool(node, "Anchored", False)
        set_bool(node, "Massless", True)
        if is_body:
            set_bool(node, "CanQuery", True)

    def local_frame(name, point):
        delta = [a-b for a,b in zip(point, centers[name])]
        turned = name != root_name
        if turned:
            delta[0] *= -1
            delta[2] *= -1
        return cf(delta, turned)

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
        motor(side + "Hem", "LowerTorso", side + "CoatTail", (sign*.50,3.00,.077))
    for child, parent in ACCESSORIES.items():
        weld = item(items[child], "Weld", child + "Mount")
        refs(weld, parent, child)
        prop(weld, "CoordinateFrame", "C0", local_frame(parent, centers[child]))
        prop(weld, "CoordinateFrame", "C1", local_frame(child, centers[child]))
    for parent, sockets in SOCKETS.items():
        for name, point in sockets.items():
            socket(parent, name, point)

    humanoid = item(model, "Humanoid", "Humanoid")
    prop(humanoid, "token", "RigType", 1)
    prop(humanoid, "token", "DisplayDistanceType", 2)
    prop(humanoid, "float", "HipHeight", 1.93)
    prop(humanoid, "float", "WalkSpeed", 13)
    prop(humanoid, "bool", "BreakJointsOnDeath", "false")
    item(humanoid, "Animator", "Animator")


def arena(root):
    model = item(root, "Model", "HunterLab")

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
    for i in range(10):
        part(model, "DistanceMarker", (3.1,.014,.042), (0, .009, 11-i*4),
             (154,136,101), 272)
    part(model, "Spawn", (1,1,1), (0,REST["root"][1]+.04,11),(100,88,71), transparency=1)


def motion(root):
    value = item(root, "StringValue", "VeteranMotion")
    path = ROOT / "assets" / "animations" / "Locomotion" / "veteran-motion.json"
    prop(value, "string", "Value", path.read_text().strip())


if __name__ == "__main__":
    build("Veteran", rig)
    build("HunterLab", arena)
    build("VeteranMotion", motion)
