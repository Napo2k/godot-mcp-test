extends Control

# Pane references
@onready var pane_a: Panel = $PaneGrid/PaneA
@onready var pane_b: Panel = $PaneGrid/PaneB
@onready var pane_c: Panel = $PaneGrid/PaneC
@onready var pane_d: Panel = $PaneGrid/PaneD
@onready var crt_rect: ColorRect = $CRTOverlay/CRTRect

# Pane content areas
@onready var pane_a_content: Control = $PaneGrid/PaneA/PaneAContent
@onready var pane_b_content: Control = $PaneGrid/PaneB/PaneBContent

# Pane D data log references
@onready var data_log_text: RichTextLabel = $PaneGrid/PaneD/PaneDContent/DataLogScroll/DataLogText

# Pane C stat references
@onready var hp_label: Label = $PaneGrid/PaneC/PaneCContent/StatusVBox/HPLabel
@onready var hp_bar: ProgressBar = $PaneGrid/PaneC/PaneCContent/StatusVBox/HPBar
@onready var sanity_label: Label = $PaneGrid/PaneC/PaneCContent/StatusVBox/SanityLabel
@onready var sanity_bar: ProgressBar = $PaneGrid/PaneC/PaneCContent/StatusVBox/SanityBar
@onready var ap_label: Label = $PaneGrid/PaneC/PaneCContent/StatusVBox/APLabel
@onready var mp_label: Label = $PaneGrid/PaneC/PaneCContent/StatusVBox/MPLabel
@onready var miasma_label: Label = $PaneGrid/PaneC/PaneCContent/StatusVBox/MiasmaLabel
@onready var weapon1_label: Label = $PaneGrid/PaneC/PaneCContent/StatusVBox/Weapon1Label
@onready var weapon2_label: Label = $PaneGrid/PaneC/PaneCContent/StatusVBox/Weapon2Label
@onready var suit_label: Label = $PaneGrid/PaneC/PaneCContent/StatusVBox/SuitLabel
@onready var chip_label: Label = $PaneGrid/PaneC/PaneCContent/StatusVBox/ChipLabel

# CRT flicker
var _flicker_time: float = 0.0
var _crt_shader_material: ShaderMaterial

# Data log
var _log_lines: Array[String] = []

func _ready() -> void:
	print("SIGNAL LOST - System Online")
	_apply_pane_styles()
	_apply_crt_shader()
	_connect_signals()

	# Register this as the HUD so other systems can update it
	GameManager.hud = self
	# Start a new run (we arrive here from the Hub's "Begin Run" button)
	GameManager.start_new_run()

	DataLog.log("[color=#00ff41]SIGNAL LOST v1.0[/color]")
	DataLog.log("Initializing station neural interface...")
	DataLog.log("WARNING: Station instability detected.")
	DataLog.log("Locate the Bridge. Send the signal.")

func _apply_pane_styles() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.039, 0.059, 0.039, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.102, 0.227, 0.102, 1.0)
	panel_style.content_margin_left = 4.0
	panel_style.content_margin_top = 4.0
	panel_style.content_margin_right = 4.0
	panel_style.content_margin_bottom = 4.0

	for pane in [pane_a, pane_b, pane_c, pane_d]:
		pane.add_theme_stylebox_override("panel", panel_style)
		# Style title labels
		for child in pane.get_children():
			if child is Label:
				child.add_theme_color_override("font_color", Color(0.0, 1.0, 0.255, 1.0))

	# Style stat labels in pane C
	var stat_vbox = $PaneGrid/PaneC/PaneCContent/StatusVBox
	for child in stat_vbox.get_children():
		if child is Label:
			child.add_theme_color_override("font_color", Color(0.0, 0.9, 0.2, 1.0))

	# Style progress bars
	var hp_bar_style := StyleBoxFlat.new()
	hp_bar_style.bg_color = Color(0.0, 0.7, 0.1, 1.0)
	hp_bar.add_theme_stylebox_override("fill", hp_bar_style)
	var hp_bg_style := StyleBoxFlat.new()
	hp_bg_style.bg_color = Color(0.05, 0.1, 0.05, 1.0)
	hp_bar.add_theme_stylebox_override("background", hp_bg_style)

	var san_bar_style := StyleBoxFlat.new()
	san_bar_style.bg_color = Color(0.1, 0.3, 0.7, 1.0)
	sanity_bar.add_theme_stylebox_override("fill", san_bar_style)
	sanity_bar.add_theme_stylebox_override("background", hp_bg_style)

	# Style data log text
	data_log_text.add_theme_color_override("default_color", Color(0.0, 0.9, 0.2, 1.0))

