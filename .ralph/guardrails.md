# Ralph Loop Guardrails

## Scope Boundaries

This loop implements: `.claude/plans/tileset-room-generation.md`

### In Scope
- `scripts/room_scene.gd` — tile drawing, obstacle drawing, enemy sprite creation, player scale hook
- `scripts/game_scene.gd` — player sprite creation in _setup_player()
- `scripts/enemy.gd` — _refresh_visuals() update for Sprite2D (if it references sprite.size)

### Out of Scope
- Any other scripts (player.gd, game_manager.gd, floor_generator.gd, player_data.gd, etc.)
- Scene files (.tscn)
- Combat, movement, or game logic of any kind
- Adding new autoloads or signals
- Changing room dimensions or tile sizing logic

## GDScript Constraints

- No Python/TypeScript syntax
- `preload()` only works with `res://` paths (project-relative), not filesystem paths
- `Sprite2D.region_enabled` must be set to `true` before `region_rect` takes effect
- `CanvasItem.TEXTURE_FILTER_NEAREST` — correct constant name for nearest-neighbor filtering
- `Texture2D` — correct type for PNG textures loaded with preload()
- `centered = false` for tile sprites (position = top-left corner of tile)
- `centered = true` for entity sprites (position = center of entity node)

## Commit Standards

- One commit per story
- Format: `feat: <description of visual change>`
- Stage only files you actually changed (do not use git add -A)

## Blocking Conditions

Stop and document in progress.txt if:
- A const/function being replaced cannot be found in the current file
- A GDScript syntax error is obvious from the code structure
- The _Floors.png or _Walls1.png file appears to not have tiles at the expected coordinates

## Recovery

If the loop stalls:
1. Check `progress.txt` for last successful story
2. Check `git -C /Users/napo2k/git/godot-mcp-test log --oneline` for committed work
3. Check `prd.json` for story states
4. Resume with: `uv run .ralph/loop.py`
