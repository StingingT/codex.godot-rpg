# Umbral Explorers: Relics of Grimvale — Main Godot RPG Implementation Plan

**Status:** ACTIVE MASTER SPEC  
**Project:** *Umbral Explorers: Relics of Grimvale*
**Engine:** Godot 4.3+  
**Language:** GDScript  
**Game type:** 2D top-down real-time action RPG  
**Map style:** Hand-authored `.tscn` maps using `TileMapLayer`  
**Primary rule:** This file is the **architecture and phase** source of truth. Domain specs listed in §0.1 provide detailed rules for lore, menus, combat, art, maps, monsters, skill trees, and inventory/itemization/loot.

**Agent skills index:** [docs/agent_skills_required.md](docs/agent_skills_required.md)

---

## 0. Instructions for ChatGPT / Claude Code / Implementation Agents

You are building a 2D top-down RPG in **Godot 4.3+** using **GDScript**.

Work through the phases sequentially. Do not skip ahead. After completing each task, validate the project in Godot before marking the task done.

### Agent rules

1. Use this file as the source of truth for **phases, autoloads, and core architecture**.
2. Use specialized docs in `docs/` for lore, menus, combat, monsters, maps, sprites, skill trees, and inventory/itemization/loot (see §0.1). Older split specs outside `docs/` are legacy unless listed in §0.1.
3. Use **real-time combat**, not turn-based combat.
4. Use **Godot scenes, GDScript, Resources, and JSON metadata**.
5. Do not implement Python architecture.
6. Use **`TileMapLayer`**, not old `TileMap`-only architecture.
7. Build maps as **hand-authored `.tscn` scenes** first.
8. Use JSON mainly for metadata, connections, encounters, quests, dialogue, and content configuration.
9. Prefer adding content through data files and scene instances instead of rewriting core systems.
10. Preserve existing folder structure and naming conventions unless this file explicitly updates them.
11. Use `res://` paths for all resources.
12. Use Godot naming conventions:
    - PascalCase for node names and scene root names
    - snake_case for variables, functions, files, and folders
13. Commit to git after each phase with a clear message.
14. If validation fails, fix the issue before continuing.
15. **Do not generate final monster art** in implementation tasks — import from [docs/sprite_deliverables/manifest.json](docs/sprite_deliverables/manifest.json) (sprite agent).
16. **Do not use flat background + rectangle collision** as the long-term map standard — follow [docs/custom_tileset_object_kit_instructions.md](docs/custom_tileset_object_kit_instructions.md).
17. Monster locomotion animations use Godot name **`move`**, not `walk` (player may still use `walk`).
18. Enable skills per role from [docs/agent_skills_required.md](docs/agent_skills_required.md).
19. Agent work must pass architect review before integration. Use [docs/agent_handoff_template.md](docs/agent_handoff_template.md), review against [docs/architect_review_checklist.md](docs/architect_review_checklist.md), and record the result in [docs/agent_integration_log.md](docs/agent_integration_log.md).

### 0.1 Active documentation index

| Domain | Canonical doc | Agent role |
|--------|---------------|------------|
| Architecture & phases | This file | Implementation |
| Agent skills | [docs/agent_skills_required.md](docs/agent_skills_required.md) | All |
| Lore / world tone / narrative foundation | [docs/Grimvale_Lore_World_Tone_Foundation.md](docs/Grimvale_Lore_World_Tone_Foundation.md) | All content / naming |
| Menu / game flow / settings | [docs/Menu_Game_Flow_Settings_Agent_Instructions.md](docs/Menu_Game_Flow_Settings_Agent_Instructions.md) | Menu / implementation |
| Combat / abilities / feedback | [docs/Combat_Ability_Logic_Feedback_Agent_Instructions.md](docs/Combat_Ability_Logic_Feedback_Agent_Instructions.md) | Combat / implementation |
| Maps / tileset kit | [docs/custom_tileset_object_kit_instructions.md](docs/custom_tileset_object_kit_instructions.md) | Maps / implementation |
| Monsters (design + data) | [docs/monster_design_bible.md](docs/monster_design_bible.md) | Implementation |
| Monster art production | [docs/external_sprite_agent_instructions.md](docs/external_sprite_agent_instructions.md) | External sprite only |
| Sprite agent skills | [docs/external_sprite_agent_skills.md](docs/external_sprite_agent_skills.md) | External sprite |
| Art handoff | [docs/sprite_deliverables/manifest.json](docs/sprite_deliverables/manifest.json) | Sprite → implementation |
| Skill tree | [docs/RPG_Skill_Tree_Agent_Guide.md](docs/RPG_Skill_Tree_Agent_Guide.md) | Skill tree / implementation |
| Inventory / equipment / itemization / loot | [docs/Inventory_Equipment_Itemization_Loot_Agent_Instructions.md](docs/Inventory_Equipment_Itemization_Loot_Agent_Instructions.md) | Inventory / implementation |
| Architect review | [docs/architect_review_checklist.md](docs/architect_review_checklist.md) | Architect / all |
| Agent handoff | [docs/agent_handoff_template.md](docs/agent_handoff_template.md) | All |
| Integration log | [docs/agent_integration_log.md](docs/agent_integration_log.md) | Architect |
| Content overlap audit | [docs/content_overlap_audit.md](docs/content_overlap_audit.md) | Architect |
| Tileset pointer (root) | [custom_tileset_object_kit_instructions.md](custom_tileset_object_kit_instructions.md) | → `docs/` copy |

### 0.2 Multi-agent workflow

```text
Sprite agent     → PNGs + manifest.json
Implementation   → monsters.json, scenes, SpriteFrames, gameplay
Tileset agent    → TileMapLayer maps + custom kit (same as implementation)
Skill tree agent → warrior_skill_tree.json + skill tree UI (mockup layout)
Inventory agent  → item definitions, inventory/equipment, loot, shops, save migration
Combat agent     → damage pipeline, abilities, combat feedback, death/reset contracts
Menu agent       → title flow, autosave metadata, top menu, pause, settings, death UI
Content agents   → Grimvale canon, naming, heroic-mystery tone, portal/dungeon logic
Architect        → reviews handoffs, integrates compatible work, logs holds
```

Implementation agents **wire** delivered assets; they do not redraw monsters or replace the skill-tree UI with a minimal list.
When an agent output includes useful suggestions that are not required for the current phase, log them as holds or follow-up tasks instead of blocking unrelated compatible work.

---

## 1. Game Vision

**Umbral Explorers: Relics of Grimvale** is a mobile-friendly 2D top-down action RPG about a new member of the Umbral Explorers entering portal-linked dungeons, protecting surviving towns, and recovering relics of the Fallen before the Umbral Realm awakens again.

