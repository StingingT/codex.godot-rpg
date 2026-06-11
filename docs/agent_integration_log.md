# Agent Integration Log

Use this log to track reviewed agent work, integration decisions, holds, and validation evidence.

The main source of truth remains `Main_ChatGPT-Godot_RPG_Implementation_Plan.md`. This log records architect decisions; it does not override the main plan or domain docs.

## Status Labels

- **Ready:** reviewed against the main plan, passes required validation, and can be integrated.
- **Partial:** compatible pieces are safe; conflicting or speculative pieces stay held.
- **Hold:** do not integrate until the listed issue is resolved.
- **Pending:** not reviewed yet.

## Current Queue

| Date | Work | Agent role | Status | Notes |
|------|------|------------|--------|-------|
| 2026-06-04 | Architect review workflow docs and validation gates | Architect | Ready | Added checklist, handoff template, static architecture gate, and validation wiring. |
| 2026-06-04 | GDScript parse validation gate | Architect | Ready | `validate_architecture.gd` now loads `.gd` files under `scripts`, `scenes`, and `tools`. |
| 2026-06-04 | Review screenshot capture tool | Architect | Ready | Generates UI/map screenshots under ignored `review_artifacts/screenshots/`; UI captures use the real 640×360 logical viewport. |
| 2026-06-04 | One-command architect review runner | Architect | Ready | Runs full validation and screenshot capture from one PowerShell entry point. |
| 2026-06-04 | Master plan architect review loop and validator reference gate | Architect | Ready | Main plan now lists handoff, review checklist, and integration log; architecture validation enforces those references. |
| 2026-06-04 | Monster locomotion animation normalization | Implementation | Ready | Changed monster `walk` locomotion to `move` in scripts and monster scenes. |
| 2026-06-04 | Main/domain specification expansion | Architect / mixed | Ready | Main plan now points to active domain docs and role routing. |
| 2026-06-05 | Non-skill-tree UI integration | UI / architect | Ready | Title, HUD, character, inventory, quest, shop, map selector, dialogue, and death layouts pass the 640×360 headless and normal-renderer gates; skill tree and mobile integration remain separate holds. |
| 2026-06-04 | Custom tileset, object, and map asset package | Maps / tileset | Ready | Static/map validation passes and route screenshots were inspected for town, field, ruins, marsh, catacombs, and dark keep. |
| 2026-06-04 | Full Warrior 37-node skill tree UI implementation | Skill tree / implementation | Hold | Existing compact/list-style skill tree UI does not satisfy `docs/RPG_Skill_Tree_Agent_Guide.md` section 2.1 or the 37-node connected graph target. |
| 2026-06-05 | Monster sprite delivery and runtime integration | Sprite / implementation | Ready | Six battle sheets, six codex portraits, affinity icons, generated SpriteFrames, manifest-backed monster data, and runtime visual wiring pass validation. |
| 2026-06-05 | Runtime monster gameplay-scale screenshot gate | Architect | Ready | Review capture now instantiates all six real monster scenes with registry IDs and 32px scale markers. |
| 2026-06-05 | Custom TileSet metadata and collision alignment correction | Maps / architect | Ready | Fixed half-tile-shifted collision polygons and added physical bounds, metadata type, tile size, and collision-layer validation. |
| 2026-06-05 | Inventory, equipment, itemization, loot, and economy domain specification | Inventory / architect | Ready | Approved as phased design direction; aggregate data paths corrected, current reference debt documented, and Phase 15 top-menu navigation held separately. |
| 2026-06-06 | Inventory/itemization migration Phase A | Inventory / architect | Ready | Canonical item/shop normalization, aggregate tier/affix/loot data, and all active item references pass the strict architect gate. |
| 2026-06-07 | Content overlap and legacy-map audit | Architect | Ready | Custom route is now the active/default route; legacy maps and quests are lifecycle-labeled, travel ownership is centralized, and regression validation is wired. |
| 2026-06-07 | Inventory/itemization migration Phase B | Inventory | Pending | Concurrent implementation detected and its focused validator passes; requires a separate architect review and handoff audit before approval. |
| 2026-06-11 | Umbral Explorers master-plan integration | Architect | Ready | Registered lore, menu, and combat domain specs; locked project identity, tone, combat/save/menu contracts, phase ownership, migration holds, and validation guards. Gameplay implementation remains held to its owning reviewed phases. |

