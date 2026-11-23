"""Author weighted trouser legs and elbow inserts for the R15 silhouette."""
import json
from pathlib import Path
import sys

import bmesh
import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from prepare_veteran import DEST, MATERIAL, PALETTE, PARTS, loft


def cuff(name, surface, sections, placement):
    loft(name, surface, sections, .69, 32, .025)
    vertices, faces = PARTS[name]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([(x, -z, y) for x,y,z in vertices], [], faces)
    mesh.update()
    surface_mesh = bmesh.new()
    surface_mesh.from_mesh(mesh)
    assert all(edge.is_manifold for edge in surface_mesh.edges)
    bmesh.ops.recalc_face_normals(surface_mesh, faces=list(surface_mesh.faces))
    surface_mesh.to_mesh(mesh)
    surface_mesh.free()
    for polygon in mesh.polygons:
        polygon.use_smooth = True

    mat = bpy.data.materials.new(surface)
    mat.diffuse_color = tuple((c/255)**2.2 for c in PALETTE[MATERIAL[name]]) + (1,)
    mesh.materials.append(mat)
    uv = mesh.uv_layers.new(name="MaterialUV")
    for polygon in mesh.polygons:
        axis = max(range(3), key=lambda i: abs(polygon.normal[i]))
        u, v = [(1, 2), (0, 2), (0, 1)][axis]
        for index in polygon.loop_indices:
            coordinate = mesh.vertices[mesh.loops[index].vertex_index].co
            uv.uv[index].vector = ((coordinate[u]+.4)*1.8, (coordinate[v]+.4)*1.8)

    rig = bpy.data.armatures.new(name+"Skin")
    armature = bpy.data.objects.new(name+"Skeleton", rig)
    bpy.context.collection.objects.link(armature)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.mode_set(mode="EDIT")
    fixed_name, bend_name, fold_name = name+"Parent", name+"Bend", name+"Fold"
    fixed = rig.edit_bones.new(fixed_name)
    fixed.head, fixed.tail = (0,0,0), (0,0,.2)
    bend = rig.edit_bones.new(bend_name)
    bend.head, bend.tail = (0,0,0), (0,0,-.2)
    bend.parent = fixed
    fold = rig.edit_bones.new(fold_name)
    fold.head, fold.tail = (0,0,0), (0,.12,.12)
    fold.parent = fixed
    bpy.ops.object.mode_set(mode="OBJECT")

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent = armature
    armature.location.x = placement
    a = obj.vertex_groups.new(name=fixed_name)
    b = obj.vertex_groups.new(name=bend_name)
    c = obj.vertex_groups.new(name=fold_name)
    for vertex in mesh.vertices:
        height = vertex.co.z
        t = min(abs(height)/.20, 1)
        weight = t*t*(3-2*t)
        if weight > 0:
            (a if height > 0 else b).add([vertex.index], weight, "REPLACE")
        if weight < 1:
            c.add([vertex.index], 1-weight, "REPLACE")
    modifier = obj.modifiers.new("Joint cloth", "ARMATURE")
    modifier.object = armature
    mesh.calc_loop_triangles()
    return {
        "triangles": len(mesh.loop_triangles),
        "vertices": len(vertices),
        "surface": surface,
        "color": PALETTE[surface],
    }


def trousers(sign):
    return [(y, x*sign, z, rx, rz) for y,x,z,rx,rz in [
        (-.80,.021,.071,.243,.236), (-.64,.018,.059,.268,.261),
        (-.45,.012,.051,.273,.270), (-.21,.004,.021,.278,.276),
        (-.12,.002,-.003,.285,.281), (-.06,.000,-.014,.298,.284),
        (0,-.001,-.009,.306,.291), (.06,-.003,.002,.317,.302),
        (.15,-.012,.012,.317,.302), (.28,-.023,.030,.323,.315),
        (.50,-.043,.043,.348,.343), (.76,-.054,.039,.357,.363),
        (1.00,-.063,.044,.355,.350), (1.14,-.063,.044,.280,.285),
        (1.18,-.064,.044,.268,.271),
    ]]


if __name__ == "__main__":
    for obj in list(bpy.context.scene.objects):
        bpy.data.objects.remove(obj, do_unlink=True)

    groups = {
        "LeftKneeCloth": cuff("LeftKneeCloth", "Twill", trousers(-1), 0),
        "RightKneeCloth": cuff("RightKneeCloth", "Twill", trousers(1), 1.5),
        "ElbowCloth": cuff("ElbowCloth", "Wool", [
            (-.15,0,.004,.181,.180), (-.10,0,.004,.205,.199), (-.055,0,.003,.229,.214),
            (0,0,.005,.249,.224), (.055,0,.003,.255,.239), (.11,0,0,.249,.235),
            (.17,0,0,.228,.204),
        ], 3),
    }
    bpy.ops.export_scene.gltf(
        filepath=str(DEST/"VeteranSeams.glb"), export_format="GLB", export_yup=True,
    )
    (DEST/"seam-layout.json").write_text(json.dumps(groups, indent=2)+"\n")
