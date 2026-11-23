--!strict

local ClothPose = {}
type Influence = { bone: Bone, motor: Motor6D, basis: CFrame, strength: number }
local ROTATION_WEIGHT: { [string]: number } = { Bend = 1, Fold = 0.5 }

function ClothPose.bind(character: Model)
    local influences: { Influence } = {}
    for _, side in { "Left", "Right" } do
        for _, joint in { "Knee", "Elbow" } do
            local name = side .. joint .. "Cloth"
            local kind = if joint == "Knee" then name else "ElbowCloth"
            local wrap = character:FindFirstChild(name, true)
            local motor = character:FindFirstChild(side .. joint, true)
            local parent = if wrap then wrap:FindFirstChild(kind .. "Parent") else nil
            if parent and parent:IsA("Bone") and motor and motor:IsA("Motor6D") then
                for label, strength in ROTATION_WEIGHT do
                    local bone = parent:FindFirstChild(kind .. label)
                    if bone and bone:IsA("Bone") then
                        local basis = (parent.CFrame * bone.CFrame).Rotation
                        table.insert(
                            influences,
                            { bone = bone, motor = motor, basis = basis, strength = strength }
                        )
                    end
                end
            end
        end
    end
    return function()
        for _, hinge in influences do
            local motor = hinge.motor
            local pivot = motor.C0.Rotation
            local turn = pivot * motor.Transform.Rotation * pivot:Inverse()
            local offset = hinge.basis:ToObjectSpace(turn * hinge.basis)
            hinge.bone.Transform = offset:Lerp(CFrame.identity, 1 - hinge.strength)
        end
    end
end

return ClothPose
