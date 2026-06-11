extends Node2D
class_name CustomKitTestMapBuilder

const SOURCE_GROUND := 0
const SOURCE_ENVIRONMENT := 1
const SOURCE_BUILDING := 2
const SOURCE_OBJECT := 3
const SOURCE_ROUTE := 4

const GRASS := Vector2i(0, 0)
const HEAVY_GRASS := Vector2i(1, 0)
const ASH_PATH := Vector2i(2, 0)
const COBBLE := Vector2i(4, 0)
const MUD := Vector2i(7, 0)
const DUNGEON_STONE := Vector2i(6, 0)
const VOID_WATER := Vector2i(0, 0)
const WATER_EDGE := Vector2i(1, 0)
const CLIFF := Vector2i(2, 0)
const MARSH_WATER := Vector2i(3, 0)
const BRIDGE_PLANK := Vector2i(4, 0)
const FENCE := Vector2i(5, 0)
const THICK_BRUSH := Vector2i(6, 0)
const CRACKED_STONE := Vector2i(7, 0)
const RIVER_BANK_WEST := Vector2i(0, 1)
const RIVER_BANK_EAST := Vector2i(1, 1)
const MARSH_BANK_WEST := Vector2i(4, 1)
const MARSH_BANK_EAST := Vector2i(5, 1)
const BRIDGE_APPROACH_WEST := Vector2i(6, 1)
const BRIDGE_APPROACH_EAST := Vector2i(7, 1)
const VOID_BANK_WEST := Vector2i(0, 2)
const VOID_BANK_EAST := Vector2i(1, 2)
const VOID_BANK_NORTH := Vector2i(2, 2)
const VOID_BANK_SOUTH := Vector2i(3, 2)
const VOID_CORNER_NORTH_WEST := Vector2i(4, 2)
const VOID_CORNER_NORTH_EAST := Vector2i(5, 2)
const VOID_CORNER_SOUTH_WEST := Vector2i(6, 2)
const VOID_CORNER_SOUTH_EAST := Vector2i(7, 2)
const BARREL := Vector2i(0, 0)
const BARREL_VARIANT := Vector2i(1, 0)
const CRATE := Vector2i(2, 0)
const SHATTERED_PILLAR := Vector2i(4, 0)
const RUINED_WALL := Vector2i(6, 0)
const WITHERED_TUFT := Vector2i(0, 1)
const BONE_SCATTER := Vector2i(1, 1)
const SMALL_STONES := Vector2i(2, 1)
const BROKEN_BOARDS := Vector2i(3, 1)
const RUBBLE_PILE := Vector2i(4, 1)
const SIGNPOST := Vector2i(5, 1)
const EMBER_BRAZIER := Vector2i(6, 1)
const MARSH_REEDS := Vector2i(7, 1)
const GRAVE_MARKER := Vector2i(0, 2)
const SARCOPHAGUS := Vector2i(1, 2)
const SACRIFICIAL_ALTAR := Vector2i(2, 2)
const FUNERARY_URN := Vector2i(3, 2)
const RUINED_WALL_LEFT := Vector2i(4, 2)
const RUINED_WALL_CENTER := Vector2i(5, 2)
const RUINED_WALL_RIGHT := Vector2i(6, 2)
const SPIKED_BARRICADE := Vector2i(7, 2)
const ENCOUNTER_BRUSH := Vector2i(0, 0)
const ROUTE_DIRT := Vector2i(1, 0)
const RUNE_STONE := Vector2i(2, 0)
const BONFIRE := Vector2i(3, 0)
const SKULL_MARKER := Vector2i(4, 0)
const DARK_SEAL := Vector2i(7, 0)
const ASH_GRASS_TRANSITION_ROW := 1
const ASH_MUD_TRANSITION_ROW := 2
const COBBLE_GRASS_TRANSITION_ROW := 3
const RED_ROOF_LEFT := Vector2i(0, 1)
const RED_ROOF_CENTER := Vector2i(1, 1)
const RED_ROOF_RIGHT := Vector2i(2, 1)
const SLATE_ROOF_LEFT := Vector2i(3, 1)
const SLATE_ROOF_CENTER := Vector2i(4, 1)
const SLATE_ROOF_RIGHT := Vector2i(5, 1)
const SLATE_ROOF_CHIMNEY := Vector2i(6, 1)
const PLASTER_CORNER_LEFT := Vector2i(0, 2)
const PLASTER_WINDOW := Vector2i(2, 2)
const PLASTER_DOOR := Vector2i(3, 2)
const PLASTER_CORNER_RIGHT := Vector2i(4, 2)
const STONE_CORNER_LEFT := Vector2i(5, 2)
const STONE_CORNER_RIGHT := Vector2i(7, 2)
const STONE_DOOR := Vector2i(1, 3)
const BLACKSMITH_FRONT := Vector2i(2, 3)

