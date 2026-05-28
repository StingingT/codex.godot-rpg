extends Node

signal ability_cast(caster: Node, ability_id: String)
signal ability_failed(caster: Node, ability_id: String, reason: String)

var cooldowns: Dictionary = {} # caster instance id -> ability id -> seconds remaining

func _process(delta: float) -> void:
	for caster_id in cooldowns.keys():
		var caster_cooldowns: Dictionary = cooldowns[caster_id]
		for ability_id in caster_cooldowns.keys():
			caster_cooldowns[ability_id] = max(float(caster_cooldowns[ability_id]) - delta, 0.0)

func can_cast(caster: Node, ability_id: String) -> bool:
	var ability := DataRegistry.get_ability(ability_id)
	if ability.is_empty():
		return false
	if get_cooldown_remaining(caster, ability_id) > 0.0:
		return false
	var mana_cost := int(ability.get("mana_cost", 0))
	var stats := _get_stats(caster)
	if stats and stats.current_mana < mana_cost:
		return false
	return true

func cast_ability(caster: Node, ability_id: String, target: Node = null, direction: Vector2 = Vector2.ZERO) -> bool:
	var ability := DataRegistry.get_ability(ability_id)
	if ability.is_empty():
		ability_failed.emit(caster, ability_id, "unknown_ability")
		return false
	if get_cooldown_remaining(caster, ability_id) > 0.0:
		ability_failed.emit(caster, ability_id, "cooldown")
		return false
	var stats := _get_stats(caster)
	var mana_cost := int(ability.get("mana_cost", 0))
	if stats and stats.current_mana < mana_cost:
		ability_failed.emit(caster, ability_id, "mana")
		return false
	if stats and mana_cost > 0:
		stats.use_mana(mana_cost)

	var cast_time := float(ability.get("cast_time_seconds", 0.0))
	if cast_time > 0.0:
		await get_tree().create_timer(cast_time).timeout

	_commit_ability(caster, target, direction, ability)
	_start_cooldown(caster, ability_id, float(ability.get("cooldown_seconds", 0.0)))
	ability_cast.emit(caster, ability_id)
	return true

func _commit_ability(caster: Node, target: Node, direction: Vector2, ability: Dictionary) -> void:
	var ability_type := str(ability.get("ability_type", "instant"))
	match ability_type:
		"instant", "self":
			var target_node := caster if target == null else target
			EffectRouter.apply_effects(ability.get("effects", []), caster, target_node)
		"projectile", "area", "hitbox":
			var scene_path := str(ability.get("scene", ""))
			if scene_path != "" and ResourceLoader.exists(scene_path):
				var effect_scene: Node2D = load(scene_path).instantiate()
				effect_scene.global_position = caster.global_position
				if effect_scene.has_method("setup"):
					effect_scene.setup(caster, ability, direction)
				get_tree().current_scene.add_child(effect_scene)
			elif target:
				EffectRouter.apply_effects(ability.get("effects", []), caster, target)
		_:
			if target:
				EffectRouter.apply_effects(ability.get("effects", []), caster, target)

func _start_cooldown(caster: Node, ability_id: String, seconds: float) -> void:
	var caster_id := caster.get_instance_id()
	if not cooldowns.has(caster_id):
		cooldowns[caster_id] = {}
	cooldowns[caster_id][ability_id] = seconds

func get_cooldown_remaining(caster: Node, ability_id: String) -> float:
	var caster_id := caster.get_instance_id()
	if not cooldowns.has(caster_id):
		return 0.0
	return float(cooldowns[caster_id].get(ability_id, 0.0))

func get_description(ability_id: String) -> String:
	var ability := DataRegistry.get_ability(ability_id)
	if ability.is_empty():
		return "Unknown ability."
	var lines := [str(ability.get("name", ability_id)), str(ability.get("description", ""))]
	var mana_cost := int(ability.get("mana_cost", 0))
	var cooldown := float(ability.get("cooldown_seconds", 0.0))
	if mana_cost > 0:
		lines.append("Mana Cost: %d" % mana_cost)
	if cooldown > 0.0:
		lines.append("Cooldown: %.1fs" % cooldown)
	return "\n".join(lines)

func _get_stats(node: Node) -> StatsComponent:
	if node == null:
		return null
	var direct_stats = node.get("stats")
	if direct_stats is StatsComponent:
		return direct_stats
	return node.get_node_or_null("StatsComponent") as StatsComponent
