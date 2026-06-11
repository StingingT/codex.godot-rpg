# Inventory, Equipment, Itemization & Loot Agent Instructions

**Status:** Active domain specification; architect-approved for phased implementation  
**Project:** Umbral Explorers: Relics of Grimvale  
**Source of truth:** `Main_ChatGPT-Godot_RPG_Implementation_Plan.md`  
**Agent name:** Inventory, Equipment, Itemization & Loot Agent  
**Scope:** Inventory UI, equipment UI, item data structure, item progression, loot rules, basic shop/economy rules, and item icon style guide.

---

## Master Plan Integration Locks

- Inventory remains a standalone window. Character owns Equipment and the canonical Skills/ability-loadout hook.
- The HUD-owned Phase 15 menu coordinator is the only authority that opens Quests, Character, Inventory, Settings, and pause modals.
- Inventory/equipment state is character payload inside `user://saves/char_0001.json`, indexed by `user://saves/index.json`.
- `SaveManager` owns migration from `user://saves/slot_1.json`; this agent owns only inventory/equipment payload migrations.
- Global settings remain outside character data at `user://settings.json` and are owned by `SettingsManager`.
- Equipment combat stats feed the central `DamageCalculator`; this domain must not calculate final damage independently.
- Warrior is the only playable v1 class. Ranger quivers and Mage spellbooks are future/inactive definitions only.
- Potions apply their effect first and consume only on success; full HP or mana is a non-consumption failure.

---

## 0. Core Rules for This Agent

You are designing the inventory, equipment, itemization, loot, and basic economy systems for a Godot 4.3+ 2D top-down real-time RPG.

Follow these rules:

1. Follow the Main MD as the source of truth.
2. Use Godot 4.3+ and GDScript-compatible designs.
3. Do not introduce Python architecture.
4. Prefer Godot scenes, GDScript, Resources, and JSON metadata.
5. Do not overwrite existing project systems unless explicitly instructed.
6. Preserve the existing project folder structure.
7. Use `res://` paths.
8. Keep the design mobile-friendly.
9. The system should be data-driven where possible.
10. Extend the current systems through migration-safe changes; do not create a parallel inventory architecture.
11. Preserve compatibility with existing saves and existing item IDs.
12. Implementation must pass the architect review workflow before being integrated.

Relevant Main MD direction:

- Items are collected through item pickup scenes.
- Item definitions live under `res://data/items/`.
- Aggregate tier/affix configuration lives under `res://data/itemization/`; aggregate loot tables live under `res://data/loot/`.
- Inventory/equipment should support item pickup, stacking, equip, unequip, stat bonuses, and UI.
- Save/load must preserve inventory, equipment, generated rolls, affixes, lock state, and loot pity state.

### Current architecture contract

The repository already has a working prototype. New mechanics in this document replace old gameplay rules, but implementation must migrate the current files instead of discarding them.

Current authoritative integration points:

```text
Item definition files:
  res://data/items/<item_id>.json

Item loading and ItemData creation:
  res://scripts/autoload/data_registry.gd

Owned inventory and equipment state:
  res://scripts/inventory/inventory_system.gd

Base item Resources:
  res://scripts/inventory/item_data.gd
  res://scripts/inventory/weapon_data.gd
  res://scripts/inventory/armor_data.gd

Player equipment stat application:
  res://scripts/player/player_controller.gd

Inventory UI:
  res://scenes/ui/inventory_ui.tscn
  res://scripts/ui/inventory_ui.gd

Item pickup:
  res://scenes/items/item_pickup.tscn
  res://scenes/items/item_pickup.gd

Character save payload integration:
  res://scripts/autoload/save_manager.gd
  user://saves/index.json
  user://saves/char_0001.json

Global settings, not owned by this agent:
  user://settings.json

Shop data and behavior:
  res://data/shops/<shop_id>.json
  res://scripts/autoload/shop_manager.gd
  res://scenes/ui/shop_ui.tscn
  res://scripts/ui/shop_ui.gd
```

Migration rules:

1. Keep per-item JSON files. Do not introduce a second monolithic `items.json` database.
2. Expand `ItemData`, `WeaponData`, `ArmorData`, `Inventory`, and `DataRegistry`; do not replace them with unrelated duplicate models.
3. Preserve the existing `Inventory.add_item(item, quantity) -> bool` entry point until every caller is migrated. A richer result API may be added underneath it.
4. Preserve existing item IDs such as `bronze_sword`, `bronze_armor`, `bronze_helmet`, `leather_bracelet`, `health_potion`, `mana_potion`, `slime_gel`, and `bone`.
5. Add save migrations before changing serialized inventory or equipment structures.
6. Do not remove existing scenes or autoloads until all references and saves have migrated.
7. Do not use both `scripts/inventory/equipment.gd` and the `Inventory.equipment` dictionary as competing runtime authorities. `Inventory` remains the owner unless an architect-approved migration explicitly changes ownership.
8. Keep aggregate configuration out of `res://data/items/`. The current `DataRegistry.load_folder_json("res://data/items")` treats every JSON file in that folder as an item definition.

---

## 1. Agent Goal

Extend the current game toward the following complete system:

```text
Inventory UI
Equipment UI
Item tabs
Equipment slots
Item data schema
Item rarity and tier progression
Item stats and affixes
Loot/drop rules
Pseudo-random pity rules
Basic shop/economy rules
Tooltip and comparison behavior
Item icon style guide
```

