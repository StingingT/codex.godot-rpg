extends Node

const MAPS_PATH := "res://data/maps/maps.json"
const ENCOUNTERS_PATH := "res://data/encounters/encounters.json"
const MONSTERS_PATH := "res://data/monsters/monsters.json"
const ABILITIES_PATH := "res://data/abilities/abilities.json"
const ITEMS_PATH := "res://data/items"
const QUESTS_PATH := "res://data/quests"
const SHOPS_PATH := "res://data/shops"
const ITEM_TIERS_PATH := "res://data/itemization/item_tiers.json"
const AFFIXES_PATH := "res://data/itemization/affixes.json"
const LOOT_TABLES_PATH := "res://data/loot/loot_tables.json"

const VALID_CATEGORIES: Array[String] = ["equipment", "consumable", "material", "quest"]
const VALID_SLOTS: Array[String] = [
	"weapon",
	"off_hand",
	"headgear",
	"overall",
	"armguards",
	"boots",
	"amulet",
	"ring"
]
const VALID_STATS: Array[String] = [
	"attack",
	"defense",
	"max_hp",
	"max_mana",
	"move_speed",
	"attack_speed",
	"crit_chance",
	"crit_damage",
	"cooldown_reduction",
	"status_resistance",
	"spell_damage"
]
const VALID_RARITIES: Array[String] = ["common", "rare", "epic", "legendary"]
const VALID_CLASSES: Array[String] = ["warrior", "ranger", "mage"]
const CURRENT_PICKUP_REFERENCES: Array[String] = ["slime_gel", "bone"]

var maps: Dictionary = {}
var encounters: Dictionary = {}
var monsters: Dictionary = {}
var abilities: Dictionary = {}
var items: Dictionary = {}
var quests: Dictionary = {}
var shops: Dictionary = {}
var item_tiers: Dictionary = {}
var affixes: Dictionary = {}
var loot_tables: Dictionary = {}
var item_resources: Dictionary = {}
var validation_errors: Array[String] = []
var validation_warnings: Array[String] = []

func _ready() -> void:
	reload_all()

func reload_all() -> void:
	maps = load_json(MAPS_PATH)
	encounters = load_json(ENCOUNTERS_PATH)
	monsters = load_json(MONSTERS_PATH)
	abilities = load_json(ABILITIES_PATH)
	items = _normalize_items(load_folder_json(ITEMS_PATH))
	quests = load_folder_json(QUESTS_PATH)
	shops = _normalize_shops(load_folder_json(SHOPS_PATH))
	item_tiers = load_json(ITEM_TIERS_PATH)
	affixes = load_json(AFFIXES_PATH)
	loot_tables = load_json(LOOT_TABLES_PATH)
	item_resources.clear()
	validate_loaded_data()

func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Missing data file: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK:
		push_error("Could not parse JSON %s: %s" % [path, json.get_error_message()])
		return {}
	return json.data if typeof(json.data) == TYPE_DICTIONARY else {}

func load_folder_json(path: String) -> Dictionary:
	var result: Dictionary = {}
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		var data := load_json(path.path_join(file_name))
		var id := file_name.get_basename()
		if data.has("item_id"):
			id = str(data.item_id)
		elif data.has("quest_id"):
			id = str(data.quest_id)
		result[id] = data
	return result

func get_map(map_id: String) -> Dictionary:
	return maps.get(map_id, {})

func get_travel_maps(include_legacy: bool = false) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for map_id in maps:
		var map_data: Dictionary = maps[map_id]
		var content_state := str(map_data.get("content_state", "legacy"))
		if content_state != "active" and not include_legacy:
			continue
		if content_state == "development":
			continue
		result.append({
			"id": str(map_id),
			"name": str(map_data.get("display_name", str(map_id).capitalize())),
			"level_req": int(map_data.get("level_requirement", max(1, int(map_data.get("zone_tier", 0))))),
			"route_order": int(map_data.get("route_order", 999))
		})
	result.sort_custom(_sort_travel_maps)
	return result

func _sort_travel_maps(a: Dictionary, b: Dictionary) -> bool:
	var a_order := int(a.get("route_order", 999))
	var b_order := int(b.get("route_order", 999))
	if a_order == b_order:
		return str(a.get("name", "")) < str(b.get("name", ""))
	return a_order < b_order

