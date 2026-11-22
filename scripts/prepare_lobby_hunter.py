"""Build Elias Reed's original showcase geometry around the CC0 MakeHuman HM08 head.

Run Blender headless with this script and pass the path to the MakeHuman base.obj after --.
Coordinates in this file are the authored Roblox rest pose in studs.
"""
from collections import defaultdict
from math import cos, pi, sin, tau
from pathlib import Path
import sys

import bpy
from mathutils import Vector

OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "lobby" / "HunterSet.glb"
PALETTE = {
    "Wool": (73, 66, 55), "Vest": (102, 90, 66), "Twill": (61, 61, 55),
    "Leather": (67, 44, 32), "Felt": (56, 49, 40), "Scarf": (99, 52, 47),
    "Skin": (161, 121, 97), "Steel": (61, 67, 69), "Walnut": (92, 55, 36),
    "Brass": (137, 109, 69), "Eyes": (57, 47, 41), "Linen": (156, 145, 124),
}
GEOMETRY = defaultdict(lambda: ([], []))


def add(name, material, vertices, faces):
    points, polygons = GEOMETRY[(name, material)]
    offset = len(points)
    points.extend(vertices)
    polygons.extend(tuple(offset + idx for idx in face) for face in faces)


def rings(name, material, levels, steps=28, folds=.02):
    """Sweep irregular elliptical cross-sections up the body."""
    vertices = []
    for row, (y, cx, cz, rx, rz) in enumerate(levels):
        for col in range(steps):
            angle = tau * col / steps
            ripple = 1 + folds * (sin(angle * 5 + row * .85) + .55 * cos(angle * 9 - row))
            vertices.append((cx + rx * sin(angle) * ripple, y, cz + rz * cos(angle) * ripple))
    faces = [tuple(reversed(range(steps)))]
    for row in range(len(levels) - 1):
        offset = row * steps
        for col in range(steps):
            nxt = (col + 1) % steps
            faces.append((offset + col, offset + nxt, offset + steps + nxt, offset + steps + col))
    faces.append(tuple((len(levels) - 1) * steps + i for i in range(steps)))
    add(name, material, vertices, faces)


def tube(name, material, a, b, radius_a, radius_b, steps=12):
    a, b = Vector(a), Vector(b)
    axis = (b - a).normalized()
    cross = axis.cross(Vector((0, 0, 1)))
    if cross.length < .001:
        cross = axis.cross(Vector((0, 1, 0)))
    side = cross.normalized()
    up = axis.cross(side)
    points = []
    for center, radius in ((a, radius_a), (b, radius_b)):
        for i in range(steps):
            angle = tau * i / steps
            points.append(center + radius * (side * cos(angle) + up * sin(angle)))
    faces = [tuple(reversed(range(steps))), tuple(range(steps, 2 * steps))]
    for i in range(steps):
        j = (i + 1) % steps
        faces.append((i, j, j + steps, i + steps))
    add(name, material, points, faces)


def plate(name, material, outline, thickness=.035):
    count = len(outline)
    points = list(outline) + [(x, y, z - thickness) for x, y, z in outline]
    surfaces = [tuple(range(count)), tuple(reversed(range(count, 2 * count)))]
    for i in range(count):
        j = (i + 1) % count
        surfaces.append((j, i, i + count, j + count))
    add(name, material, points, surfaces)


def head_geometry(base):
    vertices, faces = [], []
    body = False
    for line in base.read_text().splitlines():
        fields = line.split()
        if not fields:
            continue
        if fields[0] == "v":
            vertices.append(tuple(map(float, fields[1:4])))
        elif fields[0] == "g":
            body = fields[1] == "body"
        elif fields[0] == "f" and body:
            face = [int(part.split("/")[0]) - 1 for part in fields[1:]]
            if min(vertices[i][1] for i in face) >= 6.71:
                faces.append(face)
    ids = sorted({i for face in faces for i in face})
    remap = {old: i for i, old in enumerate(ids)}
    points = []
    for i in ids:
        x, y, z = vertices[i]
        points.append((x * .377, 3.85 + (y - 6.71) * .392, (z - .48) * .375 + .018))
    add("Face", "Skin", points, [tuple(remap[i] for i in face) for face in faces])
    for sign in (-1, 1):
        x = sign * .125
        rings("Eyes", "Eyes", [
            (4.162, x, .232, .041, .022), (4.176, x, .246, .064, .030),
            (4.190, x, .244, .056, .027), (4.198, x, .232, .020, .014),
        ], 14, 0)
        tube("Brow", "Felt", (x-sign*.057, 4.224, .261), (x+sign*.058, 4.238, .252), .014, .009)
    rings("Scarf", "Scarf", [
        (3.64, .01, .014, .239, .196), (3.71, .0, .01, .309, .233),
        (3.80, -.01, .02, .300, .292), (3.89, 0, .12, .251, .263),
        (3.94, .008, .148, .241, .215), (3.975, .018, .155, .229, .184),
    ], folds=.067)
    rings("HatCrown", "Felt", [
        (4.39, 0, .013, .326, .319), (4.465, -.018, -.002, .338, .303),
        (4.583, -.022, -.022, .316, .296), (4.669, -.018, -.055, .259, .245),
        (4.692, -.02, -.071, .19, .16),
    ], 48, .026)
    rings("HatBand", "Leather", [
        (4.403, 0, .006, .342, .332), (4.464, -.013, -.002, .343, .323),
    ], 44)
    vertices = []
    count = 60
    for thickness in (-.023, .014):
        for band in (0, 1):
            for i in range(count):
                a = tau * i / count
                edge = .077 * sin(a) ** 2 - .087 * max(0, cos(a)) + .048 * max(0, -cos(a))
                rx, rz = (.29, .30) if band == 0 else (.565, .590)
                vertices.append((sin(a) * rx, 4.407 + thickness + edge * band, cos(a) * rz + .03))
    faces = []
    for i in range(count):
        j = (i + 1) % count
        for a, b in ((0, count), (count, 3 * count), (3 * count, 2 * count), (2 * count, 0)):
            faces.append((a+i, a+j, b+j, b+i))
    add("HatBrim", "Felt", vertices, faces)


