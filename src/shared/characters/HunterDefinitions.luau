--!strict

export type Definition = {
    id: string,
    template: string,
    speedScale: number,
    idleLean: number,
}

local HunterDefinitions = {}

local roster: { Definition } = {
    { id = "reed", template = "Veteran", speedScale = 1, idleLean = 0 },
    { id = "vale", template = "Tracker", speedScale = 1.08, idleLean = -0.045 },
    { id = "shaw", template = "Marshal", speedScale = 0.94, idleLean = 0.024 },
}
local byId: { [string]: Definition } = {}
for _, hunter in roster do
    table.freeze(hunter)
    byId[hunter.id] = hunter
end
HunterDefinitions.roster = table.freeze(roster)
HunterDefinitions.byId = table.freeze(byId)

return HunterDefinitions
