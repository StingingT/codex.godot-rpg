extends Node

signal map_changed(map_id: String, map_name: String)
signal map_transition_started
signal map_transition_finished

var current_map_id: String = ""
var current_map_data: Dictionary = {}
var pending_entry_id: String = ""
var pending_spawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func change_map(map_id: String, spawn_position: Vector2 = Vector2.ZERO) -> void:
	pending_spawn_position = spawn_position
	pending_entry_id = ""
	await _change_map_internal(map_id)

func change_map_to_entry(map_id: String, entry_id: String) -> void:
	pending_entry_id = entry_id
	pending_spawn_position = Vector2.ZERO
	await _change_map_internal(map_id)

func _change_map_internal(map_id: String) -> void:
	if map_id == current_map_id and pending_entry_id == "" and pending_spawn_position == Vector2.ZERO:
		return
	map_transition_started.emit()
	SaveManager.save_game()
	await _fade_out()

	current_map_id = map_id
	current_map_data = DataRegistry.get_map(map_id)
	GameManager.current_map_id = map_id

	var scene_path := str(current_map_data.get("scene", "res://scenes/maps/%s.tscn" % map_id))
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		push_error("Map scene not found: " + scene_path)
		return

	await get_tree().process_frame
	_position_player()
	await _fade_in()
	map_changed.emit(map_id, str(current_map_data.get("display_name", map_id.capitalize())))
	map_transition_finished.emit()

func _position_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if pending_spawn_position != Vector2.ZERO:
		player.global_position = pending_spawn_position
		return
	if pending_entry_id != "":
		var entry := get_tree().current_scene.get_node_or_null("EntryPoints/%s" % pending_entry_id) as Marker2D
		if entry:
			player.global_position = entry.global_position
			return
	var fallback := get_tree().current_scene.get_node_or_null("EntryPoints/entry_default") as Marker2D
	if fallback:
		player.global_position = fallback.global_position

func get_connection_for_exit(exit_id: String) -> Dictionary:
	for connection in current_map_data.get("connections", []):
		if str(connection.get("via", "")) == exit_id:
			return connection
	return {}

func transition_from_exit(exit_id: String) -> void:
	var connection := get_connection_for_exit(exit_id)
	if connection.is_empty():
		push_warning("No map connection configured for exit: %s" % exit_id)
		return
	change_map_to_entry(str(connection.get("to", "")), str(connection.get("spawn_at", "")))

func _fade_out() -> void:
	var tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(0.3)
	await tween.finished

func _fade_in() -> void:
	var tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(0.3)
	await tween.finished

func get_current_map_name() -> String:
	return str(current_map_data.get("display_name", current_map_id.capitalize()))

func is_safe_zone() -> bool:
	return str(current_map_data.get("biome", "")) == "town"
