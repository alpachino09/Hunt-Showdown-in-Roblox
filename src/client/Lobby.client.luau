--!strict

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")

local pages = require(script.Parent.MenuPages)
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

local active = "Briefing"
local motion = not GuiService.ReducedMotionEnabled
local buttons: { [string]: TextButton } = {}

local function drawMotion()
    setMovement(motion)
    toggle.Text = if motion
        then "   Анимация: включена"
        else "   Анимация: выключена"
end

local function selectPage(key: string)
    local page = pages[key]
    if not page then
        return
    end

    active = key
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
    screen:SetAttribute("ActiveSection", key)
end

local function resize()
    local width, height = screen.AbsoluteSize.X, screen.AbsoluteSize.Y
    responsiveScale.Scale = math.min(1, height / 623, width / 790)
    menu.Position = UDim2.new(0, math.clamp(math.floor(width * 0.042), 16, 72), 0.5, 0)
end

for _, child in tabs:GetChildren() do
    if child:IsA("TextButton") and pages[child.Name] then
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
