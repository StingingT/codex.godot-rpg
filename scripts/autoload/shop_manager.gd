extends Node

signal shop_opened(shop_id: String)
signal shop_closed
signal item_bought(item_id: String, quantity: int, price: int)
signal item_sold(item_id: String, quantity: int, price: int)

const SHOPS_PATH = "res://data/shops/"

var current_shop: Dictionary = {}
var player_inventory = null
var is_shop_open: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func open_shop(shop_id: String, player_inv) -> bool:
	var shop_data = _load_shop(shop_id)
	if shop_data.is_empty():
		return false
	
	current_shop = shop_data
	player_inventory = player_inv
	is_shop_open = true
	
	shop_opened.emit(shop_id)
	GameManager.pause_game()
	
	return true

func close_shop() -> void:
	is_shop_open = false
	current_shop = {}
	player_inventory = null
	
	shop_closed.emit()
	GameManager.resume_game()

func _load_shop(shop_id: String) -> Dictionary:
	var file_path = SHOPS_PATH + shop_id + ".json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			return json.data
	return {}

func buy_item(item_id: String, quantity: int = 1) -> bool:
	if not is_shop_open:
		return false
	
	# Find item in shop
	var shop_item = null
	for item in current_shop.inventory:
		if item.item_id == item_id:
			shop_item = item
			break
	
	if not shop_item:
		return false
	
	# Check stock
	if shop_item.stock != -1 and shop_item.stock < quantity:
		return false
	
	# Calculate price
	var total_price = shop_item.price * quantity
	
	# Check player gold
	if player_inventory.gold < total_price:
		return false
	
	# Deduct gold
	player_inventory.remove_gold(total_price)
	
	# Add item to player inventory
	# TODO: Load actual item data and add to inventory
	# For now, just emit signal
	
	# Reduce shop stock
	if shop_item.stock != -1:
		shop_item.stock -= quantity
	
	item_bought.emit(item_id, quantity, total_price)
	AudioManager.play_sfx("item_pickup")
	
	return true

func sell_item(item_id: String, quantity: int = 1) -> bool:
	if not is_shop_open:
		return false
	
	# Check if player has item
	# TODO: Check actual inventory
	
	# Calculate sell price
	var buy_rate = current_shop.get("buy_rate", 0.5)
	# TODO: Get item value and calculate sell price
	var sell_price = int(100 * buy_rate) * quantity  # Placeholder
	
	# Remove item from player inventory
	# TODO: Remove from actual inventory
	
	# Add gold
	player_inventory.add_gold(sell_price)
	
	item_sold.emit(item_id, quantity, sell_price)
	AudioManager.play_sfx("menu_select")
	
	return true

func get_shop_items() -> Array:
	if not is_shop_open:
		return []
	return current_shop.get("inventory", [])

func get_shop_name() -> String:
	if not is_shop_open:
		return ""
	return current_shop.get("name", "Shop")
