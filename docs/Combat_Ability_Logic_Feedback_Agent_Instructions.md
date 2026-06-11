# Combat, Ability Logic & Feedback Agent Instructions

**Status:** Active canonical domain specification  
**Project:** Umbral Explorers: Relics of Grimvale  
**Source of truth:** `Main_ChatGPT-Godot_RPG_Implementation_Plan.md`  
**Agent name:** Combat, Ability Logic & Feedback Agent  
**Scope:** Real-time combat logic, ability behavior, player/enemy attack rules, damage pipeline, death/reset behavior, combat item effects, targeting/aiming, combat feedback, VFX/SFX categories, performance limits, and combat accessibility settings.

---

## Master Plan Integration Locks

- V1 combat is Warrior-only: free Basic Attack plus four ability slots, with Cleave and Charge as the first active abilities.
- Every hit routes through one stateless, scene-independent `DamageCalculator` and one canonical damage package.
- V1 damage types are `physical`, `spell`, `poison`, and `true`.
- During migration, prototype `fire`, `dark`, and `arcane` damage map to `spell`; `acid` maps to `poison`. Preserve their original identity only in feedback tags or content metadata.
- V1 effects are damage, healing, DoT, and knockback. Buff, debuff, shield, lifesteal, slow, and stun remain deferred.
- One combat feedback owner routes damage numbers, hit effects, and status popups. Do not leave parallel feedback paths active.
- V1 has no screen shake or hit-stop.
- Death and Return to Town use `MapManager` with `data/game_flow.json`, reset transient area state, preserve quest progress, and apply no gold, XP, or item penalty.
- Combat work belongs to Main Phases 4-7, death integration to Phase 15D, and feedback/audio to Phase 16.

---

## 0. Core Rules for This Agent

You are redesigning and implementing the combat and ability logic for a Godot 4.3+ real-time action RPG.

Follow these rules:

1. Follow the Main MD as the architecture and phase source of truth.
2. Use Godot 4.3+ and GDScript-compatible designs.
3. Use real-time combat only. Never add turn-based combat.
4. Use `res://` paths.
5. Preserve the existing player, HUD, ability, monster, inventory, save, and map systems unless an architect-approved migration says otherwise.
6. Combat changes must be reviewed by the Lead Architect before merge.
7. Use the architect handoff template and record reviewed results in `docs/agent_integration_log.md`.
8. Do not generate final monster art. Import monster sprites through the sprite manifest pipeline.
9. Do not create a parallel inventory/item architecture. Inventory structure, item storage, generated equipment, and save migration are owned by the Inventory/Itemization spec.
10. This agent may implement how item and equipment stats affect combat, and how combat consumable effects are applied.

---

## 1. Agent Goal

Create and implement combat that supports Grimvale's heroic-mystery readability and darker Umbral regions:

```text
clean ARPG combat feedback
+
roguelike dungeon-run pressure
+
readable top-down Zelda/Pokemon-style clarity
```

The system should make moment-to-moment combat feel satisfying while keeping rules readable on mobile.

The agent owns:

```text
combat damage pipeline
critical hits
defense mitigation
ability costs and cooldowns
basic attacks
first Warrior abilities: Cleave and Charge
future attack patterns for Arrow and Arcane Bolt
player aiming model
enemy attack hitboxes
boss/elite telegraph framework
DoT application and aggregated DoT display
healing effects
combat item effect application
combat VFX/SFX categories
death and dungeon-reset behavior
combat accessibility settings
mobile performance limits
```

The agent does **not** own:

```text
inventory storage model
item save migration
item generation/affixes/loot pity
shop inventory and buyback architecture
monster sprite generation
full Ranger/Mage implementation
full boss fight design
unique items, crafting, upgrades, or set bonuses
```

---

## 2. Combat Feel Direction

Combat should feel like an ARPG with fast readable feedback, but not like a screen-filling particle mess.

Target feel:

```text
- Real-time movement and attacks.
- Basic attacks are always available and do not consume mana.
- Abilities consume mana and use cooldowns in seconds.
- Hits are readable through VFX and SFX, not through camera shake.
- Combat should remain readable at mobile scale.
- Death returns the player to town and resets the current dungeon/run.
```

