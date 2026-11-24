local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local function loadModule(path)
    return luau.load(fs.readFile(path), {
        debugName = path,
        environment = { Vector3 = roblox.Vector3 },
    })()
end

local World = loadModule("src/shared/mammons-gulch/World.luau")
local Definitions = loadModule("src/shared/mammons-gulch/CompoundDefinitions.luau")

local function close(actual, expected)
    assert(math.abs(actual - expected) < 0.001, `{actual} != {expected}`)
end

local northwest = World.sourceToWorld(512, 1536, 32.79)
assert(northwest.X == -1536 and northwest.Y == 0 and northwest.Z == -1536, "northwest conversion")
local southeast = World.sourceToWorld(1536, 512, 116.733)
close(southeast.X, 1536)
close(southeast.Y, 251.829)
close(southeast.Z, 1536)

assert(#Definitions.ordered == 16, "Mammon's Gulch must contain 16 compound definitions")
assert(Definitions.byId.com_i ~= nil, "La Plata definition is missing")
assert(Definitions.byId.com_i.name == "La Plata Mine", "La Plata name")
assert(Definitions.byId.com_i.storeys == 4, "La Plata storeys")
assert(Definitions.byId.com_i.clueSpots == 10, "La Plata published clues")
assert(Definitions.byId.com_i.clueMarkersRaw == 12, "La Plata raw clues")
close(Definitions.byId.com_i.worldPosition[1], -164.352)
close(Definitions.byId.com_i.worldPosition[3], 272.7936)

for _, definition in Definitions.ordered do
    local source = definition.sourceAnchor
    local expected = definition.worldPosition
    local position = World.sourceToWorld(source[1], source[2], source[3])
    close(position.X, expected[1])
    close(position.Y, expected[2])
    close(position.Z, expected[3])
    local x, y, z = World.worldToSource(position)
    close(x, source[1])
    close(y, source[2])
    close(z, source[3])
end

print("mammons-gulch: 16 definitions and coordinate round-trips passed")
