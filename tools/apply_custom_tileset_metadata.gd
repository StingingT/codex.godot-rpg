extends SceneTree

const TILESET_PATH := "res://assets/tilesets/custom/rpg_tileset.tres"

const SOURCE_GROUND := 0
const SOURCE_ENVIRONMENT := 1
const SOURCE_BUILDING := 2
const SOURCE_OBJECT := 3
const SOURCE_ROUTE := 4

const FULL_TILE_POLYGON := [
	Vector2(-16, -16),
	Vector2(16, -16),
	Vector2(16, 16),
	Vector2(-16, 16),
]

const CUSTOM_DATA_LAYERS := [
	{"name": "terrain_type", "type": TYPE_STRING},
	{"name": "biome", "type": TYPE_STRING},
	{"name": "zone_tier", "type": TYPE_INT},
	{"name": "is_walkable", "type": TYPE_BOOL},
	{"name": "is_water", "type": TYPE_BOOL},
	{"name": "is_damage_tile", "type": TYPE_BOOL},
	{"name": "encounter_weight", "type": TYPE_FLOAT},
	{"name": "is_interactable", "type": TYPE_BOOL},
	{"name": "interaction_id", "type": TYPE_STRING},
	{"name": "footstep_sound", "type": TYPE_STRING},
	{"name": "movement_modifier", "type": TYPE_FLOAT},
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var tile_set := load(TILESET_PATH) as TileSet
	if tile_set == null:
		push_error("Could not load custom tileset: %s" % TILESET_PATH)
		quit(1)
		return

	_ensure_custom_data_layers(tile_set)
	_apply_ground_metadata(tile_set)
	_apply_environment_metadata(tile_set)
	_apply_building_metadata(tile_set)
	_apply_object_metadata(tile_set)
	_apply_route_metadata(tile_set)

	var save_result := ResourceSaver.save(tile_set, TILESET_PATH)
	if save_result != OK:
		push_error("Could not save custom tileset: %s" % error_string(save_result))
		quit(1)
		return

	print("Applied custom tile metadata and blocking collision.")
	quit()

func _ensure_custom_data_layers(tile_set: TileSet) -> void:
	var existing := {}
	for index in range(tile_set.get_custom_data_layers_count()):
		existing[str(tile_set.get_custom_data_layer_name(index))] = index

	for layer in CUSTOM_DATA_LAYERS:
		var layer_name := str(layer.name)
		if not existing.has(layer_name):
			tile_set.add_custom_data_layer()
			existing[layer_name] = tile_set.get_custom_data_layers_count() - 1
		var layer_index := int(existing[layer_name])
		tile_set.set_custom_data_layer_name(layer_index, layer_name)
		tile_set.set_custom_data_layer_type(layer_index, int(layer.type))

func _apply_ground_metadata(tile_set: TileSet) -> void:
	_set_tile(tile_set, SOURCE_GROUND, Vector2i(0, 0), _meta("corrupted_grass", "field", 1, true, false, 0.0, false, "", "grass", 1.0))
	_set_tile(tile_set, SOURCE_GROUND, Vector2i(1, 0), _meta("heavy_corrupted_grass", "field", 1, true, false, 0.4, false, "", "grass", 0.95))
	_set_tile(tile_set, SOURCE_GROUND, Vector2i(2, 0), _meta("ash_path", "field", 1, true, false, 0.0, false, "", "dirt", 1.0))
	_set_tile(tile_set, SOURCE_GROUND, Vector2i(3, 0), _meta("packed_dirt", "field", 1, true, false, 0.0, false, "", "dirt", 1.0))
	_set_tile(tile_set, SOURCE_GROUND, Vector2i(4, 0), _meta("hub_plaza_stone", "town", 0, true, false, 0.0, false, "", "stone", 1.0))
	_set_tile(tile_set, SOURCE_GROUND, Vector2i(5, 0), _meta("bone_stone_trim", "town", 0, true, false, 0.0, false, "", "stone", 1.0))
	_set_tile(tile_set, SOURCE_GROUND, Vector2i(6, 0), _meta("dungeon_flagstone", "dungeon", 4, true, false, 0.0, false, "", "stone", 1.0))
	_set_tile(tile_set, SOURCE_GROUND, Vector2i(7, 0), _meta("marsh_mud", "marsh", 3, true, false, 0.0, false, "", "mud", 0.9))

func _apply_environment_metadata(tile_set: TileSet) -> void:
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(0, 0), _meta("void_water", "river", 2, false, true, 0.0, false, "", "water", 0.0), true)
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(1, 0), _meta("wet_shore_edge", "river", 2, true, false, 0.0, false, "", "mud", 1.0))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(2, 0), _meta("cliff_wall", "dungeon", 4, false, false, 0.0, false, "", "stone", 0.0), true)
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(3, 0), _meta("marsh_water", "marsh", 3, false, true, 0.0, false, "", "water", 0.0), true)
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(4, 0), _meta("bridge_plank", "river", 2, true, false, 0.0, false, "", "wood", 1.0))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(5, 0), _meta("bone_fence", "field", 2, false, false, 0.0, false, "", "wood", 0.0), true)
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(6, 0), _meta("thick_brush_blocker", "field", 2, false, false, 0.0, false, "", "grass", 0.0), true)
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(7, 0), _meta("cracked_stone_decal", "ruins", 2, true, false, 0.0, false, "", "stone", 1.0))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(0, 1), _meta("river_bank_west", "river", 2, true, false, 0.0, false, "", "grass", 1.0))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(1, 1), _meta("river_bank_east", "river", 2, true, false, 0.0, false, "", "grass", 1.0))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(2, 1), _meta("river_bank_north", "river", 2, true, false, 0.0, false, "", "grass", 1.0))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(3, 1), _meta("river_bank_south", "river", 2, true, false, 0.0, false, "", "grass", 1.0))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(4, 1), _meta("marsh_bank_west", "marsh", 3, true, false, 0.0, false, "", "mud", 0.9))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(5, 1), _meta("marsh_bank_east", "marsh", 3, true, false, 0.0, false, "", "mud", 0.9))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(6, 1), _meta("bridge_approach_west", "river", 2, true, false, 0.0, false, "", "wood", 1.0))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(7, 1), _meta("bridge_approach_east", "river", 2, true, false, 0.0, false, "", "wood", 1.0))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(0, 2), _meta("void_bank_west", "marsh", 3, true, false, 0.0, false, "", "mud", 0.9))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(1, 2), _meta("void_bank_east", "marsh", 3, true, false, 0.0, false, "", "mud", 0.9))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(2, 2), _meta("void_bank_north", "marsh", 3, true, false, 0.0, false, "", "mud", 0.9))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(3, 2), _meta("void_bank_south", "marsh", 3, true, false, 0.0, false, "", "mud", 0.9))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(4, 2), _meta("void_corner_north_west", "marsh", 3, true, false, 0.0, false, "", "mud", 0.9))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(5, 2), _meta("void_corner_north_east", "marsh", 3, true, false, 0.0, false, "", "mud", 0.9))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(6, 2), _meta("void_corner_south_west", "marsh", 3, true, false, 0.0, false, "", "mud", 0.9))
	_set_tile(tile_set, SOURCE_ENVIRONMENT, Vector2i(7, 2), _meta("void_corner_south_east", "marsh", 3, true, false, 0.0, false, "", "mud", 0.9))

