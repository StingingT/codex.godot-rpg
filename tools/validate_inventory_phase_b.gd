extends SceneTree

var _failed: bool = false

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var registry := root.get_node_or_null("DataRegistry")
	var quest_manager := root.get_node_or_null("QuestManager")
	var save_manager := root.get_node_or_null("SaveManager")
	if registry == null or quest_manager == null or save_manager == null:
		push_error("Phase B validation requires DataRegistry, QuestManager, and SaveManager autoloads.")
		quit(1)
		return

	var health := registry.call("get_item_data", "health_potion") as ItemData
	var mana := registry.call("get_item_data", "mana_potion") as ItemData
	var bone := registry.call("get_item_data", "bone") as ItemData
	var sword := registry.call("get_item_data", "bronze_sword") as ItemData
	var quest_item := registry.call("get_item_data", "healing_herb") as ItemData
	if health == null or mana == null or bone == null or sword == null or quest_item == null:
		push_error("Phase B validation could not load required item definitions.")
		quit(1)
		return

	_test_tab_layout()
	_test_stack_splitting(health)
	_test_partial_acceptance(health, mana)
	_test_preview_is_non_mutating(health)
	_test_remove_across_stacks(health)
	_test_legacy_inventory_migration(health)
	_test_atomic_overflow_rollback(bone, sword)
	_test_quest_item_cap(quest_item, quest_manager)
	_test_save_manager_migration(save_manager)

	if _failed:
		quit(1)
		return
	print("Inventory Phase B validation passed.")
	quit(0)

func _test_tab_layout() -> void:
	var inventory := Inventory.new()
	_expect(inventory.items.size() == 72, "Inventory must contain 72 total slots.")
	for tab_id in Inventory.TAB_ORDER:
		_expect(
			inventory.get_tab_slots(tab_id).size() == Inventory.SLOTS_PER_TAB,
			"Tab %s must contain 24 slots." % tab_id
		)

func _test_stack_splitting(health: ItemData) -> void:
	var inventory := Inventory.new()
	var result := inventory.add_item_detailed(health, 45)
	_expect(int(result.get("accepted", 0)) == 45, "A 45-potion add should accept all quantities.")
	_expect(int(result.get("remaining", 0)) == 0, "A 45-potion add should have no remainder.")
	var quantities: Array[int] = []
	for slot in inventory.get_occupied_slots(Inventory.TAB_CONSUMABLES):
		quantities.append(int(slot.get("quantity", 0)))
	_expect(quantities == [20, 20, 5], "Potion stacks must split as 20, 20, 5.")

func _test_partial_acceptance(health: ItemData, mana: ItemData) -> void:
	var inventory := Inventory.new()
	_expect(inventory.add_item(mana, 460), "Twenty-three full mana stacks should fit.")
	_expect(inventory.add_item(health, 19), "A nearly full health stack should fit in the last slot.")
	var result := inventory.add_item_detailed(health, 5)
	_expect(int(result.get("accepted", 0)) == 1, "Partial add should fill the one remaining stack space.")
	_expect(int(result.get("remaining", 0)) == 4, "Partial add should return four unaccepted items.")
	_expect(result.get("reason", "") == "inventory_full", "Partial add should report inventory_full.")

func _test_preview_is_non_mutating(health: ItemData) -> void:
	var inventory := Inventory.new()
	var preview := inventory.preview_add_item(health, 45)
	_expect(int(preview.get("accepted", 0)) == 45, "Preview should report available capacity.")
	_expect(inventory.get_total_quantity("health_potion") == 0, "Preview must not mutate inventory.")

func _test_remove_across_stacks(health: ItemData) -> void:
	var inventory := Inventory.new()
	_expect(inventory.add_item(health, 35), "Removal test setup should add 35 potions.")
	_expect(inventory.remove_item_by_id("health_potion", 25), "Removal should consume quantities across stacks.")
	_expect(inventory.get_total_quantity("health_potion") == 10, "Removing 25 from 35 should leave 10.")

func _test_legacy_inventory_migration(_health: ItemData) -> void:
	var inventory := Inventory.new()
	var loaded := inventory.load_save_data({
		"gold": 123,
		"items": [
			{"item_id": "health_potion", "quantity": 30},
			{"item_id": "bronze_sword", "quantity": 2},
			{"item_id": "bone", "quantity": 100}
		],
		"equipment": {"weapon": "steel_sword"}
	}, false)
	_expect(loaded, "Version 1 inventory should migrate without loss.")
	_expect(inventory.gold == 123, "Migration must preserve gold.")
	_expect(inventory.get_total_quantity("health_potion") == 30, "Migration must preserve potion quantity.")
	_expect(inventory.get_total_quantity("bronze_sword") == 2, "Migration must split non-stackable equipment.")
	_expect(inventory.get_total_quantity("bone") == 100, "Migration must preserve material quantity.")
	var save_data := inventory.get_save_data()
	_expect(int(save_data.get("inventory_schema_version", 0)) == 2, "Migrated inventory must save schema version 2.")
	for entry in save_data.get("items", []):
		_expect(Inventory.TAB_ORDER.has(str(entry.get("tab", ""))), "Every saved item must include a valid tab.")

func _test_atomic_overflow_rollback(bone: ItemData, sword: ItemData) -> void:
	var inventory := Inventory.new()
	inventory.add_gold(7)
	_expect(inventory.add_item(bone, 1), "Overflow test setup should add one bone.")
	var loaded := inventory.load_save_data({
		"gold": 999,
		"items": [{"item_id": sword.item_id, "quantity": 73}],
		"equipment": {}
	}, false)
	_expect(not loaded, "Overflowing legacy migration must fail.")
	_expect(inventory.gold == 7, "Failed migration must restore prior gold.")
	_expect(inventory.get_total_quantity("bone") == 1, "Failed migration must restore prior items.")

func _test_quest_item_cap(quest_item: ItemData, quest_manager: Node) -> void:
	var previous_active: Dictionary = (quest_manager.get("active_quests") as Dictionary).duplicate(true)
	quest_manager.set("active_quests", {
		"phase_b_test": {
			"status": 1,
			"objectives": [{
				"type": "collect",
				"target": quest_item.item_id,
				"required": 3
			}],
			"progress": [0]
		}
	})
	var inventory := Inventory.new()
	var result := inventory.add_item_detailed(quest_item, 10)
	_expect(int(result.get("accepted", 0)) == 3, "Quest-only items must cap at remaining requirement.")
	_expect(int(result.get("remaining", 0)) == 7, "Quest-only cap must return the remainder.")
	_expect(result.get("reason", "") == "quest_limit", "Quest-only cap must report quest_limit.")
	quest_manager.set("active_quests", previous_active)

func _test_save_manager_migration(save_manager: Node) -> void:
	var migrated: Dictionary = save_manager.call("migrate_save_data", {
		"version": 1,
		"player": {
			"inventory": {
				"gold": 50,
				"items": [{"item_id": "health_potion", "quantity": 30}],
				"equipment": {}
			}
		}
	})
	_expect(not migrated.is_empty(), "SaveManager must migrate a valid version 1 save.")
	_expect(int(migrated.get("version", 0)) == 2, "Migrated save must use version 2.")
	var inventory_data: Dictionary = migrated.get("player", {}).get("inventory", {})
	_expect(int(inventory_data.get("inventory_schema_version", 0)) == 2, "Migrated save must contain inventory schema 2.")
	_expect(inventory_data.get("items", []).size() == 2, "A 30-potion legacy stack must split into two saved stacks.")

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
