"""Model a nineteenth-century travelling keeper with a rain hood and field mask."""
import sys
from math import cos, sin, tau
from pathlib import Path

from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import prepare_veteran as base
from prepare_veteran import PALETTE, PARTS, export, loft, plate
from prepare_veteran_face import Samples, shell
from prepare_veteran_materials import project
from prepare_veteran_outfit import skirt, stitch_path

PALETTE.update({
    "RainCanvas": (55, 52, 55),
    "VeilWool": (91, 50, 55),
    "OxideLeather": (90, 71, 57),
    "OldBronze": (138, 108, 72),
    "Oilcloth": (65, 59, 54),
})


def hood():
    sections = [
        (4.284,.388,.354,.640,.135), (4.436,.539,.403,.680,.117),
        (4.629,.647,.459,.695,.095), (4.853,.678,.474,.682,.078),
        (5.070,.680,.484,.657,.066), (5.284,.666,.498,.620,.062),
        (5.477,.603,.484,.541,.058), (5.609,.505,.434,.406,.068),
        (5.735,.296,.324,.190,.093), (5.792,.133,.204,.130,.115),
        (5.82,.041,.087,.065,.122),
    ]

    def swatch(name, material, columns, interval, thickness, raised=0):
        points = Samples()
        for row, (y, rx, rz, opening, center) in enumerate(sections):
            start, stop = interval(opening)
            for col in range(columns):
                angle = start+(stop-start)*col/(columns-1)
                ripple = .014*sin(angle*8+row*.6)*sin(angle*.5)
                normal = Vector((sin(angle), .06, -cos(angle)))
                point = Vector((
                    sin(angle)*(rx+ripple),
                    y+.024*sin(angle*2),
                    center-cos(angle)*(rz+ripple),
                )) + normal * raised
                points.append(tuple(point))
                points.normals.append((point,normal.normalized()))
        shell(name, material, points, columns, thickness)

    swatch("KeeperHood","RainCanvas",38,lambda opening:(opening,tau-opening),.038)
    swatch("LeftHoodFacing","VeilWool",3,lambda opening:(opening,opening+.10),.023,.015)
    swatch("RightHoodFacing","VeilWool",3,lambda opening:(tau-opening-.10,tau-opening),.023,.015)
    loft("FieldMask","OxideLeather",[
        (4.461,-.012,-.324,.265,.118), (4.522,-.009,-.379,.386,.139),
        (4.656,-.003,-.419,.461,.155),(4.778,0,-.398,.435,.174),
        (4.843,0,-.366,.352,.139), (4.91,0,-.382,.186,.108),
    ], .68, 40, .027)
    for side in (-1,1):
        plate("MaskStraps","Oilcloth", [
            (side*.34,4.729,-.459),(side*.544,4.776,-.305),
            (side*.566,4.851,-.292),(side*.346,4.817,-.445),
        ], .055)
    stitch_path("MaskSeam", [(x,4.572+.11*abs(x),-.554+.11*abs(x))
                              for x in (-.28,-.225,-.17,-.115,-.06,0,.06,.115,.17,.225,.28)], .009)


def coat():
    for side, name in ((-1,"Left"),(1,"Right")):
        skirt(name+"CoatTail",side)
        for key in (name+"CoatTail",name+"CoatTailStitch"):
            vertices, faces = PARTS[key]
            tail = []
            for x,y,z in vertices:
                hem = max(0,min((3.073-y)/1.51,1))
                wear = .047*sin(x*17+z*13)*hem**3
                tail.append((x*(1+.125*hem),y-.48*hem+wear,z*(1+.133*hem)))
            PARTS[key] = (tail,faces)
    plate("RitualStrap","Oilcloth", [
        (-.48,4.165,-.389),(-.349,4.10,-.502),(-.188,3.91,-.615),(.13,3.63,-.600),
        (.392,3.390,-.523),(.462,3.19,-.453),(.538,3.21,-.428),(.515,3.45,-.494),
        (.228,3.70,-.606),(-.138,4.008,-.548),(-.309,4.192,-.421),
    ], .044)
    plate("KeeperClasp","OldBronze", [
        (-.134,3.995,-.576),(-.057,4.044,-.594),(.037,4.039,-.594),(.111,3.984,-.587),
        (.091,3.913,-.605),(-.017,3.882,-.618),(-.106,3.92,-.592),
    ], .04)
    for n in range(2):
        xx = -.155 + n*.22
        ys = 3.640 - .063*n
        loft("ToolTokens","OldBronze",[
            (ys-.086,xx,-.615,.035,.034),(ys,xx,-.632,.070,.033),(ys+.08,xx,-.591,.054,.035),
        ], .81, 15, .034)
    loft("InstrumentSatchel","Oilcloth",[
        (2.50,-.623,.31,.144,.136),(2.56,-.667,.333,.220,.208),
        (2.779,-.678,.346,.232,.215),(2.963,-.673,.334,.212,.195),
        (3.004,-.645,.310,.170,.158),
    ], .56, 26, .059)
    plate("SatchelFlap","OxideLeather",[
        (-.858,2.98,.162),(-.489,2.99,.135),(-.485,2.80,.123),(-.638,2.719,.119),
        (-.823,2.783,.147),
    ], .072)


if __name__ == "__main__":
    base.DEST = base.DEST.parent/"Occult"
    hood()
    coat()
    def grain(_name, mesh, _material, material):
        if material in {"Wool","RainCanvas","VeilWool","OxideLeather","Oilcloth"}:
            project(mesh, 1.8)
    export("OccultHunter", "layout.json", finish=grain, prefix="Geo_")
