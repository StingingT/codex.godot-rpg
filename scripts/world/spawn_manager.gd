extends Node
class_name SpawnManager

@export var map_id: String = ""
@export var encounter_table_id: String = ""
@export var respawn_seconds: float = 12.0

var alive_by_monster: Dictionary = {}
var respawn_timer := 0.0

func _ready() -> void:
	if map_id == "":
		map_id = str(get_tree().current_scene.name).to_snake_case().trim_prefix("map_")
	if encounter_table_id == "":
		var map_data := DataRegistry.get_map(map_id)
		encounter_table_id = str(map_data.get("encounter_table", ""))
	spawn_initial()

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
		while _count_alive(monster_id) < max_alive:
			_spawn_monster(monster_id, spawn_points.pick_random().global_position)

func spawn_boss_if_configured() -> void:
	var table := DataRegistry.get_encounter_table(encounter_table_id)
	var boss: Dictionary = table.get("boss", {})
	if boss.is_empty():
		return
	var marker_name := str(boss.get("spawn_point", "BossSpawnPoint"))
	var marker := get_tree().current_scene.get_node_or_null(marker_name) as Marker2D
	if marker:
		_spawn_monster(str(boss.get("monster_id", "")), marker.global_position)

func _spawn_monster(monster_id: String, spawn_position: Vector2) -> void:
	var monster_data := DataRegistry.get_monster(monster_id)
	if monster_data.is_empty():
		return
	var scene_path := str(monster_data.get("scene", "res://scenes/monsters/monster_base.tscn"))
	var scene: PackedScene = load(scene_path)
	var monster := scene.instantiate()
	monster.global_position = spawn_position
	if monster.get("monster_type") != null:
		monster.set("monster_type", monster_id)
	if monster.has_node("StatsComponent"):
		var stats := monster.get_node("StatsComponent") as StatsComponent
		stats.max_hp = int(monster_data.get("max_hp", monster_data.get("hp", stats.max_hp)))
		stats.attack = int(monster_data.get("attack", stats.attack))
		stats.defense = int(monster_data.get("defense", stats.defense))
	get_tree().current_scene.add_child(monster)

func _get_spawn_points() -> Array[Marker2D]:
	var result: Array[Marker2D] = []
	var parent := get_tree().current_scene.get_node_or_null("SpawnPoints")
	if parent:
		for child in parent.get_children():
			if child is Marker2D:
				result.append(child)
	return result

func _count_alive(monster_id: String) -> int:
	var count := 0
	for monster in get_tree().get_nodes_in_group("monsters"):
		if monster.get("monster_type") != null and monster.get("monster_type") == monster_id:
			count += 1
	return count
