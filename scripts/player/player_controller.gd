extends CharacterBody2D
class_name Player

@export var speed: float = 80.0
@export var attack_cooldown: float = 0.4

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stats: StatsComponent = $StatsComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var weapon_sprite: Sprite2D = $WeaponSprite
@onready var attack_indicator: Line2D = $AttackIndicator

var inventory: Inventory = null
var direction: Vector2 = Vector2.ZERO
var last_direction: Vector2 = Vector2.DOWN
var can_attack: bool = true
var is_attacking: bool = false

# Class system
var player_class: PlayerClass
var skill_points: int = 0
var unlocked_skills: Array[String] = []
var ability_slots: Array[String] = ["fireball", "heal", "power_attack", "battle_cry"]

func _ready():
	add_to_group("player")
	
	# Create inventory
	inventory = Inventory.new()
	
	# Check if there's pending save data to apply
	if SaveManager._pending_player_data.size() > 0:
		SaveManager.apply_pending_player_data(self)
	else:
		# Add starting weapon (bronze sword)
		var bronze_sword = _load_weapon_data("bronze_sword")
		if bronze_sword:
			inventory.add_item(bronze_sword, 1)
			inventory.equip_item(bronze_sword, "weapon")
		
		# Add starting armor (bronze armor)
		var bronze_armor = _load_armor_data("bronze_armor")
		if bronze_armor:
			inventory.add_item(bronze_armor, 1)
			inventory.equip_item(bronze_armor, "armor")
	
	# Connect inventory signals
	inventory.equipment_changed.connect(_on_equipment_changed)
	
	# Initial equipment stats calculation
	call_deferred("_recalculate_equipment_stats")
	
	# Connect stats signals
	stats.died.connect(_on_died)
	
	# Disable hitbox initially
	hitbox.disable()
	
	# Hide weapon sprite initially
	if weapon_sprite:
		weapon_sprite.visible = false

func _load_weapon_data(weapon_id: String) -> WeaponData:
	var file_path = "res://data/items/" + weapon_id + ".json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var data = json.data
			var weapon = WeaponData.new()
			weapon.item_id = data.get("item_id", weapon_id)
			weapon.item_name = data.get("item_name", "Unknown Weapon")
			weapon.description = data.get("description", "")
			weapon.weapon_type = data.get("weapon_type", 0)
			weapon.damage = data.get("damage", 10)
			weapon.attack_speed = data.get("attack_speed", 1.0)
			weapon.knockback = data.get("knockback", 100.0)
			weapon.required_level = data.get("required_level", 1)
			weapon.buy_price = data.get("buy_price", 100)
			weapon.sell_price = data.get("sell_price", 50)
			# Load sprite
			var sprite_path = "res://assets/sprites/weapons/" + weapon_id + ".png"
			if ResourceLoader.exists(sprite_path):
				weapon.sprite = load(sprite_path)
			return weapon
	return null

func _load_armor_data(armor_id: String) -> ArmorData:
	var file_path = "res://data/items/" + armor_id + ".json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var data = json.data
			var armor = ArmorData.new()
			armor.item_id = data.get("item_id", armor_id)
			armor.item_name = data.get("item_name", "Unknown Armor")
			armor.description = data.get("description", "")
			armor.armor_type = data.get("armor_type", 0)
			armor.defense = data.get("defense", 5)
			armor.vitality_bonus = data.get("vitality_bonus", 0)
			armor.hp_bonus = data.get("hp_bonus", 0)
			armor.required_level = data.get("required_level", 1)
			armor.buy_price = data.get("buy_price", 100)
			armor.sell_price = data.get("sell_price", 50)
			return armor
	return null

func _on_equipment_changed(_slot: String, _item: ItemData) -> void:
	# Recalculate stats based on equipment
	_recalculate_equipment_stats()

func _recalculate_equipment_stats() -> void:
	# Calculate base stats
	var vit_ap = stats.distributed_ap.get("vit", 0) if stats.distributed_ap.has("vit") else 0
	var base_max_hp = 100 + (vit_ap * 5)
	var base_defense = 5 + (vit_ap / 2)
	var base_attack = stats.attack
	
	# Apply equipment bonuses
	var bonus_hp = 0
	var bonus_defense = 0
	var bonus_attack = 0
	
	# Armor slot
	if inventory.equipment.has("armor") and inventory.equipment.armor != null:
		if inventory.equipment.armor is ArmorData:
			var armor = inventory.equipment.armor as ArmorData
			bonus_hp += armor.hp_bonus
			bonus_defense += armor.defense
	
	# Helmet slot
	if inventory.equipment.has("helmet") and inventory.equipment.helmet != null:
		if inventory.equipment.helmet is ArmorData:
			var helmet = inventory.equipment.helmet as ArmorData
			bonus_hp += helmet.hp_bonus
			bonus_defense += helmet.defense
	
	# Accessory slot
	if inventory.equipment.has("accessory") and inventory.equipment.accessory != null:
		var accessory = inventory.equipment.accessory
		# Check for attack bonus in accessory
		if accessory.get("attack_bonus"):
			bonus_attack += accessory.attack_bonus
	
	# Calculate new stats
	var new_max_hp = base_max_hp + bonus_hp
	var new_defense = base_defense + bonus_defense
	var new_attack = base_attack + bonus_attack
	
	# Apply HP changes
	var hp_diff = new_max_hp - stats.max_hp
	stats.max_hp = new_max_hp
	stats.defense = new_defense
	stats.attack = new_attack
	
	# Increase current HP by the same amount as max HP increase
	if hp_diff > 0:
		stats.current_hp += hp_diff
	else:
		# Clamp current HP to new max if max decreased
		stats.current_hp = min(stats.current_hp, stats.max_hp)
	
	stats.hp_changed.emit(stats.current_hp, stats.max_hp)