This file is the approved design direction. Implementation should proceed in the migration phases defined below and must be reviewed before integration.

---

## 2. Game Style Direction

The inventory and equipment system should feel like:

```text
RuneScape simplicity:
- 1 item = 1 inventory slot
- clear equipment slots
- readable items

MapleStory organization:
- category tabs
- compact inventory
- simple item grid

Path of Exile / dark fantasy mood:
- darker panels
- ornate but readable frames
- rarity colors
- stronger RPG loot feeling
```

The target is **simple to use on mobile**, but still with satisfying RPG progression.

---

## 3. UI Layout Direction

The inventory/equipment interface should appear as a **side-panel overlay over gameplay**.

Use the existing HUD shortcuts during Phase 9 and expose clean open/close hooks for the approved HUD-owned coordinator in Main Phase 15. Inventory remains standalone; do not add a second navigation authority.

Recommended layout when both inventory and equipment are visible:

```text
[ Equipment / Character Panel ] [ Tooltip / Comparison Panel ] [ Inventory Panel ]
```

The tooltip/comparison panel appears between the equipment and inventory panels.

Do not design a huge cluttered action menu inside the tooltip yet.

Responsive behavior is required:

```text
Desktop / wide window:
- Equipment, comparison, and inventory may appear side by side.

Mobile / 640x360 gameplay viewport:
- Show one primary panel at a time.
- Keep Inventory and Character/Equipment as separate coordinated windows.
- Item selection may open an inventory-owned comparison detail view.
- Item selection opens the comparison view without shrinking slots below a usable touch size.
- Minimum interactive target: approximately 44x44 logical pixels.
- Closing the overlay returns to gameplay without losing selection or scroll position.
```

The existing `inventory_ui.tscn` and `inventory_ui.gd` should be evolved into this interface. Do not create a disconnected replacement screen while the old one remains active.

---

## 4. Inventory Grid

Inventory is grid-based:

```text
1 item = 1 slot
No Diablo-style item sizes
No 2x3 swords or large armor occupying multiple slots
```

Inventory size:

```text
4 columns x 6 rows per tab = 24 slots per tab
3 tabs = 72 total slots
```

This is the target capacity. Existing saves currently contain a flat 30-slot inventory. Migration must:

```text
1. Read legacy flat slots.
2. Route each item to its canonical category tab.
3. Preserve item order within each category where possible.
4. Refuse migration only if all 72 target slots cannot hold the legacy items.
5. Never silently delete overflow.
```

Initial inventory tabs:

```text
1. Equipment
   - weapons
   - armor
   - off-hand items
   - accessories

2. Consumables
   - health potions
   - mana potions
   - later: cleanse, portal scrolls, buffs

3. Materials / Quest Items
   - monster-specific drops
   - quest items
   - future crafting materials
```

Inventory behavior:

```text
- Items auto-stack where possible.
- Equipment is not stackable.
- Potions stack to 20.
- Materials stack to 99.
- Quest items stack only up to the amount needed for that quest.
- Accept any quantity that fits. If none fits, show "Inventory full"; leave every unaccepted item on the ground.
- Gold is auto-picked up.
- Non-gold items drop on the ground and must be tapped/clicked or interacted with.
```

Canonical category routing:

```text
equipment:
  any item whose slot is weapon, off_hand, headgear, overall,
  armguards, boots, amulet, ring_1, ring_2, or ring

consumables:
  consumable

materials:
  material, quest
```

Every item definition must declare enough information for deterministic routing. Unknown categories go to `materials` temporarily and emit a warning during development.

Stack behavior:

```text
- `max_stack` from item data is authoritative.
- Adding items fills compatible partial stacks before empty slots.
- Quantities larger than one stack are split across multiple slots.
- Equipment and generated equipment instances always use quantity 1.
- Different generated equipment instances never stack, even when they share `item_id`.
- Quest limits cap accepted quantity without deleting the remainder.
- A partial pickup leaves the unaccepted remainder on the ground.
```

The implementation should add a detailed result method, for example:

```gdscript
add_item_detailed(item: ItemData, quantity: int, instance_data: Dictionary = {}) -> Dictionary
```

Result contract:

```json
{
  "accepted": 7,
  "remaining": 3,
  "changed": true,
  "reason": "inventory_full"
}
```

Keep `add_item(item, quantity) -> bool` as a compatibility wrapper until all current callers use the detailed result.

Sorting should exist:

```text
Sort by rarity
Sort by type
Sort by level requirement
Sort by recently obtained
```

Sorting rules:

- Sorting only reorders slots inside the selected tab.
- Equipped items are not part of inventory sorting.
- `recently obtained` uses a persisted acquisition sequence or timestamp, not current array position.
- Empty slots remain after occupied slots.
- Stable sorting is required so equal items do not jump unpredictably.

---

## 5. Equipment Slots

Initial equipment slots:

```text
weapon
off_hand
headgear
overall
armguards
boots
amulet
ring_1
ring_2
```

Notes:

```text
- "Overall" covers robes, armor, tunics, and similar main-body armor.
- Accessories do not use material tiers at first; they are rarity-based only.
- More slots can be added later, but not now.
```

These snake_case identifiers are the canonical runtime and save keys.

