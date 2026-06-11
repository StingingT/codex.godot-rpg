extends SceneTree

const VIEWPORT_SIZES: Array[Vector2i] = [
	Vector2i(640, 360),
]

const UI_CASES: Array[Dictionary] = [
	{
		"name": "title_main",
		"path": "res://scenes/ui/title_screen.tscn",
		"check_paths": ["TitleLabel", "CenterContainer"],
	},
	{
		"name": "title_classes",
		"path": "res://scenes/ui/title_screen.tscn",
		"show_paths": ["ClassSelection"],
		"hide_paths": ["CenterContainer"],
		"check_paths": [
			"ClassSelection/SelectClassLabel",
			"ClassSelection/WarriorButton",
			"ClassSelection/RangerButton",
			"ClassSelection/MageButton",
			"ClassSelection/BackButton",
		],
	},
	{
		"name": "hud",
		"path": "res://scenes/ui/hud.tscn",
		"check_paths": [
			"HealthBar",
			"ManaBar",
			"XPBar",
			"LevelLabel",
			"MapLabel",
			"APLabel",
			"SPLabel",
			"CharacterButton",
			"PauseButton",
		],
	},
	{
		"name": "character_stats",
		"path": "res://scenes/ui/character_screen.tscn",
		"tab_path": "Panel/TabContainer",
		"tab": 0,
		"check_paths": ["Panel", "Panel/TitleLabel", "Panel/TabContainer", "Panel/CloseButton"],
	},
	{
		"name": "character_inventory",
		"path": "res://scenes/ui/character_screen.tscn",
		"tab_path": "Panel/TabContainer",
		"tab": 1,
		"check_paths": ["Panel", "Panel/TitleLabel", "Panel/TabContainer", "Panel/CloseButton"],
	},
	{
		"name": "character_skills",
		"path": "res://scenes/ui/character_screen.tscn",
		"tab_path": "Panel/TabContainer",
		"tab": 2,
		"check_paths": ["Panel", "Panel/TitleLabel", "Panel/TabContainer", "Panel/CloseButton"],
	},
	{
		"name": "inventory",
		"path": "res://scenes/ui/inventory_ui.tscn",
		"check_paths": ["Panel", "ItemInfoPanel"],
	},
	{
		"name": "inventory_item_info",
		"path": "res://scenes/ui/inventory_ui.tscn",
		"show_paths": ["ItemInfoPanel"],
		"check_paths": ["Panel", "ItemInfoPanel"],
	},
	{
		"name": "quest_book",
		"path": "res://scenes/ui/quest_book.tscn",
		"show_paths": ["Control"],
		"check_paths": ["Control/BookPanel", "Control/BookPanel/LeftPage", "Control/BookPanel/RightPage"],
	},
	{
		"name": "shop",
		"path": "res://scenes/ui/shop_ui.tscn",
		"check_paths": ["Panel", "Panel/ItemInfoPanel"],
	},
	{
		"name": "shop_item_info",
		"path": "res://scenes/ui/shop_ui.tscn",
		"show_paths": ["Panel/ItemInfoPanel"],
		"check_paths": ["Panel", "Panel/ItemInfoPanel"],
	},
	{
		"name": "map_selector",
		"path": "res://scenes/ui/map_selector.tscn",
		"show_paths": ["Control"],
		"check_paths": ["Control/Panel"],
	},
	{
		"name": "dialogue",
		"path": "res://scenes/ui/dialogue_box.tscn",
		"check_paths": ["DialoguePanel"],
	},
	{
		"name": "death",
		"path": "res://scenes/ui/death_screen.tscn",
		"check_paths": ["DeathLabel", "PenaltyLabel", "CenterContainer"],
	},
	{
		"name": "touch_controls",
		"path": "res://scenes/ui/touch_controls.tscn",
		"check_paths": ["Joystick", "AttackButton", "InteractButton", "InventoryButton"],
	},
]

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var failed := false
	for viewport_size in VIEWPORT_SIZES:
		for ui_case in UI_CASES:
			failed = await _validate_case(ui_case, viewport_size) or failed
	quit(1 if failed else 0)

