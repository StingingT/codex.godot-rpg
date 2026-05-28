# Main ChatGPT-Godot RPG Implementation Plan

**Status:** ACTIVE MASTER SPEC  
**Engine:** Godot 4.3+  
**Language:** GDScript  
**Game type:** 2D top-down real-time action RPG  
**Map style:** Hand-authored `.tscn` maps using `TileMapLayer`  
**Primary rule:** This file replaces the older split specs. Older files are legacy/reference only.

---

## 0. Instructions for ChatGPT / Claude Code / Implementation Agents

You are building a 2D top-down RPG in **Godot 4.3+** using **GDScript**.

Work through the phases sequentially. Do not skip ahead. After completing each task, validate the project in Godot before marking the task done.

### Agent rules

1. Use this file as the source of truth.
2. Treat all older markdown files as legacy notes only.
3. Use **real-time combat**, not old combat flow.
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

---

## 1. Game Vision

The game is a **mobile-friendly 2D top-down RPG** with free movement, monster-spawn maps, Pokémon-like map readability, and action-RPG combat inspired by games like Path of Exile.

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

---

## 2. Active Project Structure

Use this folder structure.

```text
res://
├── assets/
│   ├── sprites/
│   │   ├── player/
│   │   ├── monsters/
│   │   ├── weapons/
│   │   ├── clothes/
│   │   ├── npcs/
│   │   └── ui/
│   ├── tilesets/
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
│   ├── quests/
│   ├── dialogue/
│   ├── maps/
│   ├── encounters/
│   ├── monsters/
│   ├── abilities/
│   └── skilltrees/
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
| SupabaseClient | `scripts/autoload/supabase_client.gd` | Optional cloud saves/backend |
| IAPManager | `scripts/autoload/iap_manager.gd` | Optional RevenueCat integration |

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

### Recommended map metadata file

`res://data/maps/maps.json`

```json
{
  "forest_01": {
    "scene": "res://scenes/maps/map_forest_01.tscn",
    "display_name": "Whispering Forest",
    "biome": "forest",
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

Use a player hitbox scene.

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

### Basic damage formula

Use this simple starting formula:

```gdscript
damage = max(attacker.attack - defender.defense, 1)
```

Later this can expand to:

```gdscript
damage = max(base_power + attacker.attack - defender.defense, 1)
```

### Damage package

Pass damage using a dictionary or small class/resource-like structure:

```gdscript
{
    "source": attacker,
    "amount": damage,
    "damage_type": "physical",
    "knockback": Vector2.ZERO,
    "can_crit": true,
    "status_effects": []
}
```

---

## 9. Ability System

Abilities are real-time skills with mana costs, cooldowns in seconds, optional cast time, hitboxes, projectiles, or area effects.

### Ability data example

`res://data/abilities/abilities.json`

```json
{
  "fireball": {
    "name": "Fireball",
    "description": "Launches a fire projectile.",
    "mana_cost": 10,
    "cooldown_seconds": 3.0,
    "cast_time_seconds": 0.2,
    "ability_type": "projectile",
    "scene": "res://scenes/effects/fireball_projectile.tscn",
    "range": 160,
    "effects": [
      { "type": "damage", "amount": 30, "damage_type": "fire" },
      { "type": "dot", "amount": 4, "duration_seconds": 3.0, "tick_interval": 1.0 }
    ]
  }
}
```

### Supported real-time effect types

```text
damage
heal
dot
hot
buff
debuff
shield
lifesteal
slow
stun
knockback
```

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

### Cooldowns

Cooldowns are time-based in seconds.

```gdscript
current_cooldown_seconds = max(current_cooldown_seconds - delta, 0.0)
```

---

## 10. Monster System

Monsters are Godot scenes using real-time AI.

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
    "scene": "res://scenes/monsters/slime_green.tscn",
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

---

## 11. Inventory, Items, and Equipment

### Item pickup scene

```text
scenes/items/item_pickup.tscn
└── ItemPickup : Area2D
    ├── Sprite2D
    ├── CollisionShape2D
    └── pickup_component.gd
```

### Item data example

`res://data/items/items.json`

