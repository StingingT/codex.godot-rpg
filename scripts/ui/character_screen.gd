extends Control

@onready var tab_container: TabContainer = $Panel/TabContainer
@onready var level_label: Label = $Panel/TabContainer/Stats/LevelLabel
@onready var xp_label: Label = $Panel/TabContainer/Stats/XPLabel
@onready var ap_label: Label = $Panel/TabContainer/Stats/APLabel
@onready var sp_label: Label = $Panel/TabContainer/Stats/SPLabel
@onready var stats_label: Label = $Panel/TabContainer/Stats/StatsLabel
@onready var attributes_label: Label = $Panel/TabContainer/Stats/AttributesLabel
@onready var ap_buttons_container: VBoxContainer = $Panel/TabContainer/Stats/APButtonsContainer
@onready var equipment_container: VBoxContainer = $Panel/TabContainer/Stats/EquipmentContainer
@onready var weapon_slot: Button = $Panel/TabContainer/Stats/EquipmentContainer/WeaponSlot
@onready var armor_slot: Button = $Panel/TabContainer/Stats/EquipmentContainer/ArmorSlot
@onready var helmet_slot: Button = $Panel/TabContainer/Stats/EquipmentContainer/HelmetSlot
@onready var accessory_slot: Button = $Panel/TabContainer/Stats/EquipmentContainer/AccessorySlot
@onready var equipment_stats_label: Label = $Panel/TabContainer/Stats/EquipmentStatsLabel
@onready var item_grid: GridContainer = $Panel/TabContainer/Inventory/ItemGrid
@onready var gold_label: Label = $Panel/TabContainer/Inventory/GoldLabel
@onready var item_info_panel: Panel = $Panel/TabContainer/Inventory/ItemInfoPanel
@onready var item_name_label: Label = $Panel/TabContainer/Inventory/ItemInfoPanel/ItemName
@onready var item_desc_label: Label = $Panel/TabContainer/Inventory/ItemInfoPanel/ItemDescription
@onready var equip_button: Button = $Panel/TabContainer/Inventory/ItemInfoPanel/EquipButton
@onready var close_button: Button = $Panel/CloseButton
@onready var context_menu: PopupMenu = $ContextMenu

# Skills tab nodes
@onready var skills_sp_label: Label = $Panel/TabContainer/Skills/SPLabel
@onready var skill_list: VBoxContainer = $Panel/TabContainer/Skills/SkillList
@onready var skill_info_panel: Panel = $Panel/TabContainer/Skills/SkillInfoPanel
@onready var skill_name_label: Label = $Panel/TabContainer/Skills/SkillInfoPanel/SkillName
@onready var skill_desc_label: Label = $Panel/TabContainer/Skills/SkillInfoPanel/SkillDescription
@onready var skill_unlock_button: Button = $Panel/TabContainer/Skills/SkillInfoPanel/UnlockButton

var player: Player = null
var selected_item: ItemData = null
var selected_equipment_slot: String = ""
var selected_slot_index: int = -1
var selected_skill: String = ""

# Simple skill list
var skills = {
	"power_attack": {
		"name": "Power Attack",
		"desc": "Increase attack damage by 10%",
		"cost": 1,
		"level_req": 1,
		"prereqs": [],
		"effect": {"stat": "attack", "mul": 0.10}
	},
	"heavy_strike": {
		"name": "Heavy Strike",
		"desc": "Increase attack damage by 15%",
		"cost": 2,
		"level_req": 5,
		"prereqs": ["power_attack"],
		"effect": {"stat": "attack", "mul": 0.15}
	},
	"toughness": {
		"name": "Toughness",
		"desc": "Increase max HP by 20%",
		"cost": 1,
		"level_req": 1,
		"prereqs": [],
		"effect": {"stat": "max_hp", "mul": 0.20}
	},
	"iron_skin": {
		"name": "Iron Skin",
		"desc": "Increase defense by 10%",
		"cost": 2,
		"level_req": 5,
		"prereqs": ["toughness"],
		"effect": {"stat": "defense", "mul": 0.10}
	},
	"swiftness": {
		"name": "Swiftness",
		"desc": "Increase speed by 10%",
		"cost": 1,
		"level_req": 1,
		"prereqs": [],
		"effect": {"stat": "speed", "mul": 0.10}
	},
	"quick_reflexes": {
		"name": "Quick Reflexes",
		"desc": "Increase attack speed",
		"cost": 2,
		"level_req": 5,
		"prereqs": ["swiftness"],
		"effect": {"stat": "attack_speed", "mul": 0.15}
	}
}

