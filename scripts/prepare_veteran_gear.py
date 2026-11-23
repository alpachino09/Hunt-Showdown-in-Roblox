"""Build fitted, low-cost gear for the Veteran from the lobby's frontier vocabulary."""
from math import cos, sin, tau
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from prepare_veteran import PALETTE, add, export, loft, plate
from prepare_veteran_outfit import stitch_path

PALETTE.update({
    "HatFelt": (50, 42, 37),
    "Hair": (62, 51, 43),
    "WornBrass": (143, 107, 64),
    "DarkLeather": (83, 48, 33),
    "LeatherEdge": (111, 69, 45),
    "DullIron": (76, 79, 76),
})


def hat():
    # Asymmetric basin and rolled brim, adapted from the stage-one costume.
    sides = 48
    loft("HatCrown", "HatFelt", [
        (5.328,0,.062,.598,.438), (5.431,-.020,.073,.611,.458),
        (5.585,-.039,.079,.575,.411), (5.710,-.058,.096,.536,.372),
        (5.766,-.066,.133,.369,.278),
    ], .82, sides, .026)
    loft("HatBand", "DarkLeather", [
        (5.376,-.014,.066,.621,.472), (5.425,-.023,.071,.623,.469),
        (5.484,-.029,.075,.605,.450), (5.508,-.031,.080,.595,.438),
    ], .84, sides, .016)
    points = []
    for layer in (0, 1):
        for rim in (0, 1):
            for i in range(sides):
                a = tau*i/sides
                roll = (sin(a)**2 * .19 - max(0,cos(a)) * .134 + max(0,-cos(a)) * .038)
                x, z = ((.548,.416) if rim==0 else (1.026,.802))
                points.append((x*sin(a),5.337+.049*layer+rim*roll-.032*sin(a),-z*cos(a)+.056))
    faces = []
    for i in range(sides):
        j = (i+1) % sides
        for a,b in ((0,sides),(sides,3*sides),(3*sides,2*sides),(2*sides,0)):
            faces.append((a+i,a+j,b+j,b+i))
    add("HatBrim","HatFelt",points,faces)
    plate("HatClasp", "WornBrass", [(.412,5.449,-.304),(.525,5.454,-.260),(.537,5.411,-.257),
        (.419,5.403,-.314)], .034)
    for side in (-1,1):
        x=side*.57
        loft("TempleHair","Hair", [(5.015,x,.170,.035,.142),(5.087,x,.157,.076,.244),
             (5.230,x-side*.026,.154,.077,.289),(5.348,x-side*.053,.144,.095,.279)], .85,18,.036)


def gear():
    loft("WaistBelt", "DarkLeather", [
        (2.915,0,.030,.728,.422),(2.939,0,.027,.751,.433),
        (3.075,0,.021,.726,.422),(3.109,0,.018,.706,.414),
    ], .57, 32, .018)
    plate("WaistBuckle", "WornBrass", [(-.177,2.938,-.428),(.191,2.938,-.427),
        (.208,2.988,-.469),(.181,3.098,-.461),(-.168,3.099,-.461),(-.193,3.043,-.472)], .041)
    plate("WaistBuckleCenter","DarkLeather",[(-.122,2.973,-.473),(.133,2.976,-.474),
        (.128,3.060,-.476),(-.123,3.061,-.476)], .028)
    strap = [
        (-.475,4.170,-.38),(-.362,4.087,-.487),(-.249,3.989,-.542),
        (-.111,3.873,-.585),(.055,3.746,-.594),(.189,3.596,-.574),
        (.299,3.416,-.532),(.418,3.256,-.496),(.523,3.112,-.469),
    ]
    for i, (a,b) in enumerate(zip(strap, strap[1:])):
        x,y,z=a
        bx,by,bz=b
        plate("CrossBodyStrap","DarkLeather",[(x-.078,y-.046,z),(bx-.079,by-.046,bz),
              (bx+.079,by+.046,bz-.004),(x+.078,y+.046,z-.004)],.049)
        if 1 <= i <= 6:
            middle=((x+bx)/2,(y+by)/2,(z+bz)/2)
            mx,my,mz=middle
            plate("StrapKeepers","LeatherEdge",[(mx-.076,my-.036,mz-.009),
                (mx+.075,my+.054,mz-.020),(mx+.060,my+.078,mz-.018),
                (mx-.089,my-.011,mz-.011)],.031)
    stitch_path("StrapStitches",[(x+.057,y+.019,z-.019) for x,y,z in strap[1:-1]], width=.006)

    loft("DispatchPouch", "DarkLeather", [(2.314,-.786,.302,.204,.143),
         (2.368,-.788,.307,.243,.171),(2.54,-.798,.315,.246,.179),
         (2.796,-.788,.312,.239,.176),(2.879,-.774,.304,.198,.148)],.52,26,.035)
    plate("PouchFlap","LeatherEdge",[(-1.013,2.831,.119),(-.563,2.833,.124),
        (-.57,2.66,.127),(-.733,2.594,.131),(-.867,2.592,.131),(-1.001,2.682,.130)],.047)
    loft("PouchClasp","WornBrass",[(2.613,-.807,.099,.044,.014),(2.652,-.807,.090,.054,.019),
        (2.688,-.807,.095,.046,.017)],.8,16)
    loft("HipHolster","DarkLeather",[(2.04,.839,-.273,.112,.085),(2.11,.871,-.248,.147,.114),
        (2.36,.893,-.208,.165,.162),(2.56,.874,-.182,.189,.165),
        (2.711,.817,-.157,.182,.153),(2.77,.807,-.154,.159,.133)],.57,22,.031)
    plate("HolsterEdge","LeatherEdge",[(.656,2.683,-.303),(.990,2.713,-.297),
        (.989,2.633,-.328),(.68,2.615,-.326)],.025)
    loft("HolsterStud","DullIron",[(2.633,.821,-.336,.027,.013),(2.656,.821,-.344,.036,.016),
         (2.675,.822,-.338,.026,.014)],.82,16)


if __name__ == "__main__":
    hat()
    gear()
    export(stem="VeteranGear", layout="gear-layout.json")
