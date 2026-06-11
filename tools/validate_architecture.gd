extends SceneTree

const REQUIRED_DOCS: Array[String] = [
	"res://AGENTS.md",
	"res://Main_ChatGPT-Godot_RPG_Implementation_Plan.md",
	"res://custom_tileset_object_kit_instructions.md",
	"res://docs/agent_skills_required.md",
	"res://docs/custom_tileset_object_kit_instructions.md",
	"res://docs/monster_design_bible.md",
	"res://docs/external_sprite_agent_instructions.md",
	"res://docs/external_sprite_agent_skills.md",
	"res://docs/monster_spriteframes_setup.md",
	"res://docs/sprite_deliverables/manifest.json",
	"res://docs/RPG_Skill_Tree_Agent_Guide.md",
	"res://docs/Inventory_Equipment_Itemization_Loot_Agent_Instructions.md",
	"res://docs/Grimvale_Lore_World_Tone_Foundation.md",
	"res://docs/Menu_Game_Flow_Settings_Agent_Instructions.md",
	"res://docs/Combat_Ability_Logic_Feedback_Agent_Instructions.md",
	"res://docs/architect_review_checklist.md",
	"res://docs/agent_handoff_template.md",
	"res://docs/agent_integration_log.md",
	"res://docs/content_overlap_audit.md"
]

const REQUIRED_MASTER_PLAN_REFERENCES: Array[String] = [
	"docs/architect_review_checklist.md",
	"docs/agent_handoff_template.md",
	"docs/agent_integration_log.md",
	"docs/content_overlap_audit.md",
	"docs/Inventory_Equipment_Itemization_Loot_Agent_Instructions.md",
	"docs/Grimvale_Lore_World_Tone_Foundation.md",
	"docs/Menu_Game_Flow_Settings_Agent_Instructions.md",
	"docs/Combat_Ability_Logic_Feedback_Agent_Instructions.md"
]

const REQUIRED_MASTER_PLAN_RULES: Array[String] = [
	"Umbral Explorers: Relics of Grimvale",
	"heroic mystery first",
	"Ranger and Mage disabled with `Coming Later`",
	"user://saves/index.json",
	"user://saves/slot_1.json",
	"user://settings.json",
	"defense_softcap",
	"No screen shake or hit-stop in v1.",
	"one menu coordinator",
	"NPC quest interaction",
	"data/game_flow.json",
	"no gold, XP, or item penalty"
]

const REQUIRED_AUTOLOADS: Array[String] = [
	"GameManager",
	"MapManager",
	"DialogueManager",
	"QuestManager",
	"SaveManager",
	"AudioManager",
	"AbilityManager",
	"SupabaseClient",
	"IAPManager"
]

const REQUIRED_INPUT_ACTIONS: Array[String] = [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"interact",
	"attack",
	"ability_1",
	"ability_2",
	"ability_3",
	"ability_4",
	"open_inventory",
	"open_quest_log",
	"pause"
]

const EXPECTED_COLLISION_LAYERS := {
	"2d_physics/layer_1": "Player",
	"2d_physics/layer_2": "World",
	"2d_physics/layer_3": "Monsters",
	"2d_physics/layer_4": "NPCs",
	"2d_physics/layer_5": "Items",
	"2d_physics/layer_6": "Interaction",
	"2d_physics/layer_7": "Player Hitbox",
	"2d_physics/layer_8": "Monster Hitbox",
	"2d_physics/layer_9": "Hurtbox",
	"2d_physics/layer_10": "Projectiles"
}

const REQUIRED_JSON_FILES: Array[String] = [
	"res://data/maps/maps.json",
	"res://data/encounters/encounters.json",
	"res://data/monsters/monsters.json",
	"res://docs/sprite_deliverables/manifest.json"
]

const GDSCRIPT_PARSE_ROOTS: Array[String] = [
	"res://scripts",
	"res://scenes",
	"res://tools"
]

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var failed := false
	failed = _validate_required_docs() or failed
	failed = _validate_master_plan_review_references() or failed
	failed = _validate_master_plan_locked_rules() or failed
	failed = _validate_domain_spec_contracts() or failed
	failed = _validate_no_stale_agent_contracts() or failed
	failed = _validate_project_settings() or failed
	failed = _validate_json_files() or failed
	failed = _validate_no_legacy_map_tilemap_nodes() or failed
	failed = _validate_monster_locomotion_names() or failed
	failed = _validate_single_warrior_tree_source() or failed
	failed = _validate_gdscript_files_parse() or failed
	quit(1 if failed else 0)

