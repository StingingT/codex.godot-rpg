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

func _ready() -> void:
	reload_all()

func reload_all() -> void:
	maps = load_json(MAPS_PATH)
	encounters = load_json(ENCOUNTERS_PATH)
	monsters = load_json(MONSTERS_PATH)
	abilities = load_json(ABILITIES_PATH)
	items = load_folder_json("res://data/items")
	quests = load_folder_json("res://data/quests")

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

func get_quest(quest_id: String) -> Dictionary:
	return quests.get(quest_id, {})

func has_ability(ability_id: String) -> bool:
	return abilities.has(ability_id)