The tone is **heroic mystery first, fallen-kingdom fantasy second**. Grimvale is a country or island-scale setting, not one town or valley. The player should feel hopeful and adventurous even when exploring ruined, corrupted, or dangerous regions.

The visual contrast is intentional:

- Title, guild, and major menu identity: luminous blue/gold pixel fantasy, heroic, welcoming, readable.
- World and dungeon identity: worn stone, dark timber, cold shadows, Umbral purple/blue corruption, readable paths and interactables.
- Normal enemies and early regions remain suitable for younger players; darkness escalates through elites, bosses, ruins, and late-game regions without becoming grimdark horror.
- The supplied title-screen image is a **visual direction reference only**, not a shipping asset and not permission to copy external game UI or artwork.

The game combines:

| Reference | Owns |
|-----------|------|
| **Pokémon** | Top-down routes, zone graph, biome readability at a glance |
| **Path of Exile** | Dark world palette, ARPG loot/skills tone, grim hubs, zone escalation |
| **Zelda** | Real-time combat spaces, patrol/arena map flow, interactables, boss pockets |

**Locked:** 2D top-down (not isometric). Heroic-mystery tone, bright guild/menu identity, and darker Umbral-touched world materials must remain readable.

The game includes:

- Player movement and collision
- Hand-authored maps
- Connected areas, towns, monster maps, caves, dungeons, and boss zones
- Real-time combat
- Basic attack and ability buttons
- Monster AI with idle, wander, chase, attack, and death states
- Equipment, weapons, armor, inventory, and item pickups
- NPC dialogue
- Quests
- Save/load
- Mobile HUD
- Optional backend integration with Supabase
- Optional in-app purchases with RevenueCat
- **Warrior skill tree** (37-node prototype, PoE-style graph, ornate UI — see skill tree guide)
- **Monster Codex** menu (future) — static portraits + affinity/description from monster data
- **Custom tileset / object kit** replacing flat map backgrounds over time
- **Portal-linked multi-map dungeons** entered from towns or guild hubs
- **The Fallen and their relics** as the primary narrative, boss, equipment, and progression foundation

---

## 2. Active Project Structure

Use this folder structure.

```text
res://
├── assets/
│   ├── sprites/
│   │   ├── player/
│   │   ├── monsters/
│   │   │   ├── battle/          # sprite agent sheets
│   │   │   ├── codex/           # bestiary portraits
│   │   │   └── icons/           # affinity icons
│   │   ├── weapons/
│   │   ├── clothes/
│   │   ├── npcs/
│   │   └── ui/
│   │       └── skilltree/       # node rings, legends (skill tree UI)
│   ├── tilesets/
│   │   └── custom/              # PoE-dark tile kit (see tileset doc)
│   ├── audio/
│   │   ├── sfx/
│   │   └── music/
│   └── fonts/
├── scenes/
│   ├── player/
│   ├── monsters/
│   ├── weapons/
│   ├── npcs/
│   ├── ui/
│   ├── maps/
│   ├── items/
│   ├── effects/
│   └── world/
├── scripts/
│   ├── player/
│   ├── monsters/
│   ├── weapons/
│   ├── npcs/
│   ├── ui/
│   ├── quests/
│   ├── inventory/
│   ├── dialogue/
│   ├── components/
│   ├── combat/
│   ├── abilities/
│   ├── world/
│   └── autoload/
├── data/
│   ├── items/
│   ├── itemization/             # aggregate tier and affix configuration
│   ├── loot/                    # aggregate loot tables and rarity weights
│   ├── quests/
│   ├── dialogue/
│   ├── maps/
│   ├── encounters/
│   ├── monsters/
│   ├── abilities/
│   └── skilltrees/              # target; legacy also in data/classes/
├── docs/
│   ├── agent_skills_required.md
│   ├── monster_design_bible.md
│   ├── external_sprite_agent_instructions.md
│   ├── custom_tileset_object_kit_instructions.md
│   ├── Grimvale_Lore_World_Tone_Foundation.md
│   ├── Menu_Game_Flow_Settings_Agent_Instructions.md
│   ├── Combat_Ability_Logic_Feedback_Agent_Instructions.md
│   ├── RPG_Skill_Tree_Agent_Guide.md
│   ├── Inventory_Equipment_Itemization_Loot_Agent_Instructions.md
│   └── sprite_deliverables/
│       └── manifest.json
└── addons/
```

### Key additions compared with the old main plan

The active structure includes:

```text
res://scenes/items/
res://scenes/world/
res://scripts/components/
res://scripts/combat/
res://scripts/abilities/
res://scripts/world/
res://data/encounters/
res://data/monsters/
res://data/abilities/
res://data/skilltrees/
```

---

## 3. Core Architecture

### Scene-driven Godot architecture

Use Godot scenes for runtime objects:

```text
Player = CharacterBody2D scene
Monster = CharacterBody2D scene
NPC = CharacterBody2D or Node2D scene
Items = Area2D pickup scenes
Maps = Node2D scenes with TileMapLayer children
UI = Control scenes
```

### Component-driven gameplay

Reusable components should be placed in `scripts/components/`.

Recommended components:

```text
stats_component.gd
hitbox_component.gd
hurtbox_component.gd
health_component.gd
interaction_component.gd
pickup_component.gd
status_effect_component.gd
```

### Data-driven content

Use JSON or Godot Resources for content definitions.

Recommended split:

```text
Godot scenes = layout and runtime object composition
GDScript = behavior
Resources = reusable typed game data
JSON = external content metadata and easily editable content lists
```

Agents should add content through data files or scene instances whenever possible.

---

## 4. Collision Layers

Use this collision setup consistently.

| Layer | Name | Used By |
|---:|---|---|
| 1 | Player | Player `CharacterBody2D` |
| 2 | World | Walls, water, obstacles, blocked tiles |
| 3 | Monsters | Monster `CharacterBody2D` |
| 4 | NPCs | NPC bodies |
| 5 | Items | Item pickups / loot |
| 6 | Interaction | NPC zones, doors, exits, chests |
| 7 | Player Hitbox | Player attacks and abilities |
| 8 | Monster Hitbox | Monster attacks |
| 9 | Hurtbox | Damage receivers |
| 10 | Projectiles | Player/monster projectiles |

---

## 5. Autoload Singletons

Use these autoloads.

