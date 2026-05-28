# Unused Variables and Code Report

## DEFINITELY UNUSED (Safe to Remove)

### Variables
1. **bob_offset** in `scenes/items/item_pickup.gd` (line 10)
   - Declared but never referenced
   
2. **bob_speed** in `scenes/items/item_pickup.gd` (line 11)
   - Declared but never referenced
   
3. **bob_offset** in `scenes/items/gold_pickup.gd` (line 8)
   - Declared but never referenced
   
4. **bob_speed** in `scenes/items/gold_pickup.gd` (line 9)
   - Declared but never referenced

5. **current_quest_index** in `scripts/npcs/quest_npc.gd` (line 7)
   - Declared but never used

## PARTIALLY USED (Used in some places, not others)

### Signals (Declared but rarely connected)
- `supabase_client.gd` signals: authenticated, authentication_failed, save_uploaded, save_downloaded
  - Only `leaderboard_loaded` is connected in `leaderboard_ui.gd`
  
- `iap_manager.gd` signals: products_loaded, purchase_started, purchase_completed, purchase_failed, purchase_restored
  - These are emitted but never connected to any handlers

### @export Variables (Used by Godot inspector, not in code)
Many @export variables appear unused in code but are actually used by:
- Godot's inspector/editor
- Other scripts accessing them via properties
- Resource files setting their values

Examples:
- `player_class.gd`: player_class_name, description, base_stats, stat_growth, starting_skills, skill_tree
- `skill_node.gd`: skill_name, description, node_type, tier, prerequisites, cost, icon, stat_bonuses, passive_effects, active_skill
- `item_data.gd`: item_id, item_name, description, item_type, icon, sprite, etc.

## RECOMMENDATIONS

### Safe to Remove:
```gdscript
# In item_pickup.gd and gold_pickup.gd, remove:
var bob_offset: float = 0.0
var bob_speed: float = 3.0

# In quest_npc.gd, remove:
var current_quest_index: int = 0
```

### Consider Removing (if features not needed):
- Unused IAP signals if in-app purchases aren't implemented
- Unused Supabase signals if cloud saves aren't implemented

### Keep (used by Godot/editor):
- All @export variables in resource classes
- Signal declarations that might be used for future features
