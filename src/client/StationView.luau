--!strict

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local StationView = {}
local CAMERA_STEP = "GreyOutpostStationCamera"

function StationView.start()
    local station = Workspace:WaitForChild("Station")
    local markers = station:WaitForChild("CameraMarkers")
    local eye = markers:WaitForChild("Eye") :: BasePart
    local focus = markers:WaitForChild("Focus") :: BasePart

    local hunter = station:WaitForChild("DisplayHunter")
    local upper = hunter:WaitForChild("UpperBody") :: Model
    local head = upper:WaitForChild("Head") :: Model
    local left = upper:WaitForChild("LeftSleeve") :: Model
    local right = upper:WaitForChild("RightSleeve") :: Model

    local rest = upper:GetPivot()
    local headRest = rest:ToObjectSpace(head:GetPivot())
    local leftRest = rest:ToObjectSpace(left:GetPivot())
    local rightRest = rest:ToObjectSpace(right:GetPivot())

    local started = os.clock()
    local player = game:GetService("Players").LocalPlayer
    local movementEnabled = true
    local wasAnimated = false
    local home = CFrame.lookAt(eye.Position, focus.Position)

    RunService:BindToRenderStep(CAMERA_STEP, Enum.RenderPriority.Camera.Value + 1, function()
        local camera = Workspace.CurrentCamera
        if not camera or player:GetAttribute("RaidPhase") ~= nil then
            return
        end

        camera.CameraType = Enum.CameraType.Scriptable
        camera.FieldOfView = 52
        camera.CFrame = home
        camera.Focus = CFrame.new(focus.Position)

        if movementEnabled then
            local time = os.clock() - started
            local breath = math.sin(time * 1.7)
            local glance = math.sin(time * 0.6)
            local posture = rest
                * CFrame.new(0, 0.035 * breath, 0)
                * CFrame.Angles(0, math.rad(2 * glance), math.rad(1.2 * breath))
            upper:PivotTo(posture)
            head:PivotTo(posture * headRest * CFrame.Angles(0, math.rad(11 * glance), 0))
            left:PivotTo(posture * leftRest * CFrame.Angles(math.rad(3 * breath), 0, 0))
            right:PivotTo(posture * rightRest * CFrame.Angles(math.rad(-4 * breath), 0, 0))
            wasAnimated = true
        elseif wasAnimated then
            upper:PivotTo(rest)
            head:PivotTo(rest * headRest)
            left:PivotTo(rest * leftRest)
            right:PivotTo(rest * rightRest)
            wasAnimated = false
        end
    end)

    return function(enabled: boolean)
        movementEnabled = enabled
    end
end

return StationView
