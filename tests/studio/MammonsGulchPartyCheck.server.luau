local studio = game:GetService("StudioTestService")
if
    not game:GetService("RunService"):IsStudio()
    or studio:GetTestArgs() ~= "MammonsGulchPartyCheck"
then
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function waitFor(description, check)
    local deadline = os.clock() + 35
    repeat
        if check() then
            return
        end
        task.wait(0.1)
    until os.clock() > deadline
    error(description)
end

local ok, result = pcall(function()
    waitFor("two clients did not connect", function()
        return #Players:GetPlayers() == 2
    end)
    local first, second = table.unpack(Players:GetPlayers())
    waitFor("characters did not spawn", function()
        return first.Character and second.Character
    end)
    local remote = ReplicatedStorage:WaitForChild("MammonsGulchDebugTeleport")
    remote:FireAllClients("com_i")
    task.wait(0.5)
    assert(first.Character and second.Character, "characters must exist")
    local map = workspace.Maps.MammonsGulch
    local tunnel = map.Underground["Tunnel_VisArea-16_VisArea-17"]
    local direction = tunnel.CFrame.RightVector
    local half = tunnel.Size.X / 2 - 3
    local center = tunnel.Position
    local startFirst = center - direction * half + Vector3.yAxis * 4
    local startSecond = center + direction * half + Vector3.yAxis * 4
    first.Character:PivotTo(CFrame.new(startFirst))
    second.Character:PivotTo(CFrame.new(startSecond))
    task.wait(0.5)
    local firstHumanoid = first.Character:FindFirstChildOfClass("Humanoid")
    local secondHumanoid = second.Character:FindFirstChildOfClass("Humanoid")
    firstHumanoid.WalkSpeed = 19
    secondHumanoid.WalkSpeed = 19
    firstHumanoid:MoveTo(startFirst + direction * 20)
    secondHumanoid:MoveTo(startSecond - direction * 20)
    task.wait(2)
    firstHumanoid:Move(Vector3.zero)
    secondHumanoid:Move(Vector3.zero)
    local firstDistance = (first.Character:GetPivot().Position - startFirst).Magnitude
    local secondDistance = (second.Character:GetPivot().Position - startSecond).Magnitude
    assert(
        firstDistance > 3 and secondDistance > 3,
        string.format(
            "both clients must advance in the tunnel (%.2f, %.2f)",
            firstDistance,
            secondDistance
        )
    )
    return string.format(
        "PASS: two clients advanced in one tunnel (%.2f, %.2f studs)",
        firstDistance,
        secondDistance
    )
end)
studio:EndTest(if ok then result else tostring(result))
