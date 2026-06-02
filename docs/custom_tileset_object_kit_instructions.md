# Custom Tileset And Object Kit Instructions

This document defines the working standard for creating our own 2D RPG tileset and object kit for the Godot project. It is a draft until reviewed and finalized.

## Goal

Create a reusable custom map-building kit that fits how this game is implemented.

The kit should make maps easier to build, test, expand, and fix than the current image-background approach. Trees, buildings, water, cliffs, walls, portals, and important props should be real reusable tiles or scene objects with clear collision rules.

## Main Problems This Kit Should Solve

- Maps should not be one flat background image with rough collision rectangles on top.
- Water should always be blocked unless we intentionally add bridges, docks, shallow crossings, or swimming later.
- Buildings, trees, cliffs, walls, rocks, wells, fences, and ruins should be objects or tiles with predictable collision.
- Spawn points should always be placed on walkable ground.
- Portal positions should always be visible, reachable, and far enough from collision that the player cannot get trapped.
- Maps should look like believable places, not random tiles scattered over grass.
- New maps should be faster to make because the same pieces can be reused.

## Visual Style

Use a top-down or slightly top-down RPG style.

Keep the art readable at the current camera zoom. The player, NPCs, enemies, doors, paths, portals, and loot should be easy to identify without zooming in.

The style should be simple enough that we can produce many tiles and objects consistently. Prefer clean shapes, readable silhouettes, and limited detail over overly complex art that is hard to reuse.

Recommended style rules:

- Use a consistent pixel-art resolution.
- Use one perspective across all tiles and objects.
- Use consistent light direction, preferably upper-left.
- Use consistent shadow direction and opacity.
- Keep object outlines and contrast consistent.
- Make walkable areas visually clear.
- Make blocked areas visually obvious.
- Avoid using decorative clutter that looks interactable when it is not.

## Technical Targets

Recommended base tile size: `32x32`.

Recommended map size for current prototype maps: `640x360`, equivalent to `20x11.25` tiles at `32x32`. Because that is not a clean tile grid vertically, future handmade maps should use cleaner dimensions such as:

- `640x384` for `20x12` tiles.
- `768x432` for `24x13.5` tiles only if needed.
- `960x540` for larger maps later.

Preferred Godot version: Godot `4.3` or newer.

Use `TileMapLayer` nodes, not the older single `TileMap` node.

## Folder Structure

Use this structure for custom art and scene pieces:

```text
assets/
  tilesets/
    custom/
      rpg_ground_tiles.png
      rpg_environment_tiles.png
      rpg_building_tiles.png
      rpg_object_tiles.png
      rpg_tileset.tres
  objects/
    trees/
      oak_tree.tscn
      pine_tree.tscn
    buildings/
      town_house_small.tscn
      town_house_large.tscn
      blacksmith.tscn
    props/
      well.tscn
      barrel.tscn
      crate.tscn
      signpost.tscn
    portals/
      back_portal.tscn
      next_portal.tscn
scenes/
  maps/
    map_name.tscn
docs/
  custom_tileset_object_kit_instructions.md
```

## Tileset Files

Split tiles into logical sheets instead of one huge sheet.

### Ground Tiles

File: `assets/tilesets/custom/rpg_ground_tiles.png`

Include:

- Grass.
- Dark grass.
- Dirt.
- Mud.
- Sand.
- Stone road.
- Cobblestone.
- Dungeon floor.
- Cave floor.
- Snow or dry grass later if needed.

Ground tiles should usually have no collision.

### Terrain Edge Tiles

File: `assets/tilesets/custom/rpg_environment_tiles.png`

Include:

- Water center.
- Water edges.
- Water corners.
- River edges.
- Cliff tops.
- Cliff sides.
- Dirt-to-grass transitions.
- Mud-to-grass transitions.
- Stone road borders.
- Bridge approach tiles.

Water and cliff side tiles should have collision.

### Building Tiles

File: `assets/tilesets/custom/rpg_building_tiles.png`

Include:

- Walls.
- Roof pieces.
- Doors.
- Windows.
- Chimneys.
- Stairs.
- Stone tower pieces.
- Ruin wall pieces.

Building walls and roofs should have collision. Doors should only block if the building cannot be entered.

### Object Tiles

File: `assets/tilesets/custom/rpg_object_tiles.png`

Include small static props:

- Flowers.
- Grass tufts.
- Small stones.
- Path markers.
- Broken boards.
- Small bushes.
- Fence segments.
- Small signs.

Small decorative ground props usually should not have collision unless they visibly block movement.

## Scene Objects

Use scene objects for anything larger than one or two tiles, anything that needs y-sorting, or anything that might later become interactive.

Examples:

- Trees.
- Large rocks.
- Houses.
- Blacksmith building.
- Wells.
- Large fences.
- Bridges.
- Doors.
- Portals.
- Quest objects.
- Harvest nodes.
- Chests.

Each object scene should have:

- Root node: `Node2D` or `StaticBody2D`, depending on whether it only blocks movement.
- Visual: `Sprite2D` or `AnimatedSprite2D`.
- Collision: `StaticBody2D` plus `CollisionShape2D` or `CollisionPolygon2D`.
- Optional marker nodes for interaction points.

