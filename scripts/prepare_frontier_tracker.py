"""Model the original tracker using the same R15 rest coordinates as Elias."""
import sys
from math import cos, pi, sin
from pathlib import Path

from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
import prepare_veteran as base
from prepare_veteran import PARTS, MATERIAL, PALETTE, export, head, loft, plate
from prepare_veteran_face import hair
from prepare_veteran_materials import project
from prepare_veteran_outfit import skirt

DEST = base.DEST.parent / "Tracker"
PALETTE.update({
    "ValeSkin": (166, 122, 96),
    "ValeHair": (69, 42, 31),
    "ValeBrow": (72, 44, 34),
    "ValeEye": (66, 76, 55),
    "ScoutFelt": (75, 80, 61),
    "ScoutCanvas": (171, 155, 111),
    "ScoutLeather": (52, 45, 40),
    "MapPaper": (167, 145, 99),
    "MapWax": (107, 51, 34),
})


def face():
    head()
    for name in ("Head", "Ears", "Eyes", "Irises", "EyeSockets", "Nose", "Brow", "Mouth"):
        vertices, faces = PARTS[name]
        points = []
        for x, y, z in vertices:
            jaw = 0.76 + 0.19 * min(max((y-4.38)/.56, 0), 1)
            nose = 0.77 if name == "Nose" else 1
            lift = (.019 * abs(x) - .014) if name == "Brow" else 0
            points.append((x*jaw*nose, y+lift, z*.947))
        PARTS[name] = (points, faces)
    for name, material in {
        "Head":"ValeSkin", "Ears":"ValeSkin", "Nose":"ValeSkin", "Brow":"ValeBrow",
        "Irises":"ValeEye",
    }.items():
        MATERIAL[name] = material
    del PARTS["Beard"], MATERIAL["Beard"]
    vertices, faces = PARTS["Head"]
    surface = BVHTree.FromPolygons(vertices, faces)
    hair(surface, name="TrackHair", material="ValeHair")
    loft("TrackPlait", "ValeHair", [
        (4.102,.246,.424,.051,.050), (4.19,.252,.483,.087,.059),
        (4.30,.239,.501,.097,.078), (4.456,.226,.477,.098,.106),
        (4.59,.190,.395,.136,.124), (4.77,.124,.394,.153,.125),
    ], .82, 24, .092)
    loft("TrackHairTie", "ScoutCanvas", [
        (4.17,.250,.468,.081,.065),(4.203,.250,.477,.101,.074),(4.235,.249,.483,.099,.069),
    ], .84, 16, .032)


def costume():
    loft("ScoutCap", "ScoutFelt", [
        (5.345,-.014,.053,.523,.403),(5.401,-.020,.055,.577,.438),
        (5.481,-.046,.057,.599,.449),(5.585,-.073,.073,.538,.397),
        (5.643,-.092,.105,.404,.301),(5.665,-.09,.12,.269,.210),
    ], .83, 36, .044)
    brim = [(-.52,5.375,-.309),(-.51,5.331,-.445),(-.31,5.296,-.625),
            (0,5.29,-.677),(.281,5.313,-.602),(.439,5.350,-.465),(.479,5.400,-.311)]
    plate("ScoutVisor", "ScoutLeather", brim, .064)
    for side, name in ((-1,"Left"),(1,"Right")):
        skirt(name+"CoatTail", side)
        for key in (name+"CoatTail", name+"CoatTailStitch"):
            vertices, faces = PARTS[key]
            PARTS[key] = ([(x*.94, 3.08+(y-3.08)*.27, z*.98) for x,y,z in vertices], faces)
    loft("MapPocket", "ScoutLeather", [
        (2.68,-.630,-.23,.170,.104),(2.75,-.657,-.245,.184,.120),
        (2.984,-.668,-.251,.200,.132),(3.023,-.662,-.247,.170,.109),
    ], .53, 24, .034)
    loft("FieldMap", "MapPaper", [
        (2.801,-.73,-.272,.066,.054),(2.94,-.74,-.290,.066,.052),
        (3.139,-.76,-.307,.073,.056),(3.27,-.773,-.317,.074,.056),
    ], .78, 24,.026)
    loft("FieldMapThread", "MapWax", [
        (3.076,-.756,-.308,.081,.061),(3.10,-.759,-.308,.084,.067),
        (3.126,-.761,-.306,.083,.068),
    ], .86, 16)
    plate("ScoutPin", "DullIron", [(.369,4.057,-.483),(.416,4.100,-.467),
        (.464,4.052,-.465),(.416,4.002,-.485)], .043)


if __name__ == "__main__":
    base.DEST = DEST
    face()
    costume()
    def grain(_name, mesh, _material, surface):
        if surface in {"Wool", "ScoutFelt", "ScoutLeather", "ScoutCanvas"}:
            project(mesh, 1.8)
    export(stem="FrontierTracker", layout="layout.json", finish=grain, prefix="Geo_")
