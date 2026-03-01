- # 🛰️ SIGNAL LOST: Game Design Document (RC 1.0)
- ## 1. Executive Summary
  
  **SIGNAL LOST** is a top-down, psychological sci-fi roguelite set on a decaying space station. The player assumes the role of a survivor trapped in a recurring "Nightmare" loop. Drawing inspiration from *Cogmind*, *Teleglitch*, and *Darkest Dungeon*, the game blends fast-paced exploration with high-stakes tactical combat. The primary goal is to reach the station’s Bridge to send a distress signal, though alternative escape routes and secrets suggest a deeper, more malevolent truth behind the station's downfall.  
  
---
- ## 2. Diegetic CRT Interface System
  
  The game is viewed through a simulated 4-pane CRT terminal. The UI features spherical distortion, scanlines, and phosphorus flickering.  
  
  | **Pane** | **Name** | **Technical Function** |
  |---|---|---|
  | **A (Top-Left)** | **THE VIEWPORT** | Main gameplay window. Renders the room grid. Toggles between **Real-Time Exploration** (free movement) and **Tactical Turn-Based Combat** (AP/MP restricted). |
  | **B (Top-Right)** | **NAV-COM (MAP)** | A node-based schematic of the floor (Darkest Dungeon style). Displays discovered rooms, hallways, and "pings" for the elevator/exit. |
  | **C (Bottom-Left)** | **BIO-STATUS / GEAR** | Displays HP, Mental Health, AP, and MP. Contains the "Paper Doll" equipment system (Weapon 1, Weapon 2, Core Suit, Utility Chips). Gear here defines available combat actions. |
  | **D (Bottom-Right)** | **DATA LOG** | Scrolling text buffer. Outputs combat math, environmental descriptions ("You hear scratching in the vents"), and narrative "Nightmare" text logs. |
  
---
- ## 3. The Dual-Layer Gameplay Loop
- ### Layer 1: Strategic Floor Navigation (The Map)
  
  The player navigates the station sector-by-sector (e.g., Garbage Collection, Hydroponics, Science Labs).  
	- **Movement:** Players move between room nodes via hallways.
	- **Events:** Hallways contain lockers (loot), terminals (lore/crafting), or "Demented Echoes" (remains of other players).
	- **The Miasma (Stress Mechanic):** A "Station Instability" meter that increases with every turn/move, and potentially via randomly selected run modifiers.
		- **Low Miasma:** Normal operation.
		- **High Miasma:** Causes visual CRT glitches, enemies might appear as if with a "negative" shader, increases enemy movement speed, and drains Mental Health.
- ### Layer 2: Tactical Room Interaction (The Arena)
  
  Upon entering a room with enemies, the game transitions from free-movement to **Mode B: Tactical Combat**.  
	- **Lockdown:** Doors are sealed until all enemies are defeated.
	- **Turn-Based Logic:** Players and enemies use Action Points (AP) and Movement Points (MP).
	- **Environment:** Rooms contain pillars or crates providing **Partial Cover** ( $-25\%$ enemy accuracy) or **Full Cover** ( $-50\%$ accuracy + LoS block).
	- **Interaction:** Once cleared, players can freely loot chests or interact with environmental props.
-
---
- ## 4. Systems & Mechanics
- ### Stats & Status
	- **Physical Health (HP):** Standard durability. Death triggers a "Reset" to the Hub.
	- **Mental Health (Sanity):** Drained by Miasma or horror encounters. Low sanity causes Pane D (Data Log) to display false information or spawns "Ghost" enemies in Pane A.
	- **AP/MP:** Dictated by the equipped **Core Suit**. Better suits allow more actions or further movement per turn.
- ### Equipment & Crafting
	- **Item-Based Abilities:** The player has no "native" skills. A Medkit in Pane C grants a "Heal" action; a Plasma Cutter grants a "Destructive Shot" action.
		- **Blueprints:** Found during runs. Must be "uploaded" at a terminal to be permanently unlocked in the Hub.
- ### The "Demented Echoes" (Online Component)
	- **Asynchronous Multiplayer:** When a player dies, a ghost-like sprite of their character appears in other players' sessions.
	- **Scavenging:** Players can interact with these remains to recover one random item or blueprint the fallen player was carrying.
-
---
- ## 5. Narrative & Meta-Progression (The Hub)
- ### The Cabin
  
  Between runs, the player "wakes up" in a safe, first-person or fixed-camera cabin.  
	- **The Stash:** Allows the player to "store" one item for a future run (spawns randomly in a locker).
	- **Neuro-Implants:** Permanent upgrades purchased with "Neural Scrip" (meta-currency) to increase base stats (Damage vs. Mutants, Mental Resistance).
	- **The Loop:** The Cabin evolves over time, filling with notes and trophies that track the player's progress through the nightmare.
- ### Ending Branches
  
  The path through the station is non-linear, determined by which elevators the player takes:  
	- **The Bridge Ending:** Send the distress signal.
	- **The Hangar Ending:** Find an escape pod.
	- **The Source Ending:** A secret path requiring specific lore items to face the "Unfathomable Evil."
-
---
- ## 6. Technical Implementation Notes (For AI)
- **State Management:** Transition logic required for `EXPLORATION_MODE` vs `COMBAT_MODE`.
- **UI Shaders:** Apply a post-processing stack to the 4-Pane layout for the retro-CRT aesthetic.
- **Procedural Gen:** Use seed-based generation for sectors to ensure floor layouts can be reconstructed for "Stash" item placement.