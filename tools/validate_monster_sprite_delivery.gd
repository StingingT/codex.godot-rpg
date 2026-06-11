extends SceneTree

const MANIFEST_PATH := "res://docs/sprite_deliverables/manifest.json"
const MONSTERS_PATH := "res://data/monsters/monsters.json"
const FRAME_COLUMNS := 4
const REQUIRED_ANIMATIONS: Array[String] = [
	"idle",
	"move",
	"attack",
	"hit",
	"death",
	"spawn"
]
const REQUIRED_AFFINITY_ICONS: Array[String] = [
	"neutral",
	"fire",
	"water",
	"poison",
	"lightning",
	"ice",
	"shadow",
	"undead",
	"armored"
]

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var manifest := _load_json(MANIFEST_PATH)
	var monster_data := _load_json(MONSTERS_PATH)
	var failed := manifest.is_empty() or monster_data.is_empty()

	if str(manifest.get("status", "")) != "art_delivered":
		push_error("Sprite delivery manifest must have status 'art_delivered'.")
		failed = true

	var manifest_monsters: Dictionary = manifest.get("monsters", {})
	for monster_id in manifest_monsters.keys():
		var data_entry: Dictionary = monster_data.get(monster_id, {})
		failed = _validate_monster(
			str(monster_id),
			manifest_monsters[monster_id],
			data_entry
		) or failed
		failed = await _validate_runtime_visual(str(monster_id), data_entry) or failed

	for affinity_id in REQUIRED_AFFINITY_ICONS:
		var icon_path := "res://assets/sprites/monsters/icons/affinity_%s.png" % affinity_id
		failed = _require_texture_size(icon_path, [Vector2i(16, 16), Vector2i(24, 24)]) or failed

	quit(1 if failed else 0)

func _validate_monster(monster_id: String, manifest_entry: Dictionary, data_entry: Dictionary) -> bool:
	var failed := false
	if data_entry.is_empty():
		push_error("Monster data is missing manifest monster: %s" % monster_id)
		return true

	var frame_size_data: Array = manifest_entry.get("frame_size", [])
	var animations: Array = manifest_entry.get("animations_present", [])
	if frame_size_data.size() != 2:
		push_error("Manifest frame_size must contain two integers: %s" % monster_id)
		return true

	for required_animation in REQUIRED_ANIMATIONS:
		if not animations.has(required_animation):
			push_error("Manifest monster %s is missing animation '%s'." % [monster_id, required_animation])
			failed = true
	if animations.has("walk"):
		push_error("Manifest monster %s uses forbidden locomotion animation 'walk'." % monster_id)
		failed = true

	var frame_size := Vector2i(int(frame_size_data[0]), int(frame_size_data[1]))
	var expected_sheet_size := Vector2i(frame_size.x * FRAME_COLUMNS, frame_size.y * animations.size())
	var sheet_path := str(manifest_entry.get("battle_sheet", ""))
	failed = _require_texture_size(sheet_path, [expected_sheet_size]) or failed

	var portrait_path := str(manifest_entry.get("codex_portrait", ""))
	failed = _require_texture_size(portrait_path, [Vector2i(96, 96), Vector2i(128, 128)]) or failed

	var frames_path := "res://assets/sprites/monsters/%s_frames.tres" % monster_id
	var frames := ResourceLoader.load(frames_path, "SpriteFrames") as SpriteFrames
	if frames == null:
		push_error("Missing generated SpriteFrames: %s" % frames_path)
		failed = true
	else:
		for animation in animations:
			var animation_name := StringName(str(animation))
			if not frames.has_animation(animation_name):
				push_error("SpriteFrames %s is missing animation '%s'." % [frames_path, animation_name])
				failed = true
			elif frames.get_frame_count(animation_name) != FRAME_COLUMNS:
				push_error("SpriteFrames %s animation '%s' must have four frames." % [frames_path, animation_name])
				failed = true
		if frames.has_animation(&"walk"):
			push_error("SpriteFrames %s contains forbidden animation 'walk'." % frames_path)
			failed = true

	var expected_fields := {
		"family": manifest_entry.get("family", ""),
		"size_class": manifest_entry.get("size_class", ""),
		"affinities": manifest_entry.get("affinities", []),
		"codex_index": manifest_entry.get("codex_index", 0),
		"sprite": sheet_path,
		"sprite_frames": frames_path,
		"codex_portrait": portrait_path,
		"description": manifest_entry.get("description", ""),
		"weaknesses": manifest_entry.get("weaknesses", []),
		"resists": manifest_entry.get("resists", [])
	}
	for field_name in expected_fields.keys():
		if data_entry.get(field_name) != expected_fields[field_name]:
			push_error("Monster data %s field '%s' does not match the reviewed manifest." % [monster_id, field_name])
			failed = true

	return failed

func _validate_runtime_visual(monster_id: String, data_entry: Dictionary) -> bool:
	var scene_path := str(data_entry.get("scene", ""))
	var frames_path := str(data_entry.get("sprite_frames", ""))
	var packed := ResourceLoader.load(scene_path, "PackedScene") as PackedScene
	var expected_frames := ResourceLoader.load(frames_path, "SpriteFrames") as SpriteFrames
	if packed == null or expected_frames == null:
		push_error("Could not prepare runtime visual check for monster: %s" % monster_id)
		return true

	var monster := packed.instantiate()
	if monster == null:
		push_error("Could not instantiate monster scene: %s" % scene_path)
		return true
	if "monster_type" in monster:
		monster.set("monster_type", monster_id)

	get_root().add_child(monster)
	await process_frame

	var sprite := monster.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var failed := sprite == null or sprite.sprite_frames != expected_frames
	if failed:
		push_error("Monster %s did not apply reviewed SpriteFrames at runtime." % monster_id)

	monster.free()
	await process_frame
	return failed

func _require_texture_size(path: String, allowed_sizes: Array[Vector2i]) -> bool:
	var texture := ResourceLoader.load(path, "Texture2D") as Texture2D
	if texture == null:
		push_error("Missing or invalid texture: %s" % path)
		return true
	var actual_size := Vector2i(texture.get_width(), texture.get_height())
	if not allowed_sizes.has(actual_size):
		push_error("Texture %s has size %s; expected one of %s." % [path, actual_size, allowed_sizes])
		return true
	return false

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing JSON file: %s" % path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON object: %s" % path)
		return {}
	return parsed
