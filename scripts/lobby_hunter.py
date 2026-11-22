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
    "Skin": ((237, 223, 209), 272),
    "Steel": ((68, 73, 74), 1088),
    "Walnut": ((89, 54, 37), 512),
    "Brass": ((131, 107, 64), 1088),
    "Eyes": ((52, 44, 37), 272),
    "Linen": ((148, 139, 116), 1312),
}


def render_hunter(stage, item, mesh_part):
    display = item(stage, "Model", "DisplayHunter")

    def add_parts(parent, mapping):
        for name, material in mapping.items():
            asset = ASSETS[name]
            # Studio's glTF importer turns both horizontal axes around Y.
            x, y, z = asset["offset"]
            position = (POSITION[0] - x, POSITION[1] + y, POSITION[2] - z)
            if name in ("Eyes", "Brow"):
                position = (position[0], position[1], position[2] + .073)
            tint, surface = MATERIALS[material]
            mesh_part(parent, name, asset, asset["size"], position, tint, material=surface,
                      yaw=180, double_sided=name.endswith("CoatTail"))

    add_parts(display, {"LeftBoot": "Leather", "RightBoot": "Leather",
                        "LeftTrousers": "Twill", "RightTrousers": "Twill"})
    upper = item(display, "Model", "UpperBody")
    add_parts(upper, {"LongCoat": "Wool", "Waistcoat": "Vest", "ShirtOpening": "Linen",
                      "CoatLapels": "Wool", "PocketFlaps": "Wool", "VestButtons": "Brass",
                      "Bandolier": "Leather", "BeltStuds": "Brass", "Belt": "Leather",
                      "Buckle": "Brass", "LeftCoatTail": "Wool", "RightCoatTail": "Wool"})
    head = item(upper, "Model", "Head")
    add_parts(head, {"Face": "Skin", "Eyes": "Eyes", "Brow": "Felt", "Scarf": "Scarf",
                     "HatCrown": "Felt", "HatBrim": "Felt", "HatBand": "Leather"})
    grip = item(upper, "Model", "Grip")
    add_parts(grip, {"LeftArm": "Wool", "RightArm": "Wool", "LeftGlove": "Leather",
                     "RightGlove": "Leather"})
    rifle = item(grip, "Model", "StageRifle")
    add_parts(rifle, {"Stock": "Walnut", "DarkSpine": "Steel", "Forewood": "Walnut",
                      "Binding": "Brass", "HeelCap": "Steel"})
