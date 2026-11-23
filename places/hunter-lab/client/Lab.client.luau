--!strict

local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ClothPose = require(ReplicatedStorage.Shared.characters.ClothPose)
local HunterDefinitions = require(ReplicatedStorage.Shared.characters.HunterDefinitions)
local Locomotion = require(ReplicatedStorage.Shared.characters.Locomotion)
local Viewmodel = require(ReplicatedStorage.Shared.characters.Viewmodel)
local WeaponPose = require(ReplicatedStorage.Shared.characters.WeaponPose)
local JointReview = require(script.Parent.JointReview)
local motionData = ReplicatedStorage:WaitForChild("VeteranMotion") :: Folder
local props = ReplicatedStorage:WaitForChild("HunterProps") :: Folder
local selectHunter = ReplicatedStorage:WaitForChild("HunterLabSelect") :: RemoteEvent
local library = Locomotion.decode(motionData)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
player.CameraMinZoomDistance = 7

local gui = Instance.new("ScreenGui")
gui.Name = "HunterLabControls"
gui.ResetOnSpawn = false
local prompt = Instance.new("TextLabel")
prompt.Size = UDim2.new(1, -48, 0, 72)
prompt.Position = UDim2.fromOffset(24, 12)
prompt.BackgroundColor3 = Color3.fromRGB(25, 24, 21)
prompt.BackgroundTransparency = 0.13
prompt.TextColor3 = Color3.fromRGB(232, 216, 178)
prompt.Font = Enum.Font.GothamMedium
prompt.TextSize = 16
prompt.TextWrapped = true
prompt.Parent = gui
gui.Parent = playerGui

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
local HUNTER_KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }
local CLIPS: { Locomotion.ClipName } = {
    "Idle",
    "Walk",
    "Jog",
    "Sprint",
    "CrouchIdle",
    "CrouchWalk",
    "Jump",
    "Air",
    "Land",
    "ReachInteract",
    "TablePickup",
    "KneelInspect",
}
local ANGLES = { Vector3.new(0, 0.7, -11), Vector3.new(11, 0.7, 0), Vector3.new(0, 0.7, 11) }
local SPEEDS = { 1, 0.5, 0.25 }
local daylight = {
    clock = Lighting.ClockTime,
    exposure = Lighting.ExposureCompensation,
    outdoor = Lighting.OutdoorAmbient,
}
local clipIndex = 1
local preview: Locomotion.ClipName? = nil
local paused = false
local rateIndex = 1
local angleIndex = 0
local jointMarkers = false
local night = false

