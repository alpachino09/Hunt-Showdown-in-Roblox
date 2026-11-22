#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"

stylua --check src places tests
selene src places tests
./scripts/build.sh

if [ ! -s build/roblox.d.luau ]; then
    curl -fsSL --max-time 30 \
        https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.70.1/scripts/globalTypes.d.luau \
        -o build/roblox.d.luau.tmp
    mv build/roblox.d.luau.tmp build/roblox.d.luau
fi

luau-lsp analyze --platform roblox --definitions @roblox=build/roblox.d.luau \
    --sourcemap build/sourcemap.json src places/lobby/server
for mode in expedition rush; do
    rojo sourcemap "places/$mode.project.json" -o "build/$mode.sourcemap.json"
    (
        cd places
        luau-lsp analyze --platform roblox --definitions @roblox=../build/roblox.d.luau \
            --sourcemap "../build/$mode.sourcemap.json" ../src/server ../src/shared \
            ../src/expedition-client "$mode/server"
    )
done
