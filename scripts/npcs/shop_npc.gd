extends NPC
class_name ShopNPC

@export var shop_id: String = "general_store"
@export var shop_name: String = "General Store"

var shop_ui: Control = null

func _ready():
	super._ready()
	npc_id = "shopkeeper"
	npc_name = "Shopkeeper"

func _input(event):
	if player_in_range and event.is_action_pressed("interact"):
		if not DialogueManager.is_dialogue_active:
			_open_shop()

func _open_shop():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Create shop UI if not exists
	if not shop_ui:
		shop_ui = preload("res://scenes/ui/shop_ui.tscn").instantiate()
		get_tree().current_scene.add_child(shop_ui)
	
	# Load shop data
	var shop_data = _load_shop_data()
	
	# Open shop with player inventory
	shop_ui.open(shop_data, player.inventory)

func _load_shop_data() -> Dictionary:
	var file_path = "res://data/shops/" + shop_id + ".json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			return json.data
	
	# Return default shop if file not found
	return {
		"shop_id": shop_id,
		"shop_name": shop_name,
		"items": [
			{"item_id": "bronze_sword", "buy_price": 100, "sell_price": 50, "quantity": -1},
			{"item_id": "bronze_armor", "buy_price": 200, "sell_price": 100, "quantity": -1}
		]
	}
