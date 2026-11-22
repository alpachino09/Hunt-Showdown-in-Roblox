--!strict

local RateLimit = {}

function RateLimit.new(minimumInterval: number)
    local used: { [Player]: number } = {}
    local function allow(player: Player): boolean
        local now = os.clock()
        if now - (used[player] or -math.huge) < minimumInterval then
            return false
        end
        used[player] = now
        return true
    end
    local function drop(player: Player)
        used[player] = nil
    end
    return allow, drop
end

return table.freeze(RateLimit)
