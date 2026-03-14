# Ralph Loop Task

You are executing ONE iteration of a ralph loop for a Godot 4 GDScript project. Complete ONE story, then exit.

## Project Context

This is a Godot 4 roguelike called "Signal Lost" at `/Users/napo2k/git/cthulAI`.

Key autoloads (globally available, no import needed):
- `GameManager` — run state, floor counter, ending triggers
- `PlayerData` — player stats, reset_for_run(), implant application
- `SaveManager` — persistent save data, implant storage, stash
- `FloorGenerator` — procedural room graph generation
- `DataLog` — in-game log display
- `MiasmaMgr` — station instability tracker

Key files for this loop:
- `scripts/save_manager.gd` — implant CRUD (story 1)
- `scripts/player_data.gd` — stat application at run start, lose_sanity() (stories 2, 3)
- `scripts/game_manager.gd` — run control, floor advancement (stories 4, 5)
- `scripts/room_scene.gd` — room rendering, player movement, exit detection (story 6)
- `scripts/game_scene.gd` — game scene setup, may be needed for story 6

## Your Task

1. Read `.ralph/prd.json` to find the next incomplete story (`passes: false`, lowest `priority` number)
2. Read the relevant source file(s) FULLY before making any changes
3. Implement ONLY that story following the description exactly
4. Commit your changes
5. Update prd.json and progress.txt
6. Exit

## Quality Gates

This is a GDScript project — no automated linter or test runner is configured.

Manual quality check before committing:
- Ensure GDScript syntax is valid (correct indentation, no missing colons, valid type hints)
- Ensure no variables are referenced before they are declared
- Ensure function signatures match how they are called at all call sites

## GDScript Rules

- GDScript uses `var`, `func`, `const`, `@export`, `class_name`, `extends`
- Type hints: `var x: int`, `func foo(a: String) -> bool:`
- Dictionary access: `dict.get("key", default)` — use this, not `dict["key"]`
- `is int` type check works in GDScript 4 for type migration
- Autoloads are singletons — call them directly: `SaveManager.get_implants()`
- Do NOT add comments or docstrings to code you did not change
- Do NOT refactor or clean up code beyond what the story asks
- All files are plain text GDScript — use Read + Edit tools, not Bash cat/sed
- When replacing a function body, read the full current function first to get exact line numbers

## Story Completion Protocol

1. **Make changes** using the Edit tool (not Bash sed/awk)

2. **Check for changes:**
   ```bash
   git -C /Users/napo2k/git/cthulAI status --porcelain
   ```

3. **If there ARE changes:**
   - Stage only the files you changed:
     `git -C /Users/napo2k/git/cthulAI add scripts/save_manager.gd scripts/player_data.gd scripts/game_manager.gd scripts/room_scene.gd scripts/game_scene.gd`
     (only include files you actually modified)
   - Commit with conventional format:
     `feat: <brief description>`
   - Example: `feat: change implant storage from bool to int for stacking`

4. **Update prd.json:** Set `"passes": true` for the completed story

5. **Append to progress.txt:**
   ```
   [2026-03-14] Completed: story-N - <title>
   ```

6. **Exit immediately** — do NOT start another story

## Story-Specific Notes

### Story 1 (save_manager.gd)
The existing buy_implant() guard prevents purchasing the same implant twice. Remove that guard — stacking requires allowing repeated purchases of the same implant.

### Story 2 (player_data.gd — reset_for_run)
The `implants` dict is already fetched near the top of reset_for_run(). Reuse that variable — do not call SaveManager.get_implants() a second time. Check whether `damage_bonus` (without base_ prefix) exists as a declared var before adding the assignment.

### Story 3 (player_data.gd — lose_sanity)
Minimal change: 2 lines replaced. The rest of lose_sanity() stays unchanged.

### Story 4 (game_manager.gd)
Place MAX_FLOORS near existing constants. Place advance_floor() near start_new_run() or trigger_ending() for logical grouping.

### Story 5 (game_manager.gd)
One line change in start_new_run(). Minimal diff.

### Story 6 (room_scene.gd / game_scene.gd)
Read both files fully first. This story requires investigation — the exact implementation depends on how exit tile interaction currently works. Follow Option A or B as described in the story.

## Important

- Complete exactly ONE story per iteration
- Do not skip stories or reorder them
- Do not modify stories you are not implementing
- If blocked by an unexpected code structure, document in progress.txt and exit
