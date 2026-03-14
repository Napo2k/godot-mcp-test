extends Node
## PlayerData autoload — tracks all player stats for the current run.

signal stats_changed

# --- Base stats (modified by Neuro-Implants) ---
var base_max_hp: int = 100
var base_max_sanity: int = 100
var base_max_ap: int = 3
var base_max_mp: int = 5
var base_damage_bonus: int = 0
var base_sanity_resistance: int = 0

# --- Current run stats ---
var max_hp: int = 100
var hp: int = 100
var max_sanity: int = 100
var sanity: int = 100
var max_ap: int = 3
var ap: int = 3
var max_mp: int = 5
var mp: int = 5
var damage_bonus: int = 0

# --- Equipment slots (ItemData resources or null) ---
var equipped_weapon1: Resource = null
var equipped_weapon2: Resource = null
var equipped_suit: Resource = null
var equipped_chip: Resource = null

# --- Inventory (array of ItemData) ---
var inventory: Array = []

# --- Collected lore items (for Source ending) ---
var lore_items: Array = []

# --- Stash (persisted item from last run) ---
var stash_item: Resource = null

# --- Unlocked blueprints (persisted across runs) ---
var unlocked_blueprints: Array = []

func reset_for_run() -> void:
	"""Called at the start of each new run. Applies Neuro-Implant bonuses."""
	var implants: Dictionary = SaveManager.get_implants()

	var imp_hp  : int = implants.get("implant_max_hp", 0)
	var imp_ap  : int = implants.get("implant_ap",     0)
	var imp_san : int = implants.get("implant_sanity",  0)
	var imp_dmg : int = implants.get("implant_damage",  0)

	max_hp       = base_max_hp + (10 * imp_hp)
	max_ap       = base_max_ap + (1  * imp_ap)
	max_sanity   = base_max_sanity + (20 * imp_san)
	damage_bonus = base_damage_bonus + (5 * imp_dmg)
	max_mp = base_max_mp

	hp = max_hp
	sanity = max_sanity
	ap = max_ap
	mp = max_mp

	equipped_weapon1 = ItemData.make_scrap_blade()
	equipped_weapon2 = null
	equipped_suit = null
	equipped_chip = null
	inventory = []
	lore_items = []

	# Load stash from persistent save and place in inventory
	var stash_data = SaveManager.get_stash()
	if stash_data is Dictionary and stash_data.has("item_id"):
		var loaded_item := ItemData.from_id(stash_data.get("item_id", ""))
		if loaded_item:
			inventory.append(loaded_item)
	SaveManager.clear_stash()

	emit_signal("stats_changed")

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	emit_signal("stats_changed")
	if hp <= 0:
		GameManager.trigger_death()

func lose_sanity(amount: int) -> void:
	var imp_san: int = SaveManager.get_implants().get("implant_sanity", 0)
	var actual: int = max(0, amount - (10 * imp_san))
	sanity = max(0, sanity - actual)
	emit_signal("stats_changed")
	if sanity <= 0:
		DataLog.log("[color=#ff4444]MENTAL COLLAPSE — Hallucinations detected.[/color]")
		_trigger_hallucination()

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	emit_signal("stats_changed")

func restore_sanity(amount: int) -> void:
	sanity = min(max_sanity, sanity + amount)
	emit_signal("stats_changed")

func spend_ap(amount: int = 1) -> bool:
	if ap < amount:
		return false
	ap -= amount
	emit_signal("stats_changed")
	return true

func spend_mp(amount: int = 1) -> bool:
	if mp < amount:
		return false
	mp -= amount
	emit_signal("stats_changed")
	return true

func refresh_ap_mp() -> void:
	ap = max_ap
	mp = max_mp
	# ItemData always has ap_bonus/mp_bonus (default 0), safe direct access
	if equipped_suit is ItemData:
		ap += equipped_suit.ap_bonus
		mp += equipped_suit.mp_bonus
	emit_signal("stats_changed")

func equip_item(item: Resource) -> void:
	match item.item_type:
		"weapon":
			if equipped_weapon1 == null:
				equipped_weapon1 = item
			else:
				equipped_weapon2 = item
		"suit":
			equipped_suit = item
		"chip":
			equipped_chip = item
		"consumable":
			inventory.append(item)
			emit_signal("stats_changed")
			return
	emit_signal("stats_changed")

func get_available_actions() -> Array:
	"""Returns list of action dicts based on equipped gear."""
	var actions: Array = []
	# ItemData always has .actions (Array[Dictionary], default []) — safe direct access
	if equipped_weapon1 is ItemData and not equipped_weapon1.actions.is_empty():
		actions.append_array(equipped_weapon1.actions)
	if equipped_weapon2 is ItemData and not equipped_weapon2.actions.is_empty():
		actions.append_array(equipped_weapon2.actions)
	if equipped_chip is ItemData and not equipped_chip.actions.is_empty():
		actions.append_array(equipped_chip.actions)
	# Consumables in inventory
	for item in inventory:
		if item is ItemData and item.item_type == "consumable" and not item.actions.is_empty():
			actions.append_array(item.actions)
	return actions

func _trigger_hallucination() -> void:
	"""At 0 sanity, Pane D shows false information."""
	var false_messages := [
		"[color=#ff4444]STATUS: All systems nominal. No anomalies detected.[/color]",
		"[color=#ff4444]> You hear a familiar voice. It tells you everything is fine.[/color]",
		"[color=#ff4444]ENEMY COUNT: 0. The station is empty.[/color]",
		"[color=#ff4444]> Exit located. Proceed to corridor 4.[/color]",
	]
	var idx := randi() % false_messages.size()
	DataLog.log(false_messages[idx])