@export_enum("town", "field", "ruins", "marsh", "catacombs", "dark_keep") var map_type := "town"

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var decor_layer: TileMapLayer = $DecorLayer
@onready var collision_layer: TileMapLayer = $CollisionLayer
@onready var overlay_layer: TileMapLayer = $OverlayLayer

func _ready() -> void:
	match map_type:
		"field":
			_paint_field()
		"ruins":
			_paint_ruins()
		"marsh":
			_paint_marsh()
		"catacombs":
			_paint_catacombs()
		"dark_keep":
			_paint_dark_keep()
		_:
			_paint_town()

func _paint_town() -> void:
	_clear_layers()
	_fill(ground_layer, Rect2i(0, 0, 30, 18), SOURCE_GROUND, GRASS)
	_paint_transition_region(
		[Rect2i(0, 8, 30, 3), Rect2i(13, 0, 4, 18)],
		SOURCE_GROUND,
		ASH_PATH,
		ASH_GRASS_TRANSITION_ROW
	)
	_paint_transition_region(
		[
			Rect2i(8, 5, 14, 8),
			Rect2i(5, 5, 6, 5),
			Rect2i(19, 5, 6, 5),
			Rect2i(12, 3, 7, 4),
			Rect2i(10, 12, 10, 4),
			Rect2i(1, 4, 4, 3),
			Rect2i(25, 4, 4, 3),
		],
		SOURCE_GROUND,
		COBBLE,
		COBBLE_GRASS_TRANSITION_ROW
	)
	_paint_border_brush(30, 18)
	_paint_modular_building(Vector2i(1, 2), "red", "plaster")
	_paint_modular_building(Vector2i(25, 2), "slate", "blacksmith")
	_paint_cell(decor_layer, Vector2i(15, 9), SOURCE_ROUTE, BONFIRE)
	_line(decor_layer, Vector2i(3, 13), 8, SOURCE_ENVIRONMENT, FENCE)
	_line(decor_layer, Vector2i(19, 13), 8, SOURCE_ENVIRONMENT, FENCE)
	_line(decor_layer, Vector2i(9, 4), 4, SOURCE_ENVIRONMENT, FENCE)
	_line(decor_layer, Vector2i(18, 4), 4, SOURCE_ENVIRONMENT, FENCE)
	_paint_cell(decor_layer, Vector2i(5, 7), SOURCE_OBJECT, BARREL)
	_paint_cell(decor_layer, Vector2i(6, 7), SOURCE_OBJECT, CRATE)
	_paint_cell(decor_layer, Vector2i(6, 6), SOURCE_OBJECT, SIGNPOST)
	_paint_cell(decor_layer, Vector2i(24, 7), SOURCE_OBJECT, CRATE)
	_paint_cell(decor_layer, Vector2i(23, 7), SOURCE_OBJECT, BARREL)
	_paint_cell(decor_layer, Vector2i(24, 5), SOURCE_OBJECT, EMBER_BRAZIER)
	_paint_cell(decor_layer, Vector2i(11, 14), SOURCE_OBJECT, BARREL_VARIANT)
	_paint_cell(decor_layer, Vector2i(19, 14), SOURCE_OBJECT, CRATE)
	_paint_cell(decor_layer, Vector2i(12, 14), SOURCE_OBJECT, BROKEN_BOARDS)
	_paint_cell(decor_layer, Vector2i(17, 14), SOURCE_OBJECT, SMALL_STONES)

func _paint_field() -> void:
	_clear_layers()
	_fill(ground_layer, Rect2i(0, 0, 30, 18), SOURCE_GROUND, GRASS)
	_fill(ground_layer, Rect2i(6, 2, 7, 4), SOURCE_GROUND, HEAVY_GRASS)
	_fill(ground_layer, Rect2i(8, 11, 8, 5), SOURCE_GROUND, HEAVY_GRASS)
	_paint_transition_region(
		[Rect2i(1, 5, 17, 3), Rect2i(10, 13, 20, 3)],
		SOURCE_GROUND,
		ASH_PATH,
		ASH_GRASS_TRANSITION_ROW
	)
	_fill(ground_layer, Rect2i(18, 0, 5, 18), SOURCE_ENVIRONMENT, VOID_WATER)
	_fill(ground_layer, Rect2i(17, 0, 1, 18), SOURCE_ENVIRONMENT, RIVER_BANK_WEST)
	_fill(ground_layer, Rect2i(23, 0, 1, 18), SOURCE_ENVIRONMENT, RIVER_BANK_EAST)
	_fill(ground_layer, Rect2i(18, 5, 5, 3), SOURCE_ENVIRONMENT, BRIDGE_PLANK)
	_fill(ground_layer, Rect2i(18, 13, 5, 3), SOURCE_ENVIRONMENT, BRIDGE_PLANK)
	_fill(ground_layer, Rect2i(17, 5, 1, 3), SOURCE_ENVIRONMENT, BRIDGE_APPROACH_WEST)
	_fill(ground_layer, Rect2i(23, 5, 1, 3), SOURCE_ENVIRONMENT, BRIDGE_APPROACH_EAST)
	_fill(ground_layer, Rect2i(17, 13, 1, 3), SOURCE_ENVIRONMENT, BRIDGE_APPROACH_WEST)
	_fill(ground_layer, Rect2i(23, 13, 1, 3), SOURCE_ENVIRONMENT, BRIDGE_APPROACH_EAST)
	_paint_border_brush(30, 18)
	_fill(decor_layer, Rect2i(2, 2, 3, 3), SOURCE_ROUTE, ENCOUNTER_BRUSH)
	_fill(decor_layer, Rect2i(9, 11, 5, 3), SOURCE_ROUTE, ENCOUNTER_BRUSH)
	_fill(decor_layer, Rect2i(25, 2, 3, 9), SOURCE_ENVIRONMENT, THICK_BRUSH)
	_line(decor_layer, Vector2i(2, 9), 6, SOURCE_ENVIRONMENT, FENCE)
	_line(decor_layer, Vector2i(11, 9), 6, SOURCE_ENVIRONMENT, FENCE)
	_paint_cell(decor_layer, Vector2i(16, 14), SOURCE_ROUTE, BONFIRE)
	_paint_cell(decor_layer, Vector2i(15, 12), SOURCE_OBJECT, CRATE)
	_paint_cell(decor_layer, Vector2i(16, 12), SOURCE_OBJECT, BARREL)
	_paint_cell(decor_layer, Vector2i(14, 12), SOURCE_OBJECT, BROKEN_BOARDS)
	_paint_cell(decor_layer, Vector2i(17, 12), SOURCE_OBJECT, SMALL_STONES)
	_paint_cell(decor_layer, Vector2i(8, 8), SOURCE_OBJECT, SIGNPOST)
	_paint_cell(decor_layer, Vector2i(5, 4), SOURCE_OBJECT, WITHERED_TUFT)
	_paint_cell(decor_layer, Vector2i(9, 4), SOURCE_OBJECT, BONE_SCATTER)
	_paint_cell(decor_layer, Vector2i(26, 12), SOURCE_OBJECT, WITHERED_TUFT)
	_fill(collision_layer, Rect2i(18, 0, 5, 5), SOURCE_ENVIRONMENT, MARSH_WATER)
	_fill(collision_layer, Rect2i(18, 8, 5, 5), SOURCE_ENVIRONMENT, MARSH_WATER)
	_fill(collision_layer, Rect2i(18, 16, 5, 2), SOURCE_ENVIRONMENT, MARSH_WATER)

func _paint_ruins() -> void:
	_clear_layers()
	_fill(ground_layer, Rect2i(0, 0, 30, 18), SOURCE_GROUND, GRASS)
	_paint_transition_region(
		[Rect2i(1, 7, 27, 3)],
		SOURCE_GROUND,
		ASH_PATH,
		ASH_GRASS_TRANSITION_ROW
	)
	_fill(ground_layer, Rect2i(11, 3, 10, 11), SOURCE_GROUND, DUNGEON_STONE)
	_fill(ground_layer, Rect2i(14, 1, 5, 16), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(19, 12, 8, 4), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(5, 3, 5, 4), SOURCE_GROUND, HEAVY_GRASS)
	_paint_border_brush(30, 18)
	_fill(decor_layer, Rect2i(4, 2, 4, 4), SOURCE_ROUTE, ENCOUNTER_BRUSH)
	_fill(decor_layer, Rect2i(22, 3, 4, 4), SOURCE_ROUTE, ENCOUNTER_BRUSH)
	_fill(decor_layer, Rect2i(4, 12, 4, 4), SOURCE_ENVIRONMENT, THICK_BRUSH)
	_paint_ruined_wall(Vector2i(11, 4), 3)
	_paint_ruined_wall(Vector2i(18, 4), 3)
	_paint_ruined_wall(Vector2i(11, 12), 3)
	_paint_ruined_wall(Vector2i(19, 12), 3)
	_paint_cell(decor_layer, Vector2i(13, 5), SOURCE_OBJECT, SHATTERED_PILLAR)
	_paint_cell(decor_layer, Vector2i(19, 11), SOURCE_OBJECT, BARREL)
	_paint_cell(decor_layer, Vector2i(15, 8), SOURCE_ROUTE, BONFIRE)
	_paint_cell(decor_layer, Vector2i(23, 14), SOURCE_OBJECT, CRATE)
	_paint_cell(decor_layer, Vector2i(12, 5), SOURCE_OBJECT, RUBBLE_PILE)
	_paint_cell(decor_layer, Vector2i(20, 11), SOURCE_OBJECT, BROKEN_BOARDS)
	_paint_cell(decor_layer, Vector2i(22, 14), SOURCE_OBJECT, BONE_SCATTER)
	_paint_cell(decor_layer, Vector2i(8, 13), SOURCE_OBJECT, GRAVE_MARKER)