Static ring definitions use `slot: "ring"` because they can occupy either `ring_1` or `ring_2`. The chosen runtime destination is stored as `ring_1` or `ring_2`.

Legacy equipment migration:

```text
weapon    -> weapon
armor     -> overall
helmet    -> headgear
accessory -> amulet
```

Legacy keys must remain readable in old saves. New saves write only canonical keys after migration. If a migrated slot is occupied and a conflicting new-format item also exists, keep both items by moving the lower-priority item into the matching inventory tab; never overwrite it.

Off-hand items are class-specific:

```text
Warrior = Shield
Ranger = Quiver
Mage = Spellbook
```

Off-hand bonuses:

```text
Shield = defense
Quiver = attack speed
Spellbook = spell damage
```

Off-hand compatibility rules:

- Equipping an incompatible off-hand fails without removing the currently equipped item.
- The UI explains the required class.
- Existing saves with an incompatible future off-hand move that item back into inventory during load.
- The class restriction belongs in item metadata (`allowed_classes`) and centralized equip validation, not UI-only checks.

Weapons are **not class-locked for now**.  
However, class-specific damage calculations and skills may later make certain weapons more useful for specific classes.

Future expansion:

```text
Greatswords and other two-handed weapons can be added later.
If a two-handed weapon is equipped, it may disable the off-hand slot.
Do not implement this yet unless requested.
```

### 5.1 Equipment transaction rules

Equip and unequip operations must be atomic:

1. Validate level, class, slot, lock rules, and inventory capacity.
2. Determine where the displaced item will go.
3. Apply the swap only when every step can succeed.
4. Emit one coherent equipment/inventory update after success.
5. Leave all state unchanged on failure.

Required centralized APIs:

```gdscript
can_equip(instance_data: Dictionary, slot_id: String, player: Player) -> Dictionary
equip_instance(instance_id: String, slot_id: String, player: Player) -> Dictionary
unequip_slot(slot_id: String) -> Dictionary
```

The UI, shops, save loader, and gameplay code must not independently infer slots from `weapon_type`, `armor_type`, or attack bonuses. Slot identity comes from canonical item metadata.

### 5.2 Equipment stat ownership

`Inventory.equipment` remains the owned equipment state. `player_controller.gd` remains the current integration point for applying equipment totals until a dedicated component is architect-approved.

Stat application must:

- Rebuild totals from equipped instances instead of incrementally stacking bonuses.
- Remove old equipment contribution before applying new totals.
- Apply base item stats, standard rolls, and affixes exactly once.
- Clamp current HP and mana when maximum values decrease.
- Preserve current HP/mana proportion only if the final implementation explicitly chooses that rule.
- Emit relevant stat signals after recalculation.

Do not maintain a second independent equipment model with different slot contents.

---

## 6. Item Progression: Material Tier + Rarity

Items use two separate progression systems:

```text
Material tier = base power / level requirement
Rarity = number and quality of affixes
```

The static `item_id` identifies the base definition, not a specific rolled copy. For example, all rolled Bronze Swords use `item_id = "bronze_sword"` and differ through their owned instance data.

### 6.1 Material Tiers

Use these tiers for weapons and armor:

```text
Bronze      level 1
Steel       level 5
Adamant     level 10
Mythril     level 15
Orichalcum  level 20
```

Examples:

```text
Bronze Sword
Steel Bow
Adamant Staff
Mythril Headgear
Orichalcum Overall
```

Armor uses the same tier naming as weapons.

Accessories are only rarity-based for now:

```text
Common Amulet
Rare Ring
Epic Amulet
Legendary Ring
```

Material tiers use lowercase save/data IDs:

```text
bronze
steel
adamant
mythril
orichalcum
```

Display names may use title case. Existing item IDs and assets remain valid; new tiered items must be added as per-item JSON definitions and registered through the existing folder loader.

---

## 7. Rarity System

Rarities:

```text
Common    grey
Rare      blue
Epic      purple
Legendary orange
```

Canonical rarity IDs:

```text
common
rare
epic
legendary
```

Unique items are not included yet. They may be added later.

Rarity affects:

```text
- affix count
- affix strength range
- drop chance
- item border color
- tooltip/title color
```

### 7.1 Rarity Affix Rules

Every equipment item has:

```text
1. Fixed base stat from item type and material tier
2. Standard roll, even on common items
3. Extra affixes based on rarity
```

Recommended rarity structure:

```text
Common:
- base stat
- standard roll only

Rare:
- base stat
- better standard roll
- 1 extra affix

Epic:
- base stat
- stronger standard roll
- 2 extra affixes

Legendary:
- base stat
- strongest standard roll
- 3 extra affixes
```

Example standard roll ranges for weapon damage:

```text
Common:    +1 to +5
Rare:      +3 to +8
Epic:      +6 to +12
Legendary: +10 to +18
```

These numbers are starting examples only. The agent may propose balanced tables.

Roll rules:

- Base stats come from the static item definition.
- The standard roll is generated once when the item instance is created.
- Affixes are generated once and stored on the instance.
- Reloading, equipping, dropping, selling, or buying back must not reroll an item.
- Affixes cannot duplicate the same stat unless the affix definition explicitly allows stacking.
- All rolled numeric values must be clamped to their configured range.
- A generated instance should store its final rolled values. An optional generation seed may also be stored for debugging, but saves must not depend on rerunning a random generator to reconstruct the item.

---

