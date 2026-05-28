extends Control

@onready var shop_name_label: Label = $Panel/ShopName
@onready var gold_label: Label = $Panel/GoldLabel
@onready var tab_container: TabContainer = $Panel/TabContainer
@onready var shop_items_list: VBoxContainer = $Panel/TabContainer/Buy/ShopItems
@onready var player_items_list: VBoxContainer = $Panel/TabContainer/Sell/PlayerItems
@onready var item_info_panel: Panel = $Panel/ItemInfoPanel
@onready var item_name_label: Label = $Panel/ItemInfoPanel/ItemName
@onready var item_desc_label: Label = $Panel/ItemInfoPanel/ItemDescription
@onready var item_price_label: Label = $Panel/ItemInfoPanel/ItemPrice
@onready var action_button: Button = $Panel/ItemInfoPanel/ActionButton
@onready var close_button: Button = $Panel/CloseButton

var selected_shop_item: Dictionary = {}
var selected_player_item: ItemData = null
var shop_data: Dictionary = {}
var player_inventory: Inventory = null

func _ready():
	hide()
	action_button.pressed.connect(_on_action_pressed)
	close_button.pressed.connect(close)
	tab_container.tab_changed.connect(_on_tab_changed)

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		close()

func open(shop: Dictionary, inventory: Inventory):
	shop_data = shop
	player_inventory = inventory
	
	if player_inventory:
		# Only connect if not already connected
		if not player_inventory.gold_changed.is_connected(_update_gold_display):
			player_inventory.gold_changed.connect(_update_gold_display)
	
	_update_display()
	show()

func close():
	if player_inventory and player_inventory.gold_changed.is_connected(_update_gold_display):
		player_inventory.gold_changed.disconnect(_update_gold_display)
	hide()
	_clear_selection()

func _update_display():
	shop_name_label.text = shop_data.get("shop_name", "Shop")
	_update_gold_display()
	_update_shop_items()
	_update_player_items()

func _update_gold_display(_amount = null):
	if player_inventory:
		gold_label.text = "Gold: %d" % player_inventory.gold

func _update_shop_items():
	for child in shop_items_list.get_children():
		child.queue_free()
	
	var items = shop_data.get("items", [])
	for item_data in items:
		var item_id = item_data.get("item_id", "")
		var buy_price = item_data.get("buy_price", 100)
		
		var item = _load_item_data(item_id)
		if not item:
			continue
		
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 40)
		button.text = "%s - %dg" % [item.item_name, buy_price]
		button.pressed.connect(_on_shop_item_selected.bind(item_data, item))
		shop_items_list.add_child(button)

func _update_player_items():
	for child in player_items_list.get_children():
		child.queue_free()
	
	if not player_inventory:
		return
	
	for slot in player_inventory.items:
		if slot.item == null or slot.quantity == 0:
			continue
		
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 40)
		var sell_price = slot.item.sell_price
		button.text = "%s x%d - %dg" % [slot.item.item_name, slot.quantity, sell_price]
		button.pressed.connect(_on_player_item_selected.bind(slot.item))
		player_items_list.add_child(button)

func _on_tab_changed(tab: int):
	_clear_selection()

func _on_shop_item_selected(shop_item_data: Dictionary, item: ItemData):
	selected_shop_item = shop_item_data
	selected_player_item = null
	
	var buy_price = shop_item_data.get("buy_price", 100)
	
	item_name_label.text = item.item_name
	item_desc_label.text = item.description
	item_price_label.text = "Price: %d gold" % buy_price
	action_button.text = "Buy"
	
	var can_afford = player_inventory and player_inventory.gold >= buy_price
	action_button.disabled = not can_afford
	
	item_info_panel.show()

func _on_player_item_selected(item: ItemData):
	selected_player_item = item
	selected_shop_item = {}
	
	item_name_label.text = item.item_name
	item_desc_label.text = item.description
	item_price_label.text = "Sell Price: %d gold" % item.sell_price
	action_button.text = "Sell"
	action_button.disabled = false
	
	item_info_panel.show()

func _on_action_pressed():
	if selected_shop_item.size() > 0:
		_do_buy()
	elif selected_player_item != null:
		_do_sell()

func _do_buy():
	if selected_shop_item.is_empty() or not player_inventory:
		return
	
	var item_id = selected_shop_item.get("item_id", "")
	var buy_price = selected_shop_item.get("buy_price", 100)
	
	if player_inventory.gold < buy_price:
		return
	
	var item = _load_item_data(item_id)
	if not item:
		return
	
	if player_inventory.add_item(item, 1):
		player_inventory.remove_gold(buy_price)
		_update_display()
		_clear_selection()

func _do_sell():
	if selected_player_item == null or not player_inventory:
		return
	
	var sell_price = selected_player_item.sell_price
	
	if player_inventory.remove_item(selected_player_item, 1):
		player_inventory.add_gold(sell_price)
		_update_display()
		_clear_selection()

func _clear_selection():
	selected_shop_item = {}
	selected_player_item = null
	item_info_panel.hide()

func _load_item_data(item_id: String) -> ItemData:
	var file_path = "res://data/items/" + item_id + ".json"
	if not FileAccess.file_exists(file_path):
		return null
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		return null
	
	var data = json.data
	var item_type = data.get("item_type", 0)
	
	var item: ItemData
	
	if item_type == 0 or data.has("weapon_type"):
		var weapon = WeaponData.new()
		weapon.weapon_type = data.get("weapon_type", 0)
		weapon.damage = data.get("damage", 10)
		weapon.attack_speed = data.get("attack_speed", 1.0)
		item = weapon
	elif item_type == 1 or data.has("armor_type"):
		var armor = ArmorData.new()
		armor.armor_type = data.get("armor_type", 0)
		armor.defense = data.get("defense", 5)
		item = armor
	else:
		item = ItemData.new()
	
	item.item_id = data.get("item_id", item_id)
	item.item_name = data.get("item_name", "Unknown")
	item.description = data.get("description", "")
	item.item_type = item_type
	item.buy_price = data.get("buy_price", 100)
	item.sell_price = data.get("sell_price", 50)
	
	return item
