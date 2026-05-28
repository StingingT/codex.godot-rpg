extends Resource
class_name Equipment

signal equipment_changed

var weapon_slot: ItemData = null
var armor_slot: ItemData = null
var accessory_slot: ItemData = null

func equip(item: ItemData) -> ItemData:
	var old_item: ItemData = null
	
	match item.item_type:
		ItemData.ItemType.WEAPON:
			old_item = weapon_slot
			weapon_slot = item
		ItemData.ItemType.ARMOR:
			old_item = armor_slot
			armor_slot = item
	
	equipment_changed.emit()
	return old_item

func unequip(slot: String) -> ItemData:
	var old_item: ItemData = null
	
	match slot:
		"weapon":
			old_item = weapon_slot
			weapon_slot = null
		"armor":
			old_item = armor_slot
			armor_slot = null
		"accessory":
			old_item = accessory_slot
			accessory_slot = null
	
	equipment_changed.emit()
	return old_item

func get_total_attack_bonus() -> int:
	var bonus = 0
	if weapon_slot:
		bonus += weapon_slot.attack_bonus
	if armor_slot:
		bonus += armor_slot.attack_bonus
	return bonus

func get_total_defense_bonus() -> int:
	var bonus = 0
	if weapon_slot:
		bonus += weapon_slot.defense_bonus
	if armor_slot:
		bonus += armor_slot.defense_bonus
	return bonus

func get_total_hp_bonus() -> int:
	var bonus = 0
	if weapon_slot:
		bonus += weapon_slot.hp_bonus
	if armor_slot:
		bonus += armor_slot.hp_bonus
	return bonus
