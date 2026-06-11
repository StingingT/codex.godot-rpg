# RPG Skill Tree Agent Guide

## Status

**Project:** Umbral Explorers: Relics of Grimvale  
**Feature:** Skill tree / class keystone progression  
**Target engine:** Godot 4.3+  
**Language:** GDScript  
**Implementation style:** Additive patch only  
**First implementation target:** Warrior skill tree prototype  
**Tree logic inspiration:** Path of Exile-style connected node progression  
**Visual inspiration:** Ornate dark-fantasy skill tree panel (Warrior mockup) — vertical three-branch layout, glowing branch colors, right-side detail panel, bottom legends  

**UI reference:** Place the approved mockup at `docs/reference/skill_tree_warrior_mockup.png` (or use the project copy under `.cursor/projects/.../assets/` if synced). Agents must match this layout and tone, not a minimal list UI.

---

## Master Plan Integration Locks

- Warrior is the only playable v1 class. Ranger and Mage remain visible in class selection but disabled with **Coming Later**; do not implement their trees.
- The canonical v1 tree source is `res://data/skilltrees/warrior_skill_tree.json`.
- Level-up grants one skill point. The start node remains free.
- Active ability unlocks route through the existing `AbilityManager`; combat effects route through the central `DamageCalculator`.
- Cleave and Charge use mana, never stamina. Charge must respect walls, water, props, and closed doors and must not leave the player stuck.
- The Character screen owns the canonical Skills/ability-loadout hook. Remove its placeholder skill list only when this tree UI is wired.
- Skill-tree data is character payload inside the character-ID autosave; it does not own `user://saves/index.json` or `user://settings.json`.

---

## 1. Source of Truth

Follow the active project master spec:

```text
Main_ChatGPT-Godot_RPG_Implementation_Plan.md
```

**Agent skills:** [agent_skills_required.md](agent_skills_required.md) §4 (Skill tree agent).

This skill tree system must follow the existing project rules:

- Use Godot 4.3+.
- Use GDScript.
- Use `res://` paths.
- Use real-time combat, not turn-based combat.
- Use JSON metadata and Godot scenes/resources where appropriate.
- Preserve existing player, HUD, ability, inventory, save/load, and map systems.
- Patch additively.
- Do not replace existing systems.

Required data location (target):

```text
res://data/skilltrees/
```

**Current repo note:** Legacy trees exist at `res://data/classes/warrior_skill_tree.json` (and ranger/mage). Migrate Warrior to `res://data/skilltrees/warrior_skill_tree.json`, update every reference, validate the migration, and remove the old Warrior source only when it is no longer referenced. Do not maintain two competing Warrior trees.

Required UI location:

```text
res://scenes/ui/
res://scripts/ui/
```

Required logic location:

```text
res://scripts/autoload/
res://scripts/abilities/
res://scripts/player/
```

---

## 2. Design Goal

Create a skill tree system that gives each player a unique progression path.

The system should combine:

1. **PoE-inspired logic**
   - Nodes form a connected graph.
   - Nodes require previous connected nodes.
   - Some nodes have specific prerequisites.
   - Players unlock a visible route through the tree.
   - Keystones create major build-defining choices.

2. **Ornate readable UI (Warrior mockup)**
   - Dark stone/parchment panel with gold trim (not a plain grey list).
   - Vertical tree: **start node at bottom center**, three branches rising **left (red), center (blue), right (green)**.
   - Circular nodes with white glyph icons; branch-colored outer rings and soft glow.
   - **Right sidebar** for selected node: large icon, description, effect bullets, requirements, cost, green **UNLOCK** button.
   - **Bottom bar:** node-type legend, stat-icon legend (STR/DEX/INT/VIT/LCK), footer status line.
   - Clear states: locked, available, unlocked, blocked, selected (see §25–26).

**Node icons** may be pixel art inside the circles; **chrome** (frames, lines, panels) is high-contrast fantasy UI like the mockup.

The first version should not attempt a huge PoE-sized tree. Target **37 nodes** in the mockup layout density.

---

## 2.1 UI Visual Target — Warrior Skill Tree Mockup

Agents implementing UI must reproduce this structure and mood.

### Screen regions

