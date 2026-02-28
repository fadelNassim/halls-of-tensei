extends SceneTree

func _init() -> void:
	print("Running Night Cathedral Tests...")
	var test_scripts := [
		"res://tests/test_fusion.gd",
		"res://tests/test_negotiation.gd",
		"res://tests/test_data_load.gd"
	]
	for path in test_scripts:
		var script := load(path)
		if script == null:
			push_error("Could not load test: " + path)
			continue
		var test := script.new()
		get_root().add_child(test)
		await process_frame
		test.queue_free()
	print("Test run complete.")
	quit()
