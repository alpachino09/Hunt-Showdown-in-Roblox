--!strict

local JointPose = {}

function JointPose.child(frame: CFrame, joint: Motor6D): CFrame
    return frame * joint.C0 * joint.Transform * joint.C1:Inverse()
end

function JointPose.swing(original: Vector3, target: Vector3): CFrame
    local a, b = original.Unit, target.Unit
    local axis = a:Cross(b)
    local length = axis.Magnitude
    if length > 1e-5 then
        return CFrame.fromAxisAngle(axis / length, math.atan2(length, a:Dot(b)))
    end
    if a:Dot(b) < 0 then
        local up = if math.abs(a.Y) < 0.9 then Vector3.yAxis else Vector3.xAxis
        return CFrame.fromAxisAngle(a:Cross(up).Unit, math.pi)
    end
    return CFrame.identity
end

function JointPose.rotate(joint: Motor6D, parent: CFrame, angle: CFrame)
    local pivot = (parent * joint.C0).Rotation
    local original = joint.Transform
    joint.Transform = CFrame.new(original.Position)
        * pivot:ToObjectSpace(angle * pivot * original.Rotation)
end

return JointPose