```text
┌─────────────────────────────────────────────────────────────────┐
│  [SKILL POINTS: 8+]     WARRIOR SKILL TREE (title, gold serif)   │
├──────────────────────────────────┬──────────────────────────────┤
│                                  │  DETAIL PANEL (selected)    │
│     RED branch      BLUE branch   │  ┌────┐  CLEAVE              │
│        ╱               │          │  │icon│  Active Skill       │
│       ╱                │          │  └────┘  Description...     │
│  [nodes]          [nodes]    GREEN│  Effect: • 240% weapon...   │
│       ╲                │      ╲  │  Requires: 7 pts, Lv 12    │
│        ╲               │       ╲ │  Cost: 1 SKILL POINT         │
│         ╲──────────────┼────────╲│  [ UNLOCK ] (green)         │
│              [WARRIOR INITIATE]  │  State legend (rings)        │
│                   (free start)   │  Keystone info (if needed)   │
├──────────────────────────────────┴──────────────────────────────┤
│ NODE TYPES legend │ STAT ICONS legend │ WARRIOR • 37 NODES • 8 SP │
└─────────────────────────────────────────────────────────────────┘
```

### Layout rules

| Rule | Spec |
|------|------|
| Tree flow | Bottom → top (initiate at bottom, keystones toward top of each branch) |
| Red branch | Left column — offense — `#c03030` glow, lines tint red when active |
| Blue branch | Center — defense — `#3080c0` glow |
| Green branch | Right — utility — `#30a050` glow |
| Start node | Large gold ring, label e.g. **WARRIOR INITIATE (FREE)** |
| Positions | From JSON `position: [x, y]` in normalized 0–1 or pixel coords — not hardcoded in script |
| Connections | Curved or straight lines between parent/child; thickness 2–4px; glow on available path |

### Node chrome (by type — matches mockup legend)

| Type | Visual | Size (approx) |
|------|--------|----------------|
| `stat_node` | Simple **gold ring**, small circle | 40–48px |
| `passive_node` / `combat_stat_node` | **Blue glowing ring** | 48–56px |
| `skill_unlock_node` / strong passive | **Large spiky/sunburst** border | 64–72px |
| `keystone_node` | **Ornate gold sunburst**, largest | 80–96px |
| `mastery_node` | Ornate variant (v1 optional) | 72–80px |

Below each node: **short name** + rank fraction **`current/max`** (e.g. `3/3`, `0/1`).

Locked nodes: padlock overlay + `Requires Level X` under name when applicable.

### Detail panel (right, ~30–35% width)

When a node is selected, show:

1. **Title** — uppercase name (e.g. `CLEAVE`), serif/display font  
2. **Subtitle** — node type (`Active Skill`, `Passive`, `Keystone`, …)  
3. **Large icon** — same art as node, 96×96+ in gold square frame  
4. **Description** — 2–4 lines flavor + mechanics summary  
5. **Effect** — bullet list (parsed from JSON `effects` / `description`)  
6. **Requirements** — points in node, level, prerequisite node names  
7. **Cost** — `N SKILL POINT(S)`  
8. **UNLOCK** button — green, disabled when `can_unlock` is false  
9. **State legend** — ring colors: unlocked / available / locked / requirement not met  
10. **Keystone panel** — short note when selecting keystones (mutual exclusion with other keystone)

### Bottom footer

- **NODE TYPES:** icons for Stat (gold ring), Passive (blue ring), Active (large spiky), Keystone (ornate).  
- **STAT ICONS:** STR fist, DEX boot, INT book, VIT heart, LCK clover — reuse in stat nodes.  
- **Status line:** `{CLASS} SKILL TREE • {N} NODES • {SP} SKILL POINTS AVAILABLE`

### Typography and color

| Element | Guidance |
|---------|----------|
| Title | Gold/cream serif, letter-spaced, e.g. `WARRIOR SKILL TREE` |
| Body | Light grey sans on dark brown/black panel |
| Panel BG | `#1a1510` – `#0d0d12` with subtle noise or stone texture |
| Borders | Gold `#c9a227` 2px, beveled panel corners |
| Skill points (top-right) | `SKILL POINTS: 8+` in gold, prominent |

### Theme integration

- Reuse or extend `scripts/ui/rpg_ui_style.gd` for panels/buttons where possible.  
- Skill-tree-specific assets: `res://assets/sprites/ui/skilltree/` (node rings, line caps, legend icons, branch glow shaders optional).

### Not in v1 (mockup shows, defer if heavy)

- Animated particle background on entire tree  
- Full shader bloom on every node (use StyleBox + modulate glow first)

---

## 3. Playable Classes

The planned playable classes are:

```text
Warrior
Ranger
Mage
```

For version 1, implement **Warrior only**.

Future class support:

- Ranger and Mage should reuse the same general tree layout template.
- Red and Blue branch effects change per class.
- Green branch remains a shared universal utility branch.
- A Warrior cannot unlock Ranger or Mage class skills.
- Class changes may be introduced later, but not now.

