extends SceneTree

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var registry := root.get_node_or_null("DataRegistry")
	if registry == null:
		push_error("DataRegistry autoload is unavailable.")
		quit(1)
		return
	var validation_errors: Array = registry.get("validation_errors")
	var validation_warnings: Array = registry.get("validation_warnings")
	var items: Dictionary = registry.get("items")
	var shops: Dictionary = registry.get("shops")
	var failed := false
	var strict := OS.get_cmdline_user_args().has("--strict")

	for message in validation_errors:
		push_error("Item validation failed: %s" % message)
		failed = true
	if strict:
		for message in validation_warnings:
			if not str(message).ends_with(" has no icon path."):
				push_error("Strict item validation failed: %s" % message)
				failed = true

	var source_ids: Dictionary = {}
	var items_dir := DirAccess.open("res://data/items")
	if items_dir == null:
		push_error("Could not open per-item definition directory.")
		failed = true
	else:
		for file_name in items_dir.get_files():
			if not file_name.ends_with(".json"):
				continue
			var source: Dictionary = registry.call("load_json", "res://data/items/%s" % file_name)
			var file_id := file_name.get_basename()
			var source_id := str(source.get("item_id", ""))
			if source_id == "":
				push_error("%s has no item_id." % file_name)
				failed = true
				continue
			if source_id != file_id:
				push_error("%s declares item_id '%s'." % [file_name, source_id])
				failed = true
			if source_ids.has(source_id):
				push_error("%s duplicates item_id '%s' from %s." % [file_name, source_id, source_ids[source_id]])
				failed = true
			else:
				source_ids[source_id] = file_name

	if items.has("item_tiers") or items.has("affixes") or items.has("loot_tables"):
		push_error("Aggregate itemization or loot data leaked into per-item definitions.")
		failed = true
	if (registry.get("item_tiers") as Dictionary).get("tiers", {}).size() != 5:
		push_error("Expected five canonical material tiers.")
		failed = true
	if not (registry.get("affixes") as Dictionary).get("pools", {}).has("weapon_basic"):
		push_error("Weapon affix configuration was not loaded.")
		failed = true
	if not (registry.get("loot_tables") as Dictionary).has("rarity_weights"):
		push_error("Loot configuration was not loaded.")
		failed = true

	if registry.call("get_item_data", "iron_sword") != null or registry.call("get_item_data", "iron_armor") != null:
		push_error("Undefined iron equipment IDs must not alias distinct steel definitions.")
		failed = true

	var bronze_sword := registry.call("get_item_data", "bronze_sword") as WeaponData
	if bronze_sword == null or bronze_sword.damage != 12 or bronze_sword.slot != "weapon" or bronze_sword.category != "equipment":
		push_error("Bronze sword compatibility normalization failed.")
		failed = true

	var bronze_armor := registry.call("get_item_data", "bronze_armor") as ArmorData
	if bronze_armor == null or bronze_armor.defense != 10 or bronze_armor.hp_bonus != 50 or bronze_armor.slot != "overall":
		push_error("Bronze armor compatibility normalization failed.")
		failed = true

	var bracelet := registry.call("get_item_data", "leather_bracelet") as ItemData
	if bracelet == null or bracelet.slot != "amulet" or bracelet.attack_bonus != 5:
		push_error("Leather bracelet equipment normalization failed.")
		failed = true

	for quest_item_id in ["healing_herb", "herb_healing", "miners_helmet"]:
		var quest_item := registry.call("get_item_data", quest_item_id) as ItemData
		if quest_item == null or quest_item.category != "quest":
			push_error("%s did not normalize as a quest item." % quest_item_id)
			failed = true

	var legacy_definition: Dictionary = registry.call("normalize_item_definition", "legacy_test_sword", {
		"item_id": "legacy_test_sword",
		"item_type": ItemData.ItemType.WEAPON,
		"weapon_type": WeaponData.WeaponType.SWORD,
		"damage": 7,
		"attack_speed": 1.25
	})
	if legacy_definition.get("category", "") != "equipment" \
			or legacy_definition.get("slot", "") != "weapon" \
			or int(legacy_definition.get("base_stats", {}).get("attack", 0)) != 7:
		push_error("Legacy item field normalization failed.")
		failed = true

	var legacy_shop: Dictionary = registry.call("normalize_shop_data", "legacy_shop", {
		"name": "Legacy Shop",
		"inventory": [{"item_id": "bronze_sword", "price": 12, "stock": 3}]
	})
	if legacy_shop.get("shop_name", "") != "Legacy Shop" \
			or int(legacy_shop.get("items", [])[0].get("buy_price", 0)) != 12 \
			or int(legacy_shop.get("items", [])[0].get("quantity", 0)) != 3:
		push_error("Legacy shop alias normalization failed.")
		failed = true

	for shop_id in shops:
		var shop: Dictionary = shops[shop_id]
		if str(shop.get("shop_name", "")) == "":
			push_error("Shop %s did not normalize shop_name." % shop_id)
			failed = true
		for entry in shop.get("items", []):
			if not entry.has("buy_price") or not entry.has("quantity"):
				push_error("Shop %s contains an unnormalized item entry." % shop_id)
				failed = true

	if failed:
		quit(1)
		return

	print("Item data validation passed: %d items, %d shops." % [items.size(), shops.size()])
	quit(0)
