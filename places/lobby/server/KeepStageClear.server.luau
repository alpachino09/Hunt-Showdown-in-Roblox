--!strict

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- The station presents an authored hunter. Player characters spawn at the expedition place.
Players.CharacterAutoLoads = false

-- Mount one persistent screen for the characterless lobby and local expedition returns.
local template = ServerStorage:WaitForChild("Lobby")
local function mountMenu(player: Player)
    local playerGui = player:WaitForChild("PlayerGui")
    if player.Parent == Players and not playerGui:FindFirstChild(template.Name) then
        template:Clone().Parent = playerGui
    end
end

Players.PlayerAdded:Connect(mountMenu)
for _, player in Players:GetPlayers() do
    task.defer(mountMenu, player)
end
