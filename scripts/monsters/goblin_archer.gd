extends CharacterBody2D
class_name GoblinArcher

# Goblin Archer - Ranged enemy that runs away when player gets close
enum State { IDLE, WANDER, CHASE, FLEE, ATTACK, DEAD }

@export var monster_type: String = "goblin_archer"
@export var detection_range: float = 120.0
@export var attack_range: float = 80.0
@export var flee_range: float = 40.0
@export var wander_speed: float = 25.0
@export var chase_speed: float = 50.0
@export var flee_speed: float = 70.0
@export var xp_reward: int = 30
@export var gold_reward: int = 15

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stats: StatsComponent = $StatsComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var detection_zone: Area2D = $DetectionZone

var current_state: State = State.IDLE
var player: Player = null
var wander_timer: float = 0.0
var attack_timer: float = 0.0
var attack_cooldown: float = 1.5

func _ready():
	add_to_group("monsters")
	detection_zone.body_entered.connect(_on_detection_body_entered)
	detection_zone.body_exited.connect(_on_detection_body_exited)
	stats.died.connect(_on_died)
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
		State.FLEE:
			_process_flee(delta)
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
			wander_timer = randf_range(1.0, 2.0)
			animated_sprite.play("walk")
		State.CHASE:
			animated_sprite.play("walk")
		State.FLEE:
			animated_sprite.play("run")
		State.ATTACK:
			velocity = Vector2.ZERO
			animated_sprite.play("attack")
			attack_timer = attack_cooldown
			_shoot_arrow()

func _process_idle(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0:
		_enter_state(State.WANDER)
	
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist <= attack_range and dist > flee_range:
			_enter_state(State.ATTACK)
		elif dist <= detection_range:
			_enter_state(State.CHASE)

func _process_wander(delta: float) -> void:
	wander_timer -= delta
	# Simple wander movement
	velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * wander_speed
	move_and_slide()
	
	if wander_timer <= 0:
		_enter_state(State.IDLE)
	
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist <= flee_range:
			_enter_state(State.FLEE)
		elif dist <= attack_range:
			_enter_state(State.ATTACK)
		elif dist <= detection_range:
			_enter_state(State.CHASE)

func _process_chase(delta: float) -> void:
	if not player:
		_enter_state(State.IDLE)
		return
	
	var dist = global_position.distance_to(player.global_position)
	
	if dist <= flee_range:
		_enter_state(State.FLEE)
		return
	elif dist <= attack_range:
		_enter_state(State.ATTACK)
		return
	
	# Move toward player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed
	animated_sprite.flip_h = direction.x < 0
	move_and_slide()

func _process_flee(delta: float) -> void:
	if not player:
		_enter_state(State.IDLE)
		return
	
	var dist = global_position.distance_to(player.global_position)
	
	# Stop fleeing if player is far enough
	if dist > flee_range * 1.5:
		if dist <= attack_range:
			_enter_state(State.ATTACK)
		else:
			_enter_state(State.CHASE)
		return
	
	# Run away from player
	var direction = (global_position - player.global_position).normalized()
	velocity = direction * flee_speed
	animated_sprite.flip_h = direction.x < 0
	move_and_slide()

func _process_attack(delta: float) -> void:
	attack_timer -= delta
	
	if not player:
		_enter_state(State.IDLE)
		return
	
	var dist = global_position.distance_to(player.global_position)
	
	# Flee if player gets too close
	if dist <= flee_range:
		_enter_state(State.FLEE)
		return
	
	# Chase if player moves out of attack range
	if dist > attack_range:
		_enter_state(State.CHASE)
		return
	
	# Shoot again when cooldown is up
	if attack_timer <= 0:
		_shoot_arrow()
		attack_timer = attack_cooldown

func _shoot_arrow() -> void:
	if not player:
		return
	
	# Create arrow projectile
	print("[GoblinArcher] Shooting arrow!")
	# In full implementation: spawn arrow projectile toward player
	AudioManager.play_sfx("bow_shoot")

func _on_detection_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body

func _on_detection_body_exited(body: Node2D) -> void:
	if body is Player:
		player = null

func _on_died() -> void:
	current_state = State.DEAD
	animated_sprite.play("death")
	GameManager.emit_monster_killed(monster_type, global_position)
	await animated_sprite.animation_finished
	queue_free()
