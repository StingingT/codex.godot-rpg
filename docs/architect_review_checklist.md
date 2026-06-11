# Architect Review Checklist

Use this checklist when reviewing agent work before it is merged into **Umbral Explorers: Relics of Grimvale**.
Ask agents to submit work with `docs/agent_handoff_template.md` when possible.
Record reviewed outcomes in `docs/agent_integration_log.md`.

## Source Of Truth Order

1. `Main_ChatGPT-Godot_RPG_Implementation_Plan.md`
2. Domain docs listed in the main plan section `0.1`
3. Existing project structure, scenes, scripts, data, and validation tools
4. Agent notes or implementation summaries

If an agent output conflicts with the main plan, hold that part back and integrate only the compatible work.

## Global Gates

- Uses Godot 4.3+ and GDScript.
- Keeps the game 2D top-down and real-time, not turn-based.
- Uses Godot scenes, GDScript, Resources, and JSON metadata.
- Uses `TileMapLayer` for map layers, not legacy `TileMap`-only map architecture.
- Uses `res://` resource paths inside Godot files and data.
- Preserves snake_case files/folders/functions/variables and PascalCase node/scene roots.
- Adds content through data files or scene instances where possible.
- Does not replace core systems wholesale when an additive patch will work.
- Does not generate final monster art inside implementation work.
- Monster locomotion animation is named `move`, not `walk`.
- Agent instructions and handoff notes do not contradict the locked master-plan rules.

## Architecture Gates

- Data ownership is clear: the owner changes its own state through public methods.
- UI listens to signals or manager state; it does not directly own gameplay data.
- Autoload changes match the main plan and `project.godot`.
- Collision layers match the main plan layer table.
- Runtime save data is serialized as dictionaries or supported Godot data, not raw Node/Object instances.
- Character saves and global settings remain separate; settings use `user://settings.json`.
- Character persistence uses `user://saves/index.json` plus the character-ID autosave, with atomic writes and `slot_1.json` migration.
- New-game, return-to-town, and respawn destinations come from game-flow/map metadata rather than UI hardcoding.
- Hot paths avoid synchronous `load()`, repeated `get_nodes_in_group()`, and broad per-frame scene scans.

## Role-Specific Gates

### Implementation

- Follows the current phase order unless the task is explicitly an additive integration.
- Wires delivered assets instead of redrawing them.
- Keeps combat real-time with hitbox/hurtbox/effect flow.
- Uses `DataRegistry`, managers, and existing components before introducing parallel systems.

### Lore And Content

- Follows `docs/Grimvale_Lore_World_Tone_Foundation.md`.
- Treats Grimvale as a country/island-scale setting with surviving towns and multi-map portal-linked dungeons.
- Keeps heroic mystery and fallen-kingdom fantasy ahead of horror or hopeless grimdark.
- Connects relics to the Fallen and uses Umbral energy consistently for corruption, monster attraction, rifts, and repeatable dungeon logic.

### Menu, Game Flow, And Settings

- Follows `docs/Menu_Game_Flow_Settings_Agent_Instructions.md` and the Phase 15 subphase order.
- Uses the approved title, New Game/Continue/Settings flow, and last-played character banner.
- Warrior is playable in v1; Ranger and Mage are disabled as `Coming Later`.
- Uses one character-ID autosave plus `index.json`, with migration from `slot_1.json` and atomic writes.
- Uses one HUD/menu coordinator and one major modal at a time.
- Reuses standalone Inventory, canonical Character/Equipment, Skill Tree, and Quest systems instead of duplicating data or logic.
- Keeps NPC quest interaction separate from the categorized global Quest Journal.
- Blocks pause-menu Return to Town during combat and applies no v1 death penalty.
- Validates all affected menus at 640×360, including larger-text mode.

### Combat, Abilities, And Feedback

- Follows `docs/Combat_Ability_Logic_Feedback_Agent_Instructions.md`.
- Routes every direct hit through one central damage calculator and canonical damage package.
- Uses diminishing defense with a data-driven initial soft cap of `900.0`.
- Keeps v1 damage types to physical, spell, poison, and true unless a reviewed extension is approved.
- Keeps basic attacks free and the player loadout to basic attack plus four ability slots.
- Warrior v1 includes Basic Attack, Cleave, and collision-safe Charge.
- Potion effects report success/failure and do not consume at full HP/mana.
- Uses one combat feedback owner with mobile caps.
- Does not add screen shake or hit-stop in v1.

### Sprite Handoff

- Sprite agent output updates `docs/sprite_deliverables/manifest.json`.
- Implementation verifies PNG paths exist before changing monster data.
- `monsters.json` uses manifest-backed `battle_sheet`, `codex_portrait`, affinity, weakness, resist, and description fields when available.
- Missing PNGs keep placeholders; do not invent replacement art during implementation.

### Maps And Tileset