| Singleton | Path | Purpose |
|---|---|---|
| GameManager | `scripts/autoload/game_manager.gd` | Global game state and signals |
| MapManager | `scripts/autoload/map_manager.gd` | Map loading, transitions, spawn placement |
| DialogueManager | `scripts/autoload/dialogue_manager.gd` | Dialogue loading and state |
| QuestManager | `scripts/autoload/quest_manager.gd` | Quest tracking and objectives |
| SaveManager | `scripts/autoload/save_manager.gd` | Local save/load |
| AudioManager | `scripts/autoload/audio_manager.gd` | Music and SFX |
| InventoryManager | `scripts/autoload/inventory_manager.gd` | Inventory state if not stored directly on player |
| AbilityManager | `scripts/autoload/ability_manager.gd` | Ability lookup and cooldown helpers |
| SettingsManager | `scripts/autoload/settings_manager.gd` | Planned Phase 15 owner of global `user://settings.json` |
| SupabaseClient | `scripts/autoload/supabase_client.gd` | Optional cloud saves/backend |
| IAPManager | `scripts/autoload/iap_manager.gd` | Optional RevenueCat integration |

`SettingsManager` is a planned autoload, not a requirement of the current runtime until Phase 15 implements it. Combat calculators and feedback coordinators should remain scene-scoped or stateless helpers unless a reviewed implementation proves a global owner is necessary.

---

## 6. Map System: Hand-authored `.tscn` Maps

Maps should be made as Godot scenes first. JSON should describe metadata, connections, encounter tables, and spawn rules.

### Map scene root

Every map scene should use this contract:

```text
Map_Forest_01.tscn
└── MapForest01 : Node2D
    ├── GroundLayer : TileMapLayer
    ├── DecorLayer : TileMapLayer
    ├── CollisionLayer : TileMapLayer
    ├── OverlayLayer : TileMapLayer
    ├── EntryPoints : Node2D
    │   ├── entry_north : Marker2D
    │   ├── entry_south : Marker2D
    │   ├── entry_east : Marker2D
    │   └── entry_west : Marker2D
    ├── ExitTriggers : Node2D
    │   ├── exit_north : Area2D
    │   ├── exit_south : Area2D
    │   ├── exit_east : Area2D
    │   └── exit_west : Area2D
    ├── SpawnPoints : Node2D
    │   ├── spawn_01 : Marker2D
    │   ├── spawn_02 : Marker2D
    │   └── spawn_03 : Marker2D
    ├── BossSpawnPoint : Marker2D
    ├── NPCs : Node2D
    ├── Items : Node2D
    └── CameraLimits : ReferenceRect or Marker2D bounds
```

### Required map rules

1. Use `TileMapLayer`, not legacy `TileMap` architecture.
2. Map layouts are hand-painted in Godot.
3. World collision comes from TileSet collision shapes and/or `CollisionLayer`.
4. Exit triggers are `Area2D` nodes on layer 6.
5. Spawn points are `Marker2D` nodes.
6. Map IDs are lower snake case, for example `forest_01`.
7. Scene names are PascalCase, for example `MapForest01`.
8. Scene files may use readable filenames, for example `map_forest_01.tscn`.
9. Every registered map declares `content_state`: `active`, `legacy`, or `development`.
10. Only `active` maps appear in normal travel choices or new-game routing. `legacy` maps remain loadable only for save compatibility until migrated or removed.

### Recommended map metadata file

`res://data/maps/maps.json`

```json
{
  "forest_01": {
    "content_state": "active",
    "scene": "res://scenes/maps/map_forest_01.tscn",
    "display_name": "Whispering Forest",
    "biome": "forest",
    "zone_tier": 1,
    "route_order": 1,
    "level_requirement": 1,
    "music": "res://assets/audio/music/forest_theme.ogg",
    "encounter_table": "forest_low",
    "connections": [
      {
        "to": "forest_02",
        "via": "exit_north",
        "spawn_at": "entry_south"
      },
      {
        "to": "fields_01",
        "via": "exit_west",
        "spawn_at": "entry_east"
      }
    ]
  }
}
```

### Game-flow metadata

New-game and respawn destinations must be data-driven rather than hardcoded in title, pause, or death UI scripts.

Recommended file:

`res://data/game_flow.json`

```json
{
  "schema_version": 1,
  "new_game": {
    "map_id": "custom_kit_town",
    "entry_id": "entry_default"
  },
  "default_respawn": {
    "map_id": "custom_kit_town",
    "entry_id": "entry_default"
  }
}
```

Individual dungeon or region metadata may later override the nearest safe town and entry. Until then, `custom_kit_town` remains the configured start and respawn map.

### Recommended encounter file

`res://data/encounters/encounters.json`

```json
{
  "forest_low": {
    "ambient_spawns": [
      { "monster_id": "slime_green", "weight": 40, "max_alive": 4 },
      { "monster_id": "wolf_forest", "weight": 30, "max_alive": 3 },
      { "monster_id": "bat_small", "weight": 20, "max_alive": 2 },
      { "monster_id": "dryad_sprite", "weight": 10, "max_alive": 1 }
    ],
    "boss": { "monster_id": "ent_ancient", "spawn_point": "BossSpawnPoint" }
  }
}
```

### Typical map content rule

Each monster map usually has:

```text
4 regular monster types
1 boss or elite enemy near the end region
several spawn points
1-4 exits or transitions
optional NPCs, chests, resources, or quest triggers
```

---

## 7. Player System

The player is not a Python class. The player is a Godot scene.

### Player scene

```text
scenes/player/player.tscn
└── Player : CharacterBody2D
    ├── AnimatedSprite2D
    ├── CollisionShape2D
    ├── Camera2D
    ├── StatsComponent : Node
    ├── HurtboxComponent : Area2D
    ├── AttackOrigin : Marker2D
    ├── InteractionRay or InteractionArea : Area2D
    └── AbilitySlots : Node
```

### Core player stats

The player should support these stats:

```text
name
level
xp
gold
hp
max_hp
mana
max_mana
attack
defense
move_speed
crit_chance
crit_damage
skill_points
unlocked_skill_nodes
```

### Player runtime state

Saveable player state should include:

```text
current_map_id
position
facing_direction
level
xp
gold
hp
mana
inventory
equipment
learned_abilities
ability_slots
unlocked_skill_nodes
active_quests
completed_quests
```

### Level-up rule

Basic starting rule:

```text
level += 1
max_hp += 10
max_mana += 5
attack += 2
defense += 1
skill_points += 1
hp = max_hp
mana = max_mana
```

This can be balanced later.

---

## 8. Real-time Combat System

Combat is real-time action combat. Do not implement old combat flow.

### Core combat flow

```text
1. Player presses attack or ability input.
2. Player enters attack/cast state.
3. Animation plays.
4. Hitbox/projectile/area effect becomes active.
5. Hurtbox receives hit.
6. Damage/effects are calculated.
7. Target takes damage, knockback, status effects, or healing.
8. Cooldown starts in seconds.
9. Player/monster returns to movement or next combat state.
```

