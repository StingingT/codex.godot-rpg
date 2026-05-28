extends Control

@onready var respawn_button: Button = $CenterContainer/VBoxContainer/RespawnButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var penalty_label: Label = $PenaltyLabel

var gold_penalty: int = 0

func _ready():
	respawn_button.pressed.connect(_on_respawn)
	quit_button.pressed.connect(_on_quit)
	
	# Show gold penalty if any
	if gold_penalty > 0:
		penalty_label.text = "You lost %d gold..." % gold_penalty
	else:
		penalty_label.text = ""

func _on_respawn():
	# Heal player to full
	var player = get_tree().get_first_node_in_group("player")
	if player and player.stats:
		player.stats.current_hp = player.stats.get_max_hp()
		player.stats.current_mana = player.stats.get_max_mana()
		player.stats.hp_changed.emit(player.stats.current_hp, player.stats.get_max_hp())
		player.stats.mana_changed.emit(player.stats.current_mana, player.stats.get_max_mana())
	
	GameManager.resume_game()
	MapManager.change_map("town", Vector2(320, 180))
	queue_free()

func _on_quit():
	get_tree().quit()
