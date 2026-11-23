--!strict

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.Shared.Catalog)

export type Profile = {
    version: number,
    credits: number,
    xp: number,
    hunter: string,
    weapon: string,
    owned: { [string]: boolean },
    receipts: { [string]: number },
}
local store = if RunService:IsStudio()
    then nil
    else DataStoreService:GetDataStore("GreyOutpostProfilesV1")
local profiles: { [Player]: Profile } = {}
local busy: { [Player]: boolean } = {}
local pending = 0
local Profiles = {}

local function decode(raw: any): Profile
    if type(raw) ~= "table" then
        return {
            version = 1,
            credits = 120,
            xp = 0,
            hunter = "reed",
            weapon = "service",
            owned = { service = true },
            receipts = {},
        }
    end
    assert(raw.version == 1, "Unsupported profile version")
    assert(type(raw.credits) == "number" and type(raw.xp) == "number", "Invalid profile counters")
    assert(
        type(raw.owned) == "table" and type(raw.receipts) == "table",
        "Invalid profile collections"
    )
    if not Catalog.hunter(raw.hunter) then
        raw.hunter = "reed"
    end
    if not Catalog.weapon(raw.weapon) or not raw.owned[raw.weapon] then
        raw.weapon = "service"
    end
    raw.owned.service = true
    return raw
end

local function display(player: Player, data: Profile)
    player:SetAttribute("HunterId", data.hunter)
    player:SetAttribute("WeaponId", data.weapon)
    player:SetAttribute("Credits", data.credits)
    player:SetAttribute("Experience", data.xp)
    player:SetAttribute("OwnsCarbine", data.owned.ridge == true)
end

function Profiles.load(player: Player)
    local ok, data = pcall(function()
        return decode(if store then store:GetAsync(tostring(player.UserId)) else nil)
    end)
    if ok and player.Parent then
        profiles[player] = data
        display(player, data)
        player:SetAttribute("ProfileReady", true)
    elseif player.Parent then
        player:SetAttribute(
            "LobbyMessage",
            "Профиль недоступен. Перезайдите, чтобы повторить загрузку."
        )
    end
end

function Profiles.get(player: Player): Profile?
    return profiles[player]
end

function Profiles.drop(player: Player)
    profiles[player] = nil
end

function Profiles.change(player: Player, transform: (Profile) -> boolean): (boolean, string?)
    local current = profiles[player]
    if not current or busy[player] then
        return false, "Профиль занят или недоступен."
    end
    busy[player] = true
    pending += 1
    local ok, value = pcall(function(): Profile?
        if store then
            return store:UpdateAsync(tostring(player.UserId), function(raw): Profile?
                local data = decode(raw)
                if transform(data) then
                    return data
                end
                return nil
            end)
        end
        local copy = table.clone(current)
        copy.owned = table.clone(current.owned)
        copy.receipts = table.clone(current.receipts)
        return if transform(copy) then copy else nil
    end)
    busy[player] = nil
    pending -= 1
    if not ok then
        return false,
            "Не удалось сохранить изменение. Попробуйте ещё раз."
    end
    if not value then
        return false, "Операция недоступна."
    end
    if player.Parent then
        profiles[player] = value
        display(player, value)
    end
    return true
end

function Profiles.reward(player: Player, runId: string, credits: number, xp: number)
    local now = os.time()
    return Profiles.change(player, function(data)
        if data.receipts[runId] then
            return true
        end
        for key, timestamp in data.receipts do
            if now - timestamp > 86400 then
                data.receipts[key] = nil
            end
        end
        data.receipts[runId] = now
        data.credits += credits
        data.xp += xp
        return true
    end)
end

game:BindToClose(function()
    local deadline = os.clock() + 25
    while pending > 0 and os.clock() < deadline do
        task.wait(0.1)
    end
end)

return Profiles
