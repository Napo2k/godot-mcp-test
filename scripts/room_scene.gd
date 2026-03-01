extends Node2D
class_name RoomScene
## Renders and manages a single room in Pane A (viewport).

var _tile_size: int = 32
var room_w: int = 18
var room_h: int = 10
const WALL_COLOR   := Color(0.08, 0.18, 0.08, 1.0)
const FLOOR_COLOR  := Color(0.05, 0.10, 0.05, 1.0)
const PILLAR_COLOR := Color(0.15, 0.30, 0.15, 1.0)
const CRATE_COLOR  := Color(0.20, 0.25, 0.10, 1.0)
const EXIT_COLOR   := Color(0.0, 0.5, 0.8, 1.0)

var _room_data: Dictionary = {}
var _obstacle_map: Dictionary = {}  # Vector2i -> "pillar"|"crate"
var _exit_positions: Dictionary = {}  # Vector2i -> room_id (int)
var _loot_positions: Dictionary = {}  # Vector2i -> Array[ItemData]
var _terminal_positions: Array[Vector2i] = []
var _enemies: Array[Enemy] = []
var _player: Player = null
var _combat_manager: CombatManager = null
var _loot_revealed: bool = false

@onready var tile_container: Node2D = $TileContainer
@onready var entity_container: Node2D = $EntityContainer
@onready var overlay_container: Node2D = $OverlayContainer

func _ready() -> void:
	pass

func load_room(room_data: Dictionary, player: Player) -> void:
	_room_data = room_data
	_player = player
	_obstacle_map.clear()
	_exit_positions.clear()
	_loot_positions.clear()
	_terminal_positions.clear()
	_loot_revealed = false

	# Clear containers
	for child in tile_container.get_children():
		child.queue_free()
	for child in entity_container.get_children():
		child.queue_free()

	# Variable room dimensions — seeded per room
	var dim_rng := RandomNumberGenerator.new()
	dim_rng.seed = room_data.get("id", 0) * 9157 + FloorGenerator.get_current_seed()
	room_w = dim_rng.randi_range(14, 22)
	room_h = dim_rng.randi_range(8, 14)

	# Dynamic tile size — scale to fit PaneA content area
	var available := Vector2(636.0, 330.0)
	if GameManager.hud and GameManager.hud.has_method("get_pane_a_content"):
		var pane: Control = GameManager.hud.get_pane_a_content()
		if pane.size.x > 0:
			available = pane.size
	_tile_size = clamp(int(min(available.x / room_w, available.y / room_h)), 16, 32)

	_generate_tiles()
	_place_exits()
	_place_obstacles()
	if room_data.get("has_loot", false):
		_place_loot()
	if room_data.get("has_terminal", false):
		_place_terminal()

	# Add player
	entity_container.add_child(player)
	var spawn_rng := RandomNumberGenerator.new()
	spawn_rng.seed = room_data.get("id", 0) * 3333 + FloorGenerator.get_current_seed()
	player.grid_pos = _find_spawn_pos(spawn_rng)
	player.tile_size = _tile_size
	player._sync_visual()

	# Spawn enemies if room has them and isn't cleared
	if room_data.get("has_enemies", false) and not room_data.get("cleared", false):
		_spawn_enemies()

func _generate_tiles() -> void:
	for y in range(room_h):
		for x in range(room_w):
			var rect := ColorRect.new()
			rect.size = Vector2(_tile_size - 1, _tile_size - 1)
			rect.position = Vector2(x * _tile_size, y * _tile_size)
			# Walls on border
			var is_wall := (x == 0 or y == 0 or x == room_w - 1 or y == room_h - 1)
			rect.color = WALL_COLOR if is_wall else FLOOR_COLOR
			tile_container.add_child(rect)

func _place_exits() -> void:
	var exits: Dictionary = _room_data.get("exits", {})

	# Fallback for rooms without directional exits data
	if exits.is_empty():
		var connections: Array = _room_data.get("connections", [])
		var exit_y_positions: Array = []
		if connections.size() >= 1:
			exit_y_positions.append(room_h / 2 - 1)
		if connections.size() >= 2:
			exit_y_positions.append(room_h / 2 + 1)
		for i in range(min(connections.size(), exit_y_positions.size())):
			var exit_pos := Vector2i(room_w - 1, exit_y_positions[i])
			_exit_positions[exit_pos] = connections[i]
			_draw_exit_tile(exit_pos, ">")
		return

	for dir_name: String in exits:
		var target_id: int = exits[dir_name]
		var exit_pos: Vector2i
		var label_text: String
		match dir_name:
			"north":
				exit_pos = Vector2i(room_w / 2, 0)
				label_text = "^"
			"south":
				exit_pos = Vector2i(room_w / 2, room_h - 1)
				label_text = "v"
			"east":
				exit_pos = Vector2i(room_w - 1, room_h / 2)
				label_text = ">"
			"west":
				exit_pos = Vector2i(0, room_h / 2)
				label_text = "<"
			_:
				continue
		_exit_positions[exit_pos] = target_id
		_draw_exit_tile(exit_pos, label_text)

