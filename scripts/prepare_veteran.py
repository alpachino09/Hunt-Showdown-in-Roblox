"""Author Elias Reed's segmented stylized body in Blender.

blender -b --factory-startup --python-exit-code 1 -P scripts/prepare_veteran.py
Uses studio coordinates in studs with forward along -Z.
"""
from collections import defaultdict
import json
from math import copysign, cos, isfinite, sin, tau
from pathlib import Path

import bmesh
import bpy

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets" / "characters" / "Veteran"
PARTS = defaultdict(lambda: ([], []))
MATERIAL = {}
PALETTE = {
    "Wool": (89, 68, 52),
    "Vest": (121, 87, 55),
    "Canvas": (157, 142, 114),
    "Twill": (66, 64, 58),
    "GloveLeather": (68, 50, 39),
    "BootLeather": (71, 51, 39),
    "Rubber": (43, 36, 30),
    "Skin": (173, 121, 84),
    "Beard": (69, 53, 43),
    "Brow": (57, 42, 33),
    "EyeWhite": (203, 188, 159),
    "EyeDark": (44, 57, 53),
    "EyeShade": (127, 84, 60),
    "Lips": (98, 59, 50),
}


def add(name, surface, vertices, faces):
    points, polygons = PARTS[name]
    offset = len(points)
    points.extend(vertices)
    polygons.extend(tuple(offset + index for index in face) for face in faces)
    current = MATERIAL.setdefault(name, surface)
    assert current == surface, (name, current, surface)


def loft(name, surface, sections, exponent=.61, sides=24, fold=0):
    """Rounded rectangular sections with an optional restrained cloth fold."""
    points = []
    for row, (y, x, z, rx, rz) in enumerate(sections):
        for i in range(sides):
            angle = tau * i / sides
            dx = copysign(abs(cos(angle)) ** exponent, cos(angle))
            dz = copysign(abs(sin(angle)) ** exponent, sin(angle))
            ripple = 1 + fold * (sin(5 * angle + row * .91) + .31 * cos(9 * angle - row))
            points.append((x + dx * rx * ripple, y, z + dz * rz * ripple))
    faces = [tuple(range(sides))]
    for row in range(len(sections) - 1):
        for i in range(sides):
            j = (i + 1) % sides
            start, end = row * sides, (row + 1) * sides
            faces.append((start + i, end + i, end + j, start + j))
    faces.append(tuple(reversed(range(len(points) - sides, len(points)))))
    add(name, surface, points, faces)


def plate(name, surface, front, thickness):
    """Extrude a close-fitting planar or slightly curved costume panel toward the body."""
    n = len(front)
    points = front + [(x, y, z + thickness) for x, y, z in front]
    faces = [tuple(range(n)), tuple(reversed(range(n, 2*n)))]
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, j + n, i + n))
    add(name, surface, points, faces)


