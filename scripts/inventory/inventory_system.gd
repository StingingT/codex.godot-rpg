extends Resource
class_name Inventory

signal inventory_changed
signal item_added(item: ItemData, quantity: int)
signal item_removed(item: ItemData, quantity: int)
signal gold_changed(new_amount: int)
signal equipment_changed(slot: String, item: ItemData)

const INVENTORY_SCHEMA_VERSION := 2
const TAB_EQUIPMENT := "equipment"
const TAB_CONSUMABLES := "consumables"
const TAB_MATERIALS := "materials"
const TAB_ORDER: Array[String] = [TAB_EQUIPMENT, TAB_CONSUMABLES, TAB_MATERIALS]
const SLOTS_PER_TAB := 24
const MAX_SLOTS := 72

var gold: int = 0
var items: Array[Dictionary] = []
var equipment: Dictionary = {
	"weapon": null,
	"armor": null,
	"helmet": null,
	"accessory": null
}
var last_load_error: String = ""
var _suppress_signals: bool = false

func _init() -> void:
	_initialize_empty_slots()

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	if not _suppress_signals:
		gold_changed.emit(gold)

func remove_gold(amount: int) -> bool:
	if amount < 0 or gold < amount:
		return false
	gold -= amount
	if not _suppress_signals:
		gold_changed.emit(gold)
	return true

func add_item(item: ItemData, quantity: int = 1) -> bool:
	var result := add_item_detailed(item, quantity)
	return int(result.get("remaining", quantity)) == 0

func add_item_detailed(item: ItemData, quantity: int, instance_data: Dictionary = {}) -> Dictionary:
	return _add_item_to_slots(items, item, quantity, instance_data, true, true)

func preview_add_item(item: ItemData, quantity: int, instance_data: Dictionary = {}) -> Dictionary:
	var preview_slots := _duplicate_slots(items)
	return _add_item_to_slots(preview_slots, item, quantity, instance_data, true, false)

func remove_item(item: ItemData, quantity: int = 1) -> bool:
	if item == null:
		return false
	return remove_item_by_id(item.item_id, quantity)

func remove_item_by_id(item_id: String, quantity: int = 1) -> bool:
	var result := remove_item_detailed(item_id, quantity)
	return int(result.get("remaining", quantity)) == 0

func remove_item_detailed(item_id: String, quantity: int = 1) -> Dictionary:
	if item_id == "" or quantity <= 0:
		return _remove_result(0, max(quantity, 0), false, "invalid_request")
	if not has_item_id(item_id, quantity):
		return _remove_result(0, quantity, false, "insufficient_quantity")

	var remaining := quantity
	var removed_item: ItemData = null
	for slot in items:
		var slot_item := slot.get("item") as ItemData
		if slot_item == null or slot_item.item_id != item_id or int(slot.get("quantity", 0)) <= 0:
			continue
		if removed_item == null:
			removed_item = slot_item
		var amount: int = min(int(slot.get("quantity", 0)), remaining)
		slot["quantity"] = int(slot.get("quantity", 0)) - amount
		remaining -= amount
		if int(slot.get("quantity", 0)) == 0:
			_clear_slot(slot)
		if remaining == 0:
			break

	if not _suppress_signals:
		inventory_changed.emit()
		item_removed.emit(removed_item, quantity)
	return _remove_result(quantity, 0, true, "")

func has_item(item: ItemData, quantity: int = 1) -> bool:
	return item != null and has_item_id(item.item_id, quantity)

func has_item_id(item_id: String, quantity: int = 1) -> bool:
	return get_total_quantity(item_id) >= quantity

func get_total_quantity(item_id: String) -> int:
	var total := 0
	for slot in items:
		var slot_item := slot.get("item") as ItemData
		if slot_item != null and slot_item.item_id == item_id:
			total += int(slot.get("quantity", 0))
	return total

func get_item_by_id(item_id: String) -> ItemData:
	for slot in items:
		var slot_item := slot.get("item") as ItemData
		if slot_item != null and slot_item.item_id == item_id:
			return slot_item
	return load_item_data(item_id)

