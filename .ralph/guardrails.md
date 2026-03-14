# Ralph Loop Guardrails

## Scope Boundaries

This loop implements: `.claude/plans/p1-floor-progression-implants.md`

### In Scope
- `scripts/save_manager.gd` — implant storage schema change
- `scripts/player_data.gd` — implant bonus application and sanity resistance scaling
- `scripts/game_manager.gd` — MAX_FLOORS constant, advance_floor() function, FloorGenerator call fix
- `scripts/room_scene.gd` and/or `scripts/game_scene.gd` — elevator exit wiring

### Out of Scope
- Hub UI (hub.gd) — do not modify implant purchase UI, prices, or display
- WS-9 stash integration — already working, do not touch
- Hangar/source endings — only bridge ending triggers at MAX_FLOORS
- New room types or FloorGenerator internals
- NavCom, MiasmaMgr, DataLog internals
- Any script not listed above
- Scene files (.tscn)

## Commit Standards

- One commit per story
- Format: `feat: <brief description>`
- Stage only files you actually changed (do not use git add -A)

## Blocking Conditions

Stop and document in progress.txt if:
- A file's structure differs significantly from what the plan describes
- A required function does not exist in the target file
- Story 6 finds no exit tile mechanism at all — document the finding and exit

## Recovery

If the loop stalls:
1. Check `progress.txt` for last successful story
2. Check `git -C /Users/napo2k/git/cthulAI log --oneline` for committed work
3. Check `prd.json` for story states
4. Resume with: `uv run .ralph/loop.py`
