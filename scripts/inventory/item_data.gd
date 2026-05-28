extends Resource
class_name ItemData

enum ItemType { WEAPON, ARMOR, CONSUMABLE, MATERIAL, QUEST }

@export var item_id: String
@export var item_name: String
@export var description: String
@export var item_type: ItemType
@export var icon: Texture2D
@export var sprite: Texture2D
@export var stackable: bool = false
@export var max_stack: int = 1
@export var buy_price: int = 0
@export var sell_price: int = 0
@export var required_level: int = 1
