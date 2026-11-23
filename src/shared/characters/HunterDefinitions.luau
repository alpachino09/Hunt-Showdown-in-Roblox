--!strict

export type Definition = {
    id: string,
    template: string,
    speedScale: number,
    idleLean: number,
    showcaseScale: number,
    showcaseProp: "Rifle" | "Pistol",
    idleGlance: number,
}

local HunterDefinitions = {}

local roster: { Definition } = {
    {
        id = "reed",
        template = "Veteran",
        speedScale = 1,
        idleLean = 0,
        showcaseScale = 0.85,
        showcaseProp = "Rifle",
        idleGlance = 0.10,
    },
    {
        id = "vale",
        template = "Tracker",
        speedScale = 1.08,
        idleLean = -0.045,
        showcaseScale = 0.87,
        showcaseProp = "Rifle",
        idleGlance = -0.15,
    },
    {
        id = "shaw",
        template = "Marshal",
        speedScale = 0.94,
        idleLean = 0.024,
        showcaseScale = 0.82,
        showcaseProp = "Pistol",
        idleGlance = 0.06,
    },
    {
        id = "warden",
        template = "Occult",
        speedScale = 0.97,
        idleLean = -0.026,
        showcaseScale = 0.84,
        showcaseProp = "Rifle",
        idleGlance = -0.09,
    },
}
local byId: { [string]: Definition } = {}
for _, hunter in roster do
    table.freeze(hunter)
    byId[hunter.id] = hunter
end
HunterDefinitions.roster = table.freeze(roster)
HunterDefinitions.byId = table.freeze(byId)

return HunterDefinitions
