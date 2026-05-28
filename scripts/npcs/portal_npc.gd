extends NPC
class_name PortalNPC

@export var available_maps: Array[Dictionary] = [
	{"id": "fields", "name": "Eastern Fields", "level_req": 1},
	{"id": "swamp", "name": "Murky Swamp", "level_req": 5},
	{"id": "cave", "name": "Dark Cave", "level_req": 8},
	{"id": "dungeon", "name": "Ancient Dungeon", "level_req": 12}
]

var map_selector: Control = null

func _ready():
	super._ready()
	npc_id = "portal_master"
	npc_name = "Portal Master"
	add_to_group("portal")

func _input(event):
	if player_in_range and event.is_action_pressed("interact"):
		_open_map_selector()

func _open_map_selector():
	if map_selector and map_selector.visible:
		map_selector.hide()
		return
	
	if not map_selector:
		map_selector = preload("res://scenes/ui/map_selector.tscn").instantiate()
		add_child(map_selector)
		map_selector.map_selected.connect(_on_map_selected)
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		map_selector.open(player.stats.level, available_maps)

func _on_map_selected(map_id: String):
	map_selector.hide()
	MapManager.change_map(map_id)
