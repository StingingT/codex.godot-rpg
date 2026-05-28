extends Control

@onready var title_label: Label = $Panel/Title
@onready var entries_list: VBoxContainer = $Panel/Entries
@onready var close_button: Button = $Panel/CloseButton
@onready var refresh_button: Button = $Panel/RefreshButton

var entry_labels: Array = []

func _ready():
	hide()
	close_button.pressed.connect(_on_close)
	refresh_button.pressed.connect(_on_refresh)
	SupabaseClient.leaderboard_loaded.connect(_on_leaderboard_loaded)

func _input(event):
	if visible and event.is_action_pressed("pause"):
		_on_close()

func show_leaderboard():
	show()
	_clear_entries()
	title_label.text = "Leaderboard - Loading..."
	SupabaseClient.get_leaderboard()
	GameManager.pause_game()

func _on_leaderboard_loaded(entries: Array):
	title_label.text = "Leaderboard - Top Players"
	_clear_entries()
	
	for entry in entries:
		var label = Label.new()
		var text = "#%d %s - Level %d (Kills: %d)" % [
			entry.rank,
			entry.player_name,
			entry.level,
			entry.monsters_killed
		]
		label.text = text
		
		# Highlight the player
		if entry.player_name == "You":
			label.add_theme_color_override("font_color", Color.YELLOW)
		
		entries_list.add_child(label)
		entry_labels.append(label)

func _clear_entries():
	for label in entry_labels:
		label.queue_free()
	entry_labels.clear()

func _on_refresh():
	_clear_entries()
	title_label.text = "Leaderboard - Loading..."
	SupabaseClient.get_leaderboard()

func _on_close():
	hide()
	GameManager.resume_game()