---

## 4. Branch Color Identity

Colors represent **branch identity**, not universal stat meaning.

### Warrior

```text
Red = Offense
Blue = Defense
Green = Utility
```

### Ranger / Future

```text
Red = Damage
Blue = Speed
Green = Utility
```

### Mage / Future

```text
Red = Fire + Lightning
Blue = Ice + Poison
Green = Utility
```

Notes:

- Some colors may overlap visually later.
- Fire can be red.
- Lightning can use purple accents.
- Poison can use dark green accents.
- Green utility should stay broadly universal across all classes.

---

## 5. First Prototype Scope

Implement one Warrior skill tree.

```text
Total nodes: 37
Start node: 1
Red branch: 12 nodes
Blue branch: 12 nodes
Green branch: 12 nodes
```

The first version should include:

- 1 free starting node.
- 3 colored branches.
- 2 active Warrior skills.
- Stat nodes.
- Passive nodes.
- Skill modifier nodes.
- 2 class keystones.
- Utility progression.
- Keystone blocking.
- Save/load support for unlocked nodes.

---

## 6. Warrior Branch Identity

### Red Branch — Offense

Focus:

```text
STR
physical damage
piercing damage
attack speed
active attacks
aggressive passives
```

Do **not** introduce bleed yet.

The red branch should feel like the Warrior becomes more aggressive, stronger, and faster.

### Blue Branch — Defense

Focus:

```text
VIT
max HP
defense
hp regeneration
survival passives
```

Blue should focus on HP, defense, and survival.

### Green Branch — Utility

Focus:

```text
gold_increase
move_speed
cooldown_reduction
potion strength
quality-of-life utility
```

Green should be reusable for Warrior, Ranger, and Mage.

---

## 7. Core Stats

Use these core stats:

```text
STR
DEX
INT
VIT
LCK
```

Definitions:

```text
STR = physical damage + piercing damage
DEX = attack speed + crit damage
INT = spell damage + max mana / mana capacity
VIT = max HP
LCK = crit chance
```

Important rules:

- STR does not mean only melee scaling.
- DEX does not mean only ranged scaling.
- INT affects spell damage, which later affects elemental scaling.
- VIT does not increase defense.
- Defense mainly comes from equipment and specific stat-skill nodes.
- LCK does not affect drop rate yet.
- Drop rate may affect equipment drops in the future, but not in version 1.

---

## 8. Derived Stats

Support these derived stats:

```text
attack
attack_speed
defense
max_hp
max_mana
hp_regen
mana_regen
crit_chance
crit_damage
move_speed
gold_increase
drop_rate
cooldown_reduction
elemental_damage
physical_damage
piercing_damage
spell_damage
```

Version 1 rule:

- `gold_increase` affects the percentage of gold found.
- `drop_rate` exists for future support but should not be active yet.
- Future `drop_rate` should only affect equipment drops at first.

---

## 9. Node Types

Use these node types:

```text
stat_node
combat_stat_node
utility_stat_node
skill_unlock_node
skill_modifier_node
passive_node
keystone_node
mastery_node
```

### stat_node

Flat/core stat increase.

Examples:

```text
+5 STR
+5 VIT
+10 max HP
+2 defense
```

### combat_stat_node

Combat-focused stat increase.

Examples:

```text
+5% physical damage
+4% attack speed
+5% piercing damage
```

### utility_stat_node

Utility-focused stat increase.

Examples:

```text
+5% movement speed
+10% gold_increase
+5% cooldown reduction
```

### skill_unlock_node

Unlocks an active or passive skill.

Examples:

```text
Cleave
Charge
```

### skill_modifier_node

Modifies a learned skill.

Examples:

```text
Cleave width increased
Charge cooldown reduced
```

Rules:

- The related skill must already be learned.
- A modifier should not completely block unrelated paths.
- Version 1 should use at most one modifier per active skill.

### passive_node

Unlocks a passive effect, not just a flat stat.

Example:

```text
When HP is below 10%, deal 2x damage.
```

### keystone_node

Rare build-defining node with strength and drawback.

### mastery_node

Strong end-of-branch node. Can be used later. Do not overuse in version 1.

---

## 10. Node Visual Size Rules

Map node types to mockup chrome (§2.1):

```text
stat_node / utility_stat_node     → small gold ring
combat_stat_node / passive_node   → medium blue glowing ring
skill_modifier_node               → medium blue or large spiky (if major)
skill_unlock_node                 → large spiky / sunburst (Active)
keystone_node                     → huge ornate gold sunburst
mastery_node                      → ornate large (optional v1)
```

