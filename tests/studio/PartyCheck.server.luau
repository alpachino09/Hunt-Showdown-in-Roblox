local studio = game:GetService("StudioTestService")
if
    not game:GetService("RunService"):IsStudio()
    or studio:GetTestArgs() ~= "GreyOutpostPartyCheck"
then
    return
end

local Players = game:GetService("Players")
local function waitFor(description, check)
    local deadline = os.clock() + 40
    repeat
        if check() then
            return
        end
        task.wait(0.1)
    until os.clock() > deadline
    error(description .. " (connected clients: " .. #Players:GetPlayers() .. ")")
end

local ok, result = pcall(function()
    waitFor("clients did not connect", function()
        return #Players:GetPlayers() == 2
    end)
    local leader, member = table.unpack(Players:GetPlayers())
    waitFor("profiles unavailable", function()
        return leader:GetAttribute("ProfileReady") and member:GetAttribute("ProfileReady")
    end)
    member:SetAttribute("FixtureStage", "join")
    waitFor("member did not join", function()
        local summary = member:GetAttribute("PartySummary")
        return summary and string.find(summary, leader.DisplayName, 1, true) ~= nil
    end)
    leader:SetAttribute("FixtureStage", "ready")
    member:SetAttribute("FixtureStage", "ready")
    waitFor("party never became ready", function()
        return leader:GetAttribute("PartyReady") and member:GetAttribute("PartyReady")
    end)
    leader:SetAttribute("FixtureStage", "start")
    waitFor("party did not enter raid", function()
        return leader:GetAttribute("RaidPhase") == "Alive"
            and member:GetAttribute("RaidPhase") == "Alive"
    end)
    assert(
        (leader.Character:GetPivot().Position - member.Character:GetPivot().Position).Magnitude < 12,
        "party members did not spawn together"
    )
    assert(
        leader:GetAttribute("RaidAmmo") == 6 and member:GetAttribute("RaidAmmo") == 6,
        "both clients should begin with six rounds"
    )

    leader:SetAttribute("FixtureStage", "fire")
    waitFor("leader shot did not consume ammunition", function()
        return leader:GetAttribute("RaidAmmo") == 5
    end)
    assert(member:GetAttribute("RaidAmmo") == 6, "ammunition leaked across players")
    local world = workspace.ActiveRaid
    local warden = world:FindFirstChild("Смотритель")
    local humanoid = leader.Character:FindFirstChildOfClass("Humanoid")
    humanoid.Health = 6
    local attack = warden.Position + Vector3.new(0, 0.8, 2.5)
    leader.Character:PivotTo(CFrame.new(attack))
    waitFor("elite did not down leader", function()
        return leader:GetAttribute("RaidPhase") == "Downed"
    end)
    local marker = world:FindFirstChild("Товарищ")
    local rescue = marker.Position + Vector3.new(0, -2.7, 3)
    member.Character:PivotTo(CFrame.lookAt(rescue, marker.Position))
    member:SetAttribute("FixtureStage", "rescue")
    waitFor("teammate did not revive leader", function()
        return leader:GetAttribute("RaidPhase") == "Alive"
    end)
    assert(humanoid.Health > 1, "revived hunter did not receive health")
    return "PASS: two clients grouped, deployed, used independent ammunition and revived a teammate"
end)
studio:EndTest(if ok then result else tostring(result))
