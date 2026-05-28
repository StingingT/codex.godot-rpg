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
			_add_stack_badge(button, int(slot_data.quantity))
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
			button.pressed.connect(_on_equipment_pressed.bind(slot_name, item))
		else:
			button.disabled = false
		
		equipment_slots.add_child(button)

func _on_slot_pressed(item: ItemData) -> void:
	selected_item = item
	item_info.show()
	info_name.text = item.item_name
	info_desc.text = _build_item_description(item)
	
	if _get_equipment_slot(item) != "":
		equip_button.show()
		equip_button.text = "Equip"
	else:
		equip_button.hide()

func _on_equip_pressed() -> void:
	if not player or not selected_item:
		return
	
	var slot := _get_equipment_slot(selected_item)
	if equip_button.text == "Unequip":
		player.inventory.unequip_item(slot)
	elif slot != "":
		player.inventory.equip_item(selected_item, slot)
	_update_inventory()
	_update_equipment()
	item_info.hide()

func _on_equipment_pressed(slot_name: String, item: ItemData) -> void:
	selected_item = item
	item_info.show()
	info_name.text = item.item_name
	info_desc.text = _build_item_description(item)
	equip_button.show()
	equip_button.text = "Unequip"

func _get_equipment_slot(item: ItemData) -> String:
	if item == null:
		return ""
	if item.get("weapon_type") != null:
		return "weapon"
	if item.get("armor_type") != null:
		return "helmet" if int(item.get("armor_type")) == 1 else "armor"
	if int(item.get("attack_bonus")) > 0:
		return "accessory"
	return ""

func _build_item_description(item: ItemData) -> String:
	var desc := item.description + "\n\n"
	if item.get("damage"):
		desc += "Increases damage by: +%d\n" % int(item.get("damage"))
	if item.get("attack_speed"):
		desc += "Attack speed: %.1fx\n" % float(item.get("attack_speed"))
	if item.get("defense"):
		desc += "Increases defense by: +%d\n" % int(item.get("defense"))
	if item.get("vitality_bonus"):
		desc += "Vitality bonus: +%d\n" % int(item.get("vitality_bonus"))
	if item.get("hp_bonus"):
		desc += "Increases max HP by: +%d\n" % int(item.get("hp_bonus"))
	if item.get("attack_bonus"):
		desc += "Increases attack by: +%d\n" % int(item.get("attack_bonus"))
	if item.get("heal_amount"):
		desc += "Heals: %d HP\n" % int(item.get("heal_amount"))
	if item.get("mana_amount"):
		desc += "Restores: %d Mana\n" % int(item.get("mana_amount"))
	if desc.ends_with("\n\n"):
		desc += "No stat changes."
	return desc

func _on_close_pressed() -> void:
	close()

func _add_stack_badge(button: Button, quantity: int) -> void:
	if quantity <= 1:
		return
	var badge := Label.new()
	badge.text = str(quantity)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color.WHITE)
	badge.add_theme_color_override("font_shadow_color", Color.BLACK)
	badge.add_theme_constant_override("shadow_offset_x", 1)
	badge.add_theme_constant_override("shadow_offset_y", 1)
	badge.anchor_right = 1.0
	badge.anchor_bottom = 1.0
	badge.offset_left = 2.0
	badge.offset_top = 2.0
	badge.offset_right = -4.0
	badge.offset_bottom = -2.0
	button.add_child(badge)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		close()
