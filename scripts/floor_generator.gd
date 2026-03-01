extends Node
## FloorGenerator autoload — seed-based 2D grid procedural floor generation.

signal floor_generated(rooms: Array)

const MIN_ROOMS := 6
const MAX_ROOMS := 12
const ROOM_TYPES := ["standard", "storage", "lab", "hydroponics", "maintenance", "armory"]
const SECTOR_NAMES := [
	"Garbage Collection", "Hydroponics Bay", "Science Labs",
	"Engineering", "Medical Ward", "Crew Quarters",
	"Armory", "Reactor Core", "Communications Hub"
]

## Cardinal direction offsets on the grid.
const DIRS: Dictionary = {
	"north": Vector2i(0, -1),
	"east":  Vector2i(1,  0),
	"south": Vector2i(0,  1),
	"west":  Vector2i(-1, 0),
}
const OPPOSITE: Dictionary = {
	"north": "south",
	"south": "north",
	"east":  "west",
	"west":  "east",
}

var _rooms: Array[Dictionary] = []
var _current_seed: int = 0
var _rng: RandomNumberGenerator

func _ready() -> void:
	_rng = RandomNumberGenerator.new()

## Generate a floor layout.
## floor_depth: 0 = more linear/corridor-like (early floors), higher = more branching/labyrinthine.
func generate(seed_val: int, floor_depth: int = 0) -> void:
	_current_seed = seed_val
	_rng.seed = seed_val
	_rooms.clear()

	var room_count: int = _rng.randi_range(MIN_ROOMS, MAX_ROOMS)

	# Grid tracks which cell is occupied: Vector2i -> room_id
	var grid: Dictionary = {}

	# branching_factor: 0.0 = pure DFS (linear corridors), 1.0 = pure BFS (wide branching)
	var branching_factor: float = clampf(float(floor_depth) * 0.18, 0.05, 0.85)

	var start_pos := Vector2i(0, 0)
	var room_id := 0

	# Place start room
	var start_room: Dictionary = _make_room(room_id, start_pos)
	start_room["is_start"] = true
	start_room["visited"] = true
	start_room["has_enemies"] = false
	_rooms.append(start_room)
	grid[start_pos] = room_id
	room_id += 1

	# Frontier: grid positions from which we can expand
	var frontier: Array[Vector2i] = [start_pos]
	var dir_keys: Array = DIRS.keys()

	while _rooms.size() < room_count and not frontier.is_empty():
		# DFS picks last added; BFS/branching picks random
		var src_idx: int
		if _rng.randf() < branching_factor:
			src_idx = _rng.randi() % frontier.size()
		else:
			src_idx = frontier.size() - 1
		var src_pos: Vector2i = frontier[src_idx]

		# Shuffle directions for variety
		var shuffled: Array = dir_keys.duplicate()
		for i in range(shuffled.size() - 1, 0, -1):
			var j: int = _rng.randi() % (i + 1)
			var tmp: String = shuffled[i]
			shuffled[i] = shuffled[j]
			shuffled[j] = tmp

		var placed := false
		for dir_name: String in shuffled:
			var offset: Vector2i = DIRS[dir_name]
			var new_pos: Vector2i = src_pos + offset
			if grid.has(new_pos):
				continue
			# Place new room
			var room: Dictionary = _make_room(room_id, new_pos)
			_rooms.append(room)
			grid[new_pos] = room_id
			frontier.append(new_pos)
			_connect_dir(_rooms[grid[src_pos]], room, dir_name)
			room_id += 1
			placed = true
			break

		if not placed:
			frontier.remove_at(src_idx)

	# Add extra loop connections for labyrinthine feel (more at higher floor_depth)
	var extra_loops: int = int(branching_factor * float(room_count) * 0.4)
	for _e in range(extra_loops):
		var idx: int = _rng.randi() % _rooms.size()
		var room_a: Dictionary = _rooms[idx]
		var pos_a := Vector2i(room_a["grid_x"], room_a["grid_y"])
		for dir_name: String in dir_keys:
			var pos_b: Vector2i = pos_a + DIRS[dir_name]
			if grid.has(pos_b):
				var room_b: Dictionary = _rooms[grid[pos_b]]
				_connect_dir(room_a, room_b, dir_name)

	# Normalize grid positions so the minimum is (0, 0)
	var min_x := 99999
	var min_y := 99999
	for room in _rooms:
		min_x = min(min_x, int(room["grid_x"]))
		min_y = min(min_y, int(room["grid_y"]))
	for room in _rooms:
		room["grid_x"] = int(room["grid_x"]) - min_x
		room["grid_y"] = int(room["grid_y"]) - min_y

	# Assign elevator to the BFS-farthest room from start
	var distances: Dictionary = _bfs_distances(_rooms[0])
	var elevator_room: Dictionary = _rooms[0]
	var max_dist := 0
	for rid: int in distances:
		if distances[rid] > max_dist:
			max_dist = distances[rid]
			elevator_room = _rooms[rid]
	elevator_room["is_elevator"] = true
	elevator_room["has_enemies"] = false
	var tags: Array = ["bridge", "hangar", "source"]
	elevator_room["elevator_tag"] = tags[_rng.randi() % tags.size()]

	# Optional second elevator for larger floors (at ~50% BFS distance)
	if _rooms.size() >= 8:
		var target_dist: int = max_dist / 2
		var best_second: Dictionary = {}
		var best_diff := 99999
		for rid: int in distances:
			var diff: int = abs(distances[rid] - target_dist)
			if rid == elevator_room["id"] or rid == 0:
				continue
			if diff < best_diff:
				best_diff = diff
				best_second = _rooms[rid]
		if not best_second.is_empty():
			best_second["is_elevator"] = true
			best_second["has_enemies"] = false
			var used_tag: String = elevator_room["elevator_tag"]
			var remaining: Array = tags.filter(func(t: String) -> bool: return t != used_tag)
			best_second["elevator_tag"] = remaining[_rng.randi() % remaining.size()]

	# Derive backwards-compatible connections array from exits (for NavCom)
	for room in _rooms:
		var conn_list: Array = []
		for dir_name: String in room["exits"]:
			conn_list.append(room["exits"][dir_name])
		room["connections"] = conn_list

	emit_signal("floor_generated", _rooms)

