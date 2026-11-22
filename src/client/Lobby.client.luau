--!strict

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Catalog = require(ReplicatedStorage.Shared.Catalog)
local player = Players.LocalPlayer
local remote =
    ReplicatedStorage:WaitForChild("GreyOutpostRemotes"):WaitForChild("Lobby") :: RemoteEvent

local MenuPages = require(script.Parent.MenuPages)
local setMovement = require(script.Parent.StationView).start()

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local screen = playerGui:WaitForChild("Lobby") :: ScreenGui
local menu = screen:WaitForChild("Menu") :: Frame
local responsiveScale = menu:WaitForChild("ResponsiveScale") :: UIScale
local tabs = menu:WaitForChild("Tabs") :: Frame
local details = menu:WaitForChild("Details") :: Frame
local heading = details:WaitForChild("Heading") :: TextLabel
local summary = details:WaitForChild("Summary") :: TextLabel
local toggle = details:WaitForChild("ToggleIdle") :: TextButton

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

local primary = details:WaitForChild("Primary") :: TextButton
local secondary = details:WaitForChild("Secondary") :: TextButton
local footer = menu:WaitForChild("Footer") :: TextLabel
local active = "Briefing"
local selectedPage: MenuPages.Page? = nil
local motion = not GuiService.ReducedMotionEnabled
local buttons: { [string]: TextButton } = {}

local function drawMotion()
    setMovement(motion)
    toggle.Text = if motion
        then "   Анимация: включена"
        else "   Анимация: выключена"
end

local function selectPage(key: string)
    local page = MenuPages(player, key)
    if not page then
        return
    end

    active = key
    selectedPage = page
    for id, button in buttons do
        local selected = id == active
        button.BackgroundColor3 = if selected
            then Color3.fromRGB(92, 61, 37)
            else Color3.fromRGB(26, 22, 19)
        button.TextColor3 = if selected
            then Color3.fromRGB(255, 228, 183)
            else Color3.fromRGB(181, 162, 137)
    end
    heading.Text = page.heading
    summary.Text = page.summary
    toggle.Visible = key == "Settings"
    primary.Visible = page.primary ~= nil
    secondary.Visible = page.secondary ~= nil
    primary.Text = if page.primary then "   " .. page.primary.label else ""
    secondary.Text = if page.secondary then "   " .. page.secondary.label else ""
    screen:SetAttribute("ActiveSection", key)
end

local function resize()
    local width, height = screen.AbsoluteSize.X, screen.AbsoluteSize.Y
    responsiveScale.Scale = math.min(1, height / 623, width / 790)
    menu.Position = UDim2.new(0, math.clamp(math.floor(width * 0.042), 16, 72), 0.5, 0)
end

for _, child in tabs:GetChildren() do
    if child:IsA("TextButton") and MenuPages(player, child.Name) then
        buttons[child.Name] = child
        child.Activated:Connect(function()
            selectPage(child.Name)
        end)
    end
end

toggle.Activated:Connect(function()
    motion = not motion
    drawMotion()
end)

screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()
drawMotion()
selectPage(active)

primary.Activated:Connect(function()
    local action = selectedPage and selectedPage.primary
    if action then
        remote:FireServer(action.command, action.value)
    end
end)

secondary.Activated:Connect(function()
    local action = selectedPage and selectedPage.secondary
    if action then
        remote:FireServer(action.command, action.value)
    end
end)

for _, attr in
    {
        "HunterId",
        "WeaponId",
        "Credits",
        "Experience",
        "OwnsCarbine",
        "PartyReady",
        "PartySummary",
        "QueueId",
    }
do
    player:GetAttributeChangedSignal(attr):Connect(function()
        selectPage(active)
    end)
end

player:GetAttributeChangedSignal("LobbyMessage"):Connect(function()
    footer.Text =
        tostring(player:GetAttribute("LobbyMessage") or "ЖЕЛЕЗНОДОРОЖНЫЙ ПОСТ")
end)

local coatColors = {
    LongCoat = true,
    CoatLapels = true,
    LeftCoatTail = true,
    RightCoatTail = true,
    PocketFlaps = true,
    LeftArm = true,
    RightArm = true,
}

local function showHunter()
    local hunter = Catalog.hunter(player:GetAttribute("HunterId"))
    local upper =
        Workspace:WaitForChild("Station"):WaitForChild("DisplayHunter"):WaitForChild("UpperBody")
    if hunter then
        for _, obj in upper:GetDescendants() do
            if obj:IsA("BasePart") and coatColors[obj.Name] then
                obj.Color = hunter.color
            end
        end
    end
end
player:GetAttributeChangedSignal("HunterId"):Connect(showHunter)
showHunter()

local function changePhase()
    local phase = player:GetAttribute("RaidPhase")
    screen.Enabled = phase == nil
    player.CameraMode = if phase == "Alive" or phase == "Downed"
        then Enum.CameraMode.LockFirstPerson
        else Enum.CameraMode.Classic
    local camera = Workspace.CurrentCamera
    if phase == "Alive" and camera then
        camera.CameraType = Enum.CameraType.Custom
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            camera.CameraSubject = humanoid
        end
    end
end
player:GetAttributeChangedSignal("RaidPhase"):Connect(changePhase)
changePhase()
