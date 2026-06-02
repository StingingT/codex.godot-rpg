extends Node
class_name SpawnManager

@export var map_id: String = ""
@export var encounter_table_id: String = ""
@export var respawn_seconds: float = 12.0

var alive_by_monster: Dictionary = {}
var respawn_timer := 0.0
var monster_scene_cache: Dictionary = {}

func _ready() -> void:
	if map_id == "":
		map_id = str(get_tree().current_scene.name).to_snake_case().trim_prefix("map_")
	if encounter_table_id == "":
		var map_data := DataRegistry.get_map(map_id)
		encounter_table_id = str(map_data.get("encounter_table", ""))
	respawn_timer = respawn_seconds
	call_deferred("spawn_initial")

func _process(delta: float) -> void:
	respawn_timer -= delta
	if respawn_timer <= 0.0:
		spawn_missing()
		respawn_timer = respawn_seconds

func spawn_initial() -> void:
	spawn_missing()
	spawn_boss_if_configured()

func spawn_missing() -> void:
	var table := DataRegistry.get_encounter_table(encounter_table_id)
	if table.is_empty():
		return
	var spawn_points := _get_spawn_points()
	if spawn_points.is_empty():
		return
	for entry in table.get("ambient_spawns", []):
		var monster_id := str(entry.get("monster_id", ""))
		var max_alive := int(entry.get("max_alive", 1))
		if monster_id == "" or max_alive <= 0:
			continue
		var missing_count: int = max_alive - _count_alive(monster_id)
		for _i in range(max(missing_count, 0)):
			var spawned := _spawn_monster(monster_id, spawn_points.pick_random().global_position)
			if not spawned:
				push_warning("Could not spawn monster '%s' for encounter table '%s'." % [monster_id, encounter_table_id])
				break

func spawn_boss_if_configured() -> void:
	var table := DataRegistry.get_encounter_table(encounter_table_id)
	var boss: Dictionary = table.get("boss", {})
	if boss.is_empty():
		return
	var marker_name := str(boss.get("spawn_point", "BossSpawnPoint"))
	var map_root := _get_map_root()
	if map_root == null:
		return
	var marker := map_root.get_node_or_null(marker_name) as Marker2D
	if marker:
		_spawn_monster(str(boss.get("monster_id", "")), marker.global_position)

func _spawn_monster(monster_id: String, spawn_position: Vector2) -> bool:
	var monster_data := DataRegistry.get_monster(monster_id)
	if monster_data.is_empty():
		return false
	var scene_path := str(monster_data.get("scene", "res://scenes/monsters/monster_base.tscn"))
	var scene := _get_monster_scene(scene_path)
	if scene == null:
		return false
	var monster := scene.instantiate()
	if monster == null:
		return false
	monster.global_position = spawn_position
	if "monster_type" in monster:
		monster.set("monster_type", monster_id)
	if monster.has_node("StatsComponent"):
		var stats := monster.get_node("StatsComponent") as StatsComponent
		stats.max_hp = int(monster_data.get("max_hp", monster_data.get("hp", stats.max_hp)))
		stats.current_hp = stats.max_hp
		stats.attack = int(monster_data.get("attack", stats.attack))
		stats.defense = int(monster_data.get("defense", stats.defense))
	if "xp_reward" in monster:
		monster.set("xp_reward", int(monster_data.get("xp_reward", monster.get("xp_reward"))))
	if "gold_reward" in monster:
		var gold_min := int(monster_data.get("gold_min", monster.get("gold_reward")))
		var gold_max := int(monster_data.get("gold_max", gold_min))
		monster.set("gold_reward", randi_range(gold_min, gold_max))
	var map_root := _get_map_root()
	if map_root == null:
		monster.queue_free()
		return false
	map_root.add_child(monster)
	return true

func _get_spawn_points() -> Array[Marker2D]:
	var result: Array[Marker2D] = []
	var map_root := _get_map_root()
	if map_root == null:
		return result
	var parent := map_root.get_node_or_null("SpawnPoints")
	if parent:
		for child in parent.get_children():
			if child is Marker2D:
				result.append(child)
	return result

func _count_alive(monster_id: String) -> int:
	var count := 0
	var map_root := _get_map_root()
	if map_root == null:
		return count
	for monster in get_tree().get_nodes_in_group("monsters"):
		if monster != map_root and not map_root.is_ancestor_of(monster):
			continue
		if "monster_type" in monster and monster.get("monster_type") == monster_id:
			count += 1
	return count

func _get_map_root() -> Node:
	if get_tree().current_scene != null:
		return get_tree().current_scene
	return get_parent()

func _get_monster_scene(scene_path: String) -> PackedScene:
	if not monster_scene_cache.has(scene_path):
		monster_scene_cache[scene_path] = load(scene_path) as PackedScene
	return monster_scene_cache[scene_path]
