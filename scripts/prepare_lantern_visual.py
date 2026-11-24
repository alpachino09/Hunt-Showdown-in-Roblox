"""Build the original Lantern visual model and its weapon-lab reference layout."""

from array import array
from math import copysign, cos, sin, tau
from pathlib import Path
import json

import bmesh
import bpy

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "weapons" / "Lantern"
MARKERS = {
    "Body": {"RightGrip": (.03, -.13, .42), "Brace": (-.11, -.07, .06), "Sight": (0, .176, .15)},
    "Barrel": {"LeftGrip": (-.106, -.103, -.42), "Chamber": (0, .056, -.032),
               "Muzzle": (0, .059, -1.58), "Hinge": (0, -.023, -.009)},
    "Extractor": {},
    "LiveRound": {},
    "SpentCase": {},
}


def xyz(x, y, z):
    """Maintain the same X/Y/Z as WeaponLab when glTF is exported Y-up."""
    return (x, -z, y)


def material(name, color, roughness, metalness=0):
    result = bpy.data.materials.new("M_" + name)
    shader = next(node for node in result.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    linear = tuple((channel / 255) ** 2.2 for channel in color)
    shader.inputs["Base Color"].default_value = (*linear, 1.0)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metalness
    result.diffuse_color = (*linear, 1.0)
    return result


def grain(material):
    width, height = 256, 128
    texture = bpy.data.images.new("T_LanternWalnut", width, height)
    data = array("f")
    for row in range(height):
        v = row / (height - 1)
        for column in range(width):
            u = column / (width - 1)
            grain = .52 + .24 * cos(tau * (19 * u + .10 * sin(6 * v)))
            grain += .16 * cos(tau * (7 * u + .28 * sin(4 * v)))
            grain += .04 * cos(tau * (53 * u + 1.7 * v))
            data.extend((.20 + .20 * grain, .088 + .102 * grain, .033 + .069 * grain, 1))
    texture.pixels.foreach_set(data)
    texture.pack()
    image_node = material.node_tree.nodes.new("ShaderNodeTexImage")
    image_node.image = texture
    shader = next(node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    material.node_tree.links.new(image_node.outputs["Color"], shader.inputs["Base Color"])


def loft(name, parent, surface, rings, *, x=0, sides=24, power=1.0, edge=None):
    vertices = []
    for z, y, rx, ry in rings:
        for index in range(sides):
            angle = tau * index / sides
            a, b = cos(angle), sin(angle)
            vertices.append(xyz(x + rx * copysign(abs(a) ** power, a),
                                y + ry * copysign(abs(b) ** power, b), z))
    first, last = 0, (len(rings) - 1) * sides
    vertices += [xyz(x, rings[0][1], rings[0][0]), xyz(x, rings[-1][1], rings[-1][0])]
    first_cap, last_cap = len(vertices) - 2, len(vertices) - 1
    faces, coordinates, details = [], [], []
    for ring in range(len(rings) - 1):
        for index in range(sides):
            nxt = (index + 1) % sides
            faces.append((ring * sides + index, ring * sides + nxt,
                          (ring + 1) * sides + nxt, (ring + 1) * sides + index))
            u, u2 = index / sides, (index + 1) / sides
            v = .65 * ring / (len(rings) - 1)
            v2 = .65 * (ring + 1) / (len(rings) - 1)
            coordinates.append(((u, v), (u2, v), (u2, v2), (u, v2)))
            details.append(int(edge is not None and ring in (0, len(rings) - 2)))
    for index in range(sides):
        nxt = (index + 1) % sides
        for base, cap, u in ((first, first_cap, .25), (last, last_cap, .75)):
            faces.append((base + index, base + nxt, cap))
            coordinates.append((
                (u + .145 * cos(tau * index / sides), .82 + .145 * sin(tau * index / sides)),
                (u + .145 * cos(tau * nxt / sides), .82 + .145 * sin(tau * nxt / sides)),
                (u, .82),
            ))
            details.append(int(edge is not None))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(surface)
    if edge is not None:
        mesh.materials.append(edge)
    uv = mesh.uv_layers.new(name="UVMap")
    for polygon, loops, band in zip(mesh.polygons, coordinates, details):
        polygon.use_smooth = polygon.loop_total == 4
        polygon.material_index = band
        for loop_index, position in zip(polygon.loop_indices, loops):
            uv.uv[loop_index].vector = position
    editable = bmesh.new()
    editable.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(editable, faces=list(editable.faces))
    editable.to_mesh(mesh)
    editable.free()
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    parent.users_collection[0].objects.link(obj)
    obj.parent = parent
    return obj


def sleeve(name, group, surface, near, far, y, radius, **kwargs):
    return loft(name, group, surface, [
        (near, y, radius * .89, radius * .89), (near + .008, y, radius, radius),
        (far - .008, y, radius, radius), (far, y, radius * .89, radius * .89),
    ], **kwargs)


def plate(name, group, surface, x, y, z, width, height, length):
    bevel = min(.014, length * .23)
    return loft(name, group, surface, [
        (z, y, width * .36, height * .34),
        (z + bevel, y, width * .5, height * .5),
        (z + length - bevel, y, width * .5, height * .5),
        (z + length, y, width * .36, height * .34),
    ], x=x, sides=16, power=.42)


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    assemble = bpy.data.collections.new("Lantern_Visual")
    scene.collection.children.link(assemble)
    groups = {}
    for name, points in MARKERS.items():
        group = bpy.data.objects.new(name, None)
        group.empty_display_size = .08
        assemble.objects.link(group)
        groups[name] = group
        for marker, position in points.items():
            guide = bpy.data.objects.new(marker + "_Att", None)
            guide.empty_display_size = .045
            assemble.objects.link(guide)
            guide.parent = group
            guide.location = xyz(*position)
    iron = material("OxidizedIron", (48, 55, 57), .43, .74)
    edge = material("BrushedEdges", (97, 106, 103), .32, .80)
    dull = material("DarkSteel", (31, 34, 36), .50, .65)
    brass = material("WornBrass", (149, 113, 59), .36, .68)
    amber = material("InventoryEnamel", (177, 99, 29), .29, .20)
    walnut = material("OiledWalnut", (87, 46, 26), .48)
    grain(walnut)
    cloth = material("RedPaper", (121, 35, 31), .70)
    char = material("SpentPaper", (58, 34, 26), .75)

    body = groups["Body"]
    loft("Receiver", body, iron, [
        (.005, .018, .101, .094), (.032, .017, .128, .121),
        (.16, .020, .126, .128), (.324, .015, .120, .114),
        (.47, -.005, .103, .095), (.498, -.017, .082, .079),
    ], sides=32, power=.38, edge=edge)
    loft("Stock", body, walnut, [
        (.318, -.055, .073, .073), (.369, -.076, .090, .090),
        (.485, -.115, .091, .091), (.603, -.136, .097, .097),
        (.725, -.155, .103, .111), (.852, -.153, .119, .133),
        (.916, -.148, .117, .137),
    ], sides=32, power=.60)
    loft("ButtPad", body, dull, [
        (.89, -.148, .116, .136), (.916, -.147, .122, .145), (.936, -.147, .121, .143), (.95, -.147, .107, .131),
    ], power=.62, edge=edge)
    plate("RearSight", body, edge, 0, .147, .124, .081, .039, .075)
    plate("TriggerGuard", body, dull, 0, -.231, .161, .09, .030, .24)
    plate("GuardFront", body, dull, 0, -.163, .158, .091, .145, .060)
    plate("GuardRear", body, dull, 0, -.166, .347, .091, .148, .064)
    plate("HingeCover", body, brass, 0, -.052, -.041, .258, .092, .127)
    for side in (-1, 1):
        sign = "R" if side > 0 else "L"
        plate("SidePlate_" + sign, body, edge, side * .118, .024, .078, .025, .126, .28)
        plate("BadgeFrame_" + sign, body, brass, side * .136, .032, .129, .024, .070, .174)
        plate("BadgeInlay_" + sign, body, amber, side * .151, .032, .150, .014, .041, .131)
        for slot, offset in enumerate((.169, .193, .217, .241), start=1):
            plate(f"BadgeMark_{sign}_{slot}", body, brass, side * .160, .030, offset, .003, .018, .020)

    barrel = groups["Barrel"]
    loft("BarrelProfile", barrel, iron, [
        (-1.583, .059, .063, .064), (-1.569, .059, .074, .074), (-1.49, .060, .070, .070),
        (-.71, .058, .073, .073), (-.34, .058, .077, .077), (-.228, .056, .090, .092),
        (-.12, .056, .104, .107), (-.041, .056, .101, .105), (-.023, .056, .090, .092),
    ], sides=36, edge=edge)
    sleeve("MuzzleAccent", barrel, dull, -1.592, -1.570, .059, .057, sides=30)
    plate("FrontSight", barrel, brass, 0, .130, -1.49, .027, .037, .063)
    loft("Forend", barrel, walnut, [
        (-.97, -.060, .070, .048), (-.92, -.075, .109, .070),
        (-.72, -.080, .116, .079), (-.53, -.078, .114, .076),
        (-.38, -.067, .098, .065), (-.312, -.058, .073, .049),
    ], sides=30, power=.52)
    for side in (-1, 1):
        plate("ForendRail_" + str(side), barrel, brass, side * .101, -.064, -.888, .018, .023, .38)
    plate("EjectorTab", groups["Extractor"], brass, 0, -.06, -.017, .13, .031, .049)
    for label, surface, x in (("LiveRound", cloth, .40), ("SpentCase", char, .60)):
        group = groups[label]
        group.location = xyz(x, -.18, .13)
        sleeve(label + "Paper", group, surface, -.114, .016, 0, .037, sides=20)
        sleeve(label + "Rim", group, brass, -.021, .028, 0, .044, sides=20, edge=edge)

    scene.unit_settings.system = "NONE"
    OUTPUT.mkdir(parents=True, exist_ok=True)
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "AgX"
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT / "LanternVisual.blend"))
    bpy.ops.export_scene.gltf(filepath=str(OUTPUT / "LanternVisual.glb"), export_format="GLB",
                              export_tangents=True, export_extras=True, export_animations=False)
    (OUTPUT / "rig-layout.json").write_text(json.dumps(MARKERS, indent=2) + "\n")
    for obj in assemble.objects:
        if obj.type == "MESH":
            obj.data.calc_loop_triangles()
            print(f"{obj.name}: {len(obj.data.loop_triangles)} triangles")


if __name__ == "__main__":
    build()
