extends CharacterBody2D
class_name Player

const CharacterSpriteFactory := preload("res://scripts/visuals/character_sprite_factory.gd")

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
var _equipment_max_hp_bonus: int = 0
var _equipment_defense_bonus: int = 0
var _equipment_attack_bonus: int = 0
const CLASS_SPRITE_OFFSET := Vector2(0, -20)
const WEAPON_HAND_OFFSETS := {
	"right": Vector2(12, -18),
	"left": Vector2(-12, -18),
	"down": Vector2(0, -15),
	"up": Vector2(0, -24)
}

func _ready():
	add_to_group("player")
	
	# Create inventory
	inventory = Inventory.new()
	
	# Check if there's pending save data to apply
	if SaveManager._pending_player_data.size() > 0:
		SaveManager.apply_pending_player_data(self)
	else:
		var selected_class := GameManager.player_class as PlayerClass
		if selected_class == null:
			selected_class = DataRegistry.create_player_class(PlayerClass.ClassType.WARRIOR)
		set_class(selected_class)
		_add_starting_equipment()
	
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

func _on_equipment_changed(_slot: String, _item: ItemData) -> void:
	# Recalculate stats based on equipment
	_recalculate_equipment_stats()

func refresh_equipment_stats(adjust_current_hp: bool = true) -> void:
	_recalculate_equipment_stats(adjust_current_hp)

func _recalculate_equipment_stats(adjust_current_hp: bool = true) -> void:
	if stats == null or inventory == null:
		return

	var old_max_hp := stats.get_max_hp()
	stats.max_hp -= _equipment_max_hp_bonus
	stats.defense -= _equipment_defense_bonus
	stats.attack -= _equipment_attack_bonus

	var bonus_hp := 0
	var bonus_defense := 0
	var bonus_attack := 0
	
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
	
	_equipment_max_hp_bonus = bonus_hp
	_equipment_defense_bonus = bonus_defense
	_equipment_attack_bonus = bonus_attack
	stats.max_hp += _equipment_max_hp_bonus
	stats.defense += _equipment_defense_bonus
	stats.attack += _equipment_attack_bonus

	var hp_diff := stats.get_max_hp() - old_max_hp
	if adjust_current_hp and hp_diff > 0:
		stats.current_hp += hp_diff
	stats.current_hp = min(stats.current_hp, stats.get_max_hp())
	
	stats.hp_changed.emit(stats.current_hp, stats.get_max_hp())

func set_class(new_class: PlayerClass):
	_equipment_max_hp_bonus = 0
	_equipment_defense_bonus = 0
	_equipment_attack_bonus = 0
	player_class = new_class
	_apply_class_sprite()
	
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

func _apply_class_sprite() -> void:
	if animated_sprite == null or player_class == null:
		return
	var sprite_paths := _get_class_sprite_paths()
	if sprite_paths.is_empty():
		return
	var frames := CharacterSpriteFactory.build_directional_frames(
		str(sprite_paths.get("idle", "")),
		str(sprite_paths.get("walk", "")),
		str(sprite_paths.get("attack", ""))
	)
	if frames == null:
		return
	animated_sprite.sprite_frames = frames
	animated_sprite.position = CLASS_SPRITE_OFFSET
	animated_sprite.play("idle_" + _get_direction_name())
	animated_sprite.set_frame_and_progress(0, 0.0)

func _get_class_sprite_paths() -> Dictionary:
	match player_class.class_type:
		PlayerClass.ClassType.RANGER:
			return {
				"idle": "res://assets/sprites/player/classes/archertheresa_idle.png",
				"walk": "res://assets/sprites/player/classes/archertheresa_walk.png",
				"attack": "res://assets/sprites/player/classes/archertheresa_attack.png"
			}
		PlayerClass.ClassType.MAGE:
			return {
				"idle": "res://assets/sprites/player/classes/mageted_idle.png",
				"walk": "res://assets/sprites/player/classes/mageted_walk.png",
				"attack": "res://assets/sprites/player/classes/mageted_attack.png"
			}
		_:
			return {
				"idle": "res://assets/sprites/player/classes/knightlow_idle.png",
				"walk": "res://assets/sprites/player/classes/knightlow_walk.png",
				"attack": "res://assets/sprites/player/classes/knightlow_attack.png"
			}

