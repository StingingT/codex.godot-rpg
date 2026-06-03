extends Node

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String, objective_index: int, progress: int)
signal quest_completed(quest_id: String)
signal quest_turned_in(quest_id: String)

const QUESTS_PATH = "res://data/quests/"

# Quest status
enum QuestStatus { UNAVAILABLE, AVAILABLE, ACTIVE, COMPLETE, TURNED_IN }

# All quest data
var all_quests: Dictionary = {}

# Player's quest progress
var active_quests: Dictionary = {}
var completed_quests: Array[String] = []
var turned_in_quests: Array[String] = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_all_quests()
	
	# Connect to game events
	var game_manager := _get_game_manager()
	if game_manager:
		if game_manager.has_signal("monster_killed"):
			game_manager.monster_killed.connect(_on_monster_killed)
		if game_manager.has_signal("item_picked_up"):
			game_manager.item_picked_up.connect(_on_item_picked_up)

func _load_all_quests() -> void:
	var dir = DirAccess.open(QUESTS_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var quest_id = file_name.replace(".json", "")
				var quest_data = _load_quest(quest_id)
				if not quest_data.is_empty():
					all_quests[quest_id] = quest_data
			file_name = dir.get_next()

func _load_quest(quest_id: String) -> Dictionary:
	var file_path = QUESTS_PATH + quest_id + ".json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			return _normalize_quest(json.data)
	return {}

func _normalize_quest(quest_data: Variant) -> Dictionary:
	if typeof(quest_data) != TYPE_DICTIONARY:
		return {}
	if not quest_data.has("title") and quest_data.has("quest_name"):
		quest_data["title"] = quest_data["quest_name"]
	if quest_data.has("objectives") and typeof(quest_data["objectives"]) == TYPE_ARRAY:
		for objective in quest_data["objectives"]:
			if typeof(objective) == TYPE_DICTIONARY:
				if not objective.has("target") and objective.has("target_id"):
					objective["target"] = objective["target_id"]
				if not objective.has("target_id") and objective.has("target"):
					objective["target_id"] = objective["target"]
	return quest_data

func start_quest(quest_id: String) -> bool:
	if not is_quest_available(quest_id):
		return false
	
	var quest_data = all_quests[quest_id].duplicate(true)
	quest_data["status"] = QuestStatus.ACTIVE
	quest_data["progress"] = []
	
	# Initialize progress tracking
	if quest_data.has("objectives"):
		for objective in quest_data.objectives:
			quest_data.progress.append(0)
	
	active_quests[quest_id] = quest_data
	quest_started.emit(quest_id)
	return true

func complete_quest(quest_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	
	var quest_data = active_quests[quest_id]
	quest_data.status = QuestStatus.COMPLETE
	quest_completed.emit(quest_id)
	return true

func turn_in_quest(quest_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	
	var quest_data = active_quests[quest_id]
	if quest_data.status != QuestStatus.COMPLETE:
		return false
	
	# Grant rewards
	_grant_rewards(quest_data)
	
	quest_data.status = QuestStatus.TURNED_IN
	turned_in_quests.append(quest_id)
	completed_quests.append(quest_id)
	active_quests.erase(quest_id)
	
	quest_turned_in.emit(quest_id)
	return true

func _grant_rewards(quest_data: Dictionary) -> void:
	if not quest_data.has("rewards"):
		return
	
	var rewards = quest_data.rewards
	var player = null
	if is_inside_tree():
		player = get_tree().get_first_node_in_group("player")
	var game_manager := _get_game_manager()
	if typeof(rewards) == TYPE_ARRAY:
		for reward in rewards:
			if typeof(reward) != TYPE_DICTIONARY:
				continue
			match str(reward.get("type", "")):
				"gold":
					if player and player.inventory:
						player.inventory.add_gold(int(reward.get("amount", 0)))
						if game_manager and game_manager.has_signal("player_gold_changed"):
							game_manager.player_gold_changed.emit(player.inventory.gold)
				"xp":
					if player and player.stats:
						player.stats.add_xp(int(reward.get("amount", 0)))
				"item":
					if game_manager and game_manager.has_signal("item_picked_up"):
						game_manager.item_picked_up.emit(str(reward.get("target", reward.get("item_id", ""))), int(reward.get("quantity", 1)))
		return
	
	# Handle gold reward
	if rewards.has("gold"):
		var gold_amount = rewards.gold
		# Also give to player if available
		if player and player.inventory:
			player.inventory.add_gold(gold_amount)
			if game_manager and game_manager.has_signal("player_gold_changed"):
				game_manager.player_gold_changed.emit(player.inventory.gold)
	
	# Handle XP reward
	if rewards.has("xp"):
		var xp_amount = rewards.xp
		if player and player.stats:
			player.stats.add_xp(xp_amount)
	
	# Handle item rewards
	if rewards.has("items"):
		var items = rewards.items
		for item_reward in items:
			var item_id = item_reward.get("item_id", "")
			var quantity = item_reward.get("quantity", 1)
			# Add to inventory via GameManager signal
			if game_manager and game_manager.has_signal("item_picked_up"):
				game_manager.item_picked_up.emit(item_id, quantity)

func update_objective(quest_id: String, objective_index: int, amount: int = 1) -> void:
	if not active_quests.has(quest_id):
		return
	
	var quest_data = active_quests[quest_id]
	if not quest_data.has("progress") or objective_index >= quest_data.progress.size():
		return
	
	if not quest_data.has("objectives") or objective_index >= quest_data.objectives.size():
		return
	
	var objective = quest_data.objectives[objective_index]
	var required = objective.get("required", 1)
	
	quest_data.progress[objective_index] = min(quest_data.progress[objective_index] + amount, required)
	quest_updated.emit(quest_id, objective_index, quest_data.progress[objective_index])
	
	# Check if all objectives complete
	var all_complete = true
	for i in range(quest_data.objectives.size()):
		if i >= quest_data.progress.size():
			all_complete = false
			break
		var obj = quest_data.objectives[i]
		var req = obj.get("required", 1)
		if quest_data.progress[i] < req:
			all_complete = false
			break
	
	if all_complete:
		# Use call_deferred to avoid modifying dictionary during iteration
		call_deferred("complete_quest", quest_id)

func _on_monster_killed(monster_type: String, _position: Vector2) -> void:
	# Create a copy of keys to avoid modification during iteration
	var quest_ids = active_quests.keys()
	for quest_id in quest_ids:
		if not active_quests.has(quest_id):
			continue
		var quest_data = active_quests[quest_id]
		if quest_data.get("status", 0) != QuestStatus.ACTIVE:
			continue
		
		if not quest_data.has("objectives"):
			continue
		
		for i in range(quest_data.objectives.size()):
			var objective = quest_data.objectives[i]
			if objective.get("type", "") == "kill" and _matches_target(str(objective.get("target", objective.get("target_id", ""))), monster_type):
				update_objective(quest_id, i, 1)

func _on_item_picked_up(item_id: String, quantity: int) -> void:
	# Create a copy of keys to avoid modification during iteration
	var quest_ids = active_quests.keys()
	for quest_id in quest_ids:
		if not active_quests.has(quest_id):
			continue
		var quest_data = active_quests[quest_id]
		if quest_data.get("status", 0) != QuestStatus.ACTIVE:
			continue
		
		if not quest_data.has("objectives"):
			continue
		
		for i in range(quest_data.objectives.size()):
			var objective = quest_data.objectives[i]
			if objective.get("type", "") == "collect" and _matches_target(str(objective.get("target", objective.get("target_id", ""))), item_id):
				update_objective(quest_id, i, quantity)

func _matches_target(required_target: String, actual_id: String) -> bool:
	if required_target == actual_id:
		return true
	if required_target == "":
		return false
	return actual_id.begins_with(required_target + "_")

func get_quest_status(quest_id: String) -> int:
	if turned_in_quests.has(quest_id):
		return QuestStatus.TURNED_IN
	if completed_quests.has(quest_id):
		return QuestStatus.COMPLETE
	if active_quests.has(quest_id):
		return active_quests[quest_id].status
	return QuestStatus.AVAILABLE

func can_start_quest(quest_id: String) -> bool:
	return is_quest_available(quest_id)

func can_turn_in_quest(quest_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	return active_quests[quest_id].status == QuestStatus.COMPLETE

func is_quest_available(quest_id: String) -> bool:
	if not all_quests.has(quest_id):
		return false
	if active_quests.has(quest_id) or completed_quests.has(quest_id) or turned_in_quests.has(quest_id):
		return false
	
	var quest_data = all_quests[quest_id]
	if quest_data.has("prerequisites"):
		for prereq in quest_data.prerequisites:
			if not turned_in_quests.has(prereq):
				return false
	return true

func _get_game_manager() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/GameManager")
