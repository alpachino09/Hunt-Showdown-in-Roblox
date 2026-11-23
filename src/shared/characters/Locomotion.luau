--!strict

local HttpService = game:GetService("HttpService")
local FootPlant = require(script.Parent.FootPlant)

export type ClipName =
    "Idle"
    | "Walk"
    | "Jog"
    | "Sprint"
    | "CrouchIdle"
    | "CrouchWalk"
    | "Jump"
    | "Air"
    | "Land"
    | "ReachInteract"
    | "TablePickup"
    | "KneelInspect"
export type Mode = "Walk" | "Jog" | "Sprint" | "Crouch"

type Clip = {
    duration: number,
    loop: boolean,
    frames: { { CFrame } },
    contact: { { number } },
}

type Library = {
    joints: { string },
    clips: { [ClipName]: Clip },
}

type RawClip = {
    duration: number,
    loop: boolean,
    frames: { { number } },
    contact: { { number } },
}

local Locomotion = {}
local FADE = 0.17
local MIN_SPEED = 0.45

Locomotion.speed = table.freeze({
    Walk = 4.65,
    Jog = 8.75,
    Sprint = 13,
    Crouch = 2.55,
})

local GAIT_PACE = table.freeze({ Walk = 3.4, Jog = 7.1, Sprint = 9.8, Crouch = 2.15 })

local MOVE_CLIPS: { [ClipName]: Mode } = {
    Walk = "Walk",
    Jog = "Jog",
    Sprint = "Sprint",
    CrouchWalk = "Crouch",
}

function Locomotion.decode(data: Folder): Library
    local jointList = data:WaitForChild("Joints") :: StringValue
    local joints = HttpService:JSONDecode(jointList.Value) :: { string }
    local clips = {} :: { [ClipName]: Clip }
    for _, value in data:GetChildren() do
        if value == jointList or not value:IsA("StringValue") then
            continue
        end
        local spec = HttpService:JSONDecode(value.Value) :: RawClip
        local frames: { { CFrame } } = {}
        for index, encoded in spec.frames do
            local frame: { CFrame } = {}
            for joint = 1, #joints do
                local offset = (joint - 1) * 4 + 2
                local y = if joint == 1 then encoded[1] else 0
                frame[joint] = CFrame.new(
                    0,
                    y,
                    0,
                    encoded[offset],
                    encoded[offset + 1],
                    encoded[offset + 2],
                    encoded[offset + 3]
                )
            end
            frames[index] = frame
        end
        clips[value.Name :: ClipName] = {
            duration = spec.duration,
            loop = spec.loop,
            frames = frames,
            contact = spec.contact,
        }
    end
    return { joints = joints, clips = clips }
end

local function window(clip: Clip, time: number): (number, number, number)
    local count = #clip.frames
    local position = math.clamp(time / clip.duration, 0, 1) * (count - 1)
    local first = math.floor(position) + 1
    return first, math.min(first + 1, count), position % 1
end

function Locomotion.bind(
    character: Model,
    humanoid: Humanoid,
    root: BasePart,
    library: Library,
    idleLean: number?,
    fixedIdle: boolean?
)
    local motors: { [string]: Motor6D } = {}
    for _, obj in character:GetDescendants() do
        if obj:IsA("Motor6D") then
            motors[obj.Name] = obj
        end
    end

    local joints: { Motor6D } = {}
    for index, name in library.joints do
        joints[index] = assert(motors[name], name)
    end
    local leftHem, rightHem = motors.LeftHem, motors.RightHem
    local plant = if fixedIdle then nil else FootPlant.bind(character, root, motors)
    local scale = character:GetScale()
    local output = table.create(#joints, CFrame.identity) :: { CFrame }
    local before = table.clone(output)
    local active: ClipName = "Idle"
    local clock = 0
    local fadeAge = FADE
    local inAir = false
    character:SetAttribute("MotionClip", active)

    local function changeClip(name: ClipName)
        if active == name then
            return
        end
        before = table.clone(output)
        local oldClip, newClip = library.clips[active], library.clips[name]
        local keepPhase = MOVE_CLIPS[active] ~= nil and MOVE_CLIPS[name] ~= nil
        clock = if keepPhase then (clock / oldClip.duration) * newClip.duration else 0
        active = name
        fadeAge = 0
        character:SetAttribute("MotionClip", active)
    end

    return function(delta: number, mode: Mode, preview: ClipName?)
        local velocity = root.AssemblyLinearVelocity
        local speed = if fixedIdle then 0 else Vector2.new(velocity.X, velocity.Z).Magnitude
        local state = if fixedIdle then nil else humanoid:GetState()
        local flying = state == Enum.HumanoidStateType.Jumping
            or state == Enum.HumanoidStateType.Freefall
        if preview then
            changeClip(preview)
        elseif flying then
            if not inAir then
                changeClip(if state == Enum.HumanoidStateType.Jumping then "Jump" else "Air")
            elseif active == "Jump" and clock >= 0.21 then
                changeClip("Air")
            end
        elseif inAir then
            changeClip("Land")
        elseif active ~= "Land" or clock >= 0.57 then
            if mode == "Crouch" then
                changeClip(if speed > MIN_SPEED then "CrouchWalk" else "CrouchIdle")
            else
                changeClip(if speed > MIN_SPEED then mode else "Idle")
            end
        end
        inAir = not preview and flying

        local clip = library.clips[active]
        local movement = MOVE_CLIPS[active]
        local rate = if preview
            then 1
            elseif movement then math.clamp(speed / GAIT_PACE[movement], 0.45, 1.75)
            elseif active == "Land" then 1.45
            else 1
        clock += delta * rate
        clock = if clip.loop then clock % clip.duration else math.min(clock, clip.duration)
        fadeAge = math.min(FADE, fadeAge + delta)
        local t = fadeAge / FADE
        local ease = t * t * (3 - 2 * t)
        local first, second, fraction = window(clip, clock)
        for index, joint in joints do
            local sample = clip.frames[first][index]:Lerp(clip.frames[second][index], fraction)
            if index == 1 and scale ~= 1 then
                sample = CFrame.new(sample.Position * scale) * sample.Rotation
            end
            local blended = before[index]:Lerp(sample, ease)
            joint.Transform = blended
            output[index] = blended
        end
        if idleLean and active == "Idle" then
            motors.Waist.Transform *= CFrame.Angles(idleLean * ease, 0, 0)
        end

        local a, b = clip.contact[first], clip.contact[second]
        local supportedLeft, supportedRight = false, false
        if plant and not preview then
            supportedLeft, supportedRight = plant(
                delta,
                (a[1] + (b[1] - a[1]) * fraction) * ease,
                (a[2] + (b[2] - a[2]) * fraction) * ease,
                not flying
            )
        end

        local leftHip = motors.LeftHip.Transform:ToOrientation()
        local rightHip = motors.RightHip.Transform:ToOrientation()
        local sway = movement
                and math.sin(clock / clip.duration * math.pi * 2) * math.rad(
                    math.min(speed * 0.68, 9)
                )
            or 0
        if leftHem and rightHem then
            local fold = if mode == "Crouch" then 0.58 else 0.30
            leftHem.Transform =
                CFrame.Angles(math.clamp(leftHip * fold + sway, -0.55, 0.53), 0, math.rad(4))
            rightHem.Transform =
                CFrame.Angles(math.clamp(rightHip * fold - sway, -0.55, 0.53), 0, math.rad(-4))
        end
        return supportedLeft, supportedRight
    end
end

return Locomotion
