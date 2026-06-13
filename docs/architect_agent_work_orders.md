# Architect Agent Work Orders

**Project:** Umbral Explorers: Relics of Grimvale
**Authority:** Main plan phase order and locked architecture rules
**Last audit:** 2026-06-13

This register is the architect-controlled queue for agent work. Domain guides define the required end state; this file defines the current objective, file ownership, dependencies, and review status.

## Mandatory Routing

Every agent follows this sequence:

1. Read the main plan, the assigned domain guide, and the applicable work order below.
2. Send the architect a pre-implementation update listing intended files, dependencies, assumptions, and validation.
3. Wait for the architect to confirm scope and shared-file ownership before editing.
4. Implement only the approved scope. Do not merge, commit, push, or hand work to another agent.
5. Submit `docs/agent_handoff_template.md` plus validation evidence to the architect.
6. Continue only after the architect records **Ready** or issues a correction order.

Unreviewed work is a submission, not an integrated project decision.

## Shared-File Ownership

| File or boundary | Current owner | Other agents |
|---|---|---|
| `project.godot` autoloads and input actions | Architect | Propose changes in handoff only |
| `scripts/autoload/save_manager.gd` and save schema | Phase 14 save/menu agent | Inventory and skill agents provide payload APIs only |
| `scripts/player/player_controller.gd`, `scripts/components/stats_component.gd` | Combat agent | Skill/inventory agents request public hooks |
| `scripts/autoload/ability_manager.gd`, combat router/hurtboxes | Combat agent | Monster/skill agents consume reviewed APIs |
| `scripts/ui/hud.gd`, `scripts/ui/character_screen.gd` | Phase 15 menu agent | Inventory/skill agents own their standalone screens |
| Active map scenes, TileSet, map builder | Maps agent | Content agents may propose names/data only |
| Monster PNGs and sprite manifest art fields | Sprite agent | Implementation agents do not redraw |
| Monster scenes/data/encounter behavior | Monster implementation agent | Sprite agent does not edit runtime files |

If a task needs another owner's file, stop at an interface proposal and send it to the architect.

## Current Review Decisions

| Submission | Decision | Reason |
|---|---|---|
| Inventory Phase A | Ready | Canonical data normalization and strict reference validation passed |
| Inventory Phase B | Hold | The interrupted remediation added useful safety work and its focused validator passes, but shared Character/Save changes need separation and no final handoff was submitted |
| Custom object kit and directional dungeon tiles | Partial | Six maps now contain serialized cells, but the active scenes serialize scene-local travel catalogs and Dark Keep's town portal is blocked at `(0, 0)` |
| Ground-variation quality submission | Partial | New ground variants may be reusable, but placing them through the runtime builder increases prototype ownership and is held |
| Monster sprite package | Partial | Runtime paths and dimensions are usable; manifest approval states and several animation-quality issues remain unresolved |
| Monster gameplay integration | Hold | Damage/feedback, movement data, encounter weights, and boss caps do not meet the master combat contract |
| Warrior skill-tree submission | Hold | Shared combat/save/player files were changed before their owning phases; Character/skill stores still overlap; current validation and dependency gates remain unresolved |
| Menu/save/death submission | Hold | Phase 14 character-ID/index/atomic persistence is not implemented; title, class gating, settings, and death behavior remain incompatible |
| Combat/Warrior ability submission | Hold | No integrated canonical `DamageCalculator` or feedback owner; ability work is mixed into player and skill-tree changes |

## Execution Order

1. Low-conflict remediation may run in parallel: Inventory B, map serialization, and sprite art corrections.
2. Combat foundation establishes damage, ability, and feedback interfaces.
3. Phase 14 save establishes character autosave/index/settings ownership.
4. Monster runtime and skill-tree integration consume the reviewed combat/save interfaces.
5. Phase 15 menu flow consumes the reviewed save interfaces and canonical standalone screens.
6. Lore/content naming migrations happen only with explicit ID, save, portal, and test migrations.

## WO-INV-B1 - Inventory Phase B Remediation

**Status:** Interrupted partial implementation under architect review; correction handoff required.

**Objective:** Make Phase B genuinely atomic and compatible before Phase C begins.

**Owned files:** `scripts/inventory/`, standalone inventory UI, inventory payload helpers, focused inventory validators, and the Phase B handoff.