## 8. Stat and Affix Pools

Keep the first version simple.

### 8.1 Weapon Affixes

Allowed now:

```text
+attack
+crit chance
+crit damage
+attack speed
```

Not yet, but planned later:

```text
elemental damage
life on hit
mana on hit
```

### 8.2 Armor Affixes

Allowed now:

```text
+max hp
+max mana
+defense
+move speed, mainly boots
+cooldown reduction
+status resistance
```

Do not include evasion for now.

### 8.3 Accessory Affixes

Allowed now:

```text
+crit chance
+crit damage
+max mana
+max hp
+attack
+defense
+cooldown reduction
```

Not yet:

```text
elemental bonus
gold find
drop rate
```

### 8.4 Canonical stat keys

Use these data keys consistently:

```text
attack
defense
max_hp
max_mana
move_speed
attack_speed
crit_chance
crit_damage
cooldown_reduction
status_resistance
spell_damage
```

Value conventions:

```text
Flat integers:
  attack, defense, max_hp, max_mana, spell_damage

Decimal ratios:
  crit_chance, crit_damage, cooldown_reduction, status_resistance

Decimal multipliers or flat speed values, chosen once and documented:
  move_speed, attack_speed
```

The first implementation must not add an affix until its runtime consumer exists:

- `crit_chance` and `crit_damage` must feed combat critical-hit calculation.
- `cooldown_reduction` must modify cooldown duration when `AbilityManager` starts a cooldown.
- `status_resistance` must modify eligible hostile status durations or application chance in the status system.
- `move_speed` and `attack_speed` must feed the player movement and attack timing paths.
- `spell_damage` must affect ability damage without modifying unrelated healing unless specified.

Unknown stat keys should fail validation in development instead of being silently ignored.

Stat operation order:

1. Start from player/class base stat.
2. Add item base stats.
3. Add standard rolls.
4. Add flat affixes (`operation: "add"`).
5. Combine percentage modifiers (`operation: "percent_add"`).
6. Apply final multipliers only when explicitly supported.
7. Clamp to stat-specific minimums and maximums.

Do not mix percentages represented as `3`, `0.03`, and `"3%"`. Persist decimal ratios such as `0.03` and format them for display.

---

## 9. Item Actions

Core item actions:

```text
Equip
Unequip
Compare
Drop
Lock
Sell, inside shops only
```

Current tooltip should **not** show all actions yet, because that becomes too cluttered.

Suggested behavior:

```text
Tap item once:
- select item
- show tooltip and comparison

Tap item twice or press contextual button:
- equip/use if possible

Long press or secondary menu later:
- lock/drop/sell
```

Locked item behavior:

```text
Locked items cannot be dropped.
Locked items cannot be sold.
Locked items can still be equipped/unequipped.
```

Lock state belongs to the owned item instance, not the static item definition.

Dropped items:

```text
Dropped items appear on the ground.
Dropped items can be picked up again.
```

Dropping an item must preserve its exact `instance_id`, rarity, rolls, affixes, and lock state. A generated item must never be converted back into only an `item_id` when it becomes a world pickup.

World pickup compatibility:

- Extend the existing `item_pickup.tscn` and `item_pickup.gd`.
- Gold remains automatic.
- Non-gold items use explicit tap/click or `interact` pickup under the new rule.
- Entering the pickup area may highlight or select the item, but must not consume it automatically.
- The pickup stores `item_id`, quantity, and optional `instance_data`.
- If only part of a stack fits, update the pickup quantity to the remaining amount.
- If no quantity fits, show `Inventory full` and leave the pickup unchanged.

World-drop lifetime for the first version:

- Pickups exist for the current loaded map session.
- They are not required to persist after leaving/reloading the map.
- The Drop confirmation must state that an uncollected dropped item disappears when the area unloads.
- If persistent world drops are added later, they must serialize full instance data keyed by map ID.

---

## 10. Tooltip and Comparison Panel

The tooltip/comparison panel appears between equipment and inventory.

It should show:

```text
Item name
Rarity color
Item type
Slot
Required level
Material tier, if applicable
Base stats
Standard roll
Affixes
Sell value
Comparison versus currently equipped item
```

Comparison display:

```text
Green = stat increase
Red = stat decrease
Neutral/grey = unchanged
```

Comparison rules:

- Compare the candidate's total contribution: base stats + standard roll + affixes.
- Compare only stats affected by either the candidate or equipped item.
- Use canonical final units, including percentage formatting for ratio stats.
- Weapon, off-hand, armor, and amulet items compare against their matching slot.
- Rings show both `ring_1` and `ring_2` comparisons or let the player choose the replacement slot; do not silently replace a ring.
- Comparison is informational. Equipping still runs full centralized validation.
- Requirements the player does not meet are shown clearly and disable equip.

Do not show all item actions inside the comparison panel yet.

Optional later:

```text
flavor text
source monster
drop location
special tags
```

---

## 11. Consumables

Start with only:

```text
Health Potion
Mana Potion
```

Potion stack size:

```text
20
```

This replaces the current prototype value of 99. Update the potion JSON definitions to `max_stack: 20` when the stack-splitting inventory logic is ready. During save migration, stacks above 20 are split across available consumable slots; they are never truncated.

Consumable use rules:

