--!strict

local Workspace = game:GetService("Workspace")
local JointPose = require(script.Parent.JointPose)

type Leg = {
    hip: Motor6D,
    knee: Motor6D,
    ankle: Motor6D,
    upper: number,
    lower: number,
    solePoint: Vector3,
    clearanceY: number,
    point: Vector3?,
    surface: Instance?,
    normal: Vector3,
    heading: Vector3,
    strength: number,
}

local FootPlant = {}
local UP = Vector3.yAxis
local EPSILON = 1e-5

local downstream = JointPose.child
local swing = JointPose.swing
local aimJoint = JointPose.rotate

local function sample(leg: Leg, pelvis: CFrame): (Vector3, Vector3, Vector3)
    local upper = downstream(pelvis, leg.hip)
    local lower = downstream(upper, leg.knee)
    return (pelvis * leg.hip.C0).Position,
        (upper * leg.knee.C0).Position,
        (lower * leg.ankle.C0).Position
end

local function bindLeg(character: Model, motors: { [string]: Motor6D }, side: string): Leg
    local hip, knee, ankle = motors[side .. "Hip"], motors[side .. "Knee"], motors[side .. "Ankle"]
    local sole = character:FindFirstChild(side .. "Sole", true) :: BasePart?
    local foot = assert(ankle.Part1, "Expected an R15 foot")
    local solePoint = if sole
        then foot.CFrame:PointToObjectSpace(
            sole.CFrame:PointToWorldSpace(Vector3.new(0, -sole.Size.Y / 2, 0))
        )
        else Vector3.new(0, -foot.Size.Y / 2, 0)
    return {
        hip = hip,
        knee = knee,
        ankle = ankle,
        upper = (hip.C1.Position - knee.C0.Position).Magnitude,
        lower = (knee.C1.Position - ankle.C0.Position).Magnitude,
        solePoint = solePoint,
        clearanceY = -math.huge,
        point = nil,
        surface = nil,
        normal = UP,
        heading = Vector3.zAxis,
        strength = 0,
    }
end

local function floorFrame(leg: Leg): CFrame
    local forward = leg.heading - leg.normal * leg.heading:Dot(leg.normal)
    return CFrame.lookAt(Vector3.zero, forward, leg.normal) * CFrame.Angles(0, math.pi, 0)
end

local function ankleAbove(leg: Leg, point: Vector3, frame: CFrame): Vector3
    return point - frame:VectorToWorldSpace(leg.solePoint - leg.ankle.C1.Position)
end

local function solve(leg: Leg, pelvis: CFrame, heading: Vector3)
    local anchor = leg.point
    if (not anchor or leg.strength < 0.005) and leg.clearanceY == -math.huge then
        return
    end
    local hip, knee, ankle = sample(leg, pelvis)
    local pose = floorFrame(leg)
    local target = if anchor then ankle:Lerp(ankleAbove(leg, anchor, pose), leg.strength) else ankle
    if leg.clearanceY > target.Y then
        target = Vector3.new(target.X, leg.clearanceY, target.Z)
    end
    local toTarget = target - hip
    local actualDistance = toTarget.Magnitude
    if actualDistance < EPSILON then
        return
    end
    local ray = toTarget / actualDistance
    local maxReach = leg.upper + leg.lower - 0.012
    local d = math.clamp(actualDistance, math.abs(leg.upper - leg.lower) + 0.025, maxReach)
    local axis = knee - hip
    local bend = axis - ray * axis:Dot(ray)
    if bend.Magnitude < 0.07 then
        bend = heading - ray * heading:Dot(ray)
        if bend.Magnitude < EPSILON then
            return
        end
    end
    local along = (d * d + leg.upper * leg.upper - leg.lower * leg.lower) / (2 * d)
    local height = math.sqrt(math.max(0, leg.upper * leg.upper - along * along))
    local desiredKnee = hip + ray * along + bend.Unit * height
    local desiredAnkle = hip + ray * d
    aimJoint(leg.hip, pelvis, swing(knee - hip, desiredKnee - hip))

    local upper = downstream(pelvis, leg.hip)
    local lower = downstream(upper, leg.knee)
    local kneeNow = (upper * leg.knee.C0).Position
    local ankleNow = (lower * leg.ankle.C0).Position
    aimJoint(leg.knee, upper, swing(ankleNow - kneeNow, desiredAnkle - kneeNow))

    lower = downstream(upper, leg.knee)
    if anchor then
        local needed = (lower * leg.ankle.C0).Rotation:ToObjectSpace(pose * leg.ankle.C1.Rotation)
        leg.ankle.Transform = leg.ankle.Transform:Lerp(needed, leg.strength)
    end
