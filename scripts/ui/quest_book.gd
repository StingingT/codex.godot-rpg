extends CanvasLayer
class_name QuestBook

@onready var control: Control = $Control
@onready var book_panel: Panel = $Control/BookPanel
@onready var title_label: Label = $Control/BookPanel/TitleLabel
@onready var quest_title: Label = $Control/BookPanel/LeftPage/QuestTitle
@onready var quest_description: Label = $Control/BookPanel/LeftPage/QuestDescription
@onready var progress_label: Label = $Control/BookPanel/LeftPage/ProgressLabel
@onready var status_label: Label = $Control/BookPanel/LeftPage/StatusLabel
@onready var rewards_list: VBoxContainer = $Control/BookPanel/RightPage/RewardsList
@onready var accept_button: Button = $Control/BookPanel/RightPage/AcceptButton
@onready var complete_button: Button = $Control/BookPanel/RightPage/CompleteButton
@onready var close_button: Button = $Control/BookPanel/CloseButton

var quest_npc: QuestNPC = null
var player: Player = null

func _ready():
	control.hide()
	accept_button.pressed.connect(_on_accept_pressed)
	complete_button.pressed.connect(_on_complete_pressed)
	close_button.pressed.connect(close)

func open(p_quest_npc: QuestNPC, p_player: Player):
	quest_npc = p_quest_npc
	player = p_player
	
	_update_display()
	control.show()

func close():
	control.hide()

func _update_display():
	if not quest_npc or not player:
		return
	
	var quest_id = quest_npc.quest_id
	var quest_data = QuestManager.all_quests.get(quest_id, {})
	var objectives = quest_data.get("objectives", [])
	var required = 5
	if objectives.size() > 0:
		required = objectives[0].get("required", 5)
	
	quest_title.text = str(quest_data.get("title", quest_data.get("quest_name", quest_npc.quest_name)))
	_update_rewards(quest_data.get("rewards", {}))
	
	# Get current progress from QuestManager
	var progress = 0
	var active_quest = QuestManager.active_quests.get(quest_id, {})
	if active_quest.has("progress") and active_quest.progress.size() > 0:
		progress = active_quest.progress[0]
	
	# Update description based on quest state
	if quest_npc.is_quest_turned_in():
		quest_description.text = "You have completed this quest. Thank you for your help!"
		status_label.text = "Status: Completed"
		progress_label.text = "Progress: %d/%d" % [required, required]
		accept_button.visible = false
		complete_button.visible = false
	elif quest_npc.is_quest_completed():
		quest_description.text = "Objective complete. Return to claim your reward."
		status_label.text = "Status: Ready to Complete"
		progress_label.text = "Progress: %d/%d" % [required, required]
		accept_button.visible = false
		complete_button.visible = true
	elif quest_npc.is_quest_active():
		quest_description.text = str(quest_data.get("description", "Complete the listed objective."))
		status_label.text = "Status: In Progress"
		progress_label.text = "Progress: %d/%d" % [progress, required]
		accept_button.visible = false
		complete_button.visible = false
	else:
		quest_description.text = str(quest_data.get("description", "Complete the listed objective."))
		status_label.text = "Status: Not Started"
		progress_label.text = "Progress: 0/%d" % required
		accept_button.visible = true
		complete_button.visible = false

func _on_accept_pressed():
	if quest_npc:
		quest_npc._start_quest()
		_update_display()

func _on_complete_pressed():
	if quest_npc:
		quest_npc._turn_in_quest()
		_update_display()

func _update_rewards(rewards: Variant) -> void:
	for child in rewards_list.get_children():
		child.queue_free()
	if typeof(rewards) == TYPE_DICTIONARY:
		if rewards.has("gold"):
			_add_reward_label("%d Gold" % int(rewards.gold))
		if rewards.has("xp"):
			_add_reward_label("%d XP" % int(rewards.xp))
		for item_reward in rewards.get("items", []):
			if typeof(item_reward) == TYPE_DICTIONARY:
				_add_reward_label("%s x%d" % [str(item_reward.get("item_id", "Item")), int(item_reward.get("quantity", 1))])
	elif typeof(rewards) == TYPE_ARRAY:
		for reward in rewards:
			if typeof(reward) != TYPE_DICTIONARY:
				continue
			match str(reward.get("type", "")):
				"gold":
					_add_reward_label("%d Gold" % int(reward.get("amount", 0)))
				"xp":
					_add_reward_label("%d XP" % int(reward.get("amount", 0)))
				"item":
					_add_reward_label(str(reward.get("target", reward.get("item_id", "Item"))))
	if rewards_list.get_child_count() == 0:
		_add_reward_label("No reward")

func _add_reward_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	rewards_list.add_child(label)

func _input(event):
	if control.visible and event.is_action_pressed("ui_cancel"):
		close()