The UI must make it clear that not every node is an active skill. Stat nodes stay visually smaller than Cleave/Charge unlock nodes.

---

## 11. Warrior Active Skills — Version 1

Implement these two Warrior active skills as skill tree unlocks.

### Cleave

Cleave is a stronger and wider version of the normal attack.

Rules:

- The current normal attack can already hit multiple monsters.
- Cleave should not be treated as the only multi-target attack.
- Cleave should use a wider attack arc or larger hitbox than the normal attack.
- Cleave should deal more damage than the normal attack.
- Cleave should feel like an upgraded heavy swing.
- Cleave uses a real-time cooldown and mana cost.

Suggested first values:

```text
Damage multiplier: 1.4x normal attack
Hitbox width/arc: 1.4x to 1.7x normal attack area
Cooldown: 3.0 seconds
Cost: low to medium
```

### Charge

Charge is a dash-forward Warrior attack.

Rules:

- Player dashes forward a short distance.
- Enemies in the path take damage.
- Can be used for mobility and combat initiation.
- Must not pass through walls, blocked water, solid props, or closed doors.
- Must recover to a valid position and never leave the player stuck.
- Should use real-time cooldown.
- Uses mana, not stamina.

Suggested first values:

```text
Damage multiplier: 1.1x to 1.3x normal attack
Dash distance: short/medium
Cooldown: 5.0 seconds
Cost: medium
```

---

## 12. Ability Slot Rule

Active skills require ability slots.

Unlocking an active skill should:

- Add the skill to `player.learned_abilities`.
- Make the skill available in the skill tree window.
- Allow the player to equip it into an ability slot.
- Not automatically force it into a slot unless a slot is empty and the project already supports that behavior.

The skill tree window should eventually support ability equipping.

For version 1, at minimum:

- show that the skill is learned;
- expose enough data for existing/future ability slot UI to equip it.

---

## 13. Keystones

Keystones are rare, build-defining nodes.

A keystone should:

- Significantly change gameplay.
- Have a clear strength.
- Usually include a drawback or tradeoff.
- Create a recognizable playstyle.
- Synergize with other skill tree choices.

A keystone should not:

- Simply be a large stat bonus.
- Be mandatory for every build.
- Completely invalidate alternative choices.

---

## 14. Warrior Keystones — Version 1

Implement two Warrior keystones.

### Blood Rage

Theme:

```text
Aggressive berserker combat
```

Effect:

```text
Deal 30% increased damage while below 50% HP.
Gain 10% lifesteal.
```

Drawback:

```text
Healing effects are reduced by 50%.
```

Playstyle:

```text
Remain at lower health and sustain through combat.
```

### Iron Wall

Theme:

```text
Tank specialization
```

Effect:

```text
Gain 40% defense.
Gain 25% max HP.
```

Drawback:

```text
Movement speed reduced by 15%.
```

Playstyle:

```text
Slow but durable frontline fighter.
```

---

## 15. Keystone Blocking

Use flexible blocking.

Rules:

- Multiple keystones may exist in the full game.
- Some specific keystones can block other specific keystones.
- Version 1: `blood_rage` blocks `iron_wall` and `iron_wall` blocks `blood_rage`.

Example JSON:

```json
{
  "blood_rage": {
    "type": "keystone_node",
    "blocks": ["iron_wall"]
  },
  "iron_wall": {
    "type": "keystone_node",
    "blocks": ["blood_rage"]
  }
}
```

Blocked keystones should appear greyed out in the UI.

---

## 16. Unlock Rules

A node can only be unlocked if:

```text
1. The player has enough skill points.
2. The node is not already unlocked.
3. The node is connected to the current unlocked path.
4. All listed requirements are met.
5. The player meets the level requirement, if present.
6. The node is not blocked by an already unlocked keystone.
7. The player selected the node and confirmed unlock.
```

The start node is free.

Use confirmation:

```text
Player selects node -> Info panel opens -> Player presses Unlock/Confirm -> Node unlocks
```

Do not unlock nodes immediately on click.

---

## 17. Skill Points

Version 1 rule:

```text
Player gains 1 skill point per level.
The start node costs 0 and is unlocked for free.
```

Future rules:

- Some quests may reward skill points later.
- Special skill points may be introduced later.
- Respec/refund will be introduced later with a cost.
- Do not implement respec now.

---

## 18. Level Requirements

Version 1 should support level requirements in the data schema.

Use level requirements for:

```text
active skill nodes
keystone nodes
strong passive nodes if needed
```

Example:

```json
{
  "node_id": "charge",
  "requires_level": 5
}
```

No story progress gating yet.

---

## 19. Recommended Warrior 37-Node Layout

The exact layout can be adjusted visually, but the data should follow this structure.

### Start Node

1. `warrior_start`

### Red Branch — Offense, 12 nodes

1. `red_01_str_training`
2. `red_02_physical_damage`
3. `red_03_attack_speed`
4. `red_04_cleave_unlock`
5. `red_05_str_path`
6. `red_06_piercing_damage`
7. `red_07_cleave_wide_arc`
8. `red_08_heavy_momentum`
9. `red_09_charge_unlock`
10. `red_10_charge_impact`
11. `red_11_berserker_instinct`
12. `red_12_blood_rage_keystone`

### Blue Branch — Defense, 12 nodes

1. `blue_01_vit_training`
2. `blue_02_max_hp`
3. `blue_03_defense_training`
4. `blue_04_hp_regen`
5. `blue_05_vit_path`
6. `blue_06_guarded_stance`
7. `blue_07_more_defense`
8. `blue_08_survival_instinct`
9. `blue_09_recovery_training`
10. `blue_10_stalwart_body`
11. `blue_11_unbreakable_will`
12. `blue_12_iron_wall_keystone`

### Green Branch — Utility, 12 nodes

1. `green_01_gold_increase`
2. `green_02_move_speed`
3. `green_03_potion_strength`
4. `green_04_cooldown_reduction`
5. `green_05_gold_increase_2`
6. `green_06_utility_path`
7. `green_07_potion_efficiency`
8. `green_08_move_speed_2`
9. `green_09_cooldown_reduction_2`
10. `green_10_treasure_hunter_path`
11. `green_11_adventurer_focus`
12. `green_12_utility_mastery`

---

## 20. JSON Data Format

Create:

```text
res://data/skilltrees/warrior_skill_tree.json
```

Recommended structure:

```json
{
  "tree_id": "warrior_skill_tree",
  "class_id": "warrior",
  "display_name": "Warrior Skill Tree",
  "version": 1,
  "start_nodes": ["warrior_start"],
  "branches": {
    "red": {
      "name": "Offense",
      "color": "red",
      "class_meaning": "Warrior offense"
    },
    "blue": {
      "name": "Defense",
      "color": "blue",
      "class_meaning": "Warrior defense"
    },
    "green": {
      "name": "Utility",
      "color": "green",
      "class_meaning": "Universal utility"
    }
  },
  "nodes": {
    "warrior_start": {
      "name": "Warrior Path",
      "type": "stat_node",
      "branch": "start",
      "description": "Begin the path of the Warrior.",
      "position": { "x": 0, "y": 0 },
      "size": "large",
      "cost": 0,
      "requires": [],
      "requires_level": 1,
      "connections": [
        "red_01_str_training",
        "blue_01_vit_training",
        "green_01_gold_increase"
      ],
      "effects": [
        { "type": "stat_bonus", "stat": "STR", "amount": 1 },
        { "type": "stat_bonus", "stat": "VIT", "amount": 1 }
      ]
    }
  }
}
```

Each node should support:

```json
{
  "name": "Node Name",
  "type": "stat_node",
  "branch": "red",
  "description": "Node description.",
  "position": { "x": 0, "y": 0 },
  "size": "small",
  "cost": 1,
  "requires": [],
  "requires_level": 1,
  "connections": [],
  "blocks": [],
  "requires_skill": null,
  "effects": []
}
```

---

## 21. Supported Node Effects

Support these effect types:

```text
stat_bonus
combat_stat_bonus
utility_stat_bonus
percent_stat_bonus
unlock_active_skill
unlock_passive_skill
modify_skill
unlock_passive_flag
keystone_effect
```

Examples:

```json
{ "type": "stat_bonus", "stat": "STR", "amount": 5 }
```

```json
{ "type": "combat_stat_bonus", "stat": "physical_damage", "amount": 0.05 }
```

```json
{ "type": "utility_stat_bonus", "stat": "gold_increase", "amount": 0.10 }
```

```json
{ "type": "unlock_active_skill", "skill_id": "cleave" }
```

```json
{
  "type": "modify_skill",
  "skill_id": "cleave",
  "modifier": "hitbox_scale",
  "amount": 1.15
}
```

```json
{
  "type": "keystone_effect",
  "keystone_id": "blood_rage"
}
```

---

## 22. Required Scripts

Create or update additively:

```text
res://scripts/autoload/skill_tree_manager.gd
res://scripts/ui/skill_tree_screen.gd
res://scripts/ui/skill_tree_node_button.gd
```

