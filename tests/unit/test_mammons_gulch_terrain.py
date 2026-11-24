import base64
import json
import struct
import tempfile
import unittest
import xml.etree.ElementTree as xml
from pathlib import Path

from scripts.mammons_gulch.terrain import (
    NO_WATER,
    build_water_levels,
    generate_terrain_data,
    pack_u16_levels,
    point_in_polygon,
)


class WaterGridTest(unittest.TestCase):
    def test_point_in_polygon_handles_inside_outside_and_vertex(self):
        square = [[0, 0], [4, 0], [4, 4], [0, 4]]
        self.assertTrue(point_in_polygon(2, 2, square))
        self.assertTrue(point_in_polygon(0, 0, square))
        self.assertFalse(point_in_polygon(5, 5, square))

    def test_water_grid_marks_only_cells_below_water_level(self):
        metadata = {"grid": 3, "origin": [0, 0], "sizeMetres": 4, "stepMetres": 2}
        heights = [6.0] * 9
        heights[4] = 2.0
        water = [{"z": 5.0, "pts": [[1, 1], [3, 1], [3, 3], [1, 3]]}]
        levels = build_water_levels(heights, metadata, water)
        self.assertEqual(levels[4], 5.0)
        self.assertTrue(all(level == NO_WATER for index, level in enumerate(levels) if index != 4))

    def test_pack_u16_levels_preserves_sentinel_and_quantizes_height(self):
        packed = pack_u16_levels([NO_WATER, 5.0], 0.0, 10.0)
        self.assertEqual(struct.unpack("<HH", packed), (65535, 32768))


class TerrainDataTest(unittest.TestCase):
    def test_generated_module_roundtrips_height_and_water_payloads(self):
        with tempfile.TemporaryDirectory() as directory:
            output = generate_terrain_data(Path(directory) / "TerrainData.luau")
            source = output.read_text(encoding="utf-8")
            self.assertTrue(source.lstrip().startswith("return {"))
            height_encoded = source.split('heightData = "', 1)[1].split('"', 1)[0]
            water_encoded = source.split('waterData = "', 1)[1].split('"', 1)[0]
            reference = Path("assets/mammons-gulch/reference")
            self.assertEqual(base64.b64decode(height_encoded), (reference / "terrain.u16").read_bytes())
            water = base64.b64decode(water_encoded)
            self.assertEqual(len(water), 513 * 513 * 2)
            metadata = json.loads((reference / "terrain.json").read_text(encoding="utf-8"))
            self.assertIn(f'grid = {metadata["grid"]}', source)
            self.assertIn(f'zmin = {metadata["zmin"]}', source)


if __name__ == "__main__":
    unittest.main()
