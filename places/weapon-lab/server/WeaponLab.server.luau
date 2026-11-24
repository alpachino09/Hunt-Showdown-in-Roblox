--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Definitions = require(ReplicatedStorage.Shared.weapons.WeaponDefinitions)
local Server = game:GetService("ServerScriptService")
local WeaponState = require(Server.WeaponStateService)
local allow, drop = require(Server.RateLimit).new(0.04)
local input = ReplicatedStorage.WeaponLabInput

type CharacterState = {
    character: Model,
    weapon: WeaponState.State,
    aiming: boolean,
    desiredAim: boolean,
    nextAimAt: number,
    shotAt: number?,
}

local states: { [Player]: CharacterState } = {}

local function publish(state: CharacterState)
    local weapon = state.weapon
    state.character:SetAttribute(
        "LanternState",
        HttpService:JSONEncode({
            loaded = weapon.loaded,
            reserve = weapon.reserve,
            chamber = weapon.chamber,
            reload = weapon.reload,
            aiming = state.aiming,
            shotAt = state.shotAt,
        })
    )
end

local function bind(player: Player, character: Model)
    local state: CharacterState = {
        character = character,
        weapon = WeaponState.new(Definitions.lantern),
        aiming = false,
        desiredAim = false,
        nextAimAt = 0,
        shotAt = nil,
    }
    states[player] = state
    publish(state)
end

local function connect(player: Player)
    player.CharacterAdded:Connect(function(character)
        bind(player, character)
    end)
    player.CharacterRemoving:Connect(function(character)
        local state = states[player]
        if state and state.character == character then
            states[player] = nil
        end
    end)
    if player.Character then
        bind(player, player.Character)
    end
end

Players.PlayerAdded:Connect(connect)
Players.PlayerRemoving:Connect(function(player)
    states[player] = nil
    drop(player)
end)
for _, player in Players:GetPlayers() do
    connect(player)
end

RunService.Heartbeat:Connect(function()
    local now = workspace:GetServerTimeNow()
    for player, state in states do
        if player.Character ~= state.character or not state.character.Parent then
            continue
        end
        local reload = state.weapon.reload
        local human = state.character:FindFirstChildOfClass("Humanoid")
        if not human or human.Health <= 0 then
            if reload or state.aiming then
                WeaponState.abort(state.weapon)
                state.aiming = false
                publish(state)
            end
            continue
        end
        local changed = false
        if state.aiming ~= state.desiredAim and now >= state.nextAimAt then
            state.aiming = state.desiredAim
            state.nextAimAt = now + 0.08
            changed = true
        end
        if reload and WeaponState.advance(state.weapon, reload.revision, now) then
            changed = true
        end
        if changed then
            publish(state)
        end
    end
end)

input.OnServerEvent:Connect(function(player, action: unknown, value: unknown)
    local state = states[player]
    if not state or state.character ~= player.Character or not state.character.Parent then
        return
    end
    local human = state.character:FindFirstChildOfClass("Humanoid")
    if not human or human.Health <= 0 then
        return
    end
    if action == "Aim" and type(value) == "boolean" then
        state.desiredAim = value
        return
    end
    if (action ~= "Fire" and action ~= "Reload" and action ~= "Cancel") or not allow(player) then
        return
    end
    local now = workspace:GetServerTimeNow()
    if action == "Fire" then
        if not WeaponState.fire(state.weapon, now) then
            return
        end
        state.shotAt = now
    elseif action == "Reload" then
        if not WeaponState.beginReload(state.weapon, now) then
            return
        end
    elseif not WeaponState.cancel(state.weapon, now) then
        return
    end
    publish(state)
end)
