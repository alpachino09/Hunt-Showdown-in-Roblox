--!strict

local BASE_FOV = 44
local MAX_FOV = 62
local MIN_HORIZONTAL_FOV = 36
local SUBJECT_OFFSET = 0.38

local StationCamera = {}

function StationCamera.frame(eye: Vector3, focus: Vector3, size: Vector2): (CFrame, number)
    local aspect = if size.X > 0 and size.Y > 0 then size.X / size.Y else 16 / 9
    local narrowFov = math.deg(2 * math.atan(math.tan(math.rad(MIN_HORIZONTAL_FOV / 2)) / aspect))
    local verticalFov = math.clamp(narrowFov, BASE_FOV, MAX_FOV)
    local horizontalHalfAngle = math.tan(math.rad(verticalFov / 2)) * aspect
    local yaw = math.atan(horizontalHalfAngle * SUBJECT_OFFSET)

    return CFrame.lookAt(eye, focus) * CFrame.Angles(0, yaw, 0), verticalFov
end

return StationCamera
