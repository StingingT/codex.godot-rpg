extends Resource
class_name SkillTree

enum NodeType { PASSIVE, ACTIVE }
enum StatOp { ADD, MUL }

class SkillEffect:
	var stat_name: String
	var operation: StatOp
	var value: float
	
	func _init(s: String, op: StatOp, v: float):
		stat_name = s
		operation = op
		value = v

class TreeSkillNode:
	var id: String
	var name: String
	var description: String
	var node_type: NodeType
	var prerequisites = []  # Untyped array to avoid assignment issues
	var effects = []  # Untyped array to avoid assignment issues
	var skill_id: String = ""  # For active skills
	var metadata: Dictionary = {}
	var is_unlocked: bool = false
	var level_required: int = 1
	var cost: int = 1
	var position: Vector2 = Vector2.ZERO  # For UI placement
	
	func _init(p_id: String, p_name: String, p_desc: String, p_type: NodeType):
		id = p_id
		name = p_name
		description = p_desc
		node_type = p_type

# Skill tree data
var class_id: int = 0  # 0=Warrior, 1=Ranger, 2=Mage
var nodes: Dictionary = {}  # id -> TreeSkillNode

func _init(p_class_id: int = 0):
	class_id = p_class_id
	_build_tree()

func _build_tree():
	match class_id:
		0: _build_warrior()
		1: _build_ranger()
		2: _build_mage()

func _create_node(id: String, name: String, desc: String, type: NodeType, 
				  prereqs = [], effects = [],
				  level_req: int = 1, cost: int = 1, pos: Vector2 = Vector2.ZERO) -> TreeSkillNode:
	var node = TreeSkillNode.new(id, name, desc, type)
	if prereqs is Array:
		node.prerequisites = prereqs
	if effects is Array:
		node.effects = effects
	node.level_required = level_req
	node.cost = cost
	node.position = pos
	nodes[id] = node
	return node

func _eff(stat: String, op: StatOp, val: float) -> SkillEffect:
	return SkillEffect.new(stat, op, val)