### Basic attack

Basic attacks are always available, cost no mana, can crit, and use the same damage pipeline as abilities.

The player has:

```text
1 basic attack
4 ability slots
```

V1 class support:

```text
Warrior = playable; free melee swing, Cleave, Charge
Ranger = visible as Coming Later; Arrow basic attack deferred
Mage = visible as Coming Later; Arcane Bolt basic attack deferred
```

Use a player hitbox scene for Warrior attacks.

```text
scenes/weapons/basic_melee_hitbox.tscn
└── BasicMeleeHitbox : Area2D
    ├── CollisionShape2D
    └── hitbox_component.gd
```

Hitbox rules:

```text
active for a short real-time window, for example 0.12-0.25 seconds
uses collision layer 7 for player attacks
checks hurtboxes on layer 9
prevents repeated hits on the same target during one swing unless explicitly allowed
```

### Central damage pipeline

All direct damage must be calculated by one stateless, scene-independent `DamageCalculator` helper before the hurtbox changes health. Hitboxes, projectiles, abilities, statuses, players, and monsters must not maintain competing formulas.

Required stage order:

```text
1. Build final attacker offensive value supplied by the stat system.
2. Apply basic-attack or ability base power and/or multiplier.
3. Roll within the configured min/max range.
4. Apply attacker and skill modifiers.
5. Roll and apply critical damage when allowed.
6. Apply defender mitigation.
7. Clamp to the configured minimum and optional maximum.
8. Emit the canonical damage package.
9. Hurtbox applies final damage and requests feedback.
```

Initial defense formula:

```gdscript
var mitigation_ratio := defense / (defense + defense_softcap)
var mitigated_damage := rolled_damage * (1.0 - mitigation_ratio)
```

Store `defense_softcap`, damage floors, crit defaults, and feedback caps in `res://data/combat/combat_balance.json`. Initial `defense_softcap` is `900.0`, minimum damage is `1`, default crit chance is `0.05`, and default crit damage multiplier is `1.5`.

### Damage package

Every damaging hit passes one consistent dictionary or typed `RefCounted` data object:

```gdscript
{
    "source": attacker,
    "target": defender,
    "amount": final_damage,
    "raw_amount": rolled_damage,
    "damage_type": "physical",
    "ability_id": "basic_attack",
    "is_critical": false,
    "can_crit": true,
    "knockback": Vector2.ZERO,
    "status_effects": [],
    "feedback_tags": ["melee", "slash"]
}
```

Approved v1 damage types:

```text
physical
spell
poison
true
```

Prototype `fire`, `dark`, `arcane`, and `acid` entries must be mapped to an approved v1 type during combat migration instead of creating an unreviewed resistance chart.

### Combat state and feedback ownership

- Add one authoritative combat-state query or tracker used by pause/menu Return to Town rules.
- One combat feedback owner handles damage/heal/DoT numbers, hit flashes, particles, and SFX requests.
- Damage numbers are white for normal damage, red for critical damage, green for healing, and purple for aggregated DoT.
- Mobile defaults: at most 30 visible damage numbers, 8 particle bursts per frame, and 1 status popup per target per second.
- No screen shake or hit-stop in v1.

---

## 9. Ability System

Abilities are real-time skills with mana costs, cooldowns in seconds, optional cast time, hitboxes, projectiles, or area effects. All classes use mana for abilities; basic attacks remain free.

### Ability data example

`res://data/abilities/abilities.json`

```json
{
  "cleave": {
    "name": "Cleave",
    "description": "A wider, stronger Warrior swing.",
    "mana_cost": 8,
    "cooldown_seconds": 3.0,
    "cast_time_seconds": 0.0,
    "ability_type": "hitbox",
    "scene": "res://scenes/effects/cleave_hitbox.tscn",
    "damage_multiplier": 1.4,
    "effects": [
      { "type": "damage", "damage_type": "physical", "can_crit": true }
    ]
  }
}
```

### Supported real-time effect types

```text
damage
heal
dot
knockback
```

Prototype `hot`, `buff`, `debuff`, `shield`, `lifesteal`, `slow`, and `stun` behavior is deferred until each effect has a reviewed runtime consumer and migration path.

Warrior v1 abilities:

```text
Cleave = stronger/wider melee hit, mana cost, 3-second cooldown
Charge = short collision-safe dash attack, mana cost, 5-second cooldown
```

Charge must use collision-aware movement and must not pass through walls, water, props, or closed doors.

### Ability casting order

```text
check player state
check mana
check cooldown
start cast animation / cast timer
spend mana at cast commit point
spawn hitbox/projectile/area effect
apply effects through hurtbox/status system
start cooldown in seconds
```

Effect application must return success/failure where inventory consumption depends on the result. Health and mana potions are not consumed at full HP or mana.

### Cooldowns

Cooldowns are time-based in seconds.

```gdscript
current_cooldown_seconds = max(current_cooldown_seconds - delta, 0.0)
```

Ability buttons use a dark radial cooldown overlay. Insufficient mana flashes the button blue, requests a subtle error SFX, and may show rate-limited “Not enough mana” text controlled by settings.

---

## 10. Monster System

Monsters are Godot scenes using real-time AI. **Art** is produced by the external sprite agent; **implementation** imports paths from `docs/sprite_deliverables/manifest.json` per [monster_design_bible.md](docs/monster_design_bible.md).

### Monster animation names

Use on `AnimatedSprite2D`: `idle`, **`move`**, `attack`, `hit`, `death`, `spawn`. Do not use `walk` on monsters.

### Monster Codex (menu, future)

Bestiary UI uses `codex_portrait`, `description`, `family`, `affinities`, and optional `weaknesses` / `resists` from `monsters.json`. Portraits match codex mockup style (see sprite agent instructions).

### Monster base scene

```text
scenes/monsters/monster_base.tscn
└── MonsterBase : CharacterBody2D
    ├── AnimatedSprite2D
    ├── CollisionShape2D
    ├── StatsComponent
    ├── HurtboxComponent : Area2D
    ├── DetectionArea : Area2D
    ├── AttackArea : Area2D
    └── StateMachine : Node
```

### Monster states

```text
idle
wander
chase
attack
hit_stun
death
```

### Monster data example

`res://data/monsters/monsters.json`