Do not add screen shake or hit-stop in v1.

Future options may add:

```text
- screen shake for boss/heavy hits
- hit-stop for crits/heavy attacks
- XP or item penalties on death
```

---

## 3. Combat Resource Rules

All classes use mana for now.

```text
Warrior abilities = mana cost
Ranger abilities = mana cost
Mage abilities = mana cost
Basic attacks = free
```

Do not add stamina, rage, focus, or class-specific resource bars in v1.

The design may remain extensible for future class-specific resources, but this agent must not implement them without approval.

---

## 4. Basic Attacks by Class

Current and future class basic attacks:

```text
Warrior = melee swing
Ranger = Arrow projectile
Mage = Arcane Bolt projectile
```

Rules:

```text
- Basic attacks do not consume mana.
- Basic attacks can crit.
- Basic attacks use the normal combat damage pipeline.
- Basic attacks should support aiming.
- Warrior basic attack may hit multiple enemies if its hitbox overlaps them.
- Cleave is not the only multi-target attack; Cleave is a stronger/wider version of the normal Warrior attack.
```

Implementation priority:

```text
v1: Warrior basic attack, Cleave, Charge
future: Arrow and Arcane Bolt when Ranger/Mage are implemented further
```

---

## 5. Ability Slot Rule

Use:

```text
Basic Attack button
+
4 ability slots
```

The HUD already points toward attack + four ability buttons. Do not add extra active skill slots in this combat pass.

Abilities:

```text
- consume mana unless explicitly marked free
- have cooldowns in seconds
- can use hitboxes, projectiles, dash movement, area effects, or DoTs
- are unlocked through ability data and/or the skill tree
```

---

## 6. Aiming and Targeting

### 6.1 PC aiming

For PC:

```text
Attack and abilities aim toward the mouse position.
```

Implementation notes:

```text
- Mouse aim determines direction for melee arcs, dashes, and projectiles.
- If no mouse position is meaningful, fall back to facing direction.
- Aiming must not require clicking directly on an enemy.
```

### 6.2 Mobile aiming

The game is intended to become mobile-first later.

Mobile target direction:

```text
Tap enemy or ground to aim attacks/skills.
```

Mobile combat should be skill-oriented:

```text
- Player can tap an enemy to aim at it.
- Player can tap the ground to aim in that direction.
- The system should not become full auto-combat.
```

### 6.3 Soft targeting / aim assist

Soft targeting is allowed, especially for mobile and controller.

Rules:

```text
- If the player aims near an enemy, the attack may gently correct toward the enemy.
- Aim assist should be subtle and should not remove player skill.
- PC mouse aim may use minimal or no soft targeting unless requested.
- Mobile aim assist may be stronger to compensate for touch controls.
```

Do not add hard auto-targeting in v1 unless explicitly approved.

---

## 7. Damage Pipeline

Replace the old purely linear formula with a clearer extensible damage pipeline.

The old prototype formula:

```gdscript
damage = max(attacker.attack - defender.defense, 1)
```

is too linear for long-term scaling.

### 7.1 Required damage stages

Use this conceptual order:

```text
1. Build attacker offensive value.
2. Select ability/basic attack base power or multiplier.
3. Roll within allowed min/max damage range.
4. Apply attacker modifiers.
5. Apply critical hit roll.
6. Apply defender mitigation using diminishing defense value.
7. Clamp to minimum and maximum output rules.
8. Emit damage package.
9. Hurtbox applies damage and triggers feedback.
```

### 7.2 Class stat scaling boundary

Base attack is calculated from class stats elsewhere.

Expected class scaling direction:

```text
Warrior physical attack = STR-based
Ranger physical attack = DEX-based
Mage spell damage = INT-based
```

This combat agent does not need to redefine the full class stat formula. It must consume the final attacker stats provided by the player/monster/stat systems.

Important:

```text
INT is used for spell damage.
Spell damage should affect magical ability damage.
```

### 7.3 Min/max damage range

Damage should support a range so hits are not always identical.

Example concept:

```gdscript
var rolled_damage := randf_range(min_damage, max_damage)
```