func _apply_building_metadata(tile_set: TileSet) -> void:
	var legacy_tiles: Array[Dictionary] = [
			{"terrain": "red_shingle_roof", "material": "wood"},
			{"terrain": "slate_roof", "material": "stone"},
			{"terrain": "timber_plaster_wall", "material": "wood"},
			{"terrain": "stone_wall", "material": "stone"},
			{"terrain": "lit_window_wall", "material": "wood"},
			{"terrain": "closed_wooden_door", "material": "wood", "interaction": "building_door"},
			{"terrain": "chimney_roof", "material": "stone"},
			{"terrain": "market_awning", "material": "cloth"},
	]
	for column in range(legacy_tiles.size()):
		_apply_building_tile(tile_set, Vector2i(column, 0), legacy_tiles[column])

	var roof_tiles: Array[Dictionary] = [
		{"terrain": "red_roof_left", "material": "wood"},
		{"terrain": "red_roof_center", "material": "wood"},
		{"terrain": "red_roof_right", "material": "wood"},
		{"terrain": "slate_roof_left", "material": "stone"},
		{"terrain": "slate_roof_center", "material": "stone"},
		{"terrain": "slate_roof_right", "material": "stone"},
		{"terrain": "slate_roof_chimney", "material": "stone"},
		{"terrain": "guild_roof_dormer", "material": "stone"},
	]
	for column in range(roof_tiles.size()):
		_apply_building_tile(tile_set, Vector2i(column, 1), roof_tiles[column])

	var facade_tiles: Array[Dictionary] = [
		{"terrain": "plaster_corner_left", "material": "wood"},
		{"terrain": "plaster_wall", "material": "wood"},
		{"terrain": "plaster_window", "material": "wood"},
		{"terrain": "plaster_door", "material": "wood", "interaction": "building_door"},
		{"terrain": "plaster_corner_right", "material": "wood"},
		{"terrain": "stone_corner_left", "material": "stone"},
		{"terrain": "stone_wall_module", "material": "stone"},
		{"terrain": "stone_corner_right", "material": "stone"},
	]
	for column in range(facade_tiles.size()):
		_apply_building_tile(tile_set, Vector2i(column, 2), facade_tiles[column])

	var service_tiles: Array[Dictionary] = [
		{"terrain": "stone_window", "material": "stone"},
		{"terrain": "stone_door", "material": "stone", "interaction": "building_door"},
		{"terrain": "blacksmith_forge_front", "material": "stone"},
		{"terrain": "guild_banner_front", "material": "stone"},
		{"terrain": "barred_window", "material": "metal"},
		{"terrain": "ruined_facade", "material": "stone"},
		{"terrain": "stone_threshold", "material": "stone", "blocks": false},
		{"terrain": "tower_parapet", "material": "stone"},
	]
	for column in range(service_tiles.size()):
		_apply_building_tile(tile_set, Vector2i(column, 3), service_tiles[column])

