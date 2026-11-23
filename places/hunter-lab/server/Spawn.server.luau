--!strict

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

Players.CharacterAutoLoads = false

local template = ServerStorage:WaitForChild("Veteran") :: Model
local marker = Workspace:WaitForChild("HunterLab"):WaitForChild("Spawn") :: BasePart

local function spawnVeteran(player: Player)
    if player.Parent ~= Players or player.Character then
        return
    end
    local character = template:Clone()
    character.Name = player.Name
    local offset = #Players:GetPlayers() > 1 and (player.UserId % 6) * 3 or 0
    character:PivotTo(marker.CFrame + Vector3.new(offset, 0, 0))
    character.Parent = Workspace
    player.Character = character
end

Players.PlayerAdded:Connect(spawnVeteran)
for _, player in Players:GetPlayers() do
    task.defer(spawnVeteran, player)
end