func _paint_marsh() -> void:
	_clear_layers()
	_fill(ground_layer, Rect2i(0, 0, 30, 18), SOURCE_GROUND, MUD)
	_fill(ground_layer, Rect2i(4, 11, 6, 4), SOURCE_GROUND, GRASS)
	_paint_transition_region(
		[Rect2i(1, 4, 15, 3), Rect2i(13, 4, 4, 10), Rect2i(14, 11, 16, 3)],
		SOURCE_GROUND,
		ASH_PATH,
		ASH_MUD_TRANSITION_ROW
	)
	_fill(ground_layer, Rect2i(17, 0, 5, 18), SOURCE_ENVIRONMENT, MARSH_WATER)
	_fill(ground_layer, Rect2i(16, 0, 1, 18), SOURCE_ENVIRONMENT, MARSH_BANK_WEST)
	_fill(ground_layer, Rect2i(22, 0, 1, 18), SOURCE_ENVIRONMENT, MARSH_BANK_EAST)
	_fill(ground_layer, Rect2i(17, 6, 5, 3), SOURCE_ENVIRONMENT, BRIDGE_PLANK)
	_fill(ground_layer, Rect2i(17, 11, 5, 3), SOURCE_ENVIRONMENT, BRIDGE_PLANK)
	_fill(ground_layer, Rect2i(16, 6, 1, 3), SOURCE_ENVIRONMENT, BRIDGE_APPROACH_WEST)
	_fill(ground_layer, Rect2i(22, 6, 1, 3), SOURCE_ENVIRONMENT, BRIDGE_APPROACH_EAST)
	_fill(ground_layer, Rect2i(16, 11, 1, 3), SOURCE_ENVIRONMENT, BRIDGE_APPROACH_WEST)
	_fill(ground_layer, Rect2i(22, 11, 1, 3), SOURCE_ENVIRONMENT, BRIDGE_APPROACH_EAST)
	_fill(ground_layer, Rect2i(25, 2, 3, 8), SOURCE_ENVIRONMENT, VOID_WATER)
	_fill(ground_layer, Rect2i(25, 1, 3, 1), SOURCE_ENVIRONMENT, VOID_BANK_NORTH)
	_fill(ground_layer, Rect2i(25, 10, 3, 1), SOURCE_ENVIRONMENT, VOID_BANK_SOUTH)
	_fill(ground_layer, Rect2i(24, 2, 1, 8), SOURCE_ENVIRONMENT, VOID_BANK_WEST)
	_fill(ground_layer, Rect2i(28, 2, 1, 8), SOURCE_ENVIRONMENT, VOID_BANK_EAST)
	_paint_cell(ground_layer, Vector2i(24, 1), SOURCE_ENVIRONMENT, VOID_CORNER_NORTH_WEST)
	_paint_cell(ground_layer, Vector2i(28, 1), SOURCE_ENVIRONMENT, VOID_CORNER_NORTH_EAST)
	_paint_cell(ground_layer, Vector2i(24, 10), SOURCE_ENVIRONMENT, VOID_CORNER_SOUTH_WEST)
	_paint_cell(ground_layer, Vector2i(28, 10), SOURCE_ENVIRONMENT, VOID_CORNER_SOUTH_EAST)
	_paint_border_brush(30, 18)
	_fill(decor_layer, Rect2i(1, 10, 3, 5), SOURCE_ROUTE, ENCOUNTER_BRUSH)
	_fill(decor_layer, Rect2i(23, 11, 4, 4), SOURCE_ROUTE, ENCOUNTER_BRUSH)
	_fill(decor_layer, Rect2i(10, 1, 4, 3), SOURCE_ENVIRONMENT, THICK_BRUSH)
	_fill(decor_layer, Rect2i(8, 2, 2, 2), SOURCE_ENVIRONMENT, THICK_BRUSH)
	_line(decor_layer, Vector2i(5, 15), 5, SOURCE_ENVIRONMENT, FENCE)
	_paint_cell(decor_layer, Vector2i(24, 13), SOURCE_ROUTE, BONFIRE)
	_paint_cell(decor_layer, Vector2i(9, 14), SOURCE_OBJECT, BARREL_VARIANT)
	_paint_cell(decor_layer, Vector2i(10, 14), SOURCE_OBJECT, CRATE)
	_paint_cell(decor_layer, Vector2i(7, 14), SOURCE_OBJECT, BROKEN_BOARDS)
	_paint_cell(decor_layer, Vector2i(6, 10), SOURCE_OBJECT, MARSH_REEDS)
	_paint_cell(decor_layer, Vector2i(11, 10), SOURCE_OBJECT, MARSH_REEDS)
	_paint_cell(decor_layer, Vector2i(23, 5), SOURCE_OBJECT, MARSH_REEDS)
	_paint_cell(decor_layer, Vector2i(28, 12), SOURCE_OBJECT, BONE_SCATTER)
	_fill(collision_layer, Rect2i(17, 0, 5, 6), SOURCE_ENVIRONMENT, MARSH_WATER)
	_fill(collision_layer, Rect2i(17, 9, 5, 2), SOURCE_ENVIRONMENT, MARSH_WATER)
	_fill(collision_layer, Rect2i(17, 14, 5, 4), SOURCE_ENVIRONMENT, MARSH_WATER)
	_fill(collision_layer, Rect2i(25, 2, 3, 8), SOURCE_ENVIRONMENT, VOID_WATER)

