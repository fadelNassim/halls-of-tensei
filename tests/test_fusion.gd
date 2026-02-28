extends Node

func _ready() -> void:
	print("=== test_fusion.gd ===")
	_test_can_fuse_normal()
	_test_can_fuse_immutable()
	_test_can_fuse_same_demon()
	_test_generic_fuse_stats()
	_test_alignment_resolve()
	print("=== All fusion tests passed ===")

func _make_demon(id: String, rank: int, alignment: String, immutable: bool = false) -> Dictionary:
	return {
		"id": id,
		"name": id.capitalize(),
		"rank": rank,
		"alignment": alignment,
		"mythology": "test",
		"base_stats": { "hp": 100, "atk": 20, "def": 10, "spd": 10 },
		"skills": ["skill_a", "skill_b"],
		"recruit_rules": { "base_chance": 0.5, "alignment_bias": 0.0 },
		"flags": { "immutable": immutable, "boss": false, "recruitable_in_run": true }
	}

func _test_can_fuse_normal() -> void:
	var fs := FusionSystem.new()
	var a := _make_demon("oni", 2, "chaos")
	var b := _make_demon("angel", 3, "law")
	var result := fs.can_fuse(a, b)
	assert(result.get("ok") == true, "Normal demons should be fuseable")
	print("PASS: can_fuse normal")
	fs.free()

func _test_can_fuse_immutable() -> void:
	var fs := FusionSystem.new()
	var a := _make_demon("boss", 5, "chaos", true)
	var b := _make_demon("normal", 2, "neutral")
	var result := fs.can_fuse(a, b)
	assert(result.get("ok") == false, "Immutable demon should not be fuseable")
	print("PASS: can_fuse immutable blocked")
	fs.free()

func _test_can_fuse_same_demon() -> void:
	var fs := FusionSystem.new()
	var a := _make_demon("oni", 2, "chaos")
	var result := fs.can_fuse(a, a)
	assert(result.get("ok") == false, "Same demon cannot fuse with itself")
	print("PASS: can_fuse same demon blocked")
	fs.free()

func _test_generic_fuse_stats() -> void:
	var fs := FusionSystem.new()
	var a := _make_demon("oni", 2, "chaos")
	var b := _make_demon("angel", 3, "law")
	var child := fs.fuse(a, b)
	assert(child.size() > 0, "Fusion should return a child")
	assert(child.get("rank") == 4, "Fused rank should be max(2,3)+1=4, got %d" % child.get("rank"))
	var expected_hp := int((100 + 100) * 0.55)
	assert(child.get("base_stats", {}).get("hp") == expected_hp, "HP mismatch: expected %d" % expected_hp)
	assert(child.get("alignment") == "neutral", "law+chaos should produce neutral alignment")
	print("PASS: generic fuse stats")
	fs.free()

func _test_alignment_resolve() -> void:
	var fs := FusionSystem.new()
	var a := _make_demon("law_a", 2, "law")
	var b := _make_demon("law_b", 2, "law")
	var child := fs.fuse(a, b)
	assert(child.get("alignment") == "law", "law+law should produce law, got: " + child.get("alignment", ""))
	print("PASS: alignment resolve law+law")
	fs.free()
