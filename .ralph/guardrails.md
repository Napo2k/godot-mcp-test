# Ralph Loop Guardrails

## Scope Boundaries

This loop implements: `.claude/plans/gameplay-fixes.md`

### In Scope
- `scripts/player_data.gd` — add starting weapon
- `scripts/room_scene.gd` — randomize spawn, variable room size, dynamic tile scaling
- `scripts/player.gd` — tile_size var
- `scripts/enemy.gd` — tile_size var

### Out of Scope
- Any other scripts (game_manager.gd, floor_generator.gd, etc.)
- Scene files (.tscn)
- Shaders
- Refactoring unrelated code
- Adding new features beyond the 3 bug fixes

## GDScript Constraints

- No Python/TypeScript syntax
- Variable declarations require type hint or explicit value: `var x: int = 32`
- `clamp()` accepts int or float — use `int(clamp(...))` when int required
- `RandomNumberGenerator.new()` — must call `.seed = value` after construction
- `floori(x)` returns int in Godot 4; `floor(x)` returns float

## Commit Standards

- One commit per story
- Format: `fix: <description of what was fixed>`
- Stage only files you actually changed

## Blocking Conditions

Stop and document in progress.txt if:
- A file has changed significantly from what the story describes (verify line numbers)
- A story would break another story's changes
- The GDScript syntax produces an obvious error

## Recovery

If the loop stalls:
1. Check `progress.txt` for last successful story
2. Check `git log --oneline` for committed work
3. Check `prd.json` for story states
4. Resume with: `uv run .ralph/loop.py`