func _apply_building_tile(tile_set: TileSet, coords: Vector2i, tile: Dictionary) -> void:
	var blocks := bool(tile.get("blocks", true))
	var interaction_id := str(tile.get("interaction", ""))
	_set_tile(
		tile_set,
		SOURCE_BUILDING,
		coords,
		_meta(
			str(tile.terrain),
			"town",
			0,
			not blocks,
			false,
			0.0,
			interaction_id != "",
			interaction_id,
			str(tile.material),
			0.0 if blocks else 1.0
		),
		blocks
	)

func _apply_object_metadata(tile_set: TileSet) -> void:
	var object_rows: Array[Array] = [
		[
			{"terrain": "barrel", "biome": "object", "material": "wood", "blocks": true},
			{"terrain": "barrel_variant", "biome": "object", "material": "wood", "blocks": true},
			{"terrain": "crate", "biome": "object", "material": "wood", "blocks": true},
			{"terrain": "well", "biome": "town", "material": "stone", "blocks": true},
			{"terrain": "shattered_pillar", "biome": "ruins", "material": "stone", "blocks": true},
			{"terrain": "ritual_circle", "biome": "ruins", "material": "stone", "blocks": false},
			{"terrain": "ruined_wall", "biome": "ruins", "material": "stone", "blocks": true},
			{"terrain": "chest_marker", "biome": "object", "material": "wood", "blocks": false, "interaction": "chest"},
		],
		[
			{"terrain": "withered_grass_tuft", "biome": "field", "material": "grass", "blocks": false},
			{"terrain": "bone_scatter", "biome": "ruins", "material": "bone", "blocks": false},
			{"terrain": "small_stones", "biome": "field", "material": "stone", "blocks": false},
			{"terrain": "broken_boards", "biome": "field", "material": "wood", "blocks": false},
			{"terrain": "rubble_pile", "biome": "ruins", "material": "stone", "blocks": false},
			{"terrain": "grim_signpost", "biome": "field", "material": "wood", "blocks": true},
			{"terrain": "ember_brazier", "biome": "dungeon", "material": "metal", "blocks": true},
			{"terrain": "marsh_reeds", "biome": "marsh", "material": "grass", "blocks": false},
		],
		[
			{"terrain": "grave_marker", "biome": "dungeon", "material": "stone", "blocks": true},
			{"terrain": "sarcophagus", "biome": "dungeon", "material": "stone", "blocks": true},
			{"terrain": "sacrificial_altar", "biome": "dungeon", "material": "stone", "blocks": true},
			{"terrain": "funerary_urn", "biome": "dungeon", "material": "stone", "blocks": true},
			{"terrain": "ruined_wall_left", "biome": "ruins", "material": "stone", "blocks": true},
			{"terrain": "ruined_wall_center", "biome": "ruins", "material": "stone", "blocks": true},
			{"terrain": "ruined_wall_right", "biome": "ruins", "material": "stone", "blocks": true},
			{"terrain": "spiked_barricade", "biome": "dungeon", "material": "wood", "blocks": true},
		],
	]
	for row in range(object_rows.size()):
		for column in range(object_rows[row].size()):
			var tile: Dictionary = object_rows[row][column]
			var blocks := bool(tile.blocks)
			var interaction_id := str(tile.get("interaction", ""))
			_set_tile(
				tile_set,
				SOURCE_OBJECT,
				Vector2i(column, row),
				_meta(
					str(tile.terrain),
					str(tile.biome),
					row + 1,
					not blocks,
					false,
					0.0,
					interaction_id != "",
					interaction_id,
					str(tile.material),
					0.0 if blocks else 1.0
				),
				blocks
			)
			if blocks:
				_apply_object_collision_footprint(tile_set, Vector2i(column, row))