func _apply_crt_shader() -> void:
	var shader := load("res://shaders/crt.gdshader") as Shader
	if shader:
		_crt_shader_material = ShaderMaterial.new()
		_crt_shader_material.shader = shader
		crt_rect.material = _crt_shader_material
		_crt_shader_material.set_shader_parameter("scanline_intensity", 0.08)
		_crt_shader_material.set_shader_parameter("flicker_speed", 3.0)
		_crt_shader_material.set_shader_parameter("distortion_strength", 0.015)
		_crt_shader_material.set_shader_parameter("time_val", 0.0)

func _connect_signals() -> void:
	if DataLog.has_signal("message_logged"):
		DataLog.message_logged.connect(_on_data_log_message)
	if PlayerData.has_signal("stats_changed"):
		PlayerData.stats_changed.connect(_on_stats_changed)
	if MiasmaMgr.has_signal("miasma_changed"):
		MiasmaMgr.miasma_changed.connect(_on_miasma_changed)

func _process(delta: float) -> void:
	_flicker_time += delta
	if _crt_shader_material:
		_crt_shader_material.set_shader_parameter("time_val", _flicker_time)

# --- Data Log ---
func _on_data_log_message(text: String) -> void:
	_log_lines.insert(0, text)
	if _log_lines.size() > 150:
		_log_lines.resize(150)
	data_log_text.clear()
	data_log_text.append_text("\n".join(_log_lines))

# --- Stats Update ---
func _on_stats_changed() -> void:
	hp_label.text = "HP: %d / %d" % [PlayerData.hp, PlayerData.max_hp]
	hp_bar.max_value = PlayerData.max_hp
	hp_bar.value = PlayerData.hp
	sanity_label.text = "MENTAL HEALTH: %d / %d" % [PlayerData.sanity, PlayerData.max_sanity]
	sanity_bar.max_value = PlayerData.max_sanity
	sanity_bar.value = PlayerData.sanity
	ap_label.text = "AP: %d / %d" % [PlayerData.ap, PlayerData.max_ap]
	mp_label.text = "MP: %d / %d" % [PlayerData.mp, PlayerData.max_mp]
	_update_gear_labels()

func _update_gear_labels() -> void:
	weapon1_label.text = "WEAPON 1: " + (PlayerData.equipped_weapon1.item_name if PlayerData.equipped_weapon1 else "[EMPTY]")
	weapon2_label.text = "WEAPON 2: " + (PlayerData.equipped_weapon2.item_name if PlayerData.equipped_weapon2 else "[EMPTY]")
	suit_label.text = "CORE SUIT: " + (PlayerData.equipped_suit.item_name if PlayerData.equipped_suit else "[EMPTY]")
	chip_label.text = "UTILITY CHIP: " + (PlayerData.equipped_chip.item_name if PlayerData.equipped_chip else "[EMPTY]")

func _on_miasma_changed(value: int) -> void:
	miasma_label.text = "STATION INSTABILITY: %d%%" % value
	# Intensify CRT at high miasma
	if _crt_shader_material:
		var intensity := 0.08 + (value / 100.0) * 0.25
		_crt_shader_material.set_shader_parameter("scanline_intensity", intensity)

# --- Public API for game scenes ---
func get_pane_a_content() -> Control:
	return pane_a_content

func get_pane_b_content() -> Control:
	return pane_b_content
