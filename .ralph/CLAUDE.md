# Ralph Loop Task

You are executing ONE iteration of a ralph loop for a Godot 4 GDScript project. Complete ONE story, then exit.

## Project Context

This is a Godot 4 roguelike game called "Signal Lost" located at `/Users/napo2k/git/godot-mcp-test`.

Key files:
- `scripts/player_data.gd` — PlayerData autoload, manages run stats and gear
- `scripts/room_scene.gd` — RoomScene class, renders the tile grid and entities
- `scripts/player.gd` — Player class, handles movement and combat
- `scripts/enemy.gd` — Enemy class, handles AI and positioning
- `scripts/item_data.gd` — ItemData resource class with static factory methods

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
- Integer division in GDScript: use `int(x / y)` or `floori(x / y)` for explicit floor
- `clamp(value, min, max)` works on ints and floats
- Do NOT add comments or docstrings to code you did not change
- Do NOT refactor or clean up code beyond what the story asks
- When a story says "replace ROOM_W/ROOM_H/TILE_SIZE throughout", do a careful grep first: `grep -n "ROOM_W\|ROOM_H\|TILE_SIZE" scripts/room_scene.gd`
- All files are plain text GDScript — use Read + Edit tools, not Bash cat/sed

## Story Completion Protocol

1. **Make changes** using the Edit tool (not Bash sed/awk)

2. **Check for changes:**
   ```bash
   git status --porcelain
   ```

3. **If there ARE changes:**
   - Stage: `git add scripts/player_data.gd scripts/room_scene.gd scripts/player.gd scripts/enemy.gd` (only the changed files)
   - Commit with conventional format describing the fix
   - Format: `fix: <brief description>`

4. **Update prd.json:** Set `"passes": true` for the completed story

5. **Append to progress.txt:**
   ```
   [2026-03-01] Completed: story-N - <title>
   ```

6. **Exit immediately** — do NOT start another story

## Important

- Complete exactly ONE story per iteration
- Do not modify stories you are not implementing
- If a story references line numbers, always read the file first to verify current line numbers
- The stories must be done in priority order (story-1 first, then story-2, then story-3)
- story-3 touches THREE files — read all three before editing any of them
