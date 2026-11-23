"""Read the head of the MakeHuman HM08 OBJ while retaining original loop UVs."""


def read_head(base):
    vertices, texcoords, faces = [], [], []
    body = False
    for line in base.read_text().splitlines():
        fields = line.split()
        if not fields:
            continue
        if fields[0] == "v":
            vertices.append(tuple(map(float, fields[1:4])))
        elif fields[0] == "vt":
            texcoords.append(tuple(map(float, fields[1:3])))
        elif fields[0] == "g":
            body = fields[1] == "body"
        elif fields[0] == "f" and body:
            face = [tuple(int(value) - 1 for value in part.split("/")[:2]) for part in fields[1:]]
            if min(vertices[index][1] for index, _ in face) >= 6.71:
                faces.append(face)
    ids = sorted({index for face in faces for index, _ in face})
    remap = {old: i for i, old in enumerate(ids)}
    points = []
    for i in ids:
        x, y, z = vertices[i]
        points.append((x * .377, 3.85 + (y - 6.71) * .392, (z - .48) * .375 + .018))
    polygons = [tuple(remap[index] for index, _ in face) for face in faces]
    uvs = [tuple(texcoords[uv] for _, uv in face) for face in faces]
    return points, polygons, uvs
