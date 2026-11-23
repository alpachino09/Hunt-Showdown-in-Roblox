--!strict
-- Run in the client Command Bar of GreyOutpost-HunterLab during Solo Play.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

assert(game.PlaceId == 0 and Workspace:FindFirstChild("HunterLab"), "Use the local HunterLab")
local player = Players.LocalPlayer
local character = assert(player.Character, "The Veteran has not spawned")
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local root = character:WaitForChild("HumanoidRootPart") :: BasePart
local costume = character:WaitForChild("Costume")
local soles = {
    costume:WaitForChild("LeftSole") :: BasePart,
    costume:WaitForChild("RightSole") :: BasePart,
}

local filter = RaycastParams.new()
filter.FilterType = Enum.RaycastFilterType.Exclude
filter.FilterDescendantsInstances = { character }
filter.RespectCanCollide = true

local function quantile(values: { number }, percentile: number): number?
    if #values == 0 then
        return nil
    end
    return values[math.ceil(#values * percentile)]
end

local function route(position: Vector3, direction: Vector3, duration: number)
    local binding = "HunterGroundCheck"
    character:PivotTo(CFrame.lookAt(position, position + direction))
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.22)
    RunService:BindToRenderStep(binding, Enum.RenderPriority.Input.Value + 5, function()
        humanoid:Move(direction, false)
    end)

    local elapsed, samples, nearGround = 0, 0, 0
    local low = math.huge
    local speeds: { number } = {}
    local contact: { [number]: Vector2 } = {}
    local mats: { [string]: boolean } = {}

    while elapsed < duration do
        local step = RunService.RenderStepped:Wait()
        elapsed += step
        if elapsed > 0.42 and root.AssemblyLinearVelocity.Magnitude > 2 then
            for index, sole in soles do
                local point = sole.CFrame:PointToWorldSpace(Vector3.new(0, -sole.Size.Y / 2, 0))
                local hit =
                    Workspace:Raycast(point + Vector3.yAxis * 1.1, -Vector3.yAxis * 2.10, filter)
                if hit then
                    mats[hit.Instance.Name] = true
                    local clearance = point.Y - hit.Position.Y
                    samples += 1
                    low = math.min(low, clearance)
                    if math.abs(clearance) < 0.075 then
                        nearGround += 1
                        local planar = Vector2.new(point.X, point.Z)
                        local before = contact[index]
                        if before and step > 0 then
                            table.insert(speeds, (planar - before).Magnitude / step)
                        end
                        contact[index] = planar
                    else
                        contact[index] = nil
                    end
                else
                    contact[index] = nil
                end
            end
        end
    end
    RunService:UnbindFromRenderStep(binding)
    humanoid:Move(Vector3.zero, false)
    table.sort(speeds)
    return {
        samples = samples,
        nearGround = nearGround,
        minClearance = low,
        medianSlip = quantile(speeds, 0.5),
        p90Slip = quantile(speeds, 0.9),
        destination = tostring(root.Position),
        surfaces = mats,
    }
end

return {
    floor = route(Vector3.new(0, 2.97, 18), -Vector3.zAxis, 3),
    ramp = route(Vector3.new(-17.7, 3.45, -8), Vector3.xAxis, 2.5),
    stairs = route(Vector3.new(9, 2.97, -5), -Vector3.zAxis, 2.5),
}
