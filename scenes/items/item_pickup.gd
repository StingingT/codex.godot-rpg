extends Area2D
class_name ItemPickup

@export var item_id: String = ""
@export var quantity: int = 1
const PICKUP_TEXT_LIFETIME: float = 5.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var bob_offset: float = 0.0
var bob_speed: float = 3.0
var bob_height: float = 3.0
var player_in_range: Player = null
var is_picked_up: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_create_placeholder_marker()
	
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
	if is_picked_up or player == null:
		return
	var item := DataRegistry.get_item_data(item_id)
	if item and player.inventory:
		if not player.inventory.add_item(item, quantity):
			return
		GameManager.item_picked_up.emit(item_id, quantity)
		_show_pickup_text(item.item_name)
	else:
		GameManager.item_picked_up.emit(item_id, quantity)
		_show_pickup_text(item_id)
	is_picked_up = true
	queue_free()

func _show_pickup_text(item_name: String):
	var label = Label.new()
	label.text = "+ %s" % item_name
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

func _create_placeholder_marker() -> void:
	if sprite and sprite.texture:
		return
	for x in [-5.0, 0.0, 5.0]:
		var dot := Polygon2D.new()
		dot.color = Color.WHITE
		dot.polygon = PackedVector2Array([
			Vector2(-1.5, -1.5),
			Vector2(1.5, -1.5),
			Vector2(1.5, 1.5),
			Vector2(-1.5, 1.5)
		])
		dot.position = Vector2(x, 0.0)
		dot.z_index = 5
		add_child(dot)
