extends Control

const RPGUIStyle := preload("res://scripts/ui/rpg_ui_style.gd")

@onready var tree_container: Control = $TreeContainer
@onready var points_label: Label = $SkillPointsLabel
@onready var info_panel: Panel = $SkillInfoPanel
@onready var info_name: Label = $SkillInfoPanel/SkillName
@onready var info_desc: Label = $SkillInfoPanel/SkillDescription
@onready var info_cost: Label = $SkillInfoPanel/SkillCost
@onready var unlock_button: Button = $SkillInfoPanel/UnlockButton

var player: Player = null
var selected_skill: String = ""

# Simple skill list for testing
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
	_apply_style()
	hide()
	unlock_button.pressed.connect(_on_unlock_pressed)
	_build_ui()

func _apply_style() -> void:
	RPGUIStyle.apply_screen(self)
	RPGUIStyle.apply_dark_panel($Background)
	RPGUIStyle.apply_title($Title, 24)
	RPGUIStyle.apply_label(points_label)
	RPGUIStyle.apply_label($CloseHint, true)
	RPGUIStyle.apply_dark_panel(info_panel)
	RPGUIStyle.apply_title(info_name, 16)
	RPGUIStyle.apply_label(info_desc)
	RPGUIStyle.apply_label(info_cost)
	RPGUIStyle.apply_button(unlock_button, RPGUIStyle.BLUE)

func open(p_player: Player):
	player = p_player
	if not player:
		return
	_update_display()
	show()

func close():
	hide()

func _build_ui():
	# Clear existing
	for child in tree_container.get_children():
		child.queue_free()
	
	var y_pos = 0
	for skill_id in skills.keys():
		var skill = skills[skill_id]
		var button = Button.new()
		button.custom_minimum_size = Vector2(200, 40)
		button.size = Vector2(200, 40)
		button.position = Vector2(0, y_pos)
		button.text = skill.name
		RPGUIStyle.apply_slot_button(button, RPGUIStyle.BLUE)
		button.pressed.connect(_on_skill_selected.bind(skill_id))
		tree_container.add_child(button)
		y_pos += 50

func _on_skill_selected(skill_id: String):
	selected_skill = skill_id
	var skill = skills[skill_id]
	
	info_name.text = skill.name
	info_desc.text = skill.desc
	info_cost.text = "Cost: %d SP" % skill.cost
	
	# Check if already unlocked
	if player.unlocked_skills.has(skill_id):
		unlock_button.text = "Unlocked"
		unlock_button.disabled = true
	elif player.skill_points < skill.cost:
		unlock_button.text = "Need %d SP" % skill.cost
		unlock_button.disabled = true
	elif player.stats.level < skill.level_req:
		unlock_button.text = "Level %d Required" % skill.level_req
		unlock_button.disabled = true
	else:
		# Check prerequisites
		var prereqs_met = true
		for prereq in skill.prereqs:
			if not player.unlocked_skills.has(prereq):
				prereqs_met = false
				break
		
		if not prereqs_met:
			unlock_button.text = "Prerequisites Required"
			unlock_button.disabled = true
		else:
			unlock_button.text = "Unlock (%d SP)" % skill.cost
			unlock_button.disabled = false
	
	info_panel.show()

func _on_unlock_pressed():
	if selected_skill == "" or not player:
		return
	
	var skill = skills[selected_skill]
	
	if player.skill_points >= skill.cost:
		player.skill_points -= skill.cost
		player.unlocked_skills.append(selected_skill)
		
		# Apply effect
		_apply_skill_effect(skill)
		
		_update_display()
		_on_skill_selected(selected_skill)

func _apply_skill_effect(skill):
	var effect = skill.effect
	match effect.stat:
		"attack":
			player.stats.attack = int(player.stats.attack * (1 + effect.mul))
		"max_hp":
			player.stats.max_hp = int(player.stats.max_hp * (1 + effect.mul))
		"defense":
			player.stats.defense = int(player.stats.defense * (1 + effect.mul))
		"speed":
			player.stats.speed = player.stats.speed * (1 + effect.mul)

func _update_display():
	if player:
		points_label.text = "Skill Points: %d" % player.skill_points
	
	# Update button styles
	for child in tree_container.get_children():
		if child is Button:
			var skill_id = ""
			for sid in skills.keys():
				if skills[sid].name == child.text:
					skill_id = sid
					break
			
			if skill_id != "" and player and player.unlocked_skills.has(skill_id):
				RPGUIStyle.apply_slot_button(child, RPGUIStyle.GREEN)
			else:
				RPGUIStyle.apply_slot_button(child, RPGUIStyle.BLUE)

func _input(event):
	if visible and event.is_action_pressed("open_skill_tree"):
		close()
