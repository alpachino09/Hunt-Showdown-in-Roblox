--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugConfig = require(ReplicatedStorage.Shared["mammons-gulch"].DebugConfig)
local Definitions = require(ReplicatedStorage.Shared["mammons-gulch"].CompoundDefinitions)

local DebugService = {}

function DebugService.start(): boolean
    if not DebugConfig.enabled then
        return false
    end
    local remote = ReplicatedStorage:FindFirstChild(DebugConfig.remoteName)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = DebugConfig.remoteName
        remote.Parent = ReplicatedStorage
    end
    assert(remote:IsA("RemoteEvent"), "Debug remote must be a RemoteEvent")
    local cooldowns: { [Player]: number } = {}
    remote.OnServerEvent:Connect(function(player: Player, compoundId: unknown)
        if not DebugConfig.enabled or type(compoundId) ~= "string" then
            return
        end
        local definition = Definitions.byId[compoundId]
        if not definition then
            return
        end
        local now = os.clock()
        if now - (cooldowns[player] or -math.huge) < 0.5 then
            return
        end
        cooldowns[player] = now
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not character or not humanoid or not root or humanoid.Health <= 0 then
            return
        end
        local position = Vector3.new(table.unpack(definition.worldPosition)) + Vector3.yAxis * 6
        character:PivotTo(CFrame.lookAt(position, position - Vector3.zAxis))
        player:SetAttribute("DebugCompoundId", compoundId)
    end)
    Players.PlayerRemoving:Connect(function(player)
        cooldowns[player] = nil
    end)
    return true
end

return DebugService
