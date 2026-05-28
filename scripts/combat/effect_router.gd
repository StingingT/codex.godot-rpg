extends Node

func build_damage_package(source: Node, amount: int, damage_type: String = "physical", knockback: Vector2 = Vector2.ZERO, can_crit: bool = true, status_effects: Array = []) -> Dictionary:
	return {
		"source": source,
		"amount": amount,
		"damage_type": damage_type,
		"knockback": knockback,
		"can_crit": can_crit,
		"status_effects": status_effects
	}

func apply_effects(effects: Array, source: Node, target: Node) -> void:
	for effect in effects:
		apply_effect(effect, source, target)

func apply_effect(effect: Dictionary, source: Node, target: Node) -> void:
	if target == null:
		return
	var effect_type := str(effect.get("type", "damage"))
	match effect_type:
		"damage":
			_apply_damage(effect, source, target)
		"heal":
			_apply_heal(effect, target)
		"dot", "hot", "buff", "debuff", "shield", "slow", "stun":
			_apply_status(effect, source, target)
		"lifesteal":
			_apply_lifesteal(effect, source, target)
		"knockback":
			_apply_knockback(effect, source, target)
		_:
			push_warning("Unsupported effect type: %s" % effect_type)

func _apply_damage(effect: Dictionary, source: Node, target: Node) -> void:
	var stats := _get_stats(target)
	if stats == null:
		return
	var amount := int(effect.get("amount", 0))
	if source:
		var source_stats := _get_stats(source)
		if source_stats:
			amount += source_stats.get_total_attack()
	stats.take_damage(amount)
	_apply_knockback(effect, source, target)

func _apply_heal(effect: Dictionary, target: Node) -> void:
	var stats := _get_stats(target)
	if stats:
		stats.heal(int(effect.get("amount", 0)))

func _apply_status(effect: Dictionary, source: Node, target: Node) -> void:
	var component := _get_or_create_status_component(target)
	if component:
		component.add_status_effect(effect, source)

func _apply_lifesteal(effect: Dictionary, source: Node, _target: Node) -> void:
	var source_stats := _get_stats(source)
	if source_stats == null:
		return
	var amount := int(effect.get("amount", 0))
	if amount <= 0:
		amount = int(float(effect.get("ratio", 0.0)) * float(source_stats.get_total_attack()))
	source_stats.heal(max(amount, 1))

func _apply_knockback(effect: Dictionary, source: Node, target: Node) -> void:
	if source == null or not (target is CharacterBody2D):
		return
	var force := float(effect.get("knockback_force", effect.get("knockback", 0.0)))
	if force <= 0.0:
		return
	var direction: Vector2 = (target.global_position - source.global_position).normalized()
	target.velocity = direction * force

func _get_stats(node: Node) -> StatsComponent:
	if node == null:
		return null
	var direct_stats = node.get("stats")
	if direct_stats is StatsComponent:
		return direct_stats
	return node.get_node_or_null("StatsComponent") as StatsComponent

func _get_or_create_status_component(target: Node) -> StatusEffectComponent:
	var component := target.get_node_or_null("StatusEffectComponent") as StatusEffectComponent
	if component:
		return component
	component = StatusEffectComponent.new()
	component.name = "StatusEffectComponent"
	target.add_child(component)
	return component
