extends Area2D
class_name Portal

@export var target_map: String = ""
@export var target_position: Vector2 = Vector2.ZERO
@export var target_entry: String = ""
@export var portal_name: String = "Portal"
@export var requires_all_monsters_dead: bool = false
@export var available_maps: Array[Dictionary] = [
	{"id": "town", "name": "Safe Haven Town", "level_req": 1},
	{"id": "fields", "name": "Eastern Fields", "level_req": 1},
	{"id": "swamp", "name": "Murky Swamp", "level_req": 5},
	{"id": "cave", "name": "Dark Cave", "level_req": 8},
	{"id": "dungeon", "name": "Ancient Dungeon", "level_req": 12}
]

@onready var label: Label = $Label

var player_in_range: bool = false
var is_unlocked: bool = true
var map_selector: MapSelector = null

func _ready():
	add_to_group("portal")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.hide()

func _input(event):
	if player_in_range and event.is_action_pressed("interact") and not (event is InputEventKey and event.is_echo()):
		if is_unlocked:
			_use_portal()
		else:
			_show_locked_message()

func _on_body_entered(body: Node2D):
	if body is Player:
		player_in_range = true
		label.show()
		
		if requires_all_monsters_dead:
			_check_unlock_condition()

func _on_body_exited(body: Node2D):
	if body is Player:
		player_in_range = false
		label.hide()

func _use_portal():
	if not available_maps.is_empty():
		_open_map_selector()
		return
	if target_map == "":
		return
	if target_entry != "":
		MapManager.change_map_to_entry(target_map, target_entry)
	else:
		MapManager.change_map(target_map, target_position)

func _check_unlock_condition():
	var monsters = get_tree().get_nodes_in_group("monsters")
	if monsters.size() > 0:
		is_unlocked = false
		label.text = "Locked!\nDefeat all monsters"
	else:
		is_unlocked = true
		label.text = portal_name + "\n[Press E]"

func _show_locked_message():
	# Show a temporary message
	label.text = "Defeat all monsters first!"
	await get_tree().create_timer(2.0).timeout
	if player_in_range:
		label.text = portal_name + "\n[Locked]"

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
	map_selector.open(player_level, available_maps)

func _on_map_selected(map_id: String) -> void:
	MapManager.change_map(map_id)