Example object scene:

```text
OakTree.tscn
  Node2D
    Sprite2D
    StaticBody2D
      CollisionShape2D
```

Do not scale collision shape nodes. Resize the shape resource itself.

## Collision Rules

Use consistent physics layers.

Recommended world collision setup:

```text
Layer 1: Player
Layer 2: World
Layer 3: Monsters
Layer 6: Interaction
Layer 7: Player Hitbox
Layer 8: Hurtbox
```

World-blocking objects should use:

```text
collision_layer = 2
collision_mask = 0
```

The player should detect world collision through its collision mask.

Water:

- Deep water is always blocked.
- River water is blocked except at bridge tiles.
- Marsh water is blocked except on raised paths, islands, docks, or bridges.
- If shallow water is added later, it must be a separate tile type with custom data.

Trees:

- Collision should cover the trunk and lower canopy only.
- The upper canopy may visually overlap the player if y-sorting is correct.
- The player should not collide with empty transparent pixels around the tree.

Buildings:

- Collision should cover walls, roof body, and closed doors.
- NPCs should stand in front of the building on walkable tiles.
- Doors should be visually aligned with walkable paths.

Props:

- Barrels, crates, wells, fences, large rocks, and ruins block movement.
- Flowers, grass tufts, small stones, and path dirt do not block movement.

Portals:

- Portal Area2D collision should be interaction only, not world-blocking.
- Portals should never be placed inside world collision.
- The destination entry marker should not overlap world collision.

## TileMapLayer Structure For Maps

Each handmade map should use this node structure:

```text
MapName
  GroundLayer          TileMapLayer
  TerrainLayer         TileMapLayer
  RoadLayer            TileMapLayer
  ObjectTileLayer      TileMapLayer
  YSortedObjects       Node2D
  WorldCollision       StaticBody2D
  EntryPoints          Node2D
  SpawnPoints          Node2D
  Portals              Node2D
  Items                Node2D
  CameraLimits         ReferenceRect
  Player               Player instance
  HUD                  HUD instance
  DialogueBox          DialogueBox instance
  SpawnManager         Node
```

Use tile collision for common terrain blockers like water, cliffs, and walls.

Use object scene collision for large objects like buildings, trees, bridges, towers, and wells.

## Map Layout Rules

Every map should have a clear purpose.

Examples:

- Town: safe hub, shops, quest NPCs, portal square.
- Forest: winding path, dense trees, small clearing.
- River: bridge crossing, water boundaries, enemy patrols.
- Ruins: broken structure, open combat space, visible path.
- Marsh: islands, causeways, blocked water, swamp monsters.
- Cave: enclosed paths, rocks, dark corners.
- Dungeon: stronger enemies, structured rooms.

Avoid random placement. Place objects as if the area was used by people or shaped by nature.

Use these layout questions:

- Where does the player enter?
- Where is the obvious path forward?
- Where is the back portal?
- Where is the next portal?
- Where are enemies likely to patrol?
- What objects tell the story of this area?
- What areas are blocked, and is that visually obvious?

## Monster Map Portal Standard

Every monster map should have two direct portals:

- `BackPortal`
- `NextPortal`

The last map in a route may use:

- `BackPortal`
- `TownPortal`

Portals should use direct map targets, not a map selector.

Example:

```gdscript
target_map = "watchtower_ruins"
target_entry = "entry_west"
portal_name = "Next"
```

Back and Next portals should be placed on walkable ground, at least `24` pixels away from blocking collision.

Do not spawn the player directly on the map edge.

## Entry Point Rules

Every map should have these markers:

```text
entry_default
entry_west
entry_east
entry_north
entry_south
```

All entry points must be on walkable ground.

Entry points should not overlap:

- World collision.
- Water.
- Trees.
- Buildings.
- Props.
- Monster spawn points.
- Portals.

Recommended spacing:

- At least `24` pixels from world collision.
- At least `32` pixels from enemy spawn points.
- At least `24` pixels from portal center, unless intentionally spawning near a portal.

## Spawn Point Rules

Monster spawn points should:

- Be on walkable ground.
- Be away from entry points.
- Be away from portals.
- Be spread around combat areas.
- Avoid spawning inside narrow corridors unless intended.

Boss spawn points should:

- Be obvious in the map layout.
- Have enough room around them for movement.
- Not block the route to the next portal.

## Custom Data Layers

The custom TileSet should include custom data where useful.

Recommended tile custom data:

```text
terrain_type: String
is_walkable: bool
is_water: bool
is_damage_tile: bool
footstep_sound: String
movement_modifier: float
```

Examples:

```text
grass:
  terrain_type = "grass"
  is_walkable = true
  is_water = false
  movement_modifier = 1.0

deep_water:
  terrain_type = "water"
  is_walkable = false
  is_water = true
  movement_modifier = 0.0

mud:
  terrain_type = "mud"
  is_walkable = true
  is_water = false
  movement_modifier = 0.8
```