func get_encounter_table(table_id: String) -> Dictionary:
	return encounters.get(table_id, {})

func get_monster(monster_id: String) -> Dictionary:
	return monsters.get(monster_id, {})

func get_ability(ability_id: String) -> Dictionary:
	return abilities.get(ability_id, {})

func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})

func get_shop(shop_id: String) -> Dictionary:
	return shops.get(shop_id, {}).duplicate(true)

func get_item_tier(tier_id: String) -> Dictionary:
	return item_tiers.get("tiers", {}).get(tier_id, {})

func get_affix_pool(pool_id: String) -> Dictionary:
	return affixes.get("pools", {}).get(pool_id, {})

func get_loot_table(table_id: String) -> Dictionary:
	return loot_tables.get("tables", {}).get(table_id, {})

func get_item_data(item_id: String) -> ItemData:
	if item_id == "":
		return null
	if not item_resources.has(item_id):
		var data := get_item(item_id)
		if data.is_empty():
			return null
		var item := _create_item_data(item_id, data)
		if item == null:
			return null
		item_resources[item_id] = item
	return item_resources[item_id].duplicate(true) as ItemData

func get_quest(quest_id: String) -> Dictionary:
	return quests.get(quest_id, {})

func has_ability(ability_id: String) -> bool:
	return abilities.has(ability_id)

func create_player_class(class_type: int) -> PlayerClass:
	var player_class := PlayerClass.new()
	player_class.class_type = class_type
	match class_type:
		PlayerClass.ClassType.WARRIOR:
			player_class.player_class_name = "Warrior"
			player_class.description = "Master of melee combat"
			player_class.base_stats = {"max_hp": 120, "max_mana": 30, "attack": 15, "defense": 8, "speed": 75.0}
		PlayerClass.ClassType.RANGER:
			player_class.player_class_name = "Ranger"
			player_class.description = "Master of ranged combat"
			player_class.base_stats = {"max_hp": 90, "max_mana": 50, "attack": 12, "defense": 5, "speed": 90.0}
		PlayerClass.ClassType.MAGE:
			player_class.player_class_name = "Mage"
			player_class.description = "Master of elemental magic"
			player_class.base_stats = {"max_hp": 70, "max_mana": 100, "attack": 20, "defense": 3, "speed": 80.0}
	return player_class

func _create_item_data(item_id: String, data: Dictionary) -> ItemData:
	var item_type := int(data.get("item_type", ItemData.ItemType.MATERIAL))
	var base_stats: Dictionary = data.get("base_stats", {})
	var item: ItemData
	if item_type == ItemData.ItemType.WEAPON or data.has("weapon_type"):
		var weapon := WeaponData.new()
		weapon.weapon_type = int(data.get("weapon_type", WeaponData.WeaponType.SWORD))
		weapon.damage = int(base_stats.get("attack", data.get("damage", weapon.damage)))
		weapon.attack_speed = float(base_stats.get("attack_speed", data.get("attack_speed", weapon.attack_speed)))
		weapon.knockback = float(data.get("knockback", weapon.knockback))
		item = weapon
	elif item_type == ItemData.ItemType.ARMOR or data.has("armor_type"):
		var armor := ArmorData.new()
		armor.armor_type = int(data.get("armor_type", ArmorData.ArmorType.CHEST))
		armor.defense = int(base_stats.get("defense", data.get("defense", armor.defense)))
		armor.vitality_bonus = int(data.get("vitality_bonus", armor.vitality_bonus))
		armor.hp_bonus = int(base_stats.get("max_hp", data.get("hp_bonus", armor.hp_bonus)))
		item = armor
	else:
		item = ItemData.new()

	item.schema_version = int(data.get("schema_version", 1))
	item.item_id = str(data.get("item_id", item_id))
	item.item_name = str(data.get("item_name", "Unknown"))
	item.description = str(data.get("description", ""))
	item.item_type = item_type
	item.category = str(data.get("category", "material"))
	item.slot = str(data.get("slot", ""))
	item.material_tier = str(data.get("material_tier", ""))
	for class_id in data.get("allowed_classes", []):
		item.allowed_classes.append(str(class_id))
	item.required_level = int(data.get("required_level", item.required_level))
	item.buy_price = int(data.get("buy_price", item.buy_price))
	item.sell_price = int(data.get("sell_price", item.sell_price))
	item.stackable = bool(data.get("stackable", item.stackable))
	item.max_stack = int(data.get("max_stack", item.max_stack))
	item.base_stats = base_stats.duplicate(true)
	item.standard_roll = data.get("standard_roll", {}).duplicate(true)
	item.affix_pool = str(data.get("affix_pool", ""))
	item.fixed_rarity = str(data.get("fixed_rarity", ""))
	item.attack_bonus = int(base_stats.get("attack", data.get("attack_bonus", item.attack_bonus))) if item.slot in ["amulet", "ring"] else int(data.get("attack_bonus", item.attack_bonus))
	item.heal_amount = int(data.get("heal_amount", item.heal_amount))
	item.mana_amount = int(data.get("mana_amount", item.mana_amount))

	var texture := _load_item_texture(item.item_id, data)
	item.sprite = texture
	item.icon = texture
	return item

