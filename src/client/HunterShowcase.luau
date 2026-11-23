--!strict

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Characters = ReplicatedStorage.Shared.characters
local ClothPose = require(Characters.ClothPose)
local HunterDefinitions = require(Characters.HunterDefinitions)
local Locomotion = require(Characters.Locomotion)
local WeaponPose = require(Characters.WeaponPose)

type Actor = { rig: Model, update: (number) -> () }
local HunterShowcase = {}
local STREAM_SETTLE = 0.55

function HunterShowcase.start(station: Instance, marker: BasePart, eye: BasePart, player: Player)
    local roster = ReplicatedStorage:WaitForChild("HunterRoster")
    local motion = ReplicatedStorage:WaitForChild("VeteranMotion") :: Folder
    local props = ReplicatedStorage:WaitForChild("HunterProps") :: Folder
    local library = Locomotion.decode(motion)
    local legacy = station:WaitForChild("DisplayHunter")
    local loading: { [string]: boolean } = {}
    local warm: { [string]: boolean } = {}
    local mounting: { [string]: boolean } = {}
    local desired = ""
    local actor: Actor? = nil
    local movement = true
    local ready = false

    local function mount(definition: HunterDefinitions.Definition, template: Model)
        if mounting[definition.id] then
            return
        end
        mounting[definition.id] = true
        local rig = template:Clone()
        rig.Name = "PendingHunter"
        rig:SetAttribute("HunterId", definition.id)
        local root = assert(rig.PrimaryPart, "Expected the hunter root")
        local humanoid = assert(rig:FindFirstChildOfClass("Humanoid"), "Expected the hunter rig")
        root.Anchored = true
        humanoid.AutoRotate = false
        local pieces: { BasePart } = {}
        for _, item in rig:GetDescendants() do
            if item:IsA("BasePart") then
                item.CanCollide = false
                item.CanTouch = false
                item.CanQuery = false
            end
        end
        local scale = definition.showcaseScale
        local height = root.Position.Y * scale
        rig:ScaleTo(scale)
        local position = marker.Position + Vector3.yAxis * height
        local toEye = eye.Position - position
        local facing = CFrame.lookAt(position, position + Vector3.new(toEye.X, 0, toEye.Z))
        rig:PivotTo(facing * CFrame.Angles(0, math.rad(16), 0))

        local locomotion = Locomotion.bind(rig, humanoid, root, library, definition.idleLean, true)
        local weapon = WeaponPose.bind(rig, root, props)
        local cloth = ClothPose.bind(rig)
        local head = rig:WaitForChild("Head")
        local neck = head:WaitForChild("Neck") :: Motor6D
        weapon.equip(definition.showcaseProp)
        for _, part in rig:GetDescendants() do
            if part:IsA("BasePart") then
                table.insert(pieces, part)
                part.LocalTransparencyModifier = 1
            end
        end
        local time = 0
        local function update(delta: number)
            time += delta
            locomotion(delta, "Walk")
            weapon.update(delta, false)
            local glance = math.sin(time * 0.65) ^ 4 * definition.idleGlance
            neck.Transform *= CFrame.Angles(-math.abs(glance) * 0.18, glance, 0)
            cloth()
        end
        if player:GetAttribute("RaidPhase") == nil then
            rig.Parent = station
        end
        update(0)
        task.wait(STREAM_SETTLE)
        mounting[definition.id] = nil
        if desired ~= definition.id then
            rig:Destroy()
            return
        end
        local previous = actor
        if player:GetAttribute("RaidPhase") ~= nil then
            rig.Parent = nil
        end
        rig.Name = "ActiveHunter"
        actor = { rig = rig, update = update }
        if previous then
            previous.rig:Destroy()
        end
        for _, part in pieces do
            part.LocalTransparencyModifier = 0
        end
        if not ready then
            ready = true
            for _, item in legacy:GetDescendants() do
                if item:IsA("BasePart") then
                    item.LocalTransparencyModifier = 1
                end
            end
        end
    end

    local function selectHunter()
        local id = player:GetAttribute("HunterId")
        local definition = (if typeof(id) == "string" then HunterDefinitions.byId[id] else nil)
            or HunterDefinitions.roster[1]
        desired = definition.id
        if actor and actor.rig:GetAttribute("HunterId") == desired then
            return
        end
        local template = roster:FindFirstChild(definition.template)
        if not template or not template:IsA("Model") then
            return
        end
        if warm[desired] then
            task.spawn(mount, definition, template)
            return
        end
        if loading[desired] then
            return
        end
        loading[desired] = true
        task.spawn(function()
            local items: { Instance } = {}
            for _, source in { template, props:FindFirstChild(definition.showcaseProp) } do
                for _, item in source:GetDescendants() do
                    if item:IsA("MeshPart") and item.Transparency < 1 then
                        table.insert(items, item)
                    end
                end
            end
            -- The engine streams the processed SurfaceAppearance packs when first rendered.
            local loaded = true
            ContentProvider:PreloadAsync(items, function(_, status)
                loaded = loaded and status == Enum.AssetFetchStatus.Success
            end)
            loading[definition.id] = nil
            warm[definition.id] = loaded
            if desired == definition.id and loaded then
                mount(definition, template)
            end
        end)
    end

    player:GetAttributeChangedSignal("HunterId"):Connect(selectHunter)
    selectHunter()
    RunService.PreSimulation:Connect(function(delta)
        local current = actor
        if not current then
            return
        end
        local visible = player:GetAttribute("RaidPhase") == nil
        local parent = if visible then station else nil
        if current.rig.Parent ~= parent then
            current.rig.Parent = parent
        end
        if visible then
            current.update(if movement then delta else 0)
        end
    end)
    return {
        ready = function()
            return ready
        end,
        setMovement = function(enabled: boolean)
            movement = enabled
        end,
    }
end

return HunterShowcase