func _ready():
	hide()
	context_menu.id_pressed.connect(_on_context_menu_selected)
	tab_container.tab_changed.connect(_on_tab_changed)
	close_button.pressed.connect(close)
	equip_button.pressed.connect(_on_equip_button_pressed)
	
	# Connect equipment slot buttons
	weapon_slot.pressed.connect(_on_equipment_slot_pressed.bind("weapon"))
	armor_slot.pressed.connect(_on_equipment_slot_pressed.bind("armor"))
	helmet_slot.pressed.connect(_on_equipment_slot_pressed.bind("helmet"))
	accessory_slot.pressed.connect(_on_equipment_slot_pressed.bind("accessory"))
	weapon_slot.gui_input.connect(_on_equipment_slot_gui_input.bind("weapon"))
	armor_slot.gui_input.connect(_on_equipment_slot_gui_input.bind("armor"))
	helmet_slot.gui_input.connect(_on_equipment_slot_gui_input.bind("helmet"))
	accessory_slot.gui_input.connect(_on_equipment_slot_gui_input.bind("accessory"))
	
	# Connect AP distribution buttons
	ap_buttons_container.get_node("StrButton").pressed.connect(_on_ap_button_pressed.bind("str"))
	ap_buttons_container.get_node("DexButton").pressed.connect(_on_ap_button_pressed.bind("dex"))
	ap_buttons_container.get_node("VitButton").pressed.connect(_on_ap_button_pressed.bind("vit"))
	ap_buttons_container.get_node("IntButton").pressed.connect(_on_ap_button_pressed.bind("int"))
	ap_buttons_container.get_node("LckButton").pressed.connect(_on_ap_button_pressed.bind("lck"))
	
	# Connect skill unlock button
	skill_unlock_button.pressed.connect(_on_skill_unlock_pressed)
	
	# Build skill list
	_build_skill_list()

func _build_skill_list():
	for child in skill_list.get_children():
		child.queue_free()
	
	for skill_id in skills.keys():
		var skill = skills[skill_id]
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 28)
		button.add_theme_font_size_override("font_size", 14)
		button.text = skill.name
		button.pressed.connect(_on_skill_selected.bind(skill_id))
		skill_list.add_child(button)

func open(p_player: Player):
	player = p_player
	if not player:
		return
	
	_update_stats()
	_update_equipment()
	_update_inventory()
	_update_points()
	_update_ap_buttons()
	item_info_panel.hide()
	show()

func close():
	hide()

func _update_stats():
	if not player:
		return
	
	var stats = player.stats
	level_label.text = "Level: %d/20" % stats.level
	xp_label.text = "XP: %d / %d" % [stats.current_xp, stats.xp_to_next]
	
	# Update main stats label
	stats_label.text = "HP: %d/%d\nMana: %d/%d\nAtk: %d\nDef: %d\nSpd: %.1f" % [
		stats.current_hp, stats.get_max_hp(),
		stats.current_mana, stats.get_max_mana(),
		stats.get_total_attack(),
		stats.get_total_defense(),
		stats.get_total_speed()
	]
	
	# Update attributes label
	attributes_label.text = "STR: %d\nDEX: %d\nVIT: %d\nINT: %d\nLCK: %d" % [
		stats.get_distributed_ap("str"),
		stats.get_distributed_ap("dex"),
		stats.get_distributed_ap("vit"),
		stats.get_distributed_ap("int"),
		stats.get_distributed_ap("lck")
	]

func _update_ap_buttons():
	if not player:
		return
	
	var has_ap = player.stats.attribute_points > 0
	for child in ap_buttons_container.get_children():
		if child is Button:
			child.visible = has_ap

func _on_ap_button_pressed(stat: String):
	if not player:
		return
	
	if player.stats.distribute_ap(stat, 1):
		_update_stats()
		_update_points()
		_update_ap_buttons()
		player.stats.emit_stat_signals()