func _validate_required_docs() -> bool:
	var failed := false
	for path in REQUIRED_DOCS:
		if not FileAccess.file_exists(path):
			push_error("Missing required architecture/domain doc: %s" % path)
			failed = true
	return failed

func _validate_master_plan_review_references() -> bool:
	var failed := false
	var plan_text := _read_text("res://Main_ChatGPT-Godot_RPG_Implementation_Plan.md")
	if plan_text.is_empty():
		return true

	for required_reference in REQUIRED_MASTER_PLAN_REFERENCES:
		if not plan_text.contains(required_reference):
			push_error("Main plan must reference canonical architecture/domain doc: %s" % required_reference)
			failed = true
	return failed

func _validate_master_plan_locked_rules() -> bool:
	var failed := false
	var plan_text := _read_text("res://Main_ChatGPT-Godot_RPG_Implementation_Plan.md")
	if plan_text.is_empty():
		return true

	for required_rule in REQUIRED_MASTER_PLAN_RULES:
		if not plan_text.contains(required_rule):
			push_error("Main plan is missing locked Umbral Explorers rule: %s" % required_rule)
			failed = true
	return failed

func _validate_domain_spec_contracts() -> bool:
	var failed := false
	failed = _validate_doc_contains(
		"res://docs/Grimvale_Lore_World_Tone_Foundation.md",
		["Umbral Explorers: Relics of Grimvale", "Heroic mystery first", "Grimvale is an entire country or island", "data/game_flow.json", "custom_kit_town", "Coming Later"]
	) or failed
	failed = _validate_doc_contains(
		"res://docs/Menu_Game_Flow_Settings_Agent_Instructions.md",
		["Umbral Explorers: Relics of Grimvale", "Phase 15A", "user://saves/index.json", "user://saves/char_0001.json", "user://saves/slot_1.json", "user://settings.json", "SettingsManager", "Coming Later", "HUD owns one modal menu coordinator", "NPC quest offer/turn-in dialogue", "custom_kit_town"]
	) or failed
	failed = _validate_doc_contains(
		"res://docs/Combat_Ability_Logic_Feedback_Agent_Instructions.md",
		["Umbral Explorers: Relics of Grimvale", "DamageCalculator", "defense_softcap", "fire, dark, arcane -> spell", "acid -> poison", "One combat feedback owner", "show_damage_numbers", "data/game_flow.json", "custom_kit_town", "No gold penalty in v1.", "Do not add screen shake or hit-stop in v1.", "Basic attacks = free"]
	) or failed
	failed = _validate_doc_contains(
		"res://docs/Inventory_Equipment_Itemization_Loot_Agent_Instructions.md",
		["Umbral Explorers: Relics of Grimvale", "standalone window", "user://saves/index.json", "user://saves/char_0001.json", "user://saves/slot_1.json", "user://settings.json", "DamageCalculator", "not consumed at full health", "not consumed at full mana"]
	) or failed
	failed = _validate_doc_contains(
		"res://docs/RPG_Skill_Tree_Agent_Guide.md",
		["Umbral Explorers: Relics of Grimvale", "res://data/skilltrees/warrior_skill_tree.json", "Player gains 1 skill point per level.", "Coming Later", "AbilityManager", "DamageCalculator", "closed doors", "user://saves/char_0001.json"]
	) or failed
	failed = _validate_doc_contains(
		"res://docs/custom_tileset_object_kit_instructions.md",
		["Umbral Explorers: Relics of Grimvale", "heroic mystery", "multi-map dungeons", "data/game_flow.json", "custom_kit_town", "brown-road-on-grey-map"]
	) or failed
	failed = _validate_doc_contains(
		"res://docs/monster_design_bible.md",
		["Umbral Explorers: Relics of Grimvale", "heroic-mystery", "DamageCalculator", "single combat feedback owner", "contact-damage", "global categorized Quest Journal"]
	) or failed
	failed = _validate_doc_contains(
		"res://docs/external_sprite_agent_instructions.md",
		["Umbral Explorers: Relics of Grimvale", "Grimvale_Lore_World_Tone_Foundation.md", "heroic-mystery", "no gore or horror-first imagery"]
	) or failed
	failed = _validate_doc_contains(
		"res://docs/external_sprite_agent_skills.md",
		["Umbral Explorers: Relics of Grimvale", "Grimvale_Lore_World_Tone_Foundation.md", "blue/gold guild identity"]
	) or failed
	failed = _validate_doc_contains(
		"res://docs/agent_handoff_template.md",
		["Menu, Game Flow, And Settings", "Combat, Abilities, And Feedback", "Inventory, Equipment, Itemization, And Loot", "Lore And Content", "DamageCalculator", "data/game_flow.json"]
	) or failed
	failed = _validate_doc_contains(
		"res://docs/agent_skills_required.md",
		["Umbral Explorers: Relics of Grimvale", "Inventory, Equipment, Itemization, And Loot Agent", "Phase 15A-15D", "One stateless `DamageCalculator`", "one point per level"]
	) or failed
	failed = _validate_doc_contains(
		"res://docs/architect_review_checklist.md",
		["Umbral Explorers: Relics of Grimvale", "brown-road-crossing-a-grey-field", "Level-up grants one skill point", "Inventory remains a standalone window", "Equipment combat stats feed the canonical `DamageCalculator`"]
	) or failed
	failed = _validate_doc_contains(
		"res://AGENTS.md",
		["Umbral Explorers: Relics of Grimvale", "Ranger/Mage disabled as **Coming Later**", "one character-ID autosave plus index", "one `DamageCalculator`", "no v1 screen shake or hit-stop"]
	) or failed
	return failed