func set_class(new_class: PlayerClass):
	player_class = new_class
	
	# Apply base stats
	stats.max_hp = new_class.base_stats.get("max_hp", 100)
	stats.max_mana = new_class.base_stats.get("max_mana", 50)
	stats.attack = new_class.base_stats.get("attack", 10)
	stats.defense = new_class.base_stats.get("defense", 5)
	stats.speed = new_class.base_stats.get("speed", 80.0)
	
	# Reset current values
	stats.current_hp = stats.max_hp
	stats.current_mana = stats.max_mana
	self.speed = stats.speed
	
	# Unlock starting skills
	for skill_id in new_class.starting_skills:
		_unlock_skill(skill_id)

func add_skill_points(points: int):
	skill_points += points

func _unlock_skill(skill_id: String):
	if player_class and player_class.skill_tree:
		var node = player_class.skill_tree.get_node_by_id(skill_id)
		if node and not node.is_unlocked:
			node.is_unlocked = true
			unlocked_skills.append(skill_id)
			_apply_skill_effects(node)

func _apply_skill_effects(node: SkillNode):
	# Apply stat bonuses
	for stat in node.stat_bonuses.keys():
		var bonus = node.stat_bonuses[stat]
		match stat:
			"max_hp": stats.max_hp += bonus
			"max_mana": stats.max_mana += bonus
			"attack": stats.attack += bonus
			"defense": stats.defense += bonus
	
	# Apply passive effects
	for effect in node.passive_effects:
		_apply_passive_effect(effect)

func _apply_passive_effect(effect: String):
	match effect:
		"damage_reduction_10":
			# Would be checked in damage calculation
			pass
		"hp_regen_1":
			# Would be processed in _physics_process
			pass
		"move_speed_10", "move_speed_25":
			var bonus = 1.1 if effect == "move_speed_10" else 1.25
			speed *= bonus
		"dodge_15":
			# Would be checked when taking damage
			pass

func _physics_process(_delta: float) -> void:
	if GameManager.is_paused or is_attacking:
		return
	
	# Get input
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2.ZERO:
		last_direction = direction
	
	# Apply movement
	velocity = direction * speed
	move_and_slide()
	
	# Update animation
	_update_animation()
	
	# Handle real-time basic attack and ability inputs.
	if Input.is_action_just_pressed("attack") and can_attack:
		_attack()
	_handle_ability_input()


func _handle_ability_input() -> void:
	for index in ability_slots.size():
		var action := "ability_%d" % (index + 1)
		if Input.is_action_just_pressed(action):
			var ability_id := ability_slots[index]
			if ability_id != "":
				AbilityManager.cast_ability(self, ability_id, null, last_direction)

func _update_animation() -> void:
	if is_attacking:
		return
	
	if direction == Vector2.ZERO:
		animated_sprite.play("idle_" + _get_direction_name())
	else:
		animated_sprite.play("walk_" + _get_direction_name())

func _get_direction_name() -> String:
	if abs(last_direction.x) > abs(last_direction.y):
		return "left" if last_direction.x < 0 else "right"
	else:
		return "up" if last_direction.y < 0 else "down"

func _attack() -> void:
	can_attack = false
	is_attacking = true
	
	# Get weapon data
	var weapon = inventory.get_equipped_weapon()
	var damage = stats.get_total_attack()
	var cooldown = attack_cooldown
	
	if weapon:
		damage += weapon.damage
		cooldown = 1.0 / weapon.attack_speed
		_show_weapon_sprite(weapon)
	
	# Set hitbox damage
	hitbox.damage = damage
	
	# Show attack indicator
	_show_attack_indicator()
	
	# Play attack animation
	var anim_name = "attack_" + _get_direction_name()
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	else:
		# Fallback to idle if attack animation doesn't exist
		animated_sprite.play("idle_" + _get_direction_name())
	
	# Position hitbox based on direction
	_update_hitbox_position()
	
	# Enable hitbox
	hitbox.enable()
	
	# Wait for hitbox active duration
	await get_tree().create_timer(0.15).timeout
	hitbox.disable()
	
	# Hide attack indicator
	if attack_indicator:
		attack_indicator.visible = false
	
	# Hide weapon sprite
	if weapon_sprite:
		weapon_sprite.visible = false
	
	# Wait for animation to finish or timeout
	var anim_timer = get_tree().create_timer(0.2)
	await anim_timer.timeout
	
	is_attacking = false
	
	# Cooldown - reduced for faster attacks
	await get_tree().create_timer(max(0.05, cooldown - 0.1)).timeout
	can_attack = true