func _update_equipment():
	if not player or not player.inventory:
		return
	
	var equipment = player.inventory.equipment
	
	# Update weapon slot
	if equipment.weapon:
		weapon_slot.text = "Weapon: %s" % _short_item_name(equipment.weapon)
		weapon_slot.tooltip_text = equipment.weapon.item_name
	else:
		weapon_slot.text = "Weapon (Empty)"
		weapon_slot.tooltip_text = ""
	
	# Update armor slot
	if equipment.armor:
		armor_slot.text = "Armor: %s" % _short_item_name(equipment.armor)
		armor_slot.tooltip_text = equipment.armor.item_name
	else:
		armor_slot.text = "Armor (Empty)"
		armor_slot.tooltip_text = ""
	
	# Update helmet slot
	if equipment.helmet:
		helmet_slot.text = "Helmet: %s" % _short_item_name(equipment.helmet)
		helmet_slot.tooltip_text = equipment.helmet.item_name
	else:
		helmet_slot.text = "Helmet (Empty)"
		helmet_slot.tooltip_text = ""
	
	# Update accessory slot
	if equipment.accessory:
		accessory_slot.text = "Accessory: %s" % _short_item_name(equipment.accessory)
		accessory_slot.tooltip_text = equipment.accessory.item_name
	else:
		accessory_slot.text = "Accessory (Empty)"
		accessory_slot.tooltip_text = ""

	equipment_stats_label.text = _build_equipment_summary()

func _update_inventory():
	if not player or not player.inventory:
		return
	
	# Clear existing
	for child in item_grid.get_children():
		child.queue_free()
	
	# Update gold
	gold_label.text = "Gold: %d" % player.inventory.gold
	
	# Add inventory slots
	for slot in player.inventory.items:
		var button = Button.new()
		button.custom_minimum_size = Vector2(40, 40)
		button.add_theme_font_size_override("font_size", 13)
		
		if slot.item:
			button.text = slot.item.item_name.substr(0, 4)
			button.tooltip_text = "%s (x%d)" % [slot.item.item_name, slot.quantity]
			_add_stack_badge(button, int(slot.quantity))
			
			# Style based on item type
			match slot.item.item_type:
				ItemData.ItemType.WEAPON:
					button.modulate = Color(1.0, 0.8, 0.4)  # Gold
				ItemData.ItemType.ARMOR:
					button.modulate = Color(0.6, 0.8, 1.0)  # Blue
				ItemData.ItemType.CONSUMABLE:
					button.modulate = Color(0.4, 1.0, 0.4)  # Green
				_:
					button.modulate = Color.WHITE
			
			button.pressed.connect(_on_inventory_item_selected.bind(slot.item))
			button.gui_input.connect(_on_item_gui_input.bind(slot.item))
		else:
			button.disabled = true
			button.modulate = Color(0.3, 0.3, 0.3)
		
		item_grid.add_child(button)

func _update_points():
	if not player:
		return
	
	ap_label.text = "AP: %d" % player.stats.attribute_points
	sp_label.text = "SP: %d" % player.stats.skill_points

func _on_tab_changed(tab: int):
	if tab == 0:
		_update_stats()
		_update_equipment()
		_update_ap_buttons()
	elif tab == 1:
		_update_inventory()
	elif tab == 2:
		_update_skills()

func _update_skills():
	if not player:
		return
	
	# Update SP label from player.stats instead of player.skill_points
	if player.stats:
		skills_sp_label.text = "SP: %d" % player.stats.skill_points
	else:
		skills_sp_label.text = "SP: 0"
	
	# Update button colors based on unlock status
	var i = 0
	for skill_id in skills.keys():
		if i < skill_list.get_child_count():
			var button = skill_list.get_child(i)
			if player.unlocked_skills.has(skill_id):
				button.modulate = Color(0.3, 0.9, 0.3)  # Green
			else:
				button.modulate = Color(1, 1, 1)  # White
			i += 1

func _on_skill_selected(skill_id: String):
	selected_skill = skill_id
	var skill = skills[skill_id]
	
	skill_name_label.text = skill.name
	skill_desc_label.text = skill.desc + "\n\nCost: %d SP" % skill.cost
	
	# Check if already unlocked
	if player.unlocked_skills.has(skill_id):
		skill_unlock_button.text = "Unlocked"
		skill_unlock_button.disabled = true
	elif player.stats.skill_points < skill.cost:
		skill_unlock_button.text = "Need %d SP" % skill.cost
		skill_unlock_button.disabled = true
	elif player.stats.level < skill.level_req:
		skill_unlock_button.text = "Level %d Required" % skill.level_req
		skill_unlock_button.disabled = true
	else:
		# Check prerequisites
		var prereqs_met = true
		for prereq in skill.prereqs:
			if not player.unlocked_skills.has(prereq):
				prereqs_met = false
				break
		
		if not prereqs_met:
			skill_unlock_button.text = "Prerequisites Required"
			skill_unlock_button.disabled = true
		else:
			skill_unlock_button.text = "Unlock (%d SP)" % skill.cost
			skill_unlock_button.disabled = false
	
	skill_info_panel.show()