```json
{
  "health_potion_small": {
    "name": "Small Health Potion",
    "type": "consumable",
    "stack_size": 20,
    "icon": "res://assets/sprites/ui/items/health_potion_small.png",
    "effects": [
      { "type": "heal", "amount": 25 }
    ]
  },
  "training_sword": {
    "name": "Training Sword",
    "type": "weapon",
    "slot": "weapon",
    "attack_bonus": 3,
    "icon": "res://assets/sprites/weapons/training_sword.png"
  }
}
```

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
Top-right: settings / pause button
```

Initial desktop controls still need to work.

| Action | Input |
|---|---|
| Move | WASD / Arrow keys |
| Interact | E / Space |
| Attack | J / Left Click |
| Ability 1-4 | 1 / 2 / 3 / 4 |
| Inventory | I / Tab |
| Quest Log | L |
| Pause | Escape / P |

---

## 14. Save/Load

Local save data should be JSON-serializable.

Save data should include:

```text
save_version
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
settings
```

Use `SaveManager` for local save/load. Supabase cloud saves can be added later.

---

## 15. Implementation Phases

## Phase 0 — Project Setup & Repository

Goal: empty Godot project, version control, folder structure, and basic settings.

- [ ] Initialize git repository.
- [ ] Create Godot 4.3+ project.
- [ ] Set display resolution to 640×360.
- [ ] Set stretch mode to `canvas_items`, aspect `keep`.
- [ ] Use 2D mobile-compatible rendering settings.
- [ ] Add input actions: `move_up`, `move_down`, `move_left`, `move_right`, `interact`, `attack`, `ability_1`, `ability_2`, `ability_3`, `ability_4`, `open_inventory`, `open_quest_log`, `pause`.
- [ ] Create the active folder structure from this document.
- [ ] Create `.gitignore` for Godot.
- [ ] Create placeholder `main.tscn` with a `Node2D` root and label.
- [ ] Validate project opens without errors.
- [ ] Commit: `Phase 0: Project setup and folder structure`.

## Phase 1 — Placeholder Sprites, Tileset, and First Hand-authored Map

Goal: simple visible map using `TileMapLayer`.

- [ ] Create placeholder sprites for player, slime, skeleton, sword, shield, villager, and UI icons.
- [ ] Create a placeholder overworld tileset image.
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
- [ ] Create slime idle/bounce animation.
- [ ] Create `monster_base.tscn`.
- [ ] Validate animations.
- [ ] Commit: `Phase 3: Sprite animation`.

## Phase 4 — Components: Stats, Hurtbox, Hitbox

Goal: reusable real-time combat components.

- [ ] Create `stats_component.gd`.
- [ ] Create `hurtbox_component.gd`.
- [ ] Create `hitbox_component.gd`.
- [ ] Define damage package format.
- [ ] Add hurtbox to player and monster.
- [ ] Add debug hitbox scene.
- [ ] Validate damage can be passed from hitbox to hurtbox.
- [ ] Commit: `Phase 4: Combat components`.

## Phase 5 — Real-time Basic Combat

Goal: player can attack monsters in real time.

- [ ] Add attack input.
- [ ] Add attack state or attack lockout timer.
- [ ] Spawn or enable melee hitbox from `AttackOrigin`.
- [ ] Apply damage formula.
- [ ] Add damage numbers.
- [ ] Add knockback.
- [ ] Add monster death and reward event.
- [ ] Validate player can kill a slime.
- [ ] Commit: `Phase 5: Real-time basic combat`.

## Phase 6 — Monster AI

Goal: monsters roam and attack in real time.

- [ ] Create monster state machine.
- [ ] Add idle, wander, chase, attack, hit_stun, death states.
- [ ] Add detection and attack areas.
- [ ] Add monster hitbox for attacks.
- [ ] Validate monster chases and damages player.
- [ ] Commit: `Phase 6: Monster AI`.

## Phase 7 — Ability System

Goal: real-time skills with cooldowns and mana.

- [ ] Create ability data format.
- [ ] Create `AbilityManager`.
- [ ] Add cooldown tracking in seconds.
- [ ] Add mana spending.
- [ ] Add one projectile ability.
- [ ] Add one area ability.
- [ ] Add one buff/debuff or DOT effect.
- [ ] Add ability buttons to HUD.
- [ ] Validate abilities work during real-time combat.
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
- [ ] Add quest log UI.
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

Goal: preserve progress.

- [ ] Create `SaveManager`.
- [ ] Serialize player state.
- [ ] Serialize inventory/equipment.
- [ ] Serialize quest state.
- [ ] Serialize current map and position.
- [ ] Add save/load UI buttons.
- [ ] Validate save, quit, reload, continue.
- [ ] Commit: `Phase 14: Save and load`.

## Phase 15 — Menus and Settings

Goal: title screen, pause menu, settings.

- [ ] Create title screen.
- [ ] Create pause menu.
- [ ] Create settings menu.
- [ ] Add audio sliders.
- [ ] Add screen shake toggle.
- [ ] Set title screen as main scene.
- [ ] Validate new game and continue flow.
- [ ] Commit: `Phase 15: Menus and settings`.

## Phase 16 — Audio and Feedback

Goal: game feel.

- [ ] Add SFX for attack, hit, death, pickup, dialogue, UI.
- [ ] Add map music.
- [ ] Add AudioManager.
- [ ] Add hit flash.
- [ ] Add screen shake.
- [ ] Add simple particles.
- [ ] Validate feedback and audio settings.
- [ ] Commit: `Phase 16: Audio and feedback`.

## Phase 17 — Shops, Economy, and Progression

Goal: gold has purpose.

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

- [ ] Add town map.
- [ ] Add first monster field.
- [ ] Add cave or dungeon.
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

## 16. Legacy File Status

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

## 17. Final Source-of-Truth Rule

When there is a conflict between files:

```text
Main_ChatGPT-Godot_RPG_Implementation_Plan.md wins.
```

