# Plan: Fix obstacle color constant errors in room_scene.gd

## Context
The previous tileset/sprite upgrade removed color-based rendering but left behind two references to constants (`PILLAR_COLOR`, `CRATE_COLOR`) that were never defined. The `_draw_obstacle` function doesn't even use the color (parameter is `_color` — intentionally unused), so this is purely a compilation fix.

## Objectives

### Must Have
- Eliminate both parse errors so the project runs

### Must NOT
- Define new module-level constants (inconsistent with existing pattern)
- Touch anything outside the two broken lines

## Implementation Steps

1. **`scripts/room_scene.gd` line 167** — Replace `PILLAR_COLOR` with `Color(0.5, 0.5, 0.5, 1.0)` (grey/stone)
2. **`scripts/room_scene.gd` line 175** — Replace `CRATE_COLOR` with `Color(0.6, 0.35, 0.1, 1.0)` (brown/wood)

## Files to Modify
| File | Changes |
|------|---------|
| `scripts/room_scene.gd` | Lines 167, 175: replace undefined constants with inline Color literals |

## Acceptance Criteria
- [ ] Project opens without parse errors
- [ ] Obstacles (pillars/crates) still spawn in rooms
- [ ] No regression to loot/terminal placement