func _on_skill_unlock_pressed():
	if selected_skill == "" or not player:
		return
	
	var skill = skills[selected_skill]
	
	# Use player.stats.skill_points instead of player.skill_points
	if player.stats.skill_points >= skill.cost:
		player.stats.skill_points -= skill.cost
		player.unlocked_skills.append(selected_skill)
		
		# Apply effect
		var effect = skill.effect
		match effect.stat:
			"attack":
				player.stats.attack = int(player.stats.attack * (1 + effect.mul))
			"max_hp":
				player.stats.max_hp = int(player.stats.max_hp * (1 + effect.mul))
				player.stats.current_hp = player.stats.get_max_hp()
			"defense":
				player.stats.defense = int(player.stats.defense * (1 + effect.mul))
			"speed":
				player.stats.speed = player.stats.speed * (1 + effect.mul)
		player.stats.emit_stat_signals()
		
		_update_skills()
		_update_stats()
		_update_points()  # Update the SP display in stats tab too
		_on_skill_selected(selected_skill)

func _on_equipment_slot_pressed(slot_type: String):
	var equipped: ItemData = null
	match slot_type:
		"weapon": equipped = player.inventory.equipment.weapon
		"armor": equipped = player.inventory.equipment.armor
		"helmet": equipped = player.inventory.equipment.helmet
		"accessory": equipped = player.inventory.equipment.accessory
	
	if equipped:
		selected_item = equipped
		selected_equipment_slot = slot_type
		_show_equipment_item_info(equipped)
	else:
		selected_item = null
		selected_equipment_slot = ""
		equipment_stats_label.text = _build_equipment_summary()

func _on_equipment_slot_gui_input(event: InputEvent, slot_type: String) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var equipped := _get_equipped_item(slot_type)
			if equipped:
				selected_item = equipped
				selected_equipment_slot = slot_type
				_show_equipment_context_menu()

func _on_inventory_item_selected(item: ItemData):
	selected_item = item
	selected_equipment_slot = ""
	_show_item_info(item)
	equip_button.text = "Equip"
	equip_button.visible = _is_equippable(item)

func _on_item_gui_input(event: InputEvent, item: ItemData):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			selected_item = item
			selected_equipment_slot = ""
			_show_context_menu()

func _show_context_menu():
	if not selected_item:
		return
	
	context_menu.clear()
	
	if selected_item.item_type == ItemData.ItemType.CONSUMABLE:
		context_menu.add_item("Use", 0)
	elif _is_equippable(selected_item):
		context_menu.add_item("Equip", 0)
	
	context_menu.add_item("Drop", 1)
	context_menu.add_item("Examine", 2)
	
	context_menu.position = get_global_mouse_position()
	context_menu.popup()

func _show_equipment_context_menu() -> void:
	if not selected_item:
		return
	context_menu.clear()
	context_menu.add_item("Examine", 2)
	context_menu.add_item("Unequip", 3)
	context_menu.position = get_global_mouse_position()
	context_menu.popup()

func _on_context_menu_selected(id: int):
	if not selected_item or not player:
		return
	
	if selected_equipment_slot != "":
		match id:
			2:
				_show_equipment_item_info(selected_item)
			3:
				_unequip_selected_equipment()
		return

	match id:
		0: # Equip or Use
			if selected_item.get("weapon_type") != null:
				player.inventory.equip_item(selected_item, "weapon")
			elif selected_item.get("armor_type") != null:
				# Determine slot based on armor_type
				var armor_type = selected_item.get("armor_type")
				if armor_type == null:
					armor_type = 0
				var slot = "armor"
				if armor_type == 1:
					slot = "helmet"
				player.inventory.equip_item(selected_item, slot)
			elif selected_item.item_type == ItemData.ItemType.CONSUMABLE:
				_use_consumable(selected_item)
			elif int(selected_item.get("attack_bonus")) > 0:
				player.inventory.equip_item(selected_item, "accessory")
			_update_inventory()
			_update_equipment()
			_update_stats()
			if player.stats:
				player.stats.emit_stat_signals()
		1: # Drop
			_drop_selected_item()
		2: # Examine
			_show_item_info(selected_item)

