--!strict

export type Family = "Revolver" | "Carbine" | "BreakAction"
export type ReloadMode = "Batch" | "BreakAction"
export type Definition = {
    id: string,
    name: string,
    family: Family,
    reloadMode: ReloadMode,
    capacity: number,
    reserve: number,
    delay: number,
    reload: number,
    damage: number,
    price: number,
}

local function definition(values: Definition): Definition
    return table.freeze(values)
end

return table.freeze({
    expedition = table.freeze({
        definition({
            id = "service",
            name = "Служебный револьвер",
            family = "Revolver",
            reloadMode = "Batch",
            capacity = 6,
            reserve = 24,
            delay = 0.49,
            reload = 1.7,
            damage = 31,
            price = 0,
        }),
        definition({
            id = "ridge",
            name = "Карабин «Перегон»",
            family = "Carbine",
            reloadMode = "Batch",
            capacity = 4,
            reserve = 16,
            delay = 0.73,
            reload = 2.1,
            damage = 48,
            price = 100,
        }),
    }),
    lantern = definition({
        id = "lantern",
        name = "Фонарь",
        family = "BreakAction",
        reloadMode = "BreakAction",
        capacity = 1,
        reserve = 8,
        delay = 0.65,
        reload = 2.4,
        damage = 48,
        price = 0,
    }),
})
