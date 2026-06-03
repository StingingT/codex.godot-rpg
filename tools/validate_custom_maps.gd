extends SceneTree

const MAPS_PATH := "res://data/maps/maps.json"
const ENCOUNTERS_PATH := "res://data/encounters/encounters.json"
const MONSTERS_PATH := "res://data/monsters/monsters.json"
const QUESTS_PATH := "res://data/quests"

const SOURCE_ENVIRONMENT := 1

const VOID_WATER := Vector2i(0, 0)
const CLIFF := Vector2i(2, 0)
const MARSH_WATER := Vector2i(3, 0)
const BRIDGE_PLANK := Vector2i(4, 0)

const CUSTOM_ROUTE: Array[String] = [
	"custom_kit_town",
	"custom_kit_field",
	"custom_kit_ruins",
	"custom_kit_marsh",
	"custom_kit_catacombs",
	"custom_kit_dark_keep"
]

const REQUIRED_STRUCTURE: Array[String] = [
	"GroundLayer",
	"DecorLayer",
	"CollisionLayer",
	"OverlayLayer",
	"YSortedObjects",
	"EntryPoints",
	"ExitTriggers",
	"SpawnPoints",
	"BossSpawnPoint",
	"Portals",
	"NPCs",
	"Items",
	"CameraLimits",
	"SpawnManager"
]

const REQUIRED_ENTRIES: Array[String] = [
	"entry_default",
	"entry_west",
	"entry_east",
	"entry_north",
	"entry_south"
]

const ENTRY_CLEARANCE := 24.0
const PORTAL_CLEARANCE := 24.0
const SPAWN_CLEARANCE := 24.0
const SPAWN_DISTANCE_FROM_ENTRY_OR_PORTAL := 32.0
const BOSS_ARENA_CLEARANCE := 64.0
const MIN_GROUND_CELLS := 500
const MIN_DECOR_CELLS := 8

const MAPS_WITH_BLOCKED_WATER: Array[String] = [
	"custom_kit_field",
	"custom_kit_marsh"
]

const MAPS_WITH_BLOCKED_CLIFFS: Array[String] = [
	"custom_kit_catacombs",
	"custom_kit_dark_keep"
]

const MAPS_WITH_PASSABLE_BRIDGES: Array[String] = [
	"custom_kit_field",
	"custom_kit_marsh"
]

var maps: Dictionary = {}
var encounters: Dictionary = {}
var monsters: Dictionary = {}
var quests: Dictionary = {}
var scene_cache: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var failed := false
	maps = _load_json(MAPS_PATH)
	encounters = _load_json(ENCOUNTERS_PATH)
	monsters = _load_json(MONSTERS_PATH)
	quests = _load_quest_folder()

	if maps.is_empty() or encounters.is_empty() or monsters.is_empty():
		quit(1)
		return

	failed = _validate_route_quest_chain() or failed

	for index in range(CUSTOM_ROUTE.size()):
		var map_id := CUSTOM_ROUTE[index]
		failed = _validate_map_metadata(map_id, index) or failed
		var map_root := _instantiate_map(map_id)
		if map_root == null:
			failed = true
			continue
		failed = _validate_scene_contract(map_id, map_root) or failed
		_paint_runtime_tile_layers(map_root)
		failed = _validate_generated_tile_layout(map_id, map_root) or failed
		failed = _validate_portals(map_id, map_root) or failed
		failed = _validate_quest_link(map_id) or failed
		failed = _validate_spatial_safety(map_id, map_root) or failed
		map_root.queue_free()
		await process_frame

	quit(1 if failed else 0)

