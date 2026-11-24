--!strict

local DebugVisibility = {}

function DebugVisibility.applyBounds(compounds: Instance, alpha: number)
    for _, compound in compounds:GetChildren() do
        local boundary = compound:FindFirstChild("RegionBoundary")
        if boundary then
            for _, object in boundary:GetDescendants() do
                if object:IsA("BasePart") then
                    object.LocalTransparencyModifier = alpha
                end
            end
        end
    end
end

return DebugVisibility
