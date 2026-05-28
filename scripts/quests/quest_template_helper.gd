extends Node

class_name QuestTemplateHelper

# QuestTemplateHelper
# -------------------
#
# This helper provides utility functions to load quest templates from
# JSON files located in `res://data/quests/`. It does not enforce any
# particular quest architecture; instead, it returns plain dictionaries
# that can be consumed by a higher‑level QuestManager. If needed, this
# helper can also perform basic validation to ensure quests conform to
# the expected schema (e.g. have required fields and correct types).
#
# Usage:
#
# ```
# var helper = QuestTemplateHelper.new()
# var quest = helper.load_quest("clear_green_slimes")
# var quests = helper.load_all_quests()
# ```

# Directory where quest JSON files are stored.
const QUEST_DIRECTORY := "res://data/quests"

# Load a single quest by its identifier. Returns an empty dictionary
# if the file does not exist or cannot be parsed.
func load_quest(id: String) -> Dictionary:
    var path := "%s/%s.json" % [QUEST_DIRECTORY, id]
    var file := FileAccess.open(path, FileAccess.READ)
    if file:
        var data := file.get_as_text()
        var result: Variant = JSON.parse_string(data)
        if typeof(result) == TYPE_DICTIONARY:
            return _normalize_quest(result)
        else:
            push_error("QuestTemplateHelper: invalid JSON in %s" % path)
    else:
        push_warning("QuestTemplateHelper: could not open %s" % path)
    return {}

# Load all quests in the quest directory. Returns an array of dictionaries.
func load_all_quests() -> Array:
    var quests: Array = []
    var dir := DirAccess.open(QUEST_DIRECTORY)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if file_name.ends_with(".json"):
                var id := file_name.get_basename()
                var quest_data: Dictionary = load_quest(id)
                if not quest_data.is_empty():
                    quests.append(quest_data)
            file_name = dir.get_next()
    return quests

# Optional: validate a quest dictionary against expected schema. Returns
# true if valid, false otherwise.
func validate_quest(quest: Dictionary) -> bool:
    var required_fields := ["quest_id", "description", "objectives", "rewards"]
    for field in required_fields:
        if not quest.has(field):
            push_error("QuestTemplateHelper: missing required field %s in quest %s" % [field, quest.get("quest_id", "unknown")])
            return false
    if not quest.has("title") and not quest.has("quest_name"):
        push_error("QuestTemplateHelper: missing title/quest_name in quest %s" % quest.get("quest_id", "unknown"))
        return false
    # Validate objectives
    var objectives = quest.get("objectives")
    if typeof(objectives) != TYPE_ARRAY:
        push_error("QuestTemplateHelper: objectives must be an array in quest %s" % quest.get("quest_id", "unknown"))
        return false
    for obj in objectives:
        if typeof(obj) != TYPE_DICTIONARY:
            push_error("QuestTemplateHelper: each objective must be a dictionary in quest %s" % quest.get("quest_id", "unknown"))
            return false
        if not obj.has("type") or (not obj.has("target_id") and not obj.has("target")) or not obj.has("required"):
            push_error("QuestTemplateHelper: objective missing fields in quest %s" % quest.get("quest_id", "unknown"))
            return false
    # Validate rewards
    var rewards = quest.get("rewards")
    if typeof(rewards) != TYPE_DICTIONARY and typeof(rewards) != TYPE_ARRAY:
        push_error("QuestTemplateHelper: rewards must be a dictionary or array in quest %s" % quest.get("quest_id", "unknown"))
        return false
    return true

func _normalize_quest(quest: Dictionary) -> Dictionary:
    if not quest.has("title") and quest.has("quest_name"):
        quest["title"] = quest["quest_name"]
    if quest.has("objectives") and typeof(quest["objectives"]) == TYPE_ARRAY:
        for objective in quest["objectives"]:
            if typeof(objective) == TYPE_DICTIONARY:
                if not objective.has("target_id") and objective.has("target"):
                    objective["target_id"] = objective["target"]
                if not objective.has("target") and objective.has("target_id"):
                    objective["target"] = objective["target_id"]
    return quest
