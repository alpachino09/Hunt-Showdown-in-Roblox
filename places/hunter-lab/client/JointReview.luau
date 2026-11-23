--!strict

local JointReview = {}

type JointMarker = { node: Motor6D | Bone, part: BasePart, dot: Frame }

function JointReview.bind(character: Model, playerGui: PlayerGui)
    local overlay = Instance.new("ScreenGui")
    overlay.Name = "JointReview"
    overlay.ScreenInsets = Enum.ScreenInsets.None
    overlay.Enabled = false
    overlay.Parent = playerGui
    local markers: { JointMarker } = {}

    for _, obj in character:GetDescendants() do
        local part: BasePart?
        if obj:IsA("Motor6D") then
            part = obj.Part0
        elseif obj:IsA("Bone") then
            local mesh = obj:FindFirstAncestorWhichIsA("BasePart")
            if mesh and mesh:IsA("BasePart") then
                part = mesh
            end
        end
        if part and (obj:IsA("Motor6D") or obj:IsA("Bone")) then
            local size = if obj:IsA("Bone") then 6 else 9
            local dot = Instance.new("Frame")
            dot.Name = obj.Name
            dot.AnchorPoint = Vector2.new(0.5, 0.5)
            dot.Size = UDim2.fromOffset(size, size)
            dot.BorderSizePixel = 0
            dot.BackgroundColor3 = if obj:IsA("Bone")
                then Color3.fromRGB(233, 181, 97)
                else Color3.fromRGB(120, 205, 241)
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.5, 0)
            corner.Parent = dot
            dot.Parent = overlay
            table.insert(markers, { node = obj, part = part, dot = dot })
        end
    end

    local function update(camera: Camera?, visible: boolean)
        overlay.Enabled = visible and camera ~= nil
        if not visible or not camera then
            return
        end
        for _, marker in markers do
            local node = marker.node
            local worldFrame = if node:IsA("Motor6D")
                then marker.part.CFrame * node.C0 * node.Transform
                else node.TransformedWorldCFrame
            local point, onScreen = camera:WorldToViewportPoint(worldFrame.Position)
            marker.dot.Visible = onScreen
            marker.dot.Position = UDim2.fromOffset(point.X, point.Y)
        end
    end

    return {
        update = update,
        destroy = function()
            overlay:Destroy()
        end,
    }
end

return JointReview
