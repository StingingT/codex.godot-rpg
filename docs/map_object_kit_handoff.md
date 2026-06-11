# Map Agent Handoff: Expanded Object Kit

## Summary

- Agent role: Maps and tileset
- Date: 2026-06-06
- Domain guide: `docs/custom_tileset_object_kit_instructions.md`
- Goal: Improve the weakest tileset family and make map decoration read as authored places instead of random props.
- Outcome: Ready for main architect review. No commit or push was made.

## Scope

- Expanded the object atlas from 8 to 24 tiles.
- Added biome decor: withered grass, bones, stones, broken boards, rubble, signpost, ember brazier, and marsh reeds.
- Added structural props: grave marker, sarcophagus, altar, urn, modular ruined walls, and spiked barricade.
- Replaced repeated generic wall tiles with left/center/right wall runs.
- Reworked map prop placement into town service storage, a field camp, ruins debris, marsh driftwood/reeds, crypt furnishings, and keep defenses.
- Added narrow collision footprints for solid props instead of full transparent 32x32 cells.
- Added validation for atlas size, metadata, prop collision, biome-specific prop usage, and blocking decor under gameplay markers.
- Corrected three existing overlaps found by the new checks: town spawn/crate, ruins spawn/wall, and marsh north entry/brush.

## Files

```text
res://assets/tilesets/custom/poe_object_tiles.png
res://assets/tilesets/custom/rpg_tileset.tres
res://scripts/world/custom_kit_test_map_builder.gd
res://tools/generate_custom_style_assets.py
res://tools/apply_custom_tileset_metadata.gd
res://tools/validate_custom_maps.gd
res://project.godot
```

`project.godot` only restores `window/stretch/aspect="keep"`, required by the architect gate. Unrelated concurrent input changes were preserved.

## Architecture Notes

- Tile size remains 32x32.
- TileSet source IDs are unchanged.
- World blockers remain on collision layer 2.
- Nonblocking storytelling decor has no collision and remains walkable.
- No autoload, save format, map metadata, encounter table, or quest data was changed.
- Runtime placement remains deterministic and uses the existing `TileMapLayer` map contract.

## Validation

Commands:

```powershell
python .\tools\generate_custom_style_assets.py
Godot_v4.3-stable_win64_console.exe --headless --import --path .
Godot_v4.3-stable_win64_console.exe --headless --path . --script res://tools/apply_custom_tileset_metadata.gd
Godot_v4.3-stable_win64_console.exe --headless --path . --script res://tools/validate_custom_maps.gd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\run_architect_review.ps1
```

Result:

```text
Custom map validation passed.
All Godot validation checks passed.
Normal-renderer UI layout validation passed.
All review screenshots captured.
Architect review checks completed.
```

Review renders:

```text
res://review_artifacts/screenshots/map_custom_kit_town.png
res://review_artifacts/screenshots/map_custom_kit_field.png
res://review_artifacts/screenshots/map_custom_kit_ruins.png
res://review_artifacts/screenshots/map_custom_kit_marsh.png
res://review_artifacts/screenshots/map_custom_kit_catacombs.png
res://review_artifacts/screenshots/map_custom_kit_dark_keep.png
```

## Follow-Up

- Next tileset quality priority: add directional cliff/wall corners and room-edge transitions so dungeon layouts stop reading as large rectangular bands.
- Later: move tall structural props that need player overlap into reusable y-sorted scenes with lower-footprint collision.