## Ready To Integrate

### 2026-06-04 - Architect Review Workflow

Files:

```text
res://docs/architect_review_checklist.md
res://docs/agent_handoff_template.md
res://docs/agent_integration_log.md
res://tools/validate_architecture.gd
res://tools/validate_all.ps1
res://project.godot
```

Decision: Ready.

Evidence:

```text
All Godot validation checks passed.
```

Notes:

- Review order is main plan, domain docs, current project state, then agent notes.
- Validation now includes static architecture checks before scene/map checks.
- `project.godot` now includes `window/stretch/aspect="keep"` as required by the main plan.

### 2026-06-04 - Monster Locomotion Animation Normalization

Files:

```text
res://scripts/monsters/monster_base.gd
res://scripts/monsters/goblin_archer.gd
res://scenes/monsters/bat.tscn
res://scenes/monsters/dark_knight.tscn
res://scenes/monsters/monster_base.tscn
res://scenes/monsters/skeleton.tscn
res://scenes/monsters/swamp_monster.tscn
```

Decision: Ready.

Evidence:

```text
No remaining monster script or monster scene references to locomotion animation "walk".
All Godot validation checks passed.
```

Notes:

- This matches the main plan and monster bible rule that monster locomotion uses `move`.
- Player `walk_*` animations remain allowed and unchanged.

### 2026-06-04 - GDScript Parse Validation Gate

Files:

```text
res://tools/validate_architecture.gd
```

Decision: Ready.

Evidence:

```text
Architecture validator passes.
All Godot validation checks passed.
```

Notes:

- The architecture validator now loads every `.gd` under `res://scripts`, `res://scenes`, and `res://tools`.
- This catches script parse errors in maintenance tools and scene-local scripts instead of relying on Godot import output.

### 2026-06-04 - Review Screenshot Capture Tool

Files:

```text
res://tools/capture_review_screenshots.gd
res://.gitignore
```

Decision: Ready.

Evidence:

```text
Generated screenshots for UI and custom route maps with the normal renderer.
All Godot validation checks passed.
```

Notes:

- Screenshot artifacts are ignored under `review_artifacts/screenshots/`.
- The tool covers title, HUD, character, inventory, quest book, shop, skill tree, the full custom route map set, and a runtime monster scale gallery.

### 2026-06-04 - One-Command Architect Review Runner

Files:

```text
res://tools/run_architect_review.ps1
res://docs/architect_review_checklist.md
```

Decision: Ready.

Evidence:

```text
All Godot validation checks passed.
Architect review checks completed.
```

Notes:

- Runs `validate_all.ps1` first.
- Captures review screenshots with the normal renderer unless `-SkipScreenshots` is passed.
- Uses the same Godot binary resolution pattern as the validation script.

### 2026-06-04 - Master Plan Architect Review Loop And Validator Reference Gate

Files:

```text
res://Main_ChatGPT-Godot_RPG_Implementation_Plan.md
res://tools/validate_architecture.gd
res://docs/agent_integration_log.md
```

Decision: Ready.

Evidence:

```text
All Godot validation checks passed.
Architect review checks completed.
```

Notes:

- Main plan agent rules now require architect review before integration.
- Active documentation index now lists the review checklist, handoff template, and integration log.
- Multi-agent workflow now includes the architect role.
- Architecture validation now fails if the main plan drops those review workflow references.

### 2026-06-04 - Main And Domain Specification Expansion

Files:

```text
res://Main_ChatGPT-Godot_RPG_Implementation_Plan.md
res://docs/agent_skills_required.md
res://docs/custom_tileset_object_kit_instructions.md
res://docs/monster_design_bible.md
res://docs/external_sprite_agent_instructions.md
res://docs/external_sprite_agent_skills.md
res://docs/RPG_Skill_Tree_Agent_Guide.md
res://docs/sprite_deliverables/manifest.json
res://.cursor/skills/monster-sprite-agent/SKILL.md
```