```json
{
  "slime_green": {
    "name": "Green Slime",
    "family": "slime",
    "size_class": "small",
    "affinities": ["neutral"],
    "codex_index": 1,
    "sprite": "res://assets/sprites/monsters/battle/slime_green_sheet.png",
    "codex_portrait": "res://assets/sprites/monsters/codex/slime_green_portrait.png",
    "description": "A basic blob creature that bounces and uses splash strikes.",
    "weaknesses": [],
    "resists": [],
    "scene": "res://scenes/monsters/monster_base.tscn",
    "max_hp": 30,
    "attack": 5,
    "defense": 1,
    "move_speed": 35,
    "xp_reward": 10,
    "gold_min": 1,
    "gold_max": 3,
    "abilities": ["slime_splash"]
  }
}
```

Full schema and roster: [monster_design_bible.md](docs/monster_design_bible.md) §20–21.

---

## 10.5 Skill Tree System (Warrior v1)

PoE-inspired **connected graph** with **ornate UI** (three branches: red offense, blue defense, green utility; start node at bottom; detail panel on right). See [RPG_Skill_Tree_Agent_Guide.md](docs/RPG_Skill_Tree_Agent_Guide.md) §2.1 for mockup layout.

Target data:

```text
res://data/skilltrees/warrior_skill_tree.json
```

Legacy `res://data/classes/warrior_skill_tree.json` exists — migrate or consolidate to one tree file.

First active skills from tree: **Cleave**, **Charge**. Keystones: **Blood Rage**, **Iron Wall** (mutual exclusion v1).

UI: refactor `skill_tree_ui.tscn` toward skill tree guide layout; add `open_skill_tree` input if missing.

---

## 11. Inventory, Items, and Equipment

Use [docs/Inventory_Equipment_Itemization_Loot_Agent_Instructions.md](docs/Inventory_Equipment_Itemization_Loot_Agent_Instructions.md) as the canonical Phase 9 domain specification. Keep one JSON file per item definition and preserve the existing `Inventory`, `DataRegistry`, pickup, shop, player-equipment, and save integration paths.

### Item pickup scene

```text
scenes/items/item_pickup.tscn
└── ItemPickup : Area2D
    ├── Sprite2D
    ├── CollisionShape2D
    └── pickup_component.gd
```

### Item data example

`res://data/items/health_potion.json`

```json
{
  "item_id": "health_potion",
  "item_name": "Health Potion",
  "item_type": 2,
  "category": "consumable",
  "stackable": true,
  "max_stack": 20,
  "heal_amount": 50,
  "icon": "res://assets/sprites/ui/items/health_potion.png"
}
```

Aggregate tier/affix configuration belongs under `res://data/itemization/`, and loot tables belong under `res://data/loot/`. Do not place aggregate JSON beside per-item files unless `DataRegistry` is explicitly changed to filter non-item documents.

---

## 12. Dialogue and Quest System

### Dialogue data

`res://data/dialogue/villager_01.json`

```json
{
  "start": {
    "speaker": "Villager",
    "text": "The forest has become dangerous lately.",
    "choices": [
      { "text": "I can help.", "next": "quest_offer" },
      { "text": "Goodbye.", "next": null }
    ]
  },
  "quest_offer": {
    "speaker": "Villager",
    "text": "Please defeat 5 green slimes.",
    "start_quest": "clear_green_slimes",
    "next": null
  }
}
```

### Quest data

`res://data/quests/clear_green_slimes.json`

```json
{
  "quest_id": "clear_green_slimes",
  "title": "Clear the Green Slimes",
  "description": "Defeat 5 green slimes in the forest.",
  "objectives": [
    { "type": "kill", "target_id": "slime_green", "required": 5 }
  ],
  "rewards": {
    "xp": 100,
    "gold": 25,
    "items": [
      { "item_id": "health_potion_small", "amount": 2 }
    ]
  }
}
```

Quest UI has two distinct responsibilities:

- NPC quest interaction presents one offer, progress check, or turn-in conversation.
- The global Quest Journal lists Available, Active, Completed, and Finished quests with lore, objectives, rewards, status, and a future Monster Codex hook.

Do not evolve the NPC quest dialog into the global journal or maintain two competing global quest books.

---

## 13. Mobile HUD Direction

The project should support a mobile layout.

Recommended HUD:

```text
Top-left: HP bar and mana bar
Below HP/Mana: minimap placeholder
Bottom-left: virtual joystick
Bottom: XP bar with numbers inside
Bottom-right: basic attack button
Around attack button: ability buttons
Top-right: Quests, Character, Inventory, and Settings cog
```

The active HUD owns one menu coordinator that:

- Opens the existing canonical screens instead of creating parallel inventory, quest, character, or skill-tree state.
- Allows only one major modal menu at a time.
- Routes `pause`, `open_inventory`, `open_quest_log`, `open_character`, `open_settings`, and `open_skill_tree`.
- Keeps Inventory as a standalone window.
- Makes Character open to Equipment and provide the canonical Skill Tree/ability-loadout hook.
- Removes or migrates the duplicate Character inventory tab and script-local placeholder skill lists.
- Pauses gameplay safely while blocking gameplay input beneath modal menus.

Initial desktop controls still need to work.

| Action | Input |
|---|---|
| Move | WASD / Arrow keys |
| Interact | E / Space |
| Attack | J / Left Click |
| Ability 1-4 | 1 / 2 / 3 / 4 |
| Inventory | I / Tab |
| Quest Log | L |
| Character | C |
| Settings | Menu / optional shortcut |
| Skill Tree | T (add `open_skill_tree` if missing) |
| Pause | Escape / P |

---

## 14. Save/Load

Local save data should be JSON-serializable, versioned, validated, and written atomically.

V1 uses autosave only:

```text
user://saves/index.json
user://saves/char_0001.json
```

`index.json` stores `save_index_version`, `last_played_character_id`, and character metadata: stable character ID, display name, class ID, level, current map ID, last-played timestamp, and autosave path. V1 supports one character, but file names and APIs must not hardcode display names or prevent multiple characters later.

The character autosave includes:

```text
save_version
character_id
character_name
player state
current_map_id
player position
inventory
equipment
ability slots
skill tree unlocks
quest state
opened chests
defeated bosses
```

Use `SaveManager` for character metadata, migration, autosave, and load. Migrate the existing `user://saves/slot_1.json` into the indexed single-character model without losing progress. Keep a recoverable backup and replace completed files atomically where the platform permits.

Global settings are not character save data. Planned `SettingsManager` owns versioned `user://settings.json`, including audio, language, gameplay feedback, larger text, and prototype control scaling. Settings must load before the title screen and remain intact if a character save is migrated or removed.

Supabase cloud saves can be added later.

---

## 15. Implementation Phases

## Phase 0 — Project Setup & Repository

Goal: empty Godot project, version control, folder structure, and basic settings.

