import struct
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from scripts.mammons_gulch.la_plata_reference import (
    decode_plan,
    load_la_plata_plan,
    normalize_plan,
)

PAYLOAD = struct.pack(
    "<25h",
    4 | (3 << 12), 40, 0, 60, 80, -40, 0, 20, 0,
    4 | (1 << 12), 0, 0, 20, 20, -20, 20, 0, -20,
    3 | (2 << 12), 0, 0, 4, 0, 2, 4,
)
ENTRY = {
    "id": "fixture",
    "stairs": [[514.0, 512.0, 50.0, 514.0, 513.0, 54.0, 1.2]],
    "levels": [
        {"label": "Ground floor", "floor": 50.0, "cut": 51.2, "ground": 49.4, "n": 9},
        {"label": "Upper floor", "floor": 54.0, "cut": 55.2, "ground": 49.6, "o": 9, "n": 9, "fo": 18, "fn": 7},
    ],
}


class DecodePlanTest(unittest.TestCase):
    def test_decodes_runs_materials_and_signed_deltas(self):
        decoded = decode_plan(PAYLOAD, ENTRY)
        self.assertEqual(decoded["levels"][0]["walls"], [
            {"points": [[514.0, 512.0], [517.0, 516.0], [515.0, 516.0], [516.0, 516.0]], "material": 3}
        ])
        self.assertEqual(decoded["levels"][1]["walls"], [
            {"points": [[512.0, 512.0], [513.0, 513.0], [512.0, 514.0], [512.0, 513.0]], "material": 1}
        ])
        self.assertEqual(decoded["levels"][1]["floors"], [
            {"points": [[512.0, 512.0], [512.2, 512.0], [512.3, 512.2]], "material": 2}
        ])

    def test_rejects_truncated_wall_payload(self):
        payload = struct.pack("<2h", 3 | (1 << 12), 20)
        with self.assertRaisesRegex(ValueError, "truncated"):
            decode_plan(payload, {"id": "fixture", "levels": [{"label": "Ground", "floor": 50.0, "n": 2}]})

    def test_assigns_marks_and_stairs_by_floor_without_losing_raw_points(self):
        points = {"ground": 49.4, "box": [511.0, 511.0, 518.0, 517.0], "pts": {
            "clue": [[514.0, 512.0, 50.0, ""], [514.0, 512.0, 49.0, "below"]],
            "door": [[514.0, 512.0, 54.0, "door cabin closed"]],
            "lair_anchor": [[514.0, 512.0, 54.0, ""]],
        }}
        plan = normalize_plan(PAYLOAD, ENTRY, points, published_clue_count=1)
        ground, upper = plan["levels"]
        self.assertEqual(len(ground["marks"]["clue"]), 1)
        self.assertEqual(ground["stairs"][0]["widthMetres"], 1.2)
        self.assertEqual(upper["arrivingStairs"], ground["stairs"])
        self.assertEqual(upper["marks"]["door"][0]["variant"], "door cabin closed")
        self.assertTrue(upper["hasLair"])
        self.assertEqual(len(plan["pointGroups"]["clue"]), 2)
        self.assertEqual(plan["clueMarkersRaw"], 2)
        self.assertEqual(plan["clueSpotsPublished"], 1)
        self.assertEqual(plan["materials"][1], "wood")
        self.assertEqual(ground["walls"][0]["materialName"], "stone")
        self.assertTrue(ground["walls"][0]["isStructural"])
        self.assertEqual(plan["materials"][7], "stairs")


class LaPlataDatasetTest(unittest.TestCase):
    def test_complete_reference_dataset(self):
        plan = load_la_plata_plan()
        self.assertEqual(plan["id"], "com_i")
        self.assertEqual(len(plan["levels"]), 4)
        self.assertEqual([level["floor"] for level in plan["levels"]], [52.37, 57.39, 59.3, 65.82])
        self.assertEqual(len(plan["stairs"]), 50)
        self.assertEqual(len(plan["pointGroups"]["door"]), 10)
        self.assertEqual(len(plan["pointGroups"]["window"]), 18)
        self.assertEqual(len(plan["pointGroups"]["ladder"]), 3)
        self.assertEqual(len(plan["pointGroups"]["elevator"]), 1)
        self.assertEqual(plan["lairFloor"], "Upper floor")
        self.assertEqual(plan["clueMarkersRaw"], 12)
        self.assertEqual(plan["clueSpotsPublished"], 10)
        self.assertTrue(all(level["walls"] and level["floors"] for level in plan["levels"]))
        self.assertEqual([len(level["marks"]["clue"]) for level in plan["levels"]], [4, 2, 1, 3])
        self.assertTrue(plan["levels"][1]["hasLair"])
        for source in plan["sources"].values():
            self.assertTrue(source["url"].startswith("https://hunt.innerpulse.net/"))
            self.assertEqual(len(source["sha256"]), 64)


if __name__ == "__main__":
    unittest.main()