Decision: Ready as source-of-truth / routing documentation.

Evidence:

```text
Static architecture gate passes.
Full validation passes.
Source scan found real-time combat and TileMapLayer rules preserved.
```

Notes:

- Main plan remains the architecture and phase source of truth.
- Domain docs are explicitly scoped to maps, monsters, sprite production, and skill tree work.
- Sprite agent rules correctly separate art production from Godot implementation wiring.

### 2026-06-05 - Monster Sprite Delivery And Runtime Integration

Files include:

```text
res://assets/sprites/monsters/battle/
res://assets/sprites/monsters/codex/
res://assets/sprites/monsters/icons/
res://assets/sprites/monsters/*_frames.tres
res://data/monsters/monsters.json
res://scripts/monsters/monster_base.gd
res://tools/build_monster_spriteframes.gd
res://tools/validate_monster_sprite_delivery.gd
res://tools/validate_all.ps1
res://docs/sprite_deliverables/manifest.json
```

Decision: Ready.

Evidence:

```text
All six battle sheets match their manifest frame grid and animation row count.
All six codex portraits and nine affinity icons match allowed dimensions.
Visual contact-sheet review found readable silhouettes and matching battle/codex identities.
All six runtime monster instances apply their manifest-backed SpriteFrames.
All Godot validation checks passed.
```

Notes:

- `monsters.json` now contains manifest-backed family, size, affinity, sprite, SpriteFrames, portrait, codex, weakness, and resist fields while preserving combat stats and IDs.
- SpriteFrames are generated repeatably from manifest row order with four frames per animation.
- Generic manually placed `slime` monsters use the green slime data; encounter-spawned `slime_blue` uses its own frames through the existing shared base scene.
- Existing encounter tables and monster scene paths remain unchanged.
- Runtime gallery review confirms the small, normal, elite, and boss silhouettes remain readable against 32px tile scale.
- Monster Codex menu implementation remains future UI work; the reviewed portrait data is now ready for it.

### 2026-06-05 - Runtime Monster Gameplay-Scale Screenshot Gate

Files:

```text
res://tools/capture_review_screenshots.gd
```

Decision: Ready.

Evidence:

```text
Generated review_artifacts/screenshots/monster_runtime_gallery.png.
All six real monster scenes applied their manifest-backed SpriteFrames.
Small monsters remain below one tile high; elite and boss sizes preserve the intended hierarchy.
```

Notes:

- The gallery uses the same scene and `monster_type` path as runtime spawning.
- Four 32px reference cells make scale regressions visible during future art reviews.

### 2026-06-05 - Custom TileSet Metadata And Collision Alignment Correction

Files:

```text
res://assets/tilesets/custom/rpg_tileset.tres
res://tools/apply_custom_tileset_metadata.gd
res://tools/validate_custom_maps.gd
```

Decision: Ready after correction.

Evidence:

```text
Physics probe showed the old 0..32 polygon coordinates shifted collision half a tile.
Blocking polygons now use centered -16..16 coordinates for 32px tiles.
Targeted custom map validation passes.
All Godot validation checks passed.
```

Notes:

- Validation now proves collision covers points inside the painted tile and does not extend into adjacent cells.
- Validation also checks 32px tile size, World collision layer 2, custom data layer names and types, atlas dimensions, tile metadata, blockers, and passable transitions.
- The missing-object-atlas error path no longer dereferences a null atlas while reporting the failure.

### 2026-06-04 - Custom Tileset, Object, And Map Asset Package

Files include:

```text
res://assets/tilesets/custom/
res://assets/objects/
res://scenes/maps/custom_kit_town.tscn
res://scenes/maps/custom_kit_field.tscn
res://scenes/maps/custom_kit_ruins.tscn
res://scenes/maps/custom_kit_marsh.tscn
res://scenes/maps/custom_kit_catacombs.tscn
res://scenes/maps/custom_kit_dark_keep.tscn
res://scripts/world/custom_kit_test_map_builder.gd
res://tools/apply_custom_tileset_metadata.gd
res://tools/generate_custom_style_assets.py
```

Decision: Ready for prototype custom-route integration.

