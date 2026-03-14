extends Node
## SaveManager autoload — persistent save/load for meta-progression.

const SAVE_PATH := "user://signal_lost_save.json"

var _data: Dictionary = {}

func _ready() -> void:
	load_data()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_data = _default_data()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var text := file.get_as_text()
		file.close()
		var parsed: Variant = JSON.parse_string(text)
		if parsed is Dictionary:
			_data = parsed
		else:
			_data = _default_data()
	else:
		_data = _default_data()

func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_data, "\t"))
		file.close()

func _default_data() -> Dictionary:
	return {
		"neural_scrip": 0,
		"implants": {},
		"unlocked_blueprints": [],
		"endings_reached": [],
		"total_runs": 0,
		"stash_item": null,
	}

# --- Neural Scrip ---
func get_scrip() -> int:
	return _data.get("neural_scrip", 0)

func add_scrip(amount: int) -> void:
	_data["neural_scrip"] = get_scrip() + amount
	save_data()

func spend_scrip(amount: int) -> bool:
	if get_scrip() < amount:
		return false
	_data["neural_scrip"] -= amount
	save_data()
	return true

# --- Neuro-Implants ---
func get_implants() -> Dictionary:
	var raw: Dictionary = _data.get("implants", {})
	var result: Dictionary = {}
	for k in raw:
		result[k] = raw[k] if raw[k] is int else (1 if raw[k] else 0)
	return result

func has_implant(id: String) -> bool:
	return get_implants().get(id, 0) > 0

func buy_implant(id: String, cost: int) -> bool:
	if not spend_scrip(cost):
		return false
	_data["implants"][id] = _data["implants"].get(id, 0) + 1
	save_data()
	return true

# --- Blueprints ---
func get_blueprints() -> Array:
	return _data.get("unlocked_blueprints", [])

func unlock_blueprint(bp_id: String) -> void:
	if bp_id not in get_blueprints():
		_data["unlocked_blueprints"].append(bp_id)
		save_data()

# --- Endings ---
func record_ending(ending: String) -> void:
	if ending not in _data.get("endings_reached", []):
		if not _data.has("endings_reached"):
			_data["endings_reached"] = []
		_data["endings_reached"].append(ending)
		save_data()

func get_endings() -> Array:
	return _data.get("endings_reached", [])

# --- Stash ---
func set_stash(item_dict: Dictionary) -> void:
	_data["stash_item"] = item_dict
	save_data()

func get_stash() -> Variant:
	return _data.get("stash_item", null)

func clear_stash() -> void:
	_data["stash_item"] = null
	save_data()

# --- Run counter ---
func increment_runs() -> void:
	_data["total_runs"] = _data.get("total_runs", 0) + 1
	save_data()

func get_total_runs() -> int:
	return _data.get("total_runs", 0)
