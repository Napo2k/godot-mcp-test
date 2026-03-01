extends Node
## GameManager autoload — central game state machine.

signal mode_changed(new_mode: String)
signal run_ended(ending: String)

enum GameMode { HUB, EXPLORATION, COMBAT }

var current_mode: GameMode = GameMode.HUB
var hud: Control = null  # set by main.gd on _ready

# Current game session state
var current_floor: int = 0
var current_room_id: int = -1
var _active_game_scene: Node = null

const GAME_SCENE := "res://scenes/game.tscn"
const HUB_SCENE  := "res://scenes/hub.tscn"
const MAIN_SCENE := "res://scenes/main.tscn"

func start_new_run() -> void:
	"""Called from Hub when 'Begin Run' is pressed. Main scene has already loaded."""
	PlayerData.reset_for_run()
	MiasmaMgr.reset()
	current_floor = 0
	current_room_id = 0
	FloorGenerator.generate(randi())
	current_mode = GameMode.EXPLORATION

	# Spawn the game scene into Pane A
	_load_game_scene()
	DataLog.log("=== RUN STARTED ===")
	DataLog.log("Sector: Floor %d" % (current_floor + 1))
	DataLog.log(FloorGenerator.get_room_description(0))

func _load_game_scene() -> void:
	if _active_game_scene:
		_active_game_scene.queue_free()
		_active_game_scene = null

	if not hud:
		push_error("GameManager: HUD not set. Cannot load game scene.")
		return

	var scene := load(GAME_SCENE) as PackedScene
	if not scene:
		push_error("GameManager: Could not load " + GAME_SCENE)
		return
	_active_game_scene = scene.instantiate()
	hud.get_pane_a_content().add_child(_active_game_scene)

func enter_combat(enemy_list: Array) -> void:
	if current_mode == GameMode.COMBAT:
		return
	current_mode = GameMode.COMBAT
	emit_signal("mode_changed", "COMBAT")
	DataLog.log("[color=#ff8800]>>> COMBAT ENGAGED — Doors sealed. <<<[/color]")

func end_combat() -> void:
	if current_mode != GameMode.COMBAT:
		return
	current_mode = GameMode.EXPLORATION
	emit_signal("mode_changed", "EXPLORATION")
	DataLog.log("[color=#00ff41]>>> ROOM CLEARED — Doors unsealed. <<<[/color]")
	MiasmaMgr.tick()

func trigger_death() -> void:
	DataLog.log("[color=#ff0000]>>> NEURAL LINK SEVERED — Resetting to Hub. <<<[/color]")
	await get_tree().create_timer(2.0).timeout
	if _active_game_scene:
		_active_game_scene.queue_free()
		_active_game_scene = null
	current_mode = GameMode.HUB
	get_tree().change_scene_to_file(HUB_SCENE)

func trigger_ending(ending_type: String) -> void:
	var scrip_reward := 50
	match ending_type:
		"bridge":
			DataLog.log("[color=#00ff41]>>> DISTRESS SIGNAL SENT. Help may come. <<<[/color]")
			scrip_reward = 50
		"hangar":
			DataLog.log("[color=#00ffff]>>> ESCAPE POD LAUNCHED. You survived. <<<[/color]")
			scrip_reward = 40
		"source":
			DataLog.log("[color=#ff00ff]>>> THE UNFATHOMABLE EVIL WITNESSED. <<<[/color]")
			scrip_reward = 100
	SaveManager.add_scrip(scrip_reward)
	SaveManager.record_ending(ending_type)
	SaveManager.save_data()
	emit_signal("run_ended", ending_type)
	await get_tree().create_timer(3.0).timeout
	if _active_game_scene:
		_active_game_scene.queue_free()
		_active_game_scene = null
	current_mode = GameMode.HUB
	get_tree().change_scene_to_file(HUB_SCENE)

func move_to_room(room_id: int) -> void:
	current_room_id = room_id
	MiasmaMgr.tick()
	var room_data := FloorGenerator.get_room(room_id)
	DataLog.log("> " + FloorGenerator.get_room_description(room_id))
	if _active_game_scene and _active_game_scene.has_method("load_room"):
		_active_game_scene.load_room(room_data)
