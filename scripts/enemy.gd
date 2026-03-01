extends Node2D
class_name Enemy
## Enemy node — AI movement and attacks for tactical combat.

signal died(enemy: Enemy)

const TILE_SIZE := 32

var grid_pos: Vector2i = Vector2i(0, 0)
var enemy_type: String = "mutant_crawler"
var max_hp: int = 30
var hp: int = 30
var damage: int = 8
var base_mp: int = 3

# Not @onready — set in _ready() after entering tree
var _sprite: ColorRect = null
var _hp_label: Label = null

func setup(etype: String, pos: Vector2i) -> void:
	"""Called before node enters scene tree — only store data, no node access."""
	enemy_type = etype
	grid_pos = pos
	match etype:
		"mutant_crawler":
			max_hp = 25; hp = 25; damage = 8;  base_mp = 3
		"mutant_hound":
			max_hp = 40; hp = 40; damage = 14; base_mp = 4
		"mutant_soldier":
			max_hp = 55; hp = 55; damage = 18; base_mp = 2
		"ghost":
			max_hp = 15; hp = 15; damage = 5;  base_mp = 5
	# Set raw position now (safe, no children needed)
	position = Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0,
					   grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0)

func _ready() -> void:
	"""Called when node enters scene tree — wire up child references."""
	_sprite   = get_node_or_null("Sprite") as ColorRect
	_hp_label = get_node_or_null("HPLabel") as Label
	_refresh_visuals()

func _refresh_visuals() -> void:
	if _hp_label:
		_hp_label.text = "%d/%d" % [hp, max_hp]
	position = Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0,
					   grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0)

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	_refresh_visuals()
	if hp <= 0:
		DataLog.log("> %s destroyed!" % enemy_type.replace("_", " ").capitalize())
		emit_signal("died", self)
		queue_free()

func take_turn(player: Player, room_scene: Node) -> void:
	"""Enemy AI: move toward player then attack if adjacent."""
	var mp := base_mp + MiasmaMgr.get_enemy_mp_bonus()
	var steps := 0

	while steps < mp:
		var to_player := player.grid_pos - grid_pos
		if abs(to_player.x) + abs(to_player.y) <= 1:
			break  # Adjacent — will attack
		var best_dir := _best_direction(player.grid_pos, room_scene)
		if best_dir == Vector2i.ZERO:
			break
		grid_pos += best_dir
		_refresh_visuals()
		steps += 1

	# Attack if adjacent
	var dist: int = abs(player.grid_pos.x - grid_pos.x) + abs(player.grid_pos.y - grid_pos.y)
	if dist <= 1:
		var cover := CoverSystem.get_cover(grid_pos, player.grid_pos, room_scene.get_obstacle_map())
		var hit_chance := CoverSystem.apply_cover_to_hit_chance(0.75, cover)
		if randf() <= hit_chance:
			var actual_damage := damage
			if PlayerData.equipped_suit is ItemData and PlayerData.equipped_suit.armor > 0:
				actual_damage = max(1, actual_damage - PlayerData.equipped_suit.armor)
			PlayerData.take_damage(actual_damage)
			DataLog.log("[color=#ff4444]> %s attacks! Hit! %d dmg. [%s][/color]" % [
				enemy_type.replace("_", " ").capitalize(), actual_damage,
				CoverSystem.cover_label(cover)])
		else:
			DataLog.log("> %s attacks! Missed. [%s]" % [
				enemy_type.replace("_", " ").capitalize(), CoverSystem.cover_label(cover)])

func _best_direction(target: Vector2i, room_scene: Node) -> Vector2i:
	var dirs := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	var best_dir := Vector2i.ZERO
	var best_dist := 9999.0
	for dir in dirs:
		var new_pos: Vector2i = grid_pos + dir
		if not room_scene.is_walkable_combat(new_pos):
			continue
		var dist := float((new_pos - target).length_squared())
		if dist < best_dist:
			best_dist = dist
			best_dir = dir
	return best_dir
