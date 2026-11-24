--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local DebugConfig = require(ReplicatedStorage.Shared["mammons-gulch"].DebugConfig)
local Definitions = require(ReplicatedStorage.Shared["mammons-gulch"].CompoundDefinitions)
local DebugVisibility = require(ReplicatedStorage.Shared["mammons-gulch"].DebugVisibility)
if not DebugConfig.enabled then
    return
end

local player = Players.LocalPlayer
local map = Workspace:WaitForChild("Maps"):WaitForChild("MammonsGulch")
local remote = ReplicatedStorage:WaitForChild(DebugConfig.remoteName)
local screen = Instance.new("ScreenGui")
screen.Name = "MammonsGulchDebug"
screen.ResetOnSpawn = false
screen.DisplayOrder = 50
screen.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0.5)
panel.Position = UDim2.new(1, -18, 0.5, -120)
panel.Size = UDim2.fromOffset(340, 242)
panel.BackgroundColor3 = Color3.fromRGB(28, 26, 23)
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 5)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.fromOffset(12, 8)
title.Size = UDim2.new(1, -24, 0, 22)
title.BackgroundTransparency = 1
title.Text = "Mammon's Gulch · Studio tools"
title.TextColor3 = Color3.fromRGB(222, 208, 176)
title.Font = Enum.Font.GothamMedium
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Position = UDim2.fromOffset(12, 34)
status.Size = UDim2.new(1, -24, 0, 50)
status.BackgroundTransparency = 1
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(191, 182, 162)
status.Font = Enum.Font.Code
status.TextSize = 13
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Parent = panel

local selectedIndex = 1
local selected = Definitions.ordered[selectedIndex]
local states = {
    bounds = false,
    spawns = false,
    clues = false,
    exits = false,
    heights = false,
    sightlines = false,
    collisions = false,
}
local overlays = nil :: Folder?
local sightline = nil :: BasePart?
local sightlineGui = nil :: BillboardGui?

local function button(name: string, text: string, order: number, callback: () -> ())
    local object = Instance.new("TextButton")
    object.Name = name
    object.Size = UDim2.fromOffset(102, 28)
    object.Position =
        UDim2.fromOffset(12 + (order - 1) % 3 * 108, 96 + math.floor((order - 1) / 3) * 36)
    object.BackgroundColor3 = Color3.fromRGB(70, 57, 42)
    object.BorderSizePixel = 0
    object.Text = text
    object.TextColor3 = Color3.fromRGB(230, 218, 192)
    object.Font = Enum.Font.Gotham
    object.TextSize = 13
    object.Parent = panel
    object.Activated:Connect(callback)
    return object
end

local function markerVisibility(root: Instance, alpha: number)
    for _, object in root:GetDescendants() do
        if object:IsA("BasePart") then
            object.LocalTransparencyModifier = alpha
        end
    end
end

local function clearSightline()
    if sightline then
        sightline:Destroy()
        sightline = nil
    end
    if sightlineGui then
        sightlineGui:Destroy()
        sightlineGui = nil
    end
end

local function clearOverlays()
    DebugVisibility.applyBounds(map.Compounds, 1)
    markerVisibility(map.SpawnPoints.Candidates, 1)
    markerVisibility(map.ClueLocations, 1)
    markerVisibility(map.ExtractionPoints, 1)
    if overlays then
        overlays:Destroy()
        overlays = nil
    end
    clearSightline()
end

local function createHeightLabels()
    if overlays then
        return
    end
    overlays = Instance.new("Folder")
    assert(overlays, "overlay folder expected").Name = "MammonsGulchHeightOverlay"
    for _, definition in Definitions.ordered do
        local anchor = Instance.new("Part")
        anchor.Name = definition.id
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanQuery = false
        anchor.CanTouch = false
        anchor.Transparency = 1
        anchor.Size = Vector3.one
        anchor.Position = Vector3.new(table.unpack(definition.worldPosition)) + Vector3.yAxis * 42
        local gui = Instance.new("BillboardGui")
        gui.Name = "Height"
        gui.Size = UDim2.fromOffset(230, 32)
        gui.AlwaysOnTop = false
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text =
            string.format("%s · %.2f m", definition.name, definition.worldPosition[2] / 3 + 32.79)
        label.TextColor3 = Color3.fromRGB(231, 218, 177)
        label.Font = Enum.Font.Code
        label.TextSize = 14
        label.Parent = gui
        gui.Parent = anchor
        anchor.Parent = overlays
    end
    assert(overlays, "overlay folder expected").Parent = Workspace
end

local function createCollisionBoxes()
    if overlays then
        return
    end
    overlays = Instance.new("Folder")
    assert(overlays, "overlay folder expected").Name = "MammonsGulchCollisionOverlay"
    local targets = {
        map.Roads.western_spine.Segment_07,
        map.Railways.main_north_south_rail.Segment_01,
        map.Bridges.kingfisher_trestle.Deck_01,
        map.Underground["VisArea-22"].Floor,
    }
    for _, target in targets do
        local box = Instance.new("SelectionBox")
        box.Name = target:GetFullName()
        box.Adornee = target
        box.LineThickness = 0.12
        box.Visible = true
        box.Color3 = Color3.fromRGB(91, 181, 162)
        box.SurfaceColor3 = Color3.fromRGB(91, 181, 162)
        box.SurfaceTransparency = 0.88
        box.Parent = overlays
    end
    assert(overlays, "overlay folder expected").Parent = Workspace
