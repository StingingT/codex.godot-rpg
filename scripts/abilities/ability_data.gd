extends Resource
class_name AbilityData

@export var ability_id: String = ""
@export var ability_name: String = ""
@export_multiline var description: String = ""
@export var mana_cost: int = 0
@export var cooldown_seconds: float = 0.0
@export var cast_time_seconds: float = 0.0
@export var ability_type: String = "instant"
@export var scene: PackedScene
@export var effects: Array[Dictionary] = []

var current_cooldown_seconds: float = 0.0

func can_cast(caster: Node) -> bool:
	if current_cooldown_seconds > 0.0:
		return false
	var stats := caster.get_node_or_null("StatsComponent") as StatsComponent
	return stats == null or stats.current_mana >= mana_cost

func tick_cooldown(delta: float) -> void:
	current_cooldown_seconds = max(current_cooldown_seconds - delta, 0.0)

func get_description() -> String:
	var lines := [ability_name, description]
	if mana_cost > 0:
		lines.append("Mana Cost: %d" % mana_cost)
	if cooldown_seconds > 0.0:
		lines.append("Cooldown: %.1fs" % cooldown_seconds)
	return "\n".join(lines)
