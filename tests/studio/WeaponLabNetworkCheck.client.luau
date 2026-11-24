local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
    return
end

local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local player = Players.LocalPlayer
local ack = Storage:WaitForChild("WeaponLabNetworkAck", 14)
if not ack then
    return
end
local input = Storage:WaitForChild("WeaponLabInput", 5)

local function snapshot(owner)
    local character = owner.Character
    local value = character and character:GetAttribute("LanternState")
    return value and Http:JSONDecode(value)
end

local function waitFor(label, predicate, seconds)
    local deadline = os.clock() + (seconds or 16)
    repeat
        local result = predicate()
        if result then
            return result
        end
        task.wait(0.018)
    until os.clock() >= deadline
    error(label)
end

local shooterId = waitFor("Missing shooter ID", function()
    return workspace:GetAttribute("WeaponLabNetworkShooter")
end, 62)

local ok, result = pcall(function()
    if player.UserId == shooterId then
        waitFor("Missing start signal", function()
            return player:GetAttribute("WeaponLabNetworkStart")
        end)
        input:FireServer("Fire")
        waitFor("Local shot not confirmed", function()
            return snapshot(player).chamber == "Spent"
        end)
        task.wait(0.12)
        input:FireServer("Reload")
        waitFor("Open phase not confirmed", function()
            local action = snapshot(player).reload
            return action and action.stage == "Open"
        end)
        task.wait(0.10)
        input:FireServer("Cancel")
        waitFor("Cancel not confirmed", function()
            local state = snapshot(player)
            return state.reload and state.reload.stage == "Close" and state.chamber == "Spent"
        end)
        waitFor("Cancel closure not finished", function()
            local state = snapshot(player)
            return not state.reload and state.loaded == 0 and state.reserve == 8
        end)
        input:FireServer("Reload")
        waitFor("Full reload not confirmed", function()
            local state = snapshot(player)
            return not state.reload and state.loaded == 1 and state.reserve == 7
        end)
        return true
    end

    local shooter = waitFor("Shooter not visible on client", function()
        return Players:GetPlayerByUserId(shooterId)
    end)
    local world = workspace:WaitForChild("WeaponLabWorldmodels", 6)
    local prop = waitFor("Observer has no rendered TPP model", function()
        return world:FindFirstChild(shooter.Name .. "_Lantern")
    end)
    assert(
        Players.LocalPlayer.Character ~= shooter.Character,
        "Expected a different observed character"
    )

    local seen = { pitch = 0, roundTravel = 0, roundVisible = false }
    ack:FireServer("ready", true)
    waitFor("Observer did not see reload finish", function()
        local state = snapshot(shooter)
        local own = snapshot(player)
        assert(
            own and own.loaded == 1 and own.reserve == 8,
            "Other player's actions changed observer ammo"
        )
        if not state then
            return false
        end
        if state.reload then
            local stage = state.reload.stage
            if stage == "Open" then
                seen.open = true
            elseif stage == "Eject" then
                seen.eject = true
            elseif stage == "Insert" then
                seen.insert = true
                local position = prop.LiveRound:GetPivot().Position
                local chamber = prop.Barrel.Origin.Chamber.WorldPosition
                if prop.LiveRound.Sleeve.Transparency < 1 then
                    seen.roundVisible = true
                    seen.roundTravel = math.max(seen.roundTravel, (position - chamber).Magnitude)
                end
            elseif stage == "Close" then
                if state.chamber == "Spent" then
                    seen.canceled = true
                elseif state.chamber == "Live" then
                    seen.closed = true
                end
            end
            local pitch = prop.Body:GetPivot():ToObjectSpace(prop.Barrel:GetPivot()):ToOrientation()
            seen.pitch = math.max(seen.pitch, math.abs(pitch))
        end
        return not state.reload and state.loaded == 1 and state.reserve == 7
    end)
    return seen
end)
ack:FireServer("finished", if ok then result else "FAIL: " .. tostring(result))