Optional later:

```text
res://scripts/resources/skill_node_resource.gd
```

---

## 23. SkillTreeManager Responsibilities

`SkillTreeManager` should:

- Load skill tree JSON.
- Validate tree data.
- Validate node IDs.
- Validate requirements.
- Validate connections.
- Track unlocked nodes.
- Check if a node can be unlocked.
- Check if a node is blocked by another node.
- Spend skill points.
- Apply node effects to the player.
- Add active skills to learned abilities.
- Track skill modifiers.
- Emit signals when nodes are unlocked.
- Provide tree data to the UI.
- Provide save/load data for unlocked nodes.

Recommended signals:

```gdscript
signal skill_node_selected(node_id: String)
signal skill_node_unlocked(node_id: String)
signal skill_tree_changed
signal skill_points_changed(new_amount: int)
signal skill_tree_error(message: String)
```

Required functions:

```gdscript
func load_tree(path: String) -> void
func validate_tree() -> bool
func can_unlock_node(node_id: String, player: Node) -> bool
func unlock_node(node_id: String, player: Node) -> bool
func is_node_unlocked(node_id: String) -> bool
func is_node_blocked(node_id: String) -> bool
func get_node_data(node_id: String) -> Dictionary
func get_unlocked_nodes() -> Array[String]
func apply_node_effects(node_id: String, player: Node) -> void
func get_save_data() -> Dictionary
func load_save_data(data: Dictionary) -> void
```

---

## 24. Unlock Logic Pseudocode

```gdscript
func can_unlock_node(node_id: String, player: Node) -> bool:
    if not nodes.has(node_id):
        return false

    if unlocked_nodes.has(node_id):
        return false

    if is_node_blocked(node_id):
        return false

    var node_data: Dictionary = nodes[node_id]
    var cost := int(node_data.get("cost", 1))

    if player.skill_points < cost:
        return false

    var required_level := int(node_data.get("requires_level", 1))
    if player.level < required_level:
        return false

    var requirements: Array = node_data.get("requires", [])
    for required_id in requirements:
        if not unlocked_nodes.has(required_id):
            return false

    var required_skill = node_data.get("requires_skill", null)
    if required_skill != null:
        if not player.learned_abilities.has(required_skill):
            return false

    if node_id in start_nodes:
        return true

    return _has_unlocked_connected_parent(node_id)
```

Important:

- Nodes must not unlock randomly anywhere in the tree.
- Unlocking must continue the player's visible path.
- Skill modifier nodes must require the related skill but must not become mandatory for unrelated routes.

---

## 25. UI Requirements

**Visual target:** §2.1 Warrior mockup (ornate panel, three branches, right detail sidebar, bottom legends).

**Scene strategy:** Replace or heavily refactor existing `res://scenes/ui/skill_tree_ui.tscn` so the in-game UI matches the mockup. The guide may refer to `skill_tree_screen.tscn` as the target name; either rename after refactor or keep `skill_tree_ui.tscn` and update HUD bindings — document the chosen path in implementation notes.

Create or refactor:

```text
res://scenes/ui/skill_tree_screen.tscn
  — OR evolve res://scenes/ui/skill_tree_ui.tscn
```

Recommended scene structure (mockup-aligned):

```text
SkillTreeScreen : Control
├── Background : TextureRect          # dark stone / parchment full screen
├── MainFrame : PanelContainer        # gold-trim outer border
│   ├── Header : HBoxContainer
│   │   ├── TitleLabel : Label        # WARRIOR SKILL TREE
│   │   └── SkillPointsLabel : Label  # SKILL POINTS: 8+
│   ├── Body : HBoxContainer
│   │   ├── TreeCanvas : Control      # ~65% width
│   │   │   ├── BranchLines : Node2D  # red/blue/green tinted lines
│   │   │   └── Nodes : Control       # positioned node buttons
│   │   └── DetailPanel : PanelContainer  # ~35% width, §2.1
│   │       ├── IconFrame : TextureRect
│   │       ├── NodeNameLabel : Label
│   │       ├── NodeTypeLabel : Label
│   │       ├── DescriptionLabel : RichTextLabel
│   │       ├── EffectList : RichTextLabel
│   │       ├── RequirementLabel : Label
│   │       ├── CostLabel : Label
│   │       ├── UnlockButton : Button
│   │       ├── StateLegend : HBoxContainer
│   │       └── KeystoneInfo : Label
│   └── Footer : HBoxContainer
│       ├── NodeTypeLegend : HBoxContainer
│       ├── StatIconLegend : HBoxContainer
│       └── StatusLineLabel : Label   # 37 NODES • 8 SKILL POINTS...
└── CloseButton : Button
```

