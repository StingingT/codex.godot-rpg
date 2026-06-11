# Inventory Phase A Architect Handoff

## Summary

- Agent role: Inventory, Equipment, Itemization & Loot Agent
- Main plan phase: Phase 9, migration Phase A
- Domain docs used: `docs/Inventory_Equipment_Itemization_Loot_Agent_Instructions.md`
- Goal: Normalize current item/shop data and establish validated canonical metadata without changing save version or inventory capacity.
- Outcome: Phase A implementation complete and submitted for architect review.

## Scope

- Added: Canonical item category/slot/tier/stat metadata, aggregate tier/affix/loot configuration, missing live item definitions, and item-data validation.
- Changed: `DataRegistry` now normalizes legacy item/shop schemas and validates active references. Shop loading uses normalized registry data.
- Removed: Unresolved `antidote` and `revive_scroll` shop entries; duplicate live iron gear references.
- Deferred or held: Inventory tabs/stack splitting/save migration (Phase B), canonical runtime equipment migration (Phase C), item instances (Phase D), live loot/pity (Phase E), UI/economy completion (Phase F), and missing final item icons.

## Files

```text
res://scripts/autoload/data_registry.gd - canonical normalization, aggregate config loading, and validation
res://scripts/autoload/shop_manager.gd - load normalized shops through DataRegistry
res://scripts/inventory/item_data.gd - canonical static item metadata fields
res://scripts/npcs/shop_npc.gd - use normalized shop data
res://tools/validate_item_data.gd - focused Phase A validation
res://tools/validate_all.ps1 - include strict-aware item validation

res://data/itemization/item_tiers.json - five canonical material tiers
res://data/itemization/affixes.json - initial aggregate affix pools
res://data/loot/loot_tables.json - rarity and pity configuration root

res://data/items/apprentice_staff.json - resolve mage starter item
res://data/items/bone.json - canonical material metadata
res://data/items/bronze_armor.json - canonical overall metadata
res://data/items/bronze_helmet.json - canonical headgear metadata
res://data/items/bronze_sword.json - canonical weapon metadata
res://data/items/cloth_robe.json - resolve mage starter armor
res://data/items/healing_herb.json - resolve legacy collect objective
res://data/items/health_potion.json - canonical consumable metadata
res://data/items/herb_healing.json - resolve active collect objective
res://data/items/iron_pickaxe.json - resolve non-tiered quest reward
res://data/items/leather_armor.json - resolve starter/quest armor
res://data/items/leather_bracelet.json - migrate legacy material to amulet
res://data/items/mana_potion.json - canonical consumable metadata
res://data/items/miners_helmet.json - resolve collect objective
res://data/items/ranger_cloak.json - resolve quest armor reward
res://data/items/short_bow.json - resolve ranger starter item
res://data/items/slime_gel.json - correct legacy consumable classification to material
res://data/items/steel_armor.json - canonical steel armor
res://data/items/steel_sword.json - canonical steel weapon
res://data/items/stone_core.json - resolve quest reward
res://data/items/wooden_sword.json - resolve warrior starter item

res://data/shops/blacksmith.json - remove iron duplicates; retain canonical steel gear
res://data/shops/healer_shop.json - remove inactive unresolved consumables
res://data/quests/cave_exploration.json - replace iron sword reward with canonical steel sword
```

## Source Of Truth Check

- Main plan sections followed: 0.1, 11, Phase 9
- Domain guide sections followed: 0, 4-8, 13, 16-18
- Conflicts corrected during review: plural category IDs, static runtime ring slots, hardcoded starter references, and iron-to-steel aliases.
- Architect ruling: `iron_sword` and `iron_armor` must not silently alias distinct steel definitions. Active references use canonical exact IDs.
- Assumption: `iron_pickaxe` is a non-equippable material/tool reward and therefore has no material tier.

## Architecture Notes

- Data owner: `DataRegistry` owns immutable normalized definitions/configuration; `Inventory` remains runtime ownership authority.
- State mutation path: No new runtime item-state owner was introduced.
- Signals/events used: Existing inventory/shop signals unchanged.
- Autoloads touched: `DataRegistry`, `ShopManager`.
- Save/load impact: Save version remains 1. Item IDs retain exact identity; no silent alias migration was introduced.
- UI impact: Existing UI behavior remains compatible.
- Performance risk: Validation runs once when registry data reloads; item Resources remain cached and duplicated per request.

## Validation

Focused command:

```powershell
& "C:\Users\guyro\Desktop\RPG\Exterior sprites_Winlu\Godot_v4.3-stable_win64_console.exe" --headless --path . --script "res://tools/validate_item_data.gd"
```

Result:

```text
Item data validation passed: 21 items, 3 shops.
16 non-blocking warnings: definitions awaiting final icon assets.
```

Project commands:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tools\run_architect_review.ps1" -GodotBin "C:\Users\guyro\Desktop\RPG\Exterior sprites_Winlu\Godot_v4.3-stable_win64_console.exe" -StrictItemData -SkipScreenshots
```

Result:

```text
Strict item validation passed: 21 items, 3 shops.
All Godot validation checks passed.
Normal-renderer UI layout validation passed.
Architect review checks completed.
```

## Risks And Holds

- Safe to integrate: Phase A code/data normalization and focused validation.
- Should stay on hold: Final item icon assets; their current missing-path warnings are explicitly non-blocking for Phase A.
- Optional follow-up: Consolidate `healing_herb` and `herb_healing` only with explicit quest/save migration.
- Needs follow-up task: Architect approval before Phase B changes inventory/save structures.
