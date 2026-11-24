from math import cos, radians, sin
from pathlib import Path
from xml.etree import ElementTree as xml


def prop(obj, kind, name, value):
    properties = obj.find("Properties")
    node = xml.SubElement(properties, kind, name=name)
    if isinstance(value, dict):
        for key, item in value.items():
            xml.SubElement(node, key).text = str(item)
    else:
        node.text = str(value)
    return node


def item(parent, kind, name):
    obj = xml.SubElement(parent, "Item", {"class": kind})
    xml.SubElement(obj, "Properties")
    prop(obj, "string", "Name", name)
    return obj


def folder(parent, name, kind="Folder"):
    return item(parent, kind, name)


def ensure(parent, kind, name):
    for child in parent.findall("Item"):
        if child.attrib.get("class") == kind and child.find("Properties/string[@name='Name']").text == name:
            return child
    return item(parent, kind, name)


def vec(values):
    return dict(zip(("X", "Y", "Z"), values))


def rgb(color):
    return dict(zip(("R", "G", "B"), (value / 255 for value in color)))


def dim2(x_scale, x_offset, y_scale, y_offset):
    return dict(zip(("XS", "XO", "YS", "YO"), (x_scale, x_offset, y_scale, y_offset)))


def part(parent, name, size, position, color=(150, 149, 142), material=512, collide=False,
         visible=True, yaw=0, kind="Part"):
    obj = item(parent, kind, name)
    angle = radians(yaw)
    c, s = cos(angle), sin(angle)
    rotation = (c, 0, s, 0, 1, 0, -s, 0, c)
    prop(obj, "CoordinateFrame", "CFrame", vec(position) | {
        f"R{index // 3}{index % 3}": round(value, 8) for index, value in enumerate(rotation)
    })
    prop(obj, "Vector3", "size", vec(size))
    packed = (255 << 24) | (color[0] << 16) | (color[1] << 8) | color[2]
    prop(obj, "Color3uint8", "Color3uint8", packed)
    prop(obj, "token", "Material", material)
    prop(obj, "bool", "Anchored", "true")
    prop(obj, "bool", "CanCollide", str(collide).lower())
    prop(obj, "bool", "CanQuery", str(collide).lower())
    prop(obj, "bool", "CanTouch", "false")
    prop(obj, "float", "Transparency", 0 if visible else 1)
    return obj


def marker(parent, name, position, color=(205, 187, 115)):
    return part(parent, name, (0.5, 0.5, 0.5), position, color, visible=False)


def string_value(parent, name, value):
    obj = item(parent, "StringValue", name)
    prop(obj, "string", "Value", value)
    return obj


def billboard(parent, caption, max_distance=700):
    gui = item(parent, "BillboardGui", "CompoundLabel")
    prop(gui, "UDim2", "Size", dim2(0, 260, 0, 54))
    prop(gui, "Vector3", "StudsOffsetWorldSpace", vec((0, 0, 0)))
    prop(gui, "float", "MaxDistance", max_distance)
    prop(gui, "bool", "AlwaysOnTop", "false")
    label = item(gui, "TextLabel", "Name")
    prop(label, "UDim2", "Size", dim2(1, 0, 1, 0))
    prop(label, "float", "BackgroundTransparency", 1)
    prop(label, "string", "Text", caption)
    prop(label, "token", "Font", 15)
    prop(label, "float", "TextSize", 26)
    prop(label, "Color3", "TextColor3", rgb((232, 222, 195)))
    prop(label, "float", "TextStrokeTransparency", 0.2)
    prop(label, "bool", "TextWrapped", "true")


def build(root, output):
    for index, element in enumerate(root.iter("Item")):
        element.attrib.setdefault("referent", f"RBX{index}")
    xml.indent(root, "  ")
    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)
    xml.ElementTree(root).write(output, encoding="utf-8", xml_declaration=True)
