extends Node2D

signal run_completed(run_data: Dictionary)

@onready var player: Player = $Player
@onready var wave_label: Label = $UI/HUD/WaveLabel
@onready var hp_label: Label = $UI/HUD/HPLabel
@onready var alignment_label: Label = $UI/HUD/AlignmentLabel
@onready var fp_label: Label = $UI/HUD/FusionPointsLabel

var _spawn_manager: SpawnManager
var _alignment_system: AlignmentSystem
var _negotiation_dialog: Control
var _demon_data_list: Array = []
var _run_start_time: float = 0.0
var _recruited_count: int = 0
var _wave_count: int = 5

func _ready() -> void:
	_alignment_system = AlignmentSystem.new()
	add_child(_alignment_system)
	_alignment_system.alignment_changed.connect(_on_alignment_changed)

	_spawn_manager = SpawnManager.new()
	_spawn_manager.enemy_scene = preload("res://scenes/demon_follower.tscn")
	add_child(_spawn_manager)
	_spawn_manager.wave_started.connect(_on_wave_started)
	_spawn_manager.wave_completed.connect(_on_wave_completed)
	_spawn_manager.all_waves_completed.connect(_on_all_waves_completed)

	if has_node("UI/NegotiationDialog"):
		_negotiation_dialog = $UI/NegotiationDialog
		if _negotiation_dialog.has_signal("negotiation_done"):
			_negotiation_dialog.negotiation_done.connect(_on_negotiation_done)

	player.add_to_group("player")
	player.health_changed.connect(_on_player_hp_changed)
	player.died.connect(_on_player_died)

	_demon_data_list = DemonData.load_all_demons()
	_assign_random_demon_data()

	_run_start_time = Time.get_unix_time_from_system()
	_spawn_manager.start_run(_wave_count)
	_update_hud()

func _assign_random_demon_data() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("get_demon_data") and _demon_data_list.size() > 0:
			var random_demon: DemonData = _demon_data_list[randi() % _demon_data_list.size()]
			if enemy.has_method("set") and "demon_data" in enemy:
				enemy.demon_data = random_demon.to_dict()

func _process(_delta: float) -> void:
	if Input.is_action_pressed("interact"):
		_try_negotiate()

func _try_negotiate() -> void:
	if _negotiation_dialog == null or _negotiation_dialog.visible:
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not e.has_method("is_negotiateable"):
			continue
		if not e.is_negotiateable():
			continue
		var dist := player.global_position.distance_to(e.global_position)
		if dist > 80.0:
			continue
		var demon_dict: Dictionary = e.get_demon_data() if e.has_method("get_demon_data") else {}
		if demon_dict.size() == 0:
			continue
		if _negotiation_dialog.has_method("open_negotiation"):
			_negotiation_dialog.open_negotiation(demon_dict, player.get_stats(), _alignment_system)
		break

func _on_player_hp_changed(current: int, maximum: int) -> void:
	hp_label.text = "HP: %d/%d" % [current, maximum]

func _on_alignment_changed(new_value: float) -> void:
	alignment_label.text = "Alignment: %s (%.0f)" % [_alignment_system.get_label(), new_value]

func _on_wave_started(wave_index: int) -> void:
	wave_label.text = "Wave: %d/%d" % [wave_index + 1, _wave_count]
	_assign_random_demon_data()

func _on_wave_completed(_wave_index: int) -> void:
	pass

func _on_all_waves_completed() -> void:
	var run_time := Time.get_unix_time_from_system() - _run_start_time
	var run_data := {
		"run_time": run_time,
		"waves_cleared": _wave_count,
		"recruited_count": _recruited_count,
		"fusions_made": 0,
		"player_alignment": _alignment_system.value,
		"deaths": 0
	}
	emit_signal("run_completed", run_data)
	# Transition to hub
	get_tree().change_scene_to_file("res://scenes/hub.tscn")

func _on_player_died() -> void:
	var run_time := Time.get_unix_time_from_system() - _run_start_time
	var run_data := {
		"run_time": run_time,
		"waves_cleared": _spawn_manager.get_current_wave(),
		"recruited_count": _recruited_count,
		"fusions_made": 0,
		"player_alignment": _alignment_system.value,
		"deaths": 1
	}
	emit_signal("run_completed", run_data)
	get_tree().change_scene_to_file("res://scenes/hub.tscn")

func _on_negotiation_done(success: bool, demon_data: Dictionary) -> void:
	if success:
		_recruited_count += 1
		player.recruit_demon(demon_data)
		_alignment_system.shift(demon_data.get("recruit_rules", {}).get("alignment_bias", 0.0) * 10)
		_update_hud()
	# Find the demon enemy and handle post-negotiation
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e.has_method("is_negotiateable") and e.is_negotiateable():
			if success:
				e.queue_free()
			elif e.has_method("start_enrage"):
				e.start_enrage()
			break

func _update_hud() -> void:
	fp_label.text = "Fusion Points: %d" % player.fusion_points