func _apply_object_collision_footprint(tile_set: TileSet, coords: Vector2i) -> void:
	var points := PackedVector2Array()
	match coords:
		Vector2i(0, 0), Vector2i(1, 0):
			points = _rect_polygon(-11, -7, 11, 14)
		Vector2i(2, 0):
			points = _rect_polygon(-12, -8, 12, 14)
		Vector2i(3, 0):
			points = _rect_polygon(-13, -3, 13, 14)
		Vector2i(4, 0):
			points = _rect_polygon(-10, -8, 10, 15)
		Vector2i(6, 0):
			points = _rect_polygon(-16, 1, 16, 16)
		Vector2i(5, 1):
			points = _rect_polygon(-5, -7, 5, 16)
		Vector2i(6, 1):
			points = _rect_polygon(-11, 2, 11, 15)
		Vector2i(0, 2):
			points = _rect_polygon(-10, -1, 10, 15)
		Vector2i(1, 2):
			points = _rect_polygon(-14, -8, 14, 15)
		Vector2i(2, 2):
			points = _rect_polygon(-14, 0, 14, 15)
		Vector2i(3, 2):
			points = _rect_polygon(-10, -5, 10, 15)
		Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2):
			points = _rect_polygon(-16, 1, 16, 16)
		Vector2i(7, 2):
			points = _rect_polygon(-16, -7, 16, 16)
		_:
			return

	var source := tile_set.get_source(SOURCE_OBJECT) as TileSetAtlasSource
	if source == null:
		return
	var tile_data := source.get_tile_data(coords, 0)
	if tile_data == null:
		return
	tile_data.set_collision_polygons_count(0, 1)
	tile_data.set_collision_polygon_points(0, 0, points)

func _rect_polygon(left: float, top: float, right: float, bottom: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(left, top),
		Vector2(right, top),
		Vector2(right, bottom),
		Vector2(left, bottom),
	])

