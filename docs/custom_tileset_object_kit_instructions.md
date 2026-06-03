# Custom Tileset And Object Kit Instructions

**Status:** Active agent guide for custom map kit work.

**Related docs:** [Main_ChatGPT-Godot_RPG_Implementation_Plan.md](../Main_ChatGPT-Godot_RPG_Implementation_Plan.md) is the source of truth for autoloads, collision layers, map JSON, encounters, quests, and combat architecture. This document defines how art and map scenes support that vision.

## Design Pillars

This game is a **2D top-down** action RPG that mixes three references. Each reference owns different responsibilities. Do not blur them.

| Reference | Owns in this project | Does *not* belong in tile art |
|-----------|----------------------|-------------------------------|
| **Pokemon** | Top-down camera, tile-grid movement, route-like zone connectivity, biome readability at a glance | Turn-based battles, creature-catching UI |
| **Path of Exile** | Dark/gritty palette everywhere, escalating zone danger, loot-density expectations, grim lore tone, ARPG service hubs (vendor, quest giver, waypoint-style portals) | Isometric camera, full PoE UI clone |
| **Zelda** | Real-time combat spaces, enemy patrol/aggro layout, dungeon room flow, interactable props (chests, barriers, switches), boss arenas | 3D or screen-scroll action |

**Locked choices:**

- **Perspective:** top-down Pokemon/Zelda (not isometric).
- **World palette:** dark Path of Exile mood across all biomes.
- **Readability rule:** world tiles stay top-down and readable. Darkness comes from palette and contrast, not from hiding whether ground is walkable or blocked.

## Goal

Create a reusable custom map-building kit that fits how this game is implemented and supports the design pillars above.

The kit should make maps easier to build, test, expand, and fix than the current flat `Background` image plus manual `RectangleShape2D` blockers. Trees, buildings, water, cliffs, walls, portals, chests, and service hubs should be real reusable tiles or scene objects with clear collision and interaction rules.

Specifically, the kit must support:

- A **connected overworld route** (Pokemon-style graph) painted with **dark PoE biomes** (corrupted grass, ash roads, bone cobble, void water).
- **Zelda-shaped combat maps**: entry → safe lane → arena → boss pocket → exit, with clear sight lines for real-time hitboxes (monsters use ~80px detection and ~20px attack range in `scripts/monsters/monster_base.gd`).
- **PoE-shaped progression hooks** in metadata: encounter tables, quest chains, zone tier — defined in the Main plan, not duplicated here.

## Main Problems This Kit Should Solve

- Maps should not be one flat background image with rough collision rectangles on top.
- Water should always be blocked unless we intentionally add bridges, docks, shallow crossings, or swimming later.
- Buildings, trees, cliffs, walls, rocks, wells, fences, and ruins should be objects or tiles with predictable collision.
- Spawn points should always be placed on walkable ground in **open combat arenas**, not narrow Zelda chokepoints where knockback or projectiles break.
- Portal positions should always be visible, reachable, and far enough from collision that the player cannot get trapped.
- Maps should look like believable places with a grim PoE mood, not random dark tiles scattered without a route.
- Town hubs need a clear **service cluster** (shop, quest giver, waypoint portals) — not spread randomly.
- Decor must not look interactable when it is not (common failure when everything is dark).
- New maps should be faster to make because the same pieces can be reused across routes and zone tiers.

## Visual Style

### Perspective and clarity

Use a consistent **top-down** pixel-art perspective (Pokemon route legibility, Zelda dungeon clarity). Keep art readable at the current camera zoom. The player, NPCs, enemies, doors, paths, portals, chests, and loot must be easy to identify without zooming in.

Touchstones in prose only (do not copy assets): *Link's Awakening* shape clarity, *Path of Exile* zone mood, *Pokemon* route legibility.

### Palette (dark everywhere)

Base tones across all biomes:

- Desaturated corrupted greens and cold grays for overworld.
- Ember accents and dried blood highlights for danger and interactables.
- Sickly marsh greens and murky browns for wetlands.
- Cold blue-gray stone for caves and dungeons.
- Void or ink-black water with subtle edge highlights.

Avoid cheerful Pokemon pastels. Darkness is atmospheric, not an excuse to obscure gameplay.

### Contrast rules (readability)

