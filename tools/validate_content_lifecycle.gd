extends SceneTree

const MAPS_PATH := "res://data/maps/maps.json"
const QUESTS_PATH := "res://data/quests"
const TITLE_SCREEN_PATH := "res://scripts/ui/title_screen.gd"
const PORTAL_PATHS: Array[String] = [
	"res://scripts/ui/portal.gd",
	"res://scripts/npcs/portal_npc.gd"
]
const VALID_CONTENT_STATES: Array[String] = ["active", "legacy", "development"]
const REQUIRED_ACTIVE_MAP_NODES: Array[String] = [
	"GroundLayer",
	"DecorLayer",
	"CollisionLayer",
	"OverlayLayer",
	"EntryPoints",
	"ExitTriggers",
	"SpawnPoints",
	"BossSpawnPoint",
	"NPCs",
	"Items",
	"CameraLimits"
]

var maps: Dictionary = {}
var quests: Dictionary = {}
var monsters: Dictionary = {}
var items: Dictionary = {}
var active_map_ids: Array[String] = []
var active_quest_ids: Array[String] = []
var legacy_map_ids: Array[String] = []
var development_map_ids: Array[String] = []
var legacy_quest_ids: Array[String] = []

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var registry := root.get_node_or_null("DataRegistry")
	if registry == null:
		push_error("DataRegistry autoload is unavailable for content lifecycle validation.")
		quit(1)
		return

	maps = registry.get("maps")
	quests = registry.get("quests")
	monsters = registry.get("monsters")
	items = registry.get("items")

	var failed := false
	failed = _validate_maps(registry) or failed
	failed = _validate_quests() or failed
	failed = _validate_default_route() or failed
	failed = _validate_travel_ownership() or failed
	_report_known_content_debt()
	_report_duplicate_assets()

	if failed:
		quit(1)
		return

	print(
		"Content lifecycle validation passed: %d active maps, %d legacy maps, %d development maps, %d active quests, %d legacy quests."
		% [
			active_map_ids.size(),
			legacy_map_ids.size(),
			development_map_ids.size(),
			active_quest_ids.size(),
			legacy_quest_ids.size()
		]
	)
	quit(0)

func _validate_maps(registry: Node) -> bool:
	var failed := false
	var route_orders: Dictionary = {}

	for map_id_variant in maps:
		var map_id := str(map_id_variant)
		var map_data: Dictionary = maps[map_id]
		var state := str(map_data.get("content_state", ""))
		if not VALID_CONTENT_STATES.has(state):
			push_error("Map %s has invalid or missing content_state." % map_id)
			failed = true
			continue

		match state:
			"active":
				active_map_ids.append(map_id)
			"legacy":
				legacy_map_ids.append(map_id)
			"development":
				development_map_ids.append(map_id)

		var scene_path := str(map_data.get("scene", ""))
		if scene_path == "" or not ResourceLoader.exists(scene_path):
			push_error("Map %s references a missing scene: %s." % [map_id, scene_path])
			failed = true
			continue

		for connection_variant in map_data.get("connections", []):
			if typeof(connection_variant) != TYPE_DICTIONARY:
				push_error("Map %s has a non-dictionary connection." % map_id)
				failed = true
				continue
			var connection: Dictionary = connection_variant
			var target_id := str(connection.get("to", ""))
			if not maps.has(target_id):
				push_error("Map %s connects to unknown map %s." % [map_id, target_id])
				failed = true
			elif state == "active" and str(maps[target_id].get("content_state", "")) != "active":
				push_error("Active map %s connects to non-active map %s." % [map_id, target_id])
				failed = true

		if state != "active":
			continue

		var route_order := int(map_data.get("route_order", -1))
		if route_order < 0:
			push_error("Active map %s has no valid route_order." % map_id)
			failed = true
		elif route_orders.has(route_order):
			push_error("Active maps %s and %s share route_order %d." % [route_orders[route_order], map_id, route_order])
			failed = true
		else:
			route_orders[route_order] = map_id

		if int(map_data.get("zone_tier", -1)) < 0:
			push_error("Active map %s has no valid zone_tier." % map_id)
			failed = true

		var scene_text := _read_text(scene_path)
		if scene_text == "":
			push_error("Could not read active map scene %s." % scene_path)
			failed = true
			continue
		if scene_text.find("placeholder_tileset") >= 0:
			push_error("Active map %s still uses placeholder_tileset." % map_id)
			failed = true
		if scene_text.find("[node name=\"Background\"") >= 0:
			push_error("Active map %s still uses a flat Background node." % map_id)
			failed = true
		for node_name in REQUIRED_ACTIVE_MAP_NODES:
			if scene_text.find("[node name=\"%s\"" % node_name) < 0:
				push_error("Active map %s is missing required node %s." % [map_id, node_name])
				failed = true
		for layer_name in ["GroundLayer", "DecorLayer", "CollisionLayer", "OverlayLayer"]:
			var layer_pattern := "[node name=\"%s\" type=\"TileMapLayer\"" % layer_name
			if scene_text.find(layer_pattern) < 0:
				push_error("Active map %s does not use TileMapLayer for %s." % [map_id, layer_name])
				failed = true

	for expected_order in range(active_map_ids.size()):
		if not route_orders.has(expected_order):
			push_error("Active map route is missing route_order %d." % expected_order)
			failed = true

	var travel_maps: Array = registry.call("get_travel_maps")
	if travel_maps.size() != active_map_ids.size():
		push_error("Travel map list does not match the active map set.")
		failed = true
	for travel_map_variant in travel_maps:
		if typeof(travel_map_variant) != TYPE_DICTIONARY:
			push_error("Travel map list contains a non-dictionary entry.")
			failed = true
			continue
		var travel_map: Dictionary = travel_map_variant
		var travel_id := str(travel_map.get("id", ""))
		if not active_map_ids.has(travel_id):
			push_error("Travel list exposes non-active map %s." % travel_id)
			failed = true

	return failed

