--!strict

local Viewmodel = {}

type BonePair = { source: Bone, bone: Bone }
type Pair = { source: BasePart, part: BasePart, bones: { BonePair } }

local SLEEVES = table.freeze({
    "LeftUpperArm",
    "LeftLowerArm",
    "LeftHand",
    "LeftThumb",
    "LeftCuff",
    "LeftCuffButton",
    "LeftElbowCloth",
    "RightUpperArm",
    "RightLowerArm",
    "RightHand",
    "RightThumb",
    "RightCuff",
    "RightCuffButton",
    "RightElbowCloth",
})
local VIEW_HEIGHT = 0.94
local CAMERA_OFFSET = CFrame.new(0, -0.32, -1.28)

local function copy(source: BasePart, model: Model): Pair
    local part = source:Clone()
    for _, child in part:GetChildren() do
        if
            not (
                child:IsA("SurfaceAppearance")
                or child:IsA("SpecialMesh")
                or child:IsA("Decal")
                or child:IsA("Texture")
                or child:IsA("Bone")
            )
        then
            child:Destroy()
        end
    end
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.LocalTransparencyModifier = 0
    part.Parent = model
    local bones: { BonePair } = {}
    for _, obj in part:GetDescendants() do
        if obj:IsA("Bone") then
            local reference = source:FindFirstChild(obj.Name, true)
            if reference and reference:IsA("Bone") then
                table.insert(bones, { source = reference, bone = obj })
            end
        end
    end
    return { source = source, part = part, bones = bones }
end

function Viewmodel.bind(character: Model, root: BasePart, resolveHeld: (() -> Model?)?)
    local function defaultHeld(): Model?
        local candidate = character:FindFirstChild("Rifle") or character:FindFirstChild("Pistol")
        return if candidate and candidate:IsA("Model") then candidate else nil
    end
    local getHeld: () -> Model? = resolveHeld or defaultHeld
    local model = Instance.new("Model")
    model.Name = "HunterViewmodel"
    local sleeves: { Pair } = {}
    local prop: { Pair } = {}
    local hidden: { [BasePart]: boolean } = {}
    local current: Model? = nil
    local rootJoint = character:FindFirstChild("Root", true)
    for _, name in SLEEVES do
        local source = character:FindFirstChild(name, true)
        if source and source:IsA("BasePart") then
            table.insert(sleeves, copy(source, model))
        end
    end

    local function restore()
        for part in hidden do
            if part.Parent then
                part.LocalTransparencyModifier = 0
            end
        end
        table.clear(hidden)
    end

    local function update(camera: Camera?, enabled: boolean, projection: CFrame?)
        if not enabled or not camera then
            if model.Parent then
                model.Parent = nil
                restore()
            end
            return
        end
        local held = getHeld()
        if held ~= current then
            for _, pair in prop do
                pair.part:Destroy()
            end
            table.clear(prop)
            current = held
            if current then
                local parts: { Instance } = if resolveHeld
                    then current:GetDescendants()
                    else current:GetChildren()
                for _, obj in parts do
                    if obj:IsA("BasePart") and obj ~= current.PrimaryPart then
                        table.insert(prop, copy(obj, model))
                    end
                end
            end
        end

        local motion = if rootJoint and rootJoint:IsA("Motor6D") then rootJoint.Transform.Y else 0
        local localSpace = (root.CFrame * CFrame.new(0, VIEW_HEIGHT + motion, 0)):Inverse()
        local view = projection or camera.CFrame * CAMERA_OFFSET * localSpace
        for _, pair in sleeves do
            pair.part.CFrame = view * pair.source.CFrame
            for _, bone in pair.bones do
                bone.bone.Transform = bone.source.Transform
            end
        end
        for _, pair in prop do
            pair.part.CFrame = view * pair.source.CFrame
            pair.part.Transparency = pair.source.Transparency
        end
        for _, obj in character:GetDescendants() do
            if obj:IsA("BasePart") then
                hidden[obj] = true
                obj.LocalTransparencyModifier = 1
            end
        end
        if current and not current:IsDescendantOf(character) then
            for _, pair in prop do
                hidden[pair.source] = true
                pair.source.LocalTransparencyModifier = 1
            end
        end
        if model.Parent ~= camera then
            model.Parent = camera
        end
    end

    local function destroy()
        restore()
        model:Destroy()
    end

    return { update = update, destroy = destroy }
end

return Viewmodel
