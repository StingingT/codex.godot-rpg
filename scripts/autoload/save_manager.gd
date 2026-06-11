extends Node

signal game_saved(slot: int)
signal game_loaded(slot: int)

const SAVE_DIR = "user://saves/"
const SAVE_VERSION = 2

# Current save slot
var current_slot: int = 1

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dir = DirAccess.open("user://")
	if dir:
		dir.make_dir("saves")

func save_game(slot: int = current_slot) -> bool:
	var save_data = _gather_save_data()
	
	var file_path = SAVE_DIR + "slot_%d.json" % slot
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		game_saved.emit(slot)
		return true
	return false

func load_game(slot: int = current_slot) -> bool:
	var file_path = SAVE_DIR + "slot_%d.json" % slot
	if not FileAccess.file_exists(file_path):
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	
	if error != OK:
		return false
	
	if typeof(json.data) != TYPE_DICTIONARY:
		return false
	var save_data := migrate_save_data(json.data)
	if save_data.is_empty():
		return false
	_apply_save_data(save_data)
	game_loaded.emit(slot)
	return true

func has_save(slot: int) -> bool:
	var file_path = SAVE_DIR + "slot_%d.json" % slot
	return FileAccess.file_exists(file_path)

func migrate_save_data(source: Dictionary) -> Dictionary:
	var migrated := source.duplicate(true)
	var version := int(migrated.get("version", 1))
	if version < 1 or version > SAVE_VERSION:
		push_error("Unsupported save version: %d" % version)
		return {}

	while version < SAVE_VERSION:
		match version:
			1:
				migrated = _migrate_v1_to_v2(migrated)
			_:
				push_error("No migration path from save version %d." % version)
				return {}
		if migrated.is_empty():
			return {}
		version = int(migrated.get("version", version + 1))

	return migrated

func _migrate_v1_to_v2(source: Dictionary) -> Dictionary:
	var migrated := source.duplicate(true)
	var player_data: Dictionary = migrated.get("player", {}).duplicate(true)
	if player_data.has("inventory"):
		if typeof(player_data.get("inventory")) != TYPE_DICTIONARY:
			push_error("Version 1 save has an invalid inventory payload.")
			return {}
		var staged_inventory := Inventory.new()
		if not staged_inventory.load_save_data(player_data.get("inventory", {})):
			push_error("Version 1 inventory migration failed: %s" % staged_inventory.last_load_error)
			return {}
		player_data["inventory"] = staged_inventory.get_save_data()
		migrated["player"] = player_data
	migrated["version"] = 2
	return migrated

func stage_current_player_for_transition() -> void:
	_pending_player_data = _gather_save_data().get("player", {})

func _gather_save_data() -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")
	var player_data = {}
	
	if player:
		player_data = {
			"position": {"x": player.global_position.x, "y": player.global_position.y},
			"stats": player.get_base_stats_save_data(),
			"inventory": player.inventory.get_save_data() if player.inventory else {},
			"class_type": player.player_class.class_type if player.player_class else 0,
			"skill_points": player.skill_points,
			"unlocked_skills": player.unlocked_skills,
			"ability_slots": player.ability_slots
		}
	
	return {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"current_map": GameManager.current_map_id,
		"story_flags": GameManager.story_flags,
		"player": player_data,
		"quests": {
			"active": QuestManager.active_quests,
			"completed": QuestManager.completed_quests,
			"turned_in": QuestManager.turned_in_quests
		}
	}

func _apply_save_data(data: Dictionary) -> void:
	if data.has("story_flags"):
		GameManager.story_flags = data.story_flags
	
	if data.has("current_map"):
		GameManager.current_map_id = data.current_map
	
	if data.has("quests"):
		var quests = data.quests
		QuestManager.active_quests = quests.get("active", {})
		# Cast arrays to typed arrays
		var completed: Array[String] = []
		for q in quests.get("completed", []):
			completed.append(q)
		QuestManager.completed_quests = completed
		
		var turned_in: Array[String] = []
		for q in quests.get("turned_in", []):
			turned_in.append(q)
		QuestManager.turned_in_quests = turned_in
	
	# Player data is applied when player spawns
	_pending_player_data = data.get("player", {})

var _pending_player_data: Dictionary = {}

func apply_pending_player_data(player: Player) -> void:
	if _pending_player_data.is_empty():
		return
	
	if _pending_player_data.has("class_type"):
		var class_type := int(_pending_player_data.class_type)
		var player_class := DataRegistry.create_player_class(class_type)
		player.set_class(player_class)
		GameManager.player_class = player_class
	
	if _pending_player_data.has("stats"):
		player.stats.load_save_data(_pending_player_data.stats)
	
	if _pending_player_data.has("inventory"):
		player.inventory.load_save_data(_pending_player_data.inventory)
		player.refresh_equipment_stats(false)
	
	if _pending_player_data.has("skill_points"):
		player.skill_points = _pending_player_data.skill_points
	
	if _pending_player_data.has("unlocked_skills"):
		# Cast array to typed array
		var skills: Array[String] = []
		for s in _pending_player_data.unlocked_skills:
			skills.append(s)
		player.unlocked_skills = skills

	if _pending_player_data.has("ability_slots"):
		var slots: Array[String] = []
		for ability_id in _pending_player_data.ability_slots:
			slots.append(ability_id)
		player.ability_slots = slots
	
	if _pending_player_data.has("position"):
		var pos = _pending_player_data.position
		player.global_position = Vector2(pos.x, pos.y)
	
	_pending_player_data = {}

func auto_save() -> void:
	save_game(current_slot)

func delete_save(slot: int) -> void:
	var file_path = SAVE_DIR + "slot_%d.json" % slot
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
