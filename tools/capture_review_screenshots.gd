extends SceneTree

const OUTPUT_DIR := "res://review_artifacts/screenshots"
const VIEWPORT_SIZE := Vector2i(1280, 720)
const UI_VIEWPORT_SIZE := Vector2i(640, 360)
const MONSTER_REVIEW_IDS: Array[String] = [
	"slime_green",
	"slime_blue",
	"bat",
	"skeleton",
	"swamp_monster",
	"dark_knight"
]

const CAPTURES: Array[Dictionary] = [
	{
		"name": "ui_title_screen",
		"path": "res://scenes/ui/title_screen.tscn",
		"kind": "ui"
	},
	{
		"name": "ui_title_class_selection",
		"path": "res://scenes/ui/title_screen.tscn",
		"kind": "ui",
		"show_paths": ["ClassSelection"],
		"hide_paths": ["CenterContainer"]
	},
	{
		"name": "ui_hud",
		"path": "res://scenes/ui/hud.tscn",
		"kind": "ui"
	},
	{
		"name": "ui_character_screen",
		"path": "res://scenes/ui/character_screen.tscn",
		"kind": "ui"
	},
	{
		"name": "ui_inventory",
		"path": "res://scenes/ui/inventory_ui.tscn",
		"kind": "ui"
	},
	{
		"name": "ui_quest_book",
		"path": "res://scenes/ui/quest_book.tscn",
		"kind": "ui",
		"show_paths": ["Control"]
	},
	{
		"name": "ui_shop",
		"path": "res://scenes/ui/shop_ui.tscn",
		"kind": "ui"
	},
	{
		"name": "ui_skill_tree",
		"path": "res://scenes/ui/skill_tree_ui.tscn",
		"kind": "ui"
	},
	{
		"name": "map_custom_kit_town",
		"path": "res://scenes/maps/custom_kit_town.tscn",
		"kind": "map",
		"camera": Vector2(480, 288),
		"hide_paths": ["HUD"]
	},
	{
		"name": "map_custom_kit_field",
		"path": "res://scenes/maps/custom_kit_field.tscn",
		"kind": "map",
		"camera": Vector2(480, 288),
		"hide_paths": ["HUD"]
	},
	{
		"name": "map_custom_kit_ruins",
		"path": "res://scenes/maps/custom_kit_ruins.tscn",
		"kind": "map",
		"camera": Vector2(480, 288),
		"hide_paths": ["HUD"]
	},
	{
		"name": "map_custom_kit_marsh",
		"path": "res://scenes/maps/custom_kit_marsh.tscn",
		"kind": "map",
		"camera": Vector2(480, 288),
		"hide_paths": ["HUD"]
	},
	{
		"name": "map_custom_kit_catacombs",
		"path": "res://scenes/maps/custom_kit_catacombs.tscn",
		"kind": "map",
		"camera": Vector2(480, 288),
		"hide_paths": ["HUD"]
	},
	{
		"name": "map_custom_kit_dark_keep",
		"path": "res://scenes/maps/custom_kit_dark_keep.tscn",
		"kind": "map",
		"camera": Vector2(480, 288),
		"hide_paths": ["HUD"]
	},
	{
		"name": "legacy_map_town",
		"path": "res://scenes/maps/town.tscn",
		"kind": "map",
		"camera": Vector2(320, 180),
		"zoom": Vector2(2, 2),
		"hide_paths": ["HUD"]
	},
	{
		"name": "legacy_map_royal_courtyard",
		"path": "res://scenes/maps/royal_courtyard.tscn",
		"kind": "map",
		"camera": Vector2(320, 180),
		"zoom": Vector2(2, 2),
		"hide_paths": ["HUD"]
	},
	{
		"name": "legacy_map_fields",
		"path": "res://scenes/maps/fields.tscn",
		"kind": "map",
		"camera": Vector2(320, 180),
		"zoom": Vector2(2, 2),
		"hide_paths": ["HUD"]
	},
	{
		"name": "legacy_map_mystic_forest",
		"path": "res://scenes/maps/mystic_forest.tscn",
		"kind": "map",
		"camera": Vector2(320, 180),
		"zoom": Vector2(2, 2),
		"hide_paths": ["HUD"]
	},
	{
		"name": "legacy_map_river_crossing",
		"path": "res://scenes/maps/river_crossing.tscn",
		"kind": "map",
		"camera": Vector2(320, 180),
		"zoom": Vector2(2, 2),
		"hide_paths": ["HUD"]
	},
	{
		"name": "legacy_map_watchtower_ruins",
		"path": "res://scenes/maps/watchtower_ruins.tscn",
		"kind": "map",
		"camera": Vector2(320, 180),
		"zoom": Vector2(2, 2),
		"hide_paths": ["HUD"]
	},
	{
		"name": "legacy_map_sunken_marsh",
		"path": "res://scenes/maps/sunken_marsh.tscn",
		"kind": "map",
		"camera": Vector2(320, 180),
		"zoom": Vector2(2, 2),
		"hide_paths": ["HUD"]
	},
	{
		"name": "legacy_map_swamp",
		"path": "res://scenes/maps/swamp.tscn",
		"kind": "map",
		"camera": Vector2(320, 180),
		"zoom": Vector2(2, 2),
		"hide_paths": ["HUD"]
	},
	{
		"name": "legacy_map_cave",
		"path": "res://scenes/maps/cave.tscn",
		"kind": "map",
		"camera": Vector2(320, 180),
		"zoom": Vector2(2, 2),
		"hide_paths": ["HUD"]
	},
	{
		"name": "legacy_map_dungeon",
		"path": "res://scenes/maps/dungeon.tscn",
		"kind": "map",
		"camera": Vector2(320, 180),
		"zoom": Vector2(2, 2),
		"hide_paths": ["HUD"]
	},
	{
		"name": "development_map_test",
		"path": "res://scenes/maps/test_map.tscn",
		"kind": "map",
		"camera": Vector2(320, 180),
		"zoom": Vector2(2, 2),
		"hide_paths": ["HUD"]
	}
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_ensure_output_dir()
	var failed := false
	for capture in CAPTURES:
		failed = await _capture_scene(capture) or failed
	failed = await _capture_monster_gallery() or failed
	quit(1 if failed else 0)

func _capture_scene(capture: Dictionary) -> bool:
	var scene_path := str(capture.get("path", ""))
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Could not load scene for screenshot: %s" % scene_path)
		return true

	var viewport_size := UI_VIEWPORT_SIZE if str(capture.get("kind", "")) == "ui" else VIEWPORT_SIZE
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)

	var instance := packed.instantiate()
	if instance == null:
		push_error("Could not instantiate scene for screenshot: %s" % scene_path)
		viewport.queue_free()
		await process_frame
		return true

	viewport.add_child(instance)
	_prepare_scene_for_capture(instance, capture)

	for frame in range(8):
		await process_frame

	var texture := viewport.get_texture()
	var image := texture.get_image() if texture != null else null
	if image == null:
		push_error("Could not read rendered viewport image for %s. Run without --headless if the renderer is unavailable." % scene_path)
		viewport.queue_free()
		await process_frame
		return true

	var output_path := OUTPUT_DIR.path_join("%s.png" % str(capture.get("name", "capture")))
	var save_result := image.save_png(output_path)
	if save_result != OK:
		push_error("Could not save screenshot %s: %s" % [output_path, error_string(save_result)])
		viewport.queue_free()
		await process_frame
		return true

	print("Captured %s" % output_path)
	viewport.queue_free()
	await process_frame
	return false

