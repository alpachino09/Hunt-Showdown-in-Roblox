--!strict

local ArmIK = require(script.Parent.ArmIK)
local JointPose = require(script.Parent.JointPose)

export type Slot = "None" | "Rifle" | "Pistol"
export type Gesture = "Fire" | "Reload"
export type Controller = {
    equip: (Slot) -> (),
    play: (Gesture) -> (),
    update: (number, boolean) -> (),
}

local WeaponPose = {}
local TURNED_MESH = CFrame.Angles(0, math.pi, 0)

local HOLD = {
    Rifle = CFrame.new(0.13, -0.33, -0.69) * CFrame.Angles(math.rad(-13), math.rad(74), 0),
    Pistol = CFrame.new(0.75, -0.51, -0.56) * CFrame.Angles(math.rad(-34), math.rad(5), 0),
}
local AIM = {
    Rifle = CFrame.new(0.155, 0.47, -0.79) * CFrame.Angles(math.rad(3), math.rad(47), 0),
    Pistol = CFrame.new(0.48, 0.29, -0.98) * CFrame.Angles(math.rad(3), math.rad(12), 0),
}
local RIGHT_HAND = CFrame.Angles(math.rad(75), 0, math.rad(-23)) * TURNED_MESH
local LEFT_HAND = CFrame.Angles(math.rad(102), math.rad(-20), math.rad(20)) * TURNED_MESH

function WeaponPose.bind(character: Model, root: BasePart, assets: Folder): Controller
    local scale = character:GetScale()
    local motors: { [string]: Motor6D } = {}
    for _, obj in character:GetDescendants() do
        if obj:IsA("Motor6D") then
            motors[obj.Name] = obj
        end
    end
    local left = ArmIK.bind(motors, "Left", "SupportHand")
    local right = ArmIK.bind(motors, "Right", "TriggerHand")
    local weapon: Model? = nil
    local support: Attachment? = nil
    local handToMount = CFrame.new(right.grip.Position) * RIGHT_HAND:Inverse()
    local slot: Slot = "None"
    local aim = 0
    local elapsed = 0
    local gesture: Gesture? = nil

    local function equip(value: Slot)
        if value == slot then
            return
        end
        if weapon then
            weapon:Destroy()
            weapon = nil
        end
        slot, gesture, support = value, nil, nil
        character:SetAttribute("WeaponPose", value)
        if value == "None" then
            return
        end
        local prop = (assets:WaitForChild(value) :: Model):Clone()
        prop:ScaleTo(scale)
        local mount = assert(prop.PrimaryPart, "Expected a prop mount")
        local hand = assert(right.wrist.Part1, "Expected right hand")
        local weld = Instance.new("Weld")
        weld.Name = "HandMount"
        weld.Part0, weld.Part1 = hand, mount
        weld.C0 = handToMount
        prop:PivotTo(hand.CFrame * weld.C0)
        weld.Parent = mount
        support = mount:FindFirstChild("Support") :: Attachment?
        prop.Parent = character
        weapon = prop
    end

    local function play(value: Gesture)
        if slot ~= "None" and not gesture then
            elapsed, gesture = 0, value
        end
    end

    local function update(delta: number, aiming: boolean)
        if slot == "None" then
            return
        end
        aim += ((if aiming then 1 else 0) - aim) * (1 - math.exp(
            -delta * (if aiming then 16 else 12)
        ))
        local recoil, reload = 0, 0
        if gesture then
            elapsed += delta
            local duration = if gesture == "Fire" then 0.31 else 1.04
            if elapsed >= duration then
                gesture = nil
            elseif gesture == "Fire" then
                recoil = math.sin(math.pi * math.min(elapsed / duration, 1)) ^ 2
                    * math.exp(-3 * elapsed)
            else
                reload = math.sin(math.pi * elapsed / duration) ^ 2
            end
        end
        local pelvis = JointPose.child(root.CFrame, motors.Root)
        local yaw = if slot == "Rifle" then math.rad(-46) else math.rad(-12)
        local waist = motors.Waist
        waist.Transform = CFrame.Angles(0, yaw * (0.20 + 0.80 * aim), 0)
            * waist.Transform:Lerp(CFrame.identity, 0.38)
        local neck = motors.Neck
        neck.Transform = CFrame.Angles(0, -yaw * aim, 0) * neck.Transform
        local chest = JointPose.child(pelvis, waist)
        local body = chest * TURNED_MESH
        local hold = HOLD[slot]:Lerp(AIM[slot], aim)
        local kick = CFrame.new(0, -0.18 * reload, 0.13 * recoil)
            * CFrame.Angles(0.29 * recoil - 0.30 * reload, 0, 0.34 * reload)
        local localTarget = hold * kick
        local target = body * CFrame.new(localTarget.Position * scale) * localTarget.Rotation
        local rightHand = ArmIK.place(
            right,
            chest,
            target.Position,
            target.Rotation * RIGHT_HAND,
            body:VectorToWorldSpace(Vector3.new(0.75, -0.8, 0.12))
        )
        if support then
            local propFrame = rightHand * handToMount
            local grip = propFrame * support.CFrame
            local handTarget = grip.Position:Lerp(
                body:PointToWorldSpace(Vector3.new(-0.38, -0.57, -0.59) * scale),
                reload
            )
            ArmIK.place(
                left,
                chest,
                handTarget,
                propFrame.Rotation * LEFT_HAND,
                body:VectorToWorldSpace(Vector3.new(-0.85, -0.92, 0.04))
            )
        end
        local label = slot .. (gesture or (if aiming then "Aim" else "Idle"))
        if character:GetAttribute("WeaponPose") ~= label then
            character:SetAttribute("WeaponPose", label)
        end
    end

    return { equip = equip, play = play, update = update }
end

return WeaponPose