Rules:

```text
- The roll happens before crit and mitigation unless final tuning says otherwise.
- Ability data may define `damage_multiplier`, `base_power`, or both.
- Generated item stats and skill bonuses may modify the min/max or final value.
```

### 7.4 Diminishing defense mitigation

Defense should have diminishing returns.

Design target:

```text
100 defense gives meaningful mitigation.
200 defense gives less than double the value of 100 defense.
```

Required initial v1 formula:

```gdscript
var mitigation_ratio := defense / (defense + 900.0)
var mitigated_damage := rolled_damage * (1.0 - mitigation_ratio)
```

This makes the first 100 defense valuable while preventing defense from scaling linearly forever.

Example behavior:

```text
100 defense ≈ 10% mitigation
200 defense ≈ 18% mitigation
```

Keep the locked initial constant data-driven:

```text
res://data/combat/combat_balance.json
```

Changing the `900.0` soft cap requires a reviewed balance update; agents must not substitute a different mitigation formula during migration.

### 7.5 Minimum and maximum damage output

Every damaging hit must respect:

```text
minimum damage floor
maximum damage clamp, if configured
```

Example:

```gdscript
final_damage = clamp(roundi(mitigated_damage), minimum_damage, maximum_damage)
```

If no maximum is configured, only the minimum floor is required.

Required v1 default:

```text
minimum_damage = 1
```

Bosses and elites may use special clamps later, but not in v1 unless needed.

---

## 8. Critical Hits

Critical hits exist in v1.

Required stats:

```text
crit_chance
crit_damage
```

Rules:

```text
- Basic attacks can crit.
- Abilities can crit if their data allows it.
- Some effects may set `can_crit: false`.
- Critical hit damage uses crit damage multiplier.
- Crit display uses red damage numbers, slightly larger than normal.
```

Required initial defaults:

```text
crit_chance = 0.05
crit_damage = 1.5
```

Store percentages as decimal ratios:

```text
5% = 0.05
150% crit damage = 1.5
```

Do not mix `5`, `0.05`, and `"5%"` in runtime data.

---

## 9. Damage Package

All hits should pass a consistent package through hitbox/hurtbox components.

Required canonical fields:

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

Damage types for now:

```text
physical
spell
poison
true
```

Future damage types may include:

```text
fire
water
lightning
ice
shadow
undead
```

Do not add a full resistance/weakness system in v1 unless requested.

Legacy migration mapping:

```text
fire, dark, arcane -> spell
acid -> poison
```

Use feedback tags such as `fire`, `dark`, `arcane`, or `acid` when their visual identity must remain distinct.

---

## 10. Player Abilities — v1

Implement first:

```text
Basic Attack
Cleave
Charge
```

Define future patterns but do not implement yet:

```text
Arrow
Arcane Bolt
Projectile ability
Area effect
DoT effect
Heal effect
```

Do not implement buff effects in this pass.

---

## 11. Warrior Basic Attack

The Warrior basic attack is a free melee swing.

Rules:

```text
- Uses aiming direction.
- Uses a melee hitbox or arc.
- Can hit multiple enemies if they overlap the hitbox.
- Can crit.
- Has attack lockout / attack speed timing.
- Does not consume mana.
```

Feedback:

```text
- Small particle burst on hit.
- Hit SFX on successful hit.
- Floating damage number.
```

---

## 12. Cleave

Cleave is a stronger and wider Warrior basic attack.

Rules:

```text
- Unlocked through the Warrior skill tree.
- Uses mana.
- Uses a real-time cooldown.
- Uses a wider/larger attack hitbox than basic attack.
- Deals more damage than basic attack.
- Can hit multiple enemies.
- Does not replace the normal attack.
```

Suggested starting values:

```text
damage_multiplier = 1.4
hitbox_scale = 1.4 to 1.7
cooldown_seconds = 3.0
mana_cost = low to medium
can_crit = true
```

Feedback:

```text
- Wider slash arc VFX.
- Slightly stronger hit particle burst.
- Normal damage number rules.
- No screen shake.
- No hit-stop.
```

---

## 13. Charge

Charge is a short dash-forward Warrior attack.

Rules:

