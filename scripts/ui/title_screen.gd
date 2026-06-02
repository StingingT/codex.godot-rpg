extends Control

@onready var new_game_button: Button = $CenterContainer/VBoxContainer/NewGameButton
@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var class_selection: Control = $ClassSelection
@onready var warrior_button: Button = $ClassSelection/WarriorButton
@onready var ranger_button: Button = $ClassSelection/RangerButton
@onready var mage_button: Button = $ClassSelection/MageButton
@onready var back_button: Button = $ClassSelection/BackButton

var selected_class: int = 0  # 0 = WARRIOR, 1 = RANGER, 2 = MAGE

func _ready():
	new_game_button.pressed.connect(_on_new_game)
	continue_button.pressed.connect(_on_continue)
	quit_button.pressed.connect(_on_quit)
	
	warrior_button.pressed.connect(_on_class_selected.bind(0))
	ranger_button.pressed.connect(_on_class_selected.bind(1))
	mage_button.pressed.connect(_on_class_selected.bind(2))
	back_button.pressed.connect(_on_back)
	
	# Check if save exists
	continue_button.disabled = not SaveManager.has_save(1)
	
	class_selection.hide()

func _on_new_game():
	# Show class selection
	class_selection.show()
	$CenterContainer.hide()

func _on_class_selected(class_type: int):
	selected_class = class_type
	
	# Create player class data
	var player_class := DataRegistry.create_player_class(class_type)
	
	# Start game with selected class
	GameManager.player_class = player_class
	MapManager.change_map("town", Vector2(320, 180))

func _on_back():
	class_selection.hide()
	$CenterContainer.show()

func _on_continue():
	if SaveManager.has_save(1) and SaveManager.load_game(1):
		var map_id := GameManager.current_map_id if GameManager.current_map_id != "" else "town"
		MapManager.change_map(map_id)

func _on_quit():
	get_tree().quit()