**Do not edit:** save index/version ownership, settings, HUD coordinator, Character skills, combat formulas, loot/affix/pity, Ranger/Mage, or unrelated map/monster files.

**Required corrections:**

- Replacing equipment while inventory is full cannot delete the displaced item.
- A failed inventory payload load must be detected and preserve the prior inventory.
- Health/mana potions at full resources must report failure and remain unconsumed.
- Quest-only items cannot be sold or dropped.
- Render the specified 4-column by 6-row tab layout at 640x360.
- Delegate shop transactions to `ShopManager`; remove the second UI-owned transaction path.
- Extend migration tests to all legacy equipment keys and full-inventory replacement rollback.
- Do not edit Character to resolve its duplicate Inventory/Skills tabs. Record the overlap and expose any required standalone Inventory API; Phase 15 owns removal from the Character shell.
- Submit a completed handoff that distinguishes implemented behavior from unverified assumptions.

**Evidence:** focused tests for every correction, 640x360 screenshot, strict item-data validation, full architect validation, and updated Phase B handoff.

**Current review:** The focused Phase B validator passes and the staged equip/load/potion/quest-item changes are promising. Integration remains held because the agent stopped before final evidence and changed shared Character/Save files that require separation or explicit interface review. The duplicate Character tabs remain a Phase 15 hold, not Inventory ownership.

## WO-MAP-A1 - Serialize Active Maps And Exits

**Status:** Correction required after interrupted serialization pass.

**Objective:** Convert all six active custom maps from runtime-painted prototypes to hand-authored serialized `TileMapLayer` scenes while preserving accepted object-kit and dungeon-edge assets.

**Owned files:** active custom map scenes, custom TileSet/atlas resources, map builder retirement path, map validators, and map handoffs.

**Do not edit:** save/autoloads, UI, combat, quests, encounters, monster IDs, map IDs, entry IDs, or legacy-map removal.

**Required corrections:**

- Serialize meaningful cell data into every active map scene and remove runtime builder ownership.
- Preserve useful ground-variation tiles, but place them in serialized scene data; do not continue polishing runtime builder placement.
- Make dungeon transitions visible physical exits with populated `ExitTriggers`.
- Choose one collision authority per blocker; remove duplicate TileSet/manual collision.
- Keep spawn, portal, boss, and entry areas walkable and non-overlapping.
- Record unfinished Phase 20 ambience/reward/content hooks as holds instead of fabricating gameplay data.
- Correct tile metadata so biome/tier values describe their actual use.
- Remove serialized `available_maps` arrays from every active portal; `DataRegistry` remains the only normal-travel catalog authority.
- Restore the Dark Keep town portal to its intended serialized position and prove that it and every other transition are outside collision/decor blockers.
- Remove temporary diagnostic scripts from the handoff, or make retained tools parse cleanly and wire them into an owned validator.
- Re-run serialization from a clean reviewed source and inspect the resulting scene diff for unintended broad churn.

**Evidence:** serialized cell counts, zero entry/exit collision overlaps, active-map screenshots, map/content validators, full architect validation, and an updated map handoff.

**Current review:** All six active scenes report non-zero serialized ground/decor/collision cells. The package remains held because `available_maps = Array[Dictionary]([])` is present in active scenes, `Portals/TownPortal` in Dark Keep serialized at the default origin and fails collision validation, `tools/diagnose_field_spawn.gd` does not parse, and no final map-serialization handoff was submitted.

## WO-SPR-A1 - Monster Sprite Quality Corrections

**Status:** Blocked twice by worker sandbox refresh failure; no approved files changed.

**Objective:** Resolve final-art quality holds without changing runtime code.

**Owned files:** monster battle-sheet/codex PNGs, review artifacts, and art-review fields in `docs/sprite_deliverables/manifest.json`.

**Do not edit:** `.gd`, `.tscn`, `.tres`, `monsters.json`, encounters, stats, or runtime scale.

**Required corrections:**

- Supply genuine Dark Knight movement frames rather than idle duplicates.
- Replace duplicate Skeleton animation frames with intentional motion.
- Apply scale corrections manually per sheet; do not use uniform destructive trim/resize automation.
- Keep each monster's core body scale stable while allowing attack, hit, death, spawn, and effects to extend.
- Leave review status pending until architect visual inspection.

**Evidence:** before/after contact sheets, per-row uniqueness checks, scale measurements, updated manifest, and a complete sprite handoff.

