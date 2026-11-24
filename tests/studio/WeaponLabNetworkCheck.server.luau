local RunService = game:GetService("RunService")
local Studio = game:GetService("StudioTestService")
if not RunService:IsStudio() or Studio:GetTestArgs() ~= "GreyOutpostWeaponLabNetwork" then
    return
end

local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local Storage = game:GetService("ReplicatedStorage")
local ack = Instance.new("RemoteEvent")
ack.Name = "WeaponLabNetworkAck"
ack.Parent = Storage

local reports = {}
ack.OnServerEvent:Connect(function(player, case, value)
    if case ~= "ready" and case ~= "finished" then
        return
    end
    reports[player] = reports[player] or {}
    reports[player][case] = value
end)

local function waitFor(description, predicate, seconds)
    local deadline = os.clock() + (seconds or 18)
    repeat
        if predicate() then
            return
        end
        task.wait(0.035)
    until os.clock() >= deadline
    error(description .. " (players: " .. #Players:GetPlayers() .. ")")
end

local function state(player)
    local character = player.Character
    local payload = character and character:GetAttribute("LanternState")
    return payload and Http:JSONDecode(payload)
end

local ok, result = pcall(function()
    waitFor("Roster unavailable", function()
        return #Players:GetPlayers() == 2
    end, 60)
    local shooter, observer = table.unpack(Players:GetPlayers())
    waitFor("Initial ammo not replicated by server", function()
        local a, b = state(shooter), state(observer)
        return a and b and a.loaded == 1 and a.reserve == 8 and b.loaded == 1 and b.reserve == 8
    end)
    workspace:SetAttribute("WeaponLabNetworkShooter", shooter.UserId)
    waitFor("Observer not ready", function()
        return reports[observer] and reports[observer].ready == true
    end)
    local serverStages = {}
    shooter.Character:GetAttributeChangedSignal("LanternState"):Connect(function()
        local current = state(shooter)
        if current and current.reload then
            serverStages[current.reload.stage] = true
        end
    end)
    shooter:SetAttribute("WeaponLabNetworkStart", true)
    waitFor("First player did not spend a round", function()
        return state(shooter).chamber == "Spent" and state(shooter).loaded == 0
    end)
    waitFor("First player's canceled reload did not close with a spent chamber", function()
        local a = state(shooter)
        return a.reload and a.reload.stage == "Close" and a.chamber == "Spent" and a.reserve == 8
    end)
    waitFor("First player's full cycle did not debit exactly one round", function()
        local a = state(shooter)
        return a and not a.reload and a.loaded == 1 and a.reserve == 7
    end)
    waitFor("Client reports did not finish", function()
        return reports[shooter]
            and reports[shooter].finished
            and reports[observer]
            and reports[observer].finished
    end)
    local shooterReport = reports[shooter].finished
    local observerReport = reports[observer].finished
    assert(shooterReport == true, tostring(shooterReport))
    assert(type(observerReport) == "table", tostring(observerReport))
    assert(
        observerReport.open and observerReport.eject and observerReport.insert,
        "Observer missed a reload stage"
    )
    assert(
        observerReport.canceled and observerReport.closed,
        "Observer missed cancel or completion"
    )
    assert(
        observerReport.pitch > 0.60 and observerReport.roundVisible,
        "Observer did not animate barrel and round"
    )
    assert(observerReport.roundTravel > 0.12, "Observer round did not leave the chamber transform")
    assert(state(observer).loaded == 1 and state(observer).reserve == 8, "Observer ammo changed")
    return ("PASS: shooter 1/7, observer 1/8; canceled and completed; observer pitch %.3f rad, round separation %.3f studs"):format(
        observerReport.pitch,
        observerReport.roundTravel
    )
end)

local message = if ok then result else "FAIL: " .. tostring(result)
print(message)
Studio:EndTest(message)
