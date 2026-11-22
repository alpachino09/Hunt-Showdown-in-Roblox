--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local server = ServerScriptService.SharedServer
local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Profiles = require(server.Profiles)
local Parties = require(server.Parties)
local Raid = require(server.Raid)
local Queue = require(server.routes.Queue)
local Remotes = require(server.Remotes)
local allow, drop = require(server.RateLimit).new(0.2)
local mutating: { [Player]: boolean } = {}

local function finish(player: Player, result: string)
    if not player.Parent then
        return
    end
    if player.Character then
        player.Character:Destroy()
    end
    player:SetAttribute("LobbyMessage", result)
    player:SetAttribute("RaidPhase", nil)
end

local function init(player: Player)
    Parties.join(player)
    Profiles.load(player)
end

Players.PlayerAdded:Connect(init)
Players.PlayerRemoving:Connect(function(player)
    task.spawn(Queue.cancel, player)
    Parties.leave(player)
    Profiles.drop(player)
    drop(player)
end)
for _, player in Players:GetPlayers() do
    task.spawn(init, player)
end

Remotes.lobby.OnServerEvent:Connect(function(player: Player, action: unknown, value: unknown)
    if
        not allow(player)
        or mutating[player]
        or player:GetAttribute("RaidPhase") ~= nil
        or not Profiles.get(player)
    then
        return
    end
    if player:GetAttribute("QueueId") then
        if action == "Cancel" and not Queue.cancel(player) then
            player:SetAttribute("LobbyMessage", "Перенос уже готовится.")
        end
        return
    end
    local errorText: string? = nil
    if action == "Hunter" then
        local hunter = Catalog.hunter(value)
        if not hunter then
            return
        end
        mutating[player] = true
        local ok, reason = Profiles.change(player, function(data)
            data.hunter = hunter.id
            return true
        end)
        mutating[player] = nil
        if ok then
            errorText = "Выбран охотник: " .. hunter.name
        else
            errorText = reason
        end
    elseif action == "Equip" or action == "Buy" then
        local weapon = Catalog.weapon(value)
        if not weapon then
            return
        end
        mutating[player] = true
        local ok, reason = Profiles.change(player, function(data)
            if action == "Buy" then
                if not data.owned[weapon.id] then
                    if data.credits < weapon.price then
                        return false
                    end
                    data.credits -= weapon.price
                    data.owned[weapon.id] = true
                end
            elseif not data.owned[weapon.id] then
                return false
            end
            data.weapon = weapon.id
            return true
        end)
        mutating[player] = nil
        if ok then
            errorText = "Экипировано: " .. weapon.name
        else
            errorText = reason
        end
    elseif action == "Ready" then
        Parties.toggle(player)
    elseif action == "JoinLocal" and RunService:IsStudio() then
        local joined = false
        for _, leader in Players:GetPlayers() do
            if
                leader ~= player
                and leader:GetAttribute("RaidPhase") == nil
                and Parties.group(player, leader)
            then
                joined = true
                break
            end
        end
        errorText = if joined
            then "Вы вступили в тестовый отряд."
            else "Нет подходящего тестового отряда."
    elseif action == "LeaveParty" then
        Parties.leave(player)
        Parties.join(player)
    elseif action == "Start" or action == "StartRush" then
        local roster = Parties.roster(player)
        if not roster then
            errorText =
                "Начать может лидер, когда весь отряд готов."
        elseif RunService:IsStudio() then
            local entries = {}
            for _, member in roster do
                if
                    mutating[member]
                    or member:GetAttribute("RaidPhase") ~= nil
                    or not Profiles.get(member)
                then
                    errorText = "Участник ещё не готов."
                    break
                end
                table.insert(entries, { player = member, team = tostring(player.UserId) })
            end
            if not errorText and not Raid.start(entries, finish, action == "StartRush") then
                errorText = "Экспедиция занята или ещё не готова."
            end
        elseif action == "StartRush" then
            errorText = "Быстрый контракт пока доступен в Studio."
        else
            local queueReady = true
            for _, member in roster do
                if mutating[member] or not Profiles.get(member) then
                    queueReady = false
                    break
                end
            end
            if not queueReady or not Queue.join(roster) then
                errorText =
                    "Поиск недоступен. Проверьте подключение игрового места."
            end
        end
    else
        return
    end
    if errorText and player.Parent then
        player:SetAttribute("LobbyMessage", errorText)
    end
end)
