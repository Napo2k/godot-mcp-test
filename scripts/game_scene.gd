extends Node2D
const TEX_VARIETY := preload("res://assets/tilesets/_Meph_variety.png")
## Main game scene — loaded into Pane A during a run.
## Manages the active room, player, and nav-com map.

var _current_room: RoomScene = null
var _player: Player = null
var _nav_com: NavCom = null

@onready var room_container: Node2D = $RoomContainer

func _ready() -> void:
	_setup_player()
	_setup_nav_com()
	# Register with GameManager so it can call load_room/begin_combat
	GameManager._active_game_scene = self
	# Load first room
	var start_room := FloorGenerator.get_room(0)
	load_room(start_room)

func _setup_player() -> void:
	# Player.new() works because class_name Player is globally registered
	_player = Player.new()
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = TEX_VARIETY
	sprite.region_enabled = true
	sprite.region_rect = Rect2(8 * 32, 0, 32, 32)
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, 0)
	_player.add_child(sprite)

func _setup_nav_com() -> void:
	# NavCom.new() works because class_name NavCom is globally registered
	_nav_com = NavCom.new()

	# Inject nav-com into Pane B of the HUD
	if GameManager.hud and GameManager.hud.has_method("get_pane_b_content"):
		var pane_b: Control = GameManager.hud.get_pane_b_content()
		pane_b.add_child(_nav_com)
		_nav_com.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Initialize map with already-generated floor data
	if not FloorGenerator.get_all_rooms().is_empty():
		_nav_com._on_floor_generated(FloorGenerator.get_all_rooms())

func load_room(room_data: Dictionary) -> void:
	# Clear old room
	if _current_room:
		_current_room.queue_free()
		_current_room = null

	# Remove player from old entity container
	if _player.get_parent():
		_player.get_parent().remove_child(_player)

	# Build room node from class (RoomScene extends Node2D)
	var room_node := RoomScene.new()
	room_node.name = "ActiveRoom"

	# Add required sub-containers BEFORE entering scene tree
	# so @onready vars in room_scene.gd resolve correctly
	var tile_cont    := Node2D.new(); tile_cont.name    = "TileContainer"
	var entity_cont  := Node2D.new(); entity_cont.name  = "EntityContainer"
	var overlay_cont := Node2D.new(); overlay_cont.name = "OverlayContainer"
	room_node.add_child(tile_cont)
	room_node.add_child(entity_cont)
	room_node.add_child(overlay_cont)

	room_container.add_child(room_node)
	_current_room = room_node
	_current_room.load_room(room_data, _player)

	# Update nav-com map
	if _nav_com:
		_nav_com.update_current_room(room_data.get("id", 0))

func begin_combat(_enemy_list: Array) -> void:
	# Combat is initiated inside RoomScene — nothing extra needed here
	pass
