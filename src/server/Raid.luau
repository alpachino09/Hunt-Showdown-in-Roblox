--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Remotes = require(script.Parent.Remotes)
local Profiles = require(script.Parent.Profiles)
local Policy = require(script.Parent.routes.MatchPolicy)
local allow, drop = require(script.Parent.RateLimit).new(0.08)

type Hunter = {
    team: string,
    weapon: string,
    ammo: number,
    reserve: number,
    lastFire: number,
    reloadingUntil: number,
    life: number,
    phase: string,
    downedUntil: number,
    exitAt: number?,
    resonanceUntil: number,
    medkits: number,
    healUntil: number,
    lastPosition: Vector3,
    sampledAt: number,
    moveBudget: number,
}
type Creature = {
    body: BasePart,
    hp: number,
    origin: Vector3,
    boss: boolean,
    lastAttack: number,
}
type Mode = {
    label: string,
    seconds: number,
    sealSeconds: number,
    exitSeconds: number,
    search: boolean,
}
local hunt: Mode = {
    label = "Кедровый перегон",
    seconds = Policy.sessionSeconds,
    sealSeconds = Policy.sealSeconds,
    exitSeconds = Policy.escapeSeconds,
    search = true,
}
local rush: Mode = {
    label = "Ночная смена",
    seconds = 600,
    sealSeconds = 8,
    exitSeconds = 5,
    search = false,
}

type Session = {
    mode: Mode,
    id: string,
    world: Model,
    markers: Folder,
    players: { [Player]: Hunter },
    clues: { [string]: { [string]: boolean } },
    creatures: { Creature },
    deadline: number,
    sealAt: number?,
    proof: BasePart?,
    carrier: Player?,
    escaped: number,
    onFinish: (Player, string, boolean) -> (),
}
local Raid = {}
local current: Session? = nil
local studio = RunService:IsStudio()

local function charParts(player: Player): (BasePart?, Humanoid?)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil,
        if char then char:FindFirstChildOfClass("Humanoid") else nil
end

local function message(player: Player, value: string)
    player:SetAttribute("RaidMessage", value)
end

local function updateAmmo(player: Player, hunter: Hunter)
    player:SetAttribute("RaidAmmo", hunter.ammo)
    player:SetAttribute("RaidReserve", hunter.reserve)
end

local function near(player: Player, part: BasePart, radius: number): boolean
    local root, humanoid = charParts(player)
    return root ~= nil
        and humanoid ~= nil
        and humanoid.Health > 0
        and (root.Position - part.Position).Magnitude <= radius
end

local function sight(from: Vector3, target: Vector3, source: Instance, hitTarget: Instance?)
    local query = RaycastParams.new()
    query.FilterType = Enum.RaycastFilterType.Exclude
    query.FilterDescendantsInstances = { source }
    local hit = Workspace:Raycast(from, target - from, query)
    return not hit
        or (hitTarget and hit.Instance:IsDescendantOf(hitTarget))
        or hit.Instance == hitTarget
end

local function objective(world: Model, name: string, position: Vector3, color: Color3): BasePart
    local part = Instance.new("Part")
    part.Name = name
    part.Size = Vector3.new(0.9, 0.5, 0.9)
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Color = color
    part.Material = Enum.Material.Neon
    part.Parent = world
    return part
end

local function prompt(part: BasePart, label: string, callback: (Player) -> ())
    local control = Instance.new("ProximityPrompt")
    control.ActionText = label
    control.ObjectText = part.Name
    control.MaxActivationDistance = 8
    control.RequiresLineOfSight = true
    control.Triggered:Connect(function(player)
        local root = charParts(player)
        if
            not root
            or not near(player, part, 9)
            or not sight(root.Position, part.Position, player.Character :: Model, part)
        then
            return
        end
        callback(player)
    end)
    control.Parent = part
end