def head():
    loft("Head", "Skin", [
        (4.29, 0, .00, .29, .26),
        (4.40, 0, .01, .33, .28),
        (4.48, 0, -.025, .46, .35),
        (4.61, 0, -.012, .55, .406),
        (4.80, 0, .003, .610, .435),
        (4.96, 0, .024, .620, .422),
        (5.13, 0, .035, .605, .425),
        (5.31, 0, .05, .566, .401),
        (5.47, 0, .05, .48, .351),
        (5.54, 0, .061, .34, .241),
    ])
    for side in (-1, 1):
        x = side * .614
        loft("Ears", "Skin", [(4.73, x, .034, .036, .083), (4.80, x+side*.020, .032, .076, .12),
             (4.95, x+side*.016, .060, .076, .113), (5.00, x, .060, .049, .074)], .82, 16)
        cx = side * .231
        plate("EyeSockets", "EyeShade", [(cx-.137, 4.964, -.390), (cx+.130, 4.956, -.390),
              (cx+.125, 4.883, -.408), (cx+.074, 4.862, -.421), (cx-.089, 4.858, -.415),
              (cx-.128, 4.883, -.410)], .072)
        loft("Eyes", "EyeWhite", [(4.890, cx, -.421, .077, .029),
              (4.918, cx, -.434, .113, .032), (4.938, cx, -.428, .072, .027)], .74, 16)
        loft("Irises", "EyeDark", [(4.890, cx-.013, -.462, .009, .006),
              (4.916, cx-.013, -.465, .030, .012), (4.937, cx-.013, -.461, .013, .006)], .86, 14)
        plate("Brow", "Brow", [(cx-.147, 4.993, -.401), (cx+.130, 5.026, -.390),
              (cx+.142, 4.993, -.397), (cx-.088, 4.961, -.415), (cx-.142, 4.963, -.409)], .044)
    loft("Nose", "Skin", [(4.701, 0, -.413, .104, .066), (4.76, 0, -.459, .106, .092),
         (4.82, 0, -.432, .075, .079), (4.94, 0, -.406, .058, .046),
         (5.005, 0, -.395, .043, .026)], .84, 14)
    plate("Beard", "Beard", [(-.445,4.730,-.325),(-.305,4.627,-.422),(-.178,4.632,-.454),
        (-.131,4.695,-.467),(.135,4.692,-.464),(.193,4.631,-.45),(.35,4.633,-.388),
        (.458,4.746,-.285),(.434,4.532,-.31),(.268,4.440,-.389),(-.262,4.440,-.395),
        (-.424,4.536,-.337)], .113)
    plate("Mouth", "Lips", [(-.145,4.639,-.474),(.112,4.651,-.471),(.159,4.636,-.460),
         (.105,4.623,-.466),(-.137,4.616,-.466)], .023)


def body():
    loft("UpperTorso", "Wool", [(3.015, .0, .043, .61, .316), (3.10, 0, .031, .656, .371),
          (3.33, 0, .026, .667, .372), (3.58, 0, .026, .766, .411), (3.92, 0, .016, .852, .438),
          (4.09, 0, .020, .857, .387), (4.21, 0, .014, .754, .342), (4.29, 0, .02, .463, .3),
          (4.38, 0, .026, .28, .263)], .54, 32, .027)
    loft("LowerTorso", "Twill", [(2.48, 0, .018, .654, .324), (2.61, 0, .02, .766, .358),
          (2.83, 0, .041, .750, .375), (3.11, 0, .038, .677, .359),
          (3.18, 0, .031, .620, .321)], .61, 28, .027)
    for letter, sign in (("Left", -1), ("Right", 1)):
        def sx(value):
            return value * sign

        loft(letter+"UpperArm", "Wool", [(3.35,sx(1.196),.043,.274,.253),
             (3.49,sx(1.165),.049,.273,.253), (3.81,sx(1.061),.032,.268,.264),
             (4.02,sx(.974),.009,.271,.276), (4.15,sx(.946),.015,.242,.237),
             (4.19,sx(.937),.013,.174,.190)], .61, 24, .053)
        loft(letter+"LowerArm", "Wool", [(2.839,sx(1.281),.003,.207,.194),
             (2.938,sx(1.268),.009,.194,.203), (3.099,sx(1.226),.026,.214,.211),
             (3.272,sx(1.19),.031,.236,.222), (3.45,sx(1.167),.045,.213,.205),
             (3.51,sx(1.16),.049,.197,.188)], .63, 24, .052)
        loft(letter+"Hand", "GloveLeather", [(2.49,sx(1.307),-.025,.111,.123),
             (2.55,sx(1.31),-.016,.166,.161), (2.68,sx(1.305),-.028,.199,.164),
             (2.8,sx(1.284),-.018,.178,.171), (2.94,sx(1.28),-.005,.170,.150)], .63, 22, .025)
        loft(letter+"Thumb", "GloveLeather", [(2.64,sx(1.14),-.127,.058,.064),
             (2.73,sx(1.126),-.108,.087,.084), (2.82,sx(1.168),-.076,.094,.094),
             (2.86,sx(1.213),-.047,.077,.071)], .89, 16)
        loft(letter+"UpperLeg", "Twill", [(1.48,sx(.502),-.051,.323,.306),
             (1.62,sx(.505),-.021,.324,.312), (1.83,sx(.49),.003,.313,.304),
             (2.06,sx(.469),.014,.345,.339), (2.33,sx(.457),.008,.360,.366),
             (2.60,sx(.447),.013,.361,.35), (2.77,sx(.447),.014,.271,.282)], .59, 28, .037)
        loft(letter+"LowerLeg", "Twill", [(.39,sx(.533),.027,.228,.233),
             (.61,sx(.53),.037,.258,.259), (.88,sx(.533),.037,.281,.286),
             (1.13,sx(.519),.035,.273,.278), (1.41,sx(.514),-.013,.285,.285),
             (1.60,sx(.509),-.042,.260,.241), (1.67,sx(.507),-.041,.237,.223)], .62, 24, .047)
        loft(letter+"Foot", "BootLeather", [(.035,sx(.535),-.135,.277,.432),
             (.13,sx(.532),-.138,.284,.439), (.25,sx(.532),-.103,.277,.388),
             (.352,sx(.531),-.042,.251,.305), (.47,sx(.532),.009,.236,.255),
             (.58,sx(.534),.022,.198,.204)], .53, 28, .026)
        loft(letter+"Sole", "Rubber", [(.006,sx(.535),-.132,.255,.411),
             (.039,sx(.535),-.141,.288,.443), (.102,sx(.535),-.137,.292,.446)],
             .51, 28)
        loft(letter+"BootUpper", "BootLeather", [(.38,sx(.535),.014,.239,.253),
             (.63,sx(.534),.025,.292,.298), (.87,sx(.535),.034,.320,.314),
             (1.00,sx(.527),.031,.321,.316)], .63, 24, .025)


