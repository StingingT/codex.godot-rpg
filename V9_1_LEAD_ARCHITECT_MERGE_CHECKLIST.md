# V9.1 Lead Architect Merge Checklist

This package merges only reviewed/approved agent outputs into V9.1.

## Included

- HUD mobile patch: additive extension of the existing V9.1 HUD.
- Quest templates: additive JSON templates under `res://data/quests/`.
- Monster sprite placeholders: PNG sheets and reusable SpriteFrames resources.
- Test map package: `test_map.tscn`, placeholder TileSet, and additive map/encounter entries.

## Must validate in Godot before continuing

1. Open the project in Godot 4.3+.
2. Confirm the project opens without scene/script parse errors.
3. Open `res://scenes/ui/hud.tscn`.
   - Existing HUD values still display.
   - Character/inventory/skill hooks still work.
   - Minimap still appears/toggles.
   - `AttackButton`, `AbilityButton1-4`, and `PauseButton` exist.
4. Open `res://scenes/maps/test_map.tscn`.
   - It opens without parse errors.
   - All four `TileMapLayer` nodes show `placeholder_tileset.tres`.
   - `EntryPoints`, `ExitTriggers`, `SpawnPoints`, `BossSpawnPoint`, `NPCs`, `Items`, and `CameraLimits` are present.
5. Check `res://data/maps/maps.json` contains the additive `test_map` entry.
6. Check `res://data/encounters/encounters.json` contains the additive `test_map_low` entry.
7. Confirm quest templates load through `DataRegistry.load_folder_json("res://data/quests")`.
8. Confirm sprite sheets and `.tres` resources are visible under `res://assets/sprites/monsters/`.

## Known notes

- The joystick is a placeholder node only. Touch movement logic is not implemented yet.
- The mobile HUD buttons emit signals, but player/combat input wiring should be implemented in the next gameplay phase.
- `test_map.tscn` is a structural test map, not final content.
- The placeholder TileSet was normalized manually, but still should be opened and saved once in the Godot editor.
- Quest templates include future targets/items/NPCs that may not exist yet. Treat them as templates until matching content is added.

## Suggested next commit

`V9.1: Merge reviewed agent outputs and mobile HUD patch`
