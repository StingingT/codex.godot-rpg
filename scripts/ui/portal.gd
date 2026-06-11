extends Area2D
class_name Portal

const QUEST_STATUS_COMPLETE := 3
const QUEST_STATUS_TURNED_IN := 4

@export var target_map: String = ""
@export var target_position: Vector2 = Vector2.ZERO
@export var target_entry: String = ""
@export var portal_name: String = "Portal"
@export var requires_all_monsters_dead: bool = false
@export var required_quest_id: String = ""
@export var required_quest_turned_in: bool = false
@export var use_custom_map_list: bool = false
@export var available_maps: Array[Dictionary] = []

@onready var label: Label = $Label

var player_in_range: bool = false
var is_unlocked: bool = true
var map_selector: MapSelector = null

func _ready():
	add_to_group("portal")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_refresh_label()
	label.hide()

func _input(event):
	if player_in_range and event.is_action_pressed("interact") and not (event is InputEventKey and event.is_echo()):
		if _requirements_met():
			_use_portal()
		else:
			_show_locked_message()

func _on_body_entered(body: Node2D):
	if body is Player:
		player_in_range = true
		label.show()
		_refresh_label()

func _on_body_exited(body: Node2D):
	if body is Player:
		player_in_range = false
		label.hide()

func _use_portal():
	if target_entry != "":
		MapManager.change_map_to_entry(target_map, target_entry)
		return
	if target_map != "":
		if target_position != Vector2.ZERO:
			MapManager.change_map(target_map, target_position)
		else:
			MapManager.change_map(target_map)
		return
	if not available_maps.is_empty():
		_open_map_selector()
	else:
		return

func _requirements_met() -> bool:
	if requires_all_monsters_dead and get_tree().get_nodes_in_group("monsters").size() > 0:
		is_unlocked = false
		return false
	if required_quest_id != "" and not _quest_requirement_met():
		is_unlocked = false
		return false
	is_unlocked = true
	return true

func _quest_requirement_met() -> bool:
	var quest_manager := get_node_or_null("/root/QuestManager")
	if quest_manager == null:
		return false
	var status := int(quest_manager.get_quest_status(required_quest_id))
	if required_quest_turned_in:
		return status == QUEST_STATUS_TURNED_IN
	return status == QUEST_STATUS_COMPLETE or status == QUEST_STATUS_TURNED_IN

func _refresh_label() -> void:
	if _requirements_met():
		label.text = portal_name + "\n[Press E]"
	else:
		label.text = _get_locked_label_text()

func _show_locked_message():
	label.text = _get_locked_label_text()
	await get_tree().create_timer(2.0).timeout
	if player_in_range:
		_refresh_label()

func _get_locked_label_text() -> String:
	if requires_all_monsters_dead and get_tree().get_nodes_in_group("monsters").size() > 0:
		return "Locked!\nDefeat all monsters"
	if required_quest_id != "":
		if required_quest_turned_in:
			return "Locked!\nTurn in quest"
		return "Locked!\nComplete quest"
	return portal_name + "\n[Locked]"

func _open_map_selector() -> void:
	if map_selector and map_selector.control.visible:
		map_selector.control.hide()
		return

	if not map_selector:
		map_selector = preload("res://scenes/ui/map_selector.tscn").instantiate()
		get_tree().root.add_child(map_selector)
		map_selector.map_selected.connect(_on_map_selected)

	var player = get_tree().get_first_node_in_group("player")
	var player_level := 1
	if player and player.stats:
		player_level = player.stats.level
	var travel_maps := DataRegistry.get_travel_maps()
	if use_custom_map_list and not available_maps.is_empty():
		travel_maps = available_maps
	map_selector.open(player_level, travel_maps)

func _on_map_selected(map_id: String) -> void:
	MapManager.change_map(map_id)
