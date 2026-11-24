"""Generate the original Lantern rig used for the weapon lab's pose checks."""

from generate_lobby import build, item, part, prop, vec
from generate_hunter_lab import cf

IRON = (51, 57, 58)
EDGE = (82, 86, 79)
BRASS = (152, 116, 64)
AMBER = (174, 113, 42)
WALNUT = (83, 48, 31)
DARK_WOOD = (58, 34, 24)
METAL = 1088
WOOD = 512


def group(model, name):
    node = item(model, "Model", name)
    origin = part(node, "Origin", (.05, .05, .05), (0, 0, 0), IRON, transparency=1)
    origin.set("referent", f"Lantern{name}Origin")
    prop(node, "Ref", "PrimaryPart", origin.get("referent"))
    return node, origin


def socket(origin, name, position):
    prop(item(origin, "Attachment", name), "CoordinateFrame", "CFrame", cf(position))


def piece(node, name, size, position, color=IRON, material=METAL, yaw=0, tilt=0, shape=1):
    part(node, name, size, position, color, material, yaw=yaw, tilt=tilt, shape=shape)


def tube(node, name, length, diameter, position, color=IRON):
    piece(node, name, (length, diameter, diameter), position, color, yaw=90, shape=2)


def lantern(root):
    model = item(root, "Model", "Lantern")
    body, origin = group(model, "Body")
    socket(origin, "RightGrip", (.03, -.13, .42))
    socket(origin, "Brace", (-.11, -.07, .06))
    socket(origin, "Sight", (0, .176, .15))

    piece(body, "Frame", (.25, .23, .46), (0, .013, .20))
    piece(body, "ReceiverShoulder", (.245, .19, .15), (0, .035, .45), EDGE)
    piece(body, "SightLeaf", (.086, .041, .054), (0, .148, .15), EDGE)
    for side in (-1, 1):
        x = side * .13
        piece(body, f"LockPlate{side}", (.015, .145, .31), (x, .024, .22), EDGE)
        piece(body, f"InventoryStud{side}", (.021, .056, .17), (x * 1.06, .033, .24), AMBER)
        for index, z in enumerate((.09, .42), start=1):
            piece(body, f"Pin{side}_{index}", (.021, .051, .051), (x * 1.08, .038, z), BRASS, shape=2)
    piece(body, "Wrist", (.195, .201, .27), (0, -.107, .50), WALNUT, WOOD, tilt=-7)
    piece(body, "StockUpper", (.209, .22, .35), (0, -.115, .686), WALNUT, WOOD)
    piece(body, "StockHeel", (.236, .283, .135), (0, -.145, .85), WALNUT, WOOD)
    piece(body, "StockToe", (.224, .157, .24), (0, -.198, .767), DARK_WOOD, WOOD)
    piece(body, "ButtPlate", (.244, .295, .037), (0, -.145, .93), EDGE)
    piece(body, "Guard", (.10, .043, .244), (0, -.26, .282), EDGE)
    for index, z in enumerate((.185, .376), start=1):
        piece(body, f"GuardShoulder{index}", (.09, .114, .042), (0, -.205, z), EDGE)
    piece(body, "Hinge", (.294, .078, .078), (0, -.023, -.009), BRASS, shape=2)

    barrel, barrel_origin = group(model, "Barrel")
    socket(barrel_origin, "LeftGrip", (-.106, -.103, -.42))
    socket(barrel_origin, "Chamber", (0, .056, -.032))
    socket(barrel_origin, "Muzzle", (0, .059, -1.58))
    tube(barrel, "Barrel", 1.51, .142, (0, .059, -.807))
    tube(barrel, "BreechCollar", .22, .222, (0, .056, -.14), EDGE)
    tube(barrel, "MuzzleRing", .059, .172, (0, .059, -1.555), EDGE)
    tube(barrel, "MuzzleShade", .004, .108, (0, .059, -1.586), (21, 22, 22))
    piece(barrel, "SightPost", (.025, .036, .055), (0, .151, -1.46), BRASS)
    piece(barrel, "Forend", (.21, .138, .65), (0, -.069, -.64), WALNUT, WOOD)
    piece(barrel, "ForendBacking", (.226, .045, .66), (0, -.123, -.64), DARK_WOOD, WOOD)
    for side in (-1, 1):
        piece(barrel, f"ForendGroove{side}", (.009, .029, .51), (side * .109, -.064, -.66), DARK_WOOD, WOOD)
    piece(barrel, "ForendBand", (.219, .146, .055), (0, -.07, -.951), BRASS)

    eject, _ = group(model, "Extractor")
    piece(eject, "Lip", (.143, .038, .052), (0, -.06, .006), BRASS)
    for name, color in (("LiveRound", (127, 48, 38)), ("SpentCase", (63, 36, 30))):
        shell, _ = group(model, name)
        tube(shell, "Sleeve", .112, .076, (0, 0, -.058), color)
        tube(shell, "Rim", .034, .085, (0, 0, .011), BRASS)


if __name__ == "__main__":
    build("Lantern", lantern)