Create node button scene:

```text
res://scenes/ui/skill_tree_node_button.tscn
```

Recommended structure:

```text
SkillTreeNodeButton : Button
├── Icon : TextureRect
├── LockIcon : TextureRect
├── Highlight : TextureRect
└── StateOverlay : TextureRect
```

---

## 26. UI Visual States

Support these states (ring colors like mockup detail legend):

```text
locked
available
unlocked
blocked
selected
```

| State | Ring / node look | Line to parent |
|-------|------------------|----------------|
| **locked** | Dim grey ring, padlock icon, muted label | Dim grey |
| **available** | Branch-color bright ring + soft outer glow | Branch color, soft glow |
| **unlocked** | Solid branch-color ring, full-brightness icon | Bright branch color |
| **blocked** | Dark grey, strikethrough or “blocked” tint | Disabled dark |
| **selected** | Extra white/gold highlight pulse on ring | Unchanged |

### locked

Requirements not met (level, prereqs, or no connection from unlocked path).

### available

Path + requirements met; player has skill points; not blocked.

### unlocked

Points spent; show rank `current/max` filled.

### blocked

Excluded by another keystone (e.g. Blood Rage vs Iron Wall).

### selected

Drives right **DetailPanel**; **UNLOCK** enabled only when `can_unlock_node` is true.

---

## 27. Connection Lines

Draw lines between connected nodes.

Line rules:

```text
Dim grey = locked connection
Bright branch color = unlocked connection
Soft glow = available next path
Dark/disabled = blocked path
```

Use branch colors:

```text
Red branch = offense
Blue branch = defense
Green branch = utility
```

The data file should define node positions. Do not hardcode all positions in script.

---

## 28. Save/Load Requirements

Skill tree save data should include:

```json
{
  "skill_tree": {
    "tree_id": "warrior_skill_tree",
    "unlocked_skill_nodes": [
      "warrior_start",
      "red_01_str_training",
      "red_02_physical_damage"
    ],
    "blocked_skill_nodes": [
      "blue_12_iron_wall_keystone"
    ],
    "learned_skill_modifiers": {
      "cleave": ["wide_arc"]
    }
  }
}
```

This must integrate with the character payload saved through `SaveManager` at `user://saves/char_0001.json`. The skill-tree domain does not own the save index or global settings.

---

## 29. Integration With Player

The player should support or already has:

```text
level
skill_points
unlocked_skill_nodes
learned_abilities
ability_slots
```

Skill tree effects should update these systems rather than replacing them.

Examples:

```gdscript
player.skill_points -= cost
player.unlocked_skill_nodes.append(node_id)
```

For active skills:

```gdscript
player.learned_abilities.append(skill_id)
```

Do not auto-equip skills unless the current ability-slot design already supports a safe empty-slot behavior.

---

## 30. Integration With Ability System

Active skills should reference ability IDs from:

```text
res://data/abilities/abilities.json
```

Add or ensure entries exist for:

```text
cleave
charge
```

Skill tree nodes should unlock ability IDs. They should not duplicate full ability behavior.

Skill modifier nodes should store modifiers that the ability system can read.

Examples:

```json
{
  "type": "modify_skill",
  "skill_id": "cleave",
  "modifier": "hitbox_scale",
  "amount": 1.15
}
```

```json
{
  "type": "modify_skill",
  "skill_id": "charge",
  "modifier": "cooldown_multiplier",
  "amount": 0.9
}
```

---

## 31. Advanced Tech Tree Future Note

Future design:

- Selecting a specific active skill can open an advanced tech tree for that skill.
- This guide focuses on the main class keystone tree only.
- Advanced skill-specific trees should be separate data files later.

Possible future location:

```text
res://data/skilltrees/advanced/
```

Example future files:

```text
res://data/skilltrees/advanced/cleave_tech_tree.json
res://data/skilltrees/advanced/charge_tech_tree.json
```

Do not implement advanced tech trees in version 1.

---

## 32. Future Ranger and Mage Notes

Do not implement Ranger or Mage yet.

When implemented later:

- Reuse the same layout template.
- Replace red and blue branch effects.
- Keep green utility branch mostly identical.
- Keep class-specific active skills locked to the class.

### Ranger future identity

```text
Red = Damage
Blue = Speed
Green = Utility
```

### Mage future identity

```text
Red = Fire + Lightning
Blue = Ice + Poison
Green = Utility
```

Mage tree should eventually have split paths for different elements and some branches between elements.

