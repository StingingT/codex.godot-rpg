extends Area2D
class_name HurtboxComponent

@export var invincibility_time: float = 0.5

var is_invincible: bool = false
var stats: StatsComponent

signal damage_taken(amount: int, attacker_position: Vector2)
signal invincibility_started
signal invincibility_ended

func _ready() -> void:
	stats = get_parent().get_node_or_null("StatsComponent") as StatsComponent
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if is_invincible:
		return
	if area is HitboxComponent:
		var hitbox := area as HitboxComponent
		if not hitbox.can_hit(get_parent()):
			return
		hitbox.mark_hit(get_parent())
		_receive_damage_package(hitbox.get_damage_package(), hitbox)

func receive_damage_package(damage_package: Dictionary) -> void:
	_receive_damage_package(damage_package, null)

func _receive_damage_package(damage_package: Dictionary, hitbox: HitboxComponent = null) -> void:
	if not stats:
		return
	var amount := int(damage_package.get("amount", 0))
	var source: Variant = damage_package.get("source", null)
	var attacker_pos := global_position
	if source is Node2D:
		attacker_pos = source.global_position
	elif hitbox:
		attacker_pos = hitbox.global_position
	stats.take_damage(amount)
	for effect in damage_package.get("status_effects", []):
		EffectRouter.apply_effect(effect, source, get_parent())
	damage_taken.emit(amount, attacker_pos)
	_apply_knockback(damage_package, attacker_pos)
	_start_invincibility()
	_spawn_damage_number(amount, bool(damage_package.get("is_critical", false)))
	GameManager.emit_damage(amount, global_position, bool(damage_package.get("is_critical", false)))

func _apply_knockback(damage_package: Dictionary, attacker_pos: Vector2) -> void:
	var parent = get_parent()
	if not (parent is CharacterBody2D):
		return
	var knockback_value = damage_package.get("knockback", Vector2.ZERO)
	if knockback_value is Vector2 and knockback_value != Vector2.ZERO:
		parent.velocity = knockback_value
	else:
		var force := float(damage_package.get("knockback_force", 0.0))
		if force > 0.0:
			parent.velocity = (global_position - attacker_pos).normalized() * force

func _spawn_damage_number(amount: int, is_crit: bool = false) -> void:
	var dmg_num = preload("res://scenes/effects/damage_number.tscn").instantiate()
	dmg_num.global_position = global_position + Vector2(randf_range(-10, 10), -30)
	dmg_num.setup(amount, is_crit, true)
	get_tree().current_scene.add_child(dmg_num)

func _start_invincibility() -> void:
	is_invincible = true
	invincibility_started.emit()
	var parent = get_parent()
	var sprite = parent.get_node_or_null("AnimatedSprite2D")
	if sprite:
		var tween = create_tween()
		tween.set_loops(int(invincibility_time * 4))
		tween.tween_property(sprite, "modulate:a", 0.3, 0.125)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.125)
	await get_tree().create_timer(invincibility_time).timeout
	is_invincible = false
	invincibility_ended.emit()
