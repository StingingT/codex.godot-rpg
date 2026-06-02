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

func remove_item_by_id(item_id: String, quantity: int = 1) -> bool:
	if not has_item_id(item_id, quantity):
		return false
	var remaining := quantity
	var removed_item: ItemData = null
	for slot in items:
		if slot.item == null or slot.item.item_id != item_id or slot.quantity <= 0:
			continue
		removed_item = slot.item
		var amount: int = min(int(slot.quantity), remaining)
		slot.quantity -= amount
		remaining -= amount
		if slot.quantity == 0:
			slot.item = null
		if remaining == 0:
			inventory_changed.emit()
			item_removed.emit(removed_item, quantity)
			return true
	return false

func has_item(item: ItemData, quantity: int = 1) -> bool:
	for slot in items:
		if slot.item == item and slot.quantity >= quantity:
			return true
	return false

func has_item_id(item_id: String, quantity: int = 1) -> bool:
	var total := 0
	for slot in items:
		if slot.item != null and slot.item.item_id == item_id:
			total += int(slot.quantity)
			if total >= quantity:
				return true
	return false

func get_item_by_id(item_id: String) -> ItemData:
	for slot in items:
		if slot.item != null and slot.item.item_id == item_id:
			return slot.item
	return _load_item_from_json(item_id)

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
	var item_db := {}
	for item_id in DataRegistry.items.keys():
		var item := DataRegistry.get_item_data(str(item_id))
		if item:
			item_db[item.item_id] = item
	return item_db

func load_item_data(item_id: String) -> ItemData:
	return DataRegistry.get_item_data(item_id)

func _load_item_from_json(item_id: String) -> ItemData:
	return DataRegistry.get_item_data(item_id)