---

## 33. Implementation Deliverables

Provide a zip containing only added or changed files.

Expected files:

```text
res://data/skilltrees/warrior_skill_tree.json
res://scripts/autoload/skill_tree_manager.gd
res://scripts/ui/skill_tree_screen.gd
res://scripts/ui/skill_tree_node_button.gd
res://scenes/ui/skill_tree_screen.tscn
res://scenes/ui/skill_tree_node_button.tscn
```

If ability data is patched:

```text
res://data/abilities/abilities.json
```

If icons/placeholders are added:

```text
res://assets/sprites/ui/skilltree/
```

Also provide:

```text
SKILL_TREE_IMPLEMENTATION_NOTES.md
```

The notes should explain:

- what was added;
- how the tree is loaded;
- how unlock logic works;
- how keystone blocking works;
- how Cleave and Charge are represented;
- how save/load connects;
- what still needs future balancing.

---

## 34. Validation Checklist

The agent must confirm:

- [ ] Project opens in Godot 4.3+.
- [ ] No scene parse errors.
- [ ] No script parse errors.
- [ ] Warrior skill tree JSON loads.
- [ ] All 37 nodes exist.
- [ ] Every node has a unique ID.
- [ ] Every connection points to an existing node.
- [ ] Every requirement points to an existing node.
- [ ] Start node unlocks for free.
- [ ] Player gains/uses 1 skill point per level.
- [ ] Locked nodes cannot be unlocked.
- [ ] Available connected nodes can be unlocked.
- [ ] Unlocking requires selection and confirmation.
- [ ] Unlocking spends skill points.
- [ ] Stat nodes apply stats correctly.
- [ ] Cleave unlock adds `cleave` to learned abilities.
- [ ] Charge unlock adds `charge` to learned abilities.
- [ ] Cleave behaves as a stronger/wider normal attack, not the only multi-target attack.
- [ ] Skill modifier nodes require the relevant learned skill.
- [ ] Blood Rage and Iron Wall cannot both be unlocked in version 1.
- [ ] Blocked keystones visually grey out.
- [ ] Connection lines update visually.
- [ ] UI matches §2.1 mockup regions (header, 3 branches, detail panel, footer legends).
- [ ] Node rings differ by type (gold / blue / spiky / keystone ornate).
- [ ] Selected node shows effect bullets and green UNLOCK in detail panel.
- [ ] Footer shows node count and available skill points.
- [ ] Skill tree state can be saved.
- [ ] Skill tree state can be loaded.
- [ ] Existing HUD is not replaced.
- [ ] Existing Character screen remains the owner; its placeholder skill list is removed only after the canonical tree hook is wired.
- [ ] Existing inventory is not replaced.
- [ ] Existing ability system is not replaced.
- [ ] Existing save/load is not broken.

---

## 35. Important Restrictions

Do not:

- Replace the existing player system.
- Replace the existing HUD.
- Replace the existing ability system.
- Replace the existing inventory system.
- Replace the existing save system.
- Use turn-based cooldowns.
- Make the skill tree purely visual.
- Hardcode all nodes in GDScript.
- Unlock nodes randomly outside the connected path.
- Implement Ranger or Mage yet.
- Implement respec yet.
- Implement advanced tech trees yet.
- Add bleed yet.

Do:

- Patch additively.
- Use JSON-driven tree data.
- Use real-time ability logic.
- Use the existing player skill point and ability slot concepts.
- Keep the tree compact and expandable.
- Make Warrior feel class-defining first.
- Preserve future build-identity flexibility.

---

## 36. Agent Task Summary

Build the v1 Warrior skill tree for Umbral Explorers: Relics of Grimvale.

The skill tree must use PoE-inspired connected node logic and the **Warrior mockup UI** (§2.1): ornate dark panel, bottom start node, three glowing branches, right detail sidebar, bottom legends. It should contain 37 nodes: 1 starting node, 12 red offense nodes, 12 blue defense nodes, and 12 green utility nodes.

Implement Cleave and Charge as the first Warrior active skill unlocks. Cleave must be a stronger and wider version of the current normal attack, because the normal attack already hits multiple monsters. Charge should be a short dash attack that damages enemies in its path.

The system must support stat nodes, passive nodes, active skill unlock nodes, skill modifier nodes, keystones, skill point costs, level requirements, node confirmation, connected-path requirements, keystone blocking, and save/load of unlocked nodes.

Patch additively and do not replace existing player, HUD, ability, inventory, or save/load systems. Route ability unlocks through `AbilityManager` and combat modifiers through `DamageCalculator`.