func _add_starting_equipment() -> void:
	var item_ids := ["bronze_sword", "bronze_armor"]
	if player_class:
		var configured_ids := player_class.get_starting_equipment()
		if not configured_ids.is_empty() and DataRegistry.get_item_data(configured_ids[0]) != null:
			item_ids = configured_ids
	for item_id in item_ids:
		var item := DataRegistry.get_item_data(item_id)
		if item == null:
			continue
		inventory.add_item(item, 1)
		if item is WeaponData:
			inventory.equip_item(item, "weapon")
		elif item is ArmorData:
			var armor := item as ArmorData
			var slot := "helmet" if armor.armor_type == ArmorData.ArmorType.HELMET else "armor"
			inventory.equip_item(item, slot)

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
		if not InputMap.has_action(action):
			continue
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
	hitbox.disable()
	
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
	
	# Align the hit frame with the visible weapon swing.
	await get_tree().create_timer(0.05).timeout
	if weapon_sprite and weapon_sprite.visible:
		_animate_sword_swing(_get_direction_name())

	hitbox.enable()
	
	# Wait for hitbox active duration
	await get_tree().create_timer(0.12).timeout
	hitbox.disable()
	
	# Hide attack indicator
	if attack_indicator:
		attack_indicator.visible = false
	
	# Hide weapon sprite
	if weapon_sprite:
		weapon_sprite.visible = false
	
	# Wait for animation to finish or timeout
	var anim_timer = get_tree().create_timer(0.18)
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
	weapon_sprite.position = WEAPON_HAND_OFFSETS.get(dir_name, Vector2.ZERO)
	match dir_name:
		"right":
			weapon_sprite.rotation = PI / 2
			weapon_sprite.flip_v = false
		"left":
			weapon_sprite.rotation = -PI / 2
			weapon_sprite.flip_v = false
		"down":
			weapon_sprite.rotation = PI
			weapon_sprite.flip_v = false
		"up":
			weapon_sprite.rotation = 0
			weapon_sprite.flip_v = false
	
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
	weapon_sprite.position = WEAPON_HAND_OFFSETS.get(dir_name, Vector2.ZERO)
	match dir_name:
		"up":
			weapon_sprite.rotation = -PI / 2
		"down":
			weapon_sprite.rotation = PI / 2
		"left":
			weapon_sprite.rotation = PI
		"right":
			weapon_sprite.rotation = 0

func _update_hitbox_position() -> void:
	var offset = Vector2.ZERO
	match _get_direction_name():
		"up":
			offset = Vector2(0, -18)
		"down":
			offset = Vector2(0, 18)
		"left":
			offset = Vector2(-18, 0)
		"right":
			offset = Vector2(18, 0)
	
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
		"stats": get_base_stats_save_data(),
		"class_type": player_class.class_type if player_class else 0,
		"skill_points": skill_points,
		"unlocked_skills": unlocked_skills,
		"ability_slots": ability_slots
	}

func get_base_stats_save_data() -> Dictionary:
	var data := stats.get_save_data()
	data["max_hp"] = int(data.get("max_hp", stats.max_hp)) - _equipment_max_hp_bonus
	data["defense"] = int(data.get("defense", stats.defense)) - _equipment_defense_bonus
	data["attack"] = int(data.get("attack", stats.attack)) - _equipment_attack_bonus
	return data

func load_save_data(data: Dictionary) -> void:
	if data.has("stats"):
		stats.load_save_data(data.stats)
	if data.has("skill_points"):
		skill_points = data.skill_points
	if data.has("unlocked_skills"):
		unlocked_skills = data.unlocked_skills
	if data.has("ability_slots"):
		ability_slots = data.ability_slots
