#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

export PATH="$HOME/.rokit/bin:$PATH"
python3 scripts/generate_lobby.py
mkdir -p build
rojo build default.project.json -o build/GreyOutpost-Lobby.rbxl
rojo build places/expedition.project.json -o build/GreyOutpost-Expedition.rbxl
rojo build places/rush.project.json -o build/GreyOutpost-Rush.rbxl
rojo sourcemap default.project.json -o build/sourcemap.json
