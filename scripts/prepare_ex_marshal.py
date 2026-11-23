"""Author a charcoal duster, high service hat and worn credentials for Daniel Shaw."""
import sys
from math import cos, pi, sin, tau
from pathlib import Path

from mathutils import Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
import prepare_veteran as base
from prepare_veteran import MATERIAL, PALETTE, PARTS, add, export, head, loft, plate
from prepare_veteran_face import Samples, hair, shell
from prepare_veteran_materials import project
from prepare_veteran_outfit import skirt

PALETTE.update({
    "ShawSkin": (190, 137, 105),
    "GreyHair": (93, 82, 73),
    "ShawScar": (154, 98, 84),
    "Charcoal": (58, 59, 61),
    "ShawFelt": (50, 50, 51),
    "WeatheredSilver": (128, 127, 114),
    "MarshalLeather": (54, 44, 39),
})


def face():
    head()
    for name in ("Head", "Ears", "Eyes", "Irises", "EyeSockets", "Nose", "Brow", "Mouth"):
        vertices, faces = PARTS[name]
        points = []
        for x, y, z in vertices:
            jaw = 1 + .115 * max(0, 1 - abs(y-4.65)/.39)
            lip = .86 if name == "Mouth" else 1
            points.append((x*jaw*lip, y, z))
        PARTS[name] = (points, faces)
    for name in ("Head", "Ears", "Nose"):
        MATERIAL[name] = "ShawSkin"
    MATERIAL["Brow"] = "GreyHair"
    del PARTS["Beard"], MATERIAL["Beard"]
    vertices, faces = PARTS["Head"]
    surface = BVHTree.FromPolygons(vertices, faces)
    hair(surface, "MarshalHair", "GreyHair")
    moustache = Samples()
    for row, (y, width) in enumerate([(4.648,.245),(4.668,.274),(4.687,.238),(4.710,.144)]):
        for i in range(19):
            t = i/9-1
            origin = Vector((t*width, y-.055*abs(t)**1.5, -1))
            moustache.offset(surface, origin, Vector((0,0,1)), .019 + .011*sin(pi*row/3))
    shell("MarshalMoustache", "GreyHair", moustache, 19, .028)
    scar = Samples()
    for row in range(5):
        for i in range(3):
            origin = Vector((.404+.014*row+(.012+.002*row)*(i-1), 4.668+.038*row, -1))
            scar.offset(surface, origin, Vector((0,0,1)), .006)
    shell("MarshalScar", "ShawScar", scar, 3, .012)


def hat():
    loft("ShawHat", "ShawFelt", [
        (5.31,0,.04,.585,.433),(5.41,0,.06,.603,.456),
        (5.74,-.019,.07,.574,.421),(5.903,-.028,.073,.565,.423),
        (5.952,-.034,.092,.528,.396),(5.972,-.035,.102,.430,.339),
    ], .71, 44, .021)
    loft("ShawBand", "MarshalLeather", [
        (5.39,-.010,.059,.612,.466),(5.43,-.011,.062,.610,.465),
        (5.53,-.016,.067,.607,.455),(5.563,-.014,.07,.588,.451),
    ], .73, 36, .022)
    sides = 48
    points = []
    for layer in (0, 1):
        for rim in (0, 1):
            for i in range(sides):
                angle = tau*i/sides
                rx, rz = ((.499,.371) if rim==0 else (.968,.745))
                y = 5.331+.046*layer+rim*(.037*sin(angle)**2-.014*cos(angle))
                points.append((rx*sin(angle),y,.046-rz*cos(angle)))
    faces = []
    for i in range(sides):
        j = (i+1) % sides
        for a,b in ((0,sides),(sides,3*sides),(3*sides,2*sides),(2*sides,0)):
            faces.append((a+i,a+j,b+j,b+i))
    add("ShawBrim", "ShawFelt", points, faces)


def duster():
    for side, name in ((-1,"Left"),(1,"Right")):
        skirt(name+"CoatTail", side)
        for key in (name+"CoatTail", name+"CoatTailStitch"):
            vertices, faces = PARTS[key]
            shifted = []
            for x,y,z in vertices:
                hem = max(0, min((3.076-y)/1.49,1))
                shifted.append((x*(1+.11*hem),y-.49*hem,z*(1+.12*hem)+.035*hem))
            PARTS[key] = (shifted,faces)

    columns = 35
    points = Samples()
    for y, rx, rz, lift in [(3.67,.935,.57,.20),(3.82,.932,.535,.11),(4.02,.900,.485,.06),
                            (4.18,.735,.416,.018),(4.305,.371,.291,0)]:
        for col in range(columns):
            t = col/(columns-1)
            angle = .42 + (tau-.91)*t
            asymmetry = lift * (0.48 + 0.66*sin(angle) - .69*max(0, cos(angle)))
            x = sin(angle)*rx
            z = .04 - cos(angle)*(rz+.014*sin(angle*9))
            front = Vector((x, y+asymmetry, z))
            points.append(tuple(front))
            points.normals.append((front,Vector((sin(angle),.08,-cos(angle))).normalized()))
    shell("WatchCape", "Charcoal", points, columns, .039)
    plate("ShawBadge", "WeatheredSilver", [
        (.241,3.89,-.516),(.322,3.925,-.514),(.377,3.898,-.506),(.409,3.824,-.491),
        (.373,3.752,-.501),(.313,3.705,-.516),(.251,3.756,-.533),(.212,3.825,-.540),
    ], .027)
    plate("ShawBadgeMark", "DullIron", [
        (.247,3.809,-.537),(.282,3.86,-.537),(.315,3.823,-.533),
        (.346,3.869,-.530),(.379,3.805,-.519),
    ], .023)


if __name__ == "__main__":
    base.DEST = base.DEST.parent/"Marshal"
    face()
    hat()
    duster()
    def grain(_name, mesh, _material, surface):
        if surface in {"Wool","Charcoal","ShawFelt","MarshalLeather"}:
            project(mesh, 1.7)
    export("ExMarshal", "layout.json", finish=grain, prefix="Geo_")