func _validate_no_stale_agent_contracts() -> bool:
	var failed := false
	failed = _validate_doc_excludes(
		"res://docs/Menu_Game_Flow_Settings_Agent_Instructions.md",
		["Phase 13 / HUD", "or hidden until their gameplay is ready", '"current_map_id": "town_01"', "user://slot_1.json"]
	) or failed
	failed = _validate_doc_excludes(
		"res://docs/Combat_Ability_Logic_Feedback_Agent_Instructions.md",
		["hide_damage_numbers", "screen_shake_enabled", "Alternative implementation is allowed"]
	) or failed
	failed = _validate_doc_excludes(
		"res://docs/Inventory_Equipment_Itemization_Loot_Agent_Instructions.md",
		["user://slot_1.json", "segmented control for Inventory / Equipment / Comparison"]
	) or failed
	failed = _validate_doc_excludes(
		"res://docs/RPG_Skill_Tree_Agent_Guide.md",
		["Player gains 2 skill points per level.", "mana/stamina cost", "pick one path and document it"]
	) or failed
	return failed

func _validate_doc_contains(path: String, required_values: Array[String]) -> bool:
	var failed := false
	var text := _read_text(path)
	if text.is_empty():
		return true
	for required_value in required_values:
		if not text.contains(required_value):
			push_error("Canonical domain doc %s is missing required contract: %s" % [path, required_value])
			failed = true
	return failed

func _validate_doc_excludes(path: String, forbidden_values: Array[String]) -> bool:
	var failed := false
	var text := _read_text(path)
	if text.is_empty():
		return true
	for forbidden_value in forbidden_values:
		if text.contains(forbidden_value):
			push_error("Canonical domain doc %s still contains stale contract: %s" % [path, forbidden_value])
			failed = true
	return failed

