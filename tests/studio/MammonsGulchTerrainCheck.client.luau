--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character

local World = require(ReplicatedStorage.Shared:WaitForChild("mammons-gulch"):WaitForChild("World"))
local controls = {
    {
        name = "Blackthorn",
        source = { 678.52, 1427.21, 43.493625 },
        expected = (43.493625 - 32.79) * 3,
    },
    {
        name = "MonterosMalt",
        source = { 1041.86, 1253.01, 37.0179 },
        expected = (37.0179 - 32.79) * 3,
    },
    {
        name = "LaPlataMine",
        source = { 969.216, 933.0688, 57.53872 },
        expected = (57.53872 - 32.79) * 3,
    },
    {
        name = "RiverWater",
        source = { 824, 1490, 34.42 },
        expected = (34.42 - 32.79) * 3,
        kind = "water",
    },
}
local results = {}
local allPassed = true
for _, control in controls do
    local position = World.sourceToWorld(table.unpack(control.source))
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { Workspace.Terrain }
    if character then
        character:PivotTo(CFrame.new(position + Vector3.yAxis * 5))
    end
    local hit
    for _ = 1, 50 do
        hit = Workspace:Raycast(position + Vector3.yAxis * 300, -Vector3.yAxis * 600, params)
        if hit or not character then
            break
        end
        task.wait(0.1)
    end
    local actual = if hit then hit.Position.Y else nil
    local passed = actual ~= nil
        and math.abs(actual - control.expected) <= 5
        and (control.kind ~= "water" or (hit and hit.Material == Enum.Material.Water))
    allPassed = allPassed and passed
    results[#results + 1] = {
        name = control.name,
        expected = control.expected,
        actual = actual,
        material = if hit and hit.Material == Enum.Material.Water then "Water" else "Terrain",
        passed = passed,
    }
end
print(HttpService:JSONEncode({ passed = allPassed, controls = results }))
return allPassed
