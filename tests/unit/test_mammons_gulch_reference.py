import json
import math
import struct
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from scripts.mammons_gulch.reference import (
    decode_heightfield,
    load_layout,
    normalized_to_source,
    sample_height,
    source_to_world,
    world_to_source,
)

DATA = ROOT / "assets" / "mammons-gulch" / "reference"
EXPECTED_NAMES = {
    "Blackthorn Stockyard", "The Gasworks", "Terminus Railyard", "Grizzly Lodge",
    "O'Donovan Stone", "Monteros Malt", "East Mountain Corn", "Deadfall Timber",
    "La Plata Mine", "Split River Mill", "Machine Gorge", "Preston Oil",
    "Kingfisher Foundry", "Oro Gordo Mine", "Graystone Pit", "Miner's Folly",
}


class CoordinateTest(unittest.TestCase):
    def test_decodes_row_delta_encoded_normalized_heights(self):
        payload = struct.pack("<HHHH", 5, 10, 20, 30)
        heights = decode_heightfield(payload, {"grid": 2, "zmin": 0.0, "zmax": 65535.0})
        self.assertEqual(heights, [5.0, 15.0, 20.0, 50.0])

    def test_rejects_truncated_heightfield(self):
        with self.assertRaisesRegex(ValueError, "heightfield size"):
            decode_heightfield(b"\x00\x00", {"grid": 2, "zmin": 0, "zmax": 1})

    def test_height_sampling_interpolates_all_four_neighbours(self):
        metadata = {"grid": 2, "origin": [0, 0], "sizeMetres": 1, "stepMetres": 1}
        self.assertEqual(sample_height([0.0, 10.0, 20.0, 30.0], metadata, 0.5, 0.5), 15.0)

    def test_world_corners_keep_north_at_negative_z(self):
        self.assertEqual(source_to_world(512, 1536, 32.79), (-1536.0, 0.0, -1536.0))
        x, y, z = source_to_world(1536, 512, 116.733)
        self.assertEqual((x, z), (1536.0, 1536.0))
        self.assertAlmostEqual(y, 251.829)

    def test_la_plata_label_anchor_is_not_bbox_centre(self):
        x, y = normalized_to_source(446.5, 588.8)
        world = source_to_world(x, y, 50.0)
        self.assertAlmostEqual(world[0], -164.352)
        self.assertAlmostEqual(world[2], 272.7936)
        restored = world_to_source(world)
        self.assertAlmostEqual(restored[0], x, delta=0.001)
        self.assertAlmostEqual(restored[1], y, delta=0.001)
        self.assertAlmostEqual(restored[2], 50.0, delta=0.001)


class ReferenceDatasetTest(unittest.TestCase):
    def test_all_compounds_and_posts_are_present(self):
        layout = load_layout(DATA / "layout.json")
        self.assertEqual(layout["sizeMetres"], 1024)
        self.assertEqual(len(layout["compounds"]), 16)
        self.assertEqual({item["name"] for item in layout["compounds"]}, EXPECTED_NAMES)
        self.assertEqual(len({item["id"] for item in layout["compounds"]}), 16)
        self.assertEqual(len(layout["posts"]["extraction"]), 21)
        self.assertEqual(len(layout["posts"]["spawn"]), 42)
        self.assertEqual(len(layout["posts"]["resupply"]), 40)
        self.assertEqual(len(layout["posts"]["resupplyRaw"]), 59)

    def test_heightfield_is_complete_and_finite(self):
        metadata = json.loads((DATA / "terrain.json").read_text(encoding="utf-8"))
        self.assertEqual(metadata["grid"], 513)
        self.assertEqual(metadata["stepMetres"], 2)
        heights = decode_heightfield((DATA / "terrain.u16").read_bytes(), metadata)
        self.assertEqual(len(heights), 513 * 513)
        self.assertTrue(all(math.isfinite(value) for value in heights))
        self.assertAlmostEqual(min(heights), 32.79, places=2)
        self.assertAlmostEqual(max(heights), 116.733, places=2)
        self.assertGreater(len(metadata["water"]), 0)

    def test_height_samples_match_compound_ground_controls(self):
        metadata = json.loads((DATA / "terrain.json").read_text(encoding="utf-8"))
        heights = decode_heightfield((DATA / "terrain.u16").read_bytes(), metadata)
        self.assertAlmostEqual(sample_height(heights, metadata, 678.52, 1427.21), 43.4936, places=3)
        self.assertAlmostEqual(sample_height(heights, metadata, 1041.86, 1253.01), 37.0179, places=3)

    def test_la_plata_has_measured_floors_clues_and_lair(self):
        layout = load_layout(DATA / "layout.json")
        la_plata = next(item for item in layout["compounds"] if item["name"] == "La Plata Mine")
        self.assertEqual(la_plata["id"], "com_i")
        self.assertEqual(la_plata["storeys"], 4)
        self.assertEqual(la_plata["clueSpots"], 10)
        self.assertEqual(la_plata["clueMarkersRaw"], 12)
        self.assertEqual(la_plata["lairFloor"], "Upper floor")
        self.assertEqual([level["label"] for level in la_plata["levels"]], [
            "Ground floor", "Upper floor", "Upper floor 2", "Upper floor 3",
        ])
        self.assertTrue(all(level["floor"] > 0 for level in la_plata["levels"]))

    def test_points_keep_compound_and_variant_metadata(self):
        points = json.loads((DATA / "points.json").read_text(encoding="utf-8"))
        self.assertEqual(len(points["lair_anchor"]), 16)
        self.assertEqual(len(points["clue"]), 285)
        self.assertEqual(len(points["door"]), 339)
        self.assertEqual(len(points["window"]), 193)
        la_plata_clue = next(item for item in points["clue"] if item["compoundId"] == "com_i")
        self.assertEqual(la_plata_clue["position"], [982.62, 933.82, 57.95])

    def test_each_compound_spec_separates_evidence_from_pending_work(self):
        specifications = list((ROOT / "docs" / "map-compounds").glob("*.md"))
        self.assertEqual(len(specifications), 16)
        la_plata = (ROOT / "docs" / "map-compounds" / "la-plata-mine.md").read_text(encoding="utf-8")
        self.assertIn("CONFIRMED", la_plata)
        self.assertIn("PENDING_RESEARCH", la_plata)
        self.assertIn("0.6", la_plata)

    def test_compound_summary_accepts_singular_storey(self):
        from scripts.mammons_gulch.reference import parse_compound_summaries

        page = '<a class="cpx-card" href="/maps/3d/mammons-gulch/east-mountain-corn/" data-search="1 storey · lair on the ground floor · 6 clue spots"></a>'
        summary = parse_compound_summaries(page, expected_count=1)["east-mountain-corn"]
        self.assertEqual(summary["storeys"], 1)
        self.assertEqual(summary["lairFloor"], "Ground floor")
        self.assertEqual(summary["clueSpots"], 6)

    def test_compound_summary_accepts_lair_in_lower_tunnels(self):
        from scripts.mammons_gulch.reference import parse_compound_summaries

        page = '<a class="cpx-card" href="/maps/3d/mammons-gulch/oro-gordo-mine/" data-search="4 storeys · lair in the lower tunnels · 18 clue spots"></a>'
        summary = parse_compound_summaries(page, expected_count=1)["oro-gordo-mine"]
        self.assertEqual(summary["lairFloor"], "Lower tunnels")


if __name__ == "__main__":
    unittest.main()
