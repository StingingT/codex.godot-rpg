extends Area2D
class_name XPOrb

@export var xp_value: int = 10

@onready var sprite: Sprite2D = $Sprite2D

var target: Node2D = null
var speed: float = 100.0
var magnet_range: float = 60.0

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Find player
	await get_tree().process_frame
	target = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if target:
		var distance = global_position.distance_to(target.global_position)
		if distance < magnet_range:
			var direction = (target.global_position - global_position).normalized()
			global_position += direction * speed * delta

func _on_body_entered(body: Node2D):
	if body is Player:
		body.stats.add_xp(xp_value)
		queue_free()
