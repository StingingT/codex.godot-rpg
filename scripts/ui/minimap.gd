extends Control
class_name Minimap

@export var map_size_px: Vector2 = Vector2(160, 160)
@export var pixels_per_world_unit: float = 0.25
@export var max_world_radius: float = 900.0

# Colors for different entity types
var COLOR_PLAYER = Color(1, 1, 1)      # White
var COLOR_NPC = Color(0.3, 0.9, 0.3)   # Green
var COLOR_MONSTER = Color(0.9, 0.3, 0.3) # Red
var COLOR_PORTAL = Color(0.7, 0.3, 0.9)  # Purple

@onready var background: Panel = $Background

var _player: Node2D
var _player_dot: ColorRect
var _entity_dots: Dictionary = {}  # Node -> ColorRect
var _refresh_timer: float = 0.0
const REFRESH_INTERVAL: float = 1.0  # Refresh entity list every second

func _ready() -> void:
	custom_minimum_size = map_size_px
	size = map_size_px
	
	# Create player dot (centered)
	_player_dot = _create_dot(COLOR_PLAYER, 6)
	add_child(_player_dot)
	
	# Find player
	call_deferred("_find_player")
	call_deferred("refresh_targets")

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as Node2D

func _process(delta: float) -> void:
	# Try to find player if not found yet
	if _player == null:
		_find_player()
		return
	
	# Periodic refresh of entity list
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_INTERVAL:
		_refresh_timer = 0.0
		refresh_targets()
	
	_update_player_position()
	_update_entities()

func refresh_targets() -> void:
	if _player == null:
		return
	
	# Remove invalid entities
	for node in _entity_dots.keys():
		if not is_instance_valid(node) or not node.is_inside_tree():
			if is_instance_valid(_entity_dots[node]):
				_entity_dots[node].queue_free()
			_entity_dots.erase(node)
	
	# Find all trackable entities
	var npcs = get_tree().get_nodes_in_group("npcs")
	var monsters = get_tree().get_nodes_in_group("monsters")
	var portals = get_tree().get_nodes_in_group("portal")
	
	# Add new NPCs
	for n in npcs:
		if n is Node2D and n != _player and not _entity_dots.has(n):
			var dot = _create_dot(COLOR_NPC, 5)
			add_child(dot)
			_entity_dots[n] = dot
	
	# Add new monsters
	for m in monsters:
		if m is Node2D and m != _player and not _entity_dots.has(m):
			var dot = _create_dot(COLOR_MONSTER, 5)
			add_child(dot)
			_entity_dots[m] = dot
	
	# Add new portals
	for p in portals:
		if p is Node2D and not _entity_dots.has(p):
			var dot = _create_dot(COLOR_PORTAL, 5)
			add_child(dot)
			_entity_dots[p] = dot

func _create_dot(color: Color, size: int) -> ColorRect:
	var dot = ColorRect.new()
	dot.color = color
	dot.custom_minimum_size = Vector2(size, size)
	dot.size = Vector2(size, size)
	return dot

func _update_player_position() -> void:
	# Player is always at center of minimap
	var center = map_size_px * 0.5
	_player_dot.position = center - (_player_dot.size * 0.5)

func _update_entities() -> void:
	var center = map_size_px * 0.5
	var player_pos = _player.global_position
	
	for entity in _entity_dots.keys():
		if not is_instance_valid(entity) or not entity.is_inside_tree():
			continue
		
		var dot = _entity_dots[entity]
		
		# Calculate relative position from player
		var rel = entity.global_position - player_pos
		var rel_len = rel.length()
		
		# Clamp far entities to edge
		if rel_len > max_world_radius and rel_len > 0.001:
			rel = rel.normalized() * max_world_radius
		
		# Convert to minimap position
		var mini_pos = center + (rel * pixels_per_world_unit)
		
		# Keep inside minimap with padding
		var pad = 4.0
		mini_pos.x = clamp(mini_pos.x, pad, map_size_px.x - pad - dot.size.x)
		mini_pos.y = clamp(mini_pos.y, pad, map_size_px.y - pad - dot.size.y)
		
		# Position dot
		dot.position = mini_pos
		dot.visible = true

func toggle():
	visible = not visible
	if visible:
		refresh_targets()