func _load_item_texture(item_id: String, data: Dictionary) -> Texture2D:
	var candidates: Array[String] = []
	for key in ["sprite", "icon"]:
		var explicit_path := str(data.get(key, ""))
		if explicit_path != "":
			candidates.append(explicit_path)
	candidates.append("res://assets/sprites/weapons/%s.png" % item_id)
	var parts := item_id.split("_")
	if parts.size() == 2:
		candidates.append("res://assets/sprites/weapons/%s_%s.png" % [parts[1], parts[0]])
	for path in candidates:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null

func normalize_item_definition(item_id: String, source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	var item_type := int(data.get("item_type", ItemData.ItemType.MATERIAL))
	var slot := str(data.get("slot", ""))
	if slot == "":
		slot = _derive_legacy_slot(item_id, item_type, data)

	var category := str(data.get("category", ""))
	if category == "":
		category = _derive_category(item_type, slot)

	var base_stats: Dictionary = data.get("base_stats", {}).duplicate(true)
	_copy_legacy_stat(data, base_stats, "damage", "attack")
	_copy_legacy_stat(data, base_stats, "defense", "defense")
	_copy_legacy_stat(data, base_stats, "hp_bonus", "max_hp")
	_copy_legacy_stat(data, base_stats, "attack_bonus", "attack")
	_copy_legacy_stat(data, base_stats, "attack_speed", "attack_speed")
	_copy_legacy_stat(data, base_stats, "spell_damage", "spell_damage")

	data["schema_version"] = int(data.get("schema_version", 1))
	data["item_id"] = str(data.get("item_id", item_id))
	data["item_type"] = item_type
	data["category"] = category
	data["slot"] = slot
	data["material_tier"] = str(data.get("material_tier", ""))
	data["allowed_classes"] = data.get("allowed_classes", [])
	data["stackable"] = bool(data.get("stackable", false))
	data["max_stack"] = max(1, int(data.get("max_stack", 1)))
	data["required_level"] = max(1, int(data.get("required_level", 1)))
	data["base_stats"] = base_stats
	data["standard_roll"] = data.get("standard_roll", {})
	data["affix_pool"] = str(data.get("affix_pool", ""))
	data["fixed_rarity"] = str(data.get("fixed_rarity", ""))
	data["buy_price"] = max(0, int(data.get("buy_price", 0)))
	data["sell_price"] = max(0, int(data.get("sell_price", 0)))
	return data

func normalize_shop_data(shop_id: String, source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	data["shop_id"] = str(data.get("shop_id", shop_id))
	data["shop_name"] = str(data.get("shop_name", data.get("name", "Shop")))
	var normalized_items: Array = []
	for raw_entry in data.get("items", data.get("inventory", [])):
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry.duplicate(true)
		entry["item_id"] = str(entry.get("item_id", ""))
		entry["buy_price"] = int(entry.get("buy_price", entry.get("price", 0)))
		entry["quantity"] = int(entry.get("quantity", entry.get("stock", -1)))
		if not entry.has("sell_price"):
			var definition: Dictionary = items.get(entry["item_id"], {})
			entry["sell_price"] = int(definition.get("sell_price", 0))
		normalized_items.append(entry)
	data["items"] = normalized_items
	return data

func validate_loaded_data() -> Dictionary:
	validation_errors.clear()
	validation_warnings.clear()
	_validate_item_definitions()
	_validate_affix_configuration()
	_validate_item_references()
	for message in validation_errors:
		push_error("Item data validation: %s" % message)
	if not validation_warnings.is_empty():
		push_warning("Item data validation reported %d non-blocking warning(s)." % validation_warnings.size())
	return {
		"errors": validation_errors.duplicate(),
		"warnings": validation_warnings.duplicate()
	}

func _normalize_items(raw_items: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for item_id in raw_items:
		normalized[str(item_id)] = normalize_item_definition(str(item_id), raw_items[item_id])
	return normalized

func _normalize_shops(raw_shops: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for shop_id in raw_shops:
		normalized[str(shop_id)] = normalize_shop_data(str(shop_id), raw_shops[shop_id])
	return normalized

func _derive_legacy_slot(item_id: String, item_type: int, data: Dictionary) -> String:
	if item_id == "leather_bracelet":
		return "amulet"
	if item_type == ItemData.ItemType.WEAPON or data.has("weapon_type"):
		return "weapon"
	if item_type == ItemData.ItemType.ARMOR or data.has("armor_type"):
		match int(data.get("armor_type", ArmorData.ArmorType.CHEST)):
			ArmorData.ArmorType.HELMET:
				return "headgear"
			ArmorData.ArmorType.BOOTS:
				return "boots"
			ArmorData.ArmorType.GLOVES:
				return "armguards"
			_:
				return "overall"
	return ""

func _derive_category(item_type: int, slot: String) -> String:
	if slot != "":
		return "equipment"
	if item_type == ItemData.ItemType.CONSUMABLE:
		return "consumable"
	if item_type == ItemData.ItemType.QUEST:
		return "quest"
	return "material"

func _copy_legacy_stat(source: Dictionary, target: Dictionary, source_key: String, target_key: String) -> void:
	if not target.has(target_key) and source.has(source_key):
		target[target_key] = source[source_key]

func _validate_item_definitions() -> void:
	var tiers: Dictionary = item_tiers.get("tiers", {})
	var pools: Dictionary = affixes.get("pools", {})
	for item_id in items:
		var data: Dictionary = items[item_id]
		if str(data.get("item_id", "")) != str(item_id):
			validation_errors.append("%s has a mismatched item_id." % item_id)
		var category := str(data.get("category", ""))
		var slot := str(data.get("slot", ""))
		if not VALID_CATEGORIES.has(category):
			validation_errors.append("%s has unknown category '%s'." % [item_id, category])
		if slot != "" and not VALID_SLOTS.has(slot):
			validation_errors.append("%s has unknown slot '%s'." % [item_id, slot])
		if category == "equipment" and slot == "":
			validation_errors.append("%s is equipment but has no canonical slot." % item_id)
		if category != "equipment" and slot != "":
			validation_errors.append("%s has slot '%s' outside the equipment category." % [item_id, slot])
		var item_type := int(data.get("item_type", ItemData.ItemType.MATERIAL))
		if category == "consumable" and item_type != ItemData.ItemType.CONSUMABLE:
			validation_errors.append("%s is a consumable category with incompatible item_type." % item_id)
		if category == "material" and item_type != ItemData.ItemType.MATERIAL:
			validation_errors.append("%s is a material category with incompatible item_type." % item_id)
		if category == "quest" and item_type != ItemData.ItemType.QUEST:
			validation_errors.append("%s is a quest category with incompatible item_type." % item_id)
		if not bool(data.get("stackable", false)) and int(data.get("max_stack", 1)) != 1:
			validation_errors.append("%s is non-stackable but max_stack is not 1." % item_id)
		for stat_id in data.get("base_stats", {}):
			if not VALID_STATS.has(str(stat_id)):
				validation_errors.append("%s has unknown base stat '%s'." % [item_id, stat_id])
		for stat_id in data.get("standard_roll", {}):
			if not VALID_STATS.has(str(stat_id)):
				validation_errors.append("%s has unknown standard roll stat '%s'." % [item_id, stat_id])
		var tier_id := str(data.get("material_tier", ""))
		if tier_id != "" and not tiers.has(tier_id):
			validation_errors.append("%s has unknown material tier '%s'." % [item_id, tier_id])
		var affix_pool := str(data.get("affix_pool", ""))
		if affix_pool != "" and not pools.has(affix_pool):
			validation_errors.append("%s references unknown affix pool '%s'." % [item_id, affix_pool])
		var rarity := str(data.get("fixed_rarity", ""))
		if rarity != "" and not VALID_RARITIES.has(rarity):
			validation_errors.append("%s has unknown rarity '%s'." % [item_id, rarity])
		for class_id in data.get("allowed_classes", []):
			if not VALID_CLASSES.has(str(class_id)):
				validation_errors.append("%s allows unknown class '%s'." % [item_id, class_id])
		var icon_path := str(data.get("icon", data.get("sprite", "")))
		if icon_path == "":
			validation_warnings.append("%s has no icon path." % item_id)
		elif not ResourceLoader.exists(icon_path):
			validation_errors.append("%s icon does not exist: %s." % [item_id, icon_path])

func _validate_affix_configuration() -> void:
	for pool_id in affixes.get("pools", {}):
		var pool: Dictionary = affixes.get("pools", {})[pool_id]
		for affix in pool.get("affixes", []):
			if typeof(affix) != TYPE_DICTIONARY:
				validation_errors.append("Affix pool %s contains a non-dictionary entry." % pool_id)
				continue
			var stat_id := str(affix.get("stat", ""))
			if not VALID_STATS.has(stat_id):
				validation_errors.append("Affix %s uses unknown stat '%s'." % [affix.get("affix_id", "unknown"), stat_id])
			var operation := str(affix.get("operation", "add"))
			if operation not in ["add", "percent_add"]:
				validation_errors.append("Affix %s uses unknown operation '%s'." % [affix.get("affix_id", "unknown"), operation])
			if float(affix.get("min", 0.0)) > float(affix.get("max", 0.0)):
				validation_errors.append("Affix %s has min greater than max." % affix.get("affix_id", "unknown"))

func _validate_item_references() -> void:
	for shop_id in shops:
		for entry in shops[shop_id].get("items", []):
			_validate_item_reference(str(entry.get("item_id", "")), "shop %s" % shop_id)
	for quest_id in quests:
		_validate_quest_item_references(str(quest_id), quests[quest_id])
	for class_type in range(PlayerClass.ClassType.size()):
		var player_class := create_player_class(class_type)
		for item_id in player_class.get_starting_equipment():
			_validate_item_reference(item_id, "%s starting equipment" % player_class.player_class_name)
	for item_id in CURRENT_PICKUP_REFERENCES:
		_validate_item_reference(item_id, "current monster pickup")
	for table_id in loot_tables.get("tables", {}):
		var table: Dictionary = loot_tables.get("tables", {})[table_id]
		for entry in table.get("entries", []):
			if typeof(entry) == TYPE_DICTIONARY and entry.has("item_id"):
				_validate_item_reference(str(entry.get("item_id", "")), "loot table %s" % table_id)

func _validate_quest_item_references(quest_id: String, quest: Dictionary) -> void:
	for objective in quest.get("objectives", []):
		if typeof(objective) == TYPE_DICTIONARY and str(objective.get("type", "")) == "collect":
			_validate_item_reference(
				str(objective.get("item_id", objective.get("target_id", objective.get("target", "")))),
				"quest %s collect objective" % quest_id
			)
	var rewards = quest.get("rewards", {})
	if typeof(rewards) == TYPE_DICTIONARY:
		for entry in rewards.get("items", []):
			if typeof(entry) == TYPE_DICTIONARY:
				_validate_item_reference(str(entry.get("item_id", "")), "quest %s reward" % quest_id)
	elif typeof(rewards) == TYPE_ARRAY:
		for entry in rewards:
			if typeof(entry) == TYPE_DICTIONARY and str(entry.get("type", "")) == "item":
				_validate_item_reference(str(entry.get("item_id", entry.get("target", ""))), "quest %s reward" % quest_id)

func _validate_item_reference(item_id: String, source: String) -> void:
	if item_id == "":
		validation_errors.append("%s contains an empty item reference." % source)
	elif not items.has(item_id):
		validation_errors.append("%s references missing item '%s'." % [source, item_id])
