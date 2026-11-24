local studio = game:GetService("StudioTestService")
if
    not game:GetService("RunService"):IsStudio()
    or studio:GetTestArgs() ~= "MammonsGulchPartyCheck"
then
    return
end

local player = game:GetService("Players").LocalPlayer
local remote = game:GetService("ReplicatedStorage"):WaitForChild("MammonsGulchDebugTeleport")
remote.OnClientEvent:Connect(function(compoundId)
    if compoundId == "com_i" then
        player:SetAttribute("DebugTeleportReceived", true)
    end
end)
