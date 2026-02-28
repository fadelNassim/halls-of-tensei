extends Node
class_name AlignmentSystem

signal alignment_changed(new_value: float)

const MIN_VALUE := -100.0
const MAX_VALUE := 100.0

# Threshold for fusion/unlock effects
const LAW_THRESHOLD := 45.0
const CHAOS_THRESHOLD := -45.0

var value: float = 0.0

func shift(delta: float) -> void:
	value = clamp(value + delta, MIN_VALUE, MAX_VALUE)
	emit_signal("alignment_changed", value)

func get_label() -> String:
	if value >= LAW_THRESHOLD:
		return "Law"
	elif value <= CHAOS_THRESHOLD:
		return "Chaos"
	else:
		return "Neutral"

func get_numeric_label() -> float:
	return value

# Returns alignment category string for comparison with demons
func get_alignment_string() -> String:
	if value >= LAW_THRESHOLD:
		return "law"
	elif value <= CHAOS_THRESHOLD:
		return "chaos"
	else:
		return "neutral"

# Modifier applied to recruit chance based on alignment difference
# demon_alignment: "law", "neutral", or "chaos"
# alignment_bias: demon's recruit_rules.alignment_bias
func recruit_modifier(demon_alignment: String, alignment_bias: float) -> float:
	var demon_val := _alignment_to_value(demon_alignment)
	var player_norm := value / MAX_VALUE
	return (1.0 - abs(player_norm - demon_val)) * alignment_bias

static func _alignment_to_value(a: String) -> float:
	match a:
		"law":
			return 1.0
		"chaos":
			return -1.0
		_:
			return 0.0

func save_to_dict() -> Dictionary:
	return { "alignment_value": value }

func load_from_dict(d: Dictionary) -> void:
	value = clamp(d.get("alignment_value", 0.0), MIN_VALUE, MAX_VALUE)