func _validate_project_settings() -> bool:
	var failed := false
	var project_text := _read_text("res://project.godot")
	if project_text.is_empty():
		return true

	failed = _require_contains(project_text, 'config/features=PackedStringArray("4.3"', "Project must target Godot 4.3+ features.") or failed
	failed = _require_contains(project_text, 'window/size/viewport_width=640', "Viewport width must be 640.") or failed
	failed = _require_contains(project_text, 'window/size/viewport_height=360', "Viewport height must be 360.") or failed
	failed = _require_contains(project_text, 'window/stretch/mode="canvas_items"', "Stretch mode must be canvas_items.") or failed
	failed = _require_contains(project_text, 'window/stretch/aspect="keep"', "Stretch aspect must be keep.") or failed

	for autoload_name in REQUIRED_AUTOLOADS:
		failed = _require_contains(project_text, '%s="*res://scripts/autoload/' % autoload_name, "Missing required autoload: %s." % autoload_name) or failed

	for action_name in REQUIRED_INPUT_ACTIONS:
		failed = _require_contains(project_text, "%s={" % action_name, "Missing required input action: %s." % action_name) or failed

	for layer_key in EXPECTED_COLLISION_LAYERS.keys():
		var actual := _extract_project_value(project_text, str(layer_key))
		if actual.is_empty():
			push_error("Missing collision layer setting: %s." % str(layer_key))
			failed = true
			continue
		var expected := _normalize_label(str(EXPECTED_COLLISION_LAYERS[layer_key]))
		if _normalize_label(actual) != expected:
			push_error("Collision layer %s should be %s, found %s." % [str(layer_key), str(EXPECTED_COLLISION_LAYERS[layer_key]), actual])
			failed = true

	return failed

func _validate_json_files() -> bool:
	var failed := false
	for path in REQUIRED_JSON_FILES:
		if not FileAccess.file_exists(path):
			push_error("Missing required JSON file: %s" % path)
			failed = true
			continue
		var parsed = JSON.parse_string(_read_text(path))
		if parsed == null:
			push_error("Invalid JSON file: %s" % path)
			failed = true
	return failed

func _validate_no_legacy_map_tilemap_nodes() -> bool:
	var failed := false
	for path in _collect_files("res://scenes/maps", ["tscn"]):
		var text := _read_text(path)
		if text.contains('type="TileMap"'):
			push_error("Map scene uses legacy TileMap node instead of TileMapLayer: %s" % path)
			failed = true
	return failed

func _validate_monster_locomotion_names() -> bool:
	var failed := false
	for path in _collect_files("res://scripts/monsters", ["gd"]):
		var text := _read_text(path)
		if text.contains('play("walk")') or text.contains("play(&\"walk\")"):
			push_error("Monster script plays locomotion animation 'walk'; use 'move': %s" % path)
			failed = true

	for root in ["res://scenes/monsters", "res://assets/sprites/monsters"]:
		for path in _collect_files(root, ["tscn", "tres"]):
			var text := _read_text(path)
			if text.contains('"name": &"walk"') or text.contains('animation = &"walk"'):
				push_error("Monster resource defines locomotion animation 'walk'; use 'move': %s" % path)
				failed = true
	return failed

func _validate_single_warrior_tree_source() -> bool:
	var legacy_exists := FileAccess.file_exists("res://data/classes/warrior_skill_tree.json")
	var target_exists := FileAccess.file_exists("res://data/skilltrees/warrior_skill_tree.json")
	if legacy_exists and target_exists:
		push_error("Both legacy and target Warrior skill tree files exist. Keep one source of truth.")
		return true
	return false

func _validate_gdscript_files_parse() -> bool:
	var failed := false
	for root in GDSCRIPT_PARSE_ROOTS:
		for path in _collect_files(root, ["gd"]):
			var script := ResourceLoader.load(path, "GDScript") as GDScript
			if script == null:
				push_error("GDScript failed to parse or load: %s" % path)
				failed = true
	return failed

func _require_contains(text: String, needle: String, message: String) -> bool:
	if not text.contains(needle):
		push_error(message)
		return true
	return false

func _extract_project_value(project_text: String, key: String) -> String:
	for line in project_text.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("%s=" % key):
			return trimmed.get_slice("=", 1).strip_edges().trim_prefix('"').trim_suffix('"')
	return ""

func _normalize_label(value: String) -> String:
	return value.to_lower().replace(" ", "").replace("_", "").replace("-", "")

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not read file: %s" % path)
		return ""
	var text := file.get_as_text()
	file.close()
	return text

func _collect_files(path: String, extensions: Array[String]) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Could not open directory: %s" % path)
		return files

	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue

		var child_path := path.path_join(name)
		if dir.current_is_dir():
			files.append_array(_collect_files(child_path, extensions))
		elif extensions.has(name.get_extension().to_lower()):
			files.append(child_path)
	dir.list_dir_end()
	return files
