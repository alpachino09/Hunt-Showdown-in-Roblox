--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local HunterDefinitions = require(ReplicatedStorage.Shared.characters.HunterDefinitions)

Players.CharacterAutoLoads = false

local roster = ServerStorage:WaitForChild("HunterRoster")
local marker = Workspace:WaitForChild("HunterLab"):WaitForChild("Spawn") :: BasePart
local selectHunter = ReplicatedStorage:WaitForChild("HunterLabSelect") :: RemoteEvent
local lastSelection: { [Player]: number } = {}

local function spawn(player: Player, id: string)
    local definition = HunterDefinitions.byId[id]
    local template = if definition then roster:FindFirstChild(definition.template) else nil
    if player.Parent ~= Players or not template or not template:IsA("Model") then
        return
    end
    local previous = player.Character
    local character = template:Clone()
    character.Name = player.Name
    character:SetAttribute("HunterId", id)
    local offset = #Players:GetPlayers() > 1 and (player.UserId % 6) * 3 or 0
    local previousRoot = if previous then previous.PrimaryPart else nil
    character:PivotTo(
        if previousRoot then previousRoot.CFrame else marker.CFrame + Vector3.new(offset, 0, 0)
    )
    if previous then
        player.Character = nil
        previous:Destroy()
    end
    character.Parent = Workspace
    player.Character = character
end

local function initialSpawn(player: Player)
    if not player.Character then
        spawn(player, "reed")
    end
end

Players.PlayerAdded:Connect(initialSpawn)
Players.PlayerRemoving:Connect(function(player)
    lastSelection[player] = nil
end)
selectHunter.OnServerEvent:Connect(function(player, id: unknown)
    local now = os.clock()
    local current = player.Character
    if
        typeof(id) ~= "string"
        or not HunterDefinitions.byId[id]
        or not current
        or current:GetAttribute("HunterId") == id
        or now - (lastSelection[player] or -1) < 0.5
    then
        return
    end
    lastSelection[player] = now
    spawn(player, id)
end)
for _, player in Players:GetPlayers() do
    task.defer(initialSpawn, player)
end
