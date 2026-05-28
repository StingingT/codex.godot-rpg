extends StaticBody2D
class_name NPC

@export var npc_id: String = ""
@export var npc_name: String = "NPC"
@export var dialogue_id: String = ""

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_zone: Area2D = $InteractionZone
@onready var indicator: Label = $Indicator

var player_in_range: bool = false

func _ready():
	add_to_group("npcs")
	
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	
	indicator.hide()
	
	# Check quest status for indicator
	_update_indicator()

func _input(event):
	if player_in_range and event.is_action_pressed("interact"):
		if not DialogueManager.is_dialogue_active:
			_start_dialogue()

func _on_body_entered(body: Node2D):
	if body is Player:
		player_in_range = true
		indicator.show()
		indicator.text = "!"

func _on_body_exited(body: Node2D):
	if body is Player:
		player_in_range = false
		indicator.hide()

func _start_dialogue():
	if dialogue_id != "":
		DialogueManager.start_dialogue(dialogue_id)

func _update_indicator():
	# Check if this NPC has quests available
	# This would be expanded to show different icons for available/complete quests
	pass
