extends Area2D

@export var speed: float = 180.0

var caster: Node = null
var ability: Dictionary = {}
var direction: Vector2 = Vector2.RIGHT
var max_range: float = 160.0
var distance_traveled: float = 0.0
var hit_targets: Dictionary = {}

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func setup(source: Node, ability_data: Dictionary, cast_direction: Vector2) -> void:
	caster = source
	ability = ability_data
	direction = cast_direction.normalized() if cast_direction != Vector2.ZERO else Vector2.RIGHT
	max_range = float(ability.get("range", max_range))
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	global_position += step
	distance_traveled += step.length()
	if distance_traveled >= max_range:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		_hit_target(area.get_parent())

func _on_body_entered(body: Node2D) -> void:
	if body == caster:
		return
	if body.collision_layer & 2:
		queue_free()

func _hit_target(target: Node) -> void:
	if target == null or target == caster:
		return
	var target_id := target.get_instance_id()
	if hit_targets.has(target_id):
		return
	hit_targets[target_id] = true
	EffectRouter.apply_effects(ability.get("effects", []), caster, target)
	queue_free()
