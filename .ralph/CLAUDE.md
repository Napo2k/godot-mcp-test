# Ralph Loop Task

You are executing ONE iteration of a ralph loop for a Godot 4 GDScript project. Complete ONE story, then exit.

## Project Context

This is a Godot 4 roguelike game called "Signal Lost" located at `/Users/napo2k/git/godot-mcp-test`.

Key files for this loop:
- `scripts/room_scene.gd` — RoomScene class, renders tile grid and entities (stories 1, 2, 3, 4)
- `scripts/enemy.gd` — Enemy class, handles AI and positioning (story 3)
- `scripts/game_scene.gd` — Main game scene, creates player node (story 4)

Tileset assets (all 32×32 px tiles):
- `assets/tilesets/_Floors.png` — floor tile variants
- `assets/tilesets/_Walls1.png` — wall tiles
- `assets/tilesets/_Meph_furniture.png` — crates, terminals, containers
- `assets/tilesets/_Meph_decorations_2.png` — pillars, machinery
- `assets/tilesets/_Meph_variety.png` — entity sprites (player, enemies)

## Your Task

1. Read `.ralph/prd.json` to find the next incomplete story (passes: false, lowest priority number)
2. Read the relevant source files before making changes
3. Implement ONLY that story following the description exactly
4. Commit your changes
5. Update prd.json and progress.txt to mark the story complete
6. Exit

## Implementation Rules

- This is GDScript (Godot 4 syntax), NOT Python or TypeScript
- GDScript uses `var`, `func`, `const`, `@export`, `class_name`, `extends`
- `Sprite2D` in Godot 4: use `region_enabled = true` + `region_rect = Rect2(...)` for atlas regions
- `CanvasItem.TEXTURE_FILTER_NEAREST` is the correct constant for pixel art (nearest-neighbor)
- `preload("res://path/to/file.png")` loads a texture at compile time — use this for constants
- `Texture2D` is the correct type hint for preloaded PNG textures
- Do NOT add comments or docstrings to code you did not change
- Do NOT refactor or clean up code beyond what the story asks
- All files are plain text GDScript — use Read + Edit tools, not Bash cat/sed
- When replacing a function body, read the full current function first to get exact line numbers

## Story Completion Protocol

1. **Make changes** using the Edit tool (not Bash sed/awk)

2. **Check for changes:**
   ```bash
   git -C /Users/napo2k/git/godot-mcp-test status --porcelain
   ```

3. **If there ARE changes:**
   - Stage only the files you changed:
     `git -C /Users/napo2k/git/godot-mcp-test add scripts/room_scene.gd scripts/enemy.gd scripts/game_scene.gd`
     (only add files you actually modified)
   - Commit with conventional format:
     `feat: <brief description of visual change>`

4. **Update prd.json:** Set `"passes": true` for the completed story

5. **Append to progress.txt:**
   ```
   [2026-03-13] Completed: story-N - <title>
   ```

6. **Exit immediately** — do NOT start another story

## Important

- Complete exactly ONE story per iteration
- Do not modify stories you are not implementing
- Story 3 touches TWO files (room_scene.gd + enemy.gd) — read both before editing either
- Story 4 touches TWO files (game_scene.gd + room_scene.gd) — read both before editing either
- Tile coordinate reference (col/row → Rect2(col*32, row*32, 32, 32)):
  - Floor variants 0–3: _Floors.png col 0–3, row 0
  - Wall: _Walls1.png col 0, row 0
  - Pillar: _Meph_decorations_2.png col 0, row 0
  - Crate: _Meph_furniture.png col 1, row 0
  - Loot: _Meph_furniture.png col 2, row 0
  - Terminal: _Meph_furniture.png col 3, row 0
  - Enemy default: _Meph_variety.png col 0, row 0
  - Enemy drone: _Meph_variety.png col 2, row 0
  - Enemy heavy: _Meph_variety.png col 4, row 0
  - Enemy elite: _Meph_variety.png col 6, row 0
  - Player: _Meph_variety.png col 8, row 0
