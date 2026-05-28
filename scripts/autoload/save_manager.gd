extends Node

signal game_saved(slot: int)
signal game_loaded(slot: int)

const SAVE_DIR = "user://saves/"
const SAVE_VERSION = 1

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
	
	var save_data = json.data
	_apply_save_data(save_data)
	game_loaded.emit(slot)
	return true

func has_save(slot: int) -> bool:
	var file_path = SAVE_DIR + "slot_%d.json" % slot
	return FileAccess.file_exists(file_path)

func _gather_save_data() -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")
	var player_data = {}
	
	if player:
		player_data = {
			"position": {"x": player.global_position.x, "y": player.global_position.y},
			"stats": player.stats.get_save_data(),
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
	
	if _pending_player_data.has("stats"):
		player.stats.load_save_data(_pending_player_data.stats)
	
	if _pending_player_data.has("inventory"):
		player.inventory.load_save_data(_pending_player_data.inventory)
	
	if _pending_player_data.has("class_type"):
		# Re-apply class
		var class_type = _pending_player_data.class_type
		var _class_data = load("res://data/classes/warrior_skill_tree.json") # Default
		match class_type:
			0: _class_data = load("res://data/classes/warrior_skill_tree.json")
			1: _class_data = load("res://data/classes/ranger_skill_tree.json")
			2: _class_data = load("res://data/classes/mage_skill_tree.json")
		# Apply class...
	
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
