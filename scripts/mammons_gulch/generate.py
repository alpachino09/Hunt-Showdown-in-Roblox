from pathlib import Path
import json
import xml.etree.ElementTree as xml

from .compounds import render_compounds, render_definitions
from .markers import render_markers
from .reference import DATA, decode_heightfield, load_layout
from .railway import render_railway
from .routes import load_routes, render_routes
from .underground import load_hole_mask, render_underground
from .xml import ensure, item, build

ROOT = Path(__file__).resolve().parents[2]
MAP_OUTPUT = ROOT / "build" / "generated" / "MammonsGulch.rbxmx"
DEFINITIONS_OUTPUT = ROOT / "src" / "shared" / "mammons-gulch" / "CompoundDefinitions.luau"
ROOT_FOLDERS = (
    "Environment", "Vegetation", "Rocks", "Roads", "Railways", "Rivers", "Bridges",
    "Compounds", "Underground", "InteractiveObjects", "LightingHelpers", "Ambience",
    "SoundTraps", "SpawnPoints", "ClueLocations", "BossLairs", "ExtractionPoints",
    "SupplyPoints", "DebugMarkers", "NPCSpawnRegions",
)


def generate(map_path=MAP_OUTPUT, definitions_path=DEFINITIONS_OUTPUT):
    layout = load_layout()
    terrain = json.loads((DATA / "terrain.json").read_text(encoding="utf-8"))
    heights = decode_heightfield((DATA / "terrain.u16").read_bytes(), terrain)
    document = xml.Element("roblox", version="4")
    world = item(document, "Model", "MammonsGulch")
    for name in ROOT_FOLDERS:
        ensure(world, "Folder", name)
    render_compounds(world, layout, heights, terrain, ensure(world, "Folder", "DebugMarkers"))
    render_markers(world, layout, json.loads((DATA / "points.json").read_text(encoding="utf-8")))
    render_routes(world, load_routes(), heights, terrain)
    for route in load_routes()["railways"]:
        render_railway(route, ensure(world, "Folder", "Railways"), heights, terrain)
    render_underground(ensure(world, "Folder", "Underground"), terrain["undergroundRegions"], heights, terrain, load_hole_mask())
    build(document, map_path)
    definitions_path = Path(definitions_path)
    definitions_path.parent.mkdir(parents=True, exist_ok=True)
    definitions_path.write_text(render_definitions(layout), encoding="utf-8")
    return Path(map_path), definitions_path


def main():
    from .terrain import generate_terrain_data

    map_path, definitions_path = generate()
    terrain_path = generate_terrain_data()
    print(f"Generated {map_path.relative_to(ROOT)}, {definitions_path.relative_to(ROOT)} and {terrain_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