func _draw_exit_tile(exit_pos: Vector2i, label_text: String) -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(_tile_size - 1, _tile_size - 1)
	rect.position = Vector2(exit_pos.x * _tile_size, exit_pos.y * _tile_size)
	rect.color = EXIT_COLOR
	tile_container.add_child(rect)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.position = Vector2(exit_pos.x * _tile_size + 8, exit_pos.y * _tile_size + 6)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	overlay_container.add_child(lbl)

func _place_obstacles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _room_data.get("id", 0) * 1337 + FloorGenerator.get_current_seed()

	# 3-5 pillars
	var pillar_count := rng.randi_range(3, 5)
	for _i in range(pillar_count):
		var pos := _random_floor_pos(rng)
		if pos != Vector2i.ZERO and pos not in _obstacle_map:
			_obstacle_map[pos] = "pillar"
			_draw_obstacle(pos, PILLAR_COLOR, "P")

	# 2-4 crates
	var crate_count := rng.randi_range(2, 4)
	for _i in range(crate_count):
		var pos := _random_floor_pos(rng)
		if pos != Vector2i.ZERO and pos not in _obstacle_map:
			_obstacle_map[pos] = "crate"
			_draw_obstacle(pos, CRATE_COLOR, "C")

func _place_loot() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _room_data.get("id", 0) * 9999
	var pos := _random_floor_pos(rng)
	var loot_table: Array = _room_data.get("loot_table", ["medkit"])
	var items: Array[ItemData] = []
	for item_id in loot_table:
		items.append(ItemData.from_id(item_id))
	_loot_positions[pos] = items
	_draw_obstacle(pos, Color(0.8, 0.6, 0.0, 1.0), "L")

func _place_terminal() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _room_data.get("id", 0) * 5555
	var pos := _random_floor_pos(rng)
	_terminal_positions.append(pos)
	_draw_obstacle(pos, Color(0.0, 0.6, 0.8, 1.0), "T")

func _draw_obstacle(pos: Vector2i, color: Color, symbol: String) -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(_tile_size - 2, _tile_size - 2)
	rect.position = Vector2(pos.x * _tile_size + 1, pos.y * _tile_size + 1)
	rect.color = color
	tile_container.add_child(rect)
	var lbl := Label.new()
	lbl.text = symbol
	lbl.position = Vector2(pos.x * _tile_size + 10, pos.y * _tile_size + 6)
	overlay_container.add_child(lbl)

func _random_floor_pos(rng: RandomNumberGenerator) -> Vector2i:
	for _attempt in range(20):
		var x := rng.randi_range(2, room_w - 3)
		var y := rng.randi_range(2, room_h - 3)
		var pos := Vector2i(x, y)
		if pos not in _obstacle_map and pos not in _exit_positions:
			return pos
	return Vector2i.ZERO

func _find_spawn_pos(rng: RandomNumberGenerator) -> Vector2i:
	for _attempt in range(20):
		var x := rng.randi_range(1, min(3, room_w - 2))
		var y := rng.randi_range(1, room_h - 2)
		var pos := Vector2i(x, y)
		if pos not in _obstacle_map and pos not in _exit_positions:
			return pos
	return Vector2i(1, 1)

func _spawn_enemies() -> void:
	var enemy_types: Array = _room_data.get("enemy_types", ["mutant_crawler"])
	var rng := RandomNumberGenerator.new()
	rng.seed = _room_data.get("id", 0) * 7777

	for etype in enemy_types:
		var pos := _random_floor_pos(rng)
		if pos == Vector2i.ZERO:
			pos = Vector2i(room_w - 4, room_h / 2)
		var enemy := _make_enemy_node(etype, pos)
		_enemies.append(enemy)
		entity_container.add_child(enemy)

	# Trigger combat
	GameManager.enter_combat(_enemies)
	_setup_combat()

func _make_enemy_node(etype: String, pos: Vector2i) -> Enemy:
	# Use Enemy.new() directly — class_name Enemy is globally registered
	var enemy := Enemy.new()
	# Sprite
	var sprite := ColorRect.new()
	sprite.name = "Sprite"
	sprite.size = Vector2(_tile_size - 4, _tile_size - 4)
	sprite.position = Vector2(-(_tile_size / 2) + 2, -(_tile_size / 2) + 2)
	sprite.color = Color(0.8, 0.1, 0.1, 1.0)
	enemy.add_child(sprite)
	# HP label
	var hp_lbl := Label.new()
	hp_lbl.name = "HPLabel"
	hp_lbl.position = Vector2(-8, -_tile_size / 2 - 12)
	hp_lbl.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))
	enemy.add_child(hp_lbl)
	# setup() stores data without accessing children (safe before _ready)
	enemy.tile_size = _tile_size
	enemy.setup(etype, pos)
	return enemy