def wardrobe():
    for side, label in ((-1, "Left"), (1, "Right")):
        foot_x, foot_z = side * .31, -.095 * side
        rings(label + "Boot", "Leather", [
            (.018, foot_x, foot_z+.115, .194, .338), (.082, foot_x, foot_z+.116, .202, .363),
            (.169, foot_x, foot_z+.111, .190, .353), (.24, foot_x, foot_z+.064, .168, .256),
            (.36, foot_x, foot_z, .155, .159), (.56, foot_x, foot_z-.01, .173, .177),
            (.68, foot_x, foot_z-.01, .175, .183),
        ], folds=.037)
        rings(label + "Trousers", "Twill", [
            (.51, foot_x, foot_z, .17, .17), (.66, foot_x, foot_z, .188, .192),
            (.87, side*.304, foot_z, .181, .172), (1.03, side*.29, foot_z+.027, .203, .194),
            (1.19, side*.282, foot_z+.039, .194, .198), (1.52, side*.266, .04, .222, .221),
            (1.82, side*.23, .012, .259, .245), (2.27, side*.22, 0, .275, .251),
        ], folds=.060)
        # Two separately shaped skirt panels leave a slit down the front.
        vertices = []
        columns = 18
        for row, (y, rx, rz) in enumerate(((.98, .59, .366), (1.18, .577, .350),
                                          (1.63, .526, .327), (2.02, .487, .312),
                                          (2.27, .493, .292))):
            for col in range(columns):
                angle = .34 + (pi - .32) * col / (columns - 1)
                seam = .023 * sin(angle * 7 + row)
                vertices.append((side * sin(angle) * (rx + seam), y + .035*sin(angle * 3) * (row < 2),
                                 cos(angle) * rz - max(0, 2.0 - y) * .07))
        faces = []
        for row in range(4):
            for col in range(columns-1):
                a = row * columns + col
                face = (a, a+1, a+1+columns, a+columns)
                faces.append(face if side == 1 else tuple(reversed(face)))
        add(label + "CoatTail", "Wool", vertices, faces)

    rings("LongCoat", "Wool", [
        (1.99, 0, -.034, .488, .310), (2.20, 0, -.034, .476, .294),
        (2.55, .012, -.018, .443, .299), (2.89, .025, -.012, .493, .331),
        (3.20, .022, -.022, .552, .323), (3.43, .015, -.036, .621, .288),
        (3.58, .007, -.029, .531, .247), (3.675, .01, -.019, .266, .208),
    ], 44, .032)
    plate("Waistcoat", "Vest", [(-.31, 2.12, .317), (.32, 2.16, .315), (.29, 3.43, .295),
                               (.08, 3.23, .333), (-.09, 3.27, .332), (-.27, 3.45, .296)])
    plate("ShirtOpening", "Linen", [(-.21, 3.37, .3), (0, 3.11, .356),
                                     (.19, 3.43, .29), (.188, 3.632, .218),
                                     (-.155, 3.65, .21)])
    for side in (-1, 1):
        plate("CoatLapels", "Wool", [(side*.163, 3.66, .234), (side*.415, 3.39, .262),
            (side*.341, 3.29, .298), (side*.439, 3.24, .278), (side*.188, 2.77, .331),
            (side*.242, 3.29, .340)])
        plate("PocketFlaps", "Wool", [(side*.26, 2.20, .292), (side*.52, 2.29, .175),
                                      (side*.49, 2.17, .175), (side*.29, 2.11, .299)])
    for y in (2.35, 2.53, 2.71, 2.89, 3.07):
        tube("VestButtons", "Brass", (.035, y, .318), (.035, y, .356), .027, .026, 14)
    rings("Belt", "Leather", [(2.18, 0, -.025, .48, .321), (2.30, 0, -.018, .480, .316)])
    plate("Buckle", "Brass", [(-.102, 2.176, .347), (.106, 2.176, .348),
                               (.106, 2.302, .349), (-.102, 2.302, .351)], .019)
    plate("Bandolier", "Leather", [(-.49, 3.56, .211), (-.36, 3.61, .25),
        (-.17, 3.29, .363), (.15, 2.95, .380), (.42, 2.48, .282), (.47, 2.26, .193),
        (.36, 2.38, .234), (.001, 2.91, .374), (-.32, 3.27, .344)])
    for i in range(7):
        x, y = -.154 + i*.062, 3.255-i*.078
        tube("BeltStuds", "Brass", (x-.031, y-.033, .363), (x+.044, y+.031, .392), .018, .018)

    rings("LeftArm", "Wool", [
        (2.72, -.24, .605, .131, .126), (2.78, -.295, .57, .143, .139),
        (2.84, -.402, .504, .154, .165), (2.87, -.53, .4, .169, .164),
        (2.92, -.651, .262, .182, .177), (3.09, -.687, .12, .177, .175),
        (3.26, -.669, .018, .181, .2), (3.44, -.61, -.011, .187, .197),
        (3.55, -.55, -.026, .128, .152),
    ], folds=.054)
    rings("RightArm", "Wool", [
        (2.18, .419, .469, .127, .127), (2.27, .484, .408, .139, .151),
        (2.42, .590, .319, .16, .158), (2.62, .646, .177, .175, .159),
        (2.83, .695, .066, .182, .169), (3.06, .698, .031, .177, .179),
        (3.29, .67, .017, .189, .190), (3.46, .609, .003, .193, .193),
        (3.55, .552, -.013, .129, .146),
    ], folds=.063)
    for name, center in (("LeftGlove", (-.18, 2.755, .671)), ("RightGlove", (.377, 2.219, .549))):
        x, y, z = center
        rings(name, "Leather", [(y-.084, x, z, .083, .076), (y-.042, x, z, .126, .106),
              (y+.034, x, z, .136, .104), (y+.087, x, z, .091, .075)], 22, .032)
        for finger in range(4):
            fx = x-.072 + finger*.051
            tube(name, "Leather", (fx, y+.014, z+.055), (fx-.012, y+.048, z+.120), .026, .020, 9)
        tube(name, "Leather", (x+.090, y-.025, z+.037), (x+.104, y+.050, z+.109), .044, .030)


