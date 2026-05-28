# Godot RPG Prototype

**Status:** cleaned Main-spec prototype aligned to `Main_ChatGPT-Godot_RPG_Implementation_Plan.md`.

This project is a Godot 4.3+ top-down 2D real-time action RPG prototype. The active architecture follows the Main implementation plan:

- Godot scenes + GDScript
- Real-time combat only
- `TileMapLayer` hand-authored `.tscn` maps
- JSON metadata for maps, encounters, monsters, items, quests, dialogue, and abilities
- Component-driven combat using stats, hitbox, hurtbox, status effects, and effect routing

## Active source of truth

Use `Main_ChatGPT-Godot_RPG_Implementation_Plan.md` as the build plan.

Older Python-style model/engine files and old combat files have been removed from this package. The reusable ideas were rewritten into the active Godot structure:

- `scripts/autoload/data_registry.gd`
- `scripts/autoload/ability_manager.gd`
- `scripts/combat/effect_router.gd`
- `scripts/components/status_effect_component.gd`
- `scripts/world/spawn_manager.gd`
- `scripts/world/map_transition.gd`

## Data layout

```text
res://data/maps/maps.json
res://data/encounters/encounters.json
res://data/monsters/monsters.json
res://data/abilities/abilities.json
```

Ability data uses seconds-based fields such as `cooldown_seconds`, `duration_seconds`, `tick_interval`, and `cast_time_seconds`.

## Map direction

Maps remain hand-authored `.tscn` scenes. Each map now includes the Main-spec structural nodes:

```text
GroundLayer
DecorLayer
CollisionLayer
OverlayLayer
EntryPoints
ExitTriggers
SpawnPoints
BossSpawnPoint
NPCs
Items
CameraLimits
```

## Current limitations

This is still a prototype. It has not been validated inside the Godot editor in this environment. Open it in Godot and validate one phase at a time before continuing implementation.
