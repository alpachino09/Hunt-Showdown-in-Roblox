--!strict

local Player = game:GetService("Players").LocalPlayer
local Lighting = game:GetService("Lighting")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local remote =
    ReplicatedStorage:WaitForChild("GreyOutpostRemotes"):WaitForChild("Combat") :: RemoteEvent

local hud = Instance.new("ScreenGui")
hud.Name = "FieldHud"
hud.ResetOnSpawn = false
hud.Enabled = false

local function textLabel(
    name: string,
    size: UDim2,
    position: UDim2,
    anchor: Vector2,
    textSize: number
): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = position
    label.AnchorPoint = anchor
    label.BackgroundTransparency = 0.27
    label.BackgroundColor3 = Color3.fromRGB(18, 19, 16)
    label.TextColor3 = Color3.fromRGB(233, 220, 192)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = textSize
    label.Text = ""
    label.TextWrapped = true
    label.BorderSizePixel = 0
    label.Parent = hud
    return label
end

local status = textLabel(
    "Objective",
    UDim2.new(0.7, 0, 0, 64),
    UDim2.new(0.5, 0, 0, 14),
    Vector2.new(0.5, 0),
    17
)
local loadout = textLabel(
    "Loadout",
    UDim2.fromOffset(320, 74),
    UDim2.new(1, -22, 1, -18),
    Vector2.new(1, 1),
    17
)
local crosshair = textLabel(
    "Sight",
    UDim2.fromOffset(34, 34),
    UDim2.fromScale(0.5, 0.5),
    Vector2.new(0.5, 0.5),
    22
)
crosshair.BackgroundTransparency = 1
crosshair.Text = "·"
local exit = textLabel(
    "ExtractClock",
    UDim2.fromOffset(260, 38),
    UDim2.fromScale(0.5, 0.74),
    Vector2.new(0.5, 0.5),
    20
)
hud.Parent = Player:WaitForChild("PlayerGui")

local function act(name: string, state: Enum.UserInputState)
    if name == "Sprint" or name == "Crouch" then
        if state == Enum.UserInputState.Begin or state == Enum.UserInputState.End then
            remote:FireServer(if state == Enum.UserInputState.Begin then name else "Walk")
            local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.CameraOffset = if name == "Crouch"
                        and state == Enum.UserInputState.Begin
                    then Vector3.new(0, -0.85, 0)
                    else Vector3.zero
            end
        end
    elseif state == Enum.UserInputState.Begin then
        local camera = Workspace.CurrentCamera
        if name == "Fire" and camera then
            remote:FireServer(name, camera.CFrame.LookVector)
        else
            remote:FireServer(name)
        end
    end
    return Enum.ContextActionResult.Sink
end

local actions = {
    Fire = Enum.UserInputType.MouseButton1,
    Reload = Enum.KeyCode.R,
    Resonance = Enum.KeyCode.Q,
    Sprint = Enum.KeyCode.LeftShift,
    Crouch = Enum.KeyCode.LeftControl,
}
local stationLighting = {
    clock = Lighting.ClockTime,
    ambient = Lighting.Ambient,
    outdoors = Lighting.OutdoorAmbient,
    fog = Lighting.FogEnd,
    fogColor = Lighting.FogColor,
}
local function phase()
    local state = Player:GetAttribute("RaidPhase")
    hud.Enabled = state ~= nil
    Lighting.ClockTime = if hud.Enabled then 6.35 else stationLighting.clock
    Lighting.FogEnd = if hud.Enabled then 235 else stationLighting.fog
    Lighting.FogColor = if hud.Enabled
        then Color3.fromRGB(91, 104, 107)
        else stationLighting.fogColor
    Lighting.Ambient = if hud.Enabled then Color3.fromRGB(62, 67, 73) else stationLighting.ambient
    Lighting.OutdoorAmbient = if hud.Enabled
        then Color3.fromRGB(89, 95, 101)
        else stationLighting.outdoors
    for key in actions do
        ContextActionService:UnbindAction(key)
    end
    ContextActionService:UnbindAction("Return")
    if state == "Alive" then
        for key, input in actions do
            ContextActionService:BindAction(key, act, false, input)
        end
        Player.CameraMode = Enum.CameraMode.LockFirstPerson
        local camera = Workspace.CurrentCamera
        local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if camera and humanoid then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = humanoid
        end
    elseif state == "Debrief" then
        ContextActionService:BindAction("Return", act, false, Enum.KeyCode.Return)
    elseif state == nil then
        Player.CameraMode = Enum.CameraMode.Classic
    end
end

local function redraw()
    if not hud.Enabled then
        return
    end
    status.Text = string.format(
        "КЕДРОВЫЙ ПЕРЕГОН   /   СЛЕДЫ %s / 3\n%s",
        tostring(Player:GetAttribute("RaidClues") or 0),
        tostring(
            Player:GetAttribute("RaidMessage") or "Подготовка экспедиции…"
        )
    )
    local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local health = if humanoid then math.ceil(humanoid.Health) else 0
    loadout.Text = string.format(
        "%s     %s / %s\nЗдоровье %d  ·  %s",
        tostring(Player:GetAttribute("RaidWeapon") or ""),
        tostring(Player:GetAttribute("RaidAmmo") or "–"),
        tostring(Player:GetAttribute("RaidReserve") or "–"),
        health,
        if Player:GetAttribute("RaidReloading")
            then "Перезарядка"
            else "R · зарядить    Q · резонанс"
    )
    local untilTime = Player:GetAttribute("RaidExitAt")
    local deadline = Player:GetAttribute("RaidDeadline")
    exit.Visible = type(untilTime) == "number"
    exit.Text = if type(untilTime) == "number"
        then string.format(
            "Эвакуация через %.1f с",
            math.max(0, untilTime - Workspace:GetServerTimeNow())
        )
        else ""
    if type(deadline) == "number" and not exit.Visible then
        local seconds = math.max(0, math.floor(deadline - Workspace:GetServerTimeNow()))
        exit.Visible = seconds < 60
        exit.Text = string.format("До конца контракта %d с", seconds)
    end
end

local accumulator = 0
RunService.RenderStepped:Connect(function(dt)
    accumulator += dt
    if accumulator >= 0.1 then
        accumulator = 0
        redraw()
    end
end)

remote.OnClientEvent:Connect(function(action: string, data: any)
    if action == "Fired" and hud.Enabled then
        crosshair.TextColor3 = Color3.fromRGB(234, 155, 72)
        TweenService
            :Create(crosshair, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(233, 220, 192) })
            :Play()
    elseif action == "Resonance" and hud.Enabled then
        for _, position in data do
            local marker = Instance.new("Part")
            marker.Size = Vector3.one
            marker.Position = position + Vector3.new(0, 2.4, 0)
            marker.Transparency = 1
            marker.Anchored = true
            marker.CanCollide = false
            marker.CanQuery = false
            marker.CanTouch = false
            local billboard = Instance.new("BillboardGui")
            billboard.Size = UDim2.fromOffset(88, 25)
            billboard.AlwaysOnTop = true
            billboard.Parent = marker
            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundColor3 = Color3.fromRGB(34, 60, 59)
            label.BackgroundTransparency = 0.22
            label.TextColor3 = Color3.fromRGB(195, 222, 207)
            label.TextSize = 15
            label.Text = "СЛЕД"
            label.Parent = billboard
            marker.Parent = Workspace
            task.delay(3, function()
                marker:Destroy()
            end)
        end
    end
end)

Player:GetAttributeChangedSignal("RaidPhase"):Connect(phase)
phase()
