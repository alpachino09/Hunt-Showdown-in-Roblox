#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"

stylua --check src places tests
selene src places tests
python3 -m unittest discover -s tests/unit -p 'test_*.py'
lune run tests/unit/FootPlantContact.luau
lune run tests/unit/MammonsGulchLayout.luau
./scripts/build.sh

if [ ! -s build/roblox.d.luau ]; then
    curl -fsSL --max-time 30 \
        https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.70.1/scripts/globalTypes.d.luau \
        -o build/roblox.d.luau.tmp
    mv build/roblox.d.luau.tmp build/roblox.d.luau
fi

luau-lsp analyze --platform roblox --definitions @roblox=build/roblox.d.luau \
    --sourcemap build/sourcemap.json src places/lobby/server
rojo sourcemap places/hunter-lab.project.json -o build/hunter-lab.sourcemap.json
(
    cd places
    luau-lsp analyze --platform roblox --definitions @roblox=../build/roblox.d.luau \
        --sourcemap ../build/hunter-lab.sourcemap.json hunter-lab/server hunter-lab/client ../src/shared
)
for mode in expedition rush; do
    rojo sourcemap "places/$mode.project.json" -o "build/$mode.sourcemap.json"
    (
        cd places
        luau-lsp analyze --platform roblox --definitions @roblox=../build/roblox.d.luau \
            --sourcemap "../build/$mode.sourcemap.json" ../src/server ../src/shared \
            ../src/expedition-client "$mode/server"
    )
done

(
    cd places
    luau-lsp analyze --platform roblox --definitions @roblox=../build/roblox.d.luau \
        --sourcemap ../build/mammons-gulch.sourcemap.json ../src/shared \
        mammons-gulch/server mammons-gulch/client
)
