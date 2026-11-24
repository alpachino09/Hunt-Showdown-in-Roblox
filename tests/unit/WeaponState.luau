--!strict

local Definitions = require("../../src/shared/weapons/WeaponDefinitions")
local WeaponState = require("../../src/server/weapons/WeaponStateService")

local function completeStage(state: WeaponState.State): number
    local pending = assert(state.reload, "Expected a pending reload stage")
    assert(WeaponState.advance(state, pending.revision, pending.nextAt), "A due stage must advance")
    return pending.nextAt
end

for _, weapon in Definitions.expedition do
    local state = WeaponState.new(weapon)
    assert(WeaponState.beginReload(state, 0) == nil, "Full weapons cannot reload")
    assert(WeaponState.fire(state, 0), "A loaded weapon must fire")
    assert(not WeaponState.fire(state, weapon.delay / 2), "Reject fire during cooldown")
    assert(WeaponState.fire(state, weapon.delay), "A shot is allowed when cooldown ends")
    local pending = assert(WeaponState.beginReload(state, 2), "Start batch reload")
    assert(pending.stage == "Batch", "Legacy weapons use batch reload")
    assert(WeaponState.beginReload(state, 2.1) == nil, "Reject repeat reload")
    assert(not WeaponState.fire(state, pending.nextAt - 0.1), "Block fire during batch reload")
    assert(
        not WeaponState.advance(state, pending.revision, pending.nextAt - 0.1),
        "Batch reload cannot finish early"
    )
    assert(
        state.loaded == weapon.capacity - 2 and state.reserve == weapon.reserve,
        "Reserve changes only at commit"
    )
    completeStage(state)
    assert(
        state.loaded == weapon.capacity and state.reserve == weapon.reserve - 2,
        "Fill and debit the missing rounds"
    )
    assert(
        not WeaponState.advance(state, pending.revision, pending.nextAt + 1),
        "Completed reload cannot commit twice"
    )

    assert(WeaponState.fire(state, 6), "Fire after legacy reload")
    local abandoned =
        assert(WeaponState.beginReload(state, 7), "Start reload before lifecycle abort")
    WeaponState.abort(state)
    local replacement = assert(WeaponState.beginReload(state, 8), "Start replacement reload")
    assert(
        not WeaponState.advance(state, abandoned.revision, replacement.nextAt),
        "Stale callback cannot affect replacement reload"
    )
    completeStage(state)
    assert(
        state.loaded == weapon.capacity and state.reserve == weapon.reserve - 3,
        "Spend reserve only for the accepted reload"
    )
end

local lantern = WeaponState.new(Definitions.lantern)
assert(lantern.chamber == "Live" and WeaponState.fire(lantern, 0), "First chamber is live")
assert(lantern.chamber == "Spent" and lantern.loaded == 0, "A shot leaves a spent chamber")
assert(not WeaponState.fire(lantern, 1), "A spent chamber cannot fire")
local opening = assert(WeaponState.beginReload(lantern, 1), "Open first reload")
assert(WeaponState.cancel(lantern, 1.1), "Allow early cancellation")
local closing = assert(lantern.reload, "Canceled mechanism must close")
local previouslyOpen = (1.1 - opening.startedAt) / (opening.nextAt - opening.startedAt)
assert(closing.closeFrom == previouslyOpen, "Close begins at the current hinge progress")
assert(
    lantern.chamber == "Spent" and lantern.reserve == Definitions.lantern.reserve,
    "Early cancellation preserves spent chamber and reserve"
)
assert(
    not WeaponState.advance(lantern, opening.revision, opening.nextAt + 10),
    "Early cancel invalidates old stages"
)
completeStage(lantern)

assert(WeaponState.beginReload(lantern, 3), "Restart after early cancellation")
completeStage(lantern)
local ejectedAt = completeStage(lantern)
assert(lantern.chamber == "Empty", "Ejection leaves the chamber empty")
assert(WeaponState.cancel(lantern, ejectedAt + 0.01), "Allow cancel after ejection")
completeStage(lantern)
assert(
    lantern.chamber == "Empty" and lantern.reserve == Definitions.lantern.reserve,
    "Keep the chamber empty after cancel"
)

assert(WeaponState.beginReload(lantern, 6), "Restart from openable empty chamber")
completeStage(lantern)
assert(
    (assert(lantern.reload, "Expected timeline for the insertion")).stage == "Insert",
    "Skip ejection when the chamber is empty"
)
local insertion = assert(lantern.reload, "Expected timeline for the insertion")
assert(
    WeaponState.cancel(lantern, insertion.nextAt),
    "Resolve insertion before cancel at the boundary"
)
assert(lantern.chamber == "Live" and lantern.loaded == 1, "A confirmed insertion survives cancel")
assert(lantern.reserve == Definitions.lantern.reserve - 1, "Debit exactly one from the reserve")
assert(not WeaponState.fire(lantern, insertion.nextAt), "Wait for the closing phase before fire")
local readyAt = completeStage(lantern)
assert(WeaponState.fire(lantern, readyAt), "Fire after closing")

local function drainReserve()
    local state = WeaponState.new(Definitions.lantern)
    for index = 1, Definitions.lantern.reserve do
        local now = index * 10
        assert(WeaponState.fire(state, now), "Fire a shot during reserve drain")
        local reload =
            assert(WeaponState.beginReload(state, now + 1), "Reload from the remaining reserve")
        local total = state.loaded + state.reserve
        assert(
            WeaponState.advance(state, reload.revision, now + 9),
            "Catch up overdue reload phases"
        )
        assert(
            state.loaded + state.reserve == total,
            "Moving ammo into the chamber preserves its total"
        )
        assert(
            state.reload == nil and state.chamber == "Live",
            "Fully caught up reload leaves a live chamber"
        )
    end
    assert(WeaponState.fire(state, 100), "Fire the final loaded round")
    assert(
        WeaponState.beginReload(state, 101) == nil and state.reserve == 0,
        "Reject reload with an empty reserve"
    )
end

drainReserve()
print(
    "WeaponState: both catalog weapons and single-chamber fire, reload, cancel and lifecycle passed"
)
