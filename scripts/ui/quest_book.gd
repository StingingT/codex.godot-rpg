extends CanvasLayer
class_name QuestBook

@onready var control: Control = $Control
@onready var book_panel: Panel = $Control/BookPanel
@onready var title_label: Label = $Control/BookPanel/TitleLabel
@onready var quest_title: Label = $Control/BookPanel/LeftPage/QuestTitle
@onready var quest_description: Label = $Control/BookPanel/LeftPage/QuestDescription
@onready var progress_label: Label = $Control/BookPanel/LeftPage/ProgressLabel
@onready var status_label: Label = $Control/BookPanel/LeftPage/StatusLabel
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
	
	quest_title.text = quest_npc.quest_name
	
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
		quest_description.text = "You have defeated the slimes! Return to claim your reward."
		status_label.text = "Status: Ready to Complete"
		progress_label.text = "Progress: %d/%d" % [required, required]
		accept_button.visible = false
		complete_button.visible = true
	elif quest_npc.is_quest_active():
		quest_description.text = "Defeat 5 slimes in the Eastern Fields and return to the Quest Giver for your reward."
		status_label.text = "Status: In Progress"
		progress_label.text = "Progress: %d/%d" % [progress, required]
		accept_button.visible = false
		complete_button.visible = false
	else:
		quest_description.text = "Defeat 5 slimes in the Eastern Fields and return to the Quest Giver for your reward."
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

func _input(event):
	if control.visible and event.is_action_pressed("ui_cancel"):
		close()
