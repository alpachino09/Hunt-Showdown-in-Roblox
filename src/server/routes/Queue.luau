--!strict

local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService = game:GetService("TeleportService")
local Policy = require(script.Parent.MatchPolicy)

type Ticket = {
    id: string,
    team: string,
    users: { number },
    queued: number,
    expires: number,
    match: string?,
    access: string?,
}
type Pool = { tickets: { [string]: Ticket }, claim: string?, claimUntil: number? }
local Queue = {}
local requests = MemoryStoreService:GetHashMap("GreyOutpostLobbyQueueV1")
local admissions = MemoryStoreService:GetHashMap("GreyOutpostAdmissionsV1")
local polling = false
local pending: { [string]: { Player } } = {}

local function update(transform: (Pool, number) -> boolean): Pool?
    local now = os.time()
    local ok, result = pcall(function()
        return requests:UpdateAsync("Expedition", function(raw): Pool?
            local pool: Pool = raw or { tickets = {} }
            for id, ticket in pool.tickets do
                if ticket.expires <= now then
                    pool.tickets[id] = nil
                end
            end
            return if transform(pool, now) then pool else nil
        end, 600)
    end)
    return if ok then result else nil
end

local function dispatch(ticket: Ticket, group: { Player })
    pending[ticket.id] = nil
    if #group == 0 then
        return
    end
    local options = Instance.new("TeleportOptions")
    options.ReservedServerAccessCode = ticket.access :: string
    options:SetTeleportData({ match = ticket.match })
    local ok = pcall(function()
        TeleportService:TeleportAsync(Policy.expeditionPlaceId, group, options)
    end)
    if not ok then
        for _, player in group do
            player:SetAttribute("QueueId", nil)
            player:SetAttribute(
                "LobbyMessage",
                "Перенос не удался. Можно начать поиск снова."
            )
        end
    end
end

local function form()
    local claim = HttpService:GenerateGUID(false)
    local pool = update(function(current, now)
        if current.claim and (current.claimUntil or 0) > now then
            return false
        end
        local count, oldest = 0, now
        for _, ticket in current.tickets do
            if not ticket.match then
                count += #ticket.users
                oldest = math.min(oldest, ticket.queued)
            end
        end
        if count < 2 or (count < Policy.playerLimit and now - oldest < 30) then
            return false
        end
        current.claim = claim
        current.claimUntil = now + 30
        return true
    end)
    if not pool or pool.claim ~= claim then
        return
    end

    local waiting: { Ticket } = {}
    for _, ticket in pool.tickets do
        if not ticket.match then
            table.insert(waiting, ticket)
        end
    end
    table.sort(waiting, function(a, b)
        return a.queued < b.queued or a.queued == b.queued and a.id < b.id
    end)

    local selected, users, count = {}, {}, 0
    for _, ticket in waiting do
        if count + #ticket.users <= Policy.playerLimit then
            selected[ticket.id] = true
            for _, user in ticket.users do
                users[tostring(user)] = ticket.team
            end
            count += #ticket.users
        end
    end

    local access: string, privateId: string
    local ok = pcall(function()
        access, privateId = TeleportService:ReserveServerAsync(Policy.expeditionPlaceId)
        admissions:SetAsync(claim, { privateId = privateId, teams = users, count = count }, 180)
    end)
    update(function(state, now)
        if state.claim ~= claim then
            return false
        end
        state.claim = nil
        state.claimUntil = nil
        if not ok then
            return true
        end
        -- Discard this attempt if a selected party left while the reservation was in flight.
        for id in selected do
            if not state.tickets[id] or state.tickets[id].match then
                return true
            end
        end
        for id in selected do
            local ticket = state.tickets[id]
            ticket.match = claim
            ticket.access = access
            ticket.expires = now + 75
        end
        return true
    end)
end

local function beginPolling()
    if polling then
        return
    end
    polling = true
    task.spawn(function()
        while next(pending) do
            form()
            local ok, pool = pcall(function()
                return requests:GetAsync("Expedition") :: Pool?
            end)
            if ok and pool then
                for id, group in pending do
                    local ticket = pool.tickets[id]
                    if ticket and ticket.match and ticket.access then
                        dispatch(ticket, group)
                    elseif not ticket or ticket.expires <= os.time() then
                        pending[id] = nil
                        for _, player in group do
                            player:SetAttribute("QueueId", nil)
                            player:SetAttribute(
                                "LobbyMessage",
                                "Поиск истёк. Начните заново."
                            )
                        end
                    end
                end
            end
            task.wait(4 + math.random())
        end
        polling = false
    end)
end

function Queue.join(group: { Player }): boolean
    if Policy.expeditionPlaceId <= 0 or Policy.lobbyPlaceId <= 0 then
        return false
    end
    local id = HttpService:GenerateGUID(false)
    local users: { number } = {}
    local memberIds: { [number]: boolean } = {}
    for _, player in group do
        if player:GetAttribute("QueueId") then
            return false
        end
        table.insert(users, player.UserId)
        memberIds[player.UserId] = true
    end
    for _, player in group do
        player:SetAttribute("QueueId", id)
    end
    local state = update(function(pool, now)
        local count = 0
        for _, other in pool.tickets do
            count += 1
            if not other.match then
                for _, user in other.users do
                    if memberIds[user] then
                        return false
                    end
                end
            end
        end
        if count >= 65 then
            return false
        end
        pool.tickets[id] = { id = id, team = id, users = users, queued = now, expires = now + 125 }
        return true
    end)
    if not state or not state.tickets[id] then
        for _, player in group do
            player:SetAttribute("QueueId", nil)
        end
        return false
    end
    pending[id] = table.clone(group)
    for _, player in group do
        player:SetAttribute("LobbyMessage", "Поиск экспедиции…")
    end
    beginPolling()
    return true
end

function Queue.cancel(player: Player): boolean
    local id = player:GetAttribute("QueueId")
    if type(id) ~= "string" or not pending[id] then
        return false
    end
    local state = update(function(pool)
        local ticket = pool.tickets[id]
        if ticket and ticket.match then
            return false
        end
        pool.tickets[id] = nil
        return true
    end)
    local group = pending[id]
    if not state or not group then
        return false
    end
    pending[id] = nil
    for _, member in group do
        member:SetAttribute("QueueId", nil)
        member:SetAttribute("LobbyMessage", "Поиск отменён.")
    end
    return true
end

function Queue.admission(player: Player): (string?, number?)
    local join = player:GetJoinData()
    local raw: any = join.TeleportData
    if
        join.SourcePlaceId ~= Policy.lobbyPlaceId
        or type(raw) ~= "table"
        or type(raw.match) ~= "string"
        or #raw.match > 40
    then
        return nil
    end
    local ok, value = pcall(function()
        return admissions:GetAsync(raw.match)
    end)
    if not ok or type(value) ~= "table" or value.privateId ~= game.PrivateServerId then
        return nil
    end
    return value.teams[tostring(player.UserId)], value.count
end

TeleportService.TeleportInitFailed:Connect(function(player: Player, _, _, placeId)
    if placeId == Policy.expeditionPlaceId and player:GetAttribute("QueueId") then
        player:SetAttribute("QueueId", nil)
        player:SetAttribute(
            "LobbyMessage",
            "Перенос сорвался. Повторите поиск."
        )
    end
end)

return Queue
