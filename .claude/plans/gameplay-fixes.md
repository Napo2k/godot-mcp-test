# Gameplay Fixes: Weapon Start, Random Spawn, Variable Rooms

## Problem Statement

Three bugs discovered during playtesting:
1. Player has no weapon to begin with — no attack possible on fresh save
2. Player always spawns at the same grid position (hardcoded Vector2i(2, 5))
3. Rooms are always the same shape and size (fixed 18x10 tile grid)

The room size fix requires the PaneA viewport to adapt to varying room dimensions dynamically.

## Implementation Steps

1. Give player a Scrap Blade weapon on every new run — in `player_data.gd:reset_for_run()`, replace `equipped_weapon1 = null` with `equipped_weapon1 = ItemData.make_scrap_blade()` so every run starts with a melee weapon equipped

2. Randomize player spawn position in the room's left zone — in `room_scene.gd:load_room()`, replace the hardcoded `Vector2i(2, ROOM_H / 2)` with a seeded-RNG spawn finder that picks a random walkable tile at x in [1..3], y in [1..room_h-2], avoiding obstacles and exits; add helper `_find_spawn_pos(rng)` method

3. Add variable room dimensions per room — in `room_scene.gd`, replace `const ROOM_W := 18` and `const ROOM_H := 10` with instance vars `var room_w: int = 18` and `var room_h: int = 10`; at the top of `load_room()` seed a RNG from `room_data["id"] * 9157 + FloorGenerator.get_current_seed()` and roll `room_w = randi_range(14, 22)` and `room_h = randi_range(8, 14)`; replace all ROOM_W/ROOM_H references throughout the file

4. Add dynamic tile sizing so variable rooms always fit in PaneA — in `room_scene.gd`, change `const TILE_SIZE := 32` to `var _tile_size: int = 32`; in `load_room()` after calculating room dimensions, query `GameManager.hud.get_pane_a_content().size` (fallback 636×330) and compute `_tile_size = clamp(min(available_w/room_w, available_h/room_h), 16, 32)` as integer; replace all TILE_SIZE refs in tile/exit/obstacle/enemy drawing code with `_tile_size`; in `_make_enemy_node()` set `enemy.tile_size = _tile_size` before calling `enemy.setup()`; in `load_room()` set `player.tile_size = _tile_size` before calling `player._sync_visual()`

5. Update Player to use variable tile_size — in `player.gd`, change `const TILE_SIZE := 32` to `var tile_size: int = 32` and update `_sync_visual()` to use `tile_size` instead of `TILE_SIZE`

6. Update Enemy to use variable tile_size — in `enemy.gd`, change `const TILE_SIZE := 32` to `var tile_size: int = 32` and update both position calculations in `setup()` and `_refresh_visuals()` to use `tile_size` instead of `TILE_SIZE`