func _paint_catacombs() -> void:
	_clear_layers()
	_fill(ground_layer, Rect2i(0, 0, 30, 18), SOURCE_GROUND, DUNGEON_STONE)
	_fill(ground_layer, Rect2i(2, 7, 26, 3), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(5, 3, 7, 5), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(16, 3, 8, 5), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(10, 11, 8, 5), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(22, 11, 5, 4), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(13, 8, 4, 5), SOURCE_GROUND, COBBLE)
	_paint_stone_border(30, 18)
	_fill(decor_layer, Rect2i(3, 2, 2, 13), SOURCE_ENVIRONMENT, CLIFF)
	_fill(decor_layer, Rect2i(25, 2, 2, 13), SOURCE_ENVIRONMENT, CLIFF)
	_paint_ruined_wall(Vector2i(6, 5), 3)
	_paint_ruined_wall(Vector2i(20, 5), 3)
	_paint_ruined_wall(Vector2i(11, 13), 3)
	_paint_cell(decor_layer, Vector2i(18, 13), SOURCE_OBJECT, SHATTERED_PILLAR)
	_paint_cell(decor_layer, Vector2i(14, 9), SOURCE_ROUTE, RUNE_STONE)
	_paint_cell(decor_layer, Vector2i(15, 9), SOURCE_ROUTE, DARK_SEAL)
	_paint_cell(decor_layer, Vector2i(23, 13), SOURCE_ROUTE, BONFIRE)
	_paint_cell(decor_layer, Vector2i(7, 4), SOURCE_OBJECT, SARCOPHAGUS)
	_paint_cell(decor_layer, Vector2i(21, 4), SOURCE_OBJECT, SARCOPHAGUS)
	_paint_cell(decor_layer, Vector2i(12, 14), SOURCE_OBJECT, GRAVE_MARKER)
	_paint_cell(decor_layer, Vector2i(17, 12), SOURCE_OBJECT, FUNERARY_URN)
	_paint_cell(decor_layer, Vector2i(14, 8), SOURCE_OBJECT, SACRIFICIAL_ALTAR)
	_paint_cell(decor_layer, Vector2i(22, 12), SOURCE_OBJECT, RUBBLE_PILE)
	_fill(collision_layer, Rect2i(3, 2, 2, 13), SOURCE_ENVIRONMENT, CLIFF)
	_fill(collision_layer, Rect2i(25, 2, 2, 13), SOURCE_ENVIRONMENT, CLIFF)

