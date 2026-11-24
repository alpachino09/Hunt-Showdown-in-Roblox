--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

assert(RunService:IsStudio(), "Run this check in a local Studio session")
local player = Players.LocalPlayer
local input = ReplicatedStorage:WaitForChild("WeaponLabInput") :: RemoteEvent
local selectHunter = ReplicatedStorage:WaitForChild("HunterLabSelect") :: RemoteEvent

type State = { loaded: number, reserve: number, chamber: string, reload: { stage: string }? }

local function snapshot(): State?
    local character = player.Character
    local encoded = character and character:GetAttribute("LanternState")
    return if type(encoded) == "string" then HttpService:JSONDecode(encoded) :: State else nil
end

local function waitFor(check: () -> boolean, label: string)
    local expires = os.clock() + 6
    while os.clock() < expires do
        if check() then
            return
        end
        task.wait()
    end
    error("WeaponLab timeout: " .. label)
end

local function waitForAmmo(loaded: number, reserve: number)
    waitFor(function()
        local state = snapshot()
        return state ~= nil
            and state.reload == nil
            and state.loaded == loaded
            and state.reserve == reserve
    end, string.format("ready state %d / %d", loaded, reserve))
end

local function stage(name: string, chamber: string)
    waitFor(function()
        local state = snapshot()
        return state ~= nil
            and state.reload ~= nil
            and state.reload.stage == name
            and state.chamber == chamber
    end, name .. " = " .. chamber)
end

waitForAmmo(1, 8)
local worldFolder =
    assert(workspace:WaitForChild("WeaponLabWorldmodels", 5), "Missing lab worldmodels")
local marks = {}
for _, id in { "reed", "vale", "shaw", "warden" } do
    if not player.Character or player.Character:GetAttribute("HunterId") ~= id then
        selectHunter:FireServer(id)
    end
    waitFor(function()
        local character = player.Character
        return character ~= nil
            and character:GetAttribute("HunterId") == id
            and character:GetAttribute("LanternState") ~= nil
    end, "hunter " .. id)
    task.wait(0.62)
    local prop =
        assert(worldFolder:FindFirstChild(player.Name .. "_Lantern"), "Missing visible prop")
    local right = prop:GetAttribute("RightGripError")
    local left = prop:GetAttribute("LeftGripError")
    assert(type(right) == "number" and type(left) == "number", "Expected measured contact")
    marks[id] = { right = right, left = left }
    assert(
        math.max(right, left) < 0.03,
        string.format("%s grip error: %.4f, %.4f studs", id, right, left)
    )
    assert(#worldFolder:GetChildren() == 1, "Character change must remove the previous model")
end

input:FireServer("Fire")
waitForAmmo(0, 8)
assert((assert(snapshot(), "Missing state")).chamber == "Spent", "Shot leaves a spent case")
task.wait(0.08)
input:FireServer("Reload")
stage("Open", "Spent")
task.wait(0.08)
input:FireServer("Cancel")
stage("Close", "Spent")
waitForAmmo(0, 8)

input:FireServer("Reload")
for _, pair in
    { { "Open", "Spent" }, { "Eject", "Spent" }, { "Insert", "Empty" }, { "Close", "Live" } }
do
    stage(pair[1], pair[2])
end
waitForAmmo(1, 7)
local camera = assert(workspace.CurrentCamera, "Missing active camera")
local view = assert(camera:WaitForChild("HunterViewmodel", 5), "Expected the first-person model")
return {
    grip = marks,
    camera = player.CameraMode.Name,
    renderedParts = #view:GetChildren(),
    loaded = 1,
    reserve = 7,
}