```text
- Unlocked through the Warrior skill tree.
- Uses mana.
- Uses a real-time cooldown.
- Player dashes forward in aim direction.
- Enemies in the path take damage.
- Does not pass through walls.
- Stops or slides safely if collision blocks the dash.
- Can be used as mobility and combat initiation.
```

Suggested starting values:

```text
damage_multiplier = 1.1 to 1.3
cooldown_seconds = 5.0
mana_cost = medium
dash_distance = short to medium
can_crit = true
```

Feedback:

```text
- Short dash streak or dust effect.
- Hit particle burst on enemies struck.
- Hit SFX when contact damage is dealt.
- No screen shake.
- No hit-stop.
```

Safety rules:

```text
- Charge must not push the player through water, walls, props, or closed doors.
- Charge must not leave the player stuck inside collision.
- Charge should respect collision layers from the Main MD.
```

---

## 14. Future Basic Attack Patterns

Define now, implement later.

### 14.1 Arrow

Ranger basic attack.

```text
- Projectile basic attack.
- Free; no mana cost.
- Aims toward mouse/tap direction.
- Uses projectile collision.
- Can crit.
- Uses attack speed.
```

### 14.2 Arcane Bolt

Mage basic attack.

```text
- Projectile spell-like basic attack.
- Free; no mana cost.
- Aims toward mouse/tap direction.
- Uses INT/spell-damage path when Mage is implemented.
- Can crit if configured.
```

These are future patterns for Ranger and Mage. Do not implement them before class support is ready unless explicitly requested.

---

## 15. Cooldowns and Mana

Cooldown display in v1:

```text
Dark radial overlay on ability button.
```

Future display:

```text
Radial overlay + number countdown.
```

Rules:

```text
- Cooldowns are in seconds.
- Cooldowns must tick down with delta.
- Ability buttons are visually disabled while on cooldown.
- Basic attack does not use the ability cooldown overlay unless an attack-speed indicator is later added.
```

Insufficient mana feedback:

```text
- Ability button flashes blue.
- Subtle error SFX.
- Small "Not enough mana" text.
- This text can be turned off in settings.
```

Do not spam the text every frame. Use a short cooldown between warning messages.

---

## 16. Potions and Combat Item Effects

This agent owns combat effect application, not inventory storage.

Current consumables:

```text
Health Potion
Mana Potion
```

Potion use in v1:

```text
- Instant.
- No potion cooldown for now.
- May receive a shared cooldown later.
```

Rules:

```text
- Inventory system owns stack removal.
- Combat/effect system owns applying heal/mana restore.
- Health potion should not be consumed if player is already at full HP.
- Mana potion should not be consumed if player is already at full mana.
- Effect application must return success/failure so inventory knows whether to consume the item.
```

Future:

```text
- shared potion cooldown
- cleanse
- town portal/recall
- temporary attack/defense potions
```

---

## 17. Enemy Attack Logic

Regular monsters use attack hitboxes with cooldowns.

v1 rule:

```text
Regular enemies do not use contact damage as the main damage model.
Regular enemies use AttackArea / hitbox timing.
```

Future:

```text
Some monsters may use projectile or skill attacks.
This eventually creates a mixed monster roster.
```

Regular enemy telegraphs:

```text
- No large ground indicator.
- Use animation/wind-up only.
```

Elite/boss telegraphs:

```text
- Clear telegraph for dangerous attacks.
- Ground indicator or obvious wind-up is allowed.
```

---

## 18. Boss and Elite Framework

Create a basic framework, not a full first boss.

Required support:

```text
- wind-up phase
- telegraph phase
- active hitbox/projectile/area phase
- recovery phase
- cooldown before next attack
```

Boss/elite attack pattern structure should support later:

```text
melee slam
projectile burst
area warning
summon adds
phase change
enrage
```

Do not implement a complete boss encounter unless explicitly requested.

---

## 19. Status Effects

v1 status effect:

```text
DoT only
```

Future status effects:

```text
stun
freeze
slow
heal-over-time
buff
debuff
```

Stun/freeze later should use similar timing infrastructure to DoT/status duration but should not be implemented now.

### 19.1 DoT rules

