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
	var player_class = _create_player_class(class_type)
	
	# Start game with selected class
	GameManager.player_class = player_class
	MapManager.change_map("town", Vector2(320, 180))

func _create_player_class(class_type: int) -> PlayerClass:
	var pc = PlayerClass.new()
	pc.class_type = class_type
	
	match class_type:
		0:  # WARRIOR
			pc.player_class_name = "Warrior"
			pc.description = "Master of melee combat"
			pc.base_stats = {"max_hp": 120, "max_mana": 30, "attack": 15, "defense": 8, "speed": 75.0}
			pc.starting_skills = ["warrior_start"]
			
		1:  # RANGER
			pc.player_class_name = "Ranger"
			pc.description = "Master of ranged combat"
			pc.base_stats = {"max_hp": 90, "max_mana": 50, "attack": 12, "defense": 5, "speed": 90.0}
			pc.starting_skills = ["ranger_start"]
			
		2:  # MAGE
			pc.player_class_name = "Mage"
			pc.description = "Master of elemental magic"
			pc.base_stats = {"max_hp": 70, "max_mana": 100, "attack": 20, "defense": 3, "speed": 80.0}
			pc.starting_skills = ["mage_start"]
	
	return pc

func _on_back():
	class_selection.hide()
	$CenterContainer.show()

func _on_continue():
	if SaveManager.has_save(1):
		SaveManager.load_game(1)

func _on_quit():
	get_tree().quit()
