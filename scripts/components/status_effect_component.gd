extends Node
class_name StatusEffectComponent

signal status_added(status_id: String)
signal status_removed(status_id: String)

var active_effects: Array[Dictionary] = []
var stats: StatsComponent

func _ready() -> void:
	stats = get_parent().get_node_or_null("StatsComponent") as StatsComponent

func _process(delta: float) -> void:
	if active_effects.is_empty():
		return
	var remaining: Array[Dictionary] = []
	for effect in active_effects:
		effect["remaining_seconds"] = float(effect.get("remaining_seconds", 0.0)) - delta
		effect["tick_timer"] = float(effect.get("tick_timer", 0.0)) - delta
		if float(effect.get("tick_timer", 0.0)) <= 0.0:
			_process_tick(effect)
			effect["tick_timer"] = float(effect.get("tick_interval", 1.0))
		if float(effect.get("remaining_seconds", 0.0)) > 0.0:
			remaining.append(effect)
		else:
			_on_effect_expired(effect)
	active_effects = remaining

func add_status_effect(effect: Dictionary, source: Node = null) -> void:
	var status := effect.duplicate(true)
	status["source"] = source
	status["status_id"] = str(effect.get("id", effect.get("type", "status")))
	status["remaining_seconds"] = float(effect.get("duration_seconds", 1.0))
	status["tick_interval"] = float(effect.get("tick_interval", 1.0))
	status["tick_timer"] = 0.0
	active_effects.append(status)
	_apply_instant_status_change(status, true)
	status_added.emit(status["status_id"])

func _process_tick(effect: Dictionary) -> void:
	if stats == null:
		return
	match str(effect.get("type", "")):
		"dot":
			stats.take_damage(int(effect.get("amount", 0)))
		"hot":
			stats.heal(int(effect.get("amount", 0)))

func _apply_instant_status_change(effect: Dictionary, adding: bool) -> void:
	if stats == null:
		return
	var sign := 1 if adding else -1
	var amount := int(effect.get("amount", 0)) * sign
	var stat := str(effect.get("stat", ""))
	match str(effect.get("type", "")):
		"buff":
			_modify_stat(stat, amount)
		"debuff", "slow":
			_modify_stat(stat, -amount)
		"shield":
			# Shield storage can become damage absorption later; for now it is tracked as a timed status.
			pass
		"stun":
			get_parent().set_meta("is_stunned", adding)

func _modify_stat(stat: String, amount: int) -> void:
	match stat:
		"attack": stats.attack += amount
		"defense": stats.defense += amount
		"max_hp": stats.max_hp += amount
		"max_mana": stats.max_mana += amount
		"speed", "move_speed": stats.speed += float(amount)

func _on_effect_expired(effect: Dictionary) -> void:
	_apply_instant_status_change(effect, false)
	status_removed.emit(str(effect.get("status_id", "status")))

func clear_all() -> void:
	for effect in active_effects:
		_on_effect_expired(effect)
	active_effects.clear()
