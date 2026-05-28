extends Node

# Global signals - some reserved for future UI updates
signal player_health_changed(new_hp: int, max_hp: int)  # Reserved for HUD updates
signal player_mana_changed(new_mana: int, max_mana: int)  # Reserved for HUD updates
signal player_xp_changed(current_xp: int, xp_to_next: int, level: int)  # Reserved for HUD updates
signal player_level_up(new_level: int)  # Reserved for level-up effects
signal player_gold_changed(amount: int)  # Reserved for HUD updates
signal monster_killed(monster_type: String, position: Vector2)
signal damage_dealt(amount: int, position: Vector2, is_critical: bool)
signal item_picked_up(item_id: String, quantity: int)  # Reserved for pickup notifications
signal game_paused
signal game_resumed

# Game state
var is_paused: bool = false
var story_flags: Dictionary = {}
var current_map_id: String = ""
var player_position: Vector2 = Vector2.ZERO
var player_class: Resource = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func pause_game():
	is_paused = true
	get_tree().paused = true
	game_paused.emit()

func resume_game():
	is_paused = false
	get_tree().paused = false
	game_resumed.emit()

func toggle_pause():
	if is_paused:
		resume_game()
	else:
		pause_game()

func set_story_flag(flag: String, value: bool = true):
	story_flags[flag] = value

func get_story_flag(flag: String) -> bool:
	return story_flags.get(flag, false)

func emit_damage(amount: int, position: Vector2, is_critical: bool = false):
	damage_dealt.emit(amount, position, is_critical)

func emit_monster_killed(monster_type: String, position: Vector2):
	monster_killed.emit(monster_type, position)

func show_notification(text: String, duration: float = 2.0):
	# Create a temporary notification label
	var notification = Label.new()
	notification.text = text
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Style the notification
	notification.add_theme_font_size_override("font_size", 18)
	
	# Add to a canvas layer so it's on top
	var canvas = CanvasLayer.new()
	canvas.layer = 200  # High layer to be on top
	get_tree().root.add_child(canvas)
	canvas.add_child(notification)
	
	# Position at top center of screen
	notification.position = Vector2(
		(get_viewport().get_visible_rect().size.x - notification.size.x) / 2,
		50
	)
	
	# Animate and remove
	var tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_property(notification, "modulate:a", 0.0, 0.5)
	tween.finished.connect(func():
		canvas.queue_free()
	)
