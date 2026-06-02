extends RefCounted

const FRAME_SIZE := Vector2i(48, 48)
const FRAME_COUNT := 7
const DIRECTIONS := ["down", "left", "up", "right"]

static func build_directional_frames(idle_sheet_path: String, walk_sheet_path: String = "", attack_sheet_path: String = "") -> SpriteFrames:
	var idle_sheet := _load_texture(idle_sheet_path)
	if idle_sheet == null:
		return null

	var walk_sheet := _load_texture(walk_sheet_path)
	var attack_sheet := _load_texture(attack_sheet_path)
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	for direction_index in range(DIRECTIONS.size()):
		var direction: String = DIRECTIONS[direction_index]
		_add_animation(frames, "idle_" + direction, idle_sheet, direction_index, 2.0, true)
		_add_animation(frames, "walk_" + direction, walk_sheet if walk_sheet != null else idle_sheet, direction_index, 9.0, true)
		_add_animation(frames, "attack_" + direction, attack_sheet if attack_sheet != null else idle_sheet, direction_index, 14.0, false)

	_add_animation(frames, "idle", idle_sheet, 0, 2.0, true)
	return frames

static func _load_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

static func _add_animation(frames: SpriteFrames, animation_name: String, sheet: Texture2D, row: int, speed: float, loop: bool) -> void:
	if sheet == null:
		return
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, speed)
	frames.set_animation_loop(animation_name, loop)
	for frame_index in range(FRAME_COUNT):
		var texture := AtlasTexture.new()
		texture.atlas = sheet
		texture.region = Rect2(
			frame_index * FRAME_SIZE.x,
			row * FRAME_SIZE.y,
			FRAME_SIZE.x,
			FRAME_SIZE.y
		)
		frames.add_frame(animation_name, texture)