- **Walkable paths:** lighter value, clear edging, or worn track marks so routes read instantly.
- **Blockers:** darker, harder silhouettes (water, cliffs, walls, trunks).
- **Interactables:** consistent highlight treatment (warm rim, rune glyph, or ember glow) so chests, doors, and portals pop against PoE darkness.
- **Decor:** lower contrast than paths; never use the interactable highlight on non-interactive clutter.

### Silhouette priority (draw order of importance)

1. Player
2. Enemies
3. Portals and exits
4. Interactables (chests, doors, shrines)
5. Paths and walkable ground
6. Non-interactive decor

### Production rules

- Use a consistent pixel-art resolution and one perspective across all tiles and objects.
- Use consistent light direction, preferably upper-left.
- Use consistent shadow direction and opacity.
- Keep object outlines and contrast consistent within a biome sheet.
- Prefer clean shapes and readable silhouettes over dense detail that does not tile well.
- Make walkable areas visually clear and blocked areas visually obvious.

## Technical Targets

Recommended base tile size: `32x32`.

Recommended map size for current prototype maps: `640x360`, equivalent to `20x11.25` tiles at `32x32`. Because that is not a clean tile grid vertically, future handmade maps should use cleaner dimensions such as:

- `640x384` for `20x12` tiles.
- `768x432` for `24x13.5` tiles only if needed.
- `960x540` for larger maps later.

Preferred Godot version: Godot `4.3` or newer.

Use `TileMapLayer` nodes, not the older single `TileMap` node.

## Relationship To Main Implementation Plan

When this document and the Main plan disagree on **systems** (autoloads, JSON paths, collision layer indices, map scene contract), follow the Main plan.

When the Main plan is silent on **art and layout taste** (palette, hub layout, combat arena size, interactable visuals), follow this document.

| System | Main plan location | Kit responsibility |
|--------|-------------------|-------------------|
| Map metadata, connections, biomes | `data/maps/maps.json` | Biome-specific tile sheets, zone tier decor |
| Encounters, spawn tables | `data/encounters/encounters.json` | Spawn markers, encounter-grass custom data |
| Quests | `scripts/autoload/quest_manager.gd` | Quest NPC placement, turn-in hubs |
| Loot, inventory, equipment | `scripts/inventory/` | Chests, pickups, shop fronts |
| Skills, abilities | `scenes/ui/skill_tree_ui.tscn`, `scripts/autoload/ability_manager.gd` | Not tile art; HUD is separate |
| Real-time combat | `scripts/monsters/monster_base.gd`, hitbox/hurtbox components | Open arenas, y-sorted occluders |

## Folder Structure

Use this structure for custom art and scene pieces:

```text
assets/
  tilesets/
    custom/
      poe_ground_tiles.png
      poe_environment_tiles.png
      poe_building_tiles.png
      poe_object_tiles.png
      poe_route_tiles.png
      rpg_tileset.tres
  objects/
    trees/
      corrupted_oak.tscn
      dead_pine.tscn
    buildings/
      hub_house_small.tscn
      vendor_stall.tscn
      blacksmith.tscn
    props/
      well.tscn
      barrel.tscn
      ritual_circle.tscn
      bone_fence.tscn
    interactables/
      chest_closed.tscn
      chest_open.tscn
      breakable_pot.tscn
      dungeon_door.tscn
      barrier_gate.tscn
    portals/
      back_portal.tscn
      next_portal.tscn
      waypoint_portal.tscn
scenes/
  maps/
    map_name.tscn
docs/
  custom_tileset_object_kit_instructions.md
```

Legacy filenames (`rpg_ground_tiles.png`, etc.) may exist during migration; prefer `poe_*` names for new sheets.

## Tileset Files

Split tiles into logical atlas sheets instead of one huge sheet. Terrain, roads, and small props are **layers and atlases**, not separate conflicting map node names (see Map Scene Structure).

### Ground Tiles (PoE biomes)

File: `assets/tilesets/custom/poe_ground_tiles.png`

Include:

- Corrupted grass (light and heavy variants).
- Ash or packed dirt.
- Bone cobble or cracked stone path.
- Mud and sickly marsh floor.
- Cave floor and dungeon flagstone.
- Hub plaza stone (town centers).
- Zone-tier variants (tier 1 clean-ish → tier 5 heavily corrupted).

Ground tiles should usually have no collision.

### Terrain Edge Tiles

File: `assets/tilesets/custom/poe_environment_tiles.png`

Include:

- Void water center, edges, and corners.
- River and marsh water edges.
- Cliff tops and cliff sides.
- Corruption-to-grass transitions.
- Marsh-to-path transitions.
- Bone road borders.
- Bridge approach tiles.

