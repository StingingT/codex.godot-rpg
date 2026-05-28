extends Label
class_name DamageNumber

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 1.0
var fade_speed: float = 1.0

func _ready():
	# Random slight horizontal drift
	velocity.x = randf_range(-20, 20)
	velocity.y = -50  # Float upward
	
	# Start fade timer
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _process(delta):
	position += velocity * delta
	velocity.y += 30 * delta  # Gravity effect
	
	# Fade out
	modulate.a -= fade_speed * delta
	if modulate.a <= 0:
		queue_free()

func setup(value: int, is_critical: bool = false, is_player_damage: bool = false):
	text = str(value)
	
	if is_player_damage:
		# Player taking damage - red
		modulate = Color(1, 0, 0, 1)
		scale = Vector2(1.0, 1.0)
	elif is_critical:
		# Critical hit - yellow, larger
		modulate = Color(1, 0.9, 0.2, 1)
		scale = Vector2(1.5, 1.5)
	else:
		# Normal damage - white
		modulate = Color(1, 1, 1, 1)
		scale = Vector2(1.0, 1.0)