def prop_silhouette():
    # Original sealed stage prop. Its exterior profile follows the two hand contacts.
    plate("Stock", "Walnut", [(.93, 1.948, .632), (.855, 2.115, .652),
          (.595, 2.13, .656), (.390, 2.296, .701), (.322, 2.235, .701),
          (.477, 2.044, .659), (.715, 1.992, .632), (.837, 1.893, .609)], .125)
    tube("DarkSpine", "Steel", (.45, 2.201, .630), (-.756, 3.300, .749), .079, .041)
    tube("Forewood", "Walnut", (.258, 2.338, .639), (-.318, 2.856, .693), .092, .064, 16)
    tube("Binding", "Brass", (-.308, 2.868, .707), (-.364, 2.920, .721), .075, .065)
    tube("HeelCap", "Steel", (.937, 1.953, .571), (.867, 2.116, .588), .046, .036)


def export():
    for obj in list(bpy.context.scene.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    materials = {}
    for key, color in PALETTE.items():
        material = bpy.data.materials.new(key)
        material.diffuse_color = tuple((c / 255) ** 2.2 for c in color) + (1,)
        material.use_nodes = True
        shader = next(node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
        shader.inputs["Base Color"].default_value = material.diffuse_color
        shader.inputs["Roughness"].default_value = .88 if key in ("Wool", "Twill", "Felt", "Linen") else .64
        materials[key] = material
    for (name, key), (vertices, faces) in GEOMETRY.items():
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata([(x, -z, y) for x, y, z in vertices], [], faces)
        mesh.validate()
        mesh.update()
        import bmesh
        editing = bmesh.new()
        editing.from_mesh(mesh)
        bmesh.ops.recalc_face_normals(editing, faces=list(editing.faces))
        editing.to_mesh(mesh)
        editing.free()
        mesh.materials.append(materials[key])
        for face in mesh.polygons:
            face.use_smooth = len(face.vertices) == 4 and len(mesh.polygons) > 15
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        mesh.calc_loop_triangles()
        print(name, len(mesh.loop_triangles), "triangles")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUTPUT), export_format="GLB", export_yup=True)


if __name__ == "__main__":
    head_geometry(Path(sys.argv[sys.argv.index("--") + 1]))
    wardrobe()
    prop_silhouette()
    export()