end

local function updateSightline()
    clearSightline()
    if not states.sightlines then
        return
    end
    local nextDefinition = Definitions.ordered[selectedIndex % #Definitions.ordered + 1]
    local origin = Vector3.new(table.unpack(selected.worldPosition)) + Vector3.yAxis * 8
    local target = Vector3.new(table.unpack(nextDefinition.worldPosition)) + Vector3.yAxis * 8
    local direction = target - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { player.Character }
    local hit = Workspace:Raycast(origin, direction, params)
    local clear = hit == nil
    local part = Instance.new("Part")
    part.Name = "DebugSightline"
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Size = Vector3.new(0.45, 0.45, direction.Magnitude)
    part.CFrame = CFrame.lookAt(origin + direction / 2, target)
    part.Color = if clear then Color3.fromRGB(102, 183, 135) else Color3.fromRGB(196, 105, 82)
    part.Material = Enum.Material.Neon
    part.Parent = Workspace
    sightline = part
    local gui = Instance.new("BillboardGui")
    gui.Name = "SightlineReadout"
    gui.Size = UDim2.fromOffset(270, 42)
    gui.StudsOffsetWorldSpace = Vector3.yAxis * 4
    gui.AlwaysOnTop = true
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = string.format(
        "%s → %s · %.1f m · %s",
        selected.name,
        nextDefinition.name,
        direction.Magnitude / 3,
        if clear then "clear" else "blocked"
    )
    label.TextColor3 = Color3.fromRGB(235, 222, 190)
    label.TextStrokeTransparency = 0.2
    label.Font = Enum.Font.Code
    label.TextSize = 14
    label.Parent = gui
    gui.Parent = part
    sightlineGui = gui
end

local function updateOverlays()
    DebugVisibility.applyBounds(map.Compounds, if states.bounds then 0.35 else 1)
    markerVisibility(map.SpawnPoints.Candidates, if states.spawns then 0.35 else 1)
    markerVisibility(map.ClueLocations, if states.clues then 0.35 else 1)
    markerVisibility(map.ExtractionPoints, if states.exits then 0.35 else 1)
    if states.heights then
        createHeightLabels()
    elseif overlays and overlays.Name == "MammonsGulchHeightOverlay" then
        overlays:Destroy()
        overlays = nil
    end
    if states.collisions then
        createCollisionBoxes()
    elseif overlays and overlays.Name == "MammonsGulchCollisionOverlay" then
        overlays:Destroy()
        overlays = nil
    end
    updateSightline()
end

local function updateStatus()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local position = if root then root.Position else Vector3.zero
    status.Text = string.format(
        "%s · %s\nX %.1f · Y %.1f · Z %.1f · StreamingEnabled=%s",
        selected.name,
        selected.verificationStatus,
        position.X,
        position.Y,
        position.Z,
        tostring(Workspace.StreamingEnabled)
    )
end

button("Compound", "Next compound", 1, function()
    selectedIndex = selectedIndex % #Definitions.ordered + 1
    selected = Definitions.ordered[selectedIndex]
    updateStatus()
    updateSightline()
end)
button("Teleport", "Teleport", 2, function()
    remote:FireServer(selected.id)
end)
button("Bounds", "Bounds", 3, function()
    states.bounds = not states.bounds
    updateOverlays()
end)
button("Points", "Points", 4, function()
    states.spawns = not states.spawns
    updateOverlays()
end)
button("Clues", "Clues", 5, function()
    states.clues = not states.clues
    updateOverlays()
end)
button("Exits", "Exits", 6, function()
    states.exits = not states.exits
    updateOverlays()
end)
button("Heights", "Heights", 7, function()
    states.heights = not states.heights
    updateOverlays()
end)
button("Sightline", "Sightline", 8, function()
    states.sightlines = not states.sightlines
    updateSightline()
end)
button("Collisions", "Collisions", 9, function()
    states.collisions = not states.collisions
    updateOverlays()
end)
button("Clear", "Clear", 10, function()
    for key in states do
        states[key] = false
    end
    clearOverlays()
end)

local input = UserInputService.InputBegan:Connect(function(object, processed)
    if processed then
        return
    end
    if object.KeyCode == Enum.KeyCode.F6 then
        remote:FireServer(selected.id)
    elseif object.KeyCode == Enum.KeyCode.F7 then
        states.bounds = not states.bounds
        updateOverlays()
    end
end)
screen.Destroying:Connect(function()
    input:Disconnect()
    clearOverlays()
end)
updateStatus()
task.spawn(function()
    while screen.Parent do
        task.wait(1)
        updateStatus()
    end
end)