DoT behavior:

```text
- Has total duration.
- Has tick interval.
- Applies periodic damage.
- Can show purple aggregated tick numbers.
```

Important visual rule:

```text
DoT numbers must not display every tiny tick if that becomes spammy.
Aggregate DoT damage over a short window, for example one second, then show one summed purple number.
```

The exact aggregation window can be tuned later.

Suggested data:

```gdscript
{
    "effect_id": "poison_dot",
    "type": "dot",
    "damage_type": "poison",
    "amount_per_tick": 3,
    "duration_seconds": 4.0,
    "tick_interval": 0.5,
    "display_aggregation_seconds": 1.0
}
```

Future UI:

```text
Small debuff icon above health bar or near enemy HP bar.
```

Not required in v1.

---

## 20. Death and Dungeon Reset

Death behavior for v1:

```text
Player dies -> player is moved back to town.
Current dungeon/monster map run is reset.
No level loss.
No XP penalty in v1.
No gold penalty in v1.
No item loss in v1.
```

Future penalties:

```text
- lose some XP progress
- drop some non-locked inventory items
```

Do not implement penalties yet.

### 20.1 Repeatable dungeons

All dungeons are permanently repeatable.

On death/reset:

```text
Reset monsters.
Reset boss state.
Reset temporary dropped loot.
Reset dungeon chests so they can be reopened in repeatable runs.
Do not reset completed quest objectives.
Do not remove permanent player rewards already granted.
```

Temporary quest progress inside a dungeon may reset only if the quest is explicitly designed as run-based. Otherwise, quest objective progress should persist according to QuestManager rules.

### 20.2 Return-to-town requirements

The reset system must use `MapManager` and the start/respawn target in `data/game_flow.json`.

Do not hardcode one scene path if map metadata already defines town IDs.

Required metadata target:

```text
default_respawn_map_id = town or hub map ID
default_respawn_entry = entry_default
```

The current default map ID is `custom_kit_town` until a reviewed Grimvale naming migration.

---

## 21. Combat Feedback — Damage Numbers

Use floating damage numbers, but keep them small and clean.

Color rules:

```text
Normal damage = white
Critical hit = red and slightly larger
Healing = green
DoT = purple
```

The same color logic applies whether the player or enemy receives the number.

Rules:

```text
- Damage numbers should not flood the screen.
- DoT numbers are aggregated.
- Cap simultaneous visible numbers on mobile.
- Pool/reuse damage number nodes.
- Numbers should float briefly and fade.
```

Settings hook:

```text
show_damage_numbers
```

---

## 22. Combat Feedback — Hit VFX

On successful hit:

```text
- small particle burst
- hit SFX
- damage number
```

No v1:

```text
- no hit-stop
- no screen shake
- no large shader effects
```

Player hit feedback:

```text
- red flash on player
- player hit SFX
```

Enemy hit feedback:

```text
- small particle burst
- enemy hit SFX
- damage number
```

Boss hit feedback:

```text
- clear flash/sound
- avoid large knockback unless the boss design allows it
```

Optional setting:

```text
Disable on-hit particles.
```

---

## 23. Combat Feedback — Ability Indicators

Player abilities:

```text
- Aim direction should be clear.
- Melee arcs can show a subtle slash shape.
- Dash abilities can show a short movement trail.
- Projectiles show travel path through animation, not necessarily a pre-cast line.
```

Enemy regular attacks:

```text
- Use animation only.
- No large ground indicators for ordinary attacks.
```

Elites and bosses:

```text
- Use clear telegraphs for dangerous attacks.
- Ground indicators are allowed for boss/elite area attacks.
```

---

## 24. SFX Categories

Define categories. Do not create final audio assets unless requested.

Required combat SFX categories:

```text
attack_swing
melee_hit_generic
hit_slime
hit_bone
crit_hit
player_hurt
enemy_death
ability_cast
charge_dash
cleave_swing
insufficient_mana
```

No need for these in this agent:

```text
item_pickup
cooldown_ready
```

SFX rules:

```text
- Keep sounds short.
- Avoid loud repetitive hit spam.
- Boss/elite SFX can be heavier later.
- Reuse fallback generic sounds when monster-family-specific SFX are missing.
```

