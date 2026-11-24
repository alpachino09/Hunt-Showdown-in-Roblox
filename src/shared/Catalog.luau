--!strict
local WeaponDefinitions = require(script.Parent.weapons.WeaponDefinitions)
local Catalog = {}

Catalog.hunters = table.freeze({
    table.freeze({
        id = "reed",
        name = "Элиас Рид",
        description = "Обходчик Кедрового перегона.",
        color = Color3.fromRGB(61, 57, 49),
    }),
    table.freeze({
        id = "vale",
        name = "Марта Вейл",
        description = "Связистка ночной смены.",
        color = Color3.fromRGB(46, 67, 71),
    }),
    table.freeze({
        id = "shaw",
        name = "Дэниел Шоу",
        description = "Разведчик горной службы.",
        color = Color3.fromRGB(95, 65, 46),
    }),
    table.freeze({
        id = "warden",
        name = "Смотритель обряда",
        description = "Полевой хранитель журналов Кедровой заставы.",
        color = Color3.fromRGB(80, 46, 53),
    }),
})

Catalog.weapons = WeaponDefinitions.expedition

function Catalog.hunter(id: unknown): typeof(Catalog.hunters[1])?
    for _, entry in Catalog.hunters do
        if entry.id == id then
            return entry
        end
    end
    return nil
end

function Catalog.weapon(id: unknown): typeof(Catalog.weapons[1])?
    for _, entry in Catalog.weapons do
        if entry.id == id then
            return entry
        end
    end
    return nil
end

return table.freeze(Catalog)
