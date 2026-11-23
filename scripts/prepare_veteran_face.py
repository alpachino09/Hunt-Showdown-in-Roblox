"""Fit the Veteran's hair and facial hair to the surface of the original head."""
import sys
from math import cos, pi, sin
from pathlib import Path

from mathutils import Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
from prepare_veteran import MATERIAL, PARTS, add, export, head


def shell(name, surface, rows, rows_width, thickness):
    top_count = len(rows)
    vertices = [*rows, *[tuple(point - normal * thickness) for point, normal in rows.normals]]
    depth = top_count // rows_width
    faces = []
    for y in range(depth-1):
        for x in range(rows_width-1):
            origin = y*rows_width + x
            quad = (origin, origin+1, origin+rows_width+1, origin+rows_width)
            faces.append(quad)
            faces.append(tuple(top_count + i for i in reversed(quad)))
    perimeter = [
        *range(rows_width),
        *range(2*rows_width-1, top_count, rows_width),
        *range(top_count-2, top_count-rows_width-1, -1),
        *range(top_count-2*rows_width, 0, -rows_width),
    ]
    for a, b in zip(perimeter, perimeter[1:]+perimeter[:1]):
        faces.append((b,a,a+top_count,b+top_count))
    add(name, surface, vertices, faces)


class Samples(list):
    def __init__(self):
        super().__init__()
        self.normals = []

    def offset(self, surface, origin, direction, distance):
        normal = -direction.normalized()
        position, _, _, _ = surface.ray_cast(origin, direction)
        assert position is not None, (origin, direction)
        front = position + normal*distance
        self.append(tuple(front))
        self.normals.append((front, normal))


def beard(surface):
    for sections in (
        [(4.469,.12), (4.486,.20), (4.529,.284), (4.574,.345), (4.607,.375), (4.628,.395)],
        [(4.645,.15), (4.658,.17), (4.675,.176), (4.696,.145), (4.712,.081)],
    ):
        points = Samples()
        for row, (y, width) in enumerate(sections):
            for i in range(15):
                edge = i/7 - 1
                detail = .030*abs(edge)**1.4 if width>.22 else -.014*abs(edge)
                points.offset(surface, Vector((edge*width,y+detail,-1)), Vector((0,0,1)), .011 + .005*sin(row/len(sections)*pi))
        shell("ReedBeard", "Beard", points, 15, .014)


def hair(surface):
    points = Samples()
    columns = 41
    for row in range(9):
        for column in range(columns):
            t = column/(columns-1)
            angle = -.16 + (pi+.32)*t
            lower = 4.74 + .21*abs(2*t-1)**3 + .012*sin(t*22)
            y = lower + (5.416-lower)*row/8
            direction = Vector((cos(angle),0,sin(angle)))
            origin = 1.4*direction + Vector((0,y,.032))
            points.offset(surface, origin, -direction, .024 + .017*sin(t*pi)*sin(row*pi/8))
    shell("ReedHair", "Brow", points, columns, .025)


if __name__ == "__main__":
    head()
    vertices, faces = PARTS["Head"]
    surface = BVHTree.FromPolygons(vertices, faces)
    PARTS.clear()
    MATERIAL.clear()
    beard(surface)
    hair(surface)
    export("VeteranFace", "face-layout.json", prefix="Geo_")
