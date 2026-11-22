--!strict

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- The station presents an authored hunter. Player characters spawn at the expedition place.
Players.CharacterAutoLoads = false

-- Roblox copies StarterGui on character spawn. Mount this screen for a characterless lobby.
local template = StarterGui:WaitForChild("Lobby")
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
