--!strict

local JointPose = require(script.Parent.JointPose)
local ArmIK = {}

export type Arm = {
    shoulder: Motor6D,
    elbow: Motor6D,
    wrist: Motor6D,
    grip: Attachment,
    upper: number,
    lower: number,
}

function ArmIK.bind(motors: { [string]: Motor6D }, side: string, marker: string): Arm
    local shoulder, elbow, wrist =
        motors[side .. "Shoulder"], motors[side .. "Elbow"], motors[side .. "Wrist"]
    local hand = assert(wrist.Part1, "Expected hand mesh")
    return {
        shoulder = shoulder,
        elbow = elbow,
        wrist = wrist,
        grip = hand:WaitForChild(marker) :: Attachment,
        upper = (shoulder.C1.Position - elbow.C0.Position).Magnitude,
        lower = (elbow.C1.Position - wrist.C0.Position).Magnitude,
    }
end

function ArmIK.place(
    armRig: Arm,
    chest: CFrame,
    palm: Vector3,
    orientation: CFrame,
    elbowHint: Vector3
): CFrame
    local shoulder, elbow, wrist = armRig.shoulder, armRig.elbow, armRig.wrist
    local upper = JointPose.child(chest, shoulder)
    local lower = JointPose.child(upper, elbow)
    local shoulderPoint = (chest * shoulder.C0).Position
    local elbowPoint = (upper * elbow.C0).Position
    local target = palm - orientation:VectorToWorldSpace(armRig.grip.Position - wrist.C1.Position)
    local toward = target - shoulderPoint
    local ray = if toward.Magnitude > 1e-5 then toward.Unit else chest.LookVector
    local length = math.clamp(
        toward.Magnitude,
        math.abs(armRig.upper - armRig.lower) + 0.03,
        armRig.upper + armRig.lower - 0.018
    )
    local bend = elbowHint - ray * elbowHint:Dot(ray)
    if bend.Magnitude < 1e-5 then
        local reference = if math.abs(ray.Y) < 0.9 then Vector3.yAxis else Vector3.xAxis
        bend = reference - ray * reference:Dot(ray)
    end
    local plane = bend.Unit
    local along = (length * length + armRig.upper * armRig.upper - armRig.lower * armRig.lower)
        / (2 * length)
    local height = math.sqrt(math.max(0, armRig.upper * armRig.upper - along * along))
    local toElbow = ray * along + plane * height
    JointPose.rotate(shoulder, chest, JointPose.swing(elbowPoint - shoulderPoint, toElbow))

    upper = JointPose.child(chest, shoulder)
    lower = JointPose.child(upper, elbow)
    elbowPoint = (upper * elbow.C0).Position
    local currentWrist = (lower * wrist.C0).Position
    local desiredWrist = shoulderPoint + ray * length
    JointPose.rotate(
        elbow,
        upper,
        JointPose.swing(currentWrist - elbowPoint, desiredWrist - elbowPoint)
    )
    lower = JointPose.child(upper, elbow)
    wrist.Transform = (lower * wrist.C0).Rotation:ToObjectSpace(orientation * wrist.C1.Rotation)
    return JointPose.child(lower, wrist)
end

return table.freeze(ArmIK)
