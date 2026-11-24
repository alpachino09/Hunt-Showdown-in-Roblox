--!strict

type Rules = {
    capacity: number,
    reserve: number,
    delay: number,
    reload: number,
    reloadMode: "Batch" | "BreakAction",
}

export type Chamber = "Live" | "Spent" | "Empty"
export type Stage = "Batch" | "Open" | "Eject" | "Insert" | "Close"
export type Reload = {
    revision: number,
    stage: Stage,
    startedAt: number,
    nextAt: number,
}

export type State = {
    rules: Rules,
    loaded: number,
    reserve: number,
    chamber: Chamber?,
    lastFire: number,
    revision: number,
    reload: Reload?,
}

local WeaponStateService = {}
local duration = table.freeze({
    Batch = 1,
    Open = 0.20,
    Eject = 0.19,
    Insert = 0.41,
    Close = 0.20,
})

local function setStage(state: State, stage: Stage, startedAt: number)
    state.reload = {
        revision = state.revision,
        stage = stage,
        startedAt = startedAt,
        nextAt = startedAt + state.rules.reload * duration[stage],
    }
end

function WeaponStateService.new(rules: Rules): State
    assert(rules.reloadMode ~= "BreakAction" or rules.capacity == 1, "Expected one chamber")
    return {
        rules = rules,
        loaded = rules.capacity,
        reserve = rules.reserve,
        chamber = if rules.reloadMode == "BreakAction" then "Live" else nil,
        lastFire = -math.huge,
        revision = 0,
        reload = nil,
    }
end

function WeaponStateService.fire(state: State, now: number): boolean
    if state.reload or state.loaded == 0 or now - state.lastFire < state.rules.delay then
        return false
    end
    state.loaded -= 1
    state.lastFire = now
    if state.chamber then
        state.chamber = "Spent"
    end
    return true
end

function WeaponStateService.beginReload(state: State, now: number): Reload?
    if state.reload or state.loaded >= state.rules.capacity or state.reserve == 0 then
        return nil
    end
    state.revision += 1
    setStage(state, if state.chamber then "Open" else "Batch", now)
    return state.reload
end

function WeaponStateService.advance(state: State, revision: number, now: number): boolean
    local changed = false
    local reload = state.reload
    while reload and reload.revision == revision and now >= reload.nextAt do
        changed = true
        if reload.stage == "Batch" then
            local added = math.min(state.rules.capacity - state.loaded, state.reserve)
            state.loaded += added
            state.reserve -= added
            state.reload = nil
        elseif reload.stage == "Open" then
            setStage(state, if state.chamber == "Spent" then "Eject" else "Insert", reload.nextAt)
        elseif reload.stage == "Eject" then
            state.chamber = "Empty"
            setStage(state, "Insert", reload.nextAt)
        elseif reload.stage == "Insert" then
            state.chamber = "Live"
            state.loaded = 1
            state.reserve -= 1
            setStage(state, "Close", reload.nextAt)
        else
            state.reload = nil
        end
        reload = state.reload
    end
    return changed
end

function WeaponStateService.cancel(state: State, now: number): boolean
    local reload = state.reload
    if not reload or reload.stage == "Batch" or reload.stage == "Close" then
        return false
    end
    WeaponStateService.advance(state, reload.revision, now)
    reload = state.reload
    if reload and reload.stage ~= "Close" then
        state.revision += 1
        setStage(state, "Close", now)
    end
    return true
end

function WeaponStateService.abort(state: State)
    state.reload = nil
end

return table.freeze(WeaponStateService)
