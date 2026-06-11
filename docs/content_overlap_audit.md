# Content Overlap And Legacy Audit

**Date:** 2026-06-07  
**Source of truth:** `Main_ChatGPT-Godot_RPG_Implementation_Plan.md`

## Integrated Corrections

- New Game now starts at `custom_kit_town`.
- Normal travel choices are derived from `DataRegistry.get_travel_maps()`.
- Only maps with `content_state: "active"` appear in normal travel.
- Old map IDs remain registered as `legacy` so existing saves can still load.
- `test_map` is marked `development`.
- The active custom town no longer links back into the legacy town route.
- All quest files now declare active or legacy lifecycle state.
- The unused competing `Equipment` resource was removed; `Inventory` remains the equipment owner.
- The unused Phase 16 `EffectsManager` stub is no longer autoloaded.
- `validate_content_lifecycle.gd` now guards the active/legacy boundary and reports remaining overlaps.
- Screenshot capture now includes every legacy and development map.

## Map Classification

Active route:

```text
custom_kit_town
custom_kit_field
custom_kit_ruins
custom_kit_marsh
custom_kit_catacombs
custom_kit_dark_keep
```

Legacy flat-background maps:

```text
town
royal_courtyard
mystic_forest
river_crossing
watchtower_ruins
sunken_marsh
```

Legacy placeholder-tileset maps:

```text
fields
swamp
cave
dungeon
```

Development placeholder map:

```text
test_map
```

## Holds

1. Convert the six active custom maps from runtime-painted `TileMapLayer` cells to genuinely hand-authored scene tile data. Their current visuals and structure are usable, but `custom_kit_test_map_builder.gd` remains prototype architecture.
2. Replace or retire the ten legacy maps after save migration policy is defined.
3. Consolidate overlapping active/legacy quest objectives:
   - `purge_corrupted_field` / `kill_slimes`
   - `break_ashbone_ruins` / `clear_watchtower_ruins`
   - `drown_marsh_rot` / `cleanse_sunken_marsh`
   - `seal_blackwater_catacombs` / `hunt_skeletons`
4. Resolve or retire legacy quest targets with no monster definition:
   - `skeleton_miner`
   - `skeleton_boss`
   - `goblin_archer`
   - `golem_stone`
5. Remove ignored serialized `available_maps` arrays from legacy scenes after their final migration.
6. Consolidate six groups of byte-identical Winlu source assets after confirming the preferred source filenames.
7. Wire or replace `effects_manager.gd` during Phase 16 before restoring it as an autoload.

## Validation Evidence

```text
Content lifecycle validation passed:
6 active maps, 10 legacy maps, 1 development map,
5 active quests, 16 legacy quests.

All Godot validation checks passed.
Normal-renderer UI layout validation passed.
Architect review checks completed.
```