- Map scenes follow the main plan contract: `GroundLayer`, `DecorLayer`, `CollisionLayer`, `OverlayLayer`, `EntryPoints`, `ExitTriggers`, `SpawnPoints`, `BossSpawnPoint`, `NPCs`, `Items`, and `CameraLimits`.
- Walkable ground, blockers, exits, portals, interactables, and spawn arenas are readable.
- Long-term maps do not rely on flat background images plus rectangle blockers.
- Refreshed maps do not retain the old brown-road-crossing-a-grey-field template unless explicitly recorded as migration debt.
- Tile collision must physically match the painted cell bounds; checking that a polygon merely exists is insufficient.
- TileSet custom data layer names and Variant types must match the map kit specification.
- `data/maps/maps.json` and `data/encounters/encounters.json` stay consistent with scene names and markers.
- Every registered map has `content_state`; only active maps may appear in New Game and normal travel choices.
- Active maps cannot connect to legacy/development maps.
- Portal travel lists come from `DataRegistry`; scene-local map catalogs are migration debt, not a second authority.

### Monsters

- Monster IDs and live encounter table IDs are stable unless the main plan or monster bible explicitly requires a rename.
- Monster scenes and SpriteFrames use `idle`, `move`, `attack`, `hit`, `death`, and `spawn` when those animations exist.
- Encounter tables use weights and `max_alive`.
- Conditional rare spawns stay deferred until requested.

### Skill Tree

- Warrior v1 targets the 37-node graph and ornate three-branch UI described in `docs/RPG_Skill_Tree_Agent_Guide.md`.
- The visual target is section `2.1`: bottom-center start node, red/blue/green rising branches, right detail panel, and bottom legends.
- Required count is 37 nodes: 1 free start node, 12 red offense nodes, 12 blue defense nodes, and 12 green utility nodes.
- Skill tree node positions come from JSON, not hardcoded script layout.
- Unlocks require connected-path progression, selection/confirmation, skill point cost, level/prerequisite checks, and keystone blocking.
- The detail panel shows selected node icon, description, effects, requirements, cost, and enabled/disabled unlock action.
- Save/load persists unlocked and blocked skill nodes through the existing player save flow.
- Level-up grants one skill point and the start node remains free.
- Ability unlocks use `AbilityManager`; combat modifiers feed `DamageCalculator`.
- Character remains the owner of the canonical Skills hook; placeholder local skill lists are removed after migration.
- The UI is not reduced to a plain list.
- Do not maintain two competing Warrior tree data files.

### Inventory, Equipment, Itemization, And Loot

- Follow `docs/Inventory_Equipment_Itemization_Loot_Agent_Instructions.md` in reviewed phases rather than replacing the complete system at once.
- `Inventory` remains the owned inventory/equipment authority unless an approved migration changes ownership.
- Per-item definitions stay under `data/items/`; aggregate tier/affix files use `data/itemization/`, and loot tables use `data/loot/`.
- Existing item IDs, version 1 saves, legacy equipment keys, and current callers migrate without silent item loss.
- Stack changes support limits, splitting, partial acceptance, and ground-pickup remainders.
- Equip, unequip, shop, sell, and buyback transactions are atomic.
- Generated item instances preserve IDs, rolls, affixes, rarity, and lock state through equip, drop, shop, save, and load.
- Every enabled stat or affix has a tested runtime consumer.
- Shop UI delegates transactions to `ShopManager`; it does not own a second economy implementation.
- All shop, quest, class-loadout, pickup, and loot references resolve to item definitions.
- Phase 15 top-menu navigation remains separate from Phase 9 inventory implementation.
- Inventory remains a standalone window opened through the HUD-owned coordinator; Character owns Equipment.
- Inventory migration changes only the character payload and does not take ownership of the save index or `user://settings.json`.
- Equipment combat stats feed the canonical `DamageCalculator`.
- Phase A handoffs run the architect review with `-StrictItemData`; normal runs permit only the explicitly recorded baseline debt.

## Validation

Run this before marking reviewed work ready:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tools\run_architect_review.ps1" -GodotBin "C:\Users\guyro\Desktop\RPG\Exterior sprites_Winlu\Godot_v4.3-stable_win64_console.exe"
```

For inventory/itemization Phase A approval, add `-StrictItemData`.

Expected result:

```text
All Godot validation checks passed.
Architect review checks completed.
```

This includes static architecture checks, scene load checks, 640×360 UI layout checks, custom map checks, route/quest flow checks, and review screenshots.

The architect runner executes UI layout validation twice:

- Headless configured-geometry checks for deterministic automation.
- Normal-renderer runtime checks for real font and container minimum sizes.

For UI-heavy, animation-heavy, or map-layout-heavy changes, also open the affected scenes in Godot and inspect them visually.
You can generate review screenshots with:

```powershell
& "C:\Users\guyro\Desktop\RPG\Exterior sprites_Winlu\Godot_v4.3-stable_win64_console.exe" --path . --script "res://tools/capture_review_screenshots.gd"
```

This requires the normal renderer, not `--headless`, and writes ignored files under `review_artifacts/screenshots/`.

Use `-SkipScreenshots` on `run_architect_review.ps1` when only code/data validation is needed.

## Review Outcome

Use one of these outcomes:

- **Ready to integrate:** passes source-of-truth, architecture, role-specific, and validation gates.
- **Partially integrate:** compatible work is safe; conflicting or speculative parts stay on hold.
- **Hold:** conflicts with the main plan, breaks validation, rewrites unrelated systems, or depends on missing assets.

Keep suggestions that are not required for the current phase on hold instead of stopping other compatible work.
