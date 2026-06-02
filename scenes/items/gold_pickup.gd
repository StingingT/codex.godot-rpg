extends Area2D
class_name GoldPickup

@export var gold_amount: int = 1
const PICKUP_TEXT_LIFETIME: float = 5.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var bob_offset: float = 0.0
var bob_speed: float = 3.0
var bob_height: float = 3.0
var player_in_range: Player = null
var is_picked_up: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Start bobbing animation using the configured variables
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - bob_height, 0.5 / bob_speed)
	tween.tween_property(self, "position:y", position.y + bob_height, 0.5 / bob_speed)

func _on_body_entered(body: Node2D):
	if body is Player:
		player_in_range = body as Player
		_pick_up(player_in_range)

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and not (event is InputEventKey and event.is_echo()):
		_pick_up(player_in_range)

func _pick_up(player: Player) -> void:
	if is_picked_up or player == null or player.inventory == null:
		return
	is_picked_up = true
	player.inventory.add_gold(gold_amount)
	GameManager.player_gold_changed.emit(player.inventory.gold)
	GameManager.item_picked_up.emit("gold", gold_amount)
	_show_pickup_text()
	queue_free()

func _show_pickup_text():
	var label = Label.new()
	label.text = "+ %d Gold" % gold_amount
	label.modulate = Color(1, 0.8, 0.2)  # Gold color
	label.position = global_position
	_get_pickup_text_parent().add_child(label)
	
	# Animate while visible
	var tween = label.create_tween()
	tween.tween_interval(max(PICKUP_TEXT_LIFETIME - 1.0, 0.0))
	tween.tween_property(label, "position:y", label.position.y - 30, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(label.queue_free)

func _get_pickup_text_parent() -> Node:
	return get_tree().current_scene if get_tree().current_scene != null else get_tree().root