func _make_room(id: int, grid_pos: Vector2i) -> Dictionary:
	var rtype: String = ROOM_TYPES[_rng.randi() % ROOM_TYPES.size()]
	var sector: String = SECTOR_NAMES[_rng.randi() % SECTOR_NAMES.size()]
	var has_enemies: bool = _rng.randf() > 0.35
	var has_loot: bool = _rng.randf() > 0.4
	var has_terminal: bool = _rng.randf() > 0.7
	return {
		"id": id,
		"name": sector,
		"type": rtype,
		"exits": {},        # direction -> room_id (primary connection data)
		"connections": [],  # derived from exits after generation (for NavCom backwards-compat)
		"visited": false,
		"cleared": false,
		"has_enemies": has_enemies,
		"has_loot": has_loot,
		"has_terminal": has_terminal,
		"enemy_types": _pick_enemies(rtype),
		"loot_table": _pick_loot(rtype),
		"is_start": false,
		"is_elevator": false,
		"elevator_tag": "",
		"grid_x": grid_pos.x,
		"grid_y": grid_pos.y,
	}

func _connect_dir(room_a: Dictionary, room_b: Dictionary, dir_ab: String) -> void:
	"""Connect room_a to room_b in direction dir_ab (and room_b back in the opposite)."""
	var dir_ba: String = OPPOSITE[dir_ab]
	if not room_a["exits"].has(dir_ab):
		room_a["exits"][dir_ab] = room_b["id"]
	if not room_b["exits"].has(dir_ba):
		room_b["exits"][dir_ba] = room_a["id"]

func _bfs_distances(start: Dictionary) -> Dictionary:
	"""BFS from start. Returns Dictionary of room_id -> distance."""
	var dist: Dictionary = {start["id"]: 0}
	var queue: Array[Dictionary] = [start]
	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		for dir_name: String in current["exits"]:
			var nid: int = current["exits"][dir_name]
			if not dist.has(nid):
				dist[nid] = dist[current["id"]] + 1
				queue.append(_rooms[nid])
	return dist

func _pick_enemies(room_type: String) -> Array:
	match room_type:
		"armory":
			return ["mutant_soldier", "mutant_soldier"]
		"lab":
			return ["mutant_crawler", "mutant_hound"]
		_:
			var pool: Array = ["mutant_crawler", "mutant_hound", "ghost"]
			var count: int = _rng.randi_range(1, 3)
			var result: Array = []
			for _i in range(count):
				result.append(pool[_rng.randi() % pool.size()])
			return result

func _pick_loot(room_type: String) -> Array:
	match room_type:
		"armory":
			return ["plasma_cutter", "armor_plate"]
		"storage":
			return ["medkit", "medkit", "scrap_blade"]
		"lab":
			return ["neural_chip", "stim_pack"]
		_:
			var pool: Array = ["medkit", "scrap_blade", "neural_chip", "stim_pack", "blueprint_basic"]
			var result: Array = []
			var count: int = _rng.randi_range(1, 3)
			for _i in range(count):
				result.append(pool[_rng.randi() % pool.size()])
			return result

func get_room(id: int) -> Dictionary:
	if id >= 0 and id < _rooms.size():
		return _rooms[id]
	return {}

func get_all_rooms() -> Array[Dictionary]:
	return _rooms

func get_room_description(id: int) -> String:
	var room: Dictionary = get_room(id)
	if room.is_empty():
		return "Unknown sector."
	var desc: String = "Entering: %s [%s]" % [room["name"], room["type"].to_upper()]
	if room.get("is_elevator", false):
		desc += " | [ELEVATOR — " + room["elevator_tag"].to_upper() + "]"
	if room.get("has_terminal", false):
		desc += " | Terminal detected."
	return desc

func mark_visited(id: int) -> void:
	if id >= 0 and id < _rooms.size():
		_rooms[id]["visited"] = true

func mark_cleared(id: int) -> void:
	if id >= 0 and id < _rooms.size():
		_rooms[id]["cleared"] = true
		_rooms[id]["has_enemies"] = false

func get_current_seed() -> int:
	return _current_seed
