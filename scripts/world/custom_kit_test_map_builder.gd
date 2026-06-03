extends Node2D
class_name CustomKitTestMapBuilder

const SOURCE_GROUND := 0
const SOURCE_ENVIRONMENT := 1
const SOURCE_BUILDING := 2
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
const ENCOUNTER_BRUSH := Vector2i(0, 0)
const ROUTE_DIRT := Vector2i(1, 0)
const BONFIRE := Vector2i(3, 0)

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
	_fill(ground_layer, Rect2i(5, 3, 20, 9), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(0, 8, 30, 3), SOURCE_GROUND, ASH_PATH)
	_fill(ground_layer, Rect2i(13, 0, 4, 18), SOURCE_GROUND, ASH_PATH)
	_fill(ground_layer, Rect2i(11, 6, 8, 5), SOURCE_GROUND, COBBLE)
	_paint_border_brush(30, 18)
	_fill(decor_layer, Rect2i(6, 2, 5, 3), SOURCE_BUILDING, Vector2i(0, 0))
	_fill(decor_layer, Rect2i(19, 2, 5, 3), SOURCE_BUILDING, Vector2i(1, 0))
	_fill(decor_layer, Rect2i(6, 5, 5, 2), SOURCE_BUILDING, Vector2i(2, 0))
	_fill(decor_layer, Rect2i(19, 5, 5, 2), SOURCE_BUILDING, Vector2i(2, 0))
	_paint_cell(decor_layer, Vector2i(8, 6), SOURCE_BUILDING, Vector2i(5, 0))
	_paint_cell(decor_layer, Vector2i(21, 6), SOURCE_BUILDING, Vector2i(4, 0))
	_paint_cell(decor_layer, Vector2i(15, 7), SOURCE_ROUTE, BONFIRE)
	_line(decor_layer, Vector2i(4, 12), 8, SOURCE_ENVIRONMENT, FENCE)
	_line(decor_layer, Vector2i(18, 12), 8, SOURCE_ENVIRONMENT, FENCE)

func _paint_field() -> void:
	_clear_layers()
	_fill(ground_layer, Rect2i(0, 0, 30, 18), SOURCE_GROUND, GRASS)
	_fill(ground_layer, Rect2i(3, 5, 20, 3), SOURCE_GROUND, ASH_PATH)
	_fill(ground_layer, Rect2i(18, 0, 5, 18), SOURCE_ENVIRONMENT, VOID_WATER)
	_fill(ground_layer, Rect2i(17, 0, 1, 18), SOURCE_ENVIRONMENT, WATER_EDGE)
	_fill(ground_layer, Rect2i(23, 0, 1, 18), SOURCE_ENVIRONMENT, WATER_EDGE)
	_fill(ground_layer, Rect2i(10, 13, 12, 3), SOURCE_GROUND, ASH_PATH)
	_fill(ground_layer, Rect2i(18, 5, 5, 3), SOURCE_ENVIRONMENT, BRIDGE_PLANK)
	_paint_border_brush(30, 18)
	_fill(decor_layer, Rect2i(1, 1, 4, 3), SOURCE_ROUTE, ENCOUNTER_BRUSH)
	_fill(decor_layer, Rect2i(7, 11, 6, 4), SOURCE_ROUTE, ENCOUNTER_BRUSH)
	_fill(decor_layer, Rect2i(25, 2, 3, 12), SOURCE_ENVIRONMENT, THICK_BRUSH)
	_paint_cell(decor_layer, Vector2i(15, 14), SOURCE_ENVIRONMENT, CRACKED_STONE)
	_paint_cell(decor_layer, Vector2i(16, 14), SOURCE_ENVIRONMENT, CRACKED_STONE)
	_fill(collision_layer, Rect2i(18, 0, 5, 5), SOURCE_ENVIRONMENT, MARSH_WATER)
	_fill(collision_layer, Rect2i(18, 8, 5, 10), SOURCE_ENVIRONMENT, MARSH_WATER)

func _paint_ruins() -> void:
	_clear_layers()
	_fill(ground_layer, Rect2i(0, 0, 30, 18), SOURCE_GROUND, GRASS)
	_fill(ground_layer, Rect2i(2, 7, 26, 3), SOURCE_GROUND, ASH_PATH)
	_fill(ground_layer, Rect2i(12, 3, 8, 11), SOURCE_GROUND, DUNGEON_STONE)
	_fill(ground_layer, Rect2i(15, 1, 4, 16), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(19, 12, 7, 4), SOURCE_GROUND, COBBLE)
	_paint_border_brush(30, 18)
	_fill(decor_layer, Rect2i(4, 2, 5, 3), SOURCE_ROUTE, ENCOUNTER_BRUSH)
	_fill(decor_layer, Rect2i(22, 3, 4, 4), SOURCE_ROUTE, ENCOUNTER_BRUSH)
	_fill(decor_layer, Rect2i(4, 12, 4, 4), SOURCE_ENVIRONMENT, THICK_BRUSH)
	_line(decor_layer, Vector2i(11, 4), 5, SOURCE_ENVIRONMENT, CRACKED_STONE)
	_line(decor_layer, Vector2i(20, 11), 5, SOURCE_ENVIRONMENT, CRACKED_STONE)
	_paint_cell(decor_layer, Vector2i(22, 14), SOURCE_ROUTE, BONFIRE)

