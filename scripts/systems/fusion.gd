extends Node
class_name FusionSystem

const FUSION_RECIPES_PATH := "res://data/fusion_recipes.json"
const FUSION_COST_PER_RANK := 50

var _recipes: Array = []
var _alignment_rules: Dictionary = {}

func _ready() -> void:
	_load_recipes()

func _load_recipes() -> void:
	var file := FileAccess.open(FUSION_RECIPES_PATH, FileAccess.READ)
	if not file:
		push_error("FusionSystem: Could not open " + FUSION_RECIPES_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null:
		push_error("FusionSystem: Failed to parse fusion_recipes.json")
		return
	_recipes = parsed.get("recipes", [])
	_alignment_rules = parsed.get("alignment_rules", {})

# Returns { "ok": bool, "reason": String }
func can_fuse(a: Dictionary, b: Dictionary) -> Dictionary:
	if a.get("flags", {}).get("immutable", false):
		return { "ok": false, "reason": "%s is a unique demon and cannot be fused." % a.get("name", "Demon A") }
	if b.get("flags", {}).get("immutable", false):
		return { "ok": false, "reason": "%s is a unique demon and cannot be fused." % b.get("name", "Demon B") }
	if a.get("id", "") == b.get("id", ""):
		return { "ok": false, "reason": "Cannot fuse a demon with itself." }
	return { "ok": true, "reason": "" }

func fusion_cost(a: Dictionary, b: Dictionary) -> int:
	var rank_a: int = a.get("rank", 1)
	var rank_b: int = b.get("rank", 1)
	return (rank_a + rank_b) * FUSION_COST_PER_RANK

# Returns DemonData Dictionary for the fused child, or empty dict on failure
func fuse(a: Dictionary, b: Dictionary) -> Dictionary:
	var check := can_fuse(a, b)
	if not check.get("ok", false):
		push_error("FusionSystem.fuse: " + check.get("reason", ""))
		return {}

	# Check specific recipe first
	var recipe := _find_recipe(a.get("id", ""), b.get("id", ""))
	if recipe.size() > 0:
		return recipe.get("result", {}).duplicate(true)

	# Generic rule-based fusion
	return _generic_fuse(a, b)

func _find_recipe(id_a: String, id_b: String) -> Dictionary:
	for recipe in _recipes:
		var pa: String = recipe.get("parent_a", "")
		var pb: String = recipe.get("parent_b", "")
		if (pa == id_a and pb == id_b) or (pa == id_b and pb == id_a):
			return recipe
	return {}

func _generic_fuse(a: Dictionary, b: Dictionary) -> Dictionary:
	var child := {}
	child["id"] = a.get("id", "a") + "_" + b.get("id", "b") + "_fus"
	child["name"] = a.get("name", "?") + "-" + b.get("name", "?") + " Hybrid"
	child["rank"] = max(a.get("rank", 1), b.get("rank", 1)) + 1
	child["mythology"] = "mixed"
	child["alignment"] = _resolve_alignment(a.get("alignment", "neutral"), b.get("alignment", "neutral"))

	var stats := {}
	for stat in ["hp", "atk", "def", "spd"]:
		var sa: int = a.get("base_stats", {}).get(stat, 10)
		var sb: int = b.get("base_stats", {}).get(stat, 10)
		stats[stat] = int((sa + sb) * 0.55)
	child["base_stats"] = stats

	# Inherit one skill from each parent
	var skills_a: Array = a.get("skills", [])
	var skills_b: Array = b.get("skills", [])
	var inherited: Array = []
	if skills_a.size() > 0:
		inherited.append(skills_a[skills_a.size() - 1])
	if skills_b.size() > 0:
		inherited.append(skills_b[skills_b.size() - 1])
	child["skills"] = inherited

	child["recruit_rules"] = {
		"base_chance": 0.0,
		"requires_item": null,
		"alignment_bias": 0.0
	}
	child["flags"] = { "boss": false, "recruitable_in_run": false, "immutable": false }
	return child

func _resolve_alignment(a_align: String, b_align: String) -> String:
	var key := "%s+%s" % [a_align, b_align]
	if _alignment_rules.has(key):
		return _alignment_rules[key]
	# Try reversed
	var key_rev := "%s+%s" % [b_align, a_align]
	if _alignment_rules.has(key_rev):
		return _alignment_rules[key_rev]
	return "neutral"
