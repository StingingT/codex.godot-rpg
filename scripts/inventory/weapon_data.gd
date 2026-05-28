extends ItemData
class_name WeaponData

enum WeaponType { SWORD, BOW, STAFF }

@export var weapon_type: WeaponType
@export var damage: int = 10
@export var attack_speed: float = 1.0
@export var knockback: float = 100.0
