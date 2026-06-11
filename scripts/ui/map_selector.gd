extends CanvasLayer
class_name MapSelector

const RPGUIStyle := preload("res://scripts/ui/rpg_ui_style.gd")

signal map_selected(map_id: String)

@onready var control: Control = $Control
@onready var panel: Panel = $Control/Panel
@onready var title_label: Label = $Control/Panel/TitleLabel
@onready var map_list: ItemList = $Control/Panel/MapList
@onready var close_button: Button = $Control/Panel/CloseButton
@onready var info_label: Label = $Control/Panel/InfoLabel

var player_level: int = 1
var maps_data: Array[Dictionary] = []

func _ready():
	_apply_style()
	control.hide()
	close_button.pressed.connect(_on_close_pressed)
	map_list.item_selected.connect(_on_map_selected)

func _apply_style() -> void:
	RPGUIStyle.apply_screen(control)
	RPGUIStyle.apply_panel(panel, true)
	RPGUIStyle.apply_title(title_label, 20)
	RPGUIStyle.apply_item_list(map_list)
	RPGUIStyle.apply_label(info_label, true)
	RPGUIStyle.apply_button(close_button)

func open(level: int, available_maps: Array[Dictionary]):
	player_level = level
	maps_data = available_maps
	_populate_map_list()
	control.show()

func _populate_map_list():
	map_list.clear()
	
	for map_data in maps_data:
		var map_id = map_data.get("id", "")
		var map_name = map_data.get("name", "Unknown")
		var level_req = map_data.get("level_req", 1)
		
		var display_text = "%s (Level %d+)" % [map_name, level_req]
		
		if player_level >= level_req:
			map_list.add_item(display_text)
			map_list.set_item_metadata(map_list.item_count - 1, map_id)
		else:
			map_list.add_item(display_text + " [LOCKED]")
			map_list.set_item_disabled(map_list.item_count - 1, true)

func _on_map_selected(index: int):
	if map_list.is_item_disabled(index):
		return
	
	var map_id = map_list.get_item_metadata(index)
	map_selected.emit(map_id)
	control.hide()

func _on_close_pressed():
	control.hide()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel") and control.visible:
		control.hide()