func _apply_route_metadata(tile_set: TileSet) -> void:
	_set_tile(tile_set, SOURCE_ROUTE, Vector2i(0, 0), _meta("encounter_brush", "field", 2, true, false, 1.5, false, "", "grass", 1.0))
	_set_tile(tile_set, SOURCE_ROUTE, Vector2i(1, 0), _meta("route_dirt", "field", 1, true, false, 0.0, false, "", "dirt", 1.0))
	_set_tile(tile_set, SOURCE_ROUTE, Vector2i(2, 0), _meta("rune_stone_marker", "ruins", 2, true, false, 0.0, false, "", "stone", 1.0))
	_set_tile(tile_set, SOURCE_ROUTE, Vector2i(3, 0), _meta("bonfire_marker", "ruins", 2, true, false, 0.0, false, "", "stone", 1.0))
	_set_tile(tile_set, SOURCE_ROUTE, Vector2i(4, 0), _meta("skull_marker", "dungeon", 4, true, false, 0.0, false, "", "stone", 1.0))
	_set_tile(tile_set, SOURCE_ROUTE, Vector2i(5, 0), _meta("route_curb", "field", 1, true, false, 0.0, false, "", "dirt", 1.0))
	_set_tile(tile_set, SOURCE_ROUTE, Vector2i(6, 0), _meta("thorn_roots", "field", 2, true, false, 0.3, false, "", "grass", 0.95))
	_set_tile(tile_set, SOURCE_ROUTE, Vector2i(7, 0), _meta("dark_seal", "dungeon", 5, true, false, 0.0, false, "", "stone", 1.0))
	_apply_transition_family_metadata(tile_set, 1, "ash_grass", "field", 1, "dirt")
	_apply_transition_family_metadata(tile_set, 2, "ash_mud", "marsh", 3, "dirt")
	_apply_transition_family_metadata(tile_set, 3, "cobble_grass", "town", 0, "stone")

func _apply_transition_family_metadata(tile_set: TileSet, row: int, prefix: String, biome: String, zone_tier: int, sound: String) -> void:
	var directions := [
		"north",
		"south",
		"west",
		"east",
		"north_west",
		"north_east",
		"south_west",
		"south_east",
	]
	for column in range(directions.size()):
		_set_tile(
			tile_set,
			SOURCE_ROUTE,
			Vector2i(column, row),
			_meta("%s_%s" % [prefix, directions[column]], biome, zone_tier, true, false, 0.0, false, "", sound, 1.0)
		)

func _set_tile(tile_set: TileSet, source_id: int, coords: Vector2i, metadata: Dictionary, blocks: bool = false) -> void:
	var source := tile_set.get_source(source_id) as TileSetAtlasSource
	if source == null:
		push_error("Custom tileset missing source id: %d" % source_id)
		return
	if not source.has_tile(coords):
		source.create_tile(coords)
	var tile_data := source.get_tile_data(coords, 0)
	if tile_data == null:
		push_error("Custom tileset source %d missing atlas tile: %s" % [source_id, coords])
		return
	for key in metadata.keys():
		tile_data.set_custom_data(str(key), metadata[key])
	if blocks:
		tile_data.set_collision_polygons_count(0, 1)
		tile_data.set_collision_polygon_points(0, 0, PackedVector2Array(FULL_TILE_POLYGON))
	else:
		tile_data.set_collision_polygons_count(0, 0)

func _meta(
	terrain_type: String,
	biome: String,
	zone_tier: int,
	is_walkable: bool,
	is_water: bool,
	encounter_weight: float,
	is_interactable: bool,
	interaction_id: String,
	footstep_sound: String,
	movement_modifier: float,
	damage_tile: bool = false
) -> Dictionary:
	return {
		"terrain_type": terrain_type,
		"biome": biome,
		"zone_tier": zone_tier,
		"is_walkable": is_walkable,
		"is_water": is_water,
		"is_damage_tile": damage_tile,
		"encounter_weight": encounter_weight,
		"is_interactable": is_interactable,
		"interaction_id": interaction_id,
		"footstep_sound": footstep_sound,
		"movement_modifier": movement_modifier,
	}
