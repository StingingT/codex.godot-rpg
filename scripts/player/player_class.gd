extends Resource
class_name PlayerClass

enum ClassType { WARRIOR, RANGER, MAGE }

@export var player_class_name: String
@export var class_type: ClassType
@export var description: String
@export var base_stats: Dictionary = {
	"max_hp": 100,
	"max_mana": 50,
	"attack": 10,
	"defense": 5,
	"speed": 80.0
}
@export var stat_growth: Dictionary = {
	"hp_per_level": 10,
	"mana_per_level": 5,
	"attack_per_level": 2,
	"defense_per_level": 1
}
@export var starting_skills: Array = []
@export var skill_tree: SkillTree

func get_starting_equipment() -> Array[String]:
	match class_type:
		ClassType.WARRIOR:
			return ["wooden_sword", "leather_armor"]
		ClassType.RANGER:
			return ["short_bow", "leather_armor"]
		ClassType.MAGE:
			return ["apprentice_staff", "cloth_robe"]
		_:
			return []
