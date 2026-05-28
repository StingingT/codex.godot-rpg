extends Node

# Screen shake
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var camera: Camera2D = null

# Hit stop (time slow)
var hit_stop_active: bool = false
var hit_stop_timer: float = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float):
	_process_screen_shake(delta)
	_process_hit_stop(delta)

# Screen Shake
func shake_screen(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration
	
	if not camera:
		_find_camera()

func _find_camera() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		camera = player.get_node_or_null("Camera2D")

func _process_screen_shake(delta: float) -> void:
	if shake_duration <= 0:
		if camera and camera.offset != Vector2.ZERO:
			camera.offset = Vector2.ZERO
		return
	
	shake_duration -= delta
	
	if camera:
		var shake_x = randf_range(-1, 1) * shake_intensity
		var shake_y = randf_range(-1, 1) * shake_intensity
		camera.offset = Vector2(shake_x, shake_y)
	
	if shake_duration <= 0:
		shake_intensity = 0
		if camera:
			camera.offset = Vector2.ZERO

# Hit Stop (Hit Freeze)
func trigger_hit_stop(duration: float = 0.05, time_scale: float = 0.1) -> void:
	hit_stop_active = true
	hit_stop_timer = duration
	Engine.time_scale = time_scale

func _process_hit_stop(delta: float) -> void:
	if not hit_stop_active:
		return
	
	hit_stop_timer -= delta / Engine.time_scale  # Account for time scale
	
	if hit_stop_timer <= 0:
		hit_stop_active = false
		Engine.time_scale = 1.0

# Particle Effects
func spawn_damage_number(amount: int, position: Vector2, is_critical: bool = false) -> void:
	var label = Label.new()
	label.text = str(amount)
	label.position = position
	
	if is_critical:
		label.add_theme_color_override("font_color", Color.YELLOW)
		label.add_theme_font_size_override("font_size", 14)
	else:
		label.add_theme_color_override("font_color", Color.WHITE)
	
	get_tree().current_scene.add_child(label)
	
	# Animate
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(label, "position:y", position.y - 30, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.finished.connect(label.queue_free)

func spawn_heal_number(amount: int, position: Vector2) -> void:
	var label = Label.new()
	label.text = "+" + str(amount)
	label.add_theme_color_override("font_color", Color.GREEN)
	label.position = position
	
	get_tree().current_scene.add_child(label)
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(label, "position:y", position.y - 25, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.finished.connect(label.queue_free)

func spawn_xp_number(amount: int, position: Vector2) -> void:
	var label = Label.new()
	label.text = str(amount) + " XP"
	label.add_theme_color_override("font_color", Color.GOLD)
	label.position = position
	
	get_tree().current_scene.add_child(label)
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(label, "position:y", position.y - 20, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(label.queue_free)

func spawn_level_up_effect(position: Vector2) -> void:
	# Create level up text
	var label = Label.new()
	label.text = "LEVEL UP!"
	label.add_theme_color_override("font_color", Color.GOLD)
	label.add_theme_font_size_override("font_size", 16)
	label.position = position - Vector2(30, 0)
	
	get_tree().current_scene.add_child(label)
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(label, "scale", Vector2(1.5, 1.5), 0.5)
	tween.tween_property(label, "position:y", label.position.y - 40, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(label.queue_free)

func spawn_quest_complete_effect() -> void:
	var label = Label.new()
	label.text = "QUEST COMPLETE!"
	label.add_theme_color_override("font_color", Color.GREEN)
	label.add_theme_font_size_override("font_size", 18)
	label.position = Vector2(320, 100)  # Center of screen
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	get_tree().current_scene.add_child(label)
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(label, "position:y", 80, 0.5)
	tween.tween_interval(1.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.finished.connect(label.queue_free)

# Knockback effect
func apply_knockback(body: CharacterBody2D, direction: Vector2, force: float) -> void:
	if not body:
		return
	
	body.velocity = direction.normalized() * force
	
	# Visual flash
	var sprite = body.get_node_or_null("AnimatedSprite2D")
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.05)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.05)

# Flash effect
func flash_sprite(sprite: Node2D, color: Color, duration: float = 0.1) -> void:
	if not sprite:
		return
	
	var original_modulate = sprite.modulate
	sprite.modulate = color
	
	await get_tree().create_timer(duration).timeout
	
	if is_instance_valid(sprite):
		sprite.modulate = original_modulate

# Screen flash
func flash_screen(color: Color, duration: float = 0.2) -> void:
	var flash = ColorRect.new()
	flash.color = color
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	get_tree().root.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.finished.connect(flash.queue_free)
