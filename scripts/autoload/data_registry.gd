extends Node

const MAPS_PATH := "res://data/maps/maps.json"
const ENCOUNTERS_PATH := "res://data/encounters/encounters.json"
const MONSTERS_PATH := "res://data/monsters/monsters.json"
const ABILITIES_PATH := "res://data/abilities/abilities.json"

var maps: Dictionary = {}
var encounters: Dictionary = {}
var monsters: Dictionary = {}
var abilities: Dictionary = {}
var items: Dictionary = {}
var quests: Dictionary = {}
var item_resources: Dictionary = {}

func _ready() -> void:
	reload_all()

func reload_all() -> void:
	maps = load_json(MAPS_PATH)
	encounters = load_json(ENCOUNTERS_PATH)
	monsters = load_json(MONSTERS_PATH)
	abilities = load_json(ABILITIES_PATH)
	items = load_folder_json("res://data/items")
	quests = load_folder_json("res://data/quests")
	item_resources.clear()

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

func get_encounter_table(table_id: String) -> Dictionary:
	return encounters.get(table_id, {})

func get_monster(monster_id: String) -> Dictionary:
	return monsters.get(monster_id, {})

func get_ability(ability_id: String) -> Dictionary:
	return abilities.get(ability_id, {})

func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})

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
	var item: ItemData
	if item_type == ItemData.ItemType.WEAPON or data.has("weapon_type"):
		var weapon := WeaponData.new()
		weapon.weapon_type = int(data.get("weapon_type", WeaponData.WeaponType.SWORD))
		weapon.damage = int(data.get("damage", weapon.damage))
		weapon.attack_speed = float(data.get("attack_speed", weapon.attack_speed))
		weapon.knockback = float(data.get("knockback", weapon.knockback))
		item = weapon
	elif item_type == ItemData.ItemType.ARMOR or data.has("armor_type"):
		var armor := ArmorData.new()
		armor.armor_type = int(data.get("armor_type", ArmorData.ArmorType.CHEST))
		armor.defense = int(data.get("defense", armor.defense))
		armor.vitality_bonus = int(data.get("vitality_bonus", armor.vitality_bonus))
		armor.hp_bonus = int(data.get("hp_bonus", armor.hp_bonus))
		item = armor
	else:
		item = ItemData.new()

	item.item_id = str(data.get("item_id", item_id))
	item.item_name = str(data.get("item_name", "Unknown"))
	item.description = str(data.get("description", ""))
	item.item_type = item_type
	item.required_level = int(data.get("required_level", item.required_level))
	item.buy_price = int(data.get("buy_price", item.buy_price))
	item.sell_price = int(data.get("sell_price", item.sell_price))
	item.stackable = bool(data.get("stackable", item.stackable))
	item.max_stack = int(data.get("max_stack", item.max_stack))
	item.attack_bonus = int(data.get("attack_bonus", item.attack_bonus))
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
