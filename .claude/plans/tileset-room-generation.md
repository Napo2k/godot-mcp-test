# Plan: Tileset Room Generation

## Status
Phase: Draft Complete — Awaiting Approval
Created: 2026-03-13

## Context

All room tiles (floors, walls), obstacles, exits, and entity sprites are currently rendered as
`ColorRect` nodes with solid green/red colors. The project now has 17 tileset PNGs in
`assets/tilesets/` (each tile is 32×32 px).

This plan replaces all ColorRect visual nodes in the room with `Sprite2D` nodes that sample
regions from the appropriate tileset. The procedural room generation structure is unchanged;
only the visual layer (what nodes are created) changes.

**Tilesets identified:**
- `_Floors.png` — stone/dungeon floor tile variants (row 0 has usable floor tiles)
- `_Walls1.png` — sci-fi corridor wall tiles
- `_Meph_variety.png` — mixed entity sprites (humanoids, creatures, items)
- `_Meph_furniture.png` — crates, terminals, containers
- `_Meph_decorations_2.png` — pillars, machinery decorations

**Visual style decision:** Natural tileset colors (dark stone/sci-fi palette) — the original
green ColorRect colors are replaced by sprite texture. The dark palette of the Meph tilesets
fits the terminal aesthetic without forcing a tint.

---

## Objectives

### Must Have
- Floor tiles: `Sprite2D` from `_Floors.png`, 3–4 variants selected per-tile via position-seeded RNG
- Wall tiles: `Sprite2D` from `_Walls1.png`, consistent wall tile across border positions
- Obstacles (pillar, crate, loot, terminal): `Sprite2D` from `_Meph_furniture.png` / `_Meph_decorations_2.png`
- Exit tiles: floor-tile sprite + blue `modulate` tint (Color(0.3, 0.6, 1.0)), keep Label overlay
- Enemy sprites: `Sprite2D` from `_Meph_variety.png`, different tile per enemy type
- Player sprite: `Sprite2D` from `_Meph_variety.png`, distinct from enemy tiles
- `TEXTURE_FILTER_NEAREST` on all sprites (pixel art — no blurring when scaled)
- Sprites scale correctly when `_tile_size < 32` via `scale = Vector2(t/32.0, t/32.0)`

### Must NOT
- Do NOT use Godot's `TileMap`/`TileSet` nodes — keep existing procedural structure
- Do NOT change combat, movement, or any game logic — visual layer only
- Do NOT break variable room dimensions or dynamic tile scaling
- Do NOT add new autoloads, new scenes, or new signal wires
- Do NOT change the container hierarchy: `tile_container`, `entity_container`, `overlay_container`
- Do NOT remove the Label overlays on exit tiles (directional arrows must stay)

---

## Implementation Steps

### Story 1 — Floor and wall tiles → Sprite2D
**File: `scripts/room_scene.gd`**

1. At the top of the file (after `class_name RoomScene`), add preloaded texture constants:
   ```gdscript
   const TEX_FLOORS := preload("res://assets/tilesets/_Floors.png")
   const TEX_WALLS  := preload("res://assets/tilesets/_Walls1.png")
   ```

2. Add a private helper method `_make_tile_sprite` after the constants/vars section:
   ```gdscript
   func _make_tile_sprite(tex: Texture2D, col: int, row: int, gx: int, gy: int) -> Sprite2D:
       var spr := Sprite2D.new()
       spr.texture = tex
       spr.region_enabled = true
       spr.region_rect = Rect2(col * 32, row * 32, 32, 32)
       spr.centered = false
       spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
       spr.position = Vector2(gx * _tile_size, gy * _tile_size)
       spr.scale = Vector2(float(_tile_size) / 32.0, float(_tile_size) / 32.0)
       return spr
   ```

3. Replace `_generate_tiles()` body. Remove all ColorRect creation. New body:
   ```gdscript
   func _generate_tiles() -> void:
       var tile_rng := RandomNumberGenerator.new()
       for y in range(room_h):
           for x in range(room_w):
               var is_wall := (x == 0 or y == 0 or x == room_w - 1 or y == room_h - 1)
               var spr: Sprite2D
               if is_wall:
                   spr = _make_tile_sprite(TEX_WALLS, 0, 0, x, y)
               else:
                   tile_rng.seed = x * 7919 + y * 6271 + room_w * 3
                   var variant := tile_rng.randi_range(0, 3)
                   spr = _make_tile_sprite(TEX_FLOORS, variant, 0, x, y)
               tile_container.add_child(spr)
   ```