func _capture_monster_gallery() -> bool:
	var viewport := SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)

	var root := Node2D.new()
	viewport.add_child(root)

	var background := ColorRect.new()
	background.color = Color("#17191c")
	background.size = VIEWPORT_SIZE
	root.add_child(background)

	var title := Label.new()
	title.text = "Runtime Monster Scale Review"
	title.position = Vector2(36, 24)
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	var data_registry := get_root().get_node_or_null("DataRegistry")
	if data_registry == null:
		push_error("DataRegistry autoload is unavailable for the monster review capture.")
		viewport.queue_free()
		await process_frame
		return true

	for index in range(MONSTER_REVIEW_IDS.size()):
		var monster_id := MONSTER_REVIEW_IDS[index]
		var monster_data: Dictionary = data_registry.call("get_monster", monster_id)
		var scene_path := str(monster_data.get("scene", ""))
		var packed := load(scene_path) as PackedScene
		if packed == null:
			push_error("Could not load monster scene for screenshot: %s" % scene_path)
			viewport.queue_free()
			await process_frame
			return true

		var column := index % 3
		var row := index / 3
		var origin := Vector2(210 + column * 420, 220 + row * 310)
		_add_scale_marker(root, origin)

		var monster := packed.instantiate()
		if "monster_type" in monster:
			monster.set("monster_type", monster_id)
		monster.position = origin
		root.add_child(monster)
		monster.process_mode = Node.PROCESS_MODE_DISABLED

		var sprite := monster.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if sprite != null:
			sprite.play(&"idle")

		var label := Label.new()
		label.text = "%s  |  %s" % [
			str(monster_data.get("name", monster_id)),
			str(monster_data.get("size_class", ""))
		]
		label.position = origin + Vector2(-110, 82)
		label.size = Vector2(220, 28)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 16)
		root.add_child(label)

	for frame in range(8):
		await process_frame

	var image := viewport.get_texture().get_image()
	var output_path := OUTPUT_DIR.path_join("monster_runtime_gallery.png")
	var save_result := image.save_png(output_path)
	if save_result != OK:
		push_error("Could not save screenshot %s: %s" % [output_path, error_string(save_result)])
		viewport.queue_free()
		await process_frame
		return true

	print("Captured %s" % output_path)
	viewport.queue_free()
	await process_frame
	return false

