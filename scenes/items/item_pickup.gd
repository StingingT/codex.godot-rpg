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
	input_event.connect(_on_input_event)
	input_pickable = true
	_create_placeholder_marker()
	
	# Start bobbing animation using the configured variables
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - bob_height, 0.5 / bob_speed)
	tween.tween_property(self, "position:y", position.y + bob_height, 0.5 / bob_speed)

func _on_body_entered(body: Node2D):
	if body is Player:
		player_in_range = body as Player

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and not (event is InputEventKey and event.is_echo()):
		_pick_up(player_in_range)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if player_in_range == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_pick_up(player_in_range)
	elif event is InputEventScreenTouch and event.pressed:
		_pick_up(player_in_range)

func _pick_up(player: Player) -> void:
	if is_picked_up or player == null:
		return
	is_picked_up = true
	var item := DataRegistry.get_item_data(item_id)
	if item and player.inventory:
		var result := player.inventory.add_item_detailed(item, quantity)
		var accepted := int(result.get("accepted", 0))
		var remaining := int(result.get("remaining", quantity))
		if accepted <= 0:
			_show_message("Quest item limit reached" if result.get("reason", "") == "quest_limit" else "Inventory full")
			is_picked_up = false
			return
		GameManager.item_picked_up.emit(item_id, accepted)
		_show_message("+ %s x%d" % [item.item_name, accepted])
		quantity = remaining
		if remaining > 0:
			_show_message("Quest item limit reached" if result.get("reason", "") == "quest_limit" else "Inventory full")
			is_picked_up = false
			return
	else:
		push_warning("Cannot pick up unknown item: %s" % item_id)
		is_picked_up = false
		return
	queue_free()

func _show_message(message: String) -> void:
	var label = Label.new()
	label.text = message
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