- [ ] Initialize git repository.
- [ ] Create Godot 4.3+ project.
- [ ] Set display resolution to 640×360.
- [ ] Set stretch mode to `canvas_items`, aspect `keep`.
- [ ] Use 2D mobile-compatible rendering settings.
- [ ] Add input actions: `move_up`, `move_down`, `move_left`, `move_right`, `interact`, `attack`, `ability_1`, `ability_2`, `ability_3`, `ability_4`, `open_inventory`, `open_quest_log`, `open_character`, `open_settings`, `open_skill_tree`, `pause`.
- [ ] Create the active folder structure from this document.
- [ ] Create `.gitignore` for Godot.
- [ ] Create placeholder `main.tscn` with a `Node2D` root and label.
- [ ] Validate project opens without errors.
- [ ] Commit: `Phase 0: Project setup and folder structure`.

## Phase 1 — Placeholder Sprites, Tileset, and First Hand-authored Map

Goal: simple visible map using `TileMapLayer` per [custom_tileset_object_kit_instructions.md](docs/custom_tileset_object_kit_instructions.md) (dark PoE palette, readable paths).

- [ ] Route monster art through sprite agent + `docs/sprite_deliverables/manifest.json` (implementation imports; optional placeholders until art lands).
- [ ] Create placeholder sprites for player, sword, shield, villager, and UI icons.
- [ ] Begin custom kit under `assets/tilesets/custom/` (ground, environment, route tiles).
- [ ] Create a `TileSet` resource with collision for wall/water/blocked tiles.
- [ ] Create `scenes/maps/test_map.tscn` as a hand-authored map scene.
- [ ] Use `TileMapLayer` nodes: `GroundLayer`, `DecorLayer`, `CollisionLayer`, `OverlayLayer`.
- [ ] Add `EntryPoints`, `ExitTriggers`, `SpawnPoints`, `NPCs`, and `Items` nodes.
- [ ] Place a temporary player marker, one slime marker, and one NPC marker.
- [ ] Add a `Camera2D` or prepare player camera.
- [ ] Validate map renders and has no errors.
- [ ] Commit: `Phase 1: Placeholder sprites and first hand-authored map`.

## Phase 2 — Player Movement & Collision

Goal: player moves freely and collides with the world.

- [ ] Create `scenes/player/player.tscn` with `CharacterBody2D` root.
- [ ] Add `AnimatedSprite2D`, `CollisionShape2D`, `Camera2D`, `StatsComponent`, `HurtboxComponent`, and `AttackOrigin`.
- [ ] Write `scripts/player/player_controller.gd`.
- [ ] Use `Input.get_vector()` for movement.
- [ ] Set player collision layer/masks.
- [ ] Instance the player into `test_map.tscn`.
- [ ] Validate movement, wall collision, and camera following.
- [ ] Commit: `Phase 2: Player movement and collision`.

## Phase 3 — Sprite Animation

Goal: player and first monster animations.

- [ ] Create placeholder player spritesheet.
- [ ] Add idle/walk animations in four directions.
- [ ] Update movement script to play correct animation.
- [ ] Create slime idle/bounce animation; monster locomotion uses animation name **`move`**.
- [ ] Create `monster_base.tscn`.
- [ ] Validate animations.
- [ ] Commit: `Phase 3: Sprite animation`.

## Phase 4 — Components: Stats, Hurtbox, Hitbox

Goal: reusable real-time combat components.

- [ ] Create `stats_component.gd`.
- [ ] Create `hurtbox_component.gd`.
- [ ] Create `hitbox_component.gd`.
- [ ] Add a stateless `damage_calculator.gd`.
- [ ] Define the canonical damage package format.
- [ ] Add `data/combat/combat_balance.json` with `defense_softcap: 900.0`, crit defaults, damage floor, and feedback caps.
- [ ] Route direct damage through the central calculator and diminishing-defense formula.
- [ ] Add hurtbox to player and monster.
- [ ] Add debug hitbox scene.
- [ ] Validate damage ranges, critical hits, mitigation, minimum damage, and package transfer from hitbox to hurtbox.
- [ ] Commit: `Phase 4: Combat components`.

## Phase 5 — Real-time Basic Combat

Goal: player can attack monsters in real time.

- [ ] Add attack input.
- [ ] Add attack state or attack lockout timer.
- [ ] Spawn or enable melee hitbox from `AttackOrigin`.
- [ ] Keep Warrior basic attacks free and route them through `DamageCalculator`.
- [ ] Add the single combat feedback owner for normal/crit damage numbers.
- [ ] Add knockback.
- [ ] Add monster death and reward event.
- [ ] Add an authoritative combat-state query for menu and return-to-town rules.
- [ ] Validate player can kill a slime.
- [ ] Commit: `Phase 5: Real-time basic combat`.

## Phase 6 — Monster AI

Goal: monsters roam and attack in real time.

- [ ] Create monster state machine.
- [ ] Add idle, wander, chase, attack, hit_stun, death states.
- [ ] Add detection and attack areas.
- [ ] Add monster hitbox for attacks.
- [ ] Use timed attack hitboxes rather than contact damage as the primary monster damage model.
- [ ] Prepare reusable wind-up, telegraph, active, and recovery phases for elites/bosses.
- [ ] Validate monster chases and damages player.
- [ ] Commit: `Phase 6: Monster AI`.

## Phase 7 — Ability System

Goal: real-time skills with cooldowns and mana.

- [ ] Create ability data format.
- [ ] Create `AbilityManager`.
- [ ] Add cooldown tracking in seconds.
- [ ] Add mana spending for abilities while keeping basic attacks free.
- [ ] Implement Warrior Cleave with a wider hitbox, `1.4` multiplier, mana cost, and 3-second cooldown.
- [ ] Implement Warrior Charge with collision-safe movement, mana cost, and 5-second cooldown.
- [ ] Add mouse aim and prepare the future mobile tap-aim path.
- [ ] Support damage, healing, DoT, and knockback; defer prototype buff/debuff/shield/lifesteal effects.
- [ ] Make heal/mana effect application return success/failure so full-resource potions are not consumed.
- [ ] Add ability buttons to HUD.
- [ ] Add radial cooldown overlays and rate-limited insufficient-mana feedback.
- [ ] Validate Cleave, Charge collision, potion consumption, cooldowns, and four ability slots during real-time combat.
- [ ] Commit: `Phase 7: Real-time ability system`.

## Phase 8 — HUD and Mobile Controls

Goal: visible player status and mobile-friendly inputs.