func _add_scale_marker(root: Node2D, origin: Vector2) -> void:
	var marker := ColorRect.new()
	marker.color = Color("#3b4047")
	marker.position = origin + Vector2(-64, 32)
	marker.size = Vector2(128, 32)
	root.add_child(marker)

	for offset in [-64.0, -32.0, 0.0, 32.0]:
		var divider := ColorRect.new()
		divider.color = Color("#5c6470")
		divider.position = origin + Vector2(offset, 32)
		divider.size = Vector2(1, 32)
		root.add_child(divider)

func _prepare_scene_for_capture(instance: Node, capture: Dictionary) -> void:
	if instance is Control:
		var control := instance as Control
		control.visible = true
		control.set_anchors_preset(Control.PRESET_FULL_RECT)
	elif instance is CanvasItem:
		(instance as CanvasItem).visible = true

	for node_path in capture.get("show_paths", []):
		var node := instance.get_node_or_null(str(node_path))
		_set_tree_visible(node, true)

	for node_path in capture.get("hide_paths", []):
		var node := instance.get_node_or_null(str(node_path))
		_set_tree_visible(node, false)

	if str(capture.get("kind", "")) == "map":
		_disable_cameras(instance)
		var camera := Camera2D.new()
		camera.position = capture.get("camera", Vector2.ZERO)
		camera.zoom = capture.get("zoom", Vector2.ONE)
		instance.add_child(camera)
		camera.make_current()

func _disable_cameras(node: Node) -> void:
	if node is Camera2D:
		(node as Camera2D).enabled = false
	for child in node.get_children():
		_disable_cameras(child)

func _set_tree_visible(node: Node, visible: bool) -> void:
	if node == null:
		return
	if node is CanvasItem:
		(node as CanvasItem).visible = visible
	for child in node.get_children():
		_set_tree_visible(child, visible)

func _ensure_output_dir() -> void:
	var root := DirAccess.open("res://")
	if root == null:
		push_error("Could not open res:// to create screenshot directory.")
		return
	root.make_dir_recursive("review_artifacts/screenshots")