func _paint_dark_keep() -> void:
	_clear_layers()
	_fill(ground_layer, Rect2i(0, 0, 30, 18), SOURCE_GROUND, DUNGEON_STONE)
	_fill(ground_layer, Rect2i(2, 7, 11, 3), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(12, 4, 8, 9), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(19, 6, 9, 7), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(20, 12, 7, 4), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(14, 1, 4, 5), SOURCE_GROUND, COBBLE)
	_paint_stone_border(30, 18)
	_fill(decor_layer, Rect2i(1, 1, 6, 4), SOURCE_ENVIRONMENT, CLIFF)
	_fill(decor_layer, Rect2i(23, 1, 5, 4), SOURCE_ENVIRONMENT, CLIFF)
	_fill(decor_layer, Rect2i(2, 13, 5, 3), SOURCE_ENVIRONMENT, CLIFF)
	_paint_ruined_wall(Vector2i(12, 5), 3)
	_paint_ruined_wall(Vector2i(17, 5), 3)
	_paint_ruined_wall(Vector2i(22, 9), 3)
	_paint_cell(decor_layer, Vector2i(20, 9), SOURCE_OBJECT, SHATTERED_PILLAR)
	_paint_cell(decor_layer, Vector2i(15, 3), SOURCE_ROUTE, DARK_SEAL)
	_paint_cell(decor_layer, Vector2i(16, 3), SOURCE_ROUTE, SKULL_MARKER)
	_paint_cell(decor_layer, Vector2i(23, 13), SOURCE_ROUTE, BONFIRE)
	_paint_cell(decor_layer, Vector2i(25, 14), SOURCE_ROUTE, BONFIRE)
	_paint_cell(decor_layer, Vector2i(13, 6), SOURCE_OBJECT, EMBER_BRAZIER)
	_paint_cell(decor_layer, Vector2i(18, 6), SOURCE_OBJECT, EMBER_BRAZIER)
	_paint_cell(decor_layer, Vector2i(15, 5), SOURCE_OBJECT, SPIKED_BARRICADE)
	_paint_cell(decor_layer, Vector2i(23, 11), SOURCE_OBJECT, SACRIFICIAL_ALTAR)
	_paint_cell(decor_layer, Vector2i(25, 11), SOURCE_OBJECT, FUNERARY_URN)
	_paint_cell(decor_layer, Vector2i(21, 8), SOURCE_OBJECT, RUBBLE_PILE)
	_fill(collision_layer, Rect2i(1, 1, 6, 4), SOURCE_ENVIRONMENT, CLIFF)
	_fill(collision_layer, Rect2i(23, 1, 5, 4), SOURCE_ENVIRONMENT, CLIFF)
	_fill(collision_layer, Rect2i(2, 13, 5, 3), SOURCE_ENVIRONMENT, CLIFF)

func _paint_border_brush(width := 26, height := 18) -> void:
	for x in range(width):
		_paint_cell(decor_layer, Vector2i(x, 0), SOURCE_ENVIRONMENT, THICK_BRUSH)
		_paint_cell(decor_layer, Vector2i(x, height - 1), SOURCE_ENVIRONMENT, THICK_BRUSH)
	for y in range(height):
		_paint_cell(decor_layer, Vector2i(0, y), SOURCE_ENVIRONMENT, THICK_BRUSH)
		_paint_cell(decor_layer, Vector2i(width - 1, y), SOURCE_ENVIRONMENT, THICK_BRUSH)

func _paint_stone_border(width: int, height: int) -> void:
	for x in range(width):
		_paint_cell(decor_layer, Vector2i(x, 0), SOURCE_ENVIRONMENT, CLIFF)
		_paint_cell(decor_layer, Vector2i(x, height - 1), SOURCE_ENVIRONMENT, CLIFF)
		_paint_cell(collision_layer, Vector2i(x, 0), SOURCE_ENVIRONMENT, CLIFF)
		_paint_cell(collision_layer, Vector2i(x, height - 1), SOURCE_ENVIRONMENT, CLIFF)
	for y in range(height):
		_paint_cell(decor_layer, Vector2i(0, y), SOURCE_ENVIRONMENT, CLIFF)
		_paint_cell(decor_layer, Vector2i(width - 1, y), SOURCE_ENVIRONMENT, CLIFF)
		_paint_cell(collision_layer, Vector2i(0, y), SOURCE_ENVIRONMENT, CLIFF)
		_paint_cell(collision_layer, Vector2i(width - 1, y), SOURCE_ENVIRONMENT, CLIFF)

func _clear_layers() -> void:
	for layer in [ground_layer, decor_layer, collision_layer, overlay_layer]:
		if layer:
			layer.clear()

