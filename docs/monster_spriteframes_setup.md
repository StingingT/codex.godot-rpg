# Monster SpriteFrames Setup

**Project:** Umbral Explorers: Relics of Grimvale

**Tone:** Follow [Grimvale_Lore_World_Tone_Foundation.md](Grimvale_Lore_World_Tone_Foundation.md) and [monster_design_bible.md](monster_design_bible.md); readable heroic mystery first, darker Umbral escalation second.

**Sprite production:** [external_sprite_agent_instructions.md](external_sprite_agent_instructions.md)

**Godot wiring:** [monster_design_bible.md](monster_design_bible.md) §22

**Handoff:** [sprite_deliverables/manifest.json](sprite_deliverables/manifest.json)

## Battle sheets (delivered art)

Sprite agent saves grids to `res://assets/sprites/monsters/battle/{monster_id}_sheet.png`.

Row order and Godot names:

| Row | Animation |
|-----|-----------|
| 1 | `idle` |
| 2 | `move` |
| 3 | `attack` |
| 4 | `hit` |
| 5 | `death` |
| 6 | `spawn` |

Implementation agent builds `*_frames.tres` from the delivered sheet. Do not use `walk` on monsters.

## Legacy placeholders

Older assets may still live at `res://assets/sprites/monsters/` root (`slime_spritesheet.png`, `bat_spritesheet.png`, etc.) or 256×256 4×4 grids in:

- `slime_green_frames.tres`
- `slime_fire_frames.tres`
- `ghost_frames.tres`

Migrate to `battle/` paths when manifest PNGs exist.

## Codex portraits

Static menu art: `res://assets/sprites/monsters/codex/{monster_id}_portrait.png` — not used for `AnimatedSprite2D` combat.
