extends Resource
class_name SkillNode

enum NodeType { ATTACK, DEFENSE, UTILITY, ULTIMATE }
enum SkillCategory { RED, BLUE, GREEN, GOLD }

@export var node_id: String
@export var skill_name: String
@export var description: String
@export var node_type: NodeType
@export var category: SkillCategory
@export var tier: int = 0  # 0 = starting, higher = deeper in tree
@export var prerequisites: Array[String] = []  # node_ids that unlock this
@export var cost: int = 1  # Skill points required
@export var is_unlocked: bool = false
@export var icon: Texture2D

# Skill effects
@export var stat_bonuses: Dictionary = {}  # stat_name: bonus_value
@export var passive_effects: Array[String] = []
@export var active_skill: String = ""  # Reference to active skill if applicable

func get_category_color() -> Color:
	match category:
		SkillCategory.RED:
			return Color(0.9, 0.2, 0.2)  # Red - Attack
		SkillCategory.BLUE:
			return Color(0.2, 0.5, 0.9)  # Blue - Defense
		SkillCategory.GREEN:
			return Color(0.2, 0.8, 0.3)  # Green - Utility
		SkillCategory.GOLD:
			return Color(0.9, 0.7, 0.1)  # Gold - Ultimate
		_:
			return Color.WHITE

func get_category_name() -> String:
	match category:
		SkillCategory.RED: return "Attack"
		SkillCategory.BLUE: return "Defense"
		SkillCategory.GREEN: return "Utility"
		SkillCategory.GOLD: return "Ultimate"
		_: return "Unknown"