func _setup_combat() -> void:
	_combat_manager = CombatManager.new()
	_combat_manager.name = "CombatManager"
	add_child(_combat_manager)
	_combat_manager.setup(_player, _enemies, self)
	_combat_manager.combat_finished.connect(_on_combat_finished)
	_combat_manager.start_combat()

func _on_combat_finished() -> void:
	_enemies.clear()
	FloorGenerator.mark_cleared(_room_data.id)

# --- Public API ---
func is_walkable(pos: Vector2i) -> bool:
	# Allow movement onto exit positions (wall tiles with exits)
	if pos in _exit_positions:
		return true
	if pos.x <= 0 or pos.y <= 0 or pos.x >= room_w - 1 or pos.y >= room_h - 1:
		return false
	return pos not in _obstacle_map

func is_walkable_combat(pos: Vector2i) -> bool:
	if pos.x <= 0 or pos.y <= 0 or pos.x >= room_w - 1 or pos.y >= room_h - 1:
		return false
	if pos in _obstacle_map:
		return false
	for enemy in _enemies:
		if is_instance_valid(enemy) and enemy.grid_pos == pos:
			return false
	return true

func check_exit(pos: Vector2i) -> void:
	if GameManager.current_mode != GameManager.GameMode.EXPLORATION:
		return
	if pos in _exit_positions:
		var target_room_id: int = _exit_positions[pos]
		var target_room := FloorGenerator.get_room(target_room_id)
		FloorGenerator.mark_visited(target_room_id)
		if target_room.get("is_elevator", false):
			var tag: String = target_room.get("elevator_tag", "bridge")
			# Check Source path requirements
			if tag == "source" and PlayerData.lore_items.size() < 3:
				DataLog.log("> LOCKED: Requires 3 lore items. You have %d." % PlayerData.lore_items.size())
				return
			GameManager.trigger_ending(tag)
		else:
			GameManager.move_to_room(target_room_id)

func interact_at(pos: Vector2i) -> void:
	# Check adjacent tiles too
	var check_positions := [pos, pos + Vector2i(1,0), pos + Vector2i(-1,0), pos + Vector2i(0,1), pos + Vector2i(0,-1)]
	for check in check_positions:
		if check in _loot_positions and not _loot_revealed:
			_open_loot(check)
			return
		if check in _terminal_positions:
			_use_terminal(check)
			return

func _open_loot(pos: Vector2i) -> void:
	var items: Array = _loot_positions[pos]
	DataLog.log("> Found a container. Contents:")
	for item in items:
		DataLog.log("  + %s" % item.item_name)
		PlayerData.equip_item(item)
	_loot_positions.erase(pos)

func reveal_loot() -> void:
	if _loot_revealed:
		return
	_loot_revealed = true
	DataLog.log("> Room cleared. Loot available — press [E] near containers.")

func _use_terminal(pos: Vector2i) -> void:
	_terminal_positions.erase(pos)
	var lore := [
		"Log 4412: The organism didn't come from outside. It was here before us.",
		"Log 7823: Dr. Yelena found it in sector 7. She didn't survive contact.",
		"Log 0001: If you're reading this, you're already too late.",
		"Log 9999: The signal is a lure. Do NOT send it.",
	]
	DataLog.log("[color=#00ccff]> TERMINAL ACCESS:[/color] " + lore[randi() % lore.size()])

	# Upload blueprints if player has any
	var blueprints_to_upload := []
	for item in PlayerData.inventory:
		if item.item_type == "blueprint":
			blueprints_to_upload.append(item)
	for bp_item in blueprints_to_upload:
		SaveManager.unlock_blueprint(bp_item.blueprint_id)
		PlayerData.inventory.erase(bp_item)
		DataLog.log("[color=#00ff41]> Blueprint '%s' uploaded to Hub database.[/color]" % bp_item.item_name)

	# Also add a lore item to player
	if PlayerData.lore_items.size() < 5:
		PlayerData.lore_items.append("lore_" + str(pos.x) + "_" + str(pos.y))
		DataLog.log("> Lore data fragment acquired. (%d/3 for Source path)" % PlayerData.lore_items.size())

func get_nearest_enemy(from: Vector2i, max_range: int) -> Enemy:
	var closest: Enemy = null
	var closest_dist := 9999.0
	for enemy in _enemies:
		if not is_instance_valid(enemy) or enemy.hp <= 0:
			continue
		var dist := (enemy.grid_pos - from).length()
		# Check range and LoS
		if dist <= max_range and CoverSystem.has_line_of_sight(from, enemy.grid_pos, _obstacle_map):
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy
	return closest

func get_obstacle_map() -> Dictionary:
	return _obstacle_map
