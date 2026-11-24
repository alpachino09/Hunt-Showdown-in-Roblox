--!strict

local RunService = game:GetService("RunService")

local DebugConfig = {}
DebugConfig.enabled = RunService:IsStudio()
DebugConfig.remoteName = "MammonsGulchDebugTeleport"

return DebugConfig
