extends SceneTree

const MANIFEST_PATH := "res://docs/sprite_deliverables/manifest.json"
const OUTPUT_ROOT := "res://assets/sprites/monsters"
const FRAME_COLUMNS := 4

func _initialize() -> void:
	call_deferred("_build_all")

func _build_all() -> void:
	var manifest := _load_json(MANIFEST_PATH)
	var monsters: Dictionary = manifest.get("monsters", {})
	if monsters.is_empty():
		push_error("Sprite manifest has no monster entries.")
		quit(1)
		return

	var failed := false
	for monster_id in monsters.keys():
		failed = _build_frames(str(monster_id), monsters[monster_id]) or failed
	quit(1 if failed else 0)

func _build_frames(monster_id: String, entry: Dictionary) -> bool:
	var sheet_path := str(entry.get("battle_sheet", ""))
	var frame_size_data: Array = entry.get("frame_size", [])
	var animations: Array = entry.get("animations_present", [])
	if sheet_path.is_empty() or frame_size_data.size() != 2 or animations.is_empty():
		push_error("Incomplete sprite manifest entry: %s" % monster_id)
		return true

	var texture := ResourceLoader.load(sheet_path, "Texture2D") as Texture2D
	if texture == null:
		push_error("Could not load battle sheet: %s" % sheet_path)
		return true

	var frame_size := Vector2i(int(frame_size_data[0]), int(frame_size_data[1]))
	var expected_size := Vector2i(frame_size.x * FRAME_COLUMNS, frame_size.y * animations.size())
	var actual_size := Vector2i(texture.get_width(), texture.get_height())
	if actual_size != expected_size:
		push_error("Battle sheet %s should be %s, found %s." % [sheet_path, expected_size, actual_size])
		return true

	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for row in range(animations.size()):
		var animation_name := StringName(str(animations[row]))
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, animation_name in [&"idle", &"move"])
		frames.set_animation_speed(animation_name, _animation_speed(animation_name))
		for column in range(FRAME_COLUMNS):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(
				column * frame_size.x,
				row * frame_size.y,
				frame_size.x,
				frame_size.y
			)
			frames.add_frame(animation_name, atlas)

	var output_path := OUTPUT_ROOT.path_join("%s_frames.tres" % monster_id)
	var save_error := ResourceSaver.save(frames, output_path)
	if save_error != OK:
		push_error("Could not save SpriteFrames %s: %s" % [output_path, error_string(save_error)])
		return true

	print("Built %s" % output_path)
	return false

func _animation_speed(animation_name: StringName) -> float:
	match animation_name:
		&"idle":
			return 4.0
		&"move":
			return 6.0
		&"attack", &"hit", &"special":
			return 8.0
		_:
			return 6.0

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing JSON file: %s" % path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON object: %s" % path)
		return {}
	return parsed
