"""Combine the Veteran meshes and embed licensed PBR maps for Studio's 3D Importer.

Pass the directory with OutpostCloth.jpg and Fabric012 maps and then the directory
with the original 1K maps of Poly Haven's fabric_leather_01 after --.
"""
from pathlib import Path
import sys

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from prepare_veteran import body, export, head
from prepare_veteran_gear import gear, hat
from prepare_veteran_outfit import outfit

FABRIC = {"Wool", "Vest", "VestLapel", "Canvas", "Twill", "LapelCloth", "Lining", "HatFelt"}
LEATHER = {"GloveLeather", "BootLeather", "DarkLeather", "LeatherEdge"}
METAL = {"DullIron", "WornBrass"}


def map_node(mat, path, name, socket):
    nodes = mat.node_tree.nodes
    shader = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    image = nodes.new("ShaderNodeTexImage")
    image.label = name
    image.image = bpy.data.images.load(str(path), check_existing=True)
    if socket != "Base Color":
        image.image.colorspace_settings.name = "Non-Color"
    if socket == "Normal":
        normal = nodes.new("ShaderNodeNormalMap")
        mat.node_tree.links.new(image.outputs["Color"], normal.inputs["Color"])
        mat.node_tree.links.new(normal.outputs["Normal"], shader.inputs[socket])
    else:
        mat.node_tree.links.new(image.outputs["Color"], shader.inputs[socket])


def project(mesh, scale):
    # Project each surface along its dominant axis. All pieces use the same physical grain size.
    bounds = [min(v.co[i] for v in mesh.vertices) for i in range(3)]
    uv = mesh.uv_layers.new(name="MaterialUV")
    for polygon in mesh.polygons:
        normal = polygon.normal
        axis = max(range(3), key=lambda i: abs(normal[i]))
        axes = [(1, 2), (0, 2), (0, 1)][axis]
        for index in polygon.loop_indices:
            co = mesh.vertices[mesh.loops[index].vertex_index].co
            uv.uv[index].vector = tuple((co[i]-bounds[i])*scale for i in axes)


def finish_with(fabric_dir, leather_dir):
    configured = set()

    def finish(name, mesh, material, key):
        if key in FABRIC:
            project(mesh, 2.25 if name in {"HatBrim", "HatCrown"} else 1.8)
            if key not in configured:
                map_node(material, fabric_dir/"OutpostCloth.jpg", "Fabric012 albedo", "Base Color")
                map_node(material, fabric_dir/"Fabric012_1K-JPG_NormalGL.jpg", "Fabric012 normal", "Normal")
                map_node(material, fabric_dir/"Fabric012_1K-JPG_Roughness.jpg", "Fabric012 roughness", "Roughness")
        elif key in LEATHER:
            project(mesh, 1.17)
            if key not in configured:
                map_node(material, leather_dir/"fabric_leather_01_Diffuse.jpg", "Leather albedo", "Base Color")
                map_node(material, leather_dir/"fabric_leather_01_nor_gl.jpg", "Leather normal", "Normal")
                map_node(material, leather_dir/"fabric_leather_01_Rough.jpg", "Leather roughness", "Roughness")
        elif key in METAL:
            shader = next(n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
            shader.inputs["Metallic"].default_value = .67
            shader.inputs["Roughness"].default_value = .65
        configured.add(key)

    return finish


if __name__ == "__main__":
    fabric, leather = [Path(path) for path in sys.argv[sys.argv.index("--") + 1:]]
    head()
    body()
    outfit()
    hat()
    gear()
    export(stem="VeteranStudio", layout="kit-layout.json", finish=finish_with(fabric, leather),
           prefix="Geo_")
