extends Node

# Supabase configuration - replace with actual values from Supabase dashboard
const SUPABASE_URL = "https://your-project.supabase.co"
const SUPABASE_ANON_KEY = "your-anon-key"

# API endpoints
const AUTH_ENDPOINT = "/auth/v1"
const REST_ENDPOINT = "/rest/v1"

# Player session
var auth_token: String = ""
var player_id: String = ""
var is_authenticated: bool = false

# Signals
signal authenticated(player_id: String)
signal authentication_failed(error: String)  # Currently unused but reserved for future auth error handling
signal save_uploaded(slot: int)
signal save_downloaded(slot: int, save_data: Dictionary)
signal leaderboard_loaded(entries: Array)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

# Authentication
func sign_up_anonymous() -> void:
	# In production: POST to /auth/v1/signup with anonymous credentials
	# For now, simulate success
	_debug_log("[Supabase] Anonymous sign-up (placeholder)")
	player_id = "player_" + str(randi())
	auth_token = "dummy_token_" + str(randi())
	is_authenticated = true
	authenticated.emit(player_id)

func sign_in_email(email: String, _password: String) -> void:
	_debug_log("[Supabase] Email sign-in (placeholder)")
	# In production: POST to /auth/v1/token?grant_type=password
	player_id = "player_" + email.md5_text().substr(0, 8)
	auth_token = "dummy_token_" + str(randi())
	is_authenticated = true
	authenticated.emit(player_id)

func sign_out() -> void:
	auth_token = ""
	player_id = ""
	is_authenticated = false
	_debug_log("[Supabase] Signed out")

# Cloud Saves
func upload_save(slot: int, _save_data: Dictionary) -> void:
	if not is_authenticated:
		_debug_log("[Supabase] Not authenticated")
		return
	
	_debug_log("[Supabase] Uploading save to slot %d" % slot)
	# In production: POST to /rest/v1/cloud_saves
	# with headers: Authorization: Bearer {auth_token}
	
	# Simulate API call
	await get_tree().create_timer(0.5).timeout
	save_uploaded.emit(slot)
	_debug_log("[Supabase] Save uploaded successfully")

func download_save(slot: int) -> void:
	if not is_authenticated:
		_debug_log("[Supabase] Not authenticated")
		return
	
	_debug_log("[Supabase] Downloading save from slot %d" % slot)
	# In production: GET to /rest/v1/cloud_saves?slot=eq.{slot}
	
	# Simulate API call with placeholder data
	await get_tree().create_timer(0.5).timeout
	var placeholder_save = {
		"version": 1,
		"timestamp": Time.get_datetime_string_from_system(),
		"current_map": "town",
		"player": {
			"position": {"x": 320, "y": 180},
			"stats": {}
		}
	}
	save_downloaded.emit(slot, placeholder_save)
	_debug_log("[Supabase] Save downloaded successfully")

func list_cloud_saves() -> Array:
	if not is_authenticated:
		return []
	
	# In production: GET to /rest/v1/cloud_saves
	# Return list of save slots with timestamps
	return [
		{"slot": 1, "timestamp": "2024-01-15 10:30:00"},
		{"slot": 2, "timestamp": "2024-01-14 18:45:00"}
	]

# Leaderboard
func submit_score(level: int, play_time: int, monsters_killed: int, quests_completed: int) -> void:
	if not is_authenticated:
		return
	
	_debug_log("[Supabase] Submitting score to leaderboard")
	# In production: POST to /rest/v1/leaderboard
	
	var score_data = {
		"player_id": player_id,
		"player_name": "Player " + player_id.substr(-4),
		"level": level,
		"play_time_seconds": play_time,
		"monsters_killed": monsters_killed,
		"quests_completed": quests_completed
	}
	
	_debug_log("[Supabase] Score submitted: " + str(score_data))

func get_leaderboard(_limit: int = 50) -> void:
	_debug_log("[Supabase] Fetching leaderboard")
	# In production: GET to /rest/v1/leaderboard?order=level.desc&limit={limit}
	
	# Simulate API call
	await get_tree().create_timer(0.5).timeout
	
	var placeholder_entries = [
		{"rank": 1, "player_name": "Hero1", "level": 50, "monsters_killed": 999},
		{"rank": 2, "player_name": "Warrior", "level": 45, "monsters_killed": 850},
		{"rank": 3, "player_name": "Mage", "level": 42, "monsters_killed": 720},
		{"rank": 4, "player_name": "Ranger", "level": 38, "monsters_killed": 650},
		{"rank": 5, "player_name": "You", "level": 10, "monsters_killed": 25}
	]
	
	leaderboard_loaded.emit(placeholder_entries)

func _debug_log(message: String) -> void:
	if OS.is_debug_build():
		print(message)

# HTTP request helper
func _make_request(_method: String, _endpoint: String, _body: Dictionary = {}) -> Dictionary:
	# In production: Use HTTPRequest node to make actual API calls
	# This is a placeholder that returns empty success
	return {"success": true, "data": {}}
