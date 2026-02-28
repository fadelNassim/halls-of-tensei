extends CharacterBody2D
class_name Player

signal health_changed(current: int, maximum: int)
signal died()
signal skill_used(skill_name: String)

const SPEED := 200.0
const ISO_SCALE := Vector2(1.0, 0.5)

@export var max_hp: int = 100
@export var attack_damage: int = 15
@export var charisma: int = 8
@export var strength: int = 10

var current_hp: int
var alignment_value: float = 0.0
var equipped_skills: Array = []
var fusion_points: int = 0
var demon_roster: Array = []
var active_follower = null

var _attack_cooldown: float = 0.0
const ATTACK_COOLDOWN_TIME := 0.4

func _ready() -> void:
	current_hp = max_hp

func _physics_process(delta: float) -> void:
	_handle_movement()
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		_try_attack()
	if event.is_action_pressed("use_skill_1") and equipped_skills.size() >= 1:
		_use_skill(equipped_skills[0])
	if event.is_action_pressed("use_skill_2") and equipped_skills.size() >= 2:
		_use_skill(equipped_skills[1])

func _handle_movement() -> void:
	var direction := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	direction = direction.normalized()

	# Isometric conversion: flatten y axis
	var iso_dir := Vector2(direction.x, direction.y * ISO_SCALE.y)
	velocity = iso_dir * SPEED
	move_and_slide()

func _try_attack() -> void:
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = ATTACK_COOLDOWN_TIME
	# Find nearest enemy and damage it
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node = null
	var nearest_dist := 100.0
	for e in enemies:
		if not e.has_method("take_damage"):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	if nearest:
		nearest.take_damage(attack_damage)

func _use_skill(skill_name: String) -> void:
	emit_signal("skill_used", skill_name)
	# Apply skill effect based on name (extendable)
	match skill_name:
		"club_smash":
			_aoe_attack(attack_damage * 1.5, 80.0)
		"roar":
			_buff_self(2.0)
		"fox_fire":
			_ranged_attack(attack_damage * 0.8, 300.0)
		_:
			_aoe_attack(attack_damage, 60.0)

func _aoe_attack(damage: float, radius: float) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(e.global_position) <= radius:
			if e.has_method("take_damage"):
				e.take_damage(int(damage))

func _ranged_attack(damage: float, _range: float) -> void:
	_aoe_attack(damage, _range)

func _buff_self(_duration: float) -> void:
	# Temporary buff placeholder
	pass

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	emit_signal("health_changed", current_hp, max_hp)
	if current_hp <= 0:
		_die()

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	emit_signal("health_changed", current_hp, max_hp)

func _die() -> void:
	emit_signal("died")
	set_physics_process(false)

func recruit_demon(demon_data: Dictionary) -> void:
	demon_roster.append(demon_data)
	# Equip skills if slots available
	var demon_skills: Array = demon_data.get("skills", [])
	for skill in demon_skills:
		if equipped_skills.size() < 2 and skill not in equipped_skills:
			equipped_skills.append(skill)
	fusion_points += demon_data.get("rank", 1) * 10

func get_stats() -> Dictionary:
	return {
		"charisma": charisma,
		"strength": strength,
		"alignment": alignment_value
	}

func save_state() -> Dictionary:
	return {
		"current_hp": current_hp,
		"max_hp": max_hp,
		"alignment_value": alignment_value,
		"equipped_skills": equipped_skills.duplicate(),
		"fusion_points": fusion_points,
		"demon_roster": demon_roster.duplicate(true)
	}

func load_state(state: Dictionary) -> void:
	max_hp = state.get("max_hp", 100)
	current_hp = state.get("current_hp", max_hp)
	alignment_value = state.get("alignment_value", 0.0)
	equipped_skills = state.get("equipped_skills", []).duplicate()
	fusion_points = state.get("fusion_points", 0)
	demon_roster = state.get("demon_roster", []).duplicate(true)