func _validate_map_metadata(map_id: String, expected_order: int) -> bool:
	var failed := false
	if not maps.has(map_id):
		push_error("Missing custom map metadata: %s" % map_id)
		return true

	var map_data: Dictionary = maps[map_id]
	if not ResourceLoader.exists(str(map_data.get("scene", ""))):
		push_error("Map scene does not exist for %s: %s" % [map_id, str(map_data.get("scene", ""))])
		failed = true
	if str(map_data.get("biome", "")) == "":
		push_error("Map missing biome: %s" % map_id)
		failed = true
	if int(map_data.get("zone_tier", -1)) < 0:
		push_error("Map missing valid zone_tier: %s" % map_id)
		failed = true
	if int(map_data.get("route_order", -1)) != expected_order:
		push_error("Map route_order mismatch for %s. Expected %d." % [map_id, expected_order])
		failed = true

	var encounter_id := str(map_data.get("encounter_table", ""))
	if not encounters.has(encounter_id):
		push_error("Missing encounter table '%s' for map %s." % [encounter_id, map_id])
		failed = true

	for connection in map_data.get("connections", []):
		if typeof(connection) != TYPE_DICTIONARY:
			push_error("Invalid connection entry for map %s." % map_id)
			failed = true
			continue
		if not maps.has(str(connection.get("to", ""))):
			push_error("Connection target missing for %s: %s" % [map_id, str(connection.get("to", ""))])
			failed = true
		if str(connection.get("via", "")) == "":
			push_error("Connection via missing for %s -> %s." % [map_id, str(connection.get("to", ""))])
			failed = true
		if str(connection.get("spawn_at", "")) == "":
			push_error("Connection spawn_at missing for %s." % map_id)
			failed = true
		elif maps.has(str(connection.get("to", ""))):
			var target_root := _instantiate_map(str(connection.get("to", "")))
			if target_root == null:
				failed = true
			else:
				if target_root.get_node_or_null("EntryPoints/%s" % str(connection.get("spawn_at", ""))) == null:
					push_error("Connection from %s targets missing entry %s on %s." % [map_id, str(connection.get("spawn_at", "")), str(connection.get("to", ""))])
					failed = true
				target_root.queue_free()
	return failed

func _validate_scene_contract(map_id: String, map_root: Node) -> bool:
	var failed := false
	if not map_root is Node2D:
		push_error("Map root must be Node2D: %s" % map_id)
		failed = true
	if map_root is Node2D and not (map_root as Node2D).y_sort_enabled:
		push_error("Map root should have y_sort_enabled=true: %s" % map_id)
		failed = true

	for node_path in REQUIRED_STRUCTURE:
		if map_root.get_node_or_null(node_path) == null:
			push_error("Map %s missing node: %s" % [map_id, node_path])
			failed = true

	for layer_path in ["GroundLayer", "DecorLayer", "CollisionLayer", "OverlayLayer"]:
		var layer := map_root.get_node_or_null(layer_path)
		if layer != null and not layer is TileMapLayer:
			push_error("Map %s node %s must be TileMapLayer." % [map_id, layer_path])
			failed = true

	var entry_parent := map_root.get_node_or_null("EntryPoints")
	if entry_parent:
		for entry_name in REQUIRED_ENTRIES:
			var entry := entry_parent.get_node_or_null(entry_name)
			if entry == null or not entry is Marker2D:
				push_error("Map %s missing entry marker: %s" % [map_id, entry_name])
				failed = true

	var spawn_parent := map_root.get_node_or_null("SpawnPoints")
	if map_id != "custom_kit_town" and spawn_parent:
		var marker_count := 0
		for child in spawn_parent.get_children():
			if child is Marker2D:
				marker_count += 1
		if marker_count < 3:
			push_error("Monster map %s needs at least 3 spawn markers." % map_id)
			failed = true

	var spawn_manager := map_root.get_node_or_null("SpawnManager")
	if spawn_manager:
		if str(spawn_manager.get("map_id")) != map_id:
			push_error("SpawnManager map_id mismatch on %s." % map_id)
			failed = true
		var expected_table := str(maps[map_id].get("encounter_table", ""))
		if str(spawn_manager.get("encounter_table_id")) != expected_table:
			push_error("SpawnManager encounter_table_id mismatch on %s." % map_id)
			failed = true

	return failed

func _paint_runtime_tile_layers(map_root: Node) -> void:
	if not map_root.has_method("_paint_town"):
		return
	var ground_layer := map_root.get_node_or_null("GroundLayer")
	var decor_layer := map_root.get_node_or_null("DecorLayer")
	var collision_layer := map_root.get_node_or_null("CollisionLayer")
	var overlay_layer := map_root.get_node_or_null("OverlayLayer")
	if ground_layer == null or decor_layer == null or collision_layer == null or overlay_layer == null:
		return
	map_root.set("ground_layer", ground_layer)
	map_root.set("decor_layer", decor_layer)
	map_root.set("collision_layer", collision_layer)
	map_root.set("overlay_layer", overlay_layer)
	match str(map_root.get("map_type")):
		"field":
			map_root.call("_paint_field")
		"ruins":
			map_root.call("_paint_ruins")
		"marsh":
			map_root.call("_paint_marsh")
		"catacombs":
			map_root.call("_paint_catacombs")
		"dark_keep":
			map_root.call("_paint_dark_keep")
		_:
			map_root.call("_paint_town")

