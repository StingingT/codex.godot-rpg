extends Area2D
class_name XPOrb

@export var xp_value: int = 10

@onready var sprite: Sprite2D = $Sprite2D

var target: Node2D = null
var speed: float = 100.0
var magnet_range: float = 60.0
var player_in_range: Player = null
var is_picked_up: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
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
		player_in_range = body as Player
		_pick_up(player_in_range)

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and not (event is InputEventKey and event.is_echo()):
		_pick_up(player_in_range)

func _pick_up(player: Player) -> void:
	if is_picked_up or player == null or player.stats == null:
		return
	is_picked_up = true
	player.stats.add_xp(xp_value)
	GameManager.player_xp_changed.emit(player.stats.current_xp, player.stats.xp_to_next, player.stats.level)
	queue_free()
