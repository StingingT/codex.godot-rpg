extends Area2D
class_name GoldPickup

@export var gold_amount: int = 1

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var bob_offset: float = 0.0
var bob_speed: float = 3.0
var bob_height: float = 3.0

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Start bobbing animation using the configured variables
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - bob_height, 0.5 / bob_speed)
	tween.tween_property(self, "position:y", position.y + bob_height, 0.5 / bob_speed)

func _on_body_entered(body: Node2D):
	if body is Player:
		var player = body as Player
		
		# Add gold to inventory
		if player.inventory:
			player.inventory.add_gold(gold_amount)
			
			# Show pickup text
			_show_pickup_text()
			
			queue_free()

func _show_pickup_text():
	var label = Label.new()
	label.text = "+ %d Gold" % gold_amount
	label.modulate = Color(1, 0.8, 0.2)  # Gold color
	label.position = global_position
	get_tree().current_scene.add_child(label)
	
	# Auto-remove after 1 second
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(func():
		if is_instance_valid(label):
			label.queue_free()
	)
	
	# Animate while visible
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