func _show_weapon_sprite(weapon: WeaponData) -> void:
	if not weapon_sprite or not weapon.sprite:
		return
	
	weapon_sprite.texture = weapon.sprite
	weapon_sprite.visible = true
	
	# Position and rotate based on direction
	var dir_name = _get_direction_name()
	match dir_name:
		"right":
			weapon_sprite.position = Vector2(20, 5)
			weapon_sprite.rotation = PI / 2
			weapon_sprite.flip_v = false
		"left":
			weapon_sprite.position = Vector2(-20, 5)
			weapon_sprite.rotation = -PI / 2
			weapon_sprite.flip_v = false
		"down":
			weapon_sprite.position = Vector2(0, 20)
			weapon_sprite.rotation = PI
			weapon_sprite.flip_v = false
		"up":
			weapon_sprite.position = Vector2(0, -15)
			weapon_sprite.rotation = 0
			weapon_sprite.flip_v = false
	
	# Animate sword swing
	_animate_sword_swing(dir_name)

func _show_attack_indicator() -> void:
	if not attack_indicator:
		return
	
	# Position and rotate based on direction
	var dir_name = _get_direction_name()
	match dir_name:
		"right":
			attack_indicator.rotation = 0
			attack_indicator.position = Vector2(0, 0)
		"left":
			attack_indicator.rotation = PI
			attack_indicator.position = Vector2(0, 0)
		"down":
			attack_indicator.rotation = PI / 2
			attack_indicator.position = Vector2(0, 0)
		"up":
			attack_indicator.rotation = -PI / 2
			attack_indicator.position = Vector2(0, 0)
	
	attack_indicator.visible = true

func _animate_sword_swing(dir_name: String) -> void:
	if not weapon_sprite:
		return
	
	# Create swing animation
	var tween = create_tween()
	
	match dir_name:
		"right":
			weapon_sprite.rotation = PI / 4
			tween.tween_property(weapon_sprite, "rotation", 3 * PI / 4, 0.15)
		"left":
			weapon_sprite.rotation = -PI / 4
			tween.tween_property(weapon_sprite, "rotation", -3 * PI / 4, 0.15)
		"down":
			weapon_sprite.rotation = 3 * PI / 4
			tween.tween_property(weapon_sprite, "rotation", 5 * PI / 4, 0.15)
		"up":
			weapon_sprite.rotation = -PI / 4
			tween.tween_property(weapon_sprite, "rotation", PI / 4, 0.15)
	weapon_sprite.visible = true
	
	# Position based on direction
	match _get_direction_name():
		"up":
			weapon_sprite.position = Vector2(0, -16)
			weapon_sprite.rotation = -PI / 2
		"down":
			weapon_sprite.position = Vector2(0, 16)
			weapon_sprite.rotation = PI / 2
		"left":
			weapon_sprite.position = Vector2(-16, 0)
			weapon_sprite.rotation = PI
		"right":
			weapon_sprite.position = Vector2(16, 0)
			weapon_sprite.rotation = 0

func _update_hitbox_position() -> void:
	var offset = Vector2.ZERO
	match _get_direction_name():
		"up":
			offset = Vector2(0, -12)
		"down":
			offset = Vector2(0, 12)
		"left":
			offset = Vector2(-12, 0)
		"right":
			offset = Vector2(12, 0)
	
	hitbox.position = offset

func _on_died() -> void:
	# Calculate gold penalty (10% of current gold)
	var gold_penalty = int(inventory.gold * 0.1)
	if gold_penalty > 0:
		inventory.remove_gold(gold_penalty)
	
	# Show death screen
	var death_ui = preload("res://scenes/ui/death_screen.tscn").instantiate()
	death_ui.gold_penalty = gold_penalty
	get_tree().root.add_child(death_ui)
	
	GameManager.pause_game()

func get_save_data() -> Dictionary:
	return {
		"stats": stats.get_save_data(),
		"class_type": player_class.class_type if player_class else 0,
		"skill_points": skill_points,
		"unlocked_skills": unlocked_skills,
		"ability_slots": ability_slots
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("stats"):
		stats.load_save_data(data.stats)
	if data.has("skill_points"):
		skill_points = data.skill_points
	if data.has("unlocked_skills"):
		unlocked_skills = data.unlocked_skills
	if data.has("ability_slots"):
		ability_slots = data.ability_slots