Water and cliff side tiles should have collision.

### Building Tiles

File: `assets/tilesets/custom/poe_building_tiles.png`

Include:

- Grim wall segments.
- Roof pieces.
- Doors and barred windows.
- Chimneys and gargoyle corners.
- Stairs and tower segments.
- Ruin wall and shattered pillar caps.

Building walls and roofs should have collision. Doors should only block if the building cannot be entered in the current version.

### Object Tiles (small decor)

File: `assets/tilesets/custom/poe_object_tiles.png`

Include:

- Withered grass tufts.
- Small bones and stones.
- Broken boards and rubble.
- Bone fence segments.
- Grim signposts (non-interactive).
- Ritual circle floor decals (decor only unless wired later).
- Ember braziers (decor).

Small decorative ground props usually should not have collision unless they visibly block movement.

### Route Tiles (Pokemon-style, non-turn-based)

File: `assets/tilesets/custom/poe_route_tiles.png`

Include:

- Tall encounter grass or corrupted brush (visual danger zones).
- Route border edging tiles.
- Zone entrance markers (town gate, cave mouth frame).
- Path fork markers.

Encounter grass is **visual plus optional custom data** for encounter weighting. It does not trigger turn-based battles.

## Scene Objects

Use scene objects for anything larger than one or two tiles, anything that needs y-sorting, or anything interactive.

### World objects

- Trees (corrupted or dead).
- Large rocks and shattered pillars.
- Houses, vendor stalls, blacksmith.
- Wells, bone fences, bridges.
- Waypoint and route portals.
- Ritual circles (large, optional interaction later).

### Zelda-style interactables

Folder: `assets/objects/interactables/`

| Scene | Purpose | Collision |
|-------|---------|-----------|
| `chest_closed.tscn` / `chest_open.tscn` | Loot container | Interaction layer 6 only when closed; world block optional |
| `breakable_pot.tscn` | Small loot breakable | Optional world block; interaction on break |
| `dungeon_door.tscn` | Blocks until quest/key flag | World layer 2 when closed; data hook via `interaction_id` |
| `barrier_gate.tscn` | Blocks path until event | World layer 2 when closed |
| `pressure_plate.tscn` | Optional v1 stub | Interaction layer 6 |

Behavior (loot tables, quest flags) stays in scripts and JSON — scenes provide visuals, collision, and `interaction_id` for wiring.

Each object scene should have:

- Root: `Node2D` or `StaticBody2D` depending on movement blocking.
- Visual: `Sprite2D` or `AnimatedSprite2D`.
- Collision: `StaticBody2D` with `CollisionShape2D` or `CollisionPolygon2D` when blocking.
- Optional `InteractionArea` : `Area2D` on layer 6 for chests, doors, NPC-facing props.

Example:

```text
CorruptedOak.tscn
  Node2D
    Sprite2D
    StaticBody2D
      CollisionShape2D
```

Do not scale collision shape nodes. Resize the shape resource itself.

## Collision Rules

Use the full collision setup from the Main plan:

| Layer | Name | Used By |
|------:|------|---------|
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

World-blocking objects should use:

```text
collision_layer = 2
collision_mask = 0
```

The player detects world collision through its collision mask.

Interaction-only objects (portals, chests when not blocking, NPC talk zones):

```text
collision_layer = 6
```

Water:

- Deep or void water is always blocked.
- River water is blocked except at bridge tiles.
- Marsh water is blocked except on raised paths, islands, docks, or bridges.
- Shallow water, if added later, must be a separate tile type with custom data.

Trees:

- Collision covers trunk and lower canopy only.
- Upper canopy may overlap the player with correct y-sorting.
- No collision on empty transparent pixels.

Buildings:

- Collision covers walls, roof body, and closed doors.
- NPCs stand on walkable tiles in front of facades.
- Doors align with walkable paths.

Props:

- Barrels, crates, wells, bone fences, large rocks, and ruins block movement unless marked as breakables.
- Decor tufts, small bones, and path decals do not block movement.

Portals:

- Portal `Area2D` uses interaction layer only, not world-blocking.
- Never place portals inside world collision.
- Destination entry markers must not overlap world collision.

## Map Scene Structure

Each handmade map follows the Main plan contract. Terrain/road/object content lives in **TileSet atlases and layers**, not in extra custom node names like `TerrainLayer` or `RoadLayer`.