Do not query tile custom data every frame in `_physics_process`. If gameplay uses tile metadata frequently, cache it.

## Y-Sorting Rules

Use y-sorting for objects that the player can walk in front of or behind.

Good y-sorted objects:

- Trees.
- Tall rocks.
- Buildings with visible lower walls.
- Signposts.
- NPCs.
- Monsters.

Set the object origin near the bottom center where it touches the ground.

The visual sprite may extend upward, but collision should sit near the lower blocking area.

## Art Production Checklist

For every new tile or object:

- It matches the base tile size.
- It uses the same perspective.
- It uses the same palette style.
- It has readable contrast.
- It has a clear walkable or blocked meaning.
- It has transparent background if it is an object.
- It is named clearly.
- It has collision if needed.
- It has been tested in a small scene.

## Required First Kit

Start small. The first custom kit should include only what is needed to build the core route.

### Ground

- Grass.
- Dirt path.
- Stone path.
- Mud.
- Cave floor.
- Dungeon floor.

### Water And Terrain

- Deep water.
- River edge.
- Marsh water.
- Dirt-to-grass edge.
- Cliff wall.

### Objects

- Small tree.
- Large tree.
- Bush.
- Rock.
- Fence.
- Well.
- Crate.
- Barrel.
- Signpost.
- Bridge.

### Buildings

- Small house.
- Larger house.
- Shop front.
- Blacksmith.
- Stone tower.
- Ruined wall.

### Gameplay Markers

- Back portal.
- Next portal.
- Town portal.
- Quest marker.
- Enemy spawn marker visual for editor use.
- Boss spawn marker visual for editor use.

## Map-Building Workflow

Use this workflow for every new handmade map:

1. Define the map purpose.
2. Sketch the route: back entrance, main path, combat area, next exit.
3. Paint ground tiles.
4. Paint roads and paths.
5. Add water, cliffs, walls, or other blocked terrain.
6. Add large objects: buildings, trees, bridges, ruins.
7. Add smaller props.
8. Add world collision or verify tile/object collision.
9. Add entry markers.
10. Add Back and Next portals.
11. Add monster spawn markers.
12. Add boss marker if needed.
13. Add map data in `data/maps/maps.json`.
14. Add encounter data in `data/encounters/encounters.json`.
15. Add quest data if the map introduces a quest.
16. Add the scene to `tools/validate_scenes.gd`.
17. Run validation.
18. Smoke test the map.

## Quest Standard For New Maps

Every new monster map should usually get one matching quest.

Quest requirements:

- Quest ID uses snake_case.
- Quest target uses monster IDs from `data/monsters/monsters.json`.
- Prerequisites follow the current route order.
- Rewards scale with difficulty.
- Objective is clear and testable.

Example:

```json
{
  "quest_id": "clear_watchtower_ruins",
  "quest_name": "Clear the Watchtower Ruins",
  "description": "Skeletons have taken over the ruined watchtower. Defeat 4 skeletons and return to the Quest Giver.",
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

Before a map is considered usable:

- Scene loads in Godot.
- Player spawns inside the map.
- Every entry marker is clear of collision.
- Back portal works.
- Next portal works.
- Player cannot walk through water.
- Player cannot walk through buildings.
- Player cannot walk through tree trunks.
- Player cannot walk through cliffs or walls.
- Player can cross bridges.
- Player can reach NPCs.
- Player can reach all portals.
- Enemies do not spawn inside blockers.
- Boss does not spawn inside blockers.
- Map is included in `tools/validate_scenes.gd`.
- Map is registered in `data/maps/maps.json`.
- Encounter table exists.
- Quest exists if the map adds progression content.

## Naming Rules

Use snake_case for files and IDs.

Examples:

```text
small_oak_tree.tscn
stone_bridge.tscn
town_house_small.tscn
mud_path_tiles.png
sunken_marsh.tscn
cleanse_sunken_marsh.json
```

Use readable node names in scenes.

Examples:

```text
BackPortal
NextPortal
EntryPoints
SpawnPoints
WorldCollision
YSortedObjects
LargeOakTree
BlacksmithBuilding
```

## Implementation Rule

After this document is finalized, new maps should prefer the custom kit over generated flat background images.

Generated background maps may still be used temporarily for prototypes, but they should not become the long-term map-building standard.

## Open Decisions

These choices still need review:

- Final tile size: `16x16`, `24x24`, or `32x32`.
- Final camera zoom target.
- Final map dimensions.
- Whether buildings can be entered in the first version.
- Whether water is always blocked or shallow water becomes walkable later.
- Whether trees are TileMap tiles, object scenes, or both.
- Whether bridges are TileMap terrain pieces or object scenes.
- Whether we make the first kit by drawing manually, using generated images as references, or mixing both.

## First Implementation Milestone

The first milestone should be a small playable test map built only from the custom kit.

It should include:

- Grass.
- Dirt path.
- Water with blocked collision.
- One bridge.
- Two trees.
- One building.
- One Back portal.
- One Next portal.
- One monster spawn point.
- One safe entry point.

This test map should prove the custom kit works before replacing existing maps.
