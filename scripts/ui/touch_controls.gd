extends Control
class_name TouchControls

@onready var joystick_base: Control = $Joystick/Base
@onready var joystick_knob: Control = $Joystick/Knob
@onready var attack_button: Button = $AttackButton
@onready var interact_button: Button = $InteractButton
@onready var inventory_button: Button = $InventoryButton

var joystick_active: bool = false
var joystick_center: Vector2
var joystick_radius: float = 40.0
var joystick_touch_id: int = -1

var input_vector: Vector2 = Vector2.ZERO

func _ready():
	# Only show on mobile
	if not OS.has_feature("mobile") and not OS.has_feature("android") and not OS.has_feature("ios"):
		# For testing on PC, you can uncomment the next line:
		# pass
		hide()
		return
	
	joystick_center = joystick_base.global_position + Vector2(40, 40)
	
	# Connect button signals
	attack_button.pressed.connect(_on_attack_pressed)
	interact_button.pressed.connect(_on_interact_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)

func _input(event):
	if not visible:
		return
	
	# Handle touch events
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var touch_pos = event.position
	
	if event.pressed:
		# Check if touch is within joystick area
		var dist_to_joystick = touch_pos.distance_to(joystick_center)
		if dist_to_joystick <= joystick_radius * 2 and joystick_touch_id == -1:
			joystick_touch_id = event.index
			joystick_active = true
			_update_joystick(touch_pos)
	else:
		# Touch released
		if event.index == joystick_touch_id:
			joystick_touch_id = -1
			joystick_active = false
			input_vector = Vector2.ZERO
			joystick_knob.position = Vector2(32, 32)  # Center

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == joystick_touch_id and joystick_active:
		_update_joystick(event.position)

func _update_joystick(touch_pos: Vector2) -> void:
	var direction = touch_pos - joystick_center
	var distance = direction.length()
	
	# Clamp to radius
	if distance > joystick_radius:
		direction = direction.normalized() * joystick_radius
		distance = joystick_radius
	
	# Update knob position
	joystick_knob.global_position = joystick_center + direction - Vector2(8, 8)
	
	# Calculate input vector (normalized)
	input_vector = direction / joystick_radius

func _on_attack_pressed() -> void:
	# Simulate attack input
	Input.action_press("attack")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("attack")

func _on_interact_pressed() -> void:
	Input.action_press("interact")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("interact")

func _on_inventory_pressed() -> void:
	Input.action_press("open_inventory")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("open_inventory")

func get_input_vector() -> Vector2:
	return input_vector