---

## 25. VFX Style Guide

Combat VFX should be:

```text
readable pixel VFX
+
dark fantasy color language
+
mobile-safe density
```

Rules:

```text
- Strong silhouettes over noisy particle clouds.
- Use short-lived particles.
- Avoid full-screen effects in v1.
- Use color to distinguish damage types/effects.
- Keep effects visible over grim/dark maps.
```

Suggested colors:

```text
Physical/slash = white/grey sparks
Crit = red accent
Healing = green glow
DoT/poison = purple
Mana/arcane = blue/cyan
Warrior charge = dust/white streak
```

---

## 26. Performance Rules

This game is mobile-oriented. Combat feedback must be lightweight.

Required rules:

```text
- Pool damage number nodes.
- Pool common hit particles if needed.
- Cap visible damage numbers.
- Cap particle bursts per frame.
- Avoid expensive full-screen shaders.
- Avoid per-frame tile custom data queries for combat.
- Do not spawn dozens of unique scenes for each DoT tick.
- Aggregate DoT numbers instead of showing every tick.
```

Required initial caps for v1:

```text
max_damage_numbers_visible = 30
max_particle_bursts_per_frame = 8
max_status_tick_popups_per_target_per_second = 1
```

The combat feedback owner enforces these caps. Tuning requires recorded test evidence.

---

## 27. Accessibility and Settings

Add or prepare settings for:

```text
show_damage_numbers
disable_on_hit_particles
show_not_enough_mana_text
larger_cooldown_numbers, future
```

Do not build a full settings menu if the Menu Flow Agent owns it; expose hooks/config values that the settings menu can control later.

---

## 28. Data Files This Agent May Propose

Potential data files:

```text
res://data/combat/combat_balance.json
res://data/abilities/abilities.json
res://data/combat/feedback_rules.json
```

Example `combat_balance.json`:

```json
{
  "schema_version": 1,
  "minimum_damage": 1,
  "defense_softcap": 900.0,
  "default_crit_chance": 0.05,
  "default_crit_damage": 1.5,
  "dot_display_aggregation_seconds": 1.0,
  "max_damage_numbers_visible": 30,
  "max_particle_bursts_per_frame": 8
}
```

Do not place combat balance files in item folders.

---

## 29. Scripts and Scenes This Agent May Update

Likely integration points:

```text
res://scripts/combat/damage_calculator.gd
res://scripts/combat/combat_feedback_manager.gd
res://scripts/components/hitbox_component.gd
res://scripts/components/hurtbox_component.gd
res://scripts/components/status_effect_component.gd
res://scripts/abilities/ability_runner.gd
res://scripts/abilities/ability_data.gd
res://scripts/autoload/ability_manager.gd
res://scripts/player/player_controller.gd
res://scripts/monsters/monster_base.gd
res://scripts/ui/hud.gd
res://scripts/ui/damage_number.gd
res://scenes/ui/damage_number.tscn
res://scenes/effects/hit_particle_burst.tscn
res://scenes/effects/basic_melee_hitbox.tscn
res://scenes/effects/cleave_hitbox.tscn
res://scenes/effects/charge_trail.tscn
```

Use actual existing project paths where they differ. Do not create duplicate systems if current equivalents already exist.

---

## 30. Implementation Sequence

Implement in small reviewed phases.

### Main Phases 4-5 — Combat audit and damage pipeline

```text
- Audit current combat scripts.
- Identify existing hitbox/hurtbox/ability/player/monster paths.
- Add or refactor central damage calculator.
- Add diminishing defense mitigation.
- Add min/max damage range support.
- Add crit chance/crit damage support.
- Preserve existing basic attack behavior while routing through the new calculator.
```

### Main Phase 16 — Combat feedback core

```text
- Add damage number scene/script.
- Add color rules for normal/crit/heal/DoT.
- Add small hit particle burst.
- Add player red flash on hit.
- Add hit SFX hooks.
- Pool or cap feedback nodes.
```

### Main Phases 5-6 — Ability costs, cooldown overlay, and insufficient mana

