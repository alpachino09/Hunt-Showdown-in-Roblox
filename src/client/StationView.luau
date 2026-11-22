--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local HunterIdle = require(script.Parent.HunterIdle)
local StationCamera = require(script.Parent.StationCamera)

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
    local lamp = station
        :WaitForChild("Environment")
        :WaitForChild("TracksideProps")
        :WaitForChild("SignalLamp")
        :WaitForChild("Mantle")
        :WaitForChild("Light") :: PointLight

    local animate = HunterIdle.create(upper, head, grip)
    local player = Players.LocalPlayer
    local movementEnabled = true
    local lampBrightness = lamp.Brightness
    local time = 0
    local controlledCamera: Camera? = nil
    local priorFov = 70
    local lastSize = Vector2.zero
    local home = CFrame.identity
    local fov = priorFov

    RunService:BindToRenderStep(
        CAMERA_STEP,
        Enum.RenderPriority.Camera.Value + 1,
        function(deltaTime)
            local camera = Workspace.CurrentCamera
            if not camera or player:GetAttribute("RaidPhase") ~= nil then
                if controlledCamera then
                    controlledCamera.FieldOfView = priorFov
                    controlledCamera = nil
                    animate(0, false)
                    lamp.Brightness = lampBrightness
                end
                return
            end

            if controlledCamera ~= camera then
                controlledCamera = camera
                priorFov = camera.FieldOfView
                lastSize = Vector2.zero
            end
            local size = camera.ViewportSize
            if size ~= lastSize then
                lastSize = size
                home, fov = StationCamera.frame(eye.Position, focus.Position, size)
            end

            camera.CameraType = Enum.CameraType.Scriptable
            camera.FieldOfView = fov
            camera.Focus = focus.CFrame
            if movementEnabled then
                time += deltaTime
                camera.CFrame = home
                    * CFrame.new(math.sin(time * 0.31) * 0.034, math.sin(time * 0.22) * 0.019, 0)
                lamp.Brightness = lampBrightness * (1 + 0.065 * math.noise(time * 1.6))
            else
                camera.CFrame = home
                lamp.Brightness = lampBrightness
            end
            animate(deltaTime, movementEnabled)
        end
    )

    return function(enabled: boolean)
        movementEnabled = enabled
    end
end

return StationView