local function spawnCreature(session: Session, position: Vector3, boss: boolean): Creature
    local body = Instance.new("Part")
    body.Name = if boss then "Смотритель" else "Бродяга"
    body.Size = if boss then Vector3.new(2.8, 4.2, 2) else Vector3.new(1.35, 2.9, 1.15)
    body.Position = Vector3.new(position.X, body.Size.Y / 2, position.Z)
    body.Anchored = true
    body.CanCollide = false
    body.Material = Enum.Material.Slate
    body.Color = if boss then Color3.fromRGB(60, 43, 37) else Color3.fromRGB(76, 81, 63)
    body.Parent = session.world
    local face = Instance.new("SpecialMesh")
    face.MeshType = Enum.MeshType.Sphere
    face.Scale = Vector3.new(1.15, 1, 1)
    face.Parent = body
    local creature: Creature = {
        body = body,
        hp = if boss then 155 else 46,
        origin = body.Position,
        boss = boss,
        lastAttack = 0,
    }
    table.insert(session.creatures, creature)
    return creature
end

local function placeProof(session: Session, position: Vector3)
    if session.proof then
        session.proof:Destroy()
    end
    local token = objective(
        session.world,
        "Свидетельство",
        position,
        Color3.fromRGB(236, 157, 63)
    )
    session.proof = token
    prompt(token, "Забрать", function(player)
        local hunter = session.players[player]
        if not hunter or hunter.phase ~= "Alive" or session.carrier then
            return
        end
        session.carrier = player
        session.proof = nil
        token:Destroy()
        player:SetAttribute("RaidProof", true)
        message(player, "Свидетельство у вас. Вернитесь к выходу.")
    end)
end

local function settle(session: Session, player: Player, name: string, escaped: boolean)
    local stats = session.players[player]
    if not stats then
        return
    end
    local carries = session.carrier == player
    if carries then
        session.carrier = nil
        if not escaped then
            local root = charParts(player)
            placeProof(
                session,
                if root
                    then root.Position
                    else (session.markers:FindFirstChild("Warden") :: BasePart).Position
            )
        end
    end
    session.players[player] = nil
    player:SetAttribute("RaidProof", nil)
    player:SetAttribute("RaidExitAt", nil)
    player:SetAttribute("RaidPhase", "Debrief")
    if escaped then
        session.escaped += 1
    end
    task.spawn(function()
        local saved = true
        if escaped then
            saved = false
            for try = 1, 3 do
                if not player.Parent then
                    break
                end
                saved = Profiles.reward(
                    player,
                    session.id,
                    if carries then 150 else 25,
                    if carries then 100 else 15
                )
                if saved then
                    break
                end
                task.wait(try)
            end
        end
        local report = if escaped and carries
            then "Свидетельство доставлено. +150 монет · +100 опыта."
            else name
        session.onFinish(
            player,
            if saved
                then report
                else "Эвакуация завершена. Награду сохранить не удалось.",
            escaped
        )
    end)
end

local function hurt(session: Session, player: Player, damage: number)
    local hunter = session.players[player]
    local root, humanoid = charParts(player)
    if not hunter or hunter.phase ~= "Alive" or not root or not humanoid then
        return
    end
    if humanoid.Health > damage then
        humanoid:TakeDamage(damage)
        return
    end
    hunter.life -= 1
    if hunter.life <= 0 then
        settle(session, player, "Охотник погиб.", false)
        return
    end
    hunter.phase = "Downed"
    hunter.downedUntil = os.clock() + 20
    hunter.exitAt = nil
    humanoid.Health = 1
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.JumpHeight = 0
    player:SetAttribute("RaidPhase", "Downed")
    player:SetAttribute("RaidExitAt", nil)
    message(player, "Нокдаун. Товарищ может поднять вас.")
    local marker =
        objective(session.world, "Товарищ", root.Position, Color3.fromRGB(214, 117, 71))
    prompt(marker, "Поднять", function(helper)
        local ally = session.players[helper]
        if
            not ally
            or ally.phase ~= "Alive"
            or ally.team ~= hunter.team
            or (hunter.phase :: string) ~= "Downed"
            or session.players[player] ~= hunter
            or not near(player, marker, 4)
        then
            return
        end
        hunter.phase = "Alive"
        humanoid.Health = 45
        humanoid.WalkSpeed = 13
        humanoid.JumpHeight = 5
        humanoid.JumpPower = 40
        player:SetAttribute("RaidPhase", "Alive")
        message(player, "Вы снова на ногах.")
        marker:Destroy()
    end)
    task.delay(20, function()
        marker:Destroy()
    end)
