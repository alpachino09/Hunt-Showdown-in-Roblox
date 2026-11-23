"""Assemble the exported showcase meshes into the lobby's motion groups."""
import json
from pathlib import Path

ASSETS = json.loads((Path(__file__).resolve().parents[1] /
                     "assets/lobby/hunter-assets.json").read_text())

# Local coordinates are from the imported scene transform, with the root at the boots.
POSITION = (3.65, .06, -.38)
MATERIALS = {
    "Wool": ((118, 107, 90), 1312),
    "Vest": ((136, 114, 80), 1312),
    "Twill": ((90, 91, 82), 1312),
    "Leather": ((69, 49, 37), 2309),
    "Felt": ((76, 65, 53), 1312),
    "Scarf": ((112, 60, 49), 1312),
    "Skin": ((183, 161, 141), 272),
    "Steel": ((68, 73, 74), 1088),
    "Walnut": ((89, 54, 37), 512),
    "Brass": ((131, 107, 64), 1088),
    "Eyes": ((52, 44, 37), 272),
    "Linen": ((148, 139, 116), 1312),
}


def render_hunter(stage, item, part, mesh_part):
    display = item(stage, "Model", "DisplayHunter")

    def add_parts(parent, mapping):
        for name, material in mapping.items():
            asset = ASSETS[name]
            # Studio's glTF importer turns both horizontal axes around Y.
            x, y, z = asset["offset"]
            position = (POSITION[0] - x, POSITION[1] + y, POSITION[2] - z)
            size = asset["size"]
            tail = name.endswith("CoatTail")
            if tail:
                size = (size[0] * 1.11, size[1], size[2] * 1.28)
                position = (position[0], position[1], position[2] + .019)
            tint, surface = MATERIALS[material]
            mesh_part(parent, name, asset, size, position, tint, material=surface,
                      yaw=180, double_sided=tail)

    add_parts(display, {"LeftBoot": "Leather", "RightBoot": "Leather",
                        "LeftTrousers": "Twill", "RightTrousers": "Twill"})
    upper = item(display, "Model", "UpperBody")
    add_parts(upper, {"LongCoat": "Wool", "Waistcoat": "Vest", "ShirtOpening": "Linen",
                      "CoatLapels": "Wool", "PocketFlaps": "Wool", "VestButtons": "Brass",
                      "Bandolier": "Leather", "BeltStuds": "Brass", "Belt": "Leather",
                      "Buckle": "Brass", "LeftCoatTail": "Wool", "RightCoatTail": "Wool"})
    head = item(upper, "Model", "Head")
    add_parts(head, {"Face": "Skin", "Scarf": "Scarf",
                     "HatCrown": "Felt", "HatBrim": "Felt", "HatBand": "Leather"})
    glasses = item(head, "Model", "SmokedSpectacles")
    x, y, z = POSITION
    # Round wire frames perch over the bridge, with arms running back to the ears.
    for side in (-1, 1):
        cx = x + side * .141
        part(glasses, "DarkBrassRim", (.233, .180, .072), (cx, y + 4.181, z + .361),
             (88, 70, 47), 1088, shape=0)
        part(glasses, "SmokedLens", (.202, .148, .064), (cx, y + 4.183, z + .386),
             (39, 36, 29), 272, shape=0)
        part(glasses, "TempleArm", (.023, .026, .29), (cx + side * .107, y + 4.187, z + .204),
             (83, 65, 45), 1088, yaw=side*6, shape=0)
    part(glasses, "Bridge", (.098, .031, .048), (x, y + 4.216, z + .393),
         (91, 73, 49), 1088, shape=0)
    grip = item(upper, "Model", "Grip")
    add_parts(grip, {"LeftArm": "Wool", "RightArm": "Wool", "LeftGlove": "Leather",
                     "RightGlove": "Leather"})
    rifle = item(grip, "Model", "StageRifle")
    add_parts(rifle, {"Stock": "Walnut", "DarkSpine": "Steel", "Forewood": "Walnut",
                      "Binding": "Brass", "HeelCap": "Steel"})
