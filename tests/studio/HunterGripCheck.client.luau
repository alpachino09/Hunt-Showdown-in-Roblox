--!strict
-- Run on the local HunterLab client with a prop equipped.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

assert(
    game.PlaceId == 0 and Workspace:FindFirstChild("CharacterQualityLab"),
    "Use the local HunterLab"
)
local player = Players.LocalPlayer
local character = assert(player.Character, "The Veteran has not spawned")
local prop = assert(
    character:FindFirstChild("Rifle") or character:FindFirstChild("Pistol"),
    "Press B to equip a prop"
) :: Model
local mount = assert(prop.PrimaryPart, "Expected a prop mount")
local trigger = character:WaitForChild("RightHand"):WaitForChild("TriggerHand") :: Attachment
local support = mount:FindFirstChild("Support") :: Attachment?
local left = character:WaitForChild("LeftHand"):WaitForChild("SupportHand") :: Attachment
local root = character:WaitForChild("HumanoidRootPart") :: BasePart
local torso = character:WaitForChild("UpperTorso") :: BasePart
local maxTrigger, maxSupport, elapsed, forwardDot = 0, 0, 0, 0
local samples = 0
local minimumClearance = math.huge

while elapsed < 0.4 do
    elapsed += RunService.RenderStepped:Wait()
    samples += 1
    maxTrigger = math.max(maxTrigger, (trigger.WorldPosition - mount.Position).Magnitude)
    if support then
        maxSupport = math.max(maxSupport, (support.WorldPosition - left.WorldPosition).Magnitude)
    end
    forwardDot += mount.CFrame.LookVector:Dot(root.CFrame.LookVector)
    for _, obj in prop:GetChildren() do
        if obj:IsA("BasePart") and obj ~= mount then
            local localPoint = torso.CFrame:PointToObjectSpace(obj.Position)
            local half = torso.Size * 0.5
            local nearest = Vector3.new(
                math.clamp(localPoint.X, -half.X, half.X),
                math.clamp(localPoint.Y, -half.Y, half.Y),
                math.clamp(localPoint.Z, -half.Z, half.Z)
            )
            minimumClearance = math.min(minimumClearance, (nearest - localPoint).Magnitude)
        end
    end
end

return {
    pose = character:GetAttribute("WeaponPose"),
    motion = character:GetAttribute("MotionClip"),
    samples = samples,
    rightGripError = maxTrigger,
    leftGripError = if support then maxSupport else nil,
    meanHeadingDot = forwardDot / samples,
    minPropCenterToTorsoBox = minimumClearance,
}