end

local function creatureBeat(session: Session, creature: Creature, now: number)
    if creature.hp <= 0 then
        return
    end
    local body = creature.body
    local target: Player? = nil
    local targetPos = creature.origin
    local nearest = if creature.boss then 20 else 17
    for player, hunter in session.players do
        local root = charParts(player)
        if hunter.phase == "Alive" and root then
            local distance = (root.Position - body.Position).Magnitude
            if
                distance < nearest and sight(body.Position, root.Position, body, player.Character)
            then
                target = player
                targetPos = root.Position
                nearest = distance
            end
        end
    end
    if target and nearest <= 4.2 then
        if now - creature.lastAttack > 1.25 then
            creature.lastAttack = now
            hurt(session, target, if creature.boss then 32 else 16)
        end
        return
    end
    local delta = Vector3.new(targetPos.X - body.Position.X, 0, targetPos.Z - body.Position.Z)
    if delta.Magnitude < 0.15 then
        return
    end
    local nextPos = body.Position
        + delta.Unit * math.min(delta.Magnitude, if creature.boss then 0.75 else 0.95)
    if sight(body.Position, nextPos, body, nil) then
        body.CFrame = CFrame.lookAt(nextPos, nextPos + delta.Unit)
    end
end

local function samplePosition(player: Player, hunter: Hunter, root: BasePart, now: number): boolean
    local moved = root.Position - hunter.lastPosition
    local elapsed = math.clamp(now - hunter.sampledAt, 0, 1)
    hunter.moveBudget = math.min(12, hunter.moveBudget + 28 * elapsed)
    local distance = Vector3.new(moved.X, 0, moved.Z).Magnitude
    hunter.sampledAt = now
    if not studio and (distance > hunter.moveBudget or math.abs(moved.Y) > 14 + 48 * elapsed) then
        local character = player.Character
        if character then
            character:PivotTo(CFrame.new(hunter.lastPosition) * root.CFrame.Rotation)
        end
        root.AssemblyLinearVelocity = Vector3.zero
        return false
    end
    hunter.lastPosition = root.Position
    hunter.moveBudget = math.max(0, hunter.moveBudget - distance)
    return true
end

local function tick(session: Session)
    local now = os.clock()
    for player, hunter in session.players do
        if not player.Parent then
            settle(session, player, "Соединение прервано.", false)
        elseif now >= session.deadline then
            settle(session, player, "Время контракта вышло.", false)
        elseif hunter.phase == "Downed" and now >= hunter.downedUntil then
            settle(session, player, "Помощь не успела.", false)
        elseif hunter.phase == "Alive" then
            local root, humanoid = charParts(player)
            if not root or not humanoid or humanoid.Health <= 0 then
                settle(session, player, "Охотник погиб.", false)
            elseif not samplePosition(player, hunter, root, now) then
                hunter.exitAt = nil
                player:SetAttribute("RaidExitAt", nil)
            elseif hunter.exitAt then
                local exit = session.markers:FindFirstChild("Escape") :: BasePart
                if not near(player, exit, 10) then
                    hunter.exitAt = nil
                    player:SetAttribute("RaidExitAt", nil)
                    message(
                        player,
                        "Эвакуация отменена: вы покинули зону."
                    )
                else
                    local contested = false
                    for other, stats in session.players do
                        if
                            other ~= player
                            and stats.team ~= hunter.team
                            and stats.phase == "Alive"
                            and near(other, exit, 12)
                        then
                            contested = true
                            break
                        end
                    end
                    if contested then
                        hunter.exitAt = now + session.mode.exitSeconds
                        player:SetAttribute(
                            "RaidExitAt",
                            Workspace:GetServerTimeNow() + session.mode.exitSeconds
                        )
                        message(player, "Выход блокируют соперники.")
                    elseif now >= hunter.exitAt then
                        settle(
                            session,
                            player,
                            "Вы вернулись на заставу. +25 монет · +15 опыта.",
                            true
                        )
                    end
                end
            end
        end
    end

    if session.sealAt and now >= session.sealAt then
        session.sealAt = nil
        placeProof(session, (session.markers:FindFirstChild("Warden") :: BasePart).Position)
        for player in session.players do
            message(
                player,
                "Печать замкнулась. Свидетельство можно забрать."
            )
        end
    end
    for _, creature in session.creatures do
        creatureBeat(session, creature, now)
    end
