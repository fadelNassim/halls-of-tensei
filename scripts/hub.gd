extends Control

@onready var roster_list: ItemList = $MainLayout/RosterPanel/RosterList
@onready var fusion_points_label: Label = $MainLayout/FusionPanel/FusionPointsLabel
@onready var demon_a_label: Label = $MainLayout/FusionPanel/DemonALabel
@onready var demon_b_label: Label = $MainLayout/FusionPanel/DemonBLabel
@onready var fuse_button: Button = $MainLayout/FusionPanel/FuseButton
@onready var fusion_result_label: Label = $MainLayout/FusionPanel/FusionResultLabel
@onready var run_button: Button = $RunButton
@onready var alignment_label: Label = $AlignmentBar/AlignmentLabel
@onready var select_demon_a_button: Button = $MainLayout/FusionPanel/SelectDemonAButton
@onready var select_demon_b_button: Button = $MainLayout/FusionPanel/SelectDemonBButton
@onready var fusion_dialog: AcceptDialog = $FusionSelectionDialog
@onready var fusion_demon_list: ItemList = $FusionSelectionDialog/FusionDemonList

var _fusion_system: FusionSystem
var _demon_roster: Array = []
var _fusion_points: int = 0
var _alignment_value: float = 0.0
var _demon_a: Dictionary = {}
var _demon_b: Dictionary = {}
var _selecting_slot: String = "a"

func _ready() -> void:
	_fusion_system = FusionSystem.new()
	add_child(_fusion_system)

	_load_game_state()

	select_demon_a_button.pressed.connect(_on_select_demon_a)
	select_demon_b_button.pressed.connect(_on_select_demon_b)
	fuse_button.pressed.connect(_on_fuse_pressed)
	run_button.pressed.connect(_on_run_pressed)
	fusion_demon_list.item_activated.connect(_on_fusion_demon_selected)
	fusion_dialog.confirmed.connect(_on_fusion_dialog_confirmed)

	_refresh_ui()

func _load_game_state() -> void:
	var game_state := _get_game_state()
	if game_state:
		_demon_roster = game_state.demon_roster.duplicate(true)
		_fusion_points = game_state.fusion_points
		_alignment_value = game_state.alignment_value

func _get_game_state() -> Node:
	if has_node("/root/GameState"):
		return get_node("/root/GameState")
	return null

func _refresh_ui() -> void:
	roster_list.clear()
	for demon in _demon_roster:
		var label := "%s (Rank %d, %s)" % [demon.get("name", "?"), demon.get("rank", 1), demon.get("alignment", "?")]
		roster_list.add_item(label)

	fusion_points_label.text = "Fusion Points: %d" % _fusion_points
	_update_alignment_label()
	_update_fusion_ui()

func _update_alignment_label() -> void:
	var label := "Neutral"
	if _alignment_value >= AlignmentSystem.LAW_THRESHOLD:
		label = "Law"
	elif _alignment_value <= AlignmentSystem.CHAOS_THRESHOLD:
		label = "Chaos"
	alignment_label.text = "Alignment: %s (%.0f)" % [label, _alignment_value]

func _update_fusion_ui() -> void:
	demon_a_label.text = "Demon A: %s" % (_demon_a.get("name", "(none)") if _demon_a.size() > 0 else "(none)")
	demon_b_label.text = "Demon B: %s" % (_demon_b.get("name", "(none)") if _demon_b.size() > 0 else "(none)")
	var can_fuse := _demon_a.size() > 0 and _demon_b.size() > 0
	if can_fuse:
		var cost := _fusion_system.fusion_cost(_demon_a, _demon_b)
		can_fuse = can_fuse and _fusion_points >= cost
	fuse_button.disabled = not can_fuse

func _on_select_demon_a() -> void:
	_selecting_slot = "a"
	_open_fusion_selection_dialog()

func _on_select_demon_b() -> void:
	_selecting_slot = "b"
	_open_fusion_selection_dialog()

func _open_fusion_selection_dialog() -> void:
	fusion_demon_list.clear()
	for demon in _demon_roster:
		fusion_demon_list.add_item("%s (Rank %d)" % [demon.get("name", "?"), demon.get("rank", 1)])
	fusion_dialog.popup_centered()

func _on_fusion_demon_selected(index: int) -> void:
	if index < 0 or index >= _demon_roster.size():
		return
	var selected := _demon_roster[index]
	if _selecting_slot == "a":
		_demon_a = selected
	else:
		_demon_b = selected
	fusion_dialog.hide()
	fusion_result_label.text = ""
	_update_fusion_ui()

func _on_fusion_dialog_confirmed() -> void:
	var selected_idx := fusion_demon_list.get_selected_items()
	if selected_idx.size() > 0:
		_on_fusion_demon_selected(selected_idx[0])

func _on_fuse_pressed() -> void:
	if _demon_a.size() == 0 or _demon_b.size() == 0:
		return
	var check := _fusion_system.can_fuse(_demon_a, _demon_b)
	if not check.get("ok", false):
		fusion_result_label.text = "Cannot fuse: " + check.get("reason", "")
		return
	var cost := _fusion_system.fusion_cost(_demon_a, _demon_b)
	if _fusion_points < cost:
		fusion_result_label.text = "Not enough fusion points (need %d)" % cost
		return

	var result := _fusion_system.fuse(_demon_a, _demon_b)
	if result.size() == 0:
		fusion_result_label.text = "Fusion failed!"
		return

	_fusion_points -= cost
	_demon_roster.erase(_demon_a)
	_demon_roster.erase(_demon_b)
	_demon_roster.append(result)
	_demon_a = {}
	_demon_b = {}

	fusion_result_label.text = "Fusion successful! Created: %s (Rank %d)" % [result.get("name", "?"), result.get("rank", 1)]
	_save_game_state()
	_refresh_ui()

func _on_run_pressed() -> void:
	_save_game_state()
	get_tree().change_scene_to_file("res://scenes/run_arena.tscn")

func _save_game_state() -> void:
	var game_state := _get_game_state()
	if game_state:
		game_state.demon_roster = _demon_roster.duplicate(true)
		game_state.fusion_points = _fusion_points
		game_state.alignment_value = _alignment_value
		game_state._save_to_file()