Evidence:

```text
Static architecture and custom map validation pass.
Full validation passes.
Visual screenshots inspected for all six custom route maps.
```

Notes:

- Maps follow the `TileMapLayer` scene contract and are no longer flat-background-only maps.
- Paths, blockers, portals, NPCs, and interactables are readable at gameplay zoom.
- Tile collision is physically aligned to painted 32px cells and guarded by runtime physics queries.
- Art remains prototype-grade; future polish can deepen the dark PoE material language without blocking this integration.

## Additional Ready Integrations

### 2026-06-11 - Umbral Explorers Master-Plan Integration

Status: Ready as documentation, ownership, and validation direction.

Files:

```text
res://Main_ChatGPT-Godot_RPG_Implementation_Plan.md
res://docs/Grimvale_Lore_World_Tone_Foundation.md
res://docs/Menu_Game_Flow_Settings_Agent_Instructions.md
res://docs/Combat_Ability_Logic_Feedback_Agent_Instructions.md
res://docs/architect_review_checklist.md
res://docs/agent_integration_log.md
res://tools/validate_architecture.gd
res://AGENTS.md
```

Decision:

- The written project title is `Umbral Explorers: Relics of Grimvale`; title artwork displays it on two lines.
- Heroic mystery and bright blue/gold guild identity contrast with darker readable Umbral-touched regions.
- Warrior is the only playable v1 class; Ranger and Mage remain visible as `Coming Later`.
- V1 persistence targets one character-ID autosave plus `index.json`, migration from `slot_1.json`, and independent `user://settings.json`.
- Phase 15 owns the HUD menu coordinator, canonical screen navigation, pause/settings, and death flow.
- Combat migration targets one damage calculator, one damage package, one feedback owner, diminishing defense, and no screen shake or hit-stop in v1.

Notes:

- This approval changes documentation and validation guards only.
- Current gameplay/UI/save/combat conflicts remain implementation holds and must be resolved by separate reviewed handoffs.
- The supplied title-screen image is visual direction only and is not a shipping asset.

Evidence:

```text
All Godot validation checks passed.
Normal-renderer UI layout validation passed.
Architect review checks completed.
```

### 2026-06-05 - Inventory, Equipment, Itemization, Loot, And Economy Domain Specification

Status: Ready as canonical phased design direction. Phase A is approved separately below.

Files:

```text
res://docs/Inventory_Equipment_Itemization_Loot_Agent_Instructions.md
res://Main_ChatGPT-Godot_RPG_Implementation_Plan.md
res://docs/architect_review_checklist.md
res://tools/validate_architecture.gd
```

Evidence:

```text
The proposal extends the existing Inventory, DataRegistry, SaveManager, ShopManager, pickup, and player-equipment paths.
The initial reference audit found 17 unresolved item IDs across shops, quest rewards, collect objectives, and class starting loadouts.
The specification identifies all 17 historical IDs and requires strict regression validation.
All Godot validation checks passed.
Architect review checks completed.
```

Notes:

- Phase A is now approved; implement Phases B-F as separate reviewed handoffs.
- Keep per-item JSON under `data/items/`; use `data/itemization/` for tier/affix tables and `data/loot/` for loot tables.
- The current folder loader would otherwise register aggregate JSON as fake items.
- Pity weights, rarity weights, prices, and roll ranges are initial data defaults, not immutable architecture.
- No Phase B-F save format or public API change is Ready until its implementation, migration tests, and handoff pass review.

### 2026-06-06 - Inventory/Itemization Migration Phase A

Status: Ready after architect correction.

Files include:

```text
res://scripts/autoload/data_registry.gd
res://scripts/autoload/shop_manager.gd
res://scripts/inventory/item_data.gd
res://scripts/npcs/shop_npc.gd
res://data/items/
res://data/itemization/
res://data/loot/
res://data/shops/
res://data/quests/cave_exploration.json
res://tools/validate_item_data.gd
res://tools/validate_all.ps1
res://docs/inventory_phase_a_handoff.md
```

Evidence:

```text
Strict item validation passed: 21 items, 3 shops.
All active shop, quest, class-loadout, pickup, and loot-table references resolve.
All Godot validation checks passed.
Normal-renderer UI layout validation passed.
Architect review checks completed.
```