4. Remove the now-unused color constants `WALL_COLOR` and `FLOOR_COLOR` from the top of the file.
   Keep `PILLAR_COLOR`, `CRATE_COLOR`, `EXIT_COLOR` until Story 2.

---

### Story 2 — Obstacles and exits → Sprite2D
**File: `scripts/room_scene.gd`**

1. Add preloaded texture constants (append to the block from Story 1):
   ```gdscript
   const TEX_FURNITURE    := preload("res://assets/tilesets/_Meph_furniture.png")
   const TEX_DECORATIONS  := preload("res://assets/tilesets/_Meph_decorations_2.png")
   ```

2. Replace `_draw_obstacle()` body. Current signature: `_draw_obstacle(pos, color, symbol)`.
   The `color` parameter is still passed but is now unused — rename to `_color`.
   New body:
   ```gdscript
   func _draw_obstacle(pos: Vector2i, _color: Color, symbol: String) -> void:
       var tex: Texture2D
       var col: int
       var row: int
       match symbol:
           "P":  tex = TEX_DECORATIONS; col = 0; row = 0  # pillar
           "C":  tex = TEX_FURNITURE;   col = 1; row = 0  # crate
           "L":  tex = TEX_FURNITURE;   col = 2; row = 0  # loot
           "T":  tex = TEX_FURNITURE;   col = 3; row = 0  # terminal
           _:    tex = TEX_FURNITURE;   col = 0; row = 0
       var spr := _make_tile_sprite(tex, col, row, pos.x, pos.y)
       tile_container.add_child(spr)
       var lbl := Label.new()
       lbl.text = symbol
       lbl.position = Vector2(pos.x * _tile_size + 10, pos.y * _tile_size + 6)
       overlay_container.add_child(lbl)
   ```

3. Replace `_draw_exit_tile()` body — floor sprite with blue tint, keep Label:
   ```gdscript
   func _draw_exit_tile(exit_pos: Vector2i, label_text: String) -> void:
       var spr := _make_tile_sprite(TEX_FLOORS, 0, 0, exit_pos.x, exit_pos.y)
       spr.modulate = Color(0.3, 0.6, 1.0, 1.0)
       tile_container.add_child(spr)
       var lbl := Label.new()
       lbl.text = label_text
       lbl.position = Vector2(exit_pos.x * _tile_size + 8, exit_pos.y * _tile_size + 6)
       lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
       overlay_container.add_child(lbl)
   ```

4. Remove now-unused color constants: `PILLAR_COLOR`, `CRATE_COLOR`, `EXIT_COLOR`.

---

### Story 3 — Enemy sprites → Sprite2D
**Files: `scripts/room_scene.gd`, `scripts/enemy.gd`**

**Part A — `room_scene.gd:_make_enemy_node()`:**

1. Append to texture constants block:
   ```gdscript
   const TEX_VARIETY := preload("res://assets/tilesets/_Meph_variety.png")
   ```

2. In `_make_enemy_node(etype, pos)`, replace the `var sprite := ColorRect.new()` block with:
   ```gdscript
   var ecol: int
   match etype:
       "drone":  ecol = 2
       "heavy":  ecol = 4
       "elite":  ecol = 6
       _:        ecol = 0
   var sprite := Sprite2D.new()
   sprite.name = "Sprite"
   sprite.texture = TEX_VARIETY
   sprite.region_enabled = true
   sprite.region_rect = Rect2(ecol * 32, 0, 32, 32)
   sprite.centered = true
   sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
   sprite.position = Vector2(0, 0)
   sprite.scale = Vector2(float(_tile_size) / 32.0, float(_tile_size) / 32.0)
   ```
   Remove the old `sprite.size`, `sprite.position`, `sprite.color` lines that followed.

**Part B — `scripts/enemy.gd:_refresh_visuals()`:**

3. Read `enemy.gd` fully first. Find `_refresh_visuals()`.
   If it contains `sprite.size = ...` or `sprite.position = Vector2(-tile_size/2 + ...)`:
   - Replace `sprite.size = Vector2(tile_size - 4, tile_size - 4)` →
     `sprite.scale = Vector2(float(tile_size) / 32.0, float(tile_size) / 32.0)`
   - Remove any `sprite.position = ...` offset lines (centered=true handles positioning)

