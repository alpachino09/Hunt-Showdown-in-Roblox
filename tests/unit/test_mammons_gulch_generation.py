import tempfile
import unittest
import xml.etree.ElementTree as xml
from pathlib import Path

from scripts.mammons_gulch.generate import generate

ROOT = Path(__file__).resolve().parents[2]
EXPECTED_FOLDERS = {
    "Environment", "Vegetation", "Rocks", "Roads", "Railways", "Rivers", "Bridges",
    "Compounds", "Underground", "InteractiveObjects", "LightingHelpers", "Ambience",
    "SoundTraps", "SpawnPoints", "ClueLocations", "BossLairs", "ExtractionPoints",
    "SupplyPoints", "DebugMarkers", "NPCSpawnRegions",
}


class GenerationTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        root = Path(self.temporary.name)
        self.map_path, self.definitions_path = generate(root / "Map.rbxmx", root / "Definitions.luau")
        self.root = xml.parse(self.map_path).getroot()

    def tearDown(self):
        self.temporary.cleanup()

    def test_map_has_owned_structure_and_sixteen_compounds(self):
        map_node = self.root.find("./Item[@class='Model']")
        compounds = next(
            node for node in map_node.findall("./Item[@class='Folder']")
            if node.find("Properties/string[@name='Name']").text == "Compounds"
        )
        models = compounds.findall("./Item[@class='Model']")
        self.assertEqual(len(models), 16)
        self.assertIn("LaPlataMine", {node.find("Properties/string[@name='Name']").text for node in models})
        names = {node.find("Properties/string[@name='Name']").text for node in map_node.findall("./Item[@class='Folder']")}
        self.assertEqual(EXPECTED_FOLDERS - names, set())

    def test_generated_geometry_contains_no_third_party_code(self):
        executable = {"Script", "LocalScript", "ModuleScript", "RemoteEvent", "RemoteFunction"}
        self.assertEqual([node for node in self.root.iter("Item") if node.attrib["class"] in executable], [])
        massing = [
            model for model in self.root.iter("Item")
            if model.attrib["class"] == "Model" and model.find("Properties/string[@name='Name']").text == "ReferenceMassing"
        ]
        confidence = [node for model in massing for node in model if node.tag == "Item" and node.attrib["class"] == "StringValue" and node.find("Properties/string[@name='Name']").text == "Confidence"]
        self.assertEqual(len(confidence), 16)
        self.assertTrue(all(node.find("Properties/string[@name='Value']").text == "APPROXIMATED" for node in confidence))

    def test_candidate_markers_do_not_become_active_spawns(self):
        candidates = [node for node in self.root.iter("Item") if node.find("Properties/string[@name='Name']") is not None and node.find("Properties/string[@name='Name']").text.startswith("spawn_")]
        self.assertEqual(len(candidates), 42)
        spawns = [node for node in self.root.iter("Item") if node.attrib["class"] == "SpawnLocation"]
        self.assertEqual(len(spawns), 1)
        self.assertEqual(spawns[0].find("Properties/string[@name='Name']").text, "DevelopmentSpawn")

    def test_generation_is_deterministic(self):
        other = Path(self.temporary.name) / "second"
        map_path, definitions_path = generate(other / "Map.rbxmx", other / "Definitions.luau")
        self.assertEqual(self.map_path.read_bytes(), map_path.read_bytes())
        self.assertEqual(self.definitions_path.read_bytes(), definitions_path.read_bytes())


if __name__ == "__main__":
    unittest.main()