Notes:

- Architect corrections removed unsafe iron-to-steel aliases, restored exact item identity, enforced singular category IDs and static `ring` definitions, and derived starter references from `PlayerClass`.
- The 17 historical unresolved references were resolved by adding canonical definitions, removing inactive shop entries, or changing the active cave reward to `steel_sword`.
- Sixteen missing final icon paths remain explicitly non-blocking because icon production is deferred by the canonical Phase A specification.
- `healing_herb` and `herb_healing` remain distinct valid quest IDs; consolidation is optional follow-up work and must include quest/save migration if attempted.
- Phases B-F remain pending separate handoffs.

### 2026-06-05 - Non-Skill-Tree UI Integration

Status: Ready.

Files include:

```text
res://scripts/ui/rpg_ui_style.gd
res://scripts/ui/character_screen.gd
res://scripts/ui/hud.gd
res://scripts/ui/inventory_ui.gd
res://scripts/ui/map_selector.gd
res://scripts/ui/quest_book.gd
res://scripts/ui/shop_ui.gd
res://scripts/ui/skill_tree_ui.gd
res://scripts/ui/title_screen.gd
res://scenes/ui/character_screen.tscn
res://scenes/ui/dialogue_box.tscn
res://scenes/ui/title_screen.tscn
```

Reason:

- Godot validation passes at the required 640×360 logical viewport with both headless configured-layout checks and normal-renderer runtime geometry checks.
- The shared UI style helper is additive.
- Title class selection, character tabs, standalone inventory, HUD, quest, shop, map selector, dialogue, and death screens stay within the project viewport.
- HUD shortcuts use the canonical `open_inventory`, `open_skill_tree`, and `pause` actions from the main plan.
- Unwired duplicate HUD mobile controls were removed; the separate functional `touch_controls.tscn` remains the mobile source for later integration.
- `skill_tree_ui` remains a styled compact/list-style implementation and does not satisfy the full Warrior 37-node ornate skill tree target.
- Treat the non-skill-tree desktop UI package as compatible and ready; keep the Warrior skill tree and mobile-control scene integration on their dedicated holds.

## Holds

### 2026-06-07 - Legacy Content And Runtime-Painted Map Migration

Status: Hold.

Current state:

- Six active custom-route maps use the current custom TileSet and pass map validation, but still paint their cells at runtime through `custom_kit_test_map_builder.gd`.
- Ten old registered maps are now `legacy`; six use flat background images and four use the placeholder tileset.
- `test_map` is development-only.
- Four active quests overlap older quest objectives, four legacy quests target missing monster IDs, and six groups of Winlu source assets are byte-identical.

Release criteria:

- Bake active route tile data into hand-authored `.tscn` scenes and remove the runtime test builder.
- Migrate or retire legacy maps without invalidating existing saves.
- Consolidate legacy quests and assets only after ID/path migration is explicit.
- See `docs/content_overlap_audit.md` for the exact inventory.

### 2026-06-04 - Full Warrior 37-Node Skill Tree UI Implementation

Status: Hold.

Current state:

- Existing `skill_tree_ui` style work is compatible as general UI polish, but it remains a compact/list-style implementation.
- It does not yet meet the required ornate Warrior skill tree target from `docs/RPG_Skill_Tree_Agent_Guide.md` section 2.1.

Release criteria:

- Warrior tree contains 37 nodes: 1 free start node, 12 red offense nodes, 12 blue defense nodes, and 12 green utility nodes.
- UI uses the required layout: bottom-center start node, three rising branches, branch-colored connection lines, right-side detail panel, and bottom node/stat legends.
- Node positions and connections are JSON-driven, not hardcoded as a script-only layout.
- Unlock logic requires connected-path progression, explicit selection/confirmation, skill point cost, level/prerequisite checks, and keystone blocking.
- Detail panel shows selected node icon, description, effects, requirements, cost, and a disabled/enabled green unlock action.
- Save/load persists unlocked and blocked skill nodes through the existing player save flow.
- There is one Warrior skill tree source of truth; do not maintain duplicate competing tree data files.
- Existing player, HUD, ability, inventory, and save systems are patched additively, not replaced.

