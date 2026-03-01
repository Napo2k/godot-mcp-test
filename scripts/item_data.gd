extends Resource
class_name ItemData
## Represents an in-game item (weapon, suit, chip, consumable, blueprint).

@export var item_id: String = ""
@export var item_name: String = "Unknown Item"
@export var item_type: String = "consumable"  # weapon | suit | chip | consumable | blueprint
@export var description: String = ""
@export var ap_cost: int = 1
@export var actions: Array[Dictionary] = []  # [{name, ap_cost, damage, heal, range, effect}]

# Suit-specific
@export var ap_bonus: int = 0
@export var mp_bonus: int = 0
@export var armor: int = 0

# Blueprint-specific
@export var blueprint_id: String = ""

# Chip-specific
@export var chip_effect: String = ""

static func make_medkit() -> ItemData:
	var item := ItemData.new()
	item.item_id = "medkit"
	item.item_name = "Medkit"
	item.item_type = "consumable"
	item.description = "Emergency medical kit. Restores 25 HP."
	item.actions = [{"name": "Heal", "ap_cost": 1, "heal": 25, "range": 0}]
	return item

static func make_plasma_cutter() -> ItemData:
	var item := ItemData.new()
	item.item_id = "plasma_cutter"
	item.item_name = "Plasma Cutter"
	item.item_type = "weapon"
	item.description = "Industrial cutting tool repurposed for combat. Short range."
	item.actions = [
		{"name": "Destructive Shot", "ap_cost": 1, "damage": 20, "range": 3, "effect": "none"},
		{"name": "Plasma Burst", "ap_cost": 2, "damage": 35, "range": 2, "effect": "burn"},
	]
	return item

static func make_scrap_blade() -> ItemData:
	var item := ItemData.new()
	item.item_id = "scrap_blade"
	item.item_name = "Scrap Blade"
	item.item_type = "weapon"
	item.description = "A jagged piece of metal. Melee only."
	item.actions = [{"name": "Slash", "ap_cost": 1, "damage": 12, "range": 1, "effect": "none"}]
	return item

static func make_armor_plate() -> ItemData:
	var item := ItemData.new()
	item.item_id = "armor_plate"
	item.item_name = "Armored Exo-Suit"
	item.item_type = "suit"
	item.description = "Heavy plating. Slows movement but provides protection."
	item.armor = 5
	item.ap_bonus = 0
	item.mp_bonus = -1
	return item

static func make_neural_chip() -> ItemData:
	var item := ItemData.new()
	item.item_id = "neural_chip"
	item.item_name = "Neural Reflex Chip"
	item.item_type = "chip"
	item.description = "Boosts reaction time. Grants one extra AP per turn."
	item.chip_effect = "ap_plus_one"
	item.actions = []
	return item

static func make_stim_pack() -> ItemData:
	var item := ItemData.new()
	item.item_id = "stim_pack"
	item.item_name = "Stim Pack"
	item.item_type = "consumable"
	item.description = "Military-grade stimulant. Restores 15 Sanity."
	item.actions = [{"name": "Inject", "ap_cost": 1, "sanity_restore": 15, "range": 0}]
	return item

static func make_blueprint(bp_id: String, bp_name: String) -> ItemData:
	var item := ItemData.new()
	item.item_id = "blueprint_" + bp_id
	item.item_name = "Blueprint: " + bp_name
	item.item_type = "blueprint"
	item.description = "Schematics for " + bp_name + ". Upload at a terminal to unlock permanently."
	item.blueprint_id = bp_id
	return item

static func from_id(id: String) -> ItemData:
	match id:
		"medkit":         return make_medkit()
		"plasma_cutter":  return make_plasma_cutter()
		"scrap_blade":    return make_scrap_blade()
		"armor_plate":    return make_armor_plate()
		"neural_chip":    return make_neural_chip()
		"stim_pack":      return make_stim_pack()
		"blueprint_basic": return make_blueprint("basic", "Scrap Blade")
		_:
			var unknown := ItemData.new()
			unknown.item_id = id
			unknown.item_name = id.capitalize()
			return unknown
