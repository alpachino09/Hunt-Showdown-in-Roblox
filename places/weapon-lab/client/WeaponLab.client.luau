--!strict

local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Animation = require(Shared.weapons.LanternAnimation)
local Hunters = require(Shared.characters.HunterDefinitions)
local Locomotion = require(Shared.characters.Locomotion)
local ClothPose = require(Shared.characters.ClothPose)
local Viewmodel = require(Shared.characters.Viewmodel)
local Worldmodel = require(script.Parent.WorldmodelController)

local player = Players.LocalPlayer
local input = ReplicatedStorage.WeaponLabInput
local library = Locomotion.decode(ReplicatedStorage.VeteranMotion)
local folder = Instance.new("Folder")
folder.Name = "WeaponLabWorldmodels"
folder.Parent = workspace

type Actor = {
    character: Model,
    animate: (number, Locomotion.Mode, Locomotion.ClipName?) -> (boolean, boolean),
    cloth: () -> (),
    world: ReturnType,
    root: BasePart,
    state: Animation.State?,
    stateChanged: RBXScriptConnection,
    aim: number,
    view: View?,
}
type ReturnType = typeof(Worldmodel.bind(nil :: any, nil :: any, nil :: any))
type View = typeof(Viewmodel.bind(nil :: any, nil :: any))
local actors: { [Player]: Actor } = {}
local firstPerson, holdingAim = true, false

local function applyCameraMode()
    -- Classic retains Roblox's previous zoom, including the first-person distance.
    player.CameraMinZoomDistance = if firstPerson then 0.5 else 6
    player.CameraMode = if firstPerson
        then Enum.CameraMode.LockFirstPerson
        else Enum.CameraMode.Classic
end

local gui = Instance.new("ScreenGui")
gui.Name = "WeaponLab"
gui.ResetOnSpawn = false
local info = Instance.new("TextLabel")
info.Name = "WeaponState"
info.AnchorPoint = Vector2.new(0.5, 1)
info.Position = UDim2.new(0.5, 0, 1, -20)
info.Size = UDim2.new(0.94, 0, 0, 73)
info.BackgroundColor3 = Color3.fromRGB(22, 24, 23)
info.BackgroundTransparency = 0.15
info.TextColor3 = Color3.fromRGB(241, 230, 205)
info.TextSize = 15
info.TextWrapped = true
info.Font = Enum.Font.GothamMedium
info.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

local function clear(owner: Player, character: Model?)
    local actor = actors[owner]
    if actor and (not character or actor.character == character) then
        actor.stateChanged:Disconnect()
        if actor.view then
            actor.view.destroy()
        end
        actor.world.model:Destroy()
        actors[owner] = nil
    end
end

local function bind(owner: Player, character: Model)
    local root = character:WaitForChild("HumanoidRootPart", 6)
    local human = character:WaitForChild("Humanoid", 6)
    if not root or not root:IsA("BasePart") or not human or not human:IsA("Humanoid") then
        return
    end
    if owner.Character ~= character then
        return
    end
    clear(owner)
    local definition = Hunters.byId[character:GetAttribute("HunterId") :: string]
        or Hunters.roster[1]
    local world = Worldmodel.bind(character, root, folder)
    local function stateChanged()
        local actor = actors[owner]
        local encoded = character:GetAttribute("LanternState")
        if actor and typeof(encoded) == "string" then
            actor.state = HttpService:JSONDecode(encoded) :: Animation.State
        end
    end
    actors[owner] = {
        character = character,
        root = root,
        animate = Locomotion.bind(character, human, root, library, definition.idleLean),
        cloth = ClothPose.bind(character),
        world = world,
        state = nil,
        stateChanged = character:GetAttributeChangedSignal("LanternState"):Connect(stateChanged),
        aim = 0,
        view = if owner == player
            then Viewmodel.bind(character, root, function()
                return world.model
            end)
            else nil,
    }
    stateChanged()
    if owner == player then
        holdingAim = false
        applyCameraMode()
        local camera = workspace.CurrentCamera
        if camera then
            camera.CameraSubject = human
        end
    end
end

