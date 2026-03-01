extends Control
## Hub (The Cabin) scene — between-run screen. US-014 & US-015.

@onready var scrip_label: Label = $CabinPanel/ScripLabel
@onready var runs_label: Label = $CabinPanel/RunsLabel
@onready var stash_info: Label = $CabinPanel/StashInfo
@onready var stash_button: Button = $CabinPanel/StashButton
@onready var begin_button: Button = $CabinPanel/BeginButton
@onready var endings_label: Label = $CabinPanel/EndingsLabel

# Implant buttons
@onready var implant_max_hp: Button = $CabinPanel/ImplantMaxHP
@onready var implant_sanity: Button = $CabinPanel/ImplantSanity
@onready var implant_ap: Button = $CabinPanel/ImplantAP
@onready var implant_damage: Button = $CabinPanel/ImplantDamage

const IMPLANT_DEFS := [
	{"id": "implant_max_hp",  "cost": 30, "label": "Max HP +10"},
	{"id": "implant_sanity",  "cost": 25, "label": "Mental Resistance +10"},
	{"id": "implant_ap",      "cost": 40, "label": "Starting AP +1"},
	{"id": "implant_damage",  "cost": 35, "label": "Damage vs Mutants +5"},
]

func _ready() -> void:
	_apply_cabin_style()
	_refresh_ui()
	_connect_buttons()
	SaveManager.increment_runs()

func _apply_cabin_style() -> void:
	# Warm amber/sepia tones for the cabin (distinct from the green CRT)
	$Background.color = Color(0.08, 0.05, 0.02, 1.0)
	for child in $CabinPanel.get_children():
		if child is Label:
			child.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3, 1.0))
		if child is Button:
			var btn_style := StyleBoxFlat.new()
			btn_style.bg_color = Color(0.12, 0.08, 0.03, 1.0)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			btn_style.border_color = Color(0.6, 0.4, 0.1, 1.0)
			child.add_theme_stylebox_override("normal", btn_style)
			child.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3, 1.0))

func _refresh_ui() -> void:
	scrip_label.text = "Neural Scrip: %d" % SaveManager.get_scrip()
	runs_label.text = "Runs survived: %d" % SaveManager.get_total_runs()

	# Stash
	var stash: Variant = SaveManager.get_stash()
	if stash:
		stash_info.text = "Stashed: %s" % stash.get("item_name", "Unknown")
	else:
		stash_info.text = "No item stashed."

	# Endings
	var endings := SaveManager.get_endings()
	if endings.is_empty():
		endings_label.text = "Endings: None"
	else:
		endings_label.text = "Endings: " + ", ".join(endings).to_upper()

	# Implant buttons
	_refresh_implant_buttons()

func _refresh_implant_buttons() -> void:
	var implant_buttons := [implant_max_hp, implant_sanity, implant_ap, implant_damage]
	for i in range(IMPLANT_DEFS.size()):
		var defn: Dictionary = IMPLANT_DEFS[i]
		var btn: Button = implant_buttons[i]
		var owned := SaveManager.has_implant(defn.id)
		var scrip := SaveManager.get_scrip()
		btn.text = "[INSTALLED] " + defn.label if owned else \
			defn.label + "  [Cost: %d Scrip]" % defn.cost
		btn.disabled = owned or scrip < defn.cost
		if owned:
			btn.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3, 1.0))

func _connect_buttons() -> void:
	begin_button.pressed.connect(_on_begin_pressed)
	stash_button.pressed.connect(_on_stash_pressed)
	implant_max_hp.pressed.connect(func(): _buy_implant(0))
	implant_sanity.pressed.connect(func(): _buy_implant(1))
	implant_ap.pressed.connect(func(): _buy_implant(2))
	implant_damage.pressed.connect(func(): _buy_implant(3))

func _on_begin_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_stash_pressed() -> void:
	if PlayerData.equipped_weapon1:
		var item_dict := {
			"item_id": PlayerData.equipped_weapon1.item_id,
			"item_name": PlayerData.equipped_weapon1.item_name,
		}
		SaveManager.set_stash(item_dict)
		stash_info.text = "Stashed: " + PlayerData.equipped_weapon1.item_name
	else:
		stash_info.text = "Nothing equipped in Weapon 1 slot."

func _buy_implant(index: int) -> void:
	var defn: Dictionary = IMPLANT_DEFS[index]
	if SaveManager.buy_implant(defn.id, defn.cost):
		_refresh_implant_buttons()
		scrip_label.text = "Neural Scrip: %d" % SaveManager.get_scrip()
	else:
		pass  # Not enough scrip or already owned
