--!strict
-- Run in the client Command Bar of the locally built lobby during Solo Play.

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
assert(RunService:IsStudio() and game.PlaceId == 0, "Use the local Studio build")
assert(
    Workspace:FindFirstChild("Station") and not player:GetAttribute("RaidPhase"),
    "Open the local lobby"
)
assert(
    not Workspace:FindFirstChild("HunterPerformance"),
    "Remove the previous QA row before rerunning"
)

local Characters = ReplicatedStorage.Shared.characters
local ClothPose = require(Characters.ClothPose)
local HunterDefinitions = require(Characters.HunterDefinitions)
local Locomotion = require(Characters.Locomotion)
local WeaponPose = require(Characters.WeaponPose)

local roster = ReplicatedStorage:WaitForChild("HunterRoster")
local props = ReplicatedStorage:WaitForChild("HunterProps") :: Folder
local motion = ReplicatedStorage:WaitForChild("VeteranMotion") :: Folder
local library = Locomotion.decode(motion)
local screen = player.PlayerGui:WaitForChild("Lobby") :: ScreenGui
local camera = assert(Workspace.CurrentCamera, "Expected the Studio client camera")
local origin = Vector3.new(150, 0, 36)
local cameraTarget = origin + Vector3.new(0, 2.68, 0)
local binding = "HunterRosterPerformance"
local shots = 180
local actors: { Model } = {}
local steps: { (number) -> () } = {}
local dressCost = 0

local area = Instance.new("Folder")
area.Name = "HunterPerformance"
local deck = Instance.new("Part")
deck.Name = "ReviewDeck"
deck.Size = Vector3.new(44, 0.45, 7)
deck.Position = origin - Vector3.yAxis * (deck.Size.Y / 2)
deck.Material = Enum.Material.Slate
deck.Color = Color3.fromRGB(76, 71, 64)
deck.Anchored = true
deck.CanCollide = false
deck.Parent = area
local fillAnchor = Instance.new("Part")
fillAnchor.Name = "ReviewFill"
fillAnchor.Transparency = 1
fillAnchor.Anchored = true
fillAnchor.CanCollide = false
fillAnchor.Position = origin + Vector3.new(0, 6, 17)
fillAnchor.Parent = area
local fill = Instance.new("PointLight")
fill.Color = Color3.fromRGB(234, 220, 200)
fill.Brightness = 2.2
fill.Range = 40
fill.Shadows = false
fill.Parent = fillAnchor
area.Parent = Workspace

local function addHunter(index: number, x: number)
    local definitions = HunterDefinitions.roster
    local definition = definitions[(index - 1) % #definitions + 1]
    local template = roster:FindFirstChild(definition.template) :: Model
    local model = template:Clone()
    local root = assert(model.PrimaryPart, "Expected an R15 root")
    local humanoid = assert(model:FindFirstChildOfClass("Humanoid"), "Expected the rig")
    local spawnPosition = origin + Vector3.new(x, root.Position.Y, 0)
    root.Anchored = true
    humanoid.AutoRotate = false
    model.Name = ("%02d-%s"):format(index, definition.id)
    model:PivotTo(CFrame.lookAt(spawnPosition, spawnPosition + Vector3.zAxis))
    local move = Locomotion.bind(model, humanoid, root, library, definition.idleLean, true)
    local hold = WeaponPose.bind(model, root, props)
    local cloth = ClothPose.bind(model)
    hold.equip(definition.showcaseProp)
    model.Parent = area
    move(index * 0.13, "Walk")
    table.insert(actors, model)
    table.insert(steps, function(delta)
        move(delta, "Walk")
        hold.update(delta, false)
        cloth()
    end)
end

local visibility = screen.Enabled
screen.Enabled = false
RunService:BindToRenderStep(binding, Enum.RenderPriority.Camera.Value + 4, function()
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = CFrame.lookAt(origin + Vector3.new(0, 7.0, 32), cameraTarget)
    camera.Focus = CFrame.new(cameraTarget)
    camera.FieldOfView = 47
end)
local animation = RunService.PreSimulation:Connect(function(delta)
    local start = os.clock()
    for _, step in steps do
        step(delta)
    end
    dressCost = (os.clock() - start) * 1000
end)

area.Destroying:Connect(function()
    animation:Disconnect()
    RunService:UnbindFromRenderStep(binding)
    screen.Enabled = visibility
end)

local function percentile(numbers: { number }, fraction: number): number
    return numbers[math.ceil(#numbers * fraction)]
end

local function sample()
    local frames, cpu, gpu, scriptTimes, drawcalls, triangles = {}, {}, {}, {}, {}, {}
    local total = 0
    for index = 1, shots do
        local dt = RunService.PreRender:Wait()
        total += dt
        frames[index] = dt * 1000
        cpu[index] = Stats.RenderCPUFrameTime * 1000
        gpu[index] = Stats.RenderGPUFrameTime * 1000
        scriptTimes[index] = dressCost
        drawcalls[index] = Stats.SceneDrawcallCount
        triangles[index] = Stats.SceneTriangleCount
    end
    for _, values in { frames, cpu, gpu, scriptTimes, drawcalls, triangles } do
        table.sort(values)
    end

    local bones, motors, meshes, visible, loaded, pending = 0, 0, 0, 0, 0, {}
    for _, model in actors do
        local head = model:FindFirstChild("Head") :: BasePart
        local sole = model:FindFirstChild("LeftSole", true) :: BasePart
        local _, top = camera:WorldToViewportPoint(head.Position)
        local _, bottom = camera:WorldToViewportPoint(sole.Position)
        visible += if top and bottom then 1 else 0
        for _, obj in model:GetDescendants() do
            if obj:IsA("Bone") then
                bones += 1
            elseif obj:IsA("Motor6D") then
                motors += 1
            elseif obj:IsA("MeshPart") and obj.Transparency < 1 then
                meshes += 1
                if
                    ContentProvider:GetAssetFetchStatus(obj.MeshId) == Enum.AssetFetchStatus.Success
                then
                    loaded += 1
                else
                    pending[obj.Name] = true
                end
            end
        end
    end
    return {
        count = #actors,
        visible = visible,
        samples = shots,
        meshes = meshes,
        loaded = loaded,
        pending = pending,
        bones = bones,
        motors = motors,
        fps = shots / total,
        medianMs = percentile(frames, 0.5),
        p95Ms = percentile(frames, 0.95),
        cpuP95Ms = percentile(cpu, 0.95),
        gpuP95Ms = percentile(gpu, 0.95),
        poseP95Ms = percentile(scriptTimes, 0.95),
        drawcalls = percentile(drawcalls, 0.5),
        triangles = percentile(triangles, 0.5),
        memoryMb = Stats:GetTotalMemoryUsageMb(),
    }
end

local function run()
    local loading = {}
    for _, group in { roster, props } do
        for _, obj in group:GetDescendants() do
            if obj:IsA("MeshPart") and obj.Transparency < 1 then
                table.insert(loading, obj)
            end
        end
    end
    ContentProvider:PreloadAsync(loading)
    addHunter(1, -1.55)
    task.wait(1.25)
    local single = sample()
    for index = 2, 12 do
        local column = if index <= 6 then 0.5 - index else index - 6.5
        addHunter(index, 3.10 * column)
    end
    task.wait(2)
    return {
        single = single,
        twelve = sample(),
        viewWidth = camera.ViewportSize.X,
        viewHeight = camera.ViewportSize.Y,
    }
end

local ok, result = pcall(run)
if not ok then
    area:Destroy()
    error(result)
end
task.delay(75, function()
    if area.Parent then
        area:Destroy()
    end
end)
return result