local function reviewAction(name: string, input: Enum.UserInputState)
    if input ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Sink
    end
    if name == "HunterReviewPrev" or name == "HunterReviewNext" then
        local direction = if name == "HunterReviewPrev" then -1 else 1
        clipIndex = (clipIndex + direction - 1) % #CLIPS + 1
        preview = CLIPS[clipIndex]
        paused = false
    elseif name == "HunterReviewPause" then
        paused = not paused
    elseif name == "HunterReviewSpeed" then
        rateIndex = rateIndex % #SPEEDS + 1
    elseif name == "HunterReviewLive" then
        preview = nil
        paused = false
        rateIndex = 1
    elseif name == "HunterReviewAngle" then
        player.CameraMode = Enum.CameraMode.Classic
        angleIndex = (angleIndex + 1) % (#ANGLES + 1)
        local camera = workspace.CurrentCamera
        if camera and angleIndex == 0 then
            camera.CameraType = Enum.CameraType.Custom
            camera.FieldOfView = 70
        end
    elseif name == "HunterReviewJoints" then
        jointMarkers = not jointMarkers
    elseif name == "HunterReviewLight" then
        night = not night
        Lighting.ClockTime = if night then 20.1 else daylight.clock
        Lighting.ExposureCompensation = if night then -0.18 else daylight.exposure
        Lighting.OutdoorAmbient = if night then Color3.fromRGB(71, 82, 111) else daylight.outdoor
    end
    return Enum.ContextActionResult.Sink
end

for name, key in
    {
        HunterReviewPrev = Enum.KeyCode.LeftBracket,
        HunterReviewNext = Enum.KeyCode.RightBracket,
        HunterReviewPause = Enum.KeyCode.P,
        HunterReviewSpeed = Enum.KeyCode.G,
        HunterReviewLive = Enum.KeyCode.U,
        HunterReviewAngle = Enum.KeyCode.H,
        HunterReviewJoints = Enum.KeyCode.K,
        HunterReviewLight = Enum.KeyCode.L,
    }
do
    ContextActionService:BindAction(name, reviewAction, false, key)
end

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
            if angleIndex > 0 then
                angleIndex = 0
                local camera = workspace.CurrentCamera
                if camera then
                    camera.CameraType = Enum.CameraType.Custom
                    camera.FieldOfView = 70
                end
            end
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
ContextActionService:BindAction("HunterLabSelect", function(_, input, context)
    if input == Enum.UserInputState.Begin then
        local index = table.find(HUNTER_KEYS, context.KeyCode)
        local hunter = if index then HunterDefinitions.roster[index] else nil
        if hunter then
            selectHunter:FireServer(hunter.id)
        end
    end
    return Enum.ContextActionResult.Sink
end, false, table.unpack(HUNTER_KEYS, 1, #HunterDefinitions.roster))

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
    local hunterId = character:GetAttribute("HunterId") :: string
    local definition = HunterDefinitions.byId[hunterId] or HunterDefinitions.roster[1]
    local animate = Locomotion.bind(character, humanoid, root, library, definition.idleLean)
    local mounted = WeaponPose.bind(character, root, props)
    local finishCloth = ClothPose.bind(character)
    local view = Viewmodel.bind(character, root)
    local joints = JointReview.bind(character, playerGui)
    weapons = mounted
    mounted.equip(slot)
    RunService:BindToRenderStep(VIEW_BINDING, Enum.RenderPriority.Camera.Value + 2, function()
        local camera = workspace.CurrentCamera
        if camera and angleIndex > 0 then
            local target = root.Position
            camera.CameraType = Enum.CameraType.Scriptable
            camera.FieldOfView = 45
            camera.CFrame = CFrame.lookAt(root.CFrame * ANGLES[angleIndex], target)
            camera.Focus = CFrame.new(target)
        end
        local firstPerson = player.CameraMode == Enum.CameraMode.LockFirstPerson
        view.update(camera, firstPerson)
        joints.update(camera, jointMarkers and not firstPerson)
    end)
    clearView = function()
        RunService:UnbindFromRenderStep(VIEW_BINDING)
        view.destroy()
        joints.destroy()
    end
    local current: string? = nil
    local leftPlanted, rightPlanted = false, false
    running = RunService.PreSimulation:Connect(function(delta: number)
        local speed = if preview or paused
            then 0
            else Locomotion.speed[mode] * definition.speedScale
        if humanoid.WalkSpeed ~= speed then
            humanoid.WalkSpeed = speed
        end
        if not paused then
            local advance = if preview then delta * SPEEDS[rateIndex] else delta
            local left, right = animate(advance, mode, preview)
            if left ~= leftPlanted then
                leftPlanted = left
                character:SetAttribute("LeftFootPlanted", left)
            end
            if right ~= rightPlanted then
                rightPlanted = right
                character:SetAttribute("RightFootPlanted", right)
            end
            mounted.update(advance, aiming)
            finishCloth()
        end
        local clip = character:GetAttribute("MotionClip") :: string
        local pose = character:GetAttribute("WeaponPose") :: string?
        local state = if paused
            then " · пауза"
            elseif preview then (" · просмотр ×%g"):format(SPEEDS[rateIndex])
            else ""
        local header = (if pose and pose ~= "None" then clip .. " / " .. pose else clip) .. state
        if header ~= current then
            current = header
            prompt.Text = header
                .. "  ·  WASD — движение  ·  J — бег  ·  Shift — спринт  ·  C — присесть  ·  V — камера\n"
                .. ("Space — прыжок  ·  B — реквизит  ·  Q — прицел  ·  F — отдача  ·  R — перехват  ·  1–%d — охотник"):format(
                    #HunterDefinitions.roster
                )
                .. "\n[ ] — клип  ·  P — пауза  ·  G — скорость  ·  U — управление  ·  H — ракурс  ·  K — суставы  ·  L — свет"
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