- [ ] Create HUD scene.
- [ ] Add HP, mana, XP, gold, weapon icon.
- [ ] Add bottom-left joystick placeholder/control.
- [ ] Add bottom-right attack button.
- [ ] Add ability buttons around attack button.
- [ ] Add minimap placeholder.
- [ ] Validate desktop and mobile-style inputs.
- [ ] Commit: `Phase 8: HUD and mobile controls`.

## Phase 9 — Inventory, Items, and Equipment

Goal: collect items and equip gear.

Follow the phased migration sequence in [docs/Inventory_Equipment_Itemization_Loot_Agent_Instructions.md](docs/Inventory_Equipment_Itemization_Loot_Agent_Instructions.md). Each subphase requires its own reviewed handoff; do not merge the complete itemization rewrite as one unreviewed package.

- [ ] Create item data format.
- [ ] Create inventory data structure.
- [ ] Create item pickup scene.
- [ ] Create inventory UI.
- [ ] Add equipment slots.
- [ ] Apply equipment stat bonuses.
- [ ] Validate item pickup, stacking, equip, and unequip.
- [ ] Commit: `Phase 9: Inventory and equipment`.

## Phase 10 — Dialogue and NPCs

Goal: talk to NPCs.

- [ ] Create NPC base scene.
- [ ] Create interaction zone.
- [ ] Create dialogue JSON format.
- [ ] Create dialogue UI.
- [ ] Add choices and simple branching.
- [ ] Validate NPC interaction.
- [ ] Commit: `Phase 10: NPC dialogue`.

## Phase 11 — Quest System

Goal: start and complete quests.

- [ ] Create quest JSON format.
- [ ] Create QuestManager.
- [ ] Add kill objective tracking.
- [ ] Add collect objective tracking.
- [ ] Keep NPC quest offer/turn-in UI separate from the global Quest Journal.
- [ ] Add the categorized global Quest Journal: Available, Active, Completed, Finished.
- [ ] Add rewards.
- [ ] Validate basic quest loop.
- [ ] Commit: `Phase 11: Quest system`.

## Phase 12 — MapManager and Map Transitions

Goal: multiple hand-authored maps connected through metadata.

- [ ] Create `MapManager` autoload.
- [ ] Create `maps.json` metadata.
- [ ] Create `map_transition.gd` for exit triggers.
- [ ] Load target map scene from metadata.
- [ ] Spawn player at target entry marker.
- [ ] Add fade out/in transition.
- [ ] Validate moving between two maps.
- [ ] Commit: `Phase 12: Map transitions`.

## Phase 13 — Spawn Manager and Encounter Tables

Goal: maps spawn monsters from data.

- [ ] Create encounter tables.
- [ ] Create `spawn_manager.gd`.
- [ ] Spawn ambient monsters at `SpawnPoints`.
- [ ] Respect max alive counts.
- [ ] Respawn after timer if needed.
- [ ] Spawn boss at boss marker.
- [ ] Validate 4 regular monsters + boss setup on one map.
- [ ] Commit: `Phase 13: Spawn manager and encounters`.

## Phase 14 — Save/Load

Goal: preserve progress through one migration-safe autosave character while keeping future multiple-character support possible.

- [ ] Extend `SaveManager` around stable character IDs, not display names.
- [ ] Add versioned `user://saves/index.json` metadata and `user://saves/char_0001.json`.
- [ ] Migrate existing `user://saves/slot_1.json` without losing player, inventory, equipment, quest, skill, or map state.
- [ ] Use temporary-file replacement and a recoverable backup for atomic autosave writes.
- [ ] Serialize player state, inventory/equipment, quest state, skill state, current map, and position.
- [ ] Add character name, class, level, map, timestamp, and autosave path metadata for title Continue/banner use.
- [ ] Add `data/game_flow.json` for new-game and default-respawn map/entry IDs.
- [ ] Validate new autosave, old-save migration, corrupt-save fallback, quit/reload/Continue, and metadata refresh.
- [ ] Commit: `Phase 14: Save and load`.

## Phase 15 — Menus and Settings

Goal: coherent branded title, character start, top-menu, pause/settings, and death flow. Follow [Menu_Game_Flow_Settings_Agent_Instructions.md](docs/Menu_Game_Flow_Settings_Agent_Instructions.md) in separately reviewed subphases.

### Phase 15A — Title and character start

- [ ] Brand the project and title as `Umbral Explorers: Relics of Grimvale`.
- [ ] Create the blue/gold title composition with New Game, Continue, Settings, and top-left last-played character banner.
- [ ] Treat the supplied title-screen image as direction only; create or commission final original assets separately.
- [ ] Add name entry, class selection, confirmation, and metadata-backed start flow.
- [ ] Validate names as 1-16 trimmed characters using letters, numbers, spaces, and hyphens; use `Explorer` only as a safe fallback display name.
- [ ] Make Warrior playable; show Ranger and Mage disabled with `Coming Later`.
- [ ] Set title screen as main scene and load global settings before displaying it.

### Phase 15B — Top menu and canonical screen navigation

- [ ] Add HUD-owned Quests, Character, Inventory, and Settings controls with one modal coordinator.
- [ ] Keep Inventory standalone and add direct navigation between Inventory and Character.
- [ ] Make Character open to Equipment and host only the canonical Skill Tree/ability-loadout hook.
- [ ] Remove the duplicate Character inventory tab and script-local placeholder skill lists during migration.
- [ ] Refactor the canonical skill tree UI per [RPG_Skill_Tree_Agent_Guide.md](docs/RPG_Skill_Tree_Agent_Guide.md) §2.1.
- [ ] Add `SkillTreeManager` and consolidate the Warrior 37-node tree into one canonical data source.
- [ ] Keep the NPC quest dialog separate and add the categorized global Quest Journal.

### Phase 15C — Pause and global settings

- [ ] Create pause menu: Resume, Settings, Return to Town, Exit to Title.
- [ ] Disable pause-menu Return to Town while the authoritative combat-state query is active.
- [ ] Use `data/game_flow.json`/map metadata for return destinations; never hardcode a town scene in UI.
- [ ] Add `SettingsManager` and versioned `user://settings.json`, independent of character saves.
- [ ] Add Audio, Language, Gameplay, and Controls categories.
- [ ] Add master/music/SFX/mute, damage-number visibility, not-enough-mana text, larger text, and first control-scale settings.

### Phase 15D — Death and reset flow

- [ ] Show italic red `You have fainted`, `Revive in nearest town`, no-loss summary, and area-reset note.
- [ ] Apply no gold, XP, or item penalty in v1.
- [ ] Return through `MapManager`, reset transient monsters/bosses/drops/repeatable chests, and preserve quest progress/permanent rewards.
- [ ] Validate all title and in-game menu flows at 640×360, including larger-text mode and modal exclusivity.
- [ ] Commit: `Phase 15: Menus and settings`.