func _paint_marsh() -> void:
	_clear_layers()
	_fill(ground_layer, Rect2i(0, 0, 30, 18), SOURCE_GROUND, MUD)
	_fill(ground_layer, Rect2i(2, 4, 14, 3), SOURCE_GROUND, ASH_PATH)
	_fill(ground_layer, Rect2i(13, 4, 4, 10), SOURCE_GROUND, ASH_PATH)
	_fill(ground_layer, Rect2i(14, 11, 13, 3), SOURCE_GROUND, ASH_PATH)
	_fill(ground_layer, Rect2i(4, 11, 6, 4), SOURCE_GROUND, GRASS)
	_fill(ground_layer, Rect2i(17, 0, 5, 18), SOURCE_ENVIRONMENT, MARSH_WATER)
	_fill(ground_layer, Rect2i(17, 6, 5, 3), SOURCE_ENVIRONMENT, BRIDGE_PLANK)
	_fill(ground_layer, Rect2i(25, 2, 3, 8), SOURCE_ENVIRONMENT, VOID_WATER)
	_paint_border_brush(30, 18)
	_fill(decor_layer, Rect2i(1, 10, 3, 5), SOURCE_ROUTE, ENCOUNTER_BRUSH)
	_fill(decor_layer, Rect2i(23, 11, 4, 4), SOURCE_ROUTE, ENCOUNTER_BRUSH)
	_fill(decor_layer, Rect2i(10, 1, 4, 3), SOURCE_ENVIRONMENT, THICK_BRUSH)
	_paint_cell(decor_layer, Vector2i(24, 13), SOURCE_ROUTE, BONFIRE)
	_fill(collision_layer, Rect2i(17, 0, 5, 6), SOURCE_ENVIRONMENT, MARSH_WATER)
	_fill(collision_layer, Rect2i(17, 9, 5, 9), SOURCE_ENVIRONMENT, MARSH_WATER)
	_fill(collision_layer, Rect2i(25, 2, 3, 8), SOURCE_ENVIRONMENT, VOID_WATER)

func _paint_catacombs() -> void:
	_clear_layers()
	_fill(ground_layer, Rect2i(0, 0, 30, 18), SOURCE_GROUND, DUNGEON_STONE)
	_fill(ground_layer, Rect2i(2, 7, 26, 3), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(5, 3, 7, 5), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(16, 3, 8, 5), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(10, 11, 8, 5), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(22, 11, 5, 4), SOURCE_GROUND, COBBLE)
	_paint_stone_border(30, 18)
	_fill(decor_layer, Rect2i(3, 2, 2, 13), SOURCE_ENVIRONMENT, CLIFF)
	_fill(decor_layer, Rect2i(25, 2, 2, 13), SOURCE_ENVIRONMENT, CLIFF)
	_line(decor_layer, Vector2i(6, 5), 5, SOURCE_ENVIRONMENT, CRACKED_STONE)
	_line(decor_layer, Vector2i(17, 5), 6, SOURCE_ENVIRONMENT, CRACKED_STONE)
	_line(decor_layer, Vector2i(11, 13), 6, SOURCE_ENVIRONMENT, CRACKED_STONE)
	_paint_cell(decor_layer, Vector2i(23, 13), SOURCE_ROUTE, BONFIRE)
	_fill(collision_layer, Rect2i(3, 2, 2, 13), SOURCE_ENVIRONMENT, CLIFF)
	_fill(collision_layer, Rect2i(25, 2, 2, 13), SOURCE_ENVIRONMENT, CLIFF)

func _paint_dark_keep() -> void:
	_clear_layers()
	_fill(ground_layer, Rect2i(0, 0, 30, 18), SOURCE_GROUND, DUNGEON_STONE)
	_fill(ground_layer, Rect2i(2, 7, 11, 3), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(12, 4, 8, 9), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(19, 6, 9, 7), SOURCE_GROUND, COBBLE)
	_fill(ground_layer, Rect2i(20, 12, 7, 4), SOURCE_GROUND, COBBLE)
	_paint_stone_border(30, 18)
	_fill(decor_layer, Rect2i(1, 1, 6, 4), SOURCE_ENVIRONMENT, CLIFF)
	_fill(decor_layer, Rect2i(23, 1, 5, 4), SOURCE_ENVIRONMENT, CLIFF)
	_fill(decor_layer, Rect2i(2, 13, 5, 3), SOURCE_ENVIRONMENT, CLIFF)
	_line(decor_layer, Vector2i(12, 5), 8, SOURCE_ENVIRONMENT, CRACKED_STONE)
	_line(decor_layer, Vector2i(20, 9), 7, SOURCE_ENVIRONMENT, CRACKED_STONE)
	_paint_cell(decor_layer, Vector2i(23, 13), SOURCE_ROUTE, BONFIRE)
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

func _paint_cell(layer: TileMapLayer, coords: Vector2i, source_id: int, atlas_coords: Vector2i) -> void:
	if layer:
		layer.set_cell(coords, source_id, atlas_coords)
