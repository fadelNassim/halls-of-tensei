extends Node
class_name NegotiationSystem

signal negotiation_result(success: bool, demon_id: String)

var _current_demon: Dictionary = {}
var _player_stats: Dictionary = {}
var _alignment_system: AlignmentSystem = null
var _success_chance: float = 0.0

func setup(alignment_sys: AlignmentSystem) -> void:
	_alignment_system = alignment_sys

func start_negotiation(demon_data: Dictionary, player_stats: Dictionary) -> float:
	_current_demon = demon_data
	_player_stats = player_stats
	_success_chance = _calculate_base_chance()
	return _success_chance

func _calculate_base_chance() -> float:
	var rules: Dictionary = _current_demon.get("recruit_rules", {})
	var chance: float = rules.get("base_chance", 0.3)
	chance += _player_stats.get("charisma", 5) * 0.01
	if _alignment_system:
		var bias: float = rules.get("alignment_bias", 0.0)
		chance += _alignment_system.recruit_modifier(_current_demon.get("alignment", "neutral"), bias)
	return clamp(chance, 0.0, 1.0)

# Returns updated chance after appeal action (charisma check)
func apply_appeal() -> float:
	var charisma: int = _player_stats.get("charisma", 5)
	var bonus: float = charisma * 0.02
	_success_chance = clamp(_success_chance + bonus, 0.0, 1.0)
	return _success_chance

# Returns updated chance after threaten action (strength check)
func apply_threaten() -> float:
	var strength: int = _player_stats.get("strength", 5)
	# Threatening may backfire if demon is strong
	var demon_atk: int = _current_demon.get("base_stats", {}).get("atk", 10)
	var delta: float = (strength - demon_atk) * 0.015
	_success_chance = clamp(_success_chance + delta, 0.0, 1.0)
	return _success_chance

# Returns updated chance after offering item
func apply_item_offer(item_value: float) -> float:
	_success_chance = clamp(_success_chance + item_value, 0.0, 1.0)
	return _success_chance

# Roll for recruitment, emits signal, returns success bool
func resolve() -> bool:
	var roll := randf()
	var success := roll <= _success_chance
	emit_signal("negotiation_result", success, _current_demon.get("id", ""))
	return success

func get_current_chance() -> float:
	return _success_chance

func get_demon_id() -> String:
	return _current_demon.get("id", "")