## WO-COM-F1 - Canonical Combat Foundation

**Status:** Corrected pre-implementation contract accepted; implementation not yet authorized.

**Objective:** Establish the master-plan combat interfaces before Warrior abilities, monsters, or skill modifiers continue.

**Owned files:** combat calculator/package, balance data, effect router, hitbox/hurtbox integration, AbilityManager combat contracts, and combat validators.

**Do not edit:** save schema, menu/HUD navigation, skill-tree graph/UI, monster art, map content, or inventory ownership.

**Required implementation:**

- One scene-independent `DamageCalculator` and one canonical damage package.
- Diminishing defense with data-driven `defense_softcap = 900.0`.
- Runtime types `physical`, `spell`, `poison`, and `true`; migrate prototype type aliases.
- One feedback owner with mobile caps; remove direct number/effect spawning from hitboxes, hurtboxes, monsters, and DoT helpers.
- Free Basic Attack plus four ability slots.
- Warrior Basic Attack, Cleave, and collision-safe Charge using reviewed ability data and success/failure cost commitment.
- Potion success/failure contract and combat-state query for Return to Town.
- No screen shake or hit-stop.

**Architect corrections before implementation:**

- Treat the canonical damage package field contract from the main plan as mandatory even if implemented as a typed `RefCounted`.
- Keep `DamageCalculator` scene-independent and stateless. Keep feedback and combat-state ownership scene-scoped unless a later reviewed need proves an autoload is required.
- Store damage variance, combat-exit grace, feedback caps, and defense soft cap in reviewed balance data instead of hardcoding them.
- DoT cannot crit and may bypass per-hit invulnerability only through an explicit package flag; do not create a second damage path.
- Damage floors are required. Do not add an unexplained maximum-damage clamp.
- Do not edit save, skill-tree, menu, map, or sprite-owned files. Any necessary shared-file change must return as an interface request.

**Evidence:** unit tests for ranges, crits, mitigation, floor, true damage, aliases, costs, potion non-consumption, Charge collision, and feedback caps.

**Accepted preflight contract:** Typed `DamageRequest`/`DamagePackage`, injected stateless calculator rules and RNG, one canonical DoT path with explicit invincibility bypass, scene-scoped feedback/state owners, data-driven variance/grace/caps/soft cap, no maximum-damage clamp, free Basic Attack outside four ability slots, and success-based Cleave/Charge cost commitment. `monster_base.gd` is limited to duplicate-feedback removal and combat engagement. Shared validator wiring remains architect-applied.

## WO-MON-R1 - Monster Runtime Contract

**Status:** Blocked by WO-COM-F1.

**Objective:** Move monsters onto reviewed combat and encounter contracts without changing stable IDs or art.

**Owned files:** monster runtime scripts/scenes, monster data consumers, encounter spawning logic, and monster validators.

**Required corrections:**

- Route all monster damage and feedback through the combat foundation.
- Consume `move_speed` and attack timing from data.
- Honor encounter weights and `max_alive`; prevent duplicate/unconditional boss spawns.
- Use available `spawn` and `hit` states.
- Expand validation for stable IDs/order, frame dimensions, scale, alpha bounds, unique frames, and elite/boss rows.

## WO-SAV-14 - Character Autosave And Settings Boundary

**Status:** Corrected pre-implementation contract accepted; implementation not yet authorized.

**Objective:** Replace slot persistence with the approved one-character autosave, index, atomic-write, and migration architecture.

**Owned files:** SaveManager, new SettingsManager, `data/game_flow.json`, save/settings validators, and Phase 14 handoff.

**Do not edit:** combat formulas, inventory transactions, skill-tree behavior, map layout, or menu presentation beyond public persistence APIs.

**Required implementation:**

- `user://saves/index.json` plus character-ID autosave metadata and last-played selection.
- Atomic temp-write/replace behavior and corrupt-save fallback.
- Backward migration from `user://saves/slot_1.json`.
- Separate `user://settings.json` through `SettingsManager`.
- Payload adapters for inventory and skill tree without giving those domains save-file ownership.
- Metadata-driven start and respawn targets.

**Architect corrections before implementation:**

