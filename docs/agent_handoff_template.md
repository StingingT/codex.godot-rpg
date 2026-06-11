# Agent Handoff Template

**Project:** Umbral Explorers: Relics of Grimvale

Agents should fill this out when submitting work for architect review.

## Summary

- Agent role:
- Main plan phase:
- Domain docs used:
- Goal:
- Outcome:

## Scope

- Added:
- Changed:
- Removed:
- Deferred or held:

## Files

List every changed file and why it changed.

```text
res://path/to/file.gd - reason
res://path/to/file.tscn - reason
```

## Source Of Truth Check

- Main plan section(s) followed:
- Domain guide section(s) followed:
- Locked master-plan rules affected:
- Any conflicts with the main plan:
- Any assumptions made:

## Architecture Notes

- Data owner(s):
- State mutation path:
- Signals/events used:
- Autoloads touched:
- Collision layers touched:
- Save/load impact:
- UI impact:
- Performance risk:
- Migration/compatibility impact:

## Role-Specific Evidence

### Implementation

- Real-time combat preserved:
- Existing systems reused:
- New systems introduced:

### Sprite Handoff

- Manifest updated:
- PNG files delivered:
- Missing assets:

### Maps And Tileset

- Map scene contract satisfied:
- Metadata updated:
- `data/game_flow.json` impact:
- Live implementation IDs preserved or migrated:
- Encounter tables updated:
- Spawn/portal safety checked:
- Old flat-template content removed or explicitly held:

### Monsters

- Monster IDs changed:
- Animation names use `move`:
- Damage routes through `DamageCalculator`:
- Feedback routes through the shared owner:
- Contact-damage behavior audited:
- Encounter IDs changed:
- Sprite manifest paths verified:

### Skill Tree

- Tree data source:
- Node count:
- Positions from JSON:
- UI follows ornate three-branch target:
- One skill point per level verified:
- `AbilityManager`/`DamageCalculator` integration:
- Character autosave payload verified:

### Menu, Game Flow, And Settings

- Main Phase 15 subphase:
- Warrior enabled; Ranger/Mage disabled as Coming Later:
- Character autosave/index and `slot_1.json` migration:
- `SettingsManager` and `user://settings.json`:
- HUD modal coordinator/exclusivity:
- `data/game_flow.json` start/respawn target:
- 640x360 and larger-text evidence:

### Combat, Abilities, And Feedback

- Canonical `DamageCalculator` and package:
- V1 damage types and legacy type mapping:
- Basic Attack + four slots:
- Cleave/Charge and collision evidence:
- Potion success/failure behavior:
- Single feedback owner and mobile caps:
- No screen shake/hit-stop:
- Death/Return to Town penalties and reset behavior:

### Inventory, Equipment, Itemization, And Loot

- Standalone Inventory preserved:
- Character/Equipment relationship:
- Character autosave payload migration:
- Save index/settings ownership untouched:
- Equipment stats feed `DamageCalculator`:
- Potion non-consumption at full HP/mana:

### Lore And Content

- Grimvale region/dungeon/relic references:
- Heroic-mystery and Umbral tone check:
- Runtime IDs changed:
- Required migration for any renamed ID:
- Owning gameplay domain doc consulted:

## Validation

Command run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tools\validate_all.ps1" -GodotBin "C:\Users\guyro\Desktop\RPG\Exterior sprites_Winlu\Godot_v4.3-stable_win64_console.exe"
```

Result:

```text
Paste result here.
```

Manual checks:

- Scenes opened:
- UI inspected:
- Gameplay tested:

## Risks And Holds

- Safe to integrate:
- Should stay on hold:
- Needs follow-up task:

## Architect Log

After review, record the outcome in `docs/agent_integration_log.md`.
