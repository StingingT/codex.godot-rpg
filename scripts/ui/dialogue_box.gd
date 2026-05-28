extends Control

@onready var dialogue_panel: Panel = $DialoguePanel
@onready var portrait: TextureRect = $DialoguePanel/Portrait
@onready var speaker_label: Label = $DialoguePanel/SpeakerLabel
@onready var text_label: Label = $DialoguePanel/TextLabel
@onready var choices_container: VBoxContainer = $DialoguePanel/ChoicesContainer
@onready var continue_indicator: Label = $DialoguePanel/ContinueIndicator

var typing_speed: float = 0.03
var is_typing: bool = false
var current_text: String = ""
var current_choices: Array = []

func _ready():
	hide()
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_line_shown.connect(_on_dialogue_line_shown)
	DialogueManager.dialogue_choice_presented.connect(_on_dialogue_choice_presented)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		if is_typing:
			# Skip typing
			text_label.text = current_text
			is_typing = false
			_show_continue_or_choices()
		else:
			# Advance dialogue
			if current_choices.size() == 0:
				DialogueManager.advance_dialogue()

func _on_dialogue_started(_dialogue_id: String):
	show()
	continue_indicator.hide()
	_clear_choices()

func _on_dialogue_line_shown(speaker: String, text: String, choices: Array):
	speaker_label.text = speaker
	current_text = text
	current_choices = choices
	
	# Start typing effect
	is_typing = true
	text_label.text = ""
	continue_indicator.hide()
	
	# Use a safer typing approach with maximum iterations
	var max_iterations = text.length()
	for i in range(max_iterations):
		if not is_typing or not is_instance_valid(self) or not visible:
			break
		if i >= text.length():
			break
		text_label.text += text[i]
		await get_tree().create_timer(typing_speed).timeout
		# Extra safety check after await
		if not is_instance_valid(self):
			return
	
	is_typing = false
	_show_continue_or_choices()

func _on_dialogue_choice_presented(choices: Array):
	current_choices = choices
	_create_choice_buttons(choices)

func _on_dialogue_ended():
	hide()
	_clear_choices()

func _show_continue_or_choices():
	if current_choices.size() > 0:
		_create_choice_buttons(current_choices)
	else:
		continue_indicator.show()

func _create_choice_buttons(choices: Array):
	continue_indicator.hide()
	_clear_choices()
	
	for i in range(choices.size()):
		var button = Button.new()
		button.text = choices[i].text
		button.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(button)

func _on_choice_selected(index: int):
	_clear_choices()
	DialogueManager.advance_dialogue(index)

func _clear_choices():
	for child in choices_container.get_children():
		child.queue_free()
