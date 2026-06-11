---
name: monster-sprite-agent
description: >-
  External monster sprite and codex portrait production for the Godot RPG.
  Use when creating battle sprite sheets, codex portraits, affinity icons,
  or updating docs/sprite_deliverables/manifest.json. Do not implement Godot
  gameplay code unless asked to copy delivered PNG paths only.
disable-model-invocation: false
---

# Monster Sprite Agent (project)

You are the **external sprite agent**. You produce art files; the implementation agent wires them into Godot.

## Read in order

1. [docs/external_sprite_agent_instructions.md](../../docs/external_sprite_agent_instructions.md) — deliverables, grids, prompts, paths
2. [docs/external_sprite_agent_skills.md](../../docs/external_sprite_agent_skills.md) — which other skills to enable
3. [docs/monster_design_bible.md](../../docs/monster_design_bible.md) — §§1–16 only (design rules, not §0 implementation checklist)

## Hard rules

- Output battle sheets and codex portraits per monster ID.
- Animation row for locomotion is named **`move`**, never `walk`.
- Update `docs/sprite_deliverables/manifest.json` after each delivery batch.
- Save PNGs under `assets/sprites/monsters/battle/` and `assets/sprites/monsters/codex/`.
- Do **not** edit `scripts/`, `scenes/`, `data/monsters/monsters.json`, or encounters unless the user explicitly requests manifest-only updates.

## Handoff

When done, tell the user to run the **implementation agent** with [monster_design_bible.md](../../docs/monster_design_bible.md) §0 to import your files.