def export():
    for obj in list(bpy.context.scene.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    materials = {}
    for key, rgb in PALETTE.items():
        material = bpy.data.materials.new(key)
        material.diffuse_color = tuple((c / 255) ** 2.2 for c in rgb) + (1,)
        material.use_nodes = True
        shader = next(n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        shader.inputs["Base Color"].default_value = material.diffuse_color
        shader.inputs["Roughness"].default_value = .71 if "Twill" == key else .83
        materials[key] = material

    manifest = {}
    triangle_count = 0
    for name, (vertices, faces) in PARTS.items():
        assert all(isfinite(c) for v in vertices for c in v)
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata([(x, -z, y) for x, y, z in vertices], [], faces)
        assert not mesh.validate(verbose=True), name
        mesh.update()
        surface = bmesh.new()
        surface.from_mesh(mesh)
        assert all(edge.is_manifold for edge in surface.edges), name
        bmesh.ops.recalc_face_normals(surface, faces=list(surface.faces))
        surface.to_mesh(mesh)
        surface.free()
        mesh.materials.append(materials[MATERIAL[name]])
        for polygon in mesh.polygons:
            polygon.use_smooth = len(polygon.vertices) == 4 and len(faces) >= 20
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        mesh.calc_loop_triangles()
        low = [min(v[i] for v in vertices) for i in range(3)]
        high = [max(v[i] for v in vertices) for i in range(3)]
        triangles = len(mesh.loop_triangles)
        assert 0 < triangles <= 2000, (name, triangles)
        triangle_count += triangles
        manifest[name] = {
            "position": [round((a+b)/2, 5) for a,b in zip(low, high)],
            "size": [round(b-a, 5) for a,b in zip(low, high)],
            "surface": MATERIAL[name], "color": PALETTE[MATERIAL[name]],
            "triangles": triangles,
        }
    print(f"{len(manifest)} meshes, {triangle_count} triangles")
    DEST.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(DEST/"VeteranBody.glb"),export_format="GLB",export_yup=True)
    (DEST/"body-layout.json").write_text(json.dumps(manifest,indent=2)+"\n")


if __name__ == "__main__":
    head()
    body()
    export()
