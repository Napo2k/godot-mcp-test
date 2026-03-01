extends Control
class_name NavCom
## Nav-Com map rendering for Pane B — Darkest Dungeon style node graph (US-004).

const NODE_SIZE    := Vector2(56, 24)
const NODE_SPACING := Vector2(72, 44)
const MARGIN       := Vector2(8, 8)

var _rooms: Array = []
var _current_room_id: int = 0

func _ready() -> void:
	FloorGenerator.floor_generated.connect(_on_floor_generated)
	GameManager.mode_changed.connect(_on_mode_changed)

func _on_floor_generated(rooms: Array) -> void:
	_rooms = rooms
	_current_room_id = 0
	queue_redraw()

func update_current_room(room_id: int) -> void:
	_current_room_id = room_id
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var font_size := 10

	if _rooms.is_empty():
		draw_string(font, Vector2(8, 20), "AWAITING FLOOR DATA...",
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0.7, 0.2))
		return

	# Draw connections first (behind nodes)
	for room in _rooms:
		if not room.get("visited", false):
			continue
		var from_pos := _room_draw_pos(room)
		for conn_id in room.get("connections", []):
			var conn_room := FloorGenerator.get_room(conn_id)
			if conn_room.is_empty() or not conn_room.get("visited", false):
				continue
			draw_line(
				from_pos + NODE_SIZE * 0.5,
				_room_draw_pos(conn_room) + NODE_SIZE * 0.5,
				Color(0.0, 0.45, 0.1, 1.0), 1.0
			)

	# Draw room nodes
	for room in _rooms:
		var draw_pos := _room_draw_pos(room)
		var visited: bool = room.get("visited", false)
		var is_current: bool = room.get("id", -1) == _current_room_id
		var is_elevator: bool = room.get("is_elevator", false)
		var cleared: bool = room.get("cleared", false)

		# Determine colors
		var bg_color    := Color(0.04, 0.08, 0.04, 1.0)
		var border_color := Color(0.1, 0.25, 0.1, 1.0)
		var text_color  := Color(0.15, 0.35, 0.15, 1.0)
		var label_text  := "?"

		if visited:
			label_text   = room.get("name", "???").substr(0, 7)
			bg_color     = Color(0.06, 0.12, 0.06, 1.0)
			border_color = Color(0.0, 0.65, 0.15, 1.0)
			text_color   = Color(0.0, 0.9, 0.3, 1.0)

		if cleared:
			bg_color = Color(0.04, 0.08, 0.04, 1.0)
			text_color = Color(0.0, 0.55, 0.1, 1.0)

		if is_elevator and visited:
			bg_color     = Color(0.0, 0.06, 0.18, 1.0)
			border_color = Color(0.0, 0.45, 0.9, 1.0)
			text_color   = Color(0.3, 0.8, 1.0, 1.0)
			label_text   = "[ ELEV ]"

		if is_current:
			bg_color     = Color(0.0, 0.22, 0.06, 1.0)
			border_color = Color(0.0, 1.0, 0.35, 1.0)

		# Draw background and border
		draw_rect(Rect2(draw_pos, NODE_SIZE), bg_color)
		draw_rect(Rect2(draw_pos, NODE_SIZE), border_color, false, 1.5)

		# Room label
		draw_string(font, draw_pos + Vector2(4, 15),
			label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

		# Elevator ping (blinking dot above node)
		if is_elevator and visited:
			draw_circle(draw_pos + Vector2(NODE_SIZE.x * 0.5, -6), 3.5, Color(0.0, 0.7, 1.0))

		# Current room marker (asterisk inside)
		if is_current:
			draw_string(font, draw_pos + Vector2(NODE_SIZE.x * 0.5 - 3, NODE_SIZE.y - 4),
				"*", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, Color(0.0, 1.0, 0.4))

func _room_draw_pos(room: Dictionary) -> Vector2:
	var gx: int = room.get("grid_x", 0)
	var gy: int = room.get("grid_y", 0)
	return MARGIN + Vector2(gx * NODE_SPACING.x, gy * NODE_SPACING.y)

func _on_mode_changed(_mode: String) -> void:
	queue_redraw()
