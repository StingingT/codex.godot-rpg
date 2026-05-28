extends ItemData
class_name ArmorData

enum ArmorType { CHEST, HELMET, BOOTS, GLOVES }

@export var armor_type: ArmorType
@export var defense: int = 5
@export var vitality_bonus: int = 0
@export var hp_bonus: int = 0
