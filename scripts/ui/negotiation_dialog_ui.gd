extends Control

signal negotiation_done(success: bool, demon_data: Dictionary)

var _negotiation_system: NegotiationSystem
var _demon_data: Dictionary = {}

@onready var demon_name_label: Label = $VBoxContainer/DemonNameLabel
@onready var dialog_text: Label = $VBoxContainer/DialogText
@onready var chance_label: Label = $VBoxContainer/ChanceLabel
@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var appeal_button: Button = $VBoxContainer/ButtonsContainer/AppealButton
@onready var threaten_button: Button = $VBoxContainer/ButtonsContainer/ThreatenButton
@onready var offer_item_button: Button = $VBoxContainer/ButtonsContainer/OfferItemButton

func _ready() -> void:
	_negotiation_system = NegotiationSystem.new()
	add_child(_negotiation_system)
	_negotiation_system.negotiation_result.connect(_on_negotiation_result)
	appeal_button.pressed.connect(_on_appeal_pressed)
	threaten_button.pressed.connect(_on_threaten_pressed)
	offer_item_button.pressed.connect(_on_offer_item_pressed)
	hide()

func open_negotiation(demon_data: Dictionary, player_stats: Dictionary, alignment_sys: AlignmentSystem) -> void:
	_demon_data = demon_data
	_negotiation_system.setup(alignment_sys)
	var chance := _negotiation_system.start_negotiation(demon_data, player_stats)
	demon_name_label.text = demon_data.get("name", "Unknown Demon")
	dialog_text.text = "A %s stands before you, weakened but defiant. Will you negotiate?" % demon_data.get("name", "demon")
	result_label.text = ""
	_update_chance_label(chance)
	_set_buttons_enabled(true)
	show()

func _update_chance_label(chance: float) -> void:
	chance_label.text = "Recruit Chance: %d%%" % int(chance * 100)

func _set_buttons_enabled(enabled: bool) -> void:
	appeal_button.disabled = not enabled
	threaten_button.disabled = not enabled
	offer_item_button.disabled = not enabled

func _on_appeal_pressed() -> void:
	var chance := _negotiation_system.apply_appeal()
	_update_chance_label(chance)
	_resolve()

func _on_threaten_pressed() -> void:
	var chance := _negotiation_system.apply_threaten()
	_update_chance_label(chance)
	_resolve()

func _on_offer_item_pressed() -> void:
	var chance := _negotiation_system.apply_item_offer(0.15)
	_update_chance_label(chance)
	_resolve()

func _resolve() -> void:
	_set_buttons_enabled(false)
	var success := _negotiation_system.resolve()
	if success:
		result_label.text = "Success! The demon joins your roster!"
		result_label.modulate = Color(0.2, 1.0, 0.2, 1)
	else:
		result_label.text = "Failed! The demon is enraged!"
		result_label.modulate = Color(1.0, 0.2, 0.2, 1)
	await get_tree().create_timer(1.5).timeout
	hide()
	emit_signal("negotiation_done", success, _demon_data)

func _on_negotiation_result(_success: bool, _demon_id: String) -> void:
	pass
