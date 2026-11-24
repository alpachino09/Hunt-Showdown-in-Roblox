--!strict

export type Timeline = {
    stage: string,
    startedAt: number,
    nextAt: number,
    closeFrom: number?,
}

export type State = {
    loaded: number,
    reserve: number,
    chamber: string,
    aiming: boolean,
    shotAt: number?,
    reload: Timeline?,
}

local LanternAnimation = {}

local function smooth(alpha: number): number
    return alpha * alpha * (3 - 2 * alpha)
end

function LanternAnimation.sample(state: State, now: number)
    local open, brace, slide, insert = 0, 0, 0, 0
    local reload = state.reload
    if reload then
        local progress =
            math.clamp((now - reload.startedAt) / (reload.nextAt - reload.startedAt), 0, 1)
        local eased = smooth(progress)
        if reload.stage == "Open" then
            open, brace = eased, eased
        elseif reload.stage == "Eject" then
            open, brace, slide = 1, 1, eased
        elseif reload.stage == "Insert" then
            open, brace = 1, 1
            insert = progress
        elseif reload.stage == "Close" then
            local initial = smooth(reload.closeFrom or 1)
            open, brace = initial * (1 - eased), initial * (1 - eased)
        end
    end
    local shotAge = if state.shotAt then math.max(0, now - state.shotAt) else math.huge
    local recoil = if shotAge < 0.35 then math.exp(-shotAge * 14) else 0
    return {
        open = open,
        brace = brace,
        slide = slide,
        insert = insert,
        recoil = recoil,
        flash = shotAge < 0.048,
        spent = state.chamber == "Spent",
        loaded = state.chamber == "Live",
    }
end

export type Pose = typeof(LanternAnimation.sample({} :: State, 0))

return table.freeze(LanternAnimation)