func _validate_quests() -> bool:
	var failed := false
	var signatures: Dictionary = {}

	for quest_id_variant in quests:
		var quest_id := str(quest_id_variant)
		var quest: Dictionary = quests[quest_id]
		var state := str(quest.get("content_state", ""))
		if not VALID_CONTENT_STATES.has(state):
			push_error("Quest %s has invalid or missing content_state." % quest_id)
			failed = true
			continue
		if state == "active":
			active_quest_ids.append(quest_id)
		else:
			legacy_quest_ids.append(quest_id)

		var signature := _quest_signature(quest)
		if signature != "":
			if not signatures.has(signature):
				signatures[signature] = []
			signatures[signature].append(quest_id)

		if state != "active":
			continue

		for prerequisite_variant in quest.get("prerequisites", []):
			var prerequisite := str(prerequisite_variant)
			if not quests.has(prerequisite):
				push_error("Active quest %s references missing prerequisite %s." % [quest_id, prerequisite])
				failed = true
			elif str(quests[prerequisite].get("content_state", "")) != "active":
				push_error("Active quest %s depends on non-active quest %s." % [quest_id, prerequisite])
				failed = true

		for objective_variant in quest.get("objectives", []):
			if typeof(objective_variant) != TYPE_DICTIONARY:
				push_error("Active quest %s has a non-dictionary objective." % quest_id)
				failed = true
				continue
			var objective: Dictionary = objective_variant
			var objective_type := str(objective.get("type", ""))
			var target := str(objective.get("target", objective.get("target_id", "")))
			match objective_type:
				"kill", "boss_kill":
					if not _target_matches_known_id(target, monsters.keys()):
						push_error("Active quest %s targets unknown monster %s." % [quest_id, target])
						failed = true
				"collect":
					if not items.has(target):
						push_error("Active quest %s targets unknown item %s." % [quest_id, target])
						failed = true

		failed = _validate_quest_item_rewards(quest_id, quest) or failed

	for map_id in active_map_ids:
		var quest_id := str(maps[map_id].get("quest_id", ""))
		if quest_id == "":
			continue
		if not quests.has(quest_id):
			push_error("Active map %s references missing quest %s." % [map_id, quest_id])
			failed = true
		elif str(quests[quest_id].get("content_state", "")) != "active":
			push_error("Active map %s references non-active quest %s." % [map_id, quest_id])
			failed = true

	for signature in signatures:
		var ids: Array = signatures[signature]
		if ids.size() < 2:
			continue
		var has_active := false
		var has_non_active := false
		for quest_id in ids:
			if active_quest_ids.has(str(quest_id)):
				has_active = true
			else:
				has_non_active = true
		if has_active and has_non_active:
			push_warning("Active and legacy quests overlap on objective '%s': %s." % [signature, ", ".join(ids)])

	return failed

func _validate_quest_item_rewards(quest_id: String, quest: Dictionary) -> bool:
	var failed := false
	var rewards = quest.get("rewards", {})
	if typeof(rewards) == TYPE_DICTIONARY:
		for entry_variant in rewards.get("items", []):
			if typeof(entry_variant) == TYPE_DICTIONARY:
				var item_id := str(entry_variant.get("item_id", ""))
				if item_id != "" and not items.has(item_id):
					push_error("Active quest %s rewards unknown item %s." % [quest_id, item_id])
					failed = true
	elif typeof(rewards) == TYPE_ARRAY:
		for entry_variant in rewards:
			if typeof(entry_variant) == TYPE_DICTIONARY and str(entry_variant.get("type", "")) == "item":
				var item_id := str(entry_variant.get("target", entry_variant.get("item_id", "")))
				if item_id != "" and not items.has(item_id):
					push_error("Active quest %s rewards unknown item %s." % [quest_id, item_id])
					failed = true
	return failed