- Item effects come from static item data.
- The inventory owns quantity removal.
- Apply the effect first, then consume one item only when the effect succeeds.
- Health potions are not consumed at full health.
- Mana potions are not consumed at full mana.
- Repeated taps must not consume multiple items in the same input event.
- Using the final item clears the slot and emits one inventory update.
- Consumption must work from both desktop input and mobile UI.

Recommended API:

```gdscript
use_item_at(tab_id: String, slot_index: int, user: Player) -> Dictionary
```

Do not implement potion behavior independently inside UI buttons.

Future consumables:

```text
Cleanse / antidote
Town portal / recall scroll
Temporary attack potion
Temporary defense potion
```

Do not implement these future items yet unless requested.

---

## 12. Materials and Quest Items

No crafting yet.

Materials exist as monster-specific drops:

```text
slime_gel
bone
bat_wing
wolf_pelt
stone_core
```

`slime_gel` and `bone` are existing canonical IDs and must not be renamed. New IDs such as `bat_wing`, `wolf_pelt`, and `stone_core` require matching JSON definitions before any quest or loot table references them.

Materials can be used later for crafting, upgrades, quests, or shops.

Quest item behavior:

```text
Quest items can stack only up to the amount required for the quest.
Quest items should not clutter the equipment tab.
Quest items belong in the Materials / Quest Items tab.
```

Quest-item cap rules:

- The cap is derived from active quest objectives that reference the item.
- If several active objectives require the same item, use the sum of their remaining requirements.
- Items that are also ordinary materials are not capped unless their item definition explicitly marks them as quest-only.
- Quest-only items cannot be sold, dropped, or destroyed.
- Turning in a quest removes only the required amount.

---

## 13. Loot Drop Rules

Monster drops:

```text
- Gold
- Monster-specific material
- Occasional potion
- Rare equipment drop
```

Loot must be data-driven. `monster_base.gd` currently hardcodes a 30% material drop and chooses only `slime_gel` or `bone`; this is legacy behavior to migrate away from.

Target integration:

```text
res://data/loot/loot_tables.json
res://scripts/inventory/loot_dropper.gd
```

Each monster definition may reference:

```json
{
  "loot_table": "slime_low"
}
```

Each loot-table entry defines:

```text
item_id or equipment pool
minimum quantity
maximum quantity
drop chance or weight
minimum monster/zone tier
rarity eligibility
independent roll vs weighted exclusive group
```

Do not combine independent probability rolls and weighted-choice entries without an explicit group type.

Gold behavior:

```text
Gold is auto-picked up.
Gold can be shown as a floating pickup message.
```

Item behavior:

```text
Items drop on the ground.
Player must tap/click or interact to pick up.
Accept any quantity that fits. If none fits, show "Inventory full"; leave the unaccepted quantity on the ground.
```

### 13.1 Drop Priority

Basic monster drop profile:

```text
Gold: common
Monster material: common or uncommon
Potion: occasional
Equipment: uncommon to rare, depending on monster/area
Legendary equipment: very rare
```

Suggested first-pass equipment rarity weights after an equipment drop has been selected:

```text
Common:     75.0%
Rare:       20.0%
Epic:        4.5%
Legendary:   0.5%
```

These values must live in data, not hardcoded UI or monster scripts.

### 13.2 Simple Pseudo-Random / Pity System

Use a simple bad-luck protection system.

Design goal:

```text
The player should not go extremely long without meaningful loot.
```

Simple first version:

```text
- Track kills since last rare-or-better equipment drop.
- Each eligible kill slightly increases rare/epic/legendary chance.
- When rare-or-better equipment drops, reset the counter.
- Legendary remains rare even with pity.
```

Initial pity contract:

```text
eligible_kills_since_rare:
  increments after an eligible kill that does not produce rare-or-better equipment
  begins increasing rare-or-better chance after 8 eligible kills
  adds 1.0 percentage point per eligible kill
  caps at +20 percentage points
  guarantees at least Rare equipment on the 30th eligible kill
  resets only when Rare, Epic, or Legendary equipment is successfully created

eligible_kills_since_epic:
  increments after an eligible kill that does not produce epic-or-better equipment
  begins increasing Epic chance after 30 eligible kills
  adds 0.10 percentage points per eligible kill
  caps at +3 percentage points
  resets only on Epic or Legendary equipment

Legendary:
  receives no hard guarantee in the first version
  may receive only the capped global rarity modifier configured in loot data
```

An eligible kill is a kill from a monster whose loot table contains an equipment pool appropriate for the player/zone. Summoned enemies, training targets, repeatedly spawned tutorial dummies, and safe-zone enemies are not eligible.

Pity state:

- Belongs to player save state.
- Is updated once per eligible monster death.
- Is not reset by loading, map transitions, game restart, inventory-full failure, or dropping an item.
- Does not reset when an equipment roll is selected but cannot be delivered because inventory and ground-drop creation both fail.
- Must be saved immediately with normal save flow so save/reload cannot reroll the same kill.

The pity calculation must be unit-testable independently from scene spawning.

---

## 14. Basic Shop and Economy Rules

Include basic shop/economy rules for now.

Shop tabs should match inventory categories:

```text
Weapons / Armor
Consumables
Materials
Special
```

Initial shop behavior:

```text
Shops can sell consumables and basic equipment.
Shops do not sell materials yet.
Materials can be sold to shops.
Materials can be bought back for the same price they were sold for.
```

Sell value rules:

```text
Equipment sells for 35% of buy/base value.
Consumables sell for 50% of buy value.
Materials sell for their listed material value.
Materials buyback for the same value.
```

Generated equipment uses the definition's base value multiplied by a data-driven rarity value multiplier before the 35% sell rule. Price calculation belongs in one shared shop/economy function so tooltips and transactions cannot disagree.

Future economy agent may overwrite this later.

Shop integration rules:

- Keep per-shop JSON files under `res://data/shops/`.
- `ShopManager` is the transaction authority.
- `shop_ui.gd` displays state and calls `ShopManager`; it must not maintain separate buy/sell calculations.
- Shop inventory references static `item_id` values and prices.
- Purchasing equipment creates a new item instance with the shop-configured fixed rarity or roll policy.
- Selling generated equipment transfers the exact instance to buyback; it must not lose rolls, affixes, or lock state.
- Locked and quest-only items cannot be sold.
- Every transaction is atomic: gold and item transfer either both succeed or neither changes.
- Quantity purchases must respect stack capacity before charging gold.

Material buyback:

```text
- Buyback is scoped to the current shop session in the first version.
- It stores the exact sold item/quantity and sale price.
- Buying back costs exactly the amount paid to the player.
- Closing the shop clears the session buyback list unless persistence is explicitly added later.
- A partial buyback updates the remaining quantity.
```

Do not advertise buyback persistence across game restarts unless it is included in save data.

---

## 15. Item Icon Style Guide

The item icons should be suitable for inventory slots and readable on mobile.

Style direction:

```text
Fantasy RPG item icons
Clean readable silhouette
Slightly polished / painterly feel
Strong material progression
Dark or transparent background compatibility
Readable at small size
Not overly noisy
```

Weapon progression should be visually obvious:

```text
Bronze = warm brown/copper
Steel = silver/grey
Adamant = green or deep fantasy metal tone
Mythril = bright blue/cyan fantasy metal
Orichalcum = ornate red/gold/orange legendary metal
```

Bow progression should follow the same tier logic:

```text
Bronze/early = simple wooden bow
Steel = reinforced metal details
Adamant = green accents
Mythril = blue/icy magical accents
Orichalcum = ornate red/gold high-tier bow
```

Icon rules:

```text
- One item centered in the icon.
- No complex background.
- Strong outline or contrast.
- Use consistent angle/perspective per weapon family.
- Icons should fit square inventory slots.
- Avoid text inside icons.
- Keep a small amount of glow for high-tier items, but do not overdo it.
```

Do not generate final icon assets in the first pass.  
First create an icon style sheet and item icon prompt list only if requested.

---

## 16. Data Schema Expectations

### 16.1 Static item definitions

Keep one JSON file per definition:

```text
res://data/items/<item_id>.json
```

Example `res://data/items/bronze_sword.json`:

```json
{
  "schema_version": 2,
  "item_id": "bronze_sword",
  "item_name": "Bronze Sword",
  "description": "A worn bronze sword suited to a new adventurer.",
  "item_type": 0,
  "category": "equipment",
  "slot": "weapon",
  "weapon_type": 0,
  "material_tier": "bronze",
  "required_level": 1,
  "allowed_classes": [],
  "stackable": false,
  "max_stack": 1,
  "icon": "res://assets/sprites/weapons/sword_bronze.png",
  "base_stats": {
    "attack": 12,
    "attack_speed": 1.0
  },
  "standard_roll": {
    "attack": {
      "min": 1,
      "max": 5
    }
  },
  "affix_pool": "weapon_basic",
  "fixed_rarity": "",
  "buy_price": 100,
  "sell_price": 35
}
```

Compatibility rules:

- Existing numeric `item_type`, `weapon_type`, and `armor_type` values remain readable.
- New `category` and `slot` fields are authoritative for tabs and equipment placement.
- An empty `allowed_classes` array means all classes may equip the item.
- `DataRegistry` must accept old definitions that store fields such as `damage`, `defense`, `hp_bonus`, or `attack_bonus` at the top level and normalize them into `base_stats`.
- Existing files can be migrated incrementally; all files do not need to change in one commit.
- Static definitions may specify `fixed_rarity: "common"` for deterministic starter/shop items. An empty value allows the item generator to choose rarity.

### 16.2 Owned item instances

Generated equipment is represented by instance data stored alongside its static definition reference:

```json
{
  "instance_schema_version": 1,
  "instance_id": "item_000123",
  "item_id": "bronze_sword",
  "rarity": "rare",
  "rolled_stats": {
    "attack": 6
  },
  "affixes": [
    {
      "affix_id": "keen_1",
      "stat": "crit_chance",
      "operation": "add",
      "value": 0.03
    }
  ],
  "is_locked": false,
  "acquired_sequence": 42
}
```

Rules:

- `instance_id` is globally unique within a save.
- Stackable consumables/materials normally have no instance data.
- Generated equipment always has instance data and quantity 1.
- Fixed starter equipment may be converted into a common instance during migration.
- `DataRegistry` caches static definitions only. It must not reuse mutable instance dictionaries between owned items.

### 16.3 Inventory slot save structure

```json
{
  "tab": "equipment",
  "item_id": "bronze_sword",
  "quantity": 1,
  "instance": {
    "instance_schema_version": 1,
    "instance_id": "item_000123",
    "item_id": "bronze_sword",
    "rarity": "rare",
    "rolled_stats": {
      "attack": 6
    },
    "affixes": [],
    "is_locked": false,
    "acquired_sequence": 42
  }
}
```

