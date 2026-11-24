--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local World = require(ReplicatedStorage.Shared:WaitForChild("mammons-gulch"):WaitForChild("World"))
local player = Players.LocalPlayer
local character = player.Character
local map = Workspace:WaitForChild("Maps"):WaitForChild("MammonsGulch")
local targets = {
    {
        name = "Road",
        model = "Roads.western_spine",
        partName = "Segment_07",
        source = { 900, 1020, 60 },
        expectHit = true,
    },
    {
        name = "Railbed",
        model = "Railways.main_north_south_rail",
        partName = "Segment_01",
        source = { 940, 512, 60 },
        expectHit = true,
    },
    {
        name = "BridgeDeck",
        model = "Bridges.kingfisher_trestle",
        partName = "Deck_01",
        source = { 899.689861, 681.973697, 70 },
        expectHit = true,
    },
    {
        name = "UndergroundFloor",
        model = "Underground.VisArea-22",
        partName = "Floor",
        source = { 1069.5, 925.6, 20 },
        expectHit = true,
    },
}
local results = {}
local allPassed = true
for _, target in targets do
    local position = World.sourceToWorld(table.unpack(target.source))
    if character then
        character:PivotTo(CFrame.new(position))
    end
    local model = map
    for segment in string.gmatch(target.model, "[^.]+") do
        model = model:WaitForChild(segment)
    end
    local part = model:WaitForChild(target.partName, 10)
    if not part then
        allPassed = false
        results[#results + 1] = { name = target.name, passed = false, instance = "missing" }
        continue
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { part }
    local hit
    for _ = 1, 40 do
        hit = Workspace:Raycast(part.Position + Vector3.yAxis * 10, -Vector3.yAxis * 40, params)
        if hit or not character then
            break
        end
        task.wait(0.1)
    end
    local passed = (hit ~= nil) == target.expectHit
    allPassed = allPassed and passed
    results[#results + 1] = {
        name = target.name,
        passed = passed,
        instance = if hit then hit.Instance:GetFullName() else "none",
    }
end

if character then
    character:PivotTo(CFrame.new(-108, 175, 54))
end
local holeParams = RaycastParams.new()
holeParams.FilterType = Enum.RaycastFilterType.Include
holeParams.FilterDescendantsInstances = { Workspace.Terrain }
local holeHit = Workspace:Raycast(Vector3.new(-108, 175, 54), -Vector3.yAxis * 20, holeParams)
local holePassed = holeHit == nil
allPassed = allPassed and holePassed
results[#results + 1] = {
    name = "MineOpening",
    passed = holePassed,
    instance = if holeHit then holeHit.Instance:GetFullName() else "air",
}
print(HttpService:JSONEncode({ passed = allPassed, checks = results }))
return allPassed
