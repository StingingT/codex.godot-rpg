# Main-spec Cleanup Summary

This archive was cleaned to follow `Main_ChatGPT-Godot_RPG_Implementation_Plan.md`.

## Changed

- Removed the inactive legacy architecture and replaced it with active Godot systems.
- Removed old skill resource files that used non-real-time cooldown wording.
- Migrated ability data into `data/abilities/abilities.json`.
- Added seconds-based real-time ability fields.
- Added data registry/loading through `DataRegistry`.
- Added `AbilityManager` for cooldowns, mana checks, cast timing, and descriptions.
- Added `EffectRouter` for damage/heal/status routing.
- Added `StatusEffectComponent` for DOT, HOT, buffs, debuffs, shields, slows, and stuns.
- Added `SpawnManager` for Main-spec encounter tables.
- Added `MapTransition` for metadata-driven exits.
- Added Main-spec map metadata and encounter tables.
- Fixed player and monster collision layers to match the Main spec.
- Added missing active folders from the Main spec.
- Added Main-spec map structure nodes to each existing hand-authored map scene.

## Not validated here

Godot editor/runtime validation could not be performed in this environment. Recommended first validation steps:

1. Open the project in Godot 4.3+.
2. Fix any script parse errors.
3. Confirm autoload order.
4. Start from the title screen.
5. Test player movement and collision.
6. Test basic attack on a monster.
7. Test one ability input.
8. Test a map transition.