# ============================================================
# WARRIOR SKILL TREE
# ============================================================
func _build_warrior():
	# RED PATH - Damage
	var prev = ""
	for i in range(10):
		var id = "WAR_R_S%02d" % (i + 1)
		var effects = _get_warrior_red_small_effects(i)
		var prereqs: Array[String] = []
		if prev != "":
			prereqs.append(prev)
		_create_node(id, _get_warrior_red_small_name(i), _get_warrior_red_small_desc(i), 
					 NodeType.PASSIVE, prereqs, effects, 
					 1 + i, 1, Vector2(100 + i * 80, 100))
		prev = id
	
	# Active skills
	_create_node("WAR_R_A01", "Whirlwind", "Spin attack hitting all nearby enemies", 
				 NodeType.ACTIVE, [prev], [], 5, 2, Vector2(900, 100))
	_create_node("WAR_R_A02", "Leap Strike", "Jump and slam down for AoE damage", 
				 NodeType.ACTIVE, ["WAR_R_A01"], [], 10, 2, Vector2(980, 100))
	
	# Large nodes
	_create_node("WAR_R_L01", "Cleave", "Attacks hit +1 extra target", 
				 NodeType.PASSIVE, ["WAR_R_A02"], [_eff("cleave", StatOp.ADD, 1)], 
				 15, 3, Vector2(1060, 100))
	_create_node("WAR_R_L02", "Blood Frenzy", "Gain damage stacks on hit", 
				 NodeType.PASSIVE, ["WAR_R_L01"], [_eff("damage_stack", StatOp.ADD, 0.02)], 
				 18, 3, Vector2(1140, 100))
	_create_node("WAR_R_L03", "Vampiric", "Heal on kill", 
				 NodeType.PASSIVE, ["WAR_R_L02"], [_eff("life_steal", StatOp.ADD, 0.05)], 
				 20, 3, Vector2(1220, 100))
	
	# Capstone
	_create_node("WAR_R_C", "Avatar of War", "+20% damage, +10% crit damage", 
				 NodeType.PASSIVE, ["WAR_R_L03"], 
				 [_eff("damage", StatOp.MUL, 0.20), _eff("crit_damage", StatOp.MUL, 0.10)], 
				 25, 5, Vector2(1300, 100))
	
	# BLUE PATH - Defense
	prev = ""
	for i in range(10):
		var id = "WAR_B_S%02d" % (i + 1)
		var effects = _get_warrior_blue_small_effects(i)
		var prereqs: Array[String] = []
		if prev != "":
			prereqs.append(prev)
		_create_node(id, _get_warrior_blue_small_name(i), _get_warrior_blue_small_desc(i), 
					 NodeType.PASSIVE, prereqs, effects, 
					 1 + i, 1, Vector2(100 + i * 80, 300))
		prev = id
	
	# Active skills
	_create_node("WAR_B_A01", "Shield Bash", "Stun enemy", 
				 NodeType.ACTIVE, [prev], [], 5, 2, Vector2(900, 300))
	_create_node("WAR_B_A02", "Guard Stance", "40% damage reduction", 
				 NodeType.ACTIVE, ["WAR_B_A01"], [], 10, 2, Vector2(980, 300))
	
	# Large nodes
	_create_node("WAR_B_L01", "Reactive Shield", "Gain shield when hit", 
				 NodeType.PASSIVE, ["WAR_B_A02"], [_eff("reactive_shield", StatOp.ADD, 1)], 
				 15, 3, Vector2(1060, 300))
	_create_node("WAR_B_L02", "Thorns", "Reflect damage", 
				 NodeType.PASSIVE, ["WAR_B_L01"], [_eff("thorns", StatOp.ADD, 0.15)], 
				 18, 3, Vector2(1140, 300))
	_create_node("WAR_B_L03", "Unyielding", "Flat damage reduction", 
				 NodeType.PASSIVE, ["WAR_B_L02"], [_eff("flat_dr", StatOp.ADD, 5)], 
				 20, 3, Vector2(1220, 300))
	
	# Capstone
	_create_node("WAR_B_C", "Immortal Guardian", "Survive lethal hit once", 
				 NodeType.PASSIVE, ["WAR_B_L03"], [_eff("cheat_death", StatOp.ADD, 1)], 
				 25, 5, Vector2(1300, 300))
	
	# GREEN PATH - Utility
	prev = ""
	for i in range(10):
		var id = "WAR_G_S%02d" % (i + 1)
		var effects = _get_warrior_green_small_effects(i)
		var prereqs: Array[String] = []
		if prev != "":
			prereqs.append(prev)
		_create_node(id, _get_warrior_green_small_name(i), _get_warrior_green_small_desc(i), 
					 NodeType.PASSIVE, prereqs, effects, 
					 1 + i, 1, Vector2(100 + i * 80, 500))
		prev = id
	
	# Large nodes (no actives for green)
	_create_node("WAR_G_L01", "Veteran", "Cooldown reduction", 
				 NodeType.PASSIVE, [prev], [_eff("cdr", StatOp.ADD, 0.15)], 
				 15, 3, Vector2(900, 500))
	_create_node("WAR_G_L02", "Loot Magnet", "Increased pickup radius", 
				 NodeType.PASSIVE, ["WAR_G_L01"], [_eff("pickup_radius", StatOp.MUL, 0.25)], 
				 18, 3, Vector2(980, 500))
	_create_node("WAR_G_L03", "Second Wind", "Potion grants shield", 
				 NodeType.PASSIVE, ["WAR_G_L02"], [_eff("potion_shield", StatOp.ADD, 1)], 
				 20, 3, Vector2(1060, 500))
	
	# Capstone
	_create_node("WAR_G_C", "Warlord", "+50% buff duration", 
				 NodeType.PASSIVE, ["WAR_G_L03"], [_eff("buff_duration", StatOp.MUL, 0.50)], 
				 25, 5, Vector2(1140, 500))
	
	# Cross-path prerequisites
	# Red requires some Blue progress
	nodes["WAR_R_L01"].prerequisites.append("WAR_B_S05")
	# Blue requires some Green progress
	nodes["WAR_B_L02"].prerequisites.append("WAR_G_S05")

# Helper functions for warrior skills
func _get_warrior_red_small_effects(index: int) -> Array[SkillEffect]:
	match index:
		0: return [_eff("damage", StatOp.MUL, 0.03)]
		1: return [_eff("crit_chance", StatOp.ADD, 0.03)]
		2: return [_eff("crit_damage", StatOp.MUL, 0.06)]
		3: return [_eff("armor_pen", StatOp.ADD, 0.04)]
		4: return [_eff("bleed_chance", StatOp.ADD, 0.10)]
		5: return [_eff("execute_damage", StatOp.MUL, 0.06)]
		6: return [_eff("nearby_damage", StatOp.ADD, 0.02)]
		7: return [_eff("melee_damage", StatOp.MUL, 0.05)]
		8: return [_eff("high_hp_damage", StatOp.MUL, 0.03)]
		9: return [_eff("rage_gain", StatOp.MUL, 0.10)]
	return []

func _get_warrior_red_small_name(index: int) -> String:
	var names = ["Sharpened Steel", "Brutal Strikes", "Heavy Hands", "Armor Break", 
				 "Bleeding Edge", "Executioner", "Relentless", "Weapon Mastery", 
				 "Battle Focus", "Rage Feed"]
	return names[index]

func _get_warrior_red_small_desc(index: int) -> String:
	var descs = ["+3% Damage", "+3% Crit Chance", "+6% Crit Damage", "+4% Armor Pen", 
				 "+10% Bleed", "Execute Bonus", "Nearby Damage", "Melee Damage", 
				 "High HP Damage", "Rage Gain"]
	return descs[index]

