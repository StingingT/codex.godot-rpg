extends NPC
class_name QuestNPC

@export var quest_id: String = "kill_slimes"
@export var quest_name: String = "Kill 5 Slimes"
@export var quest_chain: Array[String] = ["kill_slimes", "hunt_skeletons"]

var quest_book: QuestBook = null

func _ready():
	super._ready()
	npc_id = "quest_giver"
	npc_name = "Quest Giver"
	_refresh_current_quest()
	
	# Connect to quest manager signals
	QuestManager.quest_started.connect(_on_quest_started)
	QuestManager.quest_updated.connect(_on_quest_updated)
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_turned_in.connect(_on_quest_turned_in)

func _input(event):
	if player_in_range and event.is_action_pressed("interact") and not (event is InputEventKey and event.is_echo()):
		if quest_book and quest_book.control.visible:
			quest_book.close()
		else:
			_open_quest_book()

func _open_quest_book():
	_refresh_current_quest()
	if not quest_book:
		quest_book = preload("res://scenes/ui/quest_book.tscn").instantiate()
		get_tree().root.add_child(quest_book)
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		quest_book.open(self, player)

func _start_quest():
	if QuestManager.start_quest(quest_id):
		GameManager.show_notification("Quest started: %s" % quest_name)
		_update_indicator()

func _turn_in_quest():
	if QuestManager.turn_in_quest(quest_id):
		GameManager.show_notification(_build_reward_text(quest_id))
		_refresh_current_quest()
		_update_indicator()

func _on_quest_started(started_quest_id: String):
	if quest_chain.has(started_quest_id):
		_refresh_current_quest()
	if started_quest_id == quest_id and quest_book and quest_book.visible:
		quest_book._update_display()

func _on_quest_updated(updated_quest_id: String, _objective_index: int, progress: int):
	if updated_quest_id == quest_id:
		var quest_data = QuestManager.active_quests.get(quest_id, {})
		var objectives = quest_data.get("objectives", [])
		if objectives.size() > 0:
			var required = objectives[0].get("required", 5)
			GameManager.show_notification("Progress: %d/%d" % [progress, required])
		
		if quest_book and quest_book.visible:
			quest_book._update_display()

func _on_quest_completed(completed_quest_id: String):
	if completed_quest_id == quest_id:
		GameManager.show_notification("Quest completed! Return to Quest Giver.")
		_update_indicator()
		if quest_book and quest_book.visible:
			quest_book._update_display()

func _on_quest_turned_in(turned_in_quest_id: String):
	if quest_chain.has(turned_in_quest_id):
		_refresh_current_quest()
	if quest_book and quest_book.visible:
		quest_book._update_display()

func is_quest_available() -> bool:
	_refresh_current_quest()
	return QuestManager.is_quest_available(quest_id)

func is_quest_active() -> bool:
	_refresh_current_quest()
	return QuestManager.get_quest_status(quest_id) == QuestManager.QuestStatus.ACTIVE

func is_quest_completed() -> bool:
	_refresh_current_quest()
	return QuestManager.get_quest_status(quest_id) == QuestManager.QuestStatus.COMPLETE

func is_quest_turned_in() -> bool:
	_refresh_current_quest()
	return QuestManager.get_quest_status(quest_id) == QuestManager.QuestStatus.TURNED_IN

func get_kill_count() -> int:
	var quest_data = QuestManager.active_quests.get(quest_id, {})
	var progress = quest_data.get("progress", [])
	if progress.size() > 0:
		return progress[0]
	return 0

func _update_indicator():
	_refresh_current_quest()
	if is_quest_turned_in():
		indicator.text = "..."
		indicator.modulate = Color(0.5, 0.5, 0.5)
	elif is_quest_completed():
		indicator.text = "!"
		indicator.modulate = Color(1, 0.9, 0.2)  # Yellow
	elif is_quest_active():
		indicator.text = "?"
		indicator.modulate = Color(0.7, 0.7, 0.7)  # Gray
	else:
		indicator.text = "!"
		indicator.modulate = Color(0.3, 0.9, 0.3)  # Green

func _refresh_current_quest() -> void:
	if quest_chain.is_empty():
		_set_current_quest(quest_id)
		return
	for chain_quest_id in quest_chain:
		var status := QuestManager.get_quest_status(chain_quest_id)
		if status == QuestManager.QuestStatus.ACTIVE or status == QuestManager.QuestStatus.COMPLETE:
			_set_current_quest(chain_quest_id)
			return
	for chain_quest_id in quest_chain:
		if QuestManager.is_quest_available(chain_quest_id):
			_set_current_quest(chain_quest_id)
			return
	_set_current_quest(quest_chain[quest_chain.size() - 1])

func _set_current_quest(new_quest_id: String) -> void:
	quest_id = new_quest_id
	var quest_data: Dictionary = QuestManager.all_quests.get(quest_id, {})
	quest_name = str(quest_data.get("title", quest_data.get("quest_name", quest_name)))

func _build_reward_text(reward_quest_id: String) -> String:
	var quest_data: Dictionary = QuestManager.all_quests.get(reward_quest_id, {})
	var rewards = quest_data.get("rewards", {})
	if typeof(rewards) != TYPE_DICTIONARY:
		return "Quest reward received"
	return "Reward: %d Gold, %d XP" % [int(rewards.get("gold", 0)), int(rewards.get("xp", 0))]
