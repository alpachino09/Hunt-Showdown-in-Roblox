#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

export PATH="$HOME/.rokit/bin:$PATH"
python3 scripts/generate_lobby.py
python3 scripts/generate_hunter_lab.py
python3 scripts/generate_weapon_lab.py
mkdir -p build
rojo build default.project.json -o build/GreyOutpost-Lobby.rbxl
rojo build places/expedition.project.json -o build/GreyOutpost-Expedition.rbxl
rojo build places/rush.project.json -o build/GreyOutpost-Rush.rbxl
rojo build places/hunter-lab.project.json -o build/GreyOutpost-HunterLab.rbxl
rojo build places/weapon-lab.project.json -o build/GreyOutpost-WeaponLab.rbxl
rojo sourcemap default.project.json -o build/sourcemap.json