func get_tab_slots(tab_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not TAB_ORDER.has(tab_id):
		return result
	for slot in items:
		if str(slot.get("tab", "")) == tab_id:
			result.append(slot)
	return result

func get_occupied_slots(tab_id: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in items:
		if tab_id != "" and str(slot.get("tab", "")) != tab_id:
			continue
		if slot.get("item") != null and int(slot.get("quantity", 0)) > 0:
			result.append(slot)
	return result

func get_tab_for_item(item: ItemData) -> String:
	if item == null:
		return TAB_MATERIALS
	if item.slot != "" or item.category == "equipment":
		return TAB_EQUIPMENT
	if item.category == "consumable" or item.item_type == ItemData.ItemType.CONSUMABLE:
		return TAB_CONSUMABLES
	if item.category not in ["material", "quest"]:
		push_warning("Unknown inventory category '%s' for %s; routing to materials." % [item.category, item.item_id])
	return TAB_MATERIALS

func equip_item(item: ItemData, slot_type: String) -> bool:
	if item == null or not equipment.has(slot_type):
		return false

	if equipment[slot_type] != null:
		unequip_item(slot_type)

	if remove_item(item, 1):
		equipment[slot_type] = item
		equipment_changed.emit(slot_type, item)
		return true
	return false

func unequip_item(slot_type: String) -> bool:
	if not equipment.has(slot_type):
		return false

	var item := equipment[slot_type] as ItemData
	if item == null:
		return false

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
	var item_data: Array[Dictionary] = []
	for slot in items:
		var item := slot.get("item") as ItemData
		if item == null or int(slot.get("quantity", 0)) <= 0:
			continue
		item_data.append({
			"tab": str(slot.get("tab", get_tab_for_item(item))),
			"item_id": item.item_id,
			"quantity": int(slot.get("quantity", 0)),
			"instance": slot.get("instance")
		})

	var equip_data: Dictionary = {}
	for slot_id in equipment:
		var item := equipment[slot_id] as ItemData
		if item != null:
			equip_data[slot_id] = item.item_id

	return {
		"inventory_schema_version": INVENTORY_SCHEMA_VERSION,
		"gold": gold,
		"items": item_data,
		"equipment": equip_data
	}

func load_save_data(data: Dictionary, report_errors: bool = true) -> bool:
	last_load_error = ""
	var previous_gold := gold
	var previous_items := _duplicate_slots(items)
	var previous_equipment := equipment.duplicate()
	var target_gold := int(data.get("gold", 0))
	var item_database := _load_item_database()
	var saved_items = data.get("items", [])
	var saved_equipment = data.get("equipment", {})

	if typeof(saved_items) != TYPE_ARRAY or typeof(saved_equipment) != TYPE_DICTIONARY:
		last_load_error = "Inventory save structure is invalid."
		return false

	_suppress_signals = true
	_initialize_empty_slots()
	for slot_id in equipment:
		equipment[slot_id] = null

	var success := true
	for saved_entry in saved_items:
		if typeof(saved_entry) != TYPE_DICTIONARY:
			last_load_error = "Inventory save contains a non-dictionary item entry."
			success = false
			break
		var item_id := str(saved_entry.get("item_id", ""))
		var quantity := int(saved_entry.get("quantity", 1))
		if not item_database.has(item_id):
			last_load_error = "Missing item definition during inventory migration: %s" % item_id
			success = false
			break
		var instance_data: Dictionary = {}
		var raw_instance = saved_entry.get("instance")
		if typeof(raw_instance) == TYPE_DICTIONARY:
			instance_data = raw_instance.duplicate(true)
		var add_result := _add_item_to_slots(
			items,
			item_database[item_id],
			quantity,
			instance_data,
			false,
			false
		)
		if int(add_result.get("remaining", quantity)) > 0:
			last_load_error = "Inventory migration overflow for %s: %d item(s) did not fit." % [
				item_id,
				int(add_result.get("remaining", quantity))
			]
			success = false
			break

	if success:
		for slot_id in saved_equipment:
			var item_id := str(saved_equipment[slot_id])
			if not equipment.has(slot_id):
				last_load_error = "Unknown equipment slot in save: %s" % slot_id
				success = false
				break
			if not item_database.has(item_id):
				last_load_error = "Missing equipped item definition during migration: %s" % item_id
				success = false
				break
			equipment[slot_id] = item_database[item_id]

	if not success:
		gold = previous_gold
		items = previous_items
		equipment = previous_equipment
		_suppress_signals = false
		if report_errors:
			push_error(last_load_error)
		return false

	gold = target_gold
	_suppress_signals = false
	inventory_changed.emit()
	gold_changed.emit(gold)
	return true

func load_item_data(item_id: String) -> ItemData:
	var registry := _get_autoload("DataRegistry")
	return registry.call("get_item_data", item_id) as ItemData if registry != null else null

func _add_item_to_slots(
	target_slots: Array[Dictionary],
	item: ItemData,
	quantity: int,
	instance_data: Dictionary,
	respect_quest_limit: bool,
	emit_signals: bool
) -> Dictionary:
	if item == null or quantity <= 0:
		return _add_result(0, max(quantity, 0), false, "invalid_request")
	if not instance_data.is_empty() and quantity != 1:
		return _add_result(0, quantity, false, "instance_quantity_must_be_one")

	var allowed_quantity := quantity
	if respect_quest_limit and item.item_type == ItemData.ItemType.QUEST:
		allowed_quantity = min(quantity, _get_quest_item_remaining(item.item_id))
	var remaining_to_place := allowed_quantity
	var tab_id := get_tab_for_item(item)
	var max_stack: int = max(1, item.max_stack if item.stackable and instance_data.is_empty() else 1)

	if max_stack > 1:
		for slot in target_slots:
			if remaining_to_place == 0:
				break
			var slot_item := slot.get("item") as ItemData
			if str(slot.get("tab", "")) != tab_id \
					or slot_item == null \
					or slot_item.item_id != item.item_id \
					or slot.get("instance") != null:
				continue
			var space: int = max_stack - int(slot.get("quantity", 0))
			if space <= 0:
				continue
			var amount: int = min(space, remaining_to_place)
			slot["quantity"] = int(slot.get("quantity", 0)) + amount
			remaining_to_place -= amount

	for slot in target_slots:
		if remaining_to_place == 0:
			break
		if str(slot.get("tab", "")) != tab_id or slot.get("item") != null:
			continue
		var amount: int = min(max_stack, remaining_to_place)
		slot["item"] = item
		slot["quantity"] = amount
		slot["instance"] = instance_data.duplicate(true) if not instance_data.is_empty() else null
		remaining_to_place -= amount

	var accepted := allowed_quantity - remaining_to_place
	var remaining := quantity - accepted
	var reason := ""
	if remaining_to_place > 0:
		reason = "inventory_full"
	elif allowed_quantity < quantity:
		reason = "quest_limit"

	if accepted > 0 and emit_signals and not _suppress_signals:
		inventory_changed.emit()
		item_added.emit(item, accepted)
	return _add_result(accepted, remaining, accepted > 0, reason)

func _get_quest_item_remaining(item_id: String) -> int:
	var quest_manager := _get_autoload("QuestManager")
	if quest_manager == null:
		return 0
	var active: Dictionary = quest_manager.get("active_quests")
	var total_remaining := 0
	for quest_id in active:
		var quest: Dictionary = active[quest_id]
		var objectives = quest.get("objectives", [])
		var progress = quest.get("progress", [])
		for index in range(objectives.size()):
			var objective = objectives[index]
			if typeof(objective) != TYPE_DICTIONARY or str(objective.get("type", "")) != "collect":
				continue
			var target_id := str(objective.get("target_id", objective.get("target", "")))
			if not _quest_target_matches(target_id, item_id):
				continue
			var required := int(objective.get("required", 1))
			var current := int(progress[index]) if index < progress.size() else 0
			total_remaining += max(0, required - current)
	return total_remaining

func _quest_target_matches(required_target: String, item_id: String) -> bool:
	return required_target == item_id or (required_target != "" and item_id.begins_with(required_target + "_"))

func _load_item_database() -> Dictionary:
	var item_database: Dictionary = {}
	var registry := _get_autoload("DataRegistry")
	if registry == null:
		return item_database
	var definitions: Dictionary = registry.get("items")
	for item_id in definitions:
		var item := registry.call("get_item_data", str(item_id)) as ItemData
		if item != null:
			item_database[item.item_id] = item
	return item_database

func _get_autoload(autoload_name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(autoload_name)

func _initialize_empty_slots() -> void:
	items.clear()
	for tab_id in TAB_ORDER:
		for _index in range(SLOTS_PER_TAB):
			items.append({
				"tab": tab_id,
				"item": null,
				"quantity": 0,
				"instance": null
			})

func _duplicate_slots(source: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in source:
		var instance_copy = null
		if typeof(slot.get("instance")) == TYPE_DICTIONARY:
			instance_copy = slot.get("instance").duplicate(true)
		result.append({
			"tab": str(slot.get("tab", TAB_MATERIALS)),
			"item": slot.get("item"),
			"quantity": int(slot.get("quantity", 0)),
			"instance": instance_copy
		})
	return result

func _clear_slot(slot: Dictionary) -> void:
	slot["item"] = null
	slot["quantity"] = 0
	slot["instance"] = null

func _add_result(accepted: int, remaining: int, changed: bool, reason: String) -> Dictionary:
	return {
		"accepted": accepted,
		"remaining": remaining,
		"changed": changed,
		"reason": reason
	}

func _remove_result(removed: int, remaining: int, changed: bool, reason: String) -> Dictionary:
	return {
		"removed": removed,
		"remaining": remaining,
		"changed": changed,
		"reason": reason
	}
