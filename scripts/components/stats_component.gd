extends Node
class_name StatsComponent

# Base stats (from class)
@export var max_hp: int = 100
@export var max_mana: int = 50
@export var attack: int = 10
@export var defense: int = 5
@export var speed: float = 80.0

# Current values
var current_hp: int
var current_mana: int

# Leveling
var level: int = 1
var current_xp: int = 0
var xp_to_next: int = 50
const MAX_LEVEL: int = 20

# Points
var attribute_points: int = 0      # AP - for distributing to core stats
var skill_points: int = 0          # SP - for unlocking skills

# Distributed Attribute Points
var distributed_ap = {
	"str": 0,  # Strength
	"dex": 0,  # Dexterity
	"vit": 0,  # Vitality
	"int": 0,  # Intelligence
	"lck": 0   # Luck
}

# Signals
signal hp_changed(new_hp: int, max_hp: int)
signal mana_changed(new_mana: int, max_mana: int)
signal xp_changed(current_xp: int, xp_to_next: int, level: int)
signal level_up(new_level: int, ap_gained: int, sp_gained: int)
signal ap_changed(new_ap: int)
signal sp_changed(new_sp: int)
signal stats_distributed()
signal died

func _ready():
	current_hp = max_hp
	current_mana = max_mana

# ========== Combat ==========

func take_damage(amount: int) -> void:
	var actual_damage = max(1, amount - get_total_defense())
	current_hp = max(0, current_hp - actual_damage)
	hp_changed.emit(current_hp, get_max_hp())
	
	if current_hp == 0:
		died.emit()

func heal(amount: int) -> void:
	current_hp = min(get_max_hp(), current_hp + amount)
	hp_changed.emit(current_hp, get_max_hp())

func use_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		mana_changed.emit(current_mana, get_max_mana())
		return true
	return false

func restore_mana(amount: int) -> void:
	current_mana = min(get_max_mana(), current_mana + amount)
	mana_changed.emit(current_mana, get_max_mana())

# ========== XP & Leveling ==========

func add_xp(amount: int) -> void:
	if level >= MAX_LEVEL:
		return
	
	current_xp += amount
	
	while current_xp >= xp_to_next and level < MAX_LEVEL:
		current_xp -= xp_to_next
		_level_up()
	
	xp_changed.emit(current_xp, xp_to_next, level)

func _level_up() -> void:
	level += 1
	
	# Flat test curve while core gameplay is being tuned.
	xp_to_next = 50
	
	# Award points
	var ap_gained = 5
	var sp_gained = 3
	
	# Bonus SP at milestone levels
	if level in [5, 10, 15, 20]:
		sp_gained += 1
	
	attribute_points += ap_gained
	skill_points += sp_gained
	
	# Full heal on level up
	current_hp = get_max_hp()
	current_mana = get_max_mana()
	
	hp_changed.emit(current_hp, get_max_hp())
	mana_changed.emit(current_mana, get_max_mana())
	ap_changed.emit(attribute_points)
	sp_changed.emit(skill_points)
	level_up.emit(level, ap_gained, sp_gained)

func get_xp_for_next_level() -> int:
	return xp_to_next

func is_max_level() -> bool:
	return level >= MAX_LEVEL

# ========== Attribute Point Distribution ==========

func distribute_ap(stat: String, amount: int = 1) -> bool:
	if attribute_points < amount:
		return false
	
	if not stat in distributed_ap:
		return false
	
	distributed_ap[stat] += amount
	attribute_points -= amount
	
	# Recalculate derived stats
	_recalculate_derived_stats()
	
	ap_changed.emit(attribute_points)
	stats_distributed.emit()
	
	return true

func can_distribute_ap(stat: String, amount: int = 1) -> bool:
	return attribute_points >= amount and stat in distributed_ap

func get_distributed_ap(stat: String) -> int:
	return distributed_ap.get(stat, 0)

func get_total_distributed_ap() -> int:
	var total = 0
	for val in distributed_ap.values():
		total += val
	return total

# ========== Skill Points ==========

func spend_skill_points(amount: int = 1) -> bool:
	if skill_points >= amount:
		skill_points -= amount
		sp_changed.emit(skill_points)
		return true
	return false

func add_skill_points(amount: int) -> void:
	skill_points += amount
	sp_changed.emit(skill_points)

