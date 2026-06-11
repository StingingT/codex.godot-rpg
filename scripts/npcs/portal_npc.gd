extends NPC
class_name PortalNPC

@export var use_custom_map_list: bool = false
@export var available_maps: Array[Dictionary] = []

var map_selector: MapSelector = null

func _ready():
	super._ready()
	npc_id = "portal_master"
	npc_name = "Portal Master"
	add_to_group("portal")

func _input(event):
	if player_in_range and event.is_action_pressed("interact") and not (event is InputEventKey and event.is_echo()):
		_open_map_selector()

func _open_map_selector():
	if map_selector and map_selector.control.visible:
		map_selector.control.hide()
		return
	
	if not map_selector:
		map_selector = preload("res://scenes/ui/map_selector.tscn").instantiate()
		add_child(map_selector)
		map_selector.map_selected.connect(_on_map_selected)
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var travel_maps := DataRegistry.get_travel_maps()
		if use_custom_map_list and not available_maps.is_empty():
			travel_maps = available_maps
		map_selector.open(player.stats.level, travel_maps)

func _on_map_selected(map_id: String):
	map_selector.control.hide()
	MapManager.change_map(map_id)
