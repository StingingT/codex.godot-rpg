extends Control

const RPGUIStyle := preload("res://scripts/ui/rpg_ui_style.gd")

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
	_apply_style()
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

func _apply_style() -> void:
	RPGUIStyle.apply_screen(self)
	RPGUIStyle.apply_dark_panel($Background)
	RPGUIStyle.apply_title($TitleLabel, 32)
	RPGUIStyle.apply_title($ClassSelection/SelectClassLabel, 24)
	for button in [new_game_button, continue_button, quit_button, back_button]:
		RPGUIStyle.apply_button(button, RPGUIStyle.GOLD)
	warrior_button.text = "WARRIOR\nKnight Vanguard\nHigh HP & Defense"
	ranger_button.text = "RANGER\nWild Archer\nHigh Speed & Crit"
	mage_button.text = "MAGE\nArcane Scholar\nHigh Damage & Mana"
	_set_class_button_style(warrior_button, "res://assets/sprites/player/classes/knightlow_idle.png", RPGUIStyle.RED)
	_set_class_button_style(ranger_button, "res://assets/sprites/player/classes/archertheresa_idle.png", RPGUIStyle.GREEN)
	_set_class_button_style(mage_button, "res://assets/sprites/player/classes/mageted_idle.png", RPGUIStyle.BLUE)

func _set_class_button_style(button: Button, sprite_path: String, accent: Color) -> void:
	RPGUIStyle.apply_button(button, accent)
	button.icon = _make_class_icon(sprite_path)
	button.expand_icon = false

func _make_class_icon(sprite_path: String) -> Texture2D:
	var sheet := load(sprite_path) as Texture2D
	if sheet == null:
		return null
	var icon := AtlasTexture.new()
	icon.atlas = sheet
	icon.region = Rect2(96, 0, 48, 48)
	return icon

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
	MapManager.change_map_to_entry("custom_kit_town", "entry_default")

func _on_back():
	class_selection.hide()
	$CenterContainer.show()

func _on_continue():
	if SaveManager.has_save(1) and SaveManager.load_game(1):
		var map_id := GameManager.current_map_id if GameManager.current_map_id != "" else "custom_kit_town"
		MapManager.change_map(map_id)

func _on_quit():
	get_tree().quit()
