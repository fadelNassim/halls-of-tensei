extends CharacterBody2D
class_name DemonAI

signal died()
signal became_negotiateable()

enum State { IDLE, PATROL, ATTACK, FLEE, NEGOTIATEABLE }

@export var demon_id: String = ""
@export var demon_data: Dictionary = {}

const SPEED := 80.0
const ATTACK_RANGE := 40.0
const DETECT_RANGE := 200.0
const NEGOTIATEABLE_HP_THRESHOLD := 0.25

var current_hp: int = 60
var max_hp: int = 60
var attack_damage: int = 8
var state: State = State.IDLE
var _player: Node = null
var _attack_cooldown: float = 0.0
const ATTACK_COOLDOWN := 1.2
var _patrol_target: Vector2 = Vector2.ZERO
var _is_negotiateable: bool = false

func _ready() -> void:
	add_to_group("enemies")
	if demon_data.size() > 0:
		_apply_demon_stats()
	_patrol_target = global_position + Vector2(randf_range(-100, 100), randf_range(-50, 50))

func _apply_demon_stats() -> void:
	var stats: Dictionary = demon_data.get("base_stats", {})
	max_hp = stats.get("hp", 60)
	current_hp = max_hp
	attack_damage = stats.get("atk", 8)

func set_spawn_position(pos: Vector2) -> void:
	global_position = pos

func _physics_process(delta: float) -> void:
	if state == State.NEGOTIATEABLE:
		return
	_find_player()
	_update_state()
	_execute_state(delta)
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta

func _find_player() -> void:
	if _player == null or not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]

func _update_state() -> void:
	if _player == null:
		state = State.PATROL
		return
	var dist := global_position.distance_to(_player.global_position)
	if state == State.FLEE:
		return
	if dist <= DETECT_RANGE:
		state = State.ATTACK
	else:
		state = State.PATROL

func _execute_state(delta: float) -> void:
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.PATROL:
			_do_patrol(delta)
		State.ATTACK:
			_do_attack(delta)
		State.FLEE:
			_do_flee(delta)

func _do_patrol(_delta: float) -> void:
	if global_position.distance_to(_patrol_target) < 10.0:
		_patrol_target = global_position + Vector2(randf_range(-150, 150), randf_range(-75, 75))
	var dir := ((_patrol_target - global_position).normalized())
	velocity = dir * (SPEED * 0.5)
	move_and_slide()

func _do_attack(_delta: float) -> void:
	if _player == null:
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist > ATTACK_RANGE:
		var dir := (_player.global_position - global_position).normalized()
		velocity = dir * SPEED
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		if _attack_cooldown <= 0.0:
			_attack_cooldown = ATTACK_COOLDOWN
			if _player.has_method("take_damage"):
				_player.take_damage(attack_damage)

func _do_flee(_delta: float) -> void:
	if _player == null:
		return
	var dir := (global_position - _player.global_position).normalized()
	velocity = dir * SPEED * 1.2
	move_and_slide()

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	var hp_ratio := float(current_hp) / float(max_hp)
	if hp_ratio <= NEGOTIATEABLE_HP_THRESHOLD and not _is_negotiateable:
		_become_negotiateable()
	if current_hp <= 0:
		_die()

func _become_negotiateable() -> void:
	_is_negotiateable = true
	state = State.NEGOTIATEABLE
	velocity = Vector2.ZERO
	emit_signal("became_negotiateable")

func _die() -> void:
	emit_signal("died")
	queue_free()

func get_demon_data() -> Dictionary:
	return demon_data

func is_negotiateable() -> bool:
	return _is_negotiateable

func start_enrage() -> void:
	_is_negotiateable = false
	state = State.ATTACK
	attack_damage = int(attack_damage * 1.5)
