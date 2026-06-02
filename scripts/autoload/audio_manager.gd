extends Node

# Audio Manager - placeholder implementation
# In a full game, this would load and play actual audio files

# BGM tracks
var bgm_tracks = {
	"village": null,
	"field": null,
	"cave": null,
	"dungeon": null,
	"boss": null
}

# SFX
var sfx_sounds = {
	"sword_swing": null,
	"hit_impact": null,
	"monster_death": null,
	"item_pickup": null,
	"menu_select": null,
	"menu_back": null,
	"level_up": null,
	"quest_complete": null,
	"footstep_grass": null,
	"footstep_stone": null
}

# Volume settings
var bgm_volume: float = 0.8
var sfx_volume: float = 1.0
var ambient_volume: float = 0.6

# Current track
var current_bgm: String = ""
var current_ambient: String = ""

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect to game events
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)
	MapManager.map_changed.connect(_on_map_changed)
	GameManager.monster_killed.connect(_on_monster_killed)
	GameManager.item_picked_up.connect(_on_item_picked_up)

func play_bgm(track_name: String) -> void:
	if track_name == current_bgm:
		return
	
	current_bgm = track_name
	_debug_log("[Audio] Playing BGM: " + track_name)
	# In full implementation: crossfade to new track

func stop_bgm() -> void:
	current_bgm = ""
	_debug_log("[Audio] Stopping BGM")

func play_sfx(sfx_name: String) -> void:
	_debug_log("[Audio] Playing SFX: " + sfx_name)
	# In full implementation: play on available SFX channel

func play_sfx_at_position(sfx_name: String, position: Vector2) -> void:
	# For positional audio (3D sound)
	_debug_log("[Audio] Playing SFX at position: " + sfx_name + " at " + str(position))

func set_ambient(ambient_name: String) -> void:
	if ambient_name == current_ambient:
		return
	
	current_ambient = ambient_name
	_debug_log("[Audio] Setting ambient: " + ambient_name)

func stop_ambient() -> void:
	current_ambient = ""
	_debug_log("[Audio] Stopping ambient")

func set_bgm_volume(volume: float) -> void:
	bgm_volume = clamp(volume, 0.0, 1.0)
	_debug_log("[Audio] BGM volume set to: " + str(bgm_volume))

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	_debug_log("[Audio] SFX volume set to: " + str(sfx_volume))

func set_ambient_volume(volume: float) -> void:
	ambient_volume = clamp(volume, 0.0, 1.0)
	_debug_log("[Audio] Ambient volume set to: " + str(ambient_volume))

func _debug_log(message: String) -> void:
	if OS.is_debug_build():
		print(message)

# Event handlers
func _on_game_paused() -> void:
	# Optionally pause BGM or reduce volume
	pass

func _on_game_resumed() -> void:
	# Resume normal audio
	pass

func _on_map_changed(map_id: String, _map_name: String) -> void:
	# Change BGM based on map
	match map_id:
		"town":
			play_bgm("village")
			set_ambient("birds")
		"fields":
			play_bgm("field")
			set_ambient("wind")
		"swamp":
			play_bgm("field")
			set_ambient("wind")
		"cave":
			play_bgm("cave")
			set_ambient("drip")
		"dungeon":
			play_bgm("dungeon")
			set_ambient("drip")

func _on_monster_killed(_monster_type: String, position: Vector2) -> void:
	play_sfx_at_position("monster_death", position)

func _on_item_picked_up(_item_id: String, _quantity: int) -> void:
	play_sfx("item_pickup")

# Public methods for gameplay
func play_attack_sound(weapon_type: String = "sword") -> void:
	match weapon_type:
		"sword": play_sfx("sword_swing")
		"bow": play_sfx("bow_shoot")
		"staff": play_sfx("magic_cast")

func play_hit_sound() -> void:
	play_sfx("hit_impact")

func play_level_up() -> void:
	play_sfx("level_up")

func play_quest_complete() -> void:
	play_sfx("quest_complete")

func play_footstep(tile_type: String = "grass") -> void:
	match tile_type:
		"grass": play_sfx("footstep_grass")
		"stone": play_sfx("footstep_stone")
		"dirt": play_sfx("footstep_grass")  # Use grass as fallback
		_: play_sfx("footstep_grass")

func play_menu_select() -> void:
	play_sfx("menu_select")

func play_menu_back() -> void:
	play_sfx("menu_back")
