--!strict

type Party = { leader: Player, members: { Player }, ready: { [Player]: boolean } }
local parties: { [Player]: Party } = {}
local Parties = {}

local function display(party: Party)
    local names = {}
    for _, member in party.members do
        table.insert(names, (if party.ready[member] then "✓ " else "· ") .. member.DisplayName)
    end
    for _, member in party.members do
        member:SetAttribute("PartySummary", table.concat(names, "   "))
        member:SetAttribute("PartyReady", party.ready[member] == true)
    end
end

function Parties.join(player: Player)
    local party = { leader = player, members = { player }, ready = {} }
    parties[player] = party
    display(party)
end

function Parties.leave(player: Player)
    local party = parties[player]
    if not party then
        return
    end
    parties[player] = nil
    party.ready[player] = nil
    local index = table.find(party.members, player)
    if index then
        table.remove(party.members, index)
    end
    if #party.members > 0 then
        if party.leader == player then
            party.leader = party.members[1]
        end
        display(party)
    end
end

function Parties.group(player: Player, leader: Player): boolean
    local old = parties[player]
    local target = parties[leader]
    if
        not old
        or not target
        or #old.members ~= 1
        or old == target
        or target.leader ~= leader
        or #target.members >= 3
    then
        return false
    end
    Parties.leave(player)
    parties[player] = target
    table.insert(target.members, player)
    table.clear(target.ready)
    display(target)
    return true
end

function Parties.toggle(player: Player)
    local party = parties[player]
    if not party then
        return
    end
    party.ready[player] = not party.ready[player]
    display(party)
end

function Parties.roster(player: Player): { Player }?
    local party = parties[player]
    if not party or party.leader ~= player then
        return nil
    end
    for _, member in party.members do
        if #party.members > 1 and not party.ready[member] then
            return nil
        end
    end
    return table.clone(party.members)
end

return Parties
