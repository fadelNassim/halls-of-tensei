extends Node

func _ready() -> void:
	print("=== test_negotiation.gd ===")
	_test_base_chance()
	_test_appeal_increases_chance()
	_test_threaten_strong_increases_chance()
	_test_item_offer_increases_chance()
	_test_chance_clamped()
	print("=== All negotiation tests passed ===")

func _make_demon(base_chance: float, alignment: String, bias: float) -> Dictionary:
	return {
		"id": "test_demon",
		"name": "Test Demon",
		"alignment": alignment,
		"base_stats": { "hp": 100, "atk": 20, "def": 10, "spd": 10 },
		"recruit_rules": {
			"base_chance": base_chance,
			"alignment_bias": bias
		},
		"flags": {}
	}

func _make_player_stats(charisma: int, strength: int, alignment: float) -> Dictionary:
	return { "charisma": charisma, "strength": strength, "alignment": alignment }

func _test_base_chance() -> void:
	var ns := NegotiationSystem.new()
	var demon := _make_demon(0.4, "neutral", 0.0)
	var player_stats := _make_player_stats(5, 5, 0.0)
	var chance := ns.start_negotiation(demon, player_stats)
	# base 0.4 + charisma 5 * 0.01 = 0.45, alignment modifier ~0 when both neutral
	assert(chance >= 0.44 and chance <= 0.46, "Base chance mismatch: got %.3f" % chance)
	print("PASS: base chance calculation")
	ns.free()

func _test_appeal_increases_chance() -> void:
	var ns := NegotiationSystem.new()
	var demon := _make_demon(0.3, "neutral", 0.0)
	var player_stats := _make_player_stats(10, 5, 0.0)
	ns.start_negotiation(demon, player_stats)
	var before := ns.get_current_chance()
	var after := ns.apply_appeal()
	assert(after > before, "Appeal should increase chance")
	print("PASS: appeal increases chance")
	ns.free()

func _test_threaten_strong_increases_chance() -> void:
	var ns := NegotiationSystem.new()
	var demon := _make_demon(0.3, "neutral", 0.0)
	var player_stats := _make_player_stats(5, 30, 0.0)
	ns.start_negotiation(demon, player_stats)
	var before := ns.get_current_chance()
	var after := ns.apply_threaten()
	assert(after > before, "Threatening with high strength should increase chance")
	print("PASS: threaten with high strength")
	ns.free()

func _test_item_offer_increases_chance() -> void:
	var ns := NegotiationSystem.new()
	var demon := _make_demon(0.3, "neutral", 0.0)
	ns.start_negotiation(demon, _make_player_stats(5, 5, 0.0))
	var before := ns.get_current_chance()
	var after := ns.apply_item_offer(0.2)
	assert(after > before, "Item offer should increase chance")
	print("PASS: item offer increases chance")
	ns.free()

func _test_chance_clamped() -> void:
	var ns := NegotiationSystem.new()
	var demon := _make_demon(1.0, "neutral", 0.0)
	ns.start_negotiation(demon, _make_player_stats(100, 100, 0.0))
	ns.apply_appeal()
	ns.apply_item_offer(1.0)
	var chance := ns.get_current_chance()
	assert(chance <= 1.0, "Chance should be clamped to 1.0")
	print("PASS: chance clamped to 1.0")
	ns.free()
