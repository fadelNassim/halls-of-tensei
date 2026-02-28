extends Node

func _ready() -> void:
	print("=== test_data_load.gd ===")
	_test_load_all_demons()
	_test_demon_fields()
	_test_alignment_values()
	_test_flags()
	print("=== All data load tests passed ===")

func _test_load_all_demons() -> void:
	var demons := DemonData.load_all_demons()
	assert(demons.size() == 10, "Expected 10 demons, got %d" % demons.size())
	print("PASS: load_all_demons returns 10 demons")

func _test_demon_fields() -> void:
	var demons := DemonData.load_all_demons()
	var d: DemonData = demons[0]
	assert(d.id != "", "Demon id should not be empty")
	assert(d.name != "", "Demon name should not be empty")
	assert(d.rank >= 1, "Rank should be >= 1")
	assert(d.base_stats.has("hp"), "base_stats should have hp")
	assert(d.base_stats.has("atk"), "base_stats should have atk")
	assert(d.skills.size() > 0, "Demon should have at least one skill")
	print("PASS: demon fields present")

func _test_alignment_values() -> void:
	var demons := DemonData.load_all_demons()
	for d in demons:
		assert(d.alignment in ["law", "neutral", "chaos"], "Invalid alignment: " + d.alignment)
	print("PASS: all alignments valid")

func _test_flags() -> void:
	var demons := DemonData.load_all_demons()
	for d in demons:
		assert(d.flags.has("boss"), "flags.boss missing for " + d.id)
		assert(d.flags.has("recruitable_in_run"), "flags.recruitable_in_run missing for " + d.id)
		assert(d.flags.has("immutable"), "flags.immutable missing for " + d.id)
	print("PASS: all flags present")
