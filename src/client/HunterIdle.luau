--!strict

local HunterIdle = {}

local SECONDS_TO_FIRST_GESTURE = 4.5
local GESTURE_LENGTHS = { 3.35, 2.65, 4.15 }

function HunterIdle.create(upper: Model, head: Model, grip: Model)
    local rest = upper:GetPivot()
    local headRest = rest:ToObjectSpace(head:GetPivot())
    local gripRest = rest:ToObjectSpace(grip:GetPivot())
    local random = Random.new()

    local time = 0
    local gestureStart = SECONDS_TO_FIRST_GESTURE
    local gesture = 1
    local direction = 1
    local active = false

    return function(deltaTime: number, enabled: boolean)
        if not enabled then
            if active then
                upper:PivotTo(rest)
                head:PivotTo(rest * headRest)
                grip:PivotTo(rest * gripRest)
                gestureStart = time + SECONDS_TO_FIRST_GESTURE
                active = false
            end
            return
        end

        active = true
        time += deltaTime
        local breath = math.sin(time * 1.52)
        local duration = GESTURE_LENGTHS[gesture]
        if time >= gestureStart + duration then
            gesture = (gesture + random:NextInteger(0, #GESTURE_LENGTHS - 2)) % #GESTURE_LENGTHS + 1
            direction = if random:NextNumber() < 0.5 then -1 else 1
            gestureStart = time + random:NextNumber(7.5, 12)
        end

        -- Each gesture leaves and returns to the breathing pose with zero velocity.
        local progress = math.clamp((time - gestureStart) / duration, 0, 1)
        local weight = math.sin(math.pi * progress) ^ 2
        local glance = if gesture == 1 then weight * direction else 0
        local adjust = if gesture == 2 then weight else 0
        local shift = if gesture == 3 then weight * direction else 0
        local torso = rest
            * CFrame.new(shift * 0.044, 0.017 * breath, 0)
            * CFrame.Angles(math.rad(breath * 0.38), math.rad(shift * 1.25), math.rad(shift * 1.4))
        upper:PivotTo(torso)
        head:PivotTo(
            torso
                * headRest
                * CFrame.Angles(math.rad(-adjust * 3 - breath * 0.38), math.rad(glance * 13), 0)
        )
        grip:PivotTo(
            torso * gripRest * CFrame.Angles(math.rad(adjust * -2.7 + breath * 0.31), 0, 0)
        )
    end
end

return HunterIdle
