--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

assert(RunService:IsStudio(), "debug checks require Studio")
local started = os.clock()
local player = Players.LocalPlayer
local character = assert(player.Character, "character required")
local root = assert(character:FindFirstChild("HumanoidRootPart"), "root required")
local remote = ReplicatedStorage:WaitForChild("MammonsGulchDebugTeleport")
local screen = player.PlayerGui:WaitForChild("MammonsGulchDebug", 15)
assert(screen, "debug GUI missing")
local loadSeconds = os.clock() - started

remote:FireServer("com_i")
remote:FireServer("com_j")
task.wait(0.4)
local first = root.Position
local valid = math.abs(first.X + 164.352) < 5 and math.abs(first.Z - 272.7936) < 5
local cooldownKept = valid
remote:FireServer("not-an-id")
remote:FireServer({ 1, 2, 3 })
task.wait(0.1)
local invalidKept = (root.Position - first).Magnitude < 0.01

local frames, cpu, gpu, drawcalls, triangles = {}, {}, {}, {}, {}
local total = 0
for index = 1, 180 do
    local delta = RunService.PreRender:Wait()
    total += delta
    frames[index] = delta * 1000
    cpu[index] = Stats.RenderCPUFrameTime * 1000
    gpu[index] = Stats.RenderGPUFrameTime * 1000
    drawcalls[index] = Stats.SceneDrawcallCount
    triangles[index] = Stats.SceneTriangleCount
end
for _, values in { frames, cpu, gpu, drawcalls, triangles } do
    table.sort(values)
end
local counts = { parts = 0, meshParts = 0, lights = 0, particles = 0 }
for _, object in Workspace:GetDescendants() do
    if object:IsA("MeshPart") then
        counts.meshParts += 1
    end
    if object:IsA("BasePart") then
        counts.parts += 1
    elseif object:IsA("Light") then
        counts.lights += 1
    elseif object:IsA("ParticleEmitter") then
        counts.particles += 1
    end
end
local result = {
    loadSeconds = loadSeconds,
    validTeleport = valid,
    invalidKept = invalidKept,
    cooldownKept = cooldownKept,
    fps = #frames / total,
    medianMs = frames[90],
    p95Ms = frames[171],
    cpuP95Ms = cpu[171],
    gpuP95Ms = gpu[171],
    drawcalls = drawcalls[90],
    triangles = triangles[90],
    memoryMb = Stats:GetTotalMemoryUsageMb(),
    counts = counts,
}
print(HttpService:JSONEncode(result))
return result
