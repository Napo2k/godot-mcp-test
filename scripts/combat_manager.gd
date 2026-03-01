extends Node
class_name CombatManager
## Manages turn order and combat flow for a single room encounter.

signal combat_finished

var _enemies: Array[Enemy] = []
var _player: Player = null
var _room_scene: Node = null

func setup(player: Player, enemies: Array[Enemy], room: Node) -> void:
	_player = player
	_enemies = enemies
	_room_scene = room
	for enemy in _enemies:
		enemy.died.connect(_on_enemy_died)

func start_combat() -> void:
	DataLog.log("--- Turn 1 begins ---")
	_player.start_player_turn()

func start_enemy_turn() -> void:
	if _enemies.is_empty():
		_end_combat()
		return

	DataLog.log("[color=#ff8800]--- Enemy turn ---[/color]")
	for enemy in _enemies.duplicate():
		if is_instance_valid(enemy) and enemy.hp > 0:
			enemy.take_turn(_player, _room_scene)
			await get_tree().create_timer(0.15).timeout

	if PlayerData.hp <= 0:
		return  # Death handled by PlayerData → GameManager

	# Back to player
	_player.start_player_turn()

func _on_enemy_died(enemy: Enemy) -> void:
	_enemies.erase(enemy)
	if _enemies.is_empty():
		_end_combat()

func _end_combat() -> void:
	emit_signal("combat_finished")
	GameManager.end_combat()
	# Spawn loot if room has loot
	if _room_scene.has_method("reveal_loot"):
		_room_scene.reveal_loot()
