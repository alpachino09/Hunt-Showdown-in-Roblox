--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Locomotion = require(ReplicatedStorage.Shared.characters.Locomotion)
local motionData = ReplicatedStorage:WaitForChild("VeteranMotion") :: StringValue
local library = Locomotion.decode(motionData.Value)
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "HunterLabControls"
gui.ResetOnSpawn = false
local prompt = Instance.new("TextLabel")
prompt.Size = UDim2.new(1, -48, 0, 50)
prompt.Position = UDim2.fromOffset(24, 12)
prompt.BackgroundColor3 = Color3.fromRGB(25, 24, 21)
prompt.BackgroundTransparency = 0.13
prompt.TextColor3 = Color3.fromRGB(232, 216, 178)
prompt.Font = Enum.Font.GothamMedium
prompt.TextSize = 16
prompt.TextWrapped = true
prompt.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

local crouched = false
local jog = false
local shift = false
local mode: Locomotion.Mode = "Walk"
local running: RBXScriptConnection? = nil

local function preferred(): Locomotion.Mode
    if crouched then
        return "Crouch"
    elseif shift then
        return "Sprint"
    elseif jog then
        return "Jog"
    else
        return "Walk"
    end
end

local function action(name: string, input: Enum.UserInputState)
    if name == "HunterLabSprint" then
        shift = input == Enum.UserInputState.Begin
    elseif input == Enum.UserInputState.Begin then
        if name == "HunterLabCrouch" then
            crouched = not crouched
        elseif name == "HunterLabJog" then
            jog = not jog
        elseif name == "HunterLabCamera" then
            player.CameraMode = if player.CameraMode == Enum.CameraMode.Classic
                then Enum.CameraMode.LockFirstPerson
                else Enum.CameraMode.Classic
        end
    end
    mode = preferred()
    return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("HunterLabSprint", action, false, Enum.KeyCode.LeftShift)
ContextActionService:BindAction("HunterLabCrouch", action, false, Enum.KeyCode.C)
ContextActionService:BindAction("HunterLabJog", action, false, Enum.KeyCode.J)
ContextActionService:BindAction("HunterLabCamera", action, false, Enum.KeyCode.V)

local function mount(character: Model)
    if running then
        running:Disconnect()
    end
    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    local root = character:WaitForChild("HumanoidRootPart") :: BasePart
    crouched, jog, shift, mode = false, false, false, "Walk"
    local animate = Locomotion.bind(character, humanoid, root, library)
    local current: string? = nil
    running = RunService.PreSimulation:Connect(function(delta)
        local speed = Locomotion.speed[mode]
        if humanoid.WalkSpeed ~= speed then
            humanoid.WalkSpeed = speed
        end
        animate(delta, mode)
        local clip = character:GetAttribute("MotionClip") :: string?
        if clip ~= current then
            current = clip
            prompt.Text = ("%s  ·  WASD — движение  ·  J — бег  ·  Shift — спринт  ·  C — присесть  ·  Space — прыжок  ·  V — камера"):format(
                clip or "Idle"
            )
        end
    end)
end

player.CharacterAdded:Connect(mount)
player.CharacterRemoving:Connect(function()
    if running then
        running:Disconnect()
        running = nil
    end
end)
if player.Character then
    mount(player.Character)
end
