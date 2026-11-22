--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Raid = require(script.Parent.Parent.Raid)
local Profiles = require(script.Parent.Parent.Profiles)
local Queue = require(script.Parent.Queue)
local Policy = require(script.Parent.MatchPolicy)
local Remotes = require(script.Parent.Parent.Remotes)
local MatchHost = {}

function MatchHost.start(fast: boolean?)
    Players.CharacterAutoLoads = false
    local roster: { { player: Player, team: string } } = {}
    local started = false
    local scheduled = false
    local expected = Policy.playerLimit
    local returning: { [Player]: boolean } = {}
    local studio = RunService:IsStudio()
    local function returnToLobby(player: Player)
        if studio or not player.Parent or returning[player] or Policy.lobbyPlaceId <= 0 then
            return
        end
        returning[player] = true
        local ok = pcall(function()
            TeleportService:TeleportAsync(Policy.lobbyPlaceId, { player })
        end)
        if not ok then
            returning[player] = nil
            player:SetAttribute(
                "RaidMessage",
                "Не удалось вернуться. Нажмите Enter, чтобы повторить."
            )
        end
    end

    TeleportService.TeleportInitFailed:Connect(function(player, _, _, place)
        if place == Policy.lobbyPlaceId and returning[player] then
            returning[player] = nil
            player:SetAttribute(
                "RaidMessage",
                "Не удалось вернуться. Нажмите Enter, чтобы повторить."
            )
        end
    end)
    Remotes.combat.OnServerEvent:Connect(function(player, action)
        if action == "Return" and player:GetAttribute("RaidPhase") == "Debrief" then
            returnToLobby(player)
        end
    end)

    local function launch()
        if started then
            return
        end
        started = true
        if #roster > 0 then
            Raid.start(roster, function(player, result)
                if player.Parent then
                    player:SetAttribute("RaidMessage", result)
                    task.delay(3, returnToLobby, player)
                end
            end, fast)
        end
    end

    local function playerAdded(player: Player)
        player:SetAttribute("RaidPhase", "Deploying")
        player:SetAttribute(
            "RaidMessage",
            "Ожидаем участников экспедиции…"
        )
        local team: string?
        local count: number?
        if studio then
            team = tostring(player.UserId)
        else
            team, count = Queue.admission(player)
        end
        if not team or started then
            player:Kick(
                "Сервер уже начал экспедицию или не получил вашу заявку."
            )
            return
        end
        if count then
            expected = math.min(count, Policy.playerLimit)
        end
        Profiles.load(player)
        if not player.Parent or started then
            return
        end
        if not Profiles.get(player) then
            player:Kick("Не удалось загрузить профиль.")
            return
        end
        table.insert(roster, { player = player, team = team })
        if not scheduled then
            scheduled = true
            task.delay(if studio then 3 else 28, launch)
        end
        if #roster >= expected then
            launch()
        end
    end
    Players.PlayerRemoving:Connect(function(player)
        Profiles.drop(player)
        returning[player] = nil
        if not started then
            for index = #roster, 1, -1 do
                if roster[index].player == player then
                    table.remove(roster, index)
                end
            end
        end
    end)
    Players.PlayerAdded:Connect(playerAdded)
    for _, player in Players:GetPlayers() do
        task.spawn(playerAdded, player)
    end
end

return MatchHost
