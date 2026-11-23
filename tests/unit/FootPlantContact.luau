local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local Vector2 = roblox.Vector2
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local currentSurface
local workspaceMock = {}

function workspaceMock:Raycast(origin, direction)
    local height, normal, surface = currentSurface(origin.X, origin.Z)
    local travel = (origin.Y - height) / -direction.Y
    if travel < 0 or travel > 1 then
        return nil
    end
    return {
        Position = Vector3.new(origin.X, height, origin.Z),
        Normal = normal,
        Instance = surface,
    }
end

local gameMock = {
    GetService = function(_, name)
        assert(name == "Workspace", "Unexpected service")
        return workspaceMock
    end,
}

local function loadModule(path)
    local environment = {
        Vector2 = Vector2,
        Vector3 = Vector3,
        CFrame = CFrame,
        Enum = roblox.Enum,
        RaycastParams = {
            new = function()
                return {}
            end,
        },
        game = gameMock,
        script = { Parent = { JointPose = "JointPose" } },
    }
    environment.require = function(target)
        assert(target == "JointPose", "Unexpected module")
        return loadModule("src/shared/characters/JointPose.luau")
    end
    return luau.load(fs.readFile(path), {
        debugName = path,
        environment = environment,
    })()
end

local FootPlant = loadModule("src/shared/characters/FootPlant.luau")
local UP = Vector3.yAxis
local STEP = 1 / 60
local SPEED = 4.65
local FRAMES = 180

local function joint(c0, part)
    return {
        C0 = c0 or CFrame.identity,
        C1 = CFrame.identity,
        Transform = CFrame.identity,
        Part1 = part,
    }
end

local function downstream(frame, motor)
    return frame * motor.C0 * motor.Transform * motor.C1:Inverse()
end

local function quantile(values, percentile)
    table.sort(values)
    return values[math.ceil(#values * percentile)] or math.huge
end

local function run(surface, name)
    currentSurface = surface
    local root = {
        CFrame = CFrame.new(0, 2.1, 0),
        AssemblyLinearVelocity = Vector3.new(SPEED, 0, 0),
    }
    local character = {
        FindFirstChild = function()
            return nil
        end,
    }
    local motors = { Root = joint() }
    for _, side in { "Left", "Right" } do
        local foot = { CFrame = CFrame.identity, Size = Vector3.new(0.4, 0.2, 0.8) }
        motors[side .. "Hip"] = joint(CFrame.new(if side == "Left" then -0.25 else 0.25, 0, 0))
        motors[side .. "Knee"] = joint(CFrame.new(0, -1, 0))
        motors[side .. "Ankle"] = joint(CFrame.new(0, -1, 0), foot)
    end
    local plant = FootPlant.bind(character, root, motors)
    local previousPoints = {}
    local previousSurfaces = {}
    local previousSupport = { false, false }
    local slip = { {}, {} }

    for _ = 1, FRAMES do
        local x = root.CFrame.X + SPEED * STEP
        local height = surface(x, 0)
        root.CFrame = CFrame.new(x, height + 2.1, 0)
        local nextHeight = surface(x + 0.01, 0)
        local slope = (nextHeight - height) / 0.01
        root.AssemblyLinearVelocity = Vector3.new(SPEED, slope * SPEED, 0)
        local supported = { plant(STEP, 1, 1, true) }
        for index, side in { "Left", "Right" } do
            local pelvis = downstream(root.CFrame, motors.Root)
            local upper = downstream(pelvis, motors[side .. "Hip"])
            local lower = downstream(upper, motors[side .. "Knee"])
            local foot = downstream(lower, motors[side .. "Ankle"])
            local point = foot:PointToWorldSpace(Vector3.new(0, -0.1, 0))
            local planar = Vector2.new(point.X, point.Z)
            local _, _, ground = surface(point.X, point.Z)
            if
                previousSupport[index]
                and supported[index]
                and previousSurfaces[index] == ground
                and previousPoints[index]
            then
                table.insert(slip[index], (planar - previousPoints[index]).Magnitude / STEP)
            end
            previousPoints[index] = planar
            previousSurfaces[index] = ground
            previousSupport[index] = supported[index]
        end
    end

    local left = quantile(slip[1], 0.9)
    local right = quantile(slip[2], 0.9)
    print(string.format("%s: established-support p90 = %.4f / %.4f stud/s", name, left, right))
    return math.max(left, right)
end

local flatSurface = { Name = "Floor" }
local rampSurface = { Name = "Ramp" }
local stairSurfaces = {}
for index = 0, 8 do
    stairSurfaces[index] = { Name = "Stair" .. index }
end

local failures = {}
local scenarios = {
    {
        name = "floor",
        surface = function()
            return 0, UP, flatSurface
        end,
    },
    {
        name = "ramp",
        surface = function(x)
            local grade = math.tan(math.rad(13))
            return x * grade, Vector3.new(-grade, 1, 0).Unit, rampSurface
        end,
    },
    {
        name = "stairs",
        surface = function(x)
            local index = math.clamp(math.floor(x / 1.4), 0, 8)
            return index * 0.38, UP, stairSurfaces[index]
        end,
    },
}

for _, scenario in scenarios do
    if run(scenario.surface, scenario.name) > 0.05 then
        table.insert(failures, scenario.name)
    end
end
assert(#failures == 0, "Established foot anchors drift on: " .. table.concat(failures, ", "))
