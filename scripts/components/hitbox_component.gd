extends Area2D
class_name HitboxComponent

@export var damage: int = 10
@export var damage_type: String = "physical"
@export var knockback_force: float = 100.0
@export var can_crit: bool = true
@export var is_critical: bool = false
@export var status_effects: Array[Dictionary] = []
@export var allow_repeat_hits: bool = false

var active: bool = false
var source: Node = null
var hit_targets: Dictionary = {}

func _ready() -> void:
	monitoring = false
	monitorable = true
	if source == null:
		source = get_parent()

func enable() -> void:
	active = true
	hit_targets.clear()
	monitoring = true

func disable() -> void:
	active = false
	monitoring = false
	hit_targets.clear()

func can_hit(target: Node) -> bool:
	if not active:
		return false
	if allow_repeat_hits:
		return true
	return not hit_targets.has(target.get_instance_id())

func mark_hit(target: Node) -> void:
	hit_targets[target.get_instance_id()] = true

func get_damage_package() -> Dictionary:
	var knockback := Vector2.ZERO
	if source and source is Node2D:
		knockback = (global_position - source.global_position).normalized() * knockback_force
	return EffectRouter.build_damage_package(source, damage, damage_type, knockback, can_crit, status_effects)

func spawn_damage_number(target_position: Vector2, amount: int, crit: bool = false) -> void:
	var dmg_num = preload("res://scenes/effects/damage_number.tscn").instantiate()
	dmg_num.global_position = target_position + Vector2(randf_range(-10, 10), -20)
	dmg_num.setup(amount, crit, false)
	get_tree().current_scene.add_child(dmg_num)