```text
MapForest01 : Node2D
  y_sort_enabled = true
  GroundLayer          TileMapLayer   # ground + roads (atlas: poe_ground, poe_route)
  DecorLayer           TileMapLayer   # edges, small decor (atlas: poe_environment, poe_object)
  CollisionLayer       TileMapLayer   # blocking terrain collision shapes
  OverlayLayer         TileMapLayer   # optional fog, decals, zone borders
  YSortedObjects       Node2D         # trees, buildings, large props (y-sort)
  EntryPoints          Node2D
    entry_default      Marker2D
    entry_west         Marker2D
    entry_east         Marker2D
    entry_north        Marker2D
    entry_south        Marker2D
  ExitTriggers         Node2D         # Area2D exits if using edge transitions
  SpawnPoints          Node2D
    spawn_01           Marker2D
    spawn_02           Marker2D
    spawn_03           Marker2D
  BossSpawnPoint       Marker2D
  Portals              Node2D         # BackPortal, NextPortal, TownPortal
  NPCs                 Node2D
  Items                Node2D         # chests, pickups placed in scene
  CameraLimits         ReferenceRect
  SpawnManager         Node           # script: spawn_manager.gd
```

Runtime UI (Player, HUD, DialogueBox) may be instanced by map flow or parent scene — not required inside every map file if loaded centrally.

Use tile collision on `CollisionLayer` for water, cliffs, and walls. Use object scene collision for large buildings, trees, bridges, and wells. Place `YSortedObjects` as a sibling under the map root; keep all y-sorted instances as its children.

## Map Layout Templates

Every map has a type. Use the template that matches.

### Town / hub

| Pillar | Layout rule |
|--------|-------------|
| Pokemon | Central plaza, obvious exits N/E/S/W (or clear portal pairs) |
| Path of Exile | Vendor + quest giver cluster, waypoint portal, grim lore signage |
| Zelda | Safe zone — no ambient monster spawns in the hub core |

Place services within one screen of the plaza. Use hub plaza ground tiles. No encounter-grass in the safe core.

### Route / zone (monster map)

| Pillar | Layout rule |
|--------|-------------|
| Pokemon | `BackPortal` → main path → `NextPortal`; readable biome shift |
| Path of Exile | Visual corruption increases toward `NextPortal`; higher `zone_tier` in JSON |
| Zelda | Side pockets for optional fights, chests, or loops; main path stays wide |

Flow: **entry → safe lane → combat pockets → boss or elite pocket → exit**.

### Dungeon / boss

| Pillar | Layout rule |
|--------|-------------|
| Pokemon | Always include `BackPortal`; last route map may add `TownPortal` |
| Path of Exile | Denser encounter table, stronger zone tier, ritual decor |
| Zelda | Room sequence, arena before boss, dodge space, line-of-sight to exit after fight |

Avoid random placement. Place objects as if the area was fought over, corrupted, or abandoned — not as arbitrary tile noise.

Layout questions for every map:

- Where does the player enter?
- Where is the obvious path forward?
- Where are `BackPortal` and `NextPortal`?
- Where do enemies patrol or spawn?
- What objects tell the grim story of this zone?
- What is blocked, and is that obvious in the dark palette?

## Monster Map Portal Standard

Every monster map should have two direct portals:

- `BackPortal`
- `NextPortal`

The last map in a route may use:

- `BackPortal`
- `TownPortal`

Portals should use direct map targets, not a map selector. Waypoint visuals should read as PoE-style travel stones or grim arches — still interaction-only collision.

Example:

```gdscript
target_map = "watchtower_ruins"
target_entry = "entry_west"
portal_name = "Next"
```

Place portals on walkable ground, at least `24` pixels from blocking collision. Do not spawn the player on the map edge.

## Entry Point Rules

Every map should have:

```text
entry_default
entry_west
entry_east
entry_north
entry_south
```

All entry points must be on walkable ground and must not overlap world collision, water, trees, buildings, props, spawn points, or portals.

Recommended spacing:

- At least `24` pixels from world collision.
- At least `32` pixels from enemy spawn points.
- At least `24` pixels from portal center unless intentionally spawning near a portal.

## Spawn Point Rules

### General

Monster spawn points should:

- Be on walkable ground.
- Be away from entry points and portals.
- Be spread through combat areas, not the hub safe core.
- Avoid narrow corridors unless the encounter is designed for it.

