--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local spawn = Workspace:WaitForChild("Maps")
    :WaitForChild("MammonsGulch")
    :WaitForChild("SpawnPoints")
    :WaitForChild("DevelopmentSpawn") :: SpawnLocation

local function assignSpawn(player: Player)
    player.RespawnLocation = spawn
end

Players.PlayerAdded:Connect(assignSpawn)
for _, player in Players:GetPlayers() do
    assignSpawn(player)
end
