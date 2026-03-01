extends RefCounted
class_name CoverSystem
## US-011: Cover calculations for tactical combat.

enum CoverType { NONE, PARTIAL, FULL }

static func get_cover(attacker_pos: Vector2i, defender_pos: Vector2i, obstacle_map: Dictionary) -> CoverType:
	"""
	obstacle_map: Dictionary of Vector2i -> String ("pillar"|"crate")
	Returns the cover type the defender enjoys.
	"""
	var adjacent_to_pillar := _is_adjacent_to(defender_pos, obstacle_map, "pillar")
	var behind_crate := _has_los_blocked(attacker_pos, defender_pos, obstacle_map)

	if behind_crate:
		return CoverType.FULL
	elif adjacent_to_pillar:
		return CoverType.PARTIAL
	return CoverType.NONE

static func apply_cover_to_hit_chance(base_chance: float, cover: CoverType) -> float:
	match cover:
		CoverType.PARTIAL:
			return base_chance * 0.75  # -25%
		CoverType.FULL:
			return base_chance * 0.50  # -50%
		_:
			return base_chance

static func cover_label(cover: CoverType) -> String:
	match cover:
		CoverType.PARTIAL: return "PARTIAL COVER"
		CoverType.FULL:    return "FULL COVER"
		_:                 return "NO COVER"

static func _is_adjacent_to(pos: Vector2i, obstacle_map: Dictionary, obj_type: String) -> bool:
	for dir: Vector2i in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var check: Vector2i = pos + dir
		if obstacle_map.get(check, "") == obj_type:
			return true
	return false

static func _has_los_blocked(from: Vector2i, to: Vector2i, obstacle_map: Dictionary) -> bool:
	"""Bresenham line-of-sight check — returns true if a crate blocks the line."""
	var points := _bresenham(from, to)
	# Skip first (attacker) and last (defender) positions
	for i in range(1, points.size() - 1):
		if obstacle_map.get(points[i], "") == "crate":
			return true
	return false

static func has_line_of_sight(from: Vector2i, to: Vector2i, obstacle_map: Dictionary) -> bool:
	"""Returns true if there is clear line of sight (no crate blocking)."""
	return not _has_los_blocked(from, to, obstacle_map)

static func _bresenham(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var x0: int = start.x
	var y0: int = start.y
	var x1: int = end.x
	var y1: int = end.y
	var dx: int = abs(x1 - x0)
	var dy: int = -abs(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy

	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			if x0 == x1: break
			err += dy
			x0 += sx
		if e2 <= dx:
			if y0 == y1: break
			err += dx
			y0 += sy
	return points