end

function Raid.start(
    roster: { { player: Player, team: string } },
    onFinish: (Player, string, boolean) -> (),
    fast: boolean?
): boolean
    if current or #roster == 0 or #roster > Policy.playerLimit then
        return false
    end
    for _, entry in roster do
        if not Profiles.get(entry.player) then
            return false
        end
    end

    local mode = if fast then rush else hunt
    local map = ServerStorage:FindFirstChild(if fast then "RushMap" else "ExpeditionMap")
    if not map then
        return false
    end
    local world = map:Clone() :: Model
    world.Name = "ActiveRaid"
    local markers = world:FindFirstChild("Markers") :: Folder
    local session: Session = {
        mode = mode,
        id = HttpService:GenerateGUID(false),
        world = world,
        markers = markers,
        players = {},
        clues = {},
        creatures = {},
        deadline = os.clock() + mode.seconds,
        escaped = 0,
        onFinish = onFinish,
    }
    current = session
    world.Parent = Workspace

    for i = 1, (if mode.search then 3 else 0) do
        local key = "Clue" .. i
        local marker = markers:FindFirstChild(key) :: BasePart
        local clue =
            objective(world, "След №" .. i, marker.Position, Color3.fromRGB(123, 172, 157))
        prompt(clue, "Исследовать", function(player)
            local hunter = session.players[player]
            if not hunter or hunter.phase ~= "Alive" then
                return
            end
            local findings = session.clues[hunter.team]
            if findings[key] then
                return
            end
            findings[key] = true
            local count = 0
            for _ in findings do
                count += 1
            end
            for member, stats in session.players do
                if stats.team == hunter.team then
                    member:SetAttribute("RaidClues", count)
                    message(
                        member,
                        if count == 3
                            then "Логово обнаружено: контора у шахты, севернее пути."
                            else "След найден. Ищите следующий."
                    )
                end
            end
        end)
    end
    local exit = objective(
        world,
        "Выход на заставу",
        (markers:FindFirstChild("Escape") :: BasePart).Position,
        Color3.fromRGB(215, 165, 88)
    )
    prompt(exit, "Эвакуироваться", function(player)
        local hunter = session.players[player]
        if not hunter or hunter.phase ~= "Alive" or hunter.exitAt then
            return
        end
        hunter.exitAt = os.clock() + session.mode.exitSeconds
        player:SetAttribute("RaidExitAt", Workspace:GetServerTimeNow() + session.mode.exitSeconds)
        message(player, "Оставайтесь у выхода.")
    end)
    spawnCreature(session, (markers:FindFirstChild("Warden") :: BasePart).Position, true)
    if mode.search then
        spawnCreature(session, (markers:FindFirstChild("Drifter") :: BasePart).Position, false)
    end

    local waiting = #roster
    local teamIndices: { [string]: number } = {}
    local teamSizes: { [string]: number } = {}
    local teamCount = 0
    for _, entry in roster do
        if not teamIndices[entry.team] then
            teamCount += 1
            teamIndices[entry.team] = teamCount
        end
        local teamIndex = teamIndices[entry.team]
        local offset = teamSizes[entry.team] or 0
        teamSizes[entry.team] = offset + 1
        local player = entry.player
        local data = Profiles.get(player) :: Profiles.Profile
        local weapon = Catalog.weapon(data.weapon) or Catalog.weapons[1]
        session.clues[entry.team] = {}
        player:SetAttribute("RaidMode", mode.label)
        player:SetAttribute("RaidSearch", mode.search)
        player:SetAttribute("RaidPhase", "Deploying")
        task.spawn(function()
            local ok = pcall(function()
                player:LoadCharacterAsync()
            end)
            local root, humanoid = charParts(player)
            if ok and root and humanoid and player.Parent then
                local spawn = (markers:FindFirstChild("Spawn") :: BasePart).Position
                    + Vector3.new(offset * 3.3, 0, 0)
                if teamIndex > 1 then
                    local angle = (teamIndex - 2) * math.pi / 5
                    local radius = if fast then 27 else 47
                    spawn = Vector3.new(
                        220 + math.cos(angle) * radius + offset * 2,
                        3.5,
                        math.sin(angle) * radius - (if fast then 8 else 17)
                    )
                end
                local character = player.Character :: Model
                character:PivotTo(CFrame.lookAt(spawn, spawn - Vector3.zAxis))
                humanoid.WalkSpeed = 13
                humanoid.JumpPower = 40
                local hunter: Hunter = {
                    team = entry.team,
                    weapon = weapon.id,
                    ammo = weapon.capacity,
                    reserve = weapon.reserve,
                    life = 2,
                    lastFire = -math.huge,
                    reloadingUntil = 0,
                    phase = "Alive",
                    downedUntil = 0,
                    resonanceUntil = 0,
                    medkits = if data.xp >= 300 then 2 else 1,
                    healUntil = 0,
                    lastPosition = root.Position,
                    sampledAt = os.clock(),
                    moveBudget = 12,
                }
                session.players[player] = hunter
                player:SetAttribute("RaidWeapon", weapon.name)
                player:SetAttribute("RaidClues", 0)
                player:SetAttribute("RaidMedkits", hunter.medkits)
                player:SetAttribute("RaidHealing", false)
                player:SetAttribute(
                    "RaidDeadline",
                    Workspace:GetServerTimeNow() + math.max(0, session.deadline - os.clock())
                )
                updateAmmo(player, hunter)
                message(
                    player,
                    if mode.search
                        then "Исследуйте следы вдоль перегона. Клавиша Q показывает ближайшие следы."
                        else "Смотритель в конторе шахты. Заберите свидетельство и возвращайтесь."
                )
                player:SetAttribute("RaidPhase", "Alive")
            else
                onFinish(player, "Не удалось загрузить охотника.", false)
            end
            waiting -= 1
        end)
    end
    task.spawn(function()
        while waiting > 0 or next(session.players) do
            task.wait(0.17)
            tick(session)
        end
        world:Destroy()
        current = nil
    end)
    return true
