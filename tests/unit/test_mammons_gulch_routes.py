import json
import unittest
from pathlib import Path

from scripts.mammons_gulch.routes import load_routes, validate_routes
from scripts.mammons_gulch.underground import build_graph, load_hole_mask, region_levels

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "assets" / "mammons-gulch" / "reference"


class RouteContractTest(unittest.TestCase):
    def test_routes_have_finite_endpoints_and_playable_widths(self):
        routes = load_routes(REFERENCE / "routes.json")
        validate_routes(routes)
        self.assertGreaterEqual(len(routes["roads"]), 3)
        self.assertGreaterEqual(len(routes["railways"]), 1)
        self.assertGreaterEqual(len(routes["bridges"]), 1)
        for group in ("roads", "railways", "bridges"):
            for route in routes[group]:
                self.assertGreaterEqual(len(route["points"]), 2, route["id"])
                self.assertGreaterEqual(route["widthMetres"], 3, route["id"])
                self.assertNotEqual(route["confidence"], "CONFIRMED", route["id"])
                for x, y in route["points"]:
                    self.assertTrue(512 <= x <= 1536, (route["id"], x))
                    self.assertTrue(512 <= y <= 1536, (route["id"], y))

    def test_invalid_route_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "widthMetres"):
            validate_routes({"roads": [{"id": "bad", "widthMetres": 1, "confidence": "CONFIRMED", "points": [[512, 512], [513, 513]]}], "railways": [], "bridges": []})


class UndergroundContractTest(unittest.TestCase):
    def test_all_regions_have_levels_and_connected_graph(self):
        metadata = json.loads((REFERENCE / "terrain.json").read_text(encoding="utf-8"))
        nodes, edges = build_graph(metadata["undergroundRegions"])
        self.assertEqual(len(nodes), 21)
        self.assertEqual(len(edges), 20)
        seen = {nodes[0]}
        while True:
            before = len(seen)
            for first, second in edges:
                if first in seen:
                    seen.add(second)
                if second in seen:
                    seen.add(first)
            if len(seen) == before:
                break
        self.assertEqual(len(seen), 21)
        for region in metadata["undergroundRegions"]:
            floor, ceiling = region_levels(region)
            self.assertLess(floor, ceiling)
            self.assertGreaterEqual(ceiling - floor, 3)

    def test_hole_mask_has_documented_size_and_count(self):
        mask = load_hole_mask(REFERENCE / "holes.bin")
        self.assertEqual(len(mask), 513 * 513)
        self.assertEqual(sum(1 for index in range(513 * 513) if mask[index]), 1445)


if __name__ == "__main__":
    unittest.main()