func _validate_case(ui_case: Dictionary, viewport_size: Vector2i) -> bool:
	var scene_path := str(ui_case.get("path", ""))
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("UI layout scene could not load: %s" % scene_path)
		return true

	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	get_root().add_child(viewport)

	var instance := packed.instantiate()
	if instance == null:
		push_error("UI layout scene could not instantiate: %s" % scene_path)
		viewport.free()
		return true

	viewport.add_child(instance)
	await process_frame
	_prepare_case(instance, ui_case)
	await process_frame
	await process_frame

	var failures: Array[String] = []
	if DisplayServer.get_name() == "headless":
		_collect_configured_failures(instance, ui_case, viewport_size, failures)
	else:
		_collect_layout_failures(instance, viewport_size, failures)
	for failure in failures:
		push_error(
			"UI layout %s at %dx%d: %s"
			% [str(ui_case.get("name", scene_path)), viewport_size.x, viewport_size.y, failure]
		)

	viewport.free()
	await process_frame
	return not failures.is_empty()

func _prepare_case(instance: Node, ui_case: Dictionary) -> void:
	if instance is Control:
		var control := instance as Control
		control.visible = true
		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	elif instance is CanvasItem:
		(instance as CanvasItem).visible = true

	for node_path in ui_case.get("show_paths", []):
		var node := instance.get_node_or_null(str(node_path))
		if node is CanvasItem:
			(node as CanvasItem).visible = true

	for node_path in ui_case.get("hide_paths", []):
		var node := instance.get_node_or_null(str(node_path))
		if node is CanvasItem:
			(node as CanvasItem).visible = false

	var tab_path := str(ui_case.get("tab_path", ""))
	if tab_path != "":
		var tabs := instance.get_node_or_null(tab_path) as TabContainer
		if tabs != null:
			tabs.current_tab = int(ui_case.get("tab", 0))

func _collect_configured_failures(
	instance: Node,
	ui_case: Dictionary,
	viewport_size: Vector2i,
	failures: Array[String]
) -> void:
	for node_path in ui_case.get("check_paths", []):
		var control := instance.get_node_or_null(str(node_path)) as Control
		if control == null:
			failures.append("missing configured layout target %s" % str(node_path))
			continue
		var rect := _get_configured_rect(control, viewport_size)
		_validate_rect(control.get_path(), rect, viewport_size, failures)

func _get_configured_rect(control: Control, viewport_size: Vector2i) -> Rect2:
	var parent_rect := Rect2(Vector2.ZERO, Vector2(viewport_size))
	var parent_control := control.get_parent() as Control
	if parent_control != null:
		parent_rect = _get_configured_rect(parent_control, viewport_size)

	var start := parent_rect.position + Vector2(
		parent_rect.size.x * control.anchor_left + control.offset_left,
		parent_rect.size.y * control.anchor_top + control.offset_top
	)
	var end := parent_rect.position + Vector2(
		parent_rect.size.x * control.anchor_right + control.offset_right,
		parent_rect.size.y * control.anchor_bottom + control.offset_bottom
	)
	return Rect2(start, end - start)

func _collect_layout_failures(node: Node, viewport_size: Vector2i, failures: Array[String]) -> void:
	if node is Control:
		var control := node as Control
		if control.is_visible_in_tree():
			_validate_rect(control.get_path(), control.get_global_rect(), viewport_size, failures)

	for child in node.get_children():
		_collect_layout_failures(child, viewport_size, failures)

func _validate_rect(
	node_path: NodePath,
	rect: Rect2,
	viewport_size: Vector2i,
	failures: Array[String]
) -> void:
	if rect.size.x < 0.5 or rect.size.y < 0.5:
		failures.append("%s has a non-positive visible size %s" % [str(node_path), str(rect.size)])
	elif (
		rect.position.x < -0.5
		or rect.position.y < -0.5
		or rect.end.x > float(viewport_size.x) + 0.5
		or rect.end.y > float(viewport_size.y) + 0.5
	):
		failures.append("%s exceeds the viewport with rect %s" % [str(node_path), str(rect)])
