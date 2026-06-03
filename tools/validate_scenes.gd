extends SceneTree

const SCENES: Array[String] = [
	"res://scenes/effects/damage_number.tscn",
	"res://scenes/effects/fireball_projectile.tscn",
	"res://scenes/items/gold_pickup.tscn",
	"res://scenes/items/item_pickup.tscn",
	"res://scenes/items/xp_orb.tscn",
	"res://scenes/maps/royal_courtyard.tscn",
	"res://scenes/maps/mystic_forest.tscn",
	"res://scenes/maps/river_crossing.tscn",
	"res://scenes/maps/watchtower_ruins.tscn",
	"res://scenes/maps/sunken_marsh.tscn",
	"res://scenes/maps/custom_kit_town.tscn",
	"res://scenes/maps/custom_kit_field.tscn",
	"res://scenes/maps/custom_kit_ruins.tscn",
	"res://scenes/maps/custom_kit_marsh.tscn",
	"res://scenes/maps/custom_kit_catacombs.tscn",
	"res://scenes/maps/custom_kit_dark_keep.tscn",
	"res://scenes/maps/fields.tscn",
	"res://scenes/maps/cave.tscn",
	"res://scenes/maps/dungeon.tscn",
	"res://scenes/maps/swamp.tscn",
	"res://scenes/maps/test_map.tscn",
	"res://scenes/maps/town.tscn",
	"res://scenes/monsters/bat.tscn",
	"res://scenes/monsters/dark_knight.tscn",
	"res://scenes/monsters/monster_base.tscn",
	"res://scenes/monsters/skeleton.tscn",
	"res://scenes/monsters/swamp_monster.tscn",
	"res://scenes/npcs/npc_base.tscn",
	"res://scenes/npcs/portal_npc.tscn",
	"res://scenes/npcs/quest_npc.tscn",
	"res://scenes/npcs/shop_npc.tscn",
	"res://scenes/player/player.tscn",
	"res://scenes/ui/character_screen.tscn",
	"res://scenes/ui/death_screen.tscn",
	"res://scenes/ui/dialogue_box.tscn",
	"res://scenes/ui/hud.tscn",
	"res://scenes/ui/inventory_ui.tscn",
	"res://scenes/ui/leaderboard_ui.tscn",
	"res://scenes/ui/map_selector.tscn",
	"res://scenes/ui/minimap.tscn",
	"res://scenes/ui/portal.tscn",
	"res://scenes/ui/quest_book.tscn",
	"res://scenes/ui/shop_ui.tscn",
	"res://scenes/ui/skill_tree_ui.tscn",
	"res://scenes/ui/title_screen.tscn",
	"res://scenes/ui/touch_controls.tscn",
	"res://assets/objects/trees/corrupted_oak.tscn",
	"res://assets/objects/trees/dead_pine.tscn",
	"res://assets/objects/buildings/vendor_stall.tscn",
	"res://assets/objects/buildings/hub_house_small.tscn",
	"res://assets/objects/props/bone_bridge.tscn",
	"res://assets/objects/props/ruined_wall.tscn",
	"res://assets/objects/props/ritual_circle.tscn",
	"res://assets/objects/props/well.tscn",
	"res://assets/objects/props/barrel.tscn",
	"res://assets/objects/props/shattered_pillar.tscn",
	"res://assets/objects/interactables/chest_closed.tscn",
	"res://assets/objects/interactables/dungeon_door.tscn",
	"res://assets/objects/interactables/barrier_gate.tscn",
	"res://assets/objects/portals/back_portal.tscn",
	"res://assets/objects/portals/next_portal.tscn",
	"res://assets/objects/portals/town_portal.tscn"
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
