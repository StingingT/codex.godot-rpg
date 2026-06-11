extends Resource
class_name ItemData

enum ItemType { WEAPON, ARMOR, CONSUMABLE, MATERIAL, QUEST }

@export var schema_version: int = 1
@export var item_id: String
@export var item_name: String
@export var description: String
@export var item_type: ItemType
@export var category: String = "material"
@export var slot: String = ""
@export var material_tier: String = ""
@export var allowed_classes: Array[String] = []
@export var icon: Texture2D
@export var sprite: Texture2D
@export var stackable: bool = false
@export var max_stack: int = 1
@export var buy_price: int = 0
@export var sell_price: int = 0
@export var required_level: int = 1
@export var base_stats: Dictionary = {}
@export var standard_roll: Dictionary = {}
@export var affix_pool: String = ""
@export var fixed_rarity: String = ""
@export var attack_bonus: int = 0
@export var heal_amount: int = 0
@export var mana_amount: int = 0
