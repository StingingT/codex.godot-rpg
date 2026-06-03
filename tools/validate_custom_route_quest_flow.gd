extends SceneTree

const QUEST_MANAGER_PATH := "res://scripts/autoload/quest_manager.gd"
const QUEST_STATUS_COMPLETE := 3
const QUEST_STATUS_TURNED_IN := 4
const CUSTOM_ROUTE_QUEST_CHAIN: Array[String] = [
	"purge_corrupted_field",
	"break_ashbone_ruins",
	"drown_marsh_rot",
	"seal_blackwater_catacombs",
	"break_the_dark_keep"
]

const CUSTOM_ROUTE_KILL_EVENTS := {
	"purge_corrupted_field": "slime_green",
	"break_ashbone_ruins": "skeleton",
	"drown_marsh_rot": "swamp_monster",
	"seal_blackwater_catacombs": "skeleton",
	"break_the_dark_keep": "dark_knight"
}

var quest_manager

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var failed := false
	await process_frame
	var quest_manager_script := load(QUEST_MANAGER_PATH) as Script
	if quest_manager_script == null:
		push_error("Could not load QuestManager script: %s" % QUEST_MANAGER_PATH)
		quit(1)
		return
	quest_manager = quest_manager_script.new()
	quest_manager._load_all_quests()
	_reset_quest_state()

	failed = _validate_quests_loaded() or failed
	failed = _validate_prerequisite_lock() or failed
	if not failed:
		failed = await _validate_chain_completion_flow()
	_reset_quest_state()
	if not failed:
		failed = await _validate_kill_event_chain_flow()

	_reset_quest_state()
	quest_manager.free()
	quest_manager = null
	await process_frame
	quit(1 if failed else 0)

func _validate_quests_loaded() -> bool:
	var failed := false
	for quest_id in CUSTOM_ROUTE_QUEST_CHAIN:
		if not quest_manager.all_quests.has(quest_id):
			push_error("Custom route quest is not loaded by QuestManager: %s" % quest_id)
			failed = true
	return failed

func _validate_prerequisite_lock() -> bool:
	var failed := false
	for index in range(1, CUSTOM_ROUTE_QUEST_CHAIN.size()):
		var quest_id := CUSTOM_ROUTE_QUEST_CHAIN[index]
		if quest_manager.is_quest_available(quest_id):
			push_error("Quest %s is available before prerequisite turn-in." % quest_id)
			failed = true
		if quest_manager.start_quest(quest_id):
			push_error("QuestManager allowed out-of-order quest start: %s" % quest_id)
			failed = true
			quest_manager.active_quests.erase(quest_id)
	return failed

func _validate_chain_completion_flow() -> bool:
	var failed := false
	for index in range(CUSTOM_ROUTE_QUEST_CHAIN.size()):
		var quest_id := CUSTOM_ROUTE_QUEST_CHAIN[index]
		if not quest_manager.is_quest_available(quest_id):
			push_error("Expected quest to be available in route order: %s" % quest_id)
			return true
		if not quest_manager.start_quest(quest_id):
			push_error("QuestManager could not start available quest: %s" % quest_id)
			return true
		var active_quest: Dictionary = quest_manager.active_quests.get(quest_id, {})
		var objectives: Array = active_quest.get("objectives", [])
		if objectives.is_empty():
			push_error("Quest %s has no objectives after start." % quest_id)
			return true
		for objective_index in range(objectives.size()):
			var objective: Dictionary = objectives[objective_index]
			quest_manager.update_objective(quest_id, objective_index, int(objective.get("required", 1)))
		await process_frame
		if quest_manager.get_quest_status(quest_id) != QUEST_STATUS_COMPLETE:
			push_error("Quest %s did not complete after required objective progress." % quest_id)
			return true
		if not quest_manager.turn_in_quest(quest_id):
			push_error("QuestManager could not turn in completed quest: %s" % quest_id)
			return true
		if quest_manager.get_quest_status(quest_id) != QUEST_STATUS_TURNED_IN:
			push_error("Quest %s was not marked turned in." % quest_id)
			return true
		if index + 1 < CUSTOM_ROUTE_QUEST_CHAIN.size():
			var next_quest_id := CUSTOM_ROUTE_QUEST_CHAIN[index + 1]
			if not quest_manager.is_quest_available(next_quest_id):
				push_error("Next route quest did not unlock after turn-in: %s" % next_quest_id)
				failed = true
	return failed

func _validate_kill_event_chain_flow() -> bool:
	var failed := false
	for index in range(CUSTOM_ROUTE_QUEST_CHAIN.size()):
		var quest_id := CUSTOM_ROUTE_QUEST_CHAIN[index]
		if not quest_manager.start_quest(quest_id):
			push_error("QuestManager could not start quest for kill-event validation: %s" % quest_id)
			return true
		var active_quest: Dictionary = quest_manager.active_quests.get(quest_id, {})
		var objectives: Array = active_quest.get("objectives", [])
		if objectives.is_empty():
			push_error("Quest %s has no objectives for kill-event validation." % quest_id)
			return true

		quest_manager._on_monster_killed("bat", Vector2.ZERO)
		await process_frame
		if int(active_quest.get("progress", [0])[0]) != 0:
			push_error("Quest %s progressed from an unrelated bat kill." % quest_id)
			return true

		for objective_index in range(objectives.size()):
			var objective: Dictionary = objectives[objective_index]
			var kill_event_id := str(CUSTOM_ROUTE_KILL_EVENTS.get(quest_id, objective.get("target", objective.get("target_id", ""))))
			var required := int(objective.get("required", 1))
			for _kill_index in range(required):
				quest_manager._on_monster_killed(kill_event_id, Vector2.ZERO)
		await process_frame
		if quest_manager.get_quest_status(quest_id) != QUEST_STATUS_COMPLETE:
			push_error("Quest %s did not complete from matching monster_killed events." % quest_id)
			return true
		if not quest_manager.turn_in_quest(quest_id):
			push_error("Quest %s could not turn in after kill-event completion." % quest_id)
			return true
		if index + 1 < CUSTOM_ROUTE_QUEST_CHAIN.size():
			var next_quest_id := CUSTOM_ROUTE_QUEST_CHAIN[index + 1]
			if not quest_manager.is_quest_available(next_quest_id):
				push_error("Next quest did not unlock after kill-event flow: %s" % next_quest_id)
				failed = true
	return failed

func _reset_quest_state() -> void:
	if quest_manager == null:
		return
	quest_manager.active_quests.clear()
	quest_manager.completed_quests.clear()
	quest_manager.turned_in_quests.clear()