### 2026-06-05 - Mobile Touch-Control Scene Integration

Status: Hold.

Current state:

- `res://scenes/ui/touch_controls.tscn` and `res://scripts/ui/touch_controls.gd` provide functional touch input injection.
- The scene is not yet instantiated by the active HUD or map flow.
- Desktop HUD placeholders were removed because they emitted unconsumed signals and had invalid viewport geometry.

Release criteria:

- Instantiate the touch-control scene only for touch/mobile targets.
- Confirm gameplay actions, joystick movement, pause behavior, and menu shortcuts work without duplicating desktop HUD controls.
- Run the 640×360 layout gate and mobile scaling review from Phase 14 of the main plan.

### 2026-06-05 - Shared Top Menu Navigation

Status: Hold.

Current state:

- The approved menu domain specification now defines Quests, Character, Inventory, and Settings under one HUD-owned modal coordinator.
- Main MD Phase 9 still owns inventory/equipment data and behavior; Phase 15 owns shared navigation.
- Existing HUD shortcuts, direct pause toggle, duplicate Character inventory/skill UI, and NPC-only quest book remain migration debt.

Release criteria:

- Implement through the reviewed Phase 15A-D sequence.
- Reuse existing screens and canonical input actions instead of creating duplicate UI state.
- Keep Inventory standalone, Character focused on Equipment plus the canonical Skill Tree hook, and the global Quest Journal separate from NPC quest interaction.
- Pass desktop and 640x360 navigation, pause ownership, and layout checks.

### 2026-06-11 - Combat, Save, Death, And Flow Contract Migration

Status: Hold.

Current state:

- Damage and feedback are produced through multiple hitbox, hurtbox, status, monster, and effect-helper paths.
- Ability data still contains prototype damage types and deferred effect behaviors.
- Saves still use `slot_1.json`; settings have no independent owner.
- Title/death flow hardcodes map destinations, and player death currently removes gold.

Release criteria:

- Route all direct damage through the reviewed central calculator/package and one feedback owner.
- Migrate prototype types/effects without silently changing active content behavior.
- Implement character-ID autosave/index migration with atomic writes and independent settings persistence.
- Resolve start/respawn through game-flow/map metadata.
- Remove v1 death penalties and validate repeatable-area reset while preserving quest/permanent progress.

### 2026-06-06 - Final Item Icon Assets

Status: Hold.

Current state:

- Sixteen Phase A definitions intentionally have no final icon path.
- The item icon style guide defers final asset production from the first implementation pass.

Release criteria:

- Deliver readable inventory icons using the canonical item icon style.
- Add valid icon paths to definitions and remove the documented strict-validation exception.

### 2026-06-11 - Master Plan And Agent Instruction Alignment

Status: Ready to integrate.

Integrated:

- Established `Umbral Explorers: Relics of Grimvale` across all active agent-facing Markdown guides.
- Locked heroic-mystery tone, bright blue/gold guild identity, and darker readable Umbral regions.
- Aligned menu, save/settings, combat, inventory, skill-tree, map, monster, sprite, lore, handoff, routing, and architect-review contracts with the master plan.
- Added deterministic validation for required cross-document rules and stale-contract exclusions.
- Preserved historical handoffs, prior review outcomes, and existing migration holds without rewriting past evidence.

Validation:

- `tools/validate_architecture.gd`: passed.
- Full `tools/run_architect_review.ps1`: passed, including normal-renderer UI checks and review screenshots.
- Existing non-blocking warnings remain recorded migration debt: active/legacy quest overlaps, runtime-painted custom maps, unresolved legacy quest targets, ignored legacy map catalogs, and duplicate source assets.

## Pending Review

- Full Warrior 37-node skill tree UI implementation.
- Mobile touch-control scene integration.
- Inventory/itemization implementation Phases B-F, each as a separate handoff.

## Validation Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tools\run_architect_review.ps1" -GodotBin "C:\Users\guyro\Desktop\RPG\Exterior sprites_Winlu\Godot_v4.3-stable_win64_console.exe"
```
