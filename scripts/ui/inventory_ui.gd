extends Control

signal item_selected(item: ItemData)
signal item_equipped(item: ItemData)

@onready var item_grid: GridContainer = $Panel/ItemGrid
@onready var equipment_slots: HBoxContainer = $Panel/EquipmentSlots
@onready var close_button: Button = $Panel/CloseButton
@onready var item_info: Panel = $ItemInfoPanel
@onready var info_name: Label = $ItemInfoPanel/ItemName
@onready var info_desc: Label = $ItemInfoPanel/ItemDescription
@onready var equip_button: Button = $ItemInfoPanel/EquipButton

var player: Player = null
var selected_item: ItemData = null
var slot_buttons: Array = []

func _ready():
	hide()
	item_info.hide()
	close_button.pressed.connect(_on_close_pressed)
	equip_button.pressed.connect(_on_equip_pressed)

func open(player_ref: Player) -> void:
	player = player_ref
	if not player:
		return
	
	player.inventory.inventory_changed.connect(_update_inventory)
	player.inventory.equipment_changed.connect(_update_equipment)
	
	_update_inventory()
	_update_equipment()
	show()

func close() -> void:
	if player:
		player.inventory.inventory_changed.disconnect(_update_inventory)
		player.inventory.equipment_changed.disconnect(_update_equipment)
	
	player = null
	selected_item = null
	item_info.hide()
	hide()

func _update_inventory() -> void:
	# Clear existing buttons
	for child in item_grid.get_children():
		child.queue_free()
	slot_buttons.clear()
	
	if not player:
		return
	
	# Create slot buttons
	for i in range(player.inventory.items.size()):
		var slot_data = player.inventory.items[i]
		var button = Button.new()
		button.custom_minimum_size = Vector2(50, 50)
		
		if slot_data.item != null:
			button.text = slot_data.item.item_name.substr(0, 2)
			button.tooltip_text = slot_data.item.item_name + " x" + str(slot_data.quantity)
			button.pressed.connect(_on_slot_pressed.bind(slot_data.item))
		else:
			button.disabled = true
		
		item_grid.add_child(button)
		slot_buttons.append(button)

func _update_equipment() -> void:
	# Clear existing
	for child in equipment_slots.get_children():
		child.queue_free()
	
	if not player:
		return
	
	# Create equipment slot buttons
	for slot_name in player.inventory.equipment.keys():
		var item = player.inventory.equipment[slot_name]
		var button = Button.new()
		button.custom_minimum_size = Vector2(60, 60)
		button.text = slot_name.capitalize()
		
		if item != null:
			button.text = item.item_name
			button.tooltip_text = item.item_name
		else:
			button.disabled = true
		
		equipment_slots.add_child(button)

func _on_slot_pressed(item: ItemData) -> void:
	selected_item = item
	item_info.show()
	info_name.text = item.item_name
	info_desc.text = item.description
	
	# Show equip button only for weapons
	# Check using get_script() or property existence
	if item.get("weapon_type") != null:
		equip_button.show()
	else:
		equip_button.hide()

func _on_equip_pressed() -> void:
	if not player or not selected_item:
		return
	
	# Check if it's a weapon by checking for weapon_type property
	if selected_item.get("weapon_type") != null:
		player.inventory.equip_item(selected_item, "weapon")
		item_info.hide()

func _on_close_pressed() -> void:
	close()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		close()
