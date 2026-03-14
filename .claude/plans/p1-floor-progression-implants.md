# Plan: P1 — Floor Progression & Implant Bonuses

## Status
Phase: Awaiting Approval
Created: 2026-03-14

## Context

Signal Lost's core loop works but the game is stuck on a single floor forever — `current_floor` never increments, and implants purchased in the Hub are partially or completely ignored at run start. This plan fixes both, making the game winnable for the first time (floor 5 → bridge ending) and making implant purchases actually matter.

Two root causes:
1. `GameManager.start_new_run()` initializes `current_floor = 0` and no code ever advances it
2. `PlayerData.reset_for_run()` only applies 2 of 4 implant bonuses, and all are stored as bools so multiple purchases of the same implant have no effect

---

## Objectives

### Must Have
- `MAX_FLOORS` constant in `game_manager.gd` controls run length (default: 5)
- `advance_floor()` function in `game_manager.gd` increments floor, regenerates layout, triggers ending at MAX_FLOORS
- `FloorGenerator.generate()` receives `current_floor` as `floor_depth` so layout complexity scales
- All 4 implant types apply bonuses in `reset_for_run()`: max_hp, max_ap, max_sanity, damage_bonus
- Implant purchases stack — buying the same implant 3× gives 3× the bonus
- `implant_sanity` per-hit resistance in `lose_sanity()` also scales with purchase count

### Must NOT
- Do not implement new room types or UI for this plan (elevator trigger uses existing room tag mechanism)
- Do not touch WS-9 (stash) — it's already working per research
- Do not implement WS-P2 ending triggers beyond the floor-5 bridge ending (hangar/source require separate design work)
- Do not change implant purchase prices or the Hub UI

---

## Implementation Steps

### WS-2: Implant Bonuses (do first — independent, quick)

**Step 1 — Change implant storage to int in `save_manager.gd`**

In `buy_implant(id, cost)`, change:
```gdscript
_data["implants"][id] = true
```
to:
```gdscript
_data["implants"][id] = _data["implants"].get(id, 0) + 1
```

Update `has_implant(id)` to:
```gdscript
func has_implant(id: String) -> bool:
    return get_implants().get(id, 0) > 0
```

> Note: existing saves with `true` values will break — add migration in `get_implants()`:
```gdscript
func get_implants() -> Dictionary:
    var raw: Dictionary = _data.get("implants", {})
    var result: Dictionary = {}
    for k in raw:
        result[k] = raw[k] if raw[k] is int else (1 if raw[k] else 0)
    return result
```

**Step 2 — Apply all 4 implant bonuses in `player_data.gd:reset_for_run()`**

Replace lines 46–48 (current partial application) with:
```gdscript
var imp_hp     : int = implants.get("implant_max_hp", 0)
var imp_ap     : int = implants.get("implant_ap",     0)
var imp_san    : int = implants.get("implant_sanity",  0)
var imp_dmg    : int = implants.get("implant_damage",  0)

max_hp     = base_max_hp + (10 * imp_hp)
max_ap     = base_max_ap + (1  * imp_ap)
max_sanity = base_max_sanity + (20 * imp_san)
damage_bonus = base_damage_bonus + (5 * imp_dmg)
```

> ⚠️ **Check first**: Verify that `damage_bonus` (no `base_` prefix) is the field read by `combat_manager.gd` or `player.gd` when resolving weapon damage. If the field name is different, adjust. Also verify `max_sanity` and `damage_bonus` are declared as run-stat vars (not just `base_*` vars) in `player_data.gd`.

**Step 3 — Scale `implant_sanity` per-hit resistance by count in `player_data.gd:lose_sanity()`**

Replace current live check:
```gdscript
var has_resistance: bool = SaveManager.has_implant("implant_sanity")
var actual: int = max(0, amount - (10 if has_resistance else 0))
```
with:
```gdscript
var imp_san: int = SaveManager.get_implants().get("implant_sanity", 0)
var actual: int = max(0, amount - (10 * imp_san))
```

---

### WS-1: Floor Progression

**Step 4 — Add `MAX_FLOORS` constant to `game_manager.gd`**

Add near the top (after existing constants):
```gdscript
const MAX_FLOORS: int = 5
```

**Step 5 — Add `advance_floor()` to `game_manager.gd`**

```gdscript
func advance_floor() -> void:
    current_floor += 1
    DataLog.log("=== FLOOR %d ===" % (current_floor + 1))

    if current_floor >= MAX_FLOORS:
        trigger_ending("bridge")
        return

    FloorGenerator.generate(randi(), current_floor)
    current_room_id = 0
    _load_game_scene()
    DataLog.log(FloorGenerator.get_room_description(0))
```

**Step 6 — Fix `start_new_run()` to pass `floor_depth` to FloorGenerator**

Change line 27 from:
```gdscript
FloorGenerator.generate(randi())
```
to:
```gdscript
FloorGenerator.generate(randi(), current_floor)
```

**Step 7 — Wire elevator exit to `GameManager.advance_floor()`**

> ⚠️ **Investigate first**: Find where the player exits a room (likely `room_scene.gd` exit trigger or `game_scene.gd`). The floor_generator tags `["bridge", "hangar", "source"]` suggest some rooms are already marked as exit rooms.
>
> The implementation should:
> - Detect when the player steps on/interacts with an exit-tagged room or tile
> - Call `GameManager.advance_floor()`
>
> If no exit interaction exists yet, add a simple one: in `room_scene.gd`, when the player reaches the exit tile (already exists as an obstacle type), emit a signal that `game_scene.gd` or `game_manager.gd` handles.

---

## Files to Modify

| File | Changes |
|------|---------|
| `scripts/save_manager.gd` | `buy_implant()` → int increment; `get_implants()` → migration; `has_implant()` → `> 0` check |
| `scripts/player_data.gd` | `reset_for_run()` → all 4 implant bonuses with stacking; `lose_sanity()` → scaled resistance |
| `scripts/game_manager.gd` | Add `MAX_FLOORS` const; add `advance_floor()`; fix `generate()` call |
| `scripts/room_scene.gd` (or `game_scene.gd`) | Wire exit tile → `GameManager.advance_floor()` |

---

## Acceptance Criteria

- [ ] Buying an implant twice gives double the stat bonus on next run start
- [ ] All 4 implant types (max_hp, max_ap, max_sanity, damage) show their bonus on run start (verify via DataLog or debug print)
- [ ] `current_floor` increments after exiting a floor
- [ ] `FloorGenerator.generate()` is called with the correct floor index (floor 3 produces more branching than floor 0)
- [ ] Completing floor 5 (or MAX_FLOORS) calls `trigger_ending("bridge")` and returns to Hub
- [ ] Existing saves with bool implant values still load correctly (migration in `get_implants()`)

---

## Dependencies & Risks

| Risk | Mitigation |
|------|------------|
| `damage_bonus` field may not exist as a run-stat in `player_data.gd` | Check before Step 2; may need to add `var damage_bonus: int = 0` |
| Exit tile interaction may not exist yet | Step 7 investigates; may need a small addition to room_scene.gd |
| Old saves with bool implant values | Handled by migration in Step 1 |
| `MAX_FLOORS = 5` may feel too short or too long | Constant makes it trivial to adjust |
