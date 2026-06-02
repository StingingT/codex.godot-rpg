extends SceneTree

const SCENES: Array[String] = [
	"res://scenes/ui/title_screen.tscn",
	"res://scenes/player/player.tscn",
	"res://scenes/maps/town.tscn",
	"res://scenes/maps/royal_courtyard.tscn",
	"res://scenes/maps/mystic_forest.tscn",
	"res://scenes/maps/river_crossing.tscn",
	"res://scenes/maps/watchtower_ruins.tscn",
	"res://scenes/maps/sunken_marsh.tscn",
	"res://scenes/maps/fields.tscn",
	"res://scenes/maps/cave.tscn",
	"res://scenes/maps/dungeon.tscn",
	"res://scenes/maps/swamp.tscn",
	"res://scenes/monsters/monster_base.tscn",
	"res://scenes/ui/hud.tscn",
	"res://scenes/ui/shop_ui.tscn",
	"res://scenes/effects/fireball_projectile.tscn"
]

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var failed := false
	for scene_path in SCENES:
		var packed := load(scene_path) as PackedScene
		if packed == null:
			push_error("Could not load scene: %s" % scene_path)
			failed = true
			continue
		var instance := packed.instantiate()
		if instance == null:
			push_error("Could not instantiate scene: %s" % scene_path)
			failed = true
			continue
		_free_cameras(instance)
		instance.free()
		await process_frame
	quit(1 if failed else 0)

func _free_cameras(node: Node) -> void:
	for child in node.get_children():
		_free_cameras(child)
	if node is Camera2D:
		node.free()
