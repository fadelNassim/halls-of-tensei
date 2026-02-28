extends Node
class_name SpawnManager

signal wave_started(wave_index: int)
signal wave_completed(wave_index: int)
signal all_waves_completed()

const BASE_ENEMIES_PER_WAVE := 3
const ENEMIES_INCREMENT := 2

@export var enemy_scene: PackedScene
@export var spawn_points: Array[NodePath] = []

var current_wave: int = 0
var max_waves: int = 5
var _active_enemies: Array[Node] = []
var _spawn_point_nodes: Array[Node] = []

func _ready() -> void:
	for sp in spawn_points:
		_spawn_point_nodes.append(get_node(sp))

func start_run(wave_count: int = 5) -> void:
	current_wave = 0
	max_waves = wave_count
	_active_enemies.clear()
	spawn_wave()

func spawn_wave() -> void:
	if current_wave >= max_waves:
		emit_signal("all_waves_completed")
		return

	emit_signal("wave_started", current_wave)
	var count := BASE_ENEMIES_PER_WAVE + current_wave * ENEMIES_INCREMENT
	for i in range(count):
		_spawn_enemy()
	current_wave += 1

func _spawn_enemy() -> void:
	if enemy_scene == null:
		push_error("SpawnManager: No enemy scene assigned")
		return
	var enemy := enemy_scene.instantiate()
	var parent := get_parent()
	parent.add_child(enemy)

	var pos := _get_spawn_position()
	if enemy.has_method("set_spawn_position"):
		enemy.set_spawn_position(pos)
	elif "global_position" in enemy:
		enemy.global_position = pos

	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died.bind(enemy))
	_active_enemies.append(enemy)

func _get_spawn_position() -> Vector2:
	if _spawn_point_nodes.size() > 0:
		var sp := _spawn_point_nodes[randi() % _spawn_point_nodes.size()]
		if "global_position" in sp:
			return sp.global_position
	return Vector2(randf_range(-200, 200), randf_range(-200, 200))

func _on_enemy_died(enemy: Node) -> void:
	_active_enemies.erase(enemy)
	if _active_enemies.is_empty():
		emit_signal("wave_completed", current_wave - 1)
		await get_tree().create_timer(1.5).timeout
		spawn_wave()

func get_active_enemy_count() -> int:
	return _active_enemies.size()

func get_current_wave() -> int:
	return current_wave