Stackable slot example:

```json
{
  "tab": "consumables",
  "item_id": "health_potion",
  "quantity": 12,
  "instance": null
}
```

### 16.4 Equipment save structure

```json
{
  "weapon": {
    "item_id": "bronze_sword",
    "instance": {
      "instance_schema_version": 1,
      "instance_id": "item_000123",
      "item_id": "bronze_sword",
      "rarity": "rare",
      "rolled_stats": {
        "attack": 6
      },
      "affixes": [],
      "is_locked": false,
      "acquired_sequence": 42
    }
  },
  "off_hand": null,
  "headgear": null,
  "overall": null,
  "armguards": null,
  "boots": null,
  "amulet": null,
  "ring_1": null,
  "ring_2": null
}
```

Important distinction:

```text
Item definition = immutable shared content loaded from per-item JSON.
Item instance = a specific owned or dropped equipment copy with permanent rolls.
Inventory slot = placement and quantity information.
Equipment slot = equipped placement of one exact item instance.
```

---

## 17. Save Versioning and Migration

The current save format is version 1 and stores inventory entries as only `item_id` plus quantity, with legacy equipment keys.

The new implementation must introduce a new save version only after a migration function exists.

This is a payload migration inside the character autosave. `SaveManager` owns `user://saves/index.json`, atomic character writes, backup recovery, and the outer migration from `user://saves/slot_1.json`. Inventory code must not read or write `user://settings.json`.

Required migration behavior:

```text
Version 1 inventory:
  [{ "item_id": "health_potion", "quantity": 30 }]

Version 1 equipment:
  {
    "weapon": "bronze_sword",
    "armor": "bronze_armor",
    "helmet": "bronze_helmet",
    "accessory": "leather_bracelet"
  }
```

Migration steps:

1. Load the static definition for each legacy `item_id`.
2. Route each inventory item into its target tab.
3. Split stacks according to the new `max_stack`.
4. Convert legacy equipped items into common fixed instances.
5. Map legacy equipment keys to canonical keys.
6. Generate stable unique `instance_id` values for migrated equipment.
7. Preserve gold and all unrelated player/quest/map state.
8. Initialize pity counters to zero when absent.
9. Save in the new format only after the migrated state validates.
10. Return the migrated inventory/equipment payload to `SaveManager`; do not create a second save index or slot owner.

Failure handling:

- Keep the original save file until the migrated save has been written successfully.
- Log missing item definitions with exact item IDs.
- Do not silently discard unknown or overflow items.
- If migration cannot complete, report the problem and leave the original save usable.

New save data must include:

```text
inventory tabs and slots
canonical equipment slots
full generated item instances
next item instance sequence/id state
acquisition sequence
loot pity counters
```

All enabled equipment modifiers must expose normalized stats to the central `DamageCalculator`. V1 damage types remain `physical`, `spell`, `poison`, and `true`; elemental affixes stay inactive until their runtime consumers are reviewed.

---

## 18. Implementation Sequence

Implement in this order:

### Phase A: Normalize current data

- Extend `DataRegistry` to normalize old and new item fields.
- Load aggregate itemization configuration from `res://data/itemization/` and loot tables from `res://data/loot/`; do not allow those files to enter `DataRegistry.items`.
- Add canonical category and slot metadata.
- Preserve all current item IDs and existing gameplay.
- Add data validation for unknown slots, categories, stats, affixes, and missing icons.
- Normalize shop aliases (`name`/`shop_name`, `inventory`/`items`, `price`/`buy_price`, `stock`/`quantity`) while old files are migrated.
- Correct `leather_bracelet` from legacy material classification to equipment slot `amulet`.
- Change health and mana potion `max_stack` from 99 to 20 only when stack splitting and save migration are active.
- Validate every item reference from shops, quests, starting equipment, loot tables, and pickups.
- Add or remove unresolved current references before marking the phase complete. The Phase A package resolved the following historical reference list; strict validation must prevent regressions:

```text
antidote
apprentice_staff
cloth_robe
healing_herb
herb_healing
iron_armor
iron_pickaxe
iron_sword
leather_armor
miners_helmet
ranger_cloak
revive_scroll
short_bow
steel_armor
steel_sword
stone_core
wooden_sword
```

Future consumables such as `antidote` and `revive_scroll` remain non-goals unless their current shop references are removed or explicitly activated.

