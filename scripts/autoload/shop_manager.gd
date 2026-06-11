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
	return DataRegistry.get_shop(shop_id)

func buy_item(item_id: String, quantity: int = 1) -> bool:
	if not is_shop_open or player_inventory == null or quantity <= 0:
		return false
	
	# Find item in shop
	var shop_item: Dictionary = {}
	for item in current_shop.get("items", current_shop.get("inventory", [])):
		if str(item.get("item_id", "")) == item_id:
			shop_item = item
			break
	
	if shop_item.is_empty():
		return false
	
	# Check stock
	var stock := int(shop_item.get("quantity", shop_item.get("stock", -1)))
	if stock != -1 and stock < quantity:
		return false
	
	# Calculate price
	var unit_price := int(shop_item.get("buy_price", shop_item.get("price", 0)))
	if unit_price <= 0:
		var item_for_price = player_inventory.get_item_by_id(item_id)
		unit_price = item_for_price.buy_price if item_for_price else 0
	var total_price := unit_price * quantity
	
	# Check player gold
	if player_inventory.gold < total_price:
		return false

	var item_data = player_inventory.load_item_data(item_id)
	if item_data == null:
		return false
	
	var preview: Dictionary = player_inventory.preview_add_item(item_data, quantity)
	if int(preview.get("accepted", 0)) != quantity:
		return false
	var add_result: Dictionary = player_inventory.add_item_detailed(item_data, quantity)
	if int(add_result.get("accepted", 0)) != quantity:
		if int(add_result.get("accepted", 0)) > 0:
			player_inventory.remove_item_by_id(item_id, int(add_result.get("accepted", 0)))
		return false
	if not player_inventory.remove_gold(total_price):
		player_inventory.remove_item_by_id(item_id, quantity)
		return false
	
	# Reduce shop stock
	if stock != -1:
		shop_item["quantity"] = stock - quantity
	
	item_bought.emit(item_id, quantity, total_price)
	AudioManager.play_sfx("item_pickup")
	
	return true

func sell_item(item_id: String, quantity: int = 1) -> bool:
	if not is_shop_open or player_inventory == null or quantity <= 0:
		return false
	
	# Check if player has item
	if not player_inventory.has_item_id(item_id, quantity):
		return false
	
	# Calculate sell price
	var buy_rate = current_shop.get("buy_rate", 0.5)
	var item_data = player_inventory.get_item_by_id(item_id)
	if item_data == null:
		return false
	var sell_price = int(item_data.sell_price if item_data.sell_price > 0 else item_data.buy_price * buy_rate) * quantity
	
	# Remove item from player inventory
	if not player_inventory.remove_item_by_id(item_id, quantity):
		return false
	
	# Add gold
	player_inventory.add_gold(sell_price)
	
	item_sold.emit(item_id, quantity, sell_price)
	AudioManager.play_sfx("menu_select")
	
	return true

func get_shop_items() -> Array:
	if not is_shop_open:
		return []
	return current_shop.get("items", current_shop.get("inventory", []))

func get_shop_name() -> String:
	if not is_shop_open:
		return ""
	return current_shop.get("shop_name", current_shop.get("name", "Shop"))
