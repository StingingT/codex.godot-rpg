Use the master plan and routed domain guide for normal work. Use `$godogen` only when the user explicitly requests full-game generation and the skill is available.

**Project:** Umbral Explorers: Relics of Grimvale
**Skills by role:** [docs/agent_skills_required.md](docs/agent_skills_required.md)
**Master plan:** [Main_ChatGPT-Godot_RPG_Implementation_Plan.md](Main_ChatGPT-Godot_RPG_Implementation_Plan.md)
**Architect review:** [docs/architect_review_checklist.md](docs/architect_review_checklist.md)
**Current work orders:** [docs/architect_agent_work_orders.md](docs/architect_agent_work_orders.md)
**Agent handoff:** [docs/agent_handoff_template.md](docs/agent_handoff_template.md)
**Integration log:** [docs/agent_integration_log.md](docs/agent_integration_log.md)

| Role | Doc |
|------|-----|
| Implementation (default) | Main plan + domain guides in `docs/` |
| Lore / world / content naming | [docs/Grimvale_Lore_World_Tone_Foundation.md](docs/Grimvale_Lore_World_Tone_Foundation.md) |
| Menu / game flow / settings | [docs/Menu_Game_Flow_Settings_Agent_Instructions.md](docs/Menu_Game_Flow_Settings_Agent_Instructions.md) |
| Combat / abilities / feedback | [docs/Combat_Ability_Logic_Feedback_Agent_Instructions.md](docs/Combat_Ability_Logic_Feedback_Agent_Instructions.md) |
| Monster sprites | [docs/external_sprite_agent_instructions.md](docs/external_sprite_agent_instructions.md) + `.cursor/skills/monster-sprite-agent` |
| Monsters (code/data) | [docs/monster_design_bible.md](docs/monster_design_bible.md) |
| Maps / tileset | [docs/custom_tileset_object_kit_instructions.md](docs/custom_tileset_object_kit_instructions.md) |
| Skill tree | [docs/RPG_Skill_Tree_Agent_Guide.md](docs/RPG_Skill_Tree_Agent_Guide.md) |
| Inventory / equipment / loot | [docs/Inventory_Equipment_Itemization_Loot_Agent_Instructions.md](docs/Inventory_Equipment_Itemization_Loot_Agent_Instructions.md) |

**Locked defaults:** heroic mystery with bright blue/gold guild identity and darker readable Umbral regions; Warrior playable in v1; Ranger/Mage disabled as **Coming Later**; one character-ID autosave plus index; global settings stored separately; one HUD modal coordinator; one `DamageCalculator`; one combat feedback owner; no v1 screen shake or hit-stop.

Before editing, send the architect the intended files, dependencies, assumptions, and validation plan. After editing, submit the handoff and validation evidence to the architect. Do not merge, commit, push, or pass work to another agent until the architect records **Ready**.
