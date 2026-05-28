extends CharacterBody2D
class_name Monster

enum State { IDLE, WANDER, CHASE, ATTACK, DEAD }

@export var monster_type: String = "slime"
@export var detection_range: float = 80.0
@export var attack_range: float = 20.0
@export var wander_speed: float = 30.0
@export var chase_speed: float = 60.0
@export var xp_reward: int = 10
@export var gold_reward: int = 5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stats: StatsComponent = $StatsComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var detection_zone: Area2D = $DetectionZone

var current_state: State = State.IDLE
var player: Player = null
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var attack_timer: float = 0.0
var attack_cooldown: float = 1.0

func _ready():
	add_to_group("monsters")
	
	# Connect signals
	detection_zone.body_entered.connect(_on_detection_body_entered)
	detection_zone.body_exited.connect(_on_detection_body_exited)
	stats.died.connect(_on_died)
	hurtbox.damage_taken.connect(_on_damage_taken)
	
	# Disable hitbox initially
	hitbox.disable()
	
	# Start idle
	_enter_state(State.IDLE)

func _physics_process(delta: float) -> void:
	if GameManager.is_paused or current_state == State.DEAD:
		return
	
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.WANDER:
			_process_wander(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)

func _enter_state(new_state: State) -> void:
	current_state = new_state
	
	match new_state:
		State.IDLE:
			velocity = Vector2.ZERO
			animated_sprite.play("idle")
			wander_timer = randf_range(1.0, 3.0)
		State.WANDER:
			wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			wander_timer = randf_range(1.0, 2.0)
			animated_sprite.play("walk")
		State.CHASE:
			animated_sprite.play("walk")
		State.ATTACK:
			velocity = Vector2.ZERO
			animated_sprite.play("attack")
			attack_timer = attack_cooldown

func _process_idle(delta: float) -> void:
	wander_timer -= delta
	
	if wander_timer <= 0:
		_enter_state(State.WANDER)
	
	# Check for player
	if player:
		_enter_state(State.CHASE)

func _process_wander(delta: float) -> void:
	wander_timer -= delta
	velocity = wander_direction * wander_speed
	
	# Flip sprite based on direction
	if wander_direction.x != 0:
		animated_sprite.flip_h = wander_direction.x < 0
	
	move_and_slide()
	
	if wander_timer <= 0:
		_enter_state(State.IDLE)
	
	# Check for player
	if player:
		_enter_state(State.CHASE)

func _process_chase(_delta: float) -> void:
	if not player:
		_enter_state(State.IDLE)
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Check if in attack range
	if distance_to_player <= attack_range:
		_enter_state(State.ATTACK)
		return
	
	# Move toward player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed
	
	# Flip sprite
	if direction.x != 0:
		animated_sprite.flip_h = direction.x < 0
	
	move_and_slide()

func _process_attack(delta: float) -> void:
	attack_timer -= delta
	
	if attack_timer <= attack_cooldown * 0.7 and attack_timer > attack_cooldown * 0.3:
		# Active hitbox during middle of attack
		hitbox.enable()
	else:
		hitbox.disable()
	
	if attack_timer <= 0:
		hitbox.disable()
		if player and global_position.distance_to(player.global_position) <= attack_range:
			_enter_state(State.ATTACK)
		else:
			_enter_state(State.CHASE)

func _on_detection_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body

func _on_detection_body_exited(body: Node2D) -> void:
	if body is Player:
		player = null

func _on_damage_taken(amount: int, _attacker_position: Vector2) -> void:
	# Flash red
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.RED, 0.05)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.05)
	
	# Spawn damage number
	var dmg_num = preload("res://scenes/effects/damage_number.tscn").instantiate()
	dmg_num.global_position = global_position + Vector2(randf_range(-10, 10), -40)
	dmg_num.setup(amount, false, false)  # white number for monster damage
	get_tree().current_scene.add_child(dmg_num)

func _on_died() -> void:
	current_state = State.DEAD
	animated_sprite.play("death")
	
	# Emit signal
	GameManager.emit_monster_killed(monster_type, global_position)
	
	# Drop loot
	_drop_loot()
	
	# Remove after animation
	await animated_sprite.animation_finished
	queue_free()

func _drop_loot() -> void:
	# Spawn XP orb using call_deferred to avoid physics state issues
	call_deferred("_spawn_xp_orb")
	
	# Drop gold (always drops, amount based on monster)
	call_deferred("_spawn_gold")
	
	# Chance to drop item
	if randf() < 0.3:
		call_deferred("_spawn_item")

func _spawn_gold() -> void:
	var gold_pickup = preload("res://scenes/items/gold_pickup.tscn").instantiate()
	gold_pickup.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
	
	# Gold amount based on monster type
	match monster_type:
		"slime": gold_pickup.gold_amount = randi_range(5, 15)
		"bat": gold_pickup.gold_amount = randi_range(3, 10)
		"skeleton": gold_pickup.gold_amount = randi_range(10, 25)
		"swamp_monster": gold_pickup.gold_amount = randi_range(15, 30)
		"dark_knight": gold_pickup.gold_amount = randi_range(50, 100)
		_: gold_pickup.gold_amount = randi_range(5, 15)
	
	get_tree().current_scene.add_child(gold_pickup)

func _spawn_xp_orb() -> void:
	var xp_orb = preload("res://scenes/items/xp_orb.tscn").instantiate()
	xp_orb.global_position = global_position
	xp_orb.xp_value = xp_reward
	get_tree().current_scene.add_child(xp_orb)

func _spawn_item() -> void:
	var item_pickup = preload("res://scenes/items/item_pickup.tscn").instantiate()
	item_pickup.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	item_pickup.item_id = "slime_gel" if monster_type == "slime" else "bone"
	get_tree().current_scene.add_child(item_pickup)
