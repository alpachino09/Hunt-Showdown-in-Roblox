--!strict

-- Shared by server systems once matchmaking is introduced.
local MatchPolicy = {
    playerLimit = 12,
    supportedPartySizes = table.freeze({ 1, 2, 3 }),
    studioMinimumPlayers = 1,
}

return table.freeze(MatchPolicy)
