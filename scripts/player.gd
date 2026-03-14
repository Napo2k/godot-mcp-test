extends Node2D
class_name Player
## Player node — handles grid movement and combat actions.

signal action_performed(action: Dictionary)
signal moved(new_pos: Vector2i)

var tile_size: int = 32

var grid_pos: Vector2i = Vector2i(5, 5)
var _can_move: bool = true  # false during combat (not player's turn)

func _ready() -> void:
	_sync_visual()

func _get_room() -> RoomScene:
	# Player lives inside entity_container which is inside RoomScene
	var parent := get_parent()
	if parent == null:
		return null
	var grandparent := parent.get_parent()
	if grandparent is RoomScene:
		return grandparent as RoomScene
	# Fallback: search ancestors
	var node := parent
	while node:
		if node is RoomScene:
			return node as RoomScene
		node = node.get_parent()
	return null

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_mode == GameManager.GameMode.COMBAT:
		_handle_combat_input(event)
	else:
		_handle_exploration_input(event)

# --- Exploration Movement ---
func _handle_exploration_input(event: InputEvent) -> void:
	if not _can_move:
		return
	var dir := Vector2i.ZERO
	if event.is_action_pressed("move_up"):    dir = Vector2i(0, -1)
	elif event.is_action_pressed("move_down"):  dir = Vector2i(0, 1)
	elif event.is_action_pressed("move_left"):  dir = Vector2i(-1, 0)
	elif event.is_action_pressed("move_right"): dir = Vector2i(1, 0)
	elif event.is_action_pressed("interact"):
		_try_interact()
		get_viewport().set_input_as_handled()
		return

	if dir != Vector2i.ZERO:
		_try_move(dir)
		get_viewport().set_input_as_handled()

func _try_move(dir: Vector2i) -> void:
	var new_pos := grid_pos + dir
	var room_scene := _get_room()
	if room_scene and room_scene.is_walkable(new_pos):
		grid_pos = new_pos
		_sync_visual()
		MiasmaMgr.tick()
		emit_signal("moved", grid_pos)
		room_scene.check_exit(grid_pos)

func _try_interact() -> void:
	var room_scene := _get_room()
	if room_scene:
		room_scene.interact_at(grid_pos)

# --- Combat Input ---
func _handle_combat_input(event: InputEvent) -> void:
	if not _can_move:
		return

	var dir := Vector2i.ZERO
	if event.is_action_pressed("move_up"):       dir = Vector2i(0, -1)
	elif event.is_action_pressed("move_down"):   dir = Vector2i(0, 1)
	elif event.is_action_pressed("move_left"):   dir = Vector2i(-1, 0)
	elif event.is_action_pressed("move_right"):  dir = Vector2i(1, 0)
	elif event.is_action_pressed("end_turn"):
		_end_turn()
		get_viewport().set_input_as_handled()
		return
	elif event.is_action_pressed("attack"):
		_do_first_attack()
		get_viewport().set_input_as_handled()
		return
	elif event.is_action_pressed("use_item"):
		_do_first_consumable()
		get_viewport().set_input_as_handled()
		return

	if dir != Vector2i.ZERO:
		_try_combat_move(dir)
		get_viewport().set_input_as_handled()

func _try_combat_move(dir: Vector2i) -> void:
	if not PlayerData.spend_mp(1):
		DataLog.log("> No MP remaining. End turn with [SPACE].")
		return
	var new_pos := grid_pos + dir
	var room_scene := _get_room()
	if room_scene and room_scene.is_walkable_combat(new_pos):
		grid_pos = new_pos
		_sync_visual()
		MiasmaMgr.tick()
		DataLog.log("> Moved. MP: %d" % PlayerData.mp)
		emit_signal("moved", grid_pos)
		if PlayerData.ap == 0 and PlayerData.mp == 0:
			_end_turn()

func _do_first_attack() -> void:
	var actions := PlayerData.get_available_actions()
	# Find first damaging action
	for action in actions:
		if action.has("damage"):
			perform_action(action)
			return
	DataLog.log("> No attack equipped. Equip a weapon first.")

func _do_first_consumable() -> void:
	var actions := PlayerData.get_available_actions()
	for action in actions:
		if action.has("heal") or action.has("sanity_restore"):
			perform_action(action)
			return
	DataLog.log("> No usable item found.")

func perform_action(action: Dictionary) -> void:
	if not PlayerData.spend_ap(action.get("ap_cost", 1)):
		DataLog.log("> Not enough AP!")
		return

	var room_scene := _get_room()
	var action_name: String = action.get("name", "Attack")

	if action.has("damage"):
		if not room_scene:
			return
		var target_enemy := room_scene.get_nearest_enemy(grid_pos, action.get("range", 999))
		if target_enemy == null:
			DataLog.log("> No target in range.")
			# Refund AP
			PlayerData.ap = mini(PlayerData.max_ap, PlayerData.ap + action.get("ap_cost", 1))
			PlayerData.emit_signal("stats_changed")
			return
		var damage: int = action.damage
		damage += PlayerData.damage_bonus
		var cover := CoverSystem.get_cover(grid_pos, target_enemy.grid_pos, room_scene.get_obstacle_map())
		var hit_chance := CoverSystem.apply_cover_to_hit_chance(0.85, cover)
		if randf() <= hit_chance:
			target_enemy.take_damage(damage)
			DataLog.log("> %s! Hit! %d dmg. [%s]" % [action_name, damage, CoverSystem.cover_label(cover)])
		else:
			DataLog.log("> %s! Missed. [%s]" % [action_name, CoverSystem.cover_label(cover)])

	elif action.has("heal"):
		PlayerData.heal(action.heal)
		DataLog.log("> %s! +%d HP. (HP: %d/%d)" % [action_name, action.heal, PlayerData.hp, PlayerData.max_hp])
		_remove_consumable_action(action)

	elif action.has("sanity_restore"):
		PlayerData.restore_sanity(action.sanity_restore)
		DataLog.log("> %s! +%d Sanity." % [action_name, action.sanity_restore])
		_remove_consumable_action(action)

	emit_signal("action_performed", action)
	if PlayerData.ap == 0 and PlayerData.mp == 0:
		_end_turn()

func _remove_consumable_action(action: Dictionary) -> void:
	for i in range(PlayerData.inventory.size()):
		var item = PlayerData.inventory[i]
		if item.item_type == "consumable":
			for a in item.actions:
				if a.get("name") == action.get("name"):
					PlayerData.inventory.remove_at(i)
					return

func _end_turn() -> void:
	_can_move = false
	DataLog.log("> Player turn ended.")
	var room_scene := _get_room()
	if room_scene:
		var combat_mgr := room_scene.get_node_or_null("CombatManager") as CombatManager
		if combat_mgr:
			combat_mgr.start_enemy_turn()

func start_player_turn() -> void:
	PlayerData.refresh_ap_mp()
	_can_move = true
	DataLog.log("[color=#00ff41]--- YOUR TURN — AP:%d MP:%d ---[/color]" % [PlayerData.ap, PlayerData.mp])
	DataLog.log("> [F]=Attack  [G]=Use Item  [SPACE]=End Turn  [WASD]=Move")

func _sync_visual() -> void:
	position = Vector2(grid_pos.x * tile_size + tile_size / 2.0,
					   grid_pos.y * tile_size + tile_size / 2.0)