```text
- Ensure abilities use mana and cooldown seconds.
- Add dark radial overlay to ability buttons.
- Add insufficient mana button flash, SFX hook, and optional text.
```

### Main Phases 6-7 — Aiming and Warrior abilities

```text
- Aim basic attack/abilities toward mouse position on PC.
- Prepare mobile tap-to-aim path.
- Implement/refine Cleave.
- Implement/refine Charge.
- Ensure Charge respects collision.
```

### Main Phases 5-7 — Status/DoT and heal effects

```text
- Add DoT effect support if missing.
- Aggregate DoT numbers for display.
- Add heal number display.
- Do not add buff effects yet.
```

### Main Phase 15D — Death and repeatable dungeon reset

```text
- On death, return player to town/hub.
- Reset current dungeon/monster map run.
- Reset monsters, boss, temporary drops, and repeatable chests.
- Do not apply XP/item/gold penalties yet.
```

### Main Phases 6-7 — Elite/boss telegraph framework

```text
- Add reusable wind-up/telegraph/active/recovery structure.
- Do not create full first boss unless requested.
```

Every phase must include architect handoff notes and validation results.

---

## 31. Validation Checklist

The agent must confirm:

```text
- Project opens in Godot 4.3+.
- No scene parse errors.
- No script parse errors.
- Basic attack still works.
- Basic attacks consume no mana.
- Abilities consume mana and start cooldowns.
- Cooldowns use seconds, not turns.
- Ability buttons show dark radial cooldown overlay.
- Insufficient mana flashes button blue and plays subtle error SFX hook.
- Damage uses central calculator.
- Defense has diminishing returns.
- Damage has min/max support.
- Crits work and show larger red damage numbers.
- Normal damage numbers are white.
- Healing numbers are green.
- DoT numbers are purple and aggregated.
- Player hit causes red player flash and hit SFX hook.
- Enemy hit causes small particle burst and SFX hook.
- No screen shake is used in v1.
- No hit-stop is used in v1.
- Cleave is stronger/wider than normal attack.
- Charge moves in aim direction and damages enemies.
- Charge cannot pass through walls or leave player stuck.
- Regular enemies use attack hitboxes with cooldowns.
- Boss/elite telegraph framework exists if implemented.
- Death returns player to town.
- Dungeon reset clears monsters, boss state, temporary drops, and repeatable chests.
- Completed quest objectives are not incorrectly removed.
- Feedback respects mobile performance caps.
- Settings hooks exist for damage numbers, particles, and not-enough-mana text.
- Existing HUD, inventory, save, skill tree, and monster systems are not replaced.
```

---

## 32. Architect Handoff Requirements

Each handoff must include:

```text
- Files changed.
- Combat paths touched.
- Whether any save data changed.
- Whether any ability data changed.
- Whether any item/equipment stat consumers were added.
- Validation performed.
- Known limitations.
- Future follow-up suggestions.
```

The handoff must explicitly state whether the implementation overlaps with:

```text
Inventory/Itemization Agent
Skill Tree Agent
Monster Design/Implementation Agent
HUD Agent
Menu Flow Agent
```

Any overlap must be reviewed by the Lead Architect before merge.

---

## 33. Non-Goals

Do not implement these in v1:

```text
screen shake
hit-stop
XP loss on death
item loss on death
stamina/rage/focus resources
full Ranger basic attack implementation
full Mage basic attack implementation
full boss fight design
buff effects
stun/freeze/slow
resistance/weakness chart
complex auto-targeting
auto-combat
new inventory storage model
new item generation model
```

Future hooks are allowed when small and non-invasive.

---

## 34. Summary

Build the reviewed v1 real-time combat foundation for Umbral Explorers: Relics of Grimvale.

The first implementation should focus on:

```text
central damage formula
crits
diminishing defense
min/max damage
small clean damage numbers
hit particles + SFX hooks
cooldown overlay
insufficient mana feedback
mouse/tap aiming foundation
Warrior basic attack, Cleave, and Charge
DoT/heal display patterns
death return-to-town and repeatable dungeon reset
mobile performance and accessibility hooks
```

Keep everything additive, reviewed, and compatible with the Main MD and active domain specs.
