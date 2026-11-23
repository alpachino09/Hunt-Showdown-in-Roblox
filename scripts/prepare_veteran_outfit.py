"""Author fitted clothing panels around the Veteran's checked rest pose."""
from math import cos, pi, sin
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from prepare_veteran import PALETTE, add, export, loft, plate

PALETTE.update({
    "VestLapel": (113, 76, 47),
    "LapelCloth": (73, 53, 42),
    "Lining": (94, 54, 45),
    "Stitch": (154, 111, 69),
    "BoneButton": (163, 133, 98),
})


def front_panel(name, material, points, depth):
    plate(name, material, [(x, y, z - .072) for x, y, z in points], depth)


def stitch_path(name, points, width=.010):
    for x, y, z in points:
        plate(name, "Stitch", [(x-width, y-.018, z), (x+width, y-.007, z),
              (x+width, y+.013, z+.003), (x-width, y+.004, z+.003)], .008)


def skirt(name, side):
    rows = [
        (1.59, 1.026, .620),
        (1.73, 1.006, .622),
        (2.00, .952, .604),
        (2.43, .896, .556),
        (2.78, .817, .541),
        (3.076, .704, .411),
    ]
    columns = 24
    points, faces = [], []
    for inside in (0, 1):
        for row, (y, rx, rz) in enumerate(rows):
            for col in range(columns):
                u = col / (columns - 1)
                theta = (.55 - .12*row/len(rows)) + (pi - .51) * u
                wave = .022 * sin(theta * 11 + row*.61)
                crease = .034 * sin(theta*4+.62) - .012*sin(theta*13+row)
                edge = (.092 * sin(theta*2-1.3)-.045*side) * max(0, 1-row/3)
                x = side * sin(theta) * (rx + wave - inside*.026) + side*.038
                z = -.015 - cos(theta) * (rz + crease - inside*.026)
                points.append((x, y + edge, z))
    layer = len(rows) * columns
    for row in range(len(rows) - 1):
        for col in range(columns - 1):
            a = row*columns + col
            b = a + 1
            c = b + columns
            d = a + columns
            faces.extend(((a,b,c,d),(d+layer,c+layer,b+layer,a+layer)))
    edge = (
        [(col,col+1) for col in range(columns-1)]
        + [(layer-columns+col+1,layer-columns+col) for col in range(columns-1)]
        + [((row+1)*columns,row*columns) for row in range(len(rows)-1)]
        + [(row*columns+columns-1,(row+1)*columns+columns-1) for row in range(len(rows)-1)]
    )
    faces.extend((a,a+layer,b+layer,b) for a,b in edge)
    add(name, "Wool", points, faces)
    stitch_path(name+"Stitch", [(points[row*columns][0]+side*.019,
                                points[row*columns][1]-.010,
                                points[row*columns][2]-.018)
                               for row in range(1,len(rows)-1)], width=.007)


def outfit():
    front_panel("Vest", "Vest", [(-.473,3.168,-.337),(.463,3.164,-.342),(.482,3.715,-.392),
        (.505,4.033,-.347),(.308,4.127,-.357),(.095,3.874,-.426),(-.099,3.853,-.432),
        (-.334,4.114,-.366),(-.492,4.00,-.365)], .104)
    front_panel("LinenShirt", "Canvas", [(-.294,4.265,-.296),(.281,4.278,-.287),
        (.26,4.092,-.387),(.134,3.935,-.442),(0,3.796,-.441),(-.123,3.946,-.441),
        (-.233,4.118,-.385)], .071)
    for i in range(5):
        y = 3.267 + i*.128
        loft("VestButtons", "BoneButton", [
            (y-.023,.016,-.485-.063*(i/4),.033,.017),
            (y,.016,-.491-.063*(i/4),.039,.021),
            (y+.023,.016,-.486-.063*(i/4),.030,.016),
        ], .87, 14)
    for side, name in ((-1,"Left"),(1,"Right")):
        front = [(side*x,y,z) for x,y,z in ((.277,4.329,-.275),(.526,4.207,-.320),
             (.582,4.047,-.384),(.496,3.998,-.437),(.551,3.946,-.451),
             (.357,3.731,-.489),(.276,3.94,-.454),(.305,4.159,-.386))]
        front_panel("CoatLapels", "LapelCloth", front, .056)
        vest_flap=[(side*x,y,z) for x,y,z in ((.23,3.454,-.427),(.477,3.477,-.405),
             (.492,3.418,-.416),(.244,3.391,-.444))]
        front_panel("VestPockets", "VestLapel", vest_flap, .039)
        stitch_path("TorsoStitch", [(side*(.338+.021*i), 3.79+.049*i, -.554+.010*i)
                    for i in range(6)])
        loft(name+"Cuff", "LapelCloth", [(2.835,side*1.278,.009,.208,.208),
             (2.892,side*1.276,.009,.223,.220),(2.993,side*1.258,.013,.225,.218),
             (3.029,side*1.251,.018,.21,.212)], .63, 24, .025)
        loft(name+"CuffButton", "BoneButton", [(2.868,side*1.373,-.187,.025,.022),
             (2.898,side*1.373,-.201,.034,.024),(2.929,side*1.371,-.194,.027,.022)], .8, 14)
        loft(name+"BootRim", "GloveLeather", [
             (.958,side*.531,.032,.326,.319), (1.012,side*.53,.031,.336,.326),
             (1.055,side*.53,.031,.330,.322),
        ], .6, 26)
        skirt(name+"CoatTail", side)
    loft("Neckerchief", "Lining", [(4.197,.011,.021,.308,.262),
         (4.244,.004,.008,.352,.321),(4.322,0,.005,.354,.331),
         (4.383,0,-.014,.320,.288),(4.425,-.008,-.021,.292,.270)], .69, 28, .076)
    plate("NeckerchiefKnot", "Lining", [(-.093,4.284,-.333),(.046,4.221,-.355),
        (.208,4.148,-.366),(.173,4.061,-.380),(.015,4.153,-.390),
        (-.065,4.209,-.364)], .09)


if __name__ == "__main__":
    outfit()
    export(stem="VeteranOutfit", layout="outfit-layout.json")
