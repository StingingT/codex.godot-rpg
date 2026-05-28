extends Area2D
class_name MapTransition

@export var target_map_id: String = ""
@export var target_entry_id: String = ""
@export var requires_interact: bool = false

var player_in_range := false

func _ready() -> void:
	collision_layer = 32 # layer 6: Interaction
	collision_mask = 1   # layer 1: Player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _input(event: InputEvent) -> void:
	if requires_interact and player_in_range and event.is_action_pressed("interact"):
		_trigger_transition()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = true
		if not requires_interact:
			_trigger_transition()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false

func _trigger_transition() -> void:
	if target_map_id == "":
		return
	MapManager.change_map_to_entry(target_map_id, target_entry_id)
