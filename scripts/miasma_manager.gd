extends Node
## MiasmaMgr autoload — Station Instability tracker (US-013).

signal miasma_changed(value: int)

var value: int = 0
const MAX_VALUE := 100

func reset() -> void:
	value = 0
	emit_signal("miasma_changed", value)

func tick(amount: int = 1) -> void:
	"""Called each player move/turn."""
	value = min(MAX_VALUE, value + amount)
	emit_signal("miasma_changed", value)

	# High miasma effects
	if value > 50:
		PlayerData.lose_sanity(1)
		DataLog.log("[color=#886600]> Station groans. The air thickens.[/color]") if value % 10 == 0 else null

	if value >= MAX_VALUE:
		DataLog.log("[color=#ff4400]>>> STATION INSTABILITY CRITICAL <<<[/color]")

func get_enemy_mp_bonus() -> int:
	"""US-013: enemies get +1 MP when miasma > 75."""
	return 1 if value > 75 else 0
