--!strict

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Data = require(script.Parent.MammonsGulchTerrainData)
local TerrainBuilder = {}
local BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local BASE64_INDEX = {}
for index = 1, #BASE64 do
    BASE64_INDEX[string.sub(BASE64, index, index)] = index - 1
end

local function decodeBase64(payload: string): string
    local chunks = {}
    local piece = {}
    local pieceCount = 0
    local accumulator = 0
    local bits = 0
    for index = 1, #payload do
        local character = string.sub(payload, index, index)
        local value = BASE64_INDEX[character]
        if value ~= nil then
            accumulator = accumulator * 64 + value
            bits += 6
            if bits >= 8 then
                bits -= 8
                local byte = math.floor(accumulator / 2 ^ bits) % 256
                pieceCount += 1
                piece[pieceCount] = string.char(byte)
                accumulator %= 2 ^ bits
                if pieceCount == 4096 then
                    chunks[#chunks + 1] = table.concat(piece)
                    piece = {}
                    pieceCount = 0
                end
            end
        elseif character == "=" then
            break
        end
    end
    if pieceCount > 0 then
        chunks[#chunks + 1] = table.concat(piece)
    end
    return table.concat(chunks)
end

local function decodeHeights(): { number }
    local payload = decodeBase64(Data.heightData)
    assert(#payload == Data.grid * Data.grid * 2, "height payload size")
    local heights = table.create(Data.grid * Data.grid)
    local scale = (Data.zmax - Data.zmin) / 65535
    for row = 1, Data.grid do
        local value = 0
        for column = 1, Data.grid do
            local index = (row - 1) * Data.grid + column
            local encoded = string.byte(payload, index * 2 - 1)
                + string.byte(payload, index * 2) * 256
            value = (value + encoded) % 65536
            heights[index] = Data.zmin + value * scale
        end
    end
    return heights
end

local function decodeWater(): { [number]: number }
    local payload = decodeBase64(Data.waterData)
    assert(#payload == Data.grid * Data.grid * 2, "water payload size")
    local levels = {}
    local scale = (Data.zmax - Data.zmin) / 65535
    for index = 1, Data.grid * Data.grid do
        local encoded = string.byte(payload, index * 2 - 1) + string.byte(payload, index * 2) * 256
        if encoded ~= 65535 then
            levels[index] = Data.zmin + encoded * scale
        end
    end
    return levels
end

local HEIGHTS = decodeHeights()
local WATER = decodeWater()
local HOLES_PAYLOAD = decodeBase64(Data.holesData)
assert(#HOLES_PAYLOAD * 8 >= Data.grid * Data.grid, "hole payload size")
local HOLES = {}
for index = 1, Data.grid * Data.grid do
    local byte = string.byte(HOLES_PAYLOAD, math.floor((index - 1) / 8) + 1)
    local mask = 2 ^ (7 - (index - 1) % 8)
    HOLES[index] = byte % (mask * 2) >= mask
end

local function sampleHeight(x: number, z: number): number
    local sourceX = x / Data.studsPerMetre + 1024
    local sourceY = 1024 - z / Data.studsPerMetre
    local column = (sourceX - Data.origin[1]) / Data.stepMetres
    local row = (Data.origin[2] + Data.sizeMetres - sourceY) / Data.stepMetres
    local x0 = math.clamp(math.floor(column), 0, Data.grid - 2)
    local y0 = math.clamp(math.floor(row), 0, Data.grid - 2)
    local fx = math.clamp(column - x0, 0, 1)
    local fy = math.clamp(row - y0, 0, 1)
    local x1 = x0 + 1
    local y1 = y0 + 1
    local top = HEIGHTS[y0 * Data.grid + x0 + 1] * (1 - fx) + HEIGHTS[y0 * Data.grid + x1 + 1] * fx
    local bottom = HEIGHTS[y1 * Data.grid + x0 + 1] * (1 - fx)
        + HEIGHTS[y1 * Data.grid + x1 + 1] * fx
    return (top * (1 - fy) + bottom * fy - Data.heightOffsetMetres) * Data.studsPerMetre
end

local function sampleWater(x: number, z: number): number?
    local sourceX = x / Data.studsPerMetre + 1024
    local sourceY = 1024 - z / Data.studsPerMetre
    local column =
        math.clamp(math.floor((sourceX - Data.origin[1]) / Data.stepMetres + 0.5), 0, Data.grid - 1)
    local row = math.clamp(
        math.floor((Data.origin[2] + Data.sizeMetres - sourceY) / Data.stepMetres + 0.5),
        0,
        Data.grid - 1
    )
    local level = WATER[row * Data.grid + column + 1]
    if level == nil then
        return nil
    end
    return (level - Data.heightOffsetMetres) * Data.studsPerMetre
end

local function sampleHole(x: number, z: number): boolean
    local sourceX = x / Data.studsPerMetre + 1024
    local sourceY = 1024 - z / Data.studsPerMetre
    local column =
        math.clamp(math.floor((sourceX - Data.origin[1]) / Data.stepMetres + 0.5), 0, Data.grid - 1)
    local row = math.clamp(
        math.floor((Data.origin[2] + Data.sizeMetres - sourceY) / Data.stepMetres + 0.5),
        0,
        Data.grid - 1
    )
    return HOLES[row * Data.grid + column + 1] == true
end

local function solidMaterial(x: number, z: number, height: number): Enum.Material
    local dx = sampleHeight(x + 4, z) - height
    local dz = sampleHeight(x, z + 4) - height
    local slope = math.sqrt(dx * dx + dz * dz) / 4
    local sourceHeight = height / Data.studsPerMetre + Data.heightOffsetMetres
    if slope >= 0.65 or sourceHeight >= 100 then
        return Enum.Material.Rock
    end
    if slope >= 0.3 then
        return Enum.Material.Slate
    end
    if sourceHeight <= 45 and slope <= 0.12 then
        return Enum.Material.Ground
    end
    return Enum.Material.Grass
end

local function selfTest()
    assert(decodeBase64("QQ==") == "A", "base64 single byte")
    assert(decodeBase64("TWFu") == "Man", "base64 multiple bytes")
    local northwest = sampleHeight(-1536, -1536)
    local southeast = sampleHeight(1536, 1536)
    assert(northwest >= -16 and southeast >= -16, "height bounds")
    assert(math.abs(sampleHeight(-1036.44, -1209.63) - 32.110875) < 0.01, "Blackthorn height")
    assert(math.abs(sampleHeight(53.58, -686.97) - 12.6837) < 0.01, "Monteros height")
    assert(math.abs(sampleHeight(-164.352, 272.7936) - 74.24616) < 0.01, "La Plata height")
    local river = sampleWater(-600, -1398)
    assert(river ~= nil and math.abs(river - 4.89) < 0.01, "river water level")
    assert(sampleHole(-108, 54), "mine opening")
    return true
end

local function carveHoles()
    local count = 0
    local terrain = Workspace.Terrain
    for index = 1, Data.grid * Data.grid do
        if HOLES[index] then
            local row = math.floor((index - 1) / Data.grid)
            local column = (index - 1) % Data.grid
            local sourceX = Data.origin[1] + column * Data.stepMetres
            local sourceY = Data.origin[2] + Data.sizeMetres - row * Data.stepMetres
            local x = (sourceX - 1024) * Data.studsPerMetre
            local z = (1024 - sourceY) * Data.studsPerMetre
            terrain:FillBlock(CFrame.new(x, 122, z), Vector3.new(12, 276, 12), Enum.Material.Air)
            count += 1
            if count % 50 == 0 then
                task.wait()
            end
        end
    end
    return count
end

TerrainBuilder.carveHoles = carveHoles
TerrainBuilder.selfTest = selfTest
TerrainBuilder.sampleHole = sampleHole

function TerrainBuilder.apply()
    assert(RunService:IsStudio(), "TerrainBuilder is Studio-only")
    assert(selfTest())
    local terrain = Workspace.Terrain
    terrain:Clear()
    local started = os.clock()
    local chunks = 0
    local voxelSize = 4
    local chunkSize = 64
    local counts = {
        math.ceil(769 / chunkSize),
        math.ceil(69 / chunkSize),
        math.ceil(769 / chunkSize),
    }
    for chunkX = 0, counts[1] - 1 do
        for chunkY = 0, counts[2] - 1 do
            for chunkZ = 0, counts[3] - 1 do
                local startX = -1536 + chunkX * chunkSize * voxelSize
                local startY = -16 + chunkY * chunkSize * voxelSize
                local startZ = -1536 + chunkZ * chunkSize * voxelSize
                local nx = math.min(chunkSize, (1536 - startX) / voxelSize + 1)
                local ny = math.min(chunkSize, (260 - startY) / voxelSize + 1)
                local nz = math.min(chunkSize, (1536 - startZ) / voxelSize + 1)
                local materials = table.create(nx)
                local occupancy = table.create(nx)
                for ix = 1, nx do
                    materials[ix] = table.create(ny)
                    occupancy[ix] = table.create(ny)
                    for iy = 1, ny do
                        materials[ix][iy] = table.create(nz)
                        occupancy[ix][iy] = table.create(nz)
                    end
                end
                for ix = 1, nx do
                    local x = startX + (ix - 1) * voxelSize
                    for iy = 1, ny do
                        local y = startY + (iy - 1) * voxelSize
                        for iz = 1, nz do
                            local z = startZ + (iz - 1) * voxelSize
                            local ground = sampleHeight(x, z)
                            local fill = math.clamp((ground - (y - 2)) / 4, 0, 1)
                            local material = Enum.Material.Grass
                            if sampleHole(x, z) then
                                fill = 0
                                material = Enum.Material.Air
                            end
                            if fill > 0 then
                                material = solidMaterial(x, z, ground)
                                local water = sampleWater(x, z)
                                if
                                    water ~= nil
                                    and water > ground
                                    and y >= ground
                                    and y <= water
                                then
                                    material = Enum.Material.Water
                                    fill = 1
                                end
                            end
                            materials[ix][iy][iz] = material
                            occupancy[ix][iy][iz] = fill
                        end
                    end
                end
                local region = Region3.new(
                    Vector3.new(startX, startY, startZ),
                    Vector3.new(
                        startX + nx * voxelSize,
                        startY + ny * voxelSize,
                        startZ + nz * voxelSize
                    )
                )
                terrain:WriteVoxels(region, voxelSize, materials, occupancy)
                chunks += 1
                if chunks % 25 == 0 then
                    print(
                        `MammonsGulch terrain: {chunks} chunks, {string.format(
                            "%.1f",
                            os.clock() - started
                        )}s`
                    )
                end
                task.wait()
            end
        end
    end
    local holes = carveHoles()
    return {
        chunks = chunks,
        holes = holes,
        seconds = os.clock() - started,
        minHeight = sampleHeight(-1536, -1536),
        maxHeight = sampleHeight(1536, 1536),
    }
end

return TerrainBuilder