func _on_equip_button_pressed():
	if not selected_item or not player:
		return
	
	if equip_button.text == "Unequip":
		# Unequip the item
		if selected_item.get("weapon_type") != null:
			player.inventory.unequip_item("weapon")
		elif selected_item.get("armor_type") != null:
			var armor_type = selected_item.get("armor_type")
			if armor_type == 1:
				player.inventory.unequip_item("helmet")
			else:
				player.inventory.unequip_item("armor")
		elif int(selected_item.get("attack_bonus")) > 0:
			player.inventory.unequip_item("accessory")
		
		_update_equipment()
		_update_inventory()
		_update_stats()
		if player.stats:
			player.stats.emit_stat_signals()
		item_info_panel.hide()
	else:
		# Equip the item
		_on_context_menu_selected(0)

func _use_consumable(item: ItemData):
	if not player or not item:
		return
	
	var consumed = false
	
	# Check for heal effect
	if item.get("heal_amount"):
		var heal = item.get("heal_amount")
		player.stats.heal(heal)
		GameManager.show_notification("Healed %d HP!" % heal)
		consumed = true
	
	# Check for mana effect
	if item.get("mana_amount"):
		var mana = item.get("mana_amount")
		player.stats.restore_mana(mana)
		GameManager.show_notification("Restored %d Mana!" % mana)
		consumed = true
	
	if consumed:
		player.inventory.remove_item(item, 1)
		_update_inventory()
		_update_stats()

func _show_item_info(item: ItemData):
	if not item:
		return
	
	item_name_label.text = item.item_name
	
	# Build description with stats
	var desc_text = item.description + "\n\n"
	
	if item.get("damage"):
		desc_text += "Increases damage by: +%d\n" % item.get("damage")
	if item.get("attack_speed"):
		desc_text += "Attack speed: %.1fx\n" % item.get("attack_speed")
	if item.get("defense"):
		desc_text += "Increases defense by: +%d\n" % item.get("defense")
	if item.get("vitality_bonus"):
		desc_text += "Vitality bonus: +%d\n" % item.get("vitality_bonus")
	if item.get("hp_bonus"):
		desc_text += "Increases max HP by: +%d\n" % item.get("hp_bonus")
	if item.get("attack_bonus"):
		desc_text += "Increases attack by: +%d\n" % item.get("attack_bonus")
	if item.get("heal_amount"):
		desc_text += "Heals: %d HP\n" % item.get("heal_amount")
	if item.get("mana_amount"):
		desc_text += "Restores: %d Mana\n" % item.get("mana_amount")
	
	# Add comparison
	var comparison = _get_comparison_text(item)
	if comparison != "":
		desc_text += "\n" + comparison
	
	item_desc_label.text = desc_text
	equip_button.visible = equip_button.text == "Unequip" or _is_equippable(item)
	item_info_panel.show()

func _drop_selected_item() -> void:
	if not selected_item or not player or not player.inventory:
		return
	if player.inventory.remove_item(selected_item, 1):
		var pickup := preload("res://scenes/items/item_pickup.tscn").instantiate()
		pickup.item_id = selected_item.item_id
		pickup.quantity = 1
		pickup.global_position = player.global_position + (player.last_direction.normalized() * 18.0)
		get_tree().current_scene.add_child(pickup)
		GameManager.show_notification("Dropped %s" % selected_item.item_name)
		selected_item = null
		selected_equipment_slot = ""
		item_info_panel.hide()
		_update_inventory()

func _build_equipment_summary() -> String:
	if not player or not player.inventory:
		return "Equipment stats"
	var attack := 0
	var defense := 0
	var hp := 0
	var vit := 0
	for item in player.inventory.equipment.values():
		if item == null:
			continue
		if item.get("damage"):
			attack += int(item.get("damage"))
		if item.get("attack_bonus"):
			attack += int(item.get("attack_bonus"))
		if item.get("defense"):
			defense += int(item.get("defense"))
		if item.get("hp_bonus"):
			hp += int(item.get("hp_bonus"))
		if item.get("vitality_bonus"):
			vit += int(item.get("vitality_bonus"))
	return "Equipment stats\nDamage/Attack: +%d\nDefense: +%d\nHP: +%d\nVitality: +%d" % [attack, defense, hp, vit]

