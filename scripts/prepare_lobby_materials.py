"""Prepare the cloth albedo and isolate the face from the CC0 MakeHuman skin atlas.

Usage: uv run --with pillow python scripts/prepare_lobby_materials.py BASE_OBJ MATERIAL_DIR
MATERIAL_DIR contains the unmodified Fabric012 and MakeHuman diffuse maps.
"""
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageOps

from lobby_head import read_head


def prepare(base, directory):
    _, _, face_uvs = read_head(base)
    skin = Image.open(directory / "old_lightskinned_male_diffuse.png").convert("RGB")
    width, height = skin.size
    mask = Image.new("L", skin.size)
    draw = ImageDraw.Draw(mask)
    for uv_face in face_uvs:
        draw.polygon([(round(u * (width - 1)), round((1 - v) * (height - 1)))
                      for u, v in uv_face], fill=255)
    mask = mask.filter(ImageFilter.MaxFilter(11))
    isolated = Image.composite(skin, Image.new("RGB", skin.size, (135, 97, 76)), mask)
    isolated.resize((1024, 1024), Image.Resampling.LANCZOS).save(directory / "OutpostFace.jpg", quality=94)

    cloth = Image.open(directory / "Fabric012_1K-JPG_Color.jpg").convert("L")
    cloth = ImageOps.autocontrast(cloth, cutoff=1)
    cloth = cloth.point(lambda intensity: 151 + intensity * .27)
    cloth.convert("RGB").save(directory / "OutpostCloth.jpg", quality=91)


if __name__ == "__main__":
    prepare(Path(sys.argv[1]), Path(sys.argv[2]))
