"""Prepare the CC0 pieces of the forest set using Blender 5.2.

Usage: blender -b --factory-startup --python-exit-code 1 -P scripts/prepare_lobby_assets.py -- SOURCE_DIR
SOURCE_DIR contains each original glTF under <Poly Haven slug>/source.gltf.
"""
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector


SOURCES = Path(sys.argv[sys.argv.index("--") + 1])
DESTINATION = Path(__file__).resolve().parents[1] / "assets" / "lobby"
ASSETS = {
    "dead_tree_trunk": (("FallenTrunk", "", 3200),),
    "tree_stump_01": (("SplitStump", "", 2200),),
    "rock_moss_set_01": (("MossRockA", "rock01", 1000), ("MossRockB", "rock04", 1000)),
    "dry_branches_medium_01": (("DryBrush", "_a", 1500),),
    "wooden_crate_01": (("FreightCrate", "", 2600),),
    "dead_quiver_branch_01": (("SnagBranches", "", 1400),),
}


def reset():
    for obj in list(bpy.context.scene.objects):
        bpy.data.objects.remove(obj, do_unlink=True)


def import_parts(slug):
    before = set(bpy.context.scene.objects)
    result = bpy.ops.import_scene.gltf(filepath=str(SOURCES / slug / "source.gltf"))
    assert result == {"FINISHED"}, (slug, result)
    return [obj for obj in set(bpy.context.scene.objects) - before if obj.type == "MESH"]


def prepare_objects(parts, name, limit):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts:
        world = obj.matrix_world.copy()
        obj.parent = None
        obj.matrix_world = world
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(parts) > 1:
        bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    if len(obj.data.materials) > 1:
        bpy.ops.mesh.separate(type="MATERIAL")
    pieces = sorted(bpy.context.selected_objects, key=lambda obj: obj.name)
    vertices = [vertex.co for piece in pieces for vertex in piece.data.vertices]
    center = Vector([(min(v[i] for v in vertices) + max(v[i] for v in vertices)) * .5 for i in range(3)])
    for index, piece in enumerate(pieces):
        piece.name = name if len(pieces) == 1 else f"{name}{index + 1}"
        for vertex in piece.data.vertices:
            vertex.co -= center
        bpy.context.view_layer.objects.active = piece
        piece.data.calc_loop_triangles()
        before = len(piece.data.loop_triangles)
        budget = max(400, limit // len(pieces))
        if before > budget:
            modifier = piece.modifiers.new("Silhouette budget", "DECIMATE")
            modifier.ratio = budget / before
            bpy.ops.object.modifier_apply(modifier=modifier.name)
        piece.data.calc_loop_triangles()
        assert piece.data.uv_layers and 0 < len(piece.data.loop_triangles) <= 20000
        assert all(math.isfinite(c) for v in piece.data.vertices for c in v.co)
        print(f"{piece.name}: {before} -> {len(piece.data.loop_triangles)} triangles")
    return pieces


def make_ground(material):
    steps, width, depth = 63, 118, 142
    vertices, faces = [], []
    for row in range(steps + 1):
        for col in range(steps + 1):
            x, y = (col / steps - .5) * width, (row / steps - .5) * depth
            trail = math.exp(-((x - 2 - 4 * math.sin(y * .07)) / 7) ** 2)
            rough = math.sin(x * .2 + y * .13) * .64 + math.cos(y * .29 - x * .18) * .32
            bank = (1 - trail) * (.90 + rough)
            height = (bank - .20 + .07 * math.sin(x * .8 + y * .95)) * min(1, (abs(y) + abs(x)) / 13)
            vertices.append((x, y, height))
            if row and col:
                i = len(vertices) - 1
                faces.append((i - steps - 2, i - steps - 1, i, i - 1))
    mesh = bpy.data.meshes.new("Trail")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    uv = mesh.uv_layers.new()
    for loop in mesh.loops:
        x, y, _ = vertices[loop.vertex_index]
        uv.data[loop.index].uv = (x / 9 + .06 * math.sin(y), y / 9 + .07 * math.cos(x))
    for face in mesh.polygons:
        face.use_smooth = True
    obj = bpy.data.objects.new("MuddyTrail", mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def main():
    reset()
    base = []
    for slug, specs in ASSETS.items():
        original = import_parts(slug)
        kept = []
        for name, pattern, limit in specs:
            matching = sorted((obj for obj in original if pattern in obj.name), key=lambda obj: obj.name)
            assert matching, (slug, pattern)
            copies = []
            for source in matching:
                obj = source.copy()
                obj.data = source.data.copy()
                bpy.context.collection.objects.link(obj)
                copies.append(obj)
            kept.extend(prepare_objects(copies, name, limit))
        base.extend(kept)
        for obj in original:
            bpy.data.objects.remove(obj, do_unlink=True)
    source = import_parts("brown_mud_leaves_01")[0]
    base.append(make_ground(source.data.materials[0]))
    bpy.data.objects.remove(source, do_unlink=True)
    bpy.ops.object.select_all(action="DESELECT")
    for index, obj in enumerate(base):
        # Use a deliberate gallery layout for the importer. The Rojo scene owns final placement.
        obj.location = (index * 8, 0, 0)
        obj.select_set(True)
    DESTINATION.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(DESTINATION / "ForestSet.glb"),
        export_format="GLB", use_selection=True, export_yup=True,
    )


if __name__ == "__main__":
    main()