---

### Story 4 — Player sprite → Sprite2D
**File: `scripts/game_scene.gd`**

1. Add preloaded texture constant at the top of the file:
   ```gdscript
   const TEX_VARIETY := preload("res://assets/tilesets/_Meph_variety.png")
   ```

2. In `_setup_player()`, replace the ColorRect sprite block:
   ```gdscript
   # REMOVE:
   var sprite := ColorRect.new()
   sprite.name = "Sprite"
   sprite.size = Vector2(24, 24)
   sprite.position = Vector2(-12, -12)
   sprite.color = Color(0.0, 0.9, 0.3, 1.0)
   _player.add_child(sprite)

   # REPLACE WITH:
   var sprite := Sprite2D.new()
   sprite.name = "Sprite"
   sprite.texture = TEX_VARIETY
   sprite.region_enabled = true
   sprite.region_rect = Rect2(8 * 32, 0, 32, 32)  # col 8, row 0 — player sprite
   sprite.centered = true
   sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
   sprite.position = Vector2(0, 0)
   _player.add_child(sprite)
   ```

3. In `scripts/room_scene.gd:load_room()`, after the line `player.tile_size = _tile_size`,
   add player sprite scale update:
   ```gdscript
   var pspr := player.get_node_or_null("Sprite") as Sprite2D
   if pspr:
       pspr.scale = Vector2(float(_tile_size) / 32.0, float(_tile_size) / 32.0)
   ```

---

## Files to Modify

| File | Stories | Changes |
|------|---------|---------|
| `scripts/room_scene.gd` | 1, 2, 3, 4 | Texture preloads, `_make_tile_sprite` helper, replace `_generate_tiles`, `_draw_obstacle`, `_draw_exit_tile`, `_make_enemy_node`; add player scale update in `load_room` |
| `scripts/game_scene.gd` | 4 | Replace player ColorRect sprite in `_setup_player()` |
| `scripts/enemy.gd` | 3 | Update `_refresh_visuals()` for Sprite2D if it modifies sprite size |

---

## Tile Coordinate Reference

All coordinates are `(col, row)` where `Rect2 = Rect2(col*32, row*32, 32, 32)`.
**These are starting approximations — verify visually in the Godot editor before finalizing.**

| Element | Texture | col | row | Notes |
|---------|---------|-----|-----|-------|
| Floor variant 0–3 | `_Floors.png` | 0–3 | 0 | seeded random per tile position |
| Wall | `_Walls1.png` | 0 | 0 | same for all border tiles |
| Exit tile | `_Floors.png` | 0 | 0 | + blue modulate |
| Pillar | `_Meph_decorations_2.png` | 0 | 0 | |
| Crate | `_Meph_furniture.png` | 1 | 0 | |
| Loot | `_Meph_furniture.png` | 2 | 0 | |
| Terminal | `_Meph_furniture.png` | 3 | 0 | |
| Enemy default | `_Meph_variety.png` | 0 | 0 | |
| Enemy drone | `_Meph_variety.png` | 2 | 0 | |
| Enemy heavy | `_Meph_variety.png` | 4 | 0 | |
| Enemy elite | `_Meph_variety.png` | 6 | 0 | |
| Player | `_Meph_variety.png` | 8 | 0 | distinct from all enemy cols |

---

## Acceptance Criteria

- [ ] Room floors show textured sprites from `_Floors.png` — no solid green fill
- [ ] Room border walls show sprites from `_Walls1.png` — no solid dark green fill
- [ ] Floor tiles have visible variation across positions (seeded variants, not all identical)
- [ ] Obstacles (crates, pillars, terminals) show furniture/decoration sprites
- [ ] Exit tiles show as tinted floor sprites with directional arrow labels still visible
- [ ] Player shows a distinct character sprite from `_Meph_variety.png` (not a green square)
- [ ] Enemies show different sprites per type (guard ≠ drone ≠ heavy)
- [ ] Variable room sizes (14–22 wide, 8–14 tall) render correctly with scaled sprites
- [ ] No GDScript errors at startup or during room transitions
- [ ] Tile scaling (`_tile_size` 16–32) does not cause sprites to overlap or misalign
