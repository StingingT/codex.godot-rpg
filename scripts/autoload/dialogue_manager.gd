extends Node

signal dialogue_started(dialogue_id: String)
signal dialogue_line_shown(speaker: String, text: String, choices: Array)
signal dialogue_choice_presented(choices: Array)
signal dialogue_ended
signal dialogue_action_triggered(action: String)

var current_dialogue: Dictionary = {}
var current_line_index: int = 0
var is_dialogue_active: bool = false
var _lines_shown_count: int = 0  # Safety counter to prevent infinite loops
const MAX_LINES_PER_DIALOGUE: int = 100  # Maximum lines before auto-ending

const DIALOGUE_PATH = "res://data/dialogue/"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_dialogue(dialogue_id: String) -> void:
	var dialogue_data = _load_dialogue(dialogue_id)
	if dialogue_data.is_empty():
		push_error("Dialogue not found: " + dialogue_id)
		# Still emit ended signal in case game was paused
		dialogue_ended.emit()
		return
	
	current_dialogue = dialogue_data
	current_line_index = 0
	_lines_shown_count = 0  # Reset safety counter
	is_dialogue_active = true
	
	GameManager.pause_game()
	dialogue_started.emit(dialogue_id)
	
	_show_current_line()

func _load_dialogue(dialogue_id: String) -> Dictionary:
	var file_path = DIALOGUE_PATH + dialogue_id + ".json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			return json.data
	return {}

func _show_current_line() -> void:
	# Safety check: prevent infinite loops
	_lines_shown_count += 1
	if _lines_shown_count > MAX_LINES_PER_DIALOGUE:
		push_warning("Dialogue exceeded maximum line count, auto-ending")
		end_dialogue()
		return
	
	# Support both "lines" and "dialogue" keys
	var lines = current_dialogue.get("lines", current_dialogue.get("dialogue", []))
	if current_line_index >= lines.size():
		end_dialogue()
		return
	
	var line = lines[current_line_index]
	var speaker = line.get("speaker", "")
	var text = line.get("text", "")
	var choices = line.get("choices", [])
	
	# Process any action
	if line.has("action"):
		_process_action(line.action)
	
	if choices.size() > 0:
		dialogue_choice_presented.emit(choices)
	else:
		dialogue_line_shown.emit(speaker, text, [])

func advance_dialogue(choice_index: int = -1) -> void:
	if not is_dialogue_active:
		return
	
	var lines = current_dialogue.get("lines", current_dialogue.get("dialogue", []))
	if current_line_index >= lines.size():
		end_dialogue()
		return
	
	var line = lines[current_line_index]
	var choices = line.get("choices", [])
	var previous_line_index = current_line_index
	
	if choices.size() > 0 and choice_index >= 0 and choice_index < choices.size():
		# Follow choice path
		var choice = choices[choice_index]
		var next_line = choice.get("next", -1)
		# Ensure next_line is a valid integer index
		if next_line is int and next_line >= 0 and next_line < lines.size():
			current_line_index = next_line
		else:
			current_line_index += 1
	else:
		# Auto-advance or follow next pointer
		var next_line = line.get("next", -1)
		if next_line is int and next_line >= 0 and next_line < lines.size():
			current_line_index = next_line
		else:
			current_line_index += 1
	
	# Safety check: prevent infinite loops
	if current_line_index == previous_line_index:
		current_line_index += 1
	
	_show_current_line()

func _process_action(action: String) -> void:
	dialogue_action_triggered.emit(action)
	
	# Parse common actions
	if action.begins_with("start_quest:"):
		var quest_id = action.split(":")[1]
		QuestManager.start_quest(quest_id)
	elif action.begins_with("complete_quest:"):
		var quest_id = action.split(":")[1]
		QuestManager.complete_quest(quest_id)
	elif action.begins_with("open_shop:"):
		var shop_id = action.split(":")[1]
		# Get player inventory
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_node("Inventory"):
			var inv = player.get_node("Inventory")
			ShopManager.open_shop(shop_id, inv)

func end_dialogue() -> void:
	is_dialogue_active = false
	current_dialogue = {}
	current_line_index = 0
	dialogue_ended.emit()
	GameManager.resume_game()