func _show_equipment_item_info(item: ItemData) -> void:
	equipment_stats_label.text = _build_item_detail_text(item)

func _build_item_detail_text(item: ItemData) -> String:
	if not item:
		return _build_equipment_summary()
	var text := item.item_name + "\n"
	if item.get("damage"):
		text += "Damage: +%d\n" % int(item.get("damage"))
	if item.get("attack_bonus"):
		text += "Attack: +%d\n" % int(item.get("attack_bonus"))
	if item.get("defense"):
		text += "Defense: +%d\n" % int(item.get("defense"))
	if item.get("hp_bonus"):
		text += "HP: +%d\n" % int(item.get("hp_bonus"))
	if item.get("vitality_bonus"):
		text += "Vitality: +%d\n" % int(item.get("vitality_bonus"))
	return text.strip_edges()

func _get_equipped_item(slot_type: String) -> ItemData:
	if not player or not player.inventory:
		return null
	return player.inventory.equipment.get(slot_type)

func _unequip_selected_equipment() -> void:
	if selected_equipment_slot == "" or not player or not player.inventory:
		return
	var item := selected_item
	if player.inventory.unequip_item(selected_equipment_slot):
		GameManager.show_notification("Unequipped %s" % item.item_name)
		selected_item = null
		selected_equipment_slot = ""
		_update_equipment()
		_update_inventory()
		_update_stats()
		if player.stats:
			player.stats.emit_stat_signals()

func _short_item_name(item: ItemData) -> String:
	if not item:
		return ""
	var name := item.item_name
	return name if name.length() <= 16 else name.substr(0, 15) + "."

func _is_equippable(item: ItemData) -> bool:
	if item == null:
		return false
	return item.get("weapon_type") != null or item.get("armor_type") != null or int(item.get("attack_bonus")) > 0

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
	badge.anchor_left = 0.0
	badge.anchor_top = 0.0
	badge.anchor_right = 1.0
	badge.anchor_bottom = 1.0
	badge.offset_left = 2.0
	badge.offset_top = 2.0
	badge.offset_right = -4.0
	badge.offset_bottom = -2.0
	button.add_child(badge)

func _get_comparison_text(item: ItemData) -> String:
	if not player or not item:
		return ""
	
	var equipped: ItemData = null
	
	# Determine which slot and get equipped item
	if item.get("weapon_type") != null:
		equipped = player.inventory.equipment.weapon
	elif item.get("armor_type") != null:
		var armor_type = item.get("armor_type")
		if armor_type == null:
			armor_type = 0
		if armor_type == 1:
			equipped = player.inventory.equipment.helmet
		else:
			equipped = player.inventory.equipment.armor
	elif int(item.get("attack_bonus")) > 0:
		equipped = player.inventory.equipment.accessory
	
	if not equipped:
		return "(No item equipped in this slot)"
	
	if equipped == item:
		return "(Currently equipped)"
	
	var comparison = "Compared to equipped:\n"
	var has_diff = false
	
	# Compare damage
	if item.get("damage") and equipped.get("damage"):
		var diff = item.get("damage") - equipped.get("damage")
		comparison += "Damage: %s%d\n" % ["+" if diff > 0 else "", diff]
		has_diff = true
	
	# Compare defense
	if item.get("defense") and equipped.get("defense"):
		var diff = item.get("defense") - equipped.get("defense")
		comparison += "Defense: %s%d\n" % ["+" if diff > 0 else "", diff]
		has_diff = true
	
	# Compare HP bonus
	if item.get("hp_bonus") and equipped.get("hp_bonus"):
		var diff = item.get("hp_bonus") - equipped.get("hp_bonus")
		comparison += "HP: %s%d\n" % ["+" if diff > 0 else "", diff]
		has_diff = true
	
	# Compare attack bonus
	if item.get("attack_bonus") and equipped.get("attack_bonus"):
		var diff = item.get("attack_bonus") - equipped.get("attack_bonus")
		comparison += "Attack: %s%d\n" % ["+" if diff > 0 else "", diff]
		has_diff = true
	
	return comparison if has_diff else ""

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		close()