func _fill(layer: TileMapLayer, area: Rect2i, source_id: int, atlas_coords: Vector2i) -> void:
	for y in range(area.position.y, area.position.y + area.size.y):
		for x in range(area.position.x, area.position.x + area.size.x):
			_paint_cell(layer, Vector2i(x, y), source_id, atlas_coords)

func _line(layer: TileMapLayer, start: Vector2i, length: int, source_id: int, atlas_coords: Vector2i) -> void:
	for x in range(start.x, start.x + length):
		_paint_cell(layer, Vector2i(x, start.y), source_id, atlas_coords)

func _paint_ruined_wall(start: Vector2i, length: int) -> void:
	if length <= 0:
		return
	if length == 1:
		_paint_cell(decor_layer, start, SOURCE_OBJECT, RUINED_WALL_CENTER)
		return
	_paint_cell(decor_layer, start, SOURCE_OBJECT, RUINED_WALL_LEFT)
	for offset in range(1, length - 1):
		_paint_cell(decor_layer, start + Vector2i(offset, 0), SOURCE_OBJECT, RUINED_WALL_CENTER)
	_paint_cell(decor_layer, start + Vector2i(length - 1, 0), SOURCE_OBJECT, RUINED_WALL_RIGHT)

func _paint_transition_region(rects: Array[Rect2i], center_source: int, center_coords: Vector2i, transition_row: int) -> void:
	var cells := {}
	for rect in rects:
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				cells[Vector2i(x, y)] = true

	for cell: Vector2i in cells:
		var missing_north := not cells.has(cell + Vector2i.UP)
		var missing_south := not cells.has(cell + Vector2i.DOWN)
		var missing_west := not cells.has(cell + Vector2i.LEFT)
		var missing_east := not cells.has(cell + Vector2i.RIGHT)
		var transition_column := -1
		if missing_north and missing_west:
			transition_column = 4
		elif missing_north and missing_east:
			transition_column = 5
		elif missing_south and missing_west:
			transition_column = 6
		elif missing_south and missing_east:
			transition_column = 7
		elif missing_north:
			transition_column = 0
		elif missing_south:
			transition_column = 1
		elif missing_west:
			transition_column = 2
		elif missing_east:
			transition_column = 3

		if transition_column >= 0:
			_paint_cell(ground_layer, cell, SOURCE_ROUTE, Vector2i(transition_column, transition_row))
		else:
			_paint_cell(ground_layer, cell, center_source, center_coords)

func _paint_modular_building(origin: Vector2i, roof_style: String, facade_style: String) -> void:
	var roof_tiles: Array[Vector2i]
	if roof_style == "slate":
		roof_tiles = [SLATE_ROOF_LEFT, SLATE_ROOF_CENTER, SLATE_ROOF_CHIMNEY, SLATE_ROOF_RIGHT]
	else:
		roof_tiles = [RED_ROOF_LEFT, RED_ROOF_CENTER, RED_ROOF_CENTER, RED_ROOF_RIGHT]

	var facade_tiles: Array[Vector2i]
	if facade_style == "blacksmith":
		facade_tiles = [STONE_CORNER_LEFT, BLACKSMITH_FRONT, STONE_DOOR, STONE_CORNER_RIGHT]
	else:
		facade_tiles = [PLASTER_CORNER_LEFT, PLASTER_WINDOW, PLASTER_DOOR, PLASTER_CORNER_RIGHT]

	for column in range(4):
		_paint_cell(decor_layer, origin + Vector2i(column, 0), SOURCE_BUILDING, roof_tiles[column])
		_paint_cell(decor_layer, origin + Vector2i(column, 1), SOURCE_BUILDING, facade_tiles[column])

func _paint_cell(layer: TileMapLayer, coords: Vector2i, source_id: int, atlas_coords: Vector2i) -> void:
	if layer:
		layer.set_cell(coords, source_id, atlas_coords)