- Use distinct schema names for the new character envelope and legacy slot migration so version numbers cannot be confused.
- The atomic store must explicitly handle an existing destination and backup on Windows; do not assume a rename silently overwrites.
- Derive autosave paths from validated character IDs instead of trusting a persisted path.
- Preserve legacy Ranger/Mage saves, but reject those classes only during new-character creation.
- The save agent owns `SaveManager`, `SettingsManager`, `AtomicJsonStore`, `data/game_flow.json`, and a focused Phase 14 validator. Changes to `project.godot`, `validate_all.ps1`, and architect guards are proposals for the architect to apply.
- Settings persistence belongs to Phase 14; Phase 15 owns only settings UI and navigation.

**Accepted preflight contract:** Independent `CHARACTER_SAVE_VERSION`, `SAVE_INDEX_VERSION`, `SETTINGS_VERSION`, and legacy-slot limits; validated `char_0001`-style IDs with internally derived paths; opaque boolean-validated inventory/skill payloads; Ranger/Mage legacy preservation with Warrior-only creation; same-directory temp/backup/replacement recovery; index reconstruction; and an explicit migration/rollback matrix. The agent may edit only the owned files listed above after authorization. Architect applies autoload and shared-validator wiring.

## WO-SKL-W1 - Warrior Skill Tree Rebase

**Status:** Hold until WO-COM-F1 and WO-SAV-14 publish interfaces.

The current `docs/skill_tree_handoff.md` is rejected as an integration claim. `WO-SKL-W1` was not approved for implementation, `EffectRouter` is not the required `DamageCalculator`, and save version 3 is not a substitute for Phase 14 character-ID/index/settings architecture. `SKILL_TREE_IMPLEMENTATION_NOTES.md` is non-canonical and must not override this work order.

**Objective:** Keep the valid 37-node JSON graph, then complete the canonical connected tree UI without owning combat, player stats, or save architecture.

**Owned files:** `data/skilltrees/warrior_skill_tree.json`, SkillTreeManager after architect approval, standalone skill-tree UI/scene, skill-tree validators, and handoff.

**Required corrections:**

- One Warrior tree source and one unlocked-node/skill-point authority.
- One skill point per level; free start node.
- Remove the hardcoded Character skill list and any remaining duplicate skill-point/unlock stores after the canonical screen is connected.
- Use JSON positions for the ornate three-branch graph, detail panel, legends, confirmation, prerequisites, and keystone blocking.
- Fit the complete graph, detail panel, and footer inside 640x360, including larger-text mode.
- Request pause/modal ownership from the HUD coordinator; the skill-tree screen must not pause/resume the game independently.
- Require explicit unlock confirmation before spending a point.
- Route ability unlocks through `AbilityManager` and modifiers through reviewed combat APIs.
- Persist only through the Phase 14 payload adapter.
- Do not implement lifesteal, buffs, shields, or other deferred effects unless combat scope is explicitly expanded.

## WO-MENU-15 - Title, Coordinator, Settings, And Death Flow

**Status:** Blocked by WO-SAV-14; execute Phase 15A through 15D in order.

**Objective:** Deliver the approved title and in-game menu flow using canonical domain screens.

**Owned files:** title, HUD/menu coordinator, Character shell, Quest Journal shell, pause/settings/death UI, and menu validators.

**Required implementation:**

- Two-line title, New Game, Continue, Settings, and last-played character banner.
- Warrior enabled; Ranger/Mage visible and disabled as `Coming Later`.
- One HUD-owned modal coordinator for Quests, Character, Inventory, Settings, pause, and death.
- Inventory remains standalone; Character owns Equipment and the canonical Skill Tree hook.
- NPC quest offer/turn-in remains separate from the categorized global Quest Journal.
- Return to Town blocked during combat.
- Death uses metadata/MapManager, resets transient area state, preserves quest progress, and has no gold, XP, or item penalty.
- Validate every state at 640x360 and in larger-text mode.

## WO-LORE-C1 - Content And Naming Audit

**Status:** Documentation/data proposals only until runtime owners approve migrations.

**Objective:** Replace placeholder names and overlapping content with Grimvale-consistent proposals while preserving live IDs.

**Owned files:** lore/content proposal docs and architect-approved data-only naming notes.

**Do not edit:** live map, quest, monster, item, portal, save, or scene IDs without a complete migration work order.

**Required review:** active/legacy quest objective overlaps, unresolved legacy targets, old brown-road/grey-map content, duplicate assets, placeholder title strings, and future dedicated Grimvale names for `custom_kit_town`.