end

function FootPlant.bind(character: Model, root: BasePart, motors: { [string]: Motor6D })
    local rootJoint = motors.Root
    local legs = {
        bindLeg(character, motors, "Left"),
        bindLeg(character, motors, "Right"),
    }
    local filter = RaycastParams.new()
    filter.FilterType = Enum.RaycastFilterType.Exclude
    filter.FilterDescendantsInstances = { character }
    filter.RespectCanCollide = true
    local descent = 0

    return function(delta: number, left: number, right: number, grounded: boolean)
        local pelvis = downstream(root.CFrame, rootJoint)
        local heading = root.CFrame.LookVector
        local velocity = root.AssemblyLinearVelocity
        local prediction = Vector3.new(velocity.X, 0, velocity.Z) * math.min(delta, 0.065)
        local requestedDrop = 0
        local alpha = 1 - math.exp(-math.max(delta, 0) * 24)
        for index, leg in legs do
            local confidence = if grounded then (if index == 1 then left else right) else 0
            local hip, _, ankle = sample(leg, pelvis)
            local anchor = leg.point
            leg.clearanceY = -math.huge
            local collision: RaycastResult? = nil
            local lift = 0
            if grounded then
                local upper = downstream(pelvis, leg.hip)
                local lower = downstream(upper, leg.knee)
                local rawSole = downstream(lower, leg.ankle):PointToWorldSpace(leg.solePoint)
                local hit = Workspace:Raycast(rawSole + UP * 1.30, -UP * 2.85, filter)
                if hit and hit.Normal.Y > 0.59 then
                    collision = hit
                    lift = hit.Position.Y - rawSole.Y + 0.014
                end
            end
            if anchor then
                local separation = hip - anchor
                local stride = Vector2.new(separation.X, separation.Z).Magnitude
                local changedStep = collision
                    and collision.Instance ~= leg.surface
                    and collision.Position.Y > anchor.Y + 0.12
                    and lift > 0
                if
                    not grounded
                    or confidence < 0.12
                    or leg.heading:Dot(heading) < 0.71
                    or stride > 1.37
                    or changedStep
                then
                    leg.point = nil
                    leg.surface = nil
                    anchor = nil
                end
            end
            if not anchor and collision then
                if confidence >= 0.58 then
                    leg.point = collision.Position
                    leg.surface = collision.Instance
                    leg.normal = collision.Normal
                    leg.heading = heading
                    anchor = leg.point
                end
                if lift > 0 then
                    leg.clearanceY = ankle.Y + math.min(lift, 0.48)
                end
            end
            local intent = if anchor then confidence else 0
            leg.strength += (intent - leg.strength) * alpha
            if anchor then
                local hipOffset = hip - ankleAbove(leg, anchor, floorFrame(leg))
                local stride = Vector2.new(hipOffset.X, hipOffset.Z).Magnitude
                local reach = leg.upper + leg.lower - 0.025
                local allowableY = math.sqrt(math.max(0, reach * reach - stride * stride))
                local shift = math.clamp(hipOffset.Y - allowableY, 0, 0.38)
                requestedDrop = math.max(requestedDrop, shift * leg.strength)
            end
        end
        descent += (requestedDrop - descent) * alpha
        if descent > 0.001 then
            rootJoint.Transform = CFrame.new(0, -descent, 0) * rootJoint.Transform
            pelvis = downstream(root.CFrame, rootJoint)
        end
        for _, leg in legs do
            solve(leg, pelvis, heading)
            if grounded then
                local upper = downstream(pelvis, leg.hip)
                local lower = downstream(upper, leg.knee)
                local correctedSole = downstream(lower, leg.ankle):PointToWorldSpace(leg.solePoint)
                local floor = Workspace:Raycast(correctedSole + UP * 0.72, -UP * 1.42, filter)
                local ahead =
                    Workspace:Raycast(correctedSole + prediction + UP * 0.72, -UP * 1.42, filter)
                if
                    ahead
                    and ahead.Normal.Y > 0.59
                    and (not floor or ahead.Position.Y > floor.Position.Y + 0.065)
                then
                    floor = ahead
                end
                if floor and floor.Normal.Y > 0.59 then
                    local lift = floor.Position.Y - correctedSole.Y
                    if lift > 0.045 then
                        local _, _, correctedAnkle = sample(leg, pelvis)
                        leg.clearanceY = correctedAnkle.Y + math.min(lift + 0.018, 0.48)
                        solve(leg, pelvis, heading)
                    end
                end
            end
        end
    end
end

return FootPlant
