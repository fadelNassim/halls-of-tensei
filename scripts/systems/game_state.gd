extends Node
class_name GameState

const SAVE_PATH := "user://night_cathedral_save.json"

var player_state: Dictionary = {}
var demon_roster: Array = []
var fusion_points: int = 0
var alignment_value: float = 0.0
var run_count: int = 0
var telemetry: Array = []

func save_run_data(run_data: Dictionary) -> void:
	telemetry.append(run_data)
	_save_to_file()

func _save_to_file() -> void:
	var data := {
		"player_state": player_state,
		"demon_roster": demon_roster.duplicate(true),
		"fusion_points": fusion_points,
		"alignment_value": alignment_value,
		"run_count": run_count,
		"telemetry": telemetry.duplicate(true)
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_from_file() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null:
		return false
	player_state = parsed.get("player_state", {})
	demon_roster = parsed.get("demon_roster", []).duplicate(true)
	fusion_points = parsed.get("fusion_points", 0)
	alignment_value = parsed.get("alignment_value", 0.0)
	run_count = parsed.get("run_count", 0)
	telemetry = parsed.get("telemetry", []).duplicate(true)
	return true

func update_from_player(player: Player) -> void:
	player_state = player.save_state()
	demon_roster = player.demon_roster.duplicate(true)
	fusion_points = player.fusion_points
	alignment_value = player.alignment_value

func restore_player(player: Player) -> void:
	if player_state.size() > 0:
		player.load_state(player_state)

func record_run_telemetry(
	run_time: float,
	waves_cleared: int,
	recruited_count: int,
	fusions_made: int,
	player_alignment: float,
	deaths: int
) -> void:
	run_count += 1
	var entry := {
		"run_id": run_count,
		"run_time": run_time,
		"waves_cleared": waves_cleared,
		"recruited_count": recruited_count,
		"fusions_made": fusions_made,
		"player_alignment": player_alignment,
		"deaths": deaths
	}
	telemetry.append(entry)
	_save_to_file()

func export_telemetry_csv() -> String:
	var lines := ["run_id,run_time,waves_cleared,recruited_count,fusions_made,player_alignment,deaths"]
	for entry in telemetry:
		lines.append("%d,%.2f,%d,%d,%d,%.2f,%d" % [
			entry.get("run_id", 0),
			entry.get("run_time", 0.0),
			entry.get("waves_cleared", 0),
			entry.get("recruited_count", 0),
			entry.get("fusions_made", 0),
			entry.get("player_alignment", 0.0),
			entry.get("deaths", 0)
		])
	return "\n".join(lines)
