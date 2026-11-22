--!strict

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local HunterIdle = require(script.Parent.HunterIdle)

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
    local grip = upper:WaitForChild("Grip") :: Model

    local animate = HunterIdle.create(upper, head, grip)
    local player = game:GetService("Players").LocalPlayer
    local movementEnabled = true
    local home = CFrame.lookAt(eye.Position, focus.Position)

    RunService:BindToRenderStep(
        CAMERA_STEP,
        Enum.RenderPriority.Camera.Value + 1,
        function(deltaTime)
            local camera = Workspace.CurrentCamera
            if not camera or player:GetAttribute("RaidPhase") ~= nil then
                return
            end

            camera.CameraType = Enum.CameraType.Scriptable
            camera.FieldOfView = 52
            camera.CFrame = home
            camera.Focus = CFrame.new(focus.Position)

            animate(deltaTime, movementEnabled)
        end
    )

    return function(enabled: boolean)
        movementEnabled = enabled
    end
end

return StationView
