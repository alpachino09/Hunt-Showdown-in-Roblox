--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArmIK = require(ReplicatedStorage.Shared.characters.ArmIK)
local JointPose = require(ReplicatedStorage.Shared.characters.JointPose)
local LanternAnimation = require(ReplicatedStorage.Shared.weapons.LanternAnimation)

local WorldmodelController = {}
local HAND_FLIP = CFrame.Angles(0, math.pi, 0)
local RIGHT = CFrame.Angles(math.rad(75), 0, math.rad(-18)) * HAND_FLIP
local LEFT = CFrame.Angles(math.rad(91), math.rad(-17), math.rad(15)) * HAND_FLIP
local HINGE = CFrame.new(0, -0.023, -0.009)
local HIP = CFrame.new(0.23, -0.02, -0.59) * CFrame.Angles(-0.08, 0.58, -0.10)
local AIM = CFrame.new(0.24, 0.24, -0.60) * CFrame.Angles(0, 0.55, 0)

local function attachment(group: Model, name: string): Attachment
    return assert(group.PrimaryPart, "Missing model origin"):FindFirstChild(name) :: Attachment
end

local function visibility(model: Model): (boolean) -> ()
    local pieces: { [BasePart]: number } = {}
    for _, child in model:GetDescendants() do
        if child:IsA("BasePart") and child ~= model.PrimaryPart then
            pieces[child] = child.Transparency
        end
    end
    local isVisible = true
    return function(shown: boolean)
        if shown ~= isVisible then
            isVisible = shown
            for piece, alpha in pieces do
                piece.Transparency = if shown then alpha else 1
            end
        end
    end
end

function WorldmodelController.bind(character: Model, root: BasePart, container: Folder)
    local prop = ReplicatedStorage.Lantern:Clone()
    prop.Name = character.Name .. "_Lantern"
    local body, barrel = prop.Body, prop.Barrel
    local slide = prop.Extractor
    local live, spent = prop.LiveRound, prop.SpentCase
    local showLive, showSpent = visibility(live), visibility(spent)
    showSpent(false)
    local sight = attachment(body, "Sight")
    local rightGrip, leftGrip = attachment(body, "RightGrip"), attachment(barrel, "LeftGrip")
    local brace = attachment(body, "Brace")
    local chamber, muzzle = attachment(barrel, "Chamber"), attachment(barrel, "Muzzle")

    local flash = Instance.new("Part")
    flash.Name = "MuzzleFlash"
    flash.Shape = Enum.PartType.Ball
    flash.Size = Vector3.new(0.25, 0.22, 0.38)
    flash.Material = Enum.Material.Neon
    flash.Color = Color3.fromRGB(255, 186, 81)
    flash.Transparency = 1
    flash.Anchored, flash.CanCollide, flash.CanTouch, flash.CanQuery = true, false, false, false
    flash.CastShadow = false
    flash.Parent = prop

    local motors: { [string]: Motor6D } = {}
    for _, child in character:GetDescendants() do
        if child:IsA("Motor6D") then
            motors[child.Name] = child
        end
    end
    local right = ArmIK.bind(motors, "Right", "TriggerHand")
    local left = ArmIK.bind(motors, "Left", "SupportHand")
    local previousSpent = false
    local caseDrop: { at: number, frame: CFrame }? = nil

    local function update(now: number, pose: LanternAnimation.Pose, aim: number)
        local chest = JointPose.child(JointPose.child(root.CFrame, motors.Root), motors.Waist)
        local forward = CFrame.new(chest.Position) * root.CFrame.Rotation
        local mount = forward
            * HIP:Lerp(AIM, aim)
            * CFrame.new(-0.05 * pose.open, -0.16 * pose.open, 0.09 * pose.recoil)
            * CFrame.Angles(0.23 * pose.recoil - 0.1 * pose.open, 0, -0.22 * pose.open)
        body:PivotTo(mount)
        barrel:PivotTo(mount * HINGE * CFrame.Angles(-0.78 * pose.open, 0, 0) * HINGE:Inverse())
        slide:PivotTo(chamber.WorldCFrame * CFrame.new(0, 0, 0.11 * pose.slide))

        local leftTarget = leftGrip.WorldPosition:Lerp(brace.WorldPosition, pose.brace)
        local round = chamber.WorldCFrame
        local showHeld = false
        if pose.insert > 0 then
            local pocket = forward * CFrame.new(-0.36, -0.65, -0.24)
            local contact = round * CFrame.new(-0.07, -0.043, 0.04)
            if pose.insert < 0.35 then
                leftTarget = leftTarget:Lerp(pocket.Position, pose.insert / 0.35)
            else
                local reach = math.clamp((pose.insert - 0.35) / 0.65, 0, 1)
                leftTarget = pocket.Position:Lerp(contact.Position, reach)
                round = CFrame.new(leftTarget) * round.Rotation * CFrame.new(0.07, 0.043, -0.04)
                showHeld = true
            end
        end

        local solvedRight = ArmIK.place(
            right,
            chest,
            rightGrip.WorldPosition,
            mount.Rotation * RIGHT,
            forward:VectorToWorldSpace(Vector3.new(0.85, -0.82, 0.12))
        )
        local solvedLeft = ArmIK.place(
            left,
            chest,
            leftTarget,
            mount.Rotation * LEFT,
            forward:VectorToWorldSpace(Vector3.new(-0.85, -0.88, 0.06))
        )
        local leftPalm = solvedLeft:PointToWorldSpace(left.grip.Position)
        if showHeld then
            round += leftPalm - leftTarget
        end
        live:PivotTo(round)
        showLive(pose.loaded or showHeld)

        if previousSpent and not pose.spent then
            caseDrop = { at = now, frame = spent:GetPivot() }
        end
        previousSpent = pose.spent
        if pose.spent then
            caseDrop = nil
            spent:PivotTo(chamber.WorldCFrame * CFrame.new(0, 0, 0.16 * pose.slide))
        elseif caseDrop then
            local elapsed = now - caseDrop.at
            if elapsed > 0.48 then
                caseDrop = nil
            else
                spent:PivotTo(
                    CFrame.new(-0.58 * elapsed, -5 * elapsed * elapsed, 0.25 * elapsed)
                        * caseDrop.frame
                        * CFrame.Angles(elapsed * 7, elapsed * 4, 0)
                )
            end
        end
        showSpent(pose.spent or caseDrop ~= nil)
        flash.CFrame = muzzle.WorldCFrame * CFrame.new(0, 0, -0.13)
        flash.Transparency = if pose.flash then 0.18 else 1
        return (solvedRight:PointToWorldSpace(right.grip.Position) - rightGrip.WorldPosition).Magnitude,
            (leftPalm - leftTarget).Magnitude
    end

    prop.Parent = container
    return { model = prop, sight = sight, update = update }
end

return table.freeze(WorldmodelController)
