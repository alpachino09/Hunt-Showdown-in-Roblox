--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ClothPose = require(ReplicatedStorage.Shared.characters.ClothPose)
local Locomotion = require(ReplicatedStorage.Shared.characters.Locomotion)
local Viewmodel = require(ReplicatedStorage.Shared.characters.Viewmodel)
local WeaponPose = require(ReplicatedStorage.Shared.characters.WeaponPose)
local motionData = ReplicatedStorage:WaitForChild("VeteranMotion") :: Folder
local props = ReplicatedStorage:WaitForChild("HunterProps") :: Folder
local library = Locomotion.decode(motionData)
local player = Players.LocalPlayer
player.CameraMinZoomDistance = 7

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
local slot: WeaponPose.Slot = "None"
local aiming = false
local weapons: WeaponPose.Controller? = nil
local running: RBXScriptConnection? = nil
local clearView: (() -> ())? = nil
local VIEW_BINDING = "HunterLabViewmodel"

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
    elseif name == "HunterLabAim" then
        aiming = input == Enum.UserInputState.Begin
    elseif input == Enum.UserInputState.Begin then
        if name == "HunterLabCrouch" then
            crouched = not crouched
        elseif name == "HunterLabJog" then
            jog = not jog
        elseif name == "HunterLabCamera" then
            player.CameraMode = if player.CameraMode == Enum.CameraMode.Classic
                then Enum.CameraMode.LockFirstPerson
                else Enum.CameraMode.Classic
        elseif weapons then
            if name == "HunterLabEquip" then
                slot = if slot == "None"
                    then "Rifle"
                    elseif slot == "Rifle" then "Pistol"
                    else "None"
                weapons.equip(slot)
            elseif name == "HunterLabFire" then
                weapons.play("Fire")
            elseif name == "HunterLabReload" then
                weapons.play("Reload")
            end
        end
    end
    mode = preferred()
    return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("HunterLabSprint", action, false, Enum.KeyCode.LeftShift)
ContextActionService:BindAction("HunterLabCrouch", action, false, Enum.KeyCode.C)
ContextActionService:BindAction("HunterLabJog", action, false, Enum.KeyCode.J)
ContextActionService:BindAction("HunterLabCamera", action, false, Enum.KeyCode.V)
ContextActionService:BindAction("HunterLabEquip", action, false, Enum.KeyCode.B)
ContextActionService:BindAction(
    "HunterLabAim",
    action,
    false,
    Enum.KeyCode.Q,
    Enum.UserInputType.MouseButton2
)
ContextActionService:BindAction("HunterLabFire", action, false, Enum.KeyCode.F)
ContextActionService:BindAction("HunterLabReload", action, false, Enum.KeyCode.R)

local function mount(character: Model)
    if running then
        running:Disconnect()
    end
    if clearView then
        clearView()
    end
    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    local root = character:WaitForChild("HumanoidRootPart") :: BasePart
    crouched, jog, shift, mode = false, false, false, "Walk"
    local animate = Locomotion.bind(character, humanoid, root, library)
    local mounted = WeaponPose.bind(character, root, props)
    local finishCloth = ClothPose.bind(character)
    local view = Viewmodel.bind(character, root)
    weapons = mounted
    mounted.equip(slot)
    RunService:BindToRenderStep(VIEW_BINDING, Enum.RenderPriority.Camera.Value + 2, function()
        view.update(workspace.CurrentCamera, player.CameraMode == Enum.CameraMode.LockFirstPerson)
    end)
    clearView = function()
        RunService:UnbindFromRenderStep(VIEW_BINDING)
        view.destroy()
    end
    local current: string? = nil
    running = RunService.PreSimulation:Connect(function(delta)
        local speed = Locomotion.speed[mode]
        if humanoid.WalkSpeed ~= speed then
            humanoid.WalkSpeed = speed
        end
        animate(delta, mode)
        mounted.update(delta, aiming)
        finishCloth()
        local clip = character:GetAttribute("MotionClip") :: string
        local pose = character:GetAttribute("WeaponPose") :: string?
        local header = if pose and pose ~= "None" then clip .. " / " .. pose else clip
        if header ~= current then
            current = header
            prompt.Text = header
                .. "  ·  WASD — движение  ·  J — бег  ·  Shift — спринт  ·  C — присесть  ·  V — камера\n"
                .. "Space — прыжок  ·  B — реквизит  ·  Q — прицел  ·  F — отдача  ·  R — перехват"
        end
    end)
end

player.CharacterAdded:Connect(mount)
player.CharacterRemoving:Connect(function()
    weapons = nil
    aiming = false
    if clearView then
        clearView()
        clearView = nil
    end
    if running then
        running:Disconnect()
        running = nil
    end
end)
if player.Character then
    mount(player.Character)
end