# ========== Respec ==========

func respec_attributes(gold_cost: int) -> Dictionary:
	# Returns the result of respec attempt
	var result = {
		"success": false,
		"refunded_ap": 0,
		"cost": gold_cost
	}
	
	var total_distributed = get_total_distributed_ap()
	if total_distributed == 0:
		return result  # Nothing to respec
	
	# Refund all distributed AP
	for stat in distributed_ap:
		result["refunded_ap"] += distributed_ap[stat]
		distributed_ap[stat] = 0
	
	attribute_points += result["refunded_ap"]
	_recalculate_derived_stats()
	
	ap_changed.emit(attribute_points)
	stats_distributed.emit()
	
	result["success"] = true
	return result

func get_respec_cost() -> int:
	return level * 100  # 100 gold per level

# ========== Computed Total Stats ==========

func get_max_hp() -> int:
	return max_hp + (distributed_ap["vit"] * 5)  # +5 HP per VIT

func get_max_mana() -> int:
	return max_mana + (distributed_ap["int"] * 3)  # +3 Mana per INT

func get_total_attack() -> int:
	return attack + distributed_ap["str"]  # +1 Attack per STR

func get_total_defense() -> int:
	return defense + (distributed_ap["vit"] / 2)  # +1 Def per 2 VIT

func get_total_speed() -> float:
	return speed + (distributed_ap["dex"] * 0.5)  # +0.5 Speed per DEX

func get_attack_speed() -> float:
	return 1.0 + (distributed_ap["dex"] * 0.02)  # +2% attack speed per DEX

func get_crit_chance() -> float:
	return 0.05 + (distributed_ap["lck"] * 0.005)  # +0.5% crit per LCK (base 5%)

func get_crit_damage() -> float:
	return 1.5 + (distributed_ap["str"] * 0.02)  # +2% crit damage per STR (base 150%)

func get_hp_regen() -> float:
	return distributed_ap["vit"] * 0.1  # +0.1 HP/s per VIT

func get_drop_rate_bonus() -> float:
	return distributed_ap["lck"] * 0.02  # +2% drop rate per LCK

func get_skill_damage_bonus() -> float:
	return 1.0 + (distributed_ap["int"] * 0.02)  # +2% skill damage per INT

func _recalculate_derived_stats() -> void:
	# Clamp current HP/Mana to new max values
	current_hp = min(current_hp, get_max_hp())
	current_mana = min(current_mana, get_max_mana())
	hp_changed.emit(current_hp, get_max_hp())
	mana_changed.emit(current_mana, get_max_mana())

# ========== Save/Load ==========

func get_save_data() -> Dictionary:
	return {
		"max_hp": max_hp,
		"max_mana": max_mana,
		"attack": attack,
		"defense": defense,
		"speed": speed,
		"current_hp": current_hp,
		"current_mana": current_mana,
		"level": level,
		"current_xp": current_xp,
		"xp_to_next": xp_to_next,
		"attribute_points": attribute_points,
		"skill_points": skill_points,
		"distributed_ap": distributed_ap.duplicate()
	}

func load_save_data(data: Dictionary) -> void:
	max_hp = data.get("max_hp", 100)
	max_mana = data.get("max_mana", 50)
	attack = data.get("attack", 10)
	defense = data.get("defense", 5)
	speed = data.get("speed", 80.0)
	current_hp = data.get("current_hp", max_hp)
	current_mana = data.get("current_mana", max_mana)
	level = data.get("level", 1)
	current_xp = data.get("current_xp", 0)
	xp_to_next = min(int(data.get("xp_to_next", 50)), 50)
	attribute_points = data.get("attribute_points", 0)
	skill_points = data.get("skill_points", 0)
	
	var saved_ap = data.get("distributed_ap", {})
	for stat in distributed_ap:
		distributed_ap[stat] = saved_ap.get(stat, 0)
	
	_recalculate_derived_stats()
	xp_changed.emit(current_xp, xp_to_next, level)
	ap_changed.emit(attribute_points)
	sp_changed.emit(skill_points)

func emit_stat_signals() -> void:
	hp_changed.emit(current_hp, get_max_hp())
	mana_changed.emit(current_mana, get_max_mana())
	xp_changed.emit(current_xp, xp_to_next, level)
	ap_changed.emit(attribute_points)
	sp_changed.emit(skill_points)