func _validate_generated_tile_layout(map_id: String, map_root: Node) -> bool:
	var failed := false
	var ground_layer := map_root.get_node_or_null("GroundLayer") as TileMapLayer
	var decor_layer := map_root.get_node_or_null("DecorLayer") as TileMapLayer
	var collision_layer := map_root.get_node_or_null("CollisionLayer") as TileMapLayer
	if ground_layer == null or decor_layer == null or collision_layer == null:
		return true

	if ground_layer.get_used_cells().size() < MIN_GROUND_CELLS:
		push_error("Map %s generated too few ground tiles: %d." % [map_id, ground_layer.get_used_cells().size()])
		failed = true
	if decor_layer.get_used_cells().size() < MIN_DECOR_CELLS:
		push_error("Map %s generated too few decor tiles: %d." % [map_id, decor_layer.get_used_cells().size()])
		failed = true

	failed = _validate_water_tiles_are_blocked(map_id, ground_layer, collision_layer) or failed
	failed = _validate_cliff_tiles_are_blocked(map_id, decor_layer, collision_layer) or failed
	failed = _validate_bridge_tiles_are_passable(map_id, ground_layer, collision_layer, map_root) or failed
	failed = _validate_runtime_points_on_walkable_tiles(map_id, map_root, ground_layer, collision_layer) or failed
	return failed

func _validate_water_tiles_are_blocked(map_id: String, ground_layer: TileMapLayer, collision_layer: TileMapLayer) -> bool:
	var failed := false
	var water_cells := _get_cells_matching(ground_layer, SOURCE_ENVIRONMENT, VOID_WATER)
	water_cells.append_array(_get_cells_matching(ground_layer, SOURCE_ENVIRONMENT, MARSH_WATER))
	if MAPS_WITH_BLOCKED_WATER.has(map_id) and water_cells.is_empty():
		push_error("Map %s should generate blocked water tiles." % map_id)
		return true
	for cell in water_cells:
		if not _is_cell_occupied(collision_layer, cell):
			push_error("Map %s has an unblocked water tile at %s." % [map_id, str(cell)])
			failed = true
	return failed

func _validate_cliff_tiles_are_blocked(map_id: String, decor_layer: TileMapLayer, collision_layer: TileMapLayer) -> bool:
	var failed := false
	var cliff_cells := _get_cells_matching(decor_layer, SOURCE_ENVIRONMENT, CLIFF)
	if MAPS_WITH_BLOCKED_CLIFFS.has(map_id) and cliff_cells.is_empty():
		push_error("Map %s should generate blocked cliff tiles." % map_id)
		return true
	for cell in cliff_cells:
		if not _is_cell_occupied(collision_layer, cell):
			push_error("Map %s has an unblocked cliff tile at %s." % [map_id, str(cell)])
			failed = true
	return failed

func _validate_bridge_tiles_are_passable(map_id: String, ground_layer: TileMapLayer, collision_layer: TileMapLayer, map_root: Node) -> bool:
	var failed := false
	var bridge_cells := _get_cells_matching(ground_layer, SOURCE_ENVIRONMENT, BRIDGE_PLANK)
	if MAPS_WITH_PASSABLE_BRIDGES.has(map_id) and bridge_cells.is_empty():
		push_error("Map %s should generate passable bridge tiles." % map_id)
		return true
	for cell in bridge_cells:
		if _is_cell_occupied(collision_layer, cell):
			push_error("Map %s has a blocked bridge tile at %s." % [map_id, str(cell)])
			failed = true
	if MAPS_WITH_PASSABLE_BRIDGES.has(map_id) and map_root.get_node_or_null("YSortedObjects/BoneBridge") == null:
		push_error("Map %s should place a BoneBridge object with its bridge tiles." % map_id)
		failed = true
	return failed

