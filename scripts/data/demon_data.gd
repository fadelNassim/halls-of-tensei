extends Resource
class_name DemonData

const DEMONS_JSON_PATH := "res://data/demons.json"

var id: String = ""
var name: String = ""
var alignment: String = "neutral"
var mythology: String = ""
var rank: int = 1
var base_stats: Dictionary = {}
var skills: Array = []
var recruit_rules: Dictionary = {}
var flags: Dictionary = {}

static func load_all_demons() -> Array:
	var file := FileAccess.open(DEMONS_JSON_PATH, FileAccess.READ)
	if not file:
		push_error("DemonData: Could not open " + DEMONS_JSON_PATH)
		return []
	var json_text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(json_text)
	if parsed == null:
		push_error("DemonData: Failed to parse demons.json")
		return []
	var demons_list: Array = []
	for d in parsed.get("demons", []):
		demons_list.append(from_dict(d))
	return demons_list

static func from_dict(d: Dictionary) -> DemonData:
	var demon := DemonData.new()
	demon.id = d.get("id", "")
	demon.name = d.get("name", "Unknown")
	demon.alignment = d.get("alignment", "neutral")
	demon.mythology = d.get("mythology", "")
	demon.rank = d.get("rank", 1)
	demon.base_stats = d.get("base_stats", {}).duplicate()
	demon.skills = d.get("skills", []).duplicate()
	demon.recruit_rules = d.get("recruit_rules", {}).duplicate()
	demon.flags = d.get("flags", {}).duplicate()
	return demon

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"alignment": alignment,
		"mythology": mythology,
		"rank": rank,
		"base_stats": base_stats.duplicate(),
		"skills": skills.duplicate(),
		"recruit_rules": recruit_rules.duplicate(),
		"flags": flags.duplicate()
	}

func is_recruitable() -> bool:
	return flags.get("recruitable_in_run", false)

func is_immutable() -> bool:
	return flags.get("immutable", false)

func is_boss() -> bool:
	return flags.get("boss", false)

func alignment_value() -> float:
	match alignment:
		"law":
			return 1.0
		"chaos":
			return -1.0
		_:
			return 0.0