func _get_warrior_blue_small_effects(index: int) -> Array[SkillEffect]:
	match index:
		0: return [_eff("max_hp", StatOp.MUL, 0.04)]
		1: return [_eff("defense", StatOp.MUL, 0.04)]
		2: return [_eff("block_chance", StatOp.ADD, 0.03)]
		3: return [_eff("stationary_dr", StatOp.ADD, 0.03)]
		4: return [_eff("low_hp_dr", StatOp.ADD, 0.04)]
		5: return [_eff("healing_received", StatOp.MUL, 0.10)]
		6: return [_eff("knockback_resist", StatOp.ADD, 0.10)]
		7: return [_eff("stamina", StatOp.MUL, 0.06)]
		8: return [_eff("shield_defense", StatOp.MUL, 0.08)]
		9: return [_eff("post_hit_regen", StatOp.MUL, 0.10)]
	return []

func _get_warrior_blue_small_name(index: int) -> String:
	var names = ["Iron Skin", "Reinforced Armor", "Block Training", "Steadfast", 
				 "Pain Tolerance", "Thick Blood", "Guarded Steps", "Endurance", 
				 "Shield Familiarity", "Recovery Window"]
	return names[index]

func _get_warrior_blue_small_desc(index: int) -> String:
	var descs = ["+4% HP", "+4% Defense", "Block Chance", "Stationary DR", 
				 "Low HP DR", "Healing", "Knockback Resist", "Stamina", 
				 "Shield Defense", "Post-Hit Regen"]
	return descs[index]

func _get_warrior_green_small_effects(index: int) -> Array[SkillEffect]:
	match index:
		0: return [_eff("xp_gain", StatOp.MUL, 0.05)]
		1: return [_eff("item_drop", StatOp.MUL, 0.05)]
		2: return [_eff("gold_gain", StatOp.MUL, 0.06)]
		3: return [_eff("pickup_radius", StatOp.MUL, 0.10)]
		4: return [_eff("potion_power", StatOp.MUL, 0.10)]
		5: return [_eff("inventory_slots", StatOp.ADD, 1)]
		6: return [_eff("cooldown_reduction", StatOp.ADD, 0.03)]
		7: return [_eff("move_speed", StatOp.MUL, 0.04)]
		8: return [_eff("rare_drop", StatOp.ADD, 0.03)]
		9: return [_eff("sell_value", StatOp.MUL, 0.08)]
	return []

func _get_warrior_green_small_name(index: int) -> String:
	var names = ["Efficient Training", "War Spoils", "Coin Sense", "Quick Hands", 
				 "Field Rations", "Pack Discipline", "Battle Tempo", "Pathfinder", 
				 "Lucky Find", "Merchant's Eye"]
	return names[index]

func _get_warrior_green_small_desc(index: int) -> String:
	var descs = ["+5% XP", "+5% Drops", "+6% Gold", "Pickup Radius", 
				 "Potion Power", "Inventory", "Cooldowns", "Move Speed", 
				 "Rare Drops", "Sell Value"]
	return descs[index]

# ============================================================
# RANGER SKILL TREE (simplified - similar structure)
# ============================================================
func _build_ranger():
	# Similar structure to warrior but with ranger-specific skills
	# RED - Damage/Precision
	# BLUE - Speed/Mobility  
	# GREEN - Utility/Traps
	pass

# ============================================================
# MAGE SKILL TREE (simplified)
# ============================================================
func _build_mage():
	# RED - Fire damage
	# BLUE - Lightning/CC
	# GREEN - Buffs/Utility
	pass

# ============================================================
# PUBLIC API
# ============================================================
func can_unlock(node_id: String, player_level: int, available_points: int) -> bool:
	if not nodes.has(node_id):
		return false
	
	var node = nodes[node_id]
	
	# Already unlocked
	if node.is_unlocked:
		return false
	
	# Check level requirement
	if player_level < node.level_required:
		return false
	
	# Check skill points
	if available_points < node.cost:
		return false
	
	# Check prerequisites
	for prereq_id in node.prerequisites:
		if not nodes.has(prereq_id) or not nodes[prereq_id].is_unlocked:
			return false
	
	return true

func unlock_node(node_id: String) -> bool:
	if not nodes.has(node_id):
		return false
	
	nodes[node_id].is_unlocked = true
	return true

func get_unlocked_effects() -> Array[SkillEffect]:
	var all_effects: Array[SkillEffect] = []
	for node in nodes.values():
		if node.is_unlocked:
			all_effects.append_array(node.effects)
	return all_effects

func get_total_spent_points() -> int:
	var total = 0
	for node in nodes.values():
		if node.is_unlocked:
			total += node.cost
	return total

func get_save_data() -> Dictionary:
	var unlocked = []
	for node_id in nodes.keys():
		if nodes[node_id].is_unlocked:
			unlocked.append(node_id)
	return {"unlocked_nodes": unlocked}

func load_save_data(data: Dictionary) -> void:
	if data.has("unlocked_nodes"):
		for node_id in data.unlocked_nodes:
			if nodes.has(node_id):
				nodes[node_id].is_unlocked = true