func _get_cells_matching(layer: TileMapLayer, source_id: int, atlas_coords: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in layer.get_used_cells():
		if layer.get_cell_source_id(cell) == source_id and layer.get_cell_atlas_coords(cell) == atlas_coords:
			result.append(cell)
	return result

func _is_cell_occupied(layer: TileMapLayer, cell: Vector2i) -> bool:
	return layer.get_cell_source_id(cell) != -1

func _validate_runtime_points_on_walkable_tiles(map_id: String, map_root: Node, ground_layer: TileMapLayer, collision_layer: TileMapLayer) -> bool:
	var failed := false
	var points: Array[Dictionary] = []
	var entry_parent := map_root.get_node_or_null("EntryPoints")
	if entry_parent:
		for entry_name in REQUIRED_ENTRIES:
			var entry := entry_parent.get_node_or_null(entry_name) as Marker2D
			if entry:
				points.append({"label": "EntryPoints/%s" % entry_name, "position": entry.global_position})
	var portals := map_root.get_node_or_null("Portals")
	if portals:
		for portal in portals.get_children():
			if portal is Node2D:
				points.append({"label": "Portals/%s" % portal.name, "position": (portal as Node2D).global_position})
	var spawn_parent := map_root.get_node_or_null("SpawnPoints")
	if spawn_parent:
		for spawn in spawn_parent.get_children():
			if spawn is Marker2D:
				points.append({"label": "SpawnPoints/%s" % spawn.name, "position": (spawn as Marker2D).global_position})
	var boss := map_root.get_node_or_null("BossSpawnPoint") as Marker2D
	if boss and map_id != "custom_kit_town":
		points.append({"label": "BossSpawnPoint", "position": boss.global_position})

	for point in points:
		var local_position := ground_layer.to_local(point["position"])
		var cell := ground_layer.local_to_map(local_position)
		if not _is_cell_occupied(ground_layer, cell):
			push_error("Map %s point %s is not on generated ground at tile %s." % [map_id, str(point["label"]), str(cell)])
			failed = true
		if _is_cell_occupied(collision_layer, cell):
			push_error("Map %s point %s is on a blocked collision tile at %s." % [map_id, str(point["label"]), str(cell)])
			failed = true
	return failed

func _validate_portals(map_id: String, map_root: Node) -> bool:
	var failed := false
	var portals := map_root.get_node_or_null("Portals")
	if portals == null:
		return true

	var has_back := portals.get_node_or_null("BackPortal") != null
	var has_next := portals.get_node_or_null("NextPortal") != null
	var has_town := portals.get_node_or_null("TownPortal") != null
	if map_id != "custom_kit_town" and not has_back:
		push_error("Monster map %s missing BackPortal." % map_id)
		failed = true
	if map_id != "custom_kit_town" and map_id != "custom_kit_dark_keep" and not has_next:
		push_error("Monster map %s missing NextPortal." % map_id)
		failed = true
	if map_id == "custom_kit_dark_keep" and not has_town:
		push_error("Final map custom_kit_dark_keep missing TownPortal.")
		failed = true

	var route_index := CUSTOM_ROUTE.find(map_id)
	if route_index > 0:
		var back_portal := portals.get_node_or_null("BackPortal")
		if back_portal and str(back_portal.get("target_map")) != CUSTOM_ROUTE[route_index - 1]:
			push_error("BackPortal on %s should target %s." % [map_id, CUSTOM_ROUTE[route_index - 1]])
			failed = true
	if route_index >= 0 and route_index < CUSTOM_ROUTE.size() - 1:
		var next_portal := portals.get_node_or_null("NextPortal")
		if next_portal and str(next_portal.get("target_map")) != CUSTOM_ROUTE[route_index + 1]:
			push_error("NextPortal on %s should target %s." % [map_id, CUSTOM_ROUTE[route_index + 1]])
			failed = true
	if map_id == "custom_kit_dark_keep":
		var town_portal := portals.get_node_or_null("TownPortal")
		if town_portal and str(town_portal.get("target_map")) != "custom_kit_town":
			push_error("TownPortal on custom_kit_dark_keep should target custom_kit_town.")
			failed = true
	failed = _validate_route_portal_quest_gates(map_id, portals) or failed

	for portal in portals.get_children():
		var target_map := str(portal.get("target_map"))
		var target_entry := str(portal.get("target_entry"))
		if target_map == "":
			continue
		if not maps.has(target_map):
			push_error("Portal %s/%s targets missing map: %s" % [map_id, portal.name, target_map])
			failed = true
			continue
		if target_entry == "":
			push_error("Portal %s/%s missing target_entry." % [map_id, portal.name])
			failed = true
			continue
		var target_root := _instantiate_map(target_map)
		if target_root == null:
			failed = true
			continue
		if target_root.get_node_or_null("EntryPoints/%s" % target_entry) == null:
			push_error("Portal %s/%s targets missing entry %s on %s." % [map_id, portal.name, target_entry, target_map])
			failed = true
		failed = _validate_portal_has_metadata_connection(map_id, portal.name, target_map, target_entry) or failed
		target_root.queue_free()
	failed = _validate_metadata_connections_have_portals(map_id, portals) or failed
	return failed

func _validate_route_portal_quest_gates(map_id: String, portals: Node) -> bool:
	var failed := false
	var route_index := CUSTOM_ROUTE.find(map_id)
	if route_index < 1:
		return false
	var quest_id := str(maps[map_id].get("quest_id", ""))
	if quest_id == "":
		return true

	var back_portal := portals.get_node_or_null("BackPortal")
	if back_portal and str(back_portal.get("required_quest_id")) != "":
		push_error("BackPortal on %s should not be quest-gated." % map_id)
		failed = true

	if map_id == "custom_kit_dark_keep":
		var town_portal := portals.get_node_or_null("TownPortal")
		if town_portal == null:
			return true
		if str(town_portal.get("required_quest_id")) != quest_id:
			push_error("TownPortal on %s should require quest %s." % [map_id, quest_id])
			failed = true
		if bool(town_portal.get("required_quest_turned_in")):
			push_error("TownPortal on %s should require quest completion, not turn-in." % map_id)
			failed = true
		return failed

	var next_portal := portals.get_node_or_null("NextPortal")
	if next_portal == null:
		return true
	if str(next_portal.get("required_quest_id")) != quest_id:
		push_error("NextPortal on %s should require quest %s." % [map_id, quest_id])
		failed = true
	if not bool(next_portal.get("required_quest_turned_in")):
		push_error("NextPortal on %s should require quest turn-in before route progression." % map_id)
		failed = true
	return failed

func _validate_portal_has_metadata_connection(map_id: String, portal_name: String, target_map: String, target_entry: String) -> bool:
	if not maps.has(map_id):
		return true
	for connection in maps[map_id].get("connections", []):
		if typeof(connection) != TYPE_DICTIONARY:
			continue
		if str(connection.get("to", "")) == target_map and str(connection.get("spawn_at", "")) == target_entry:
			return false
	push_error("Portal %s/%s targets %s:%s but maps.json has no matching connection." % [map_id, portal_name, target_map, target_entry])
	return true

func _validate_metadata_connections_have_portals(map_id: String, portals: Node) -> bool:
	var failed := false
	if not maps.has(map_id):
		return true
	for connection in maps[map_id].get("connections", []):
		if typeof(connection) != TYPE_DICTIONARY:
			continue
		var target_map := str(connection.get("to", ""))
		var target_entry := str(connection.get("spawn_at", ""))
		if target_map == "" or target_entry == "":
			continue
		if not _has_portal_targeting(portals, target_map, target_entry):
			push_error("Map %s has maps.json connection to %s:%s but no matching direct portal." % [map_id, target_map, target_entry])
			failed = true
	return failed

func _has_portal_targeting(portals: Node, target_map: String, target_entry: String) -> bool:
	for portal in portals.get_children():
		if str(portal.get("target_map")) == target_map and str(portal.get("target_entry")) == target_entry:
			return true
	return false

func _validate_quest_link(map_id: String) -> bool:
	if map_id == "custom_kit_town":
		return false
	var failed := false
	var quest_id := str(maps[map_id].get("quest_id", ""))
	if quest_id == "":
		push_error("Monster map %s missing quest_id metadata." % map_id)
		return true
	if not quests.has(quest_id):
		push_error("Map %s references missing quest: %s" % [map_id, quest_id])
		return true
	var quest: Dictionary = quests[quest_id]
	if str(quest.get("quest_id", "")) != quest_id:
		push_error("Quest file data mismatch for %s." % quest_id)
		failed = true
	if str(quest.get("quest_name", quest.get("title", ""))) == "":
		push_error("Quest %s missing quest_name/title." % quest_id)
		failed = true
	if str(quest.get("description", "")) == "":
		push_error("Quest %s missing description." % quest_id)
		failed = true
	if int(quest.get("level_requirement", 0)) > int(maps[map_id].get("zone_tier", 0)) + 1:
		push_error("Quest %s level_requirement is too high for map zone_tier." % quest_id)
		failed = true
	if str(quest.get("giver", "")) != "quest_giver" or str(quest.get("turn_in", "")) != "quest_giver":
		push_error("Quest %s should use quest_giver as giver and turn_in." % quest_id)
		failed = true
	failed = _validate_quest_prerequisite(map_id, quest_id, quest) or failed
	failed = _validate_quest_rewards(quest_id, quest) or failed
	failed = _validate_quest_objectives(map_id, quest_id, quest) or failed
	return failed

func _validate_route_quest_chain() -> bool:
	var failed := false
	var expected_chain := _get_route_quest_ids()
	var town_root := _instantiate_map("custom_kit_town")
	if town_root == null:
		return true
	var quest_giver := town_root.get_node_or_null("NPCs/QuestGiver")
	if quest_giver == null:
		push_error("custom_kit_town missing NPCs/QuestGiver for custom route quests.")
		town_root.queue_free()
		return true
	var actual_chain: Array[String] = []
	for quest_id in quest_giver.get("quest_chain"):
		actual_chain.append(str(quest_id))
	if actual_chain != expected_chain:
		push_error("Custom town QuestGiver quest_chain does not match route quest metadata. Expected %s got %s." % [str(expected_chain), str(actual_chain)])
		failed = true
	town_root.queue_free()
	return failed

func _get_route_quest_ids() -> Array[String]:
	var result: Array[String] = []
	for index in range(1, CUSTOM_ROUTE.size()):
		var map_id := CUSTOM_ROUTE[index]
		if maps.has(map_id):
			var quest_id := str(maps[map_id].get("quest_id", ""))
			if quest_id != "":
				result.append(quest_id)
	return result

func _validate_quest_prerequisite(map_id: String, quest_id: String, quest: Dictionary) -> bool:
	var route_index := CUSTOM_ROUTE.find(map_id)
	if route_index <= 1:
		return false
	var previous_map_id := CUSTOM_ROUTE[route_index - 1]
	var expected_prereq := str(maps[previous_map_id].get("quest_id", ""))
	var prerequisites: Array = quest.get("prerequisites", [])
	if not prerequisites.has(expected_prereq):
		push_error("Quest %s should require previous route quest %s." % [quest_id, expected_prereq])
		return true
	return false

func _validate_quest_rewards(quest_id: String, quest: Dictionary) -> bool:
	var rewards = quest.get("rewards", {})
	if typeof(rewards) != TYPE_DICTIONARY:
		push_error("Quest %s rewards must be a dictionary for the custom route." % quest_id)
		return true
	var failed := false
	if int(rewards.get("xp", 0)) <= 0:
		push_error("Quest %s missing positive xp reward." % quest_id)
		failed = true
	if int(rewards.get("gold", 0)) <= 0:
		push_error("Quest %s missing positive gold reward." % quest_id)
		failed = true
	if not rewards.has("items") or typeof(rewards.get("items")) != TYPE_ARRAY:
		push_error("Quest %s rewards should include an items array." % quest_id)
		failed = true
	return failed

func _validate_quest_objectives(map_id: String, quest_id: String, quest: Dictionary) -> bool:
	var failed := false
	var objectives: Array = quest.get("objectives", [])
	if objectives.is_empty():
		push_error("Quest %s needs at least one objective." % quest_id)
		return true
	var encounter_id := str(maps[map_id].get("encounter_table", ""))
	var encounter: Dictionary = encounters.get(encounter_id, {})
	var encounter_monsters := _get_encounter_monster_ids(encounter)
	for objective in objectives:
		if typeof(objective) != TYPE_DICTIONARY:
			push_error("Quest %s has an invalid objective entry." % quest_id)
			failed = true
			continue
		var objective_type := str(objective.get("type", ""))
		if objective_type != "kill":
			push_error("Custom route quest %s should use kill objectives for now." % quest_id)
			failed = true
			continue
		var target := str(objective.get("target", objective.get("target_id", "")))
		if target == "":
			push_error("Quest %s has a kill objective without target." % quest_id)
			failed = true
			continue
		if int(objective.get("required", 0)) <= 0:
			push_error("Quest %s objective %s has invalid required count." % [quest_id, target])
			failed = true
		if not _target_matches_any_monster(target, monsters.keys()):
			push_error("Quest %s target %s does not match any known monster id." % [quest_id, target])
			failed = true
		if not _target_matches_any_monster(target, encounter_monsters):
			push_error("Quest %s target %s is not present in encounter table %s." % [quest_id, target, encounter_id])
			failed = true
	return failed

func _get_encounter_monster_ids(encounter: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for spawn in encounter.get("ambient_spawns", []):
		if typeof(spawn) == TYPE_DICTIONARY:
			var monster_id := str(spawn.get("monster_id", ""))
			if monster_id != "":
				result.append(monster_id)
	var boss: Dictionary = encounter.get("boss", {})
	var boss_id := str(boss.get("monster_id", ""))
	if boss_id != "":
		result.append(boss_id)
	for monster_id in result:
		if not monsters.has(monster_id):
			push_error("Encounter references unknown monster id: %s" % monster_id)
	return result

func _target_matches_any_monster(target: String, monster_ids: Array) -> bool:
	for monster_id_variant in monster_ids:
		var monster_id := str(monster_id_variant)
		if monster_id == target or monster_id.begins_with(target + "_"):
			return true
	return false

func _validate_spatial_safety(map_id: String, map_root: Node) -> bool:
	var failed := false
	var blockers := _collect_world_blockers(map_root)
	var portal_positions := _collect_marker_positions(map_root.get_node_or_null("Portals"))
	var entry_parent := map_root.get_node_or_null("EntryPoints")
	if entry_parent:
		for entry_name in REQUIRED_ENTRIES:
			var entry := entry_parent.get_node_or_null(entry_name) as Marker2D
			if entry == null:
				continue
			if _is_too_close_to_blocker(entry.global_position, blockers, ENTRY_CLEARANCE):
				push_error("Entry marker %s/%s is too close to world collision." % [map_id, entry_name])
				failed = true
			if _is_too_close_to_points(entry.global_position, portal_positions, PORTAL_CLEARANCE, ""):
				push_error("Entry marker %s/%s is too close to a portal." % [map_id, entry_name])
				failed = true

	var portals := map_root.get_node_or_null("Portals")
	if portals:
		for portal in portals.get_children():
			if portal is Node2D and _is_too_close_to_blocker((portal as Node2D).global_position, blockers, PORTAL_CLEARANCE):
				push_error("Portal %s/%s is too close to world collision." % [map_id, portal.name])
				failed = true

	var spawn_parent := map_root.get_node_or_null("SpawnPoints")
	if spawn_parent:
		var entry_positions := _collect_marker_positions(entry_parent)
		for child in spawn_parent.get_children():
			if child is Marker2D:
				var spawn := child as Marker2D
				if _is_too_close_to_blocker(spawn.global_position, blockers, SPAWN_CLEARANCE):
					push_error("Spawn marker %s/%s is too close to world collision." % [map_id, spawn.name])
					failed = true
				if _is_too_close_to_points(spawn.global_position, entry_positions, SPAWN_DISTANCE_FROM_ENTRY_OR_PORTAL, ""):
					push_error("Spawn marker %s/%s is too close to an entry point." % [map_id, spawn.name])
					failed = true
				if _is_too_close_to_points(spawn.global_position, portal_positions, SPAWN_DISTANCE_FROM_ENTRY_OR_PORTAL, ""):
					push_error("Spawn marker %s/%s is too close to a portal." % [map_id, spawn.name])
					failed = true

	var boss := map_root.get_node_or_null("BossSpawnPoint") as Marker2D
	if boss and map_id != "custom_kit_town":
		if _is_too_close_to_blocker(boss.global_position, blockers, BOSS_ARENA_CLEARANCE):
			push_error("BossSpawnPoint on %s does not have the required arena clearance." % map_id)
			failed = true
		if _is_too_close_to_points(boss.global_position, portal_positions, SPAWN_DISTANCE_FROM_ENTRY_OR_PORTAL, ""):
			push_error("BossSpawnPoint on %s is too close to a portal." % map_id)
			failed = true

	return failed

func _collect_world_blockers(root: Node) -> Array[Dictionary]:
	var blockers: Array[Dictionary] = []
	_collect_world_blockers_recursive(root, blockers)
	_collect_collision_layer_blockers(root, blockers)
	return blockers

func _collect_collision_layer_blockers(root: Node, blockers: Array[Dictionary]) -> void:
	var collision_layer := root.get_node_or_null("CollisionLayer") as TileMapLayer
	if collision_layer == null:
		return
	var tile_size := Vector2(32.0, 32.0)
	if collision_layer.tile_set:
		var tile_size_i := collision_layer.tile_set.tile_size
		tile_size = Vector2(float(tile_size_i.x), float(tile_size_i.y))
	for cell in collision_layer.get_used_cells():
		blockers.append({
			"type": "rect",
			"position": collision_layer.to_global(collision_layer.map_to_local(cell)),
			"half_extents": tile_size * 0.5
		})

func _collect_world_blockers_recursive(node: Node, blockers: Array[Dictionary]) -> void:
	if node is CollisionShape2D:
		var collision_shape := node as CollisionShape2D
		var body := collision_shape.get_parent()
		if body is StaticBody2D and int((body as StaticBody2D).collision_layer) & 2 != 0:
			var shape := collision_shape.shape
			if shape is RectangleShape2D:
				blockers.append({
					"type": "rect",
					"position": collision_shape.global_position,
					"half_extents": (shape as RectangleShape2D).size * 0.5
				})
			elif shape is CircleShape2D:
				blockers.append({
					"type": "circle",
					"position": collision_shape.global_position,
					"radius": (shape as CircleShape2D).radius
				})
	for child in node.get_children():
		_collect_world_blockers_recursive(child, blockers)

func _collect_marker_positions(parent: Node) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if parent == null:
		return points
	for child in parent.get_children():
		if child is Node2D:
			points.append((child as Node2D).global_position)
	return points

func _is_too_close_to_blocker(point: Vector2, blockers: Array[Dictionary], clearance: float) -> bool:
	for blocker in blockers:
		if _distance_to_blocker(point, blocker) < clearance:
			return true
	return false

func _distance_to_blocker(point: Vector2, blocker: Dictionary) -> float:
	var center := blocker.get("position", Vector2.ZERO) as Vector2
	match str(blocker.get("type", "")):
		"rect":
			var half_extents := blocker.get("half_extents", Vector2.ZERO) as Vector2
			var delta := (point - center).abs() - half_extents
			if delta.x <= 0.0 and delta.y <= 0.0:
				return 0.0
			return Vector2(max(delta.x, 0.0), max(delta.y, 0.0)).length()
		"circle":
			return max(point.distance_to(center) - float(blocker.get("radius", 0.0)), 0.0)
	return INF

func _is_too_close_to_points(point: Vector2, points: Array[Vector2], clearance: float, ignore_name: String) -> bool:
	for other in points:
		if point == other:
			continue
		if point.distance_to(other) < clearance:
			return true
	return false

func _instantiate_map(map_id: String) -> Node:
	if not maps.has(map_id):
		push_error("Cannot instantiate missing map: %s" % map_id)
		return null
	var scene_path := str(maps[map_id].get("scene", ""))
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Could not load map scene: %s" % scene_path)
		return null
	var instance := packed.instantiate()
	if instance == null:
		push_error("Could not instantiate map scene: %s" % scene_path)
	return instance

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing JSON file: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK:
		push_error("JSON parse error in %s: %s" % [path, json.get_error_message()])
		return {}
	return json.data if typeof(json.data) == TYPE_DICTIONARY else {}

func _load_quest_folder() -> Dictionary:
	var result: Dictionary = {}
	var dir := DirAccess.open(QUESTS_PATH)
	if dir == null:
		push_error("Missing quest folder: %s" % QUESTS_PATH)
		return result
	for file_name in dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		var quest := _load_json(QUESTS_PATH.path_join(file_name))
		if not quest.is_empty():
			result[str(quest.get("quest_id", file_name.get_basename()))] = quest
	return result
