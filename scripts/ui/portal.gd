extends Area2D
class_name Portal

@export var target_map: String = ""
@export var target_position: Vector2 = Vector2.ZERO
@export var target_entry: String = ""
@export var portal_name: String = "Portal"
@export var requires_all_monsters_dead: bool = false

@onready var label: Label = $Label

var player_in_range: bool = false
var is_unlocked: bool = true

func _ready():
	add_to_group("portal")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.hide()

func _input(event):
	if player_in_range and event.is_action_pressed("interact"):
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