Boss spawn points should:

- Sit in an obvious arena (ruins circle, ritual floor, cleared platform).
- Have room to move and kite (see Zelda checklist below).
- Not block the route to `NextPortal` after the fight.

### Zelda combat layout checklist

Tune from `monster_base.gd` detection (~80px) and attack (~20px), plus player abilities:

- Minimum **96×96 px** open walkable floor per regular spawn marker.
- Boss arena: at least **128×128 px** clear floor around `BossSpawnPoint`, or equivalent open ruin courtyard.
- Patrol-friendly loops in side pockets; avoid dead-end corners flush against water or cliffs.
- Line-of-sight from boss arena to main exit path after clearing adds (Zelda pacing).
- Do not place spawns where knockback pushes into water or walls instantly.

## Custom Data Layers

The custom TileSet should include custom data where useful.

Recommended tile custom data:

```text
terrain_type: String
biome: String
zone_tier: int
is_walkable: bool
is_water: bool
is_damage_tile: bool
encounter_weight: float
is_interactable: bool
interaction_id: String
footstep_sound: String
movement_modifier: float
```

Examples:

```text
corrupted_grass:
  terrain_type = "grass"
  biome = "forest"
  zone_tier = 2
  is_walkable = true
  is_water = false
  encounter_weight = 0.2
  movement_modifier = 1.0

encounter_brush:
  terrain_type = "encounter_grass"
  biome = "forest"
  zone_tier = 2
  is_walkable = true
  encounter_weight = 1.5
  movement_modifier = 1.0

void_water:
  terrain_type = "water"
  biome = "marsh"
  zone_tier = 3
  is_walkable = false
  is_water = true
  movement_modifier = 0.0

hub_plaza:
  terrain_type = "stone"
  biome = "town"
  zone_tier = 0
  is_walkable = true
  encounter_weight = 0.0
  movement_modifier = 1.0
```

Do not query tile custom data every frame in `_physics_process`. Cache values when gameplay reads them often.

## Y-Sorting Rules

Enable `y_sort_enabled` on the map root. Use y-sorting for objects the player walks behind or in front of.

Good y-sorted objects:

- Trees.
- Tall rocks and pillars.
- Buildings with visible lower walls.
- Signposts.
- NPCs.
- Monsters.
- Chests and gates (tall sprites).

Set object origin near bottom center at ground contact. Collision sits in the lower blocking region, not on the full sprite height.

## Art Production Checklist

For every new tile or object:

- Matches base tile size.
- Uses top-down perspective consistent with the kit.
- Uses dark PoE palette with readability contrast rules.
- Walkable vs blocked meaning is obvious.
- Interactables use the shared highlight language.
- Transparent background for standalone objects.
- Named clearly in snake_case files.
- Collision assigned correctly (world 2 vs interaction 6).
- Tested in a small sandbox scene.

## Required First Kit

Start small. Build only what the core route needs.

### Ground

- Corrupted grass.
- Ash dirt path.
- Bone cobble path.
- Hub plaza stone.
- Cave floor.
- Dungeon flagstone.

### Water and terrain

- Void water.
- River edge.
- Marsh water.
- Corruption edge.
- Cliff wall.

### Route (Pokemon-style)

- Encounter brush tile.
- Route border edge.
- Zone entrance frame.

### PoE decor (tiles or small objects)

- Ritual circle decal.
- Bone fence segment.
- Shattered pillar (small).

### World objects

- Corrupted tree (small and large).
- Bush or dead thicket.
- Rock.
- Well.
- Crate and barrel.
- Bridge.
- Vendor stall or shop front.
- Hub house.
- Ruined wall segment.

### Interactables (Zelda-style)

- `chest_closed.tscn`
- `breakable_pot.tscn` (optional v1)

### Gameplay markers

- Back portal (waypoint visual).
- Next portal.
- Town portal.
- Enemy spawn marker visual (editor).
- Boss spawn marker visual (editor).

## Map-Building Workflow