end

local function endCreature(session: Session, creature: Creature)
    creature.body:Destroy()
    if not creature.boss then
        return
    end
    local altar = objective(
        session.world,
        "Печать смотрителя",
        creature.origin,
        Color3.fromRGB(185, 89, 54)
    )
    prompt(altar, "Опечатать", function(player)
        local hunter = session.players[player]
        if not hunter or hunter.phase ~= "Alive" or session.sealAt then
            return
        end
        session.sealAt = os.clock() + session.mode.sealSeconds
        altar:Destroy()
        for member in session.players do
            message(
                member,
                string.format(
                    "Печать в конторе шахты замкнётся через %d с.",
                    session.mode.sealSeconds
                )
            )
        end
    end)
    for member in session.players do
        message(
            member,
            "Смотритель повержен. Опечатайте останки."
        )
    end
end

Remotes.combat.OnServerEvent:Connect(function(player: Player, action: unknown, direction: unknown)
    if not allow(player) then
        return
    end
    local session = current
    local hunter = session and session.players[player]
    if not session or not hunter or hunter.phase ~= "Alive" then
        return
    end
    local root, humanoid = charParts(player)
    if not root or not humanoid or humanoid.Health <= 0 then
        return
    end
    local weapon = Catalog.weapon(hunter.weapon)
    if not weapon then
        return
    end
    local now = os.clock()
    if not studio and (root.Position - hunter.lastPosition).Magnitude > 17 then
        return
    end
    if action == "Heal" then
        if
            hunter.medkits == 0
            or humanoid.Health >= humanoid.MaxHealth
            or now < hunter.healUntil
        then
            return
        end
        hunter.healUntil = now + 2
        local began = root.Position
        player:SetAttribute("RaidHealing", true)
        task.delay(2, function()
            if player.Parent then
                player:SetAttribute("RaidHealing", false)
            end
            if
                current ~= session
                or session.players[player] ~= hunter
                or hunter.phase ~= "Alive"
                or not root.Parent
                or (root.Position - began).Magnitude > 5
                or humanoid.Health >= humanoid.MaxHealth
            then
                return
            end
            hunter.medkits -= 1
            humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 38)
            player:SetAttribute("RaidMedkits", hunter.medkits)
        end)
        return
    end
    if action == "Resonance" and session.mode.search and now >= hunter.resonanceUntil then
        hunter.resonanceUntil = now + 8
        local positions = {}
        for i = 1, 3 do
            local key = "Clue" .. i
            if not session.clues[hunter.team][key] then
                local marker = session.markers:FindFirstChild(key) :: BasePart
                if (marker.Position - root.Position).Magnitude <= 100 then
                    table.insert(positions, marker.Position)
                end
            end
        end
        Remotes.combat:FireClient(player, "Resonance", positions)
        return
    end
    if action == "Sprint" or action == "Crouch" or action == "Walk" then
        humanoid.WalkSpeed = if action == "Sprint" then 19 elseif action == "Crouch" then 8 else 13
        return
    end
    if action == "Reload" then
        if hunter.ammo >= weapon.capacity or hunter.reserve <= 0 or now < hunter.reloadingUntil then
            return
        end
        hunter.reloadingUntil = now + weapon.reload
        player:SetAttribute("RaidReloading", true)
        task.delay(weapon.reload, function()
            if session.players[player] ~= hunter or hunter.phase ~= "Alive" then
                if player.Parent then
                    player:SetAttribute("RaidReloading", false)
                end
                return
            end
            local fill = math.min(weapon.capacity - hunter.ammo, hunter.reserve)
            hunter.ammo += fill
            hunter.reserve -= fill
            player:SetAttribute("RaidReloading", false)
            updateAmmo(player, hunter)
        end)
        return
    end
    if
        action ~= "Fire"
        or typeof(direction) ~= "Vector3"
        or not (direction.Magnitude >= 0.98 and direction.Magnitude <= 1.02)
        or hunter.ammo <= 0
        or now - hunter.lastFire < weapon.delay
        or now < hunter.reloadingUntil
        or now < hunter.healUntil
    then
        return
    end
    hunter.ammo -= 1
    hunter.lastFire = now
    updateAmmo(player, hunter)
    local head = player.Character and player.Character:FindFirstChild("Head")
    local origin = if head and head:IsA("BasePart") then head.Position else root.Position
    local query = RaycastParams.new()
    query.FilterType = Enum.RaycastFilterType.Exclude
    query.FilterDescendantsInstances = { player.Character :: Model }
    local hit = Workspace:Raycast(origin, direction.Unit * 165, query)
    Remotes.combat:FireClient(player, "Fired", hit and hit.Position)
    if not hit then
        return
    end
    local damage = math.max(8, math.floor(weapon.damage * (1 - hit.Distance / 450)))
    for _, creature in session.creatures do
        if creature.body == hit.Instance and creature.hp > 0 then
            creature.hp -= damage
            if creature.hp <= 0 then
                endCreature(session, creature)
            end
            return
        end
    end
    local character = hit.Instance:FindFirstAncestorOfClass("Model")
    local victim = character and Players:GetPlayerFromCharacter(character)
    local other = victim and session.players[victim]
    if victim and other and other.team ~= hunter.team then
        hurt(session, victim, if hit.Instance.Name == "Head" then damage * 2 else damage)
    end
end)

Players.PlayerRemoving:Connect(drop)

return Raid
