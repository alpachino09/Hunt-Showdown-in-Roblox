local studio = game:GetService("StudioTestService")
if
    not game:GetService("RunService"):IsStudio()
    or studio:GetTestArgs() ~= "GreyOutpostPartyCheck"
then
    return
end

local player = game:GetService("Players").LocalPlayer
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("GreyOutpostRemotes")
local lobby = remotes:WaitForChild("Lobby")
local combat = remotes:WaitForChild("Combat")
local actions = { join = "JoinLocal", ready = "Ready", start = "Start" }
local function step()
    local stage = player:GetAttribute("FixtureStage")
    task.wait(0.35)
    if stage == "fire" then
        combat:FireServer("Fire", -Vector3.zAxis)
    elseif stage == "rescue" then
        combat:FireServer("Revive")
    elseif actions[stage] then
        lobby:FireServer(actions[stage])
    end
end
player:GetAttributeChangedSignal("FixtureStage"):Connect(step)
step()