## Phase 16 — Audio and Feedback

Goal: lightweight, readable game feel that performs on mobile.

- [ ] Add SFX for attack, hit, death, pickup, dialogue, UI.
- [ ] Add map music.
- [ ] Add AudioManager.
- [ ] Add player/enemy hit flash and small capped particle bursts.
- [ ] Route normal, critical, healing, and aggregated DoT numbers through one feedback owner.
- [ ] Enforce combat feedback caps from `data/combat/combat_balance.json`.
- [ ] Do not add screen shake or hit-stop in v1.
- [ ] Validate feedback and audio settings.
- [ ] Commit: `Phase 16: Audio and feedback`.

## Phase 17 — Shops, Economy, and Progression

Goal: gold has purpose.

- [ ] Optional: Monster Codex menu (portraits from `codex_portrait`, affinities, descriptions).
- [ ] Create shop NPC.
- [ ] Create shop UI.
- [ ] Buy/sell items.
- [ ] Add price data.
- [ ] Add basic progression balancing.
- [ ] Validate buying/selling/equipping.
- [ ] Commit: `Phase 17: Shops and economy`.

## Phase 18 — Backend Optional: Supabase

Goal: optional cloud features.

- [ ] Add SupabaseClient autoload.
- [ ] Add authentication placeholder.
- [ ] Add cloud save upload/download.
- [ ] Add leaderboard placeholder if desired.
- [ ] Validate local game still works without backend.
- [ ] Commit: `Phase 18: Supabase backend integration`.

## Phase 19 — In-app Purchases Optional: RevenueCat

Goal: optional monetization.

- [ ] Add IAPManager.
- [ ] Define purchasable products.
- [ ] Add starter pack placeholder.
- [ ] Add inventory expansion placeholder.
- [ ] Validate no core progression depends on purchases.
- [ ] Commit: `Phase 19: RevenueCat IAP integration`.

## Phase 20 — Expansion Content

Goal: add real game content safely.

- [ ] Follow [Grimvale_Lore_World_Tone_Foundation.md](docs/Grimvale_Lore_World_Tone_Foundation.md) for canon, naming, portals, relics, the Fallen, and region tone.
- [ ] Add a surviving Grimvale town/guild hub with controlled dungeon portals.
- [ ] Add the first multi-map dungeon route using visible physical exits between areas.
- [ ] Connect the route to an Umbral outbreak, fallen settlement, guild assignment, and first relic clue.
- [ ] Add 4 monsters per monster map.
- [ ] Add 1 boss per major region.
- [ ] Add NPCs, quests, item rewards.
- [ ] Add player abilities and skill tree nodes.
- [ ] Validate complete early-game loop.
- [ ] Commit: `Phase 20: First content expansion`.

## Phase 21 — Mobile Export and Release Prep

Goal: prepare for Android/iOS.

- [ ] Test mobile resolution and scaling.
- [ ] Test virtual controls.
- [ ] Optimize sprites and particles.
- [ ] Configure Android export.
- [ ] Configure iOS export if needed.
- [ ] Test performance.
- [ ] Prepare release checklist.
- [ ] Commit: `Phase 21: Mobile export and release prep`.

---

## 16. Current Integration And Migration Holds

These are known overlaps or prototype conflicts. They are not approval to modify gameplay during documentation-only work; the owning phase must migrate them with tests and an architect handoff.

1. **Placeholder branding:** `project.godot` and the active title screen still use `2D RPG Adventure` rather than the approved project title and three-button flow.
2. **Character/menu duplication:** the current Character screen contains an inventory tab and script-local placeholder skill list while standalone Inventory and Skill Tree screens also exist.
3. **Quest UI overlap:** the current `quest_book` scene is an NPC offer/turn-in view, not the required global categorized Quest Journal.
4. **Pause/settings gap:** the HUD toggles pause directly; there is no pause menu, modal coordinator, settings UI, or independent settings persistence.
5. **Save migration:** current saves use numbered `slot_1.json`; the character-ID index/autosave model and atomic migration are not implemented.
6. **Hardcoded flow destinations:** title and death scripts still reference town IDs/positions directly instead of `data/game_flow.json` or map metadata.
7. **Death contract conflict:** current player death removes gold even though v1 requires no gold, XP, or item penalty.
8. **Competing damage paths:** hitbox, hurtbox, `EffectRouter`, status ticks, monster scripts, and damage-number scenes currently calculate or present damage through multiple paths.
9. **Prototype damage types/effects:** current ability data includes fire, dark, arcane, acid, buff, debuff, shield, lifesteal, slow, and stun behavior that must be mapped, deferred, or migrated to the approved v1 contract.
10. **Feedback overlap:** damage numbers can be spawned by hurtbox, monster, hitbox, and legacy effect helpers; Phase 16 must establish one owner and enforce mobile caps.
11. **Class readiness:** Ranger and Mage currently have prototype stats/assets but are not approved playable v1 classes until their basic attacks, abilities, skill trees, equipment paths, and validation are complete.
12. **Legacy map/content debt:** retain the active/legacy lifecycle and runtime-painted-map holds recorded in [content_overlap_audit.md](docs/content_overlap_audit.md).

## 17. Legacy File Status

The following files are now **old/reference only** and should not be used as active implementation specs:

```text
godot-rpg-implementation-plan.md
README.md
RPG_GODOT_WORLD_AND_MAP_SYSTEM_SPEC.md
RPG_AGENT_SPEC.md
RPG_PLAYER_SYSTEM_SPEC.md
RPG_COMBAT_AND_ABILITY_ENGINE_SPEC.md
```

Useful parts have been folded into this master spec:

- Phase-based implementation order from `godot-rpg-implementation-plan.md`
- Project overview and folder additions from `README.md`
- Map scene contract and metadata ideas from `RPG_GODOT_WORLD_AND_MAP_SYSTEM_SPEC.md`
- Agent-safe data-driven principles from `RPG_AGENT_SPEC.md`
- Player stat/save checklist from `RPG_PLAYER_SYSTEM_SPEC.md`
- Ability/effect ideas from `RPG_COMBAT_AND_ABILITY_ENGINE_SPEC.md`

Conflicting parts intentionally removed:

- Python folder structure
- Python model classes
- Turn-based combat flow
- Turn-based cooldowns
- Legacy `TileMap`-only map architecture
- Fully JSON-generated map-first workflow

---

## 18. Final Source-of-Truth Rule

When there is a conflict between files:

```text
Main_ChatGPT-Godot_RPG_Implementation_Plan.md wins.
```
