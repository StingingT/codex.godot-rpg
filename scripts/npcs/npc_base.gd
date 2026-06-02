extends StaticBody2D
class_name NPC

const CharacterSpriteFactory := preload("res://scripts/visuals/character_sprite_factory.gd")

@export var npc_id: String = ""
@export var npc_name: String = "NPC"
@export var dialogue_id: String = ""
@export_file("*.png") var idle_sprite_sheet_path: String = ""
@export var sprite_offset: Vector2 = Vector2(0, -20)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_zone: Area2D = $InteractionZone
@onready var indicator: Label = $Indicator

var player_in_range: bool = false

func _ready():
	add_to_group("npcs")
	_apply_custom_sprite()
	
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	
	indicator.hide()
	
	# Check quest status for indicator
	_update_indicator()

func _apply_custom_sprite() -> void:
	if idle_sprite_sheet_path == "" or animated_sprite == null:
		if animated_sprite:
			animated_sprite.play("idle")
		return
	var frames := CharacterSpriteFactory.build_directional_frames(idle_sprite_sheet_path)
	if frames == null:
		return
	animated_sprite.sprite_frames = frames
	animated_sprite.position = sprite_offset
	animated_sprite.modulate = Color.WHITE
	animated_sprite.play("idle")
	animated_sprite.set_frame_and_progress(0, 0.0)

func _input(event):
	if player_in_range and event.is_action_pressed("interact") and not (event is InputEventKey and event.is_echo()):
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
