--!strict
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
})

Catalog.weapons = table.freeze({
    table.freeze({
        id = "service",
        name = "Служебный револьвер",
        capacity = 6,
        reserve = 24,
        delay = 0.49,
        reload = 1.7,
        damage = 31,
        price = 0,
    }),
    table.freeze({
        id = "ridge",
        name = "Карабин «Перегон»",
        capacity = 4,
        reserve = 16,
        delay = 0.73,
        reload = 2.1,
        damage = 48,
        price = 100,
    }),
})

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