func _validate_default_route() -> bool:
	var title_text := _read_text(TITLE_SCREEN_PATH)
	if title_text.find("change_map_to_entry(\"custom_kit_town\", \"entry_default\")") < 0:
		push_error("New Game must start at custom_kit_town entry_default.")
		return true
	return false

func _validate_travel_ownership() -> bool:
	var failed := false
	for script_path in PORTAL_PATHS:
		var script_text := _read_text(script_path)
		if script_text.find("{\"id\":") >= 0:
			push_error("Travel choices are hardcoded in %s instead of DataRegistry." % script_path)
			failed = true
		if script_text.find("DataRegistry.get_travel_maps()") < 0:
			push_error("Travel script %s does not use DataRegistry.get_travel_maps()." % script_path)
			failed = true
	return failed

func _report_known_content_debt() -> void:
	var runtime_painted: Array[String] = []
	for map_id in active_map_ids:
		var scene_path := str(maps[map_id].get("scene", ""))
		if _read_text(scene_path).find("custom_kit_test_map_builder.gd") >= 0:
			runtime_painted.append(map_id)
	if not runtime_painted.is_empty():
		push_warning(
			"Hand-authored map hold: active maps still paint TileMapLayer cells at runtime through custom_kit_test_map_builder.gd: %s."
			% ", ".join(runtime_painted)
		)

	var unresolved_legacy_targets: Array[String] = []
	for quest_id in legacy_quest_ids:
		var quest: Dictionary = quests[quest_id]
		for objective_variant in quest.get("objectives", []):
			if typeof(objective_variant) != TYPE_DICTIONARY:
				continue
			var objective: Dictionary = objective_variant
			var objective_type := str(objective.get("type", ""))
			var target := str(objective.get("target", objective.get("target_id", "")))
			if objective_type in ["kill", "boss_kill"] and not _target_matches_known_id(target, monsters.keys()):
				unresolved_legacy_targets.append("%s:%s" % [quest_id, target])
	if not unresolved_legacy_targets.is_empty():
		push_warning("Legacy quest targets remain unresolved: %s." % ", ".join(unresolved_legacy_targets))

	var serialized_travel_lists: Array[String] = []
	_collect_serialized_travel_lists("res://scenes/maps", serialized_travel_lists)
	if not serialized_travel_lists.is_empty():
		push_warning(
			"Legacy scenes retain ignored serialized available_maps lists: %s."
			% ", ".join(serialized_travel_lists)
		)

func _report_duplicate_assets() -> void:
	var asset_paths: Array[String] = []
	_collect_asset_files("res://assets", asset_paths)
	var hashes: Dictionary = {}
	for asset_path in asset_paths:
		var hash := FileAccess.get_md5(asset_path)
		if hash == "":
			continue
		if not hashes.has(hash):
			hashes[hash] = []
		hashes[hash].append(asset_path)
	for hash in hashes:
		var duplicates: Array = hashes[hash]
		if duplicates.size() > 1:
			push_warning("Byte-identical assets share hash %s: %s." % [hash, ", ".join(duplicates)])

func _collect_asset_files(path: String, result: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file_name in dir.get_files():
		var extension := file_name.get_extension().to_lower()
		if extension in ["png", "jpg", "jpeg", "webp", "ogg", "wav"]:
			result.append(path.path_join(file_name))
	for directory_name in dir.get_directories():
		_collect_asset_files(path.path_join(directory_name), result)

func _collect_serialized_travel_lists(path: String, result: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file_name in dir.get_files():
		if not file_name.ends_with(".tscn"):
			continue
		var scene_path := path.path_join(file_name)
		if _read_text(scene_path).find("available_maps = Array") >= 0:
			result.append(scene_path)
	for directory_name in dir.get_directories():
		_collect_serialized_travel_lists(path.path_join(directory_name), result)

func _quest_signature(quest: Dictionary) -> String:
	var parts: Array[String] = []
	for objective_variant in quest.get("objectives", []):
		if typeof(objective_variant) != TYPE_DICTIONARY:
			continue
		var objective: Dictionary = objective_variant
		parts.append("%s:%s:%d" % [
			str(objective.get("type", "")),
			str(objective.get("target", objective.get("target_id", ""))),
			int(objective.get("required", 0))
		])
	parts.sort()
	return "|".join(parts)

func _target_matches_known_id(target: String, known_ids: Array) -> bool:
	if target == "":
		return false
	for known_id_variant in known_ids:
		var known_id := str(known_id_variant)
		if target == known_id or known_id.begins_with(target + "_"):
			return true
	return false

func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""
