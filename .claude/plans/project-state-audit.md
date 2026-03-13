# Plan: Signal Lost — Project State Audit & Remaining Workstreams

## Status
Phase: Draft Complete — Awaiting Approval
Created: 2026-03-13

## Context

Signal Lost is a Godot 4 turn-based roguelike with a 4-pane CRT terminal aesthetic.
The ralph loop finished its 3 gameplay bug fixes (weapon start, random spawn, variable rooms).
This audit identifies what the design document specifies vs. what is actually implemented.

All 6 autoloads are functional. The core game loop (enter room → combat → loot → move) works.
The gaps are in depth systems, progression, and polish layers.

---

## Workstream Status Overview

### ✅ COMPLETE Workstreams

| Feature | Evidence |
|---------|----------|
| 4-pane CRT HUD layout | `scenes/main.tscn`, `scripts/main.gd` |
| Room rendering + tile grid | `scripts/room_scene.gd` (variable size, dynamic tile scaling) |
| Player movement + melee combat | `scripts/player.gd` |
| Enemy AI + turn-based combat loop | `scripts/enemy.gd`, `scripts/combat_manager.gd` |
| Cover system (LoS + accuracy penalty) | `scripts/cover_system.gd` |
| Procedural floor generation (seeded) | `scripts/floor_generator.gd` |
| NavCom map (node graph) | `scripts/nav_com.gd` |
| Data Log (Pane D) | `scripts/data_log.gd` |
| Miasma/Station Instability tracker | `scripts/miasma_manager.gd` |
| Hub/Cabin screen | `scripts/hub.gd`, `scenes/hub.tscn` |
| Neuro-Implant purchases (4 types) | `hub.gd:17-22` |
| Save/load (scrip, implants, endings) | `scripts/save_manager.gd` |
| Weapon 1 starting item (Scrap Blade) | `player_data.gd` (ralph story-1) |
| Random player spawn | `room_scene.gd` (ralph story-2) |
| Variable room dimensions + tile scaling | `room_scene.gd`, `player.gd`, `enemy.gd` (ralph story-3) |
| Ending logic structure | `game_manager.gd:76` — all 3 endings wired |

---

### 🔴 NOT STARTED Workstreams

#### WS-1: Floor Progression
**Gap:** `current_floor` is initialized to 0 and never increments. There is no "next floor" trigger or elevator room. The game is currently one-floor-only.
- `game_manager.gd:25` — `var current_floor: int = 0` (never mutated)
- No `next_floor()` function exists
- `trigger_ending("bridge")` etc. exist but **nothing calls them**
- **Scope:** Add floor counter increment, elevator room type in FloorGenerator, and wire elevator → `trigger_ending`

#### WS-2: Implant Bonuses Applied at Run Start
**Gap:** Players can buy implants (max_hp, sanity, ap, damage) in the Hub but `start_new_run()` in `game_manager.gd:21-34` never reads `SaveManager.get_implants()` or applies stat bonuses to `PlayerData`.
- Implants are cosmetically purchased but functionally inert
- **Scope:** In `game_manager.gd:start_new_run()`, after `PlayerData.reset_for_run()`, apply implant bonuses from `SaveManager`