1. Define map type: town, route, or dungeon.
2. Set `biome` and `zone_tier` in `data/maps/maps.json`.
3. Sketch flow: entry, safe lane, arenas, boss pocket, exits.
4. Paint `GroundLayer` (ground + paths).
5. Paint `DecorLayer` and `OverlayLayer` (edges, decor, encounter brush).
6. Paint `CollisionLayer` blockers.
7. Instance `YSortedObjects` (trees, buildings, bridge).
8. Place interactables under `Items` or `YSortedObjects`.
9. Verify tile and object collision.
10. Add `EntryPoints` markers.
11. Add `BackPortal` and `NextPortal` (or `TownPortal` on last map).
12. Add `SpawnPoints` and `BossSpawnPoint` using Zelda checklist.
13. Add NPCs for hub services on town maps.
14. Register map in `data/maps/maps.json`.
15. Add `data/encounters/encounters.json` entry.
16. Add quest JSON if the map advances the route.
17. Add scene to `tools/validate_scenes.gd`.
18. Run validation and smoke test combat + portals.

## Quest Standard For New Maps

Every new monster map should usually get one matching quest with grim PoE tone in copy.

Quest requirements:

- Quest ID uses snake_case.
- Targets use monster IDs from `data/monsters/monsters.json`.
- Prerequisites follow current route order.
- Rewards scale with zone tier.
- Objective is clear and testable.

Example:

```json
{
  "quest_id": "clear_watchtower_ruins",
  "quest_name": "Ashes of the Watchtower",
  "description": "The ruined watchtower chokes on bone dust and restless dead. Cut down 4 skeletons and report back before the corruption spreads to the crossing.",
  "level_requirement": 4,
  "prerequisites": ["secure_river_crossing"],
  "objectives": [
    {
      "type": "kill",
      "target": "skeleton",
      "required": 4,
      "current": 0
    }
  ],
  "rewards": {
    "xp": 420,
    "gold": 210,
    "items": []
  },
  "giver": "quest_giver",
  "turn_in": "quest_giver"
}
```

## Validation Checklist

Before a map is usable:

- Scene loads in Godot.
- Player spawns inside the map on walkable ground.
- Every entry marker is clear of collision.
- `BackPortal` and `NextPortal` work (or `TownPortal` on finale).
- Walkable vs blocked reads clearly in dark palette.
- Player cannot walk through water, buildings, or tree trunks.
- Player can cross bridges.
- Hub: vendor and quest NPC reachable; no spawns in safe core.
- Player can reach all portals and chests.
- Enemies do not spawn inside blockers.
- Boss has adequate arena space (Zelda checklist).
- Map in `tools/validate_scenes.gd`.
- Map registered in `data/maps/maps.json` with `biome` and connections.
- Encounter table exists.
- Quest exists if the map adds progression.

## Naming Rules

Use snake_case for files and map IDs.

Examples:

```text
corrupted_oak.tscn
bone_bridge.tscn
vendor_stall.tscn
poe_ground_tiles.png
watchtower_ruins.tscn
ashes_of_the_watchtower.json
```

Use readable PascalCase or descriptive names for scene root nodes and key markers:

```text
MapWatchtowerRuins
BackPortal
NextPortal
EntryPoints
SpawnPoints
BossSpawnPoint
YSortedObjects
```

## Implementation Rule

New maps should prefer this custom kit over flat background images.

Generated or painted background maps may remain temporarily for legacy scenes, but they must not be the long-term standard. Migrate maps to `TileMapLayer` + `YSortedObjects` as the kit becomes available.

## Open Decisions

**Locked:**

- Dark PoE palette for all world biomes.
- Top-down Pokemon/Zelda perspective.

**Still open:**

- Final tile size: `16x16`, `24x24`, or `32x32` (default remains `32x32`).
- Final camera zoom target.
- Final map dimensions for production maps.
- Whether buildings are enterable in v1.
- Shallow water as walkable/slow tile later.
- Trees as tiles, scenes, or both.
- Bridges as terrain tiles vs scene objects.
- Art pipeline: hand-drawn, generated reference, or mixed.
- How literal encounter brush is (pure decor vs spawn weight modifier only).
- Minimum arena size formula tied to longest ability range.
- Single shared hub atlas vs per-town variants.

## First Implementation Milestone

Build one small playable test map using **only** the custom kit.

It must prove town + route + combat flow:

- Hub plaza stone and corrupted grass.
- Ash path connecting entry to portals.
- Void water with blocked collision.
- One bridge.
- Two corrupted trees in `YSortedObjects`.
- One vendor stall or hub house.
- One `chest_closed.tscn`.
- Waypoint-style `BackPortal` and `NextPortal`.
- Three `SpawnPoints` in an open arena plus one `BossSpawnPoint` with Zelda clearance.
- One safe `entry_default`.

Pass validation checklist and one full combat smoke test before replacing legacy background maps.