local function watch(owner: Player)
    owner.CharacterAdded:Connect(function(character)
        bind(owner, character)
    end)
    owner.CharacterRemoving:Connect(function(character)
        clear(owner, character)
    end)
    if owner.Character then
        task.spawn(bind, owner, owner.Character)
    end
end

Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(owner)
    clear(owner)
end)
for _, owner in Players:GetPlayers() do
    watch(owner)
end

local function handle(action: string, phase: Enum.UserInputState)
    if action == "Aim" then
        holdingAim = phase == Enum.UserInputState.Begin
        input:FireServer(action, holdingAim)
    elseif phase == Enum.UserInputState.Begin then
        if action == "View" then
            firstPerson = not firstPerson
            applyCameraMode()
        else
            input:FireServer(action)
        end
    end
    return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction(
    "Fire",
    handle,
    false,
    Enum.UserInputType.MouseButton1,
    Enum.KeyCode.ButtonR2
)
ContextActionService:BindAction(
    "Aim",
    handle,
    false,
    Enum.UserInputType.MouseButton2,
    Enum.KeyCode.ButtonL2
)
ContextActionService:BindAction("Reload", handle, false, Enum.KeyCode.R, Enum.KeyCode.ButtonX)
ContextActionService:BindAction("Cancel", handle, false, Enum.KeyCode.X, Enum.KeyCode.ButtonB)
ContextActionService:BindAction("View", handle, false, Enum.KeyCode.V)
for index, key in { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four } do
    local id = Hunters.roster[index].id
    ContextActionService:BindAction("Hunter" .. index, function(_, state)
        if state == Enum.UserInputState.Begin then
            ReplicatedStorage.HunterLabSelect:FireServer(id)
        end
        return Enum.ContextActionResult.Sink
    end, false, key)
end

local checkAt = 0
RunService.PreSimulation:Connect(function(delta)
    local now = workspace:GetServerTimeNow()
    local sampleContact = now >= checkAt
    if sampleContact then
        checkAt = now + 0.1
    end
    for owner, actor in actors do
        local state = actor.state
        if state and actor.character.Parent then
            actor.animate(delta, "Walk")
            local aiming = if owner == player then holdingAim else state.aiming
            local target = if aiming and not state.reload then 1 else 0
            actor.aim += (target - actor.aim) * (1 - math.exp(-delta * 17))
            local rightError, leftError =
                actor.world.update(now, Animation.sample(state, now), actor.aim)
            if sampleContact then
                actor.world.model:SetAttribute("RightGripError", rightError)
                actor.world.model:SetAttribute("LeftGripError", leftError)
            end
            actor.cloth()
        end
    end
end)

local stageName = table.freeze({
    Open = "Открытие",
    Eject = "Извлечение",
    Insert = "Заряжание",
    Close = "Закрытие",
})

RunService:BindToRenderStep("WeaponLabViewmodel", Enum.RenderPriority.Camera.Value + 2, function()
    local actor = actors[player]
    local camera = workspace.CurrentCamera
    if not actor or not actor.state or not actor.view or not camera then
        return
    end
    if firstPerson then
        local reference = actor.root.CFrame * CFrame.new(0, 1.0, 0)
        local hip = camera.CFrame
            * CFrame.new(0.30, -0.33, -1.34)
            * CFrame.Angles(0, -0.34, 0)
            * reference:Inverse()
        local aim = camera.CFrame
            * CFrame.new(0, -0.03, -0.52)
            * actor.world.sight.WorldCFrame:Inverse()
        actor.view.update(camera, true, hip:Lerp(aim, actor.aim))
    else
        actor.view.update(camera, false)
    end
    local state = actor.state
    local phase = state.reload and stageName[state.reload.stage]
    local line = string.format(
        "Фонарь   %d / %d   ·   %s   ·   %s\nЛКМ выстрел  ·  ПКМ прицел  ·  R перезарядка  ·  X отмена  ·  V камера  ·  1–4 охотник",
        state.loaded,
        state.reserve,
        phase or (if state.loaded > 0 then "Готов" else "Пусто"),
        if firstPerson then "FPP" else "TPP"
    )
    if line ~= info.Text then
        info.Text = line
    end
end)
