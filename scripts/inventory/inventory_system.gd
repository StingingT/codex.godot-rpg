extends Resource
class_name Inventory

signal inventory_changed
signal item_added(item: ItemData, quantity: int)
signal item_removed(item: ItemData, quantity: int)
signal gold_changed(new_amount: int)
signal equipment_changed(slot: String, item: ItemData)

const MAX_SLOTS = 30

var gold: int = 0
var items: Array[Dictionary] = []  # [{item: ItemData, quantity: int}]
var equipment: Dictionary = {
	"weapon": null,
	"armor": null,
	"helmet": null,
	"accessory": null
}

func _init():
	# Initialize empty slots
	for i in range(MAX_SLOTS):
		items.append({"item": null, "quantity": 0})

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func remove_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

func add_item(item: ItemData, quantity: int = 1) -> bool:
	# Try to stack with existing
	for slot in items:
		if slot.item != null and slot.item.item_id == item.item_id and slot.quantity > 0:
			if item.stackable:
				slot.quantity += quantity
				inventory_changed.emit()
				item_added.emit(item, quantity)
				return true
	
	# Find empty slot
	for slot in items:
		if slot.item == null or slot.quantity == 0:
			slot.item = item
			slot.quantity = quantity
			inventory_changed.emit()
			item_added.emit(item, quantity)
			return true
	
	return false  # Inventory full

func remove_item(item: ItemData, quantity: int = 1) -> bool:
	for slot in items:
		if slot.item == item and slot.quantity >= quantity:
			slot.quantity -= quantity
			if slot.quantity == 0:
				slot.item = null
			inventory_changed.emit()
			item_removed.emit(item, quantity)
			return true
	return false

func has_item(item: ItemData, quantity: int = 1) -> bool:
	for slot in items:
		if slot.item == item and slot.quantity >= quantity:
			return true
	return false

func equip_item(item: ItemData, slot_type: String) -> bool:
	if not equipment.has(slot_type):
		return false
	
	# Unequip current item if any
	if equipment[slot_type] != null:
		unequip_item(slot_type)
	
	# Remove from inventory
	if remove_item(item, 1):
		equipment[slot_type] = item
		equipment_changed.emit(slot_type, item)
		return true
	return false

func unequip_item(slot_type: String) -> bool:
	if not equipment.has(slot_type):
		return false
	
	var item = equipment[slot_type]
	if item == null:
		return false
	
	# Add back to inventory
	if add_item(item, 1):
		equipment[slot_type] = null
		equipment_changed.emit(slot_type, null)
		return true
	return false

func get_equipped_weapon() -> WeaponData:
	var weapon = equipment.get("weapon")
	if weapon is WeaponData:
		return weapon
	return null

func get_save_data() -> Dictionary:
	var item_data = []
	for slot in items:
		if slot.item != null:
			item_data.append({
				"item_id": slot.item.item_id if slot.item.has_method("get") else "",
				"quantity": slot.quantity
			})
	
	var equip_data = {}
	for slot in equipment:
		if equipment[slot] != null:
			equip_data[slot] = equipment[slot].item_id
	
	return {
		"gold": gold,
		"items": item_data,
		"equipment": equip_data
	}

func load_save_data(data: Dictionary) -> void:
	gold = data.get("gold", 0)
	
	# Clear items
	for slot in items:
		slot.item = null
		slot.quantity = 0
	
	# Load items - need to resolve item IDs to actual items
	var item_dict = _load_item_database()
	var saved_items = data.get("items", [])
	for i in range(min(saved_items.size(), items.size())):
		var item_data = saved_items[i]
		var item_id = item_data.get("item_id", "")
		if item_dict.has(item_id):
			items[i].item = item_dict[item_id]
			items[i].quantity = item_data.get("quantity", 1)
	
	# Load equipment
	var equip_data = data.get("equipment", {})
	for slot_name in equip_data:
		var item_id = equip_data[slot_name]
		if item_dict.has(item_id):
			equipment[slot_name] = item_dict[item_id]
	
	inventory_changed.emit()
	gold_changed.emit(gold)

func _load_item_database() -> Dictionary:
	# Load all items from data folder
	var item_db = {}
	var dir = DirAccess.open("res://data/items/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var item_id = file_name.replace(".json", "")
				var item = _load_item_from_json(item_id)
				if item:
					item_db[item_id] = item
			file_name = dir.get_next()
	return item_db

func _load_item_from_json(item_id: String) -> ItemData:
	var file_path = "res://data/items/" + item_id + ".json"
	if not FileAccess.file_exists(file_path):
		return null
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		return null
	
	var data = json.data
	var item_type = data.get("item_type", 0)
	
	var item: ItemData
	
	# Check if it's a weapon (item_type 0 or has weapon_type)
	if item_type == 0 or data.has("weapon_type"):
		var weapon = WeaponData.new()
		weapon.weapon_type = data.get("weapon_type", 0)
		weapon.damage = data.get("damage", 10)
		weapon.attack_speed = data.get("attack_speed", 1.0)
		weapon.knockback = data.get("knockback", 100.0)
		item = weapon
	# Check if it's armor (item_type 1 or has armor_type)
	elif item_type == 1 or data.has("armor_type"):
		var armor = ArmorData.new()
		armor.armor_type = data.get("armor_type", 0)
		armor.defense = data.get("defense", 5)
		armor.vitality_bonus = data.get("vitality_bonus", 0)
		armor.hp_bonus = data.get("hp_bonus", 0)
		item = armor
	else:
		item = ItemData.new()
	
	# Common properties
	item.item_id = data.get("item_id", item_id)
	item.item_name = data.get("item_name", "Unknown")
	item.description = data.get("description", "")
	item.item_type = item_type
	item.required_level = data.get("required_level", 1)
	item.buy_price = data.get("buy_price", 100)
	item.sell_price = data.get("sell_price", 50)
	item.stackable = data.get("stackable", false)
	item.max_stack = data.get("max_stack", 1)
	item.attack_bonus = data.get("attack_bonus", 0)
	item.heal_amount = data.get("heal_amount", 0)
	item.mana_amount = data.get("mana_amount", 0)
	
	# Try to load sprite
	var sprite_path = "res://assets/sprites/weapons/" + item_id + ".png"
	if ResourceLoader.exists(sprite_path):
		item.sprite = load(sprite_path)
	
	return item