Phase A approval command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tools\run_architect_review.ps1" -GodotBin "<path-to-godot-console.exe>" -StrictItemData
```

Normal architect runs allow only the explicitly recorded baseline debt. Strict mode requires canonical routing metadata, zero unresolved references, and an empty baseline list.

### Phase B: Safe stack and tab inventory

- Add detailed add/remove results.
- Enforce `max_stack`.
- Add three 24-slot tabs.
- Add legacy 30-slot migration.
- Update pickup and shop callers to handle partial quantities.

### Phase C: Canonical equipment slots

- Add the nine canonical slots.
- Add atomic equip/unequip/swap validation.
- Migrate legacy slot keys.
- Expand player equipment stat rebuilding.

### Phase D: Item instances, rarity, and affixes

- Add instance generation and unique IDs.
- Store rolls, affixes, rarity, lock state, and acquisition order.
- Update UI, pickups, drops, shops, and save/load to preserve exact instances.

### Phase E: Data-driven loot and pity

- Add loot-table data and `loot_dropper.gd`.
- Replace hardcoded material drops per migrated monster.
- Add persisted and tested pity counters.

### Phase F: UI and economy completion

- Add responsive tabs and comparison UI.
- Consolidate transactions through `ShopManager`.
- Add session buyback.
- Add sorting and lock/drop actions.

Each phase must pass validation before the next phase changes save data or public APIs.

---

## 19. Deliverables for This Agent

Required deliverables:

```text
1. Inventory and equipment UI design spec.
2. Equipment slot spec.
3. Item tier and rarity spec.
4. Affix and stat pool spec.
5. Loot/drop-rate spec.
6. Simple pity-system spec.
7. Shop/economy starting rules.
8. Tooltip/comparison behavior spec.
9. Item icon style guide.
10. JSON schemas for item definitions, item instances, inventory slots, equipment slots, loot tables, and pity state.
11. Save migration implementation and tests.
12. Updated scenes/scripts/data files following the implementation sequence.
13. Architect handoff using `docs/agent_handoff_template.md`.
```

Optional later deliverables:

```text
- Wireframe image prompt
- Example JSON item pack
- Example shop data
- Example loot table data
- Item icon prompt list
```

Do not merge implementation until the architect review passes and the result is recorded in `docs/agent_integration_log.md`.

---

## 20. Files the Agent May Create or Update

Prefer updating existing integration points. New files should cover genuinely new responsibilities rather than duplicate current models.

```text
res://data/itemization/item_tiers.json
res://data/itemization/affixes.json
res://data/loot/loot_tables.json
res://data/items/<item_id>.json
res://data/shops/<shop_id>.json

res://scenes/ui/inventory_ui.tscn
res://scenes/ui/item_tooltip.tscn
res://scenes/items/item_pickup.tscn

res://scripts/autoload/data_registry.gd
res://scripts/autoload/save_manager.gd
res://scripts/autoload/shop_manager.gd
res://scripts/inventory/inventory_system.gd
res://scripts/inventory/item_data.gd
res://scripts/inventory/weapon_data.gd
res://scripts/inventory/armor_data.gd
res://scripts/inventory/item_generator.gd
res://scripts/inventory/loot_dropper.gd
res://scripts/ui/inventory_ui.gd
res://scripts/ui/item_tooltip.gd
res://scripts/ui/shop_ui.gd
```

Do not add a new `InventoryManager` autoload while inventory remains owned by the player unless an architect-approved ownership migration is part of the same reviewed change.

---

## 21. Non-Goals for This Agent

Do not design or implement these yet:

```text
Crafting system
Upgrade system
Unique items
Set bonuses
Two-handed weapon behavior
Elemental damage affixes
Life on hit / mana on hit
Gold find / drop rate stats
Complex auction/trading
Real-money purchases
Full economy rebalance
```

These can be separate later systems.

---

## 22. Review Checklist

Before approval, the Lead Architect should check:

```text
- Does it follow the Main MD?
- Is it Godot 4 / GDScript compatible?
- Does it avoid Python architecture?
- Does it keep inventory mobile-friendly?
- Does it preserve the existing project structure?
- Does it extend the current Inventory/DataRegistry/SaveManager path instead of creating parallel state?
- Does inventory remain a standalone window opened through the HUD-owned menu coordinator?
- Does the migration preserve the character autosave/index contract without touching `user://settings.json`?
- Do equipment combat stats feed `DamageCalculator` rather than a local final-damage formula?
- Are item definitions and item instances separated?
- Are exact generated instances preserved through equip, drop, sell, buyback, save, and load?
- Are inventory tabs and equipment slots clear?
- Are old 30-slot saves and legacy equipment keys migrated without item loss?
- Are stack limits enforced with splitting and partial pickup behavior?
- Are rarity and material tier separated?
- Does every enabled affix have a tested runtime consumer?
- Are drop rules simple enough for first implementation?
- Are loot tables data-driven and are pity counters persisted?
- Are shops/economy basic and not overbuilt?
- Are shop transactions atomic and centralized through ShopManager?
- Do all referenced item IDs resolve to definitions?
- Are item icons described clearly enough for a future sprite/icon agent?
```

Required functional validation:

1. Load a version 1 save containing inventory and all four legacy equipment keys.
2. Confirm no item or gold loss after migration.
3. Split a potion stack above 20 across consumable slots.
4. Attempt a partial pickup with one nearly full stack and no extra slot.
5. Equip an item while the destination slot is occupied and inventory is full; verify no state changes.
6. Save/load Rare or better equipment and compare every roll, affix, lock flag, and instance ID.
7. Drop and repick the same generated item without rerolling it.
8. Sell and buy back a generated item without changing it.
9. Verify locked and quest-only items cannot be sold or dropped.
10. Verify pity counters persist through save/load and reset only on the specified rarity.
11. Verify all active shop, quest, starting-equipment, pickup, and loot-table item references resolve.
12. Validate the inventory UI at desktop and 640x360 viewport sizes.

Run the project architect review after domain tests:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tools\run_architect_review.ps1" -GodotBin "<path-to-godot-console.exe>"
```

Record the reviewed result in `docs/agent_integration_log.md`.
