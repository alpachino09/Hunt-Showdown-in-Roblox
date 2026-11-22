--!strict

local Catalog = require(game:GetService("ReplicatedStorage").Shared.Catalog)
local studio = game:GetService("RunService"):IsStudio()

type Action = { label: string, command: string, value: string? }
export type Page = { heading: string, summary: string, primary: Action?, secondary: Action? }

local function action(label: string, command: string, value: string?): Action
    return { label = label, command = command, value = value }
end

local function get(player: Player, key: string): Page?
    local hunter = Catalog.hunter(player:GetAttribute("HunterId")) or Catalog.hunters[1]
    local weapon = Catalog.weapon(player:GetAttribute("WeaponId")) or Catalog.weapons[1]
    local credits = player:GetAttribute("Credits") or 0
    local xp = tonumber(player:GetAttribute("Experience")) or 0
    local ready = player:GetAttribute("PartyReady") == true
    if key == "Briefing" then
        return {
            heading = "Последний сигнал",
            summary = "На Кедровом перегоне погасли сигнальные огни. Исследуйте следы и вернитесь со свидетельством.",
            primary = if player:GetAttribute("QueueId")
                then action("Отменить поиск", "Cancel")
                else action("Начать экспедицию", "Start"),
            secondary = if studio
                then action("Быстрый контракт", "StartRush")
                else nil,
        }
    elseif key == "Hunter" or key == "Recruitment" then
        local index = table.find(Catalog.hunters, hunter) or 1
        local nextHunter = Catalog.hunters[index % #Catalog.hunters + 1]
        local prevHunter = Catalog.hunters[(index - 2) % #Catalog.hunters + 1]
        return {
            heading = hunter.name,
            summary = hunter.description,
            primary = action(nextHunter.name, "Hunter", nextHunter.id),
            secondary = action(prevHunter.name, "Hunter", prevHunter.id),
        }
    elseif key == "Equipment" then
        return {
            heading = "Походный комплект",
            summary = weapon.name
                .. "  ·  "
                .. tostring(weapon.capacity)
                .. " патронов в зарядке",
            primary = action("Взять револьвер", "Equip", "service"),
            secondary = if player:GetAttribute("OwnsCarbine")
                then action("Взять карабин", "Equip", "ridge")
                else nil,
        }
    elseif key == "Roster" then
        return {
            heading = "Связь с отрядом",
            summary = tostring(player:GetAttribute("PartySummary") or ""),
            primary = action(
                if ready
                    then "Снять готовность"
                    else "Отметить готовность",
                "Ready"
            ),
            secondary = if ready
                then action("Выйти из отряда", "LeaveParty")
                else action("Вступить в тестовый отряд", "JoinLocal"),
        }
    elseif key == "Progression" then
        return {
            heading = "Полевой журнал",
            summary = "Опыт: "
                .. tostring(xp)
                .. "\nМонеты: "
                .. tostring(credits)
                .. "\nПолевой медик: "
                .. (
                    if xp >= 300
                        then "открыт · две аптечки"
                        else tostring(xp) .. " / 300 опыта"
                ),
        }
    elseif key == "Store" then
        return {
            heading = "Склад снабжения",
            summary = "Карабин «Перегон» · 100 монет\nВаш баланс: "
                .. tostring(credits),
            primary = if player:GetAttribute("OwnsCarbine")
                then action("Карабин в комплекте", "Equip", "ridge")
                else action("Купить карабин", "Buy", "ridge"),
        }
    elseif key == "Settings" then
        return {
            heading = "Настройки показа",
            summary = "Включайте или выключайте движение охотника на этой заставе.",
        }
    end
    return nil
end

return get