#### WS-3: Hallway Events (Lockers, Terminals, Demented Echoes)
**Gap:** Design doc §3 specifies events triggered when moving between rooms. None are implemented:
- Lockers: random loot drops in hallways
- Terminals: lore fragments + blueprint upload points
- Demented Echoes: async ghost mechanic (other players' deaths)
- **Scope:** Large — new event system, terminal interaction UI, online component (Echoes is largest)

#### WS-4: Blueprint System
**Gap:** Design doc §4 specifies blueprints found in runs, uploaded at terminals, permanently unlocked in Hub. Not present in any script.
- No `BlueprintData` resource class
- No terminal interaction
- No blueprint display in Hub
- **Scope:** Medium — new item type, terminal UI, Hub blueprint display

#### WS-5: Equipment Slots (Weapon 2, Core Suit, Utility Chips)
**Gap:** `PlayerData` likely has slots but only `equipped_weapon1` is used. Hub stash only saves weapon 1. Design doc §2 specifies a full paper doll.
- `hub.gd:93` — stash is weapon1-only
- No UI for selecting equipped items
- **Scope:** Medium — expand Hub UI, wire all slots into combat

#### WS-6: Sanity/Mental Health System
**Gap:** Design doc §4 specifies Mental Health (Sanity) stat. `PlayerData` likely tracks `sanity` but:
- No sanity drain during combat
- No "Ghost enemies" spawned at low sanity
- No visual effect at low sanity (should affect Pane A rendering)
- **Scope:** Medium — drain hook in `combat_manager.gd`, ghost spawn logic, visual hook

#### WS-7: Miasma Visual Effects
**Gap:** `MiasmaMgr` correctly tracks Station Instability and grants enemy MP bonus. But design doc specifies visible CRT glitches at high Miasma values. Nothing visual is wired.
- `main.gd` likely has no Miasma signal listener
- No shader or draw-call distortion tied to Miasma level
- **Scope:** Small-Medium — add `MiasmaMgr.instability_changed` signal listener in `main.gd`, drive visual CRT effect

#### WS-8: Hub Cabin Evolution (Notes & Trophies)
**Gap:** Design doc §5: "The Cabin fills with notes and trophies as you complete runs." Not implemented.
- No visual changes to hub based on run count or endings discovered
- **Scope:** Small — conditional rendering in `hub.gd` based on `SaveManager` run count / endings

#### WS-9: Stash Integration into Run
**Gap:** Players can stash weapon1 in Hub but `start_new_run()` never retrieves or injects the stashed item into the run.
- `hub.gd:92-101` — saves to `SaveManager` correctly
- `game_manager.gd:start_new_run()` — never reads stash
- **Scope:** Small — one function call in `start_new_run()`

---

### 🟡 PARTIAL Workstreams

#### WS-P1: Combat Depth (AP/MP, Turn Counter, Cover, Door Locking)
**Gap:** Core combat loop works but several design doc features are missing:
- Turn counter never increments past "Turn 1" (`combat_manager.gd:19`)
- Cover system exists (`cover_system.gd`) but is **not called** from `combat_manager.gd`, `player.gd`, or `enemy.gd`
- Door-locking on combat enter: message logged but no game state set
- AP enforcement: tracked in Player but not validated in CombatManager
- **Scope:** Medium — wire cover into attack resolution, add turn counter, implement door state

#### WS-P2: Ending Triggers
**Gap:** `trigger_ending()` is fully implemented in `game_manager.gd:76` with all 3 ending types, scrip rewards, and save recording — but **nothing calls it**.
- Bridge ending (elevator on Floor 5): no floor 5 detection
- Hangar ending: not specified where it triggers
- Source ending: requires 3 lore items — logic exists in `room_scene.gd:288` but is disconnected
- **Scope:** Small-Medium — add trigger calls in appropriate room types (depends on WS-1)

#### WS-P3: NavCom Polish
**Gap:** NavCom draws the floor graph correctly but is missing:
- Elevator blinking ping animation (static dot, code comment says "blinking")
- Hallway event markers on connections (depends on WS-3)
- Miasma-driven visual glitches on map (depends on WS-7)
- **Scope:** Small for the ping animation alone

---

## Priority Matrix

| Workstream | Impact | Effort | Priority |
|-----------|--------|--------|----------|
| WS-2: Implant bonuses applied | High | XS | **P1** |
| WS-9: Stash integration | Medium | XS | **P1** |
| WS-1: Floor progression | High | S | **P1** |
| WS-P2: Ending triggers | High | S | **P1** |
| WS-P1: Combat depth (cover, turns) | High | M | **P2** |
| WS-6: Sanity system | High | M | **P2** |
| WS-7: Miasma visual effects | Medium | S | **P2** |
| WS-P3: NavCom ping animation | Low | XS | **P2** |
| WS-8: Hub cabin evolution | Low | S | **P3** |
| WS-5: Equipment slots | High | M | **P3** |
| WS-4: Blueprint system | Medium | L | **P3** |
| WS-3: Hallway events | High | XL | **P4** |

---

## Acceptance Criteria (for this audit)

- [ ] All workstreams documented with specific file:line evidence
- [ ] Priority order agreed upon
- [ ] Next ralph loop plan targets P1 workstreams
