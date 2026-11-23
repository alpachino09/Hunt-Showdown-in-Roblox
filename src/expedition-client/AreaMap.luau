--!strict

local Players = game:GetService("Players")
local player = Players.LocalPlayer

type Landmark = { title: string, x: number, z: number }
local mainLandmarks: { Landmark } = {
    { title = "Северная контора", x = 0, z = -44 },
    { title = "Просека", x = -24, z = 9 },
    { title = "Кедровый путь", x = 19, z = 30 },
    { title = "Выход", x = -3, z = 68 },
}
local rushLandmarks: { Landmark } = {
    { title = "Контора", x = 0, z = -44 },
    { title = "Выход", x = -3, z = 39 },
}

local MAP_INK = Color3.fromRGB(50, 43, 34)
local function label(
    parent: Instance,
    caption: string,
    size: UDim2,
    position: UDim2,
    fontSize: number
): TextLabel
    local object = Instance.new("TextLabel")
    object.BackgroundTransparency = 1
    object.Text = caption
    object.Font = Enum.Font.GothamMedium
    object.TextSize = fontSize
    object.TextColor3 = MAP_INK
    object.Size = size
    object.Position = position
    object.Parent = parent
    return object
end

local AreaMap = {}

function AreaMap.mount(screen: ScreenGui)
    local map = Instance.new("Frame")
    map.Name = "SurveyMap"
    map.AnchorPoint = Vector2.new(0.5, 0.5)
    map.Position = UDim2.fromScale(0.5, 0.49)
    map.Size = UDim2.fromScale(0.64, 0.69)
    map.BackgroundColor3 = Color3.fromRGB(172, 150, 116)
    map.BorderSizePixel = 0
    map.ZIndex = 3
    map.Visible = false
    map.Parent = screen

    local bound = Instance.new("UISizeConstraint")
    bound.MaxSize = Vector2.new(600, 475)
    bound.Parent = map
    local title = label(map, "", UDim2.new(1, 0, 0, 48), UDim2.new(), 24)
    title.ZIndex = 4
    local field = Instance.new("Frame")
    field.Name = "Survey"
    field.Position = UDim2.new(0.07, 0, 0, 56)
    field.Size = UDim2.new(0.86, 0, 1, -94)
    field.BackgroundColor3 = Color3.fromRGB(149, 131, 104)
    field.ClipsDescendants = true
    field.BorderSizePixel = 0
    field.ZIndex = 4
    field.Parent = map

    for i = 1, 6 do
        for _, vertical in { true, false } do
            local line = Instance.new("Frame")
            line.BackgroundTransparency = 0.54
            line.BackgroundColor3 = MAP_INK
            line.BorderSizePixel = 0
            line.Position = if vertical
                then UDim2.fromScale(i / 7, 0)
                else UDim2.fromScale(0, i / 7)
            line.Size = if vertical then UDim2.new(0, 1, 1, 0) else UDim2.new(1, 0, 0, 1)
            line.ZIndex = 4
            line.Parent = field
        end
    end
    local compass = label(field, "С ↑", UDim2.fromOffset(35, 23), UDim2.fromOffset(8, 6), 15)
    compass.ZIndex = 5
    local self = label(field, "◆", UDim2.fromOffset(22, 22), UDim2.new(), 18)
    self.Name = "Position"
    self.AnchorPoint = Vector2.new(0.5, 0.5)
    self.TextColor3 = Color3.fromRGB(99, 38, 30)
    self.ZIndex = 6
    local tip = label(
        map,
        "M · закрыть карту     ◆ · ваше положение",
        UDim2.new(1, 0, 0, 34),
        UDim2.new(0, 0, 1, -34),
        15
    )
    tip.ZIndex = 4

    local marks = {} :: { TextLabel }
    local function toMap(x: number, z: number, fast: boolean)
        return UDim2.fromScale(
            (x / (if fast then 80 else 139)) + 0.5,
            (z / (if fast then 128 else 178)) + 0.5
        )
    end

    local function show(visible: boolean)
        map.Visible = visible
        if not visible then
            return
        end
        local fast = player:GetAttribute("RaidSearch") == false
        title.Text = tostring(player:GetAttribute("RaidMode") or "Кедровый округ")
        for _, mark in marks do
            mark:Destroy()
        end
        table.clear(marks)
        local landmarks: { Landmark } = if fast then rushLandmarks else mainLandmarks
        for _, landmark in landmarks do
            local marker = label(
                field,
                "· " .. landmark.title,
                UDim2.fromOffset(120, 20),
                toMap(landmark.x, landmark.z, fast),
                13
            )
            marker.AnchorPoint = Vector2.new(0.5, 0.5)
            marker.ZIndex = 5
            table.insert(marks, marker)
        end
    end

    local function update()
        local character = player.Character
        if not map.Visible or not character then
            return
        end
        local position = character:GetPivot().Position
        self.Position =
            toMap(position.X - 220, position.Z, player:GetAttribute("RaidSearch") == false)
    end
    return map, show, update
end

return AreaMap
