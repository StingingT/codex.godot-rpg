# External Monster Sprite Agent — Instructions

**Project:** Umbral Explorers: Relics of Grimvale  
**Audience:** Dedicated art / sprite agent (Cursor, Codex, ComfyUI workflow, or human lead).  
**Do not:** Edit Godot scenes, scripts, `monsters.json`, or encounter tables unless the user explicitly asks you to import files only.

**Read first:** [Grimvale_Lore_World_Tone_Foundation.md](Grimvale_Lore_World_Tone_Foundation.md) for tone, then [monster_design_bible.md](monster_design_bible.md) §§1–16 for monster rules.  
**Skills to enable:** [external_sprite_agent_skills.md](external_sprite_agent_skills.md) or [agent_skills_required.md](agent_skills_required.md) §2.

---

## 1. Your job

Produce **two asset types** per monster (when in the active roster):

| Asset | Purpose | Typical size |
|-------|---------|--------------|
| **Battle sprite sheet** | In-world combat, `AnimatedSprite2D` | 48×48 to 128×128 per frame (see bible §4) |
| **Codex portrait** | Monster Codex menu — static illustration | 96×96 or 128×128 (can be larger if downscaled in UI) |

The implementation agent wires these into Godot. You deliver **files + manifest**, not game logic.

---

## 2. Style target (match the Monster Codex mockup)

**Reference look:** detailed pixel art, strong silhouette, soft drop shadow under the creature, readable at small size, heroic-mystery fantasy with darker Umbral accents on elites.

**Codex portrait style (menu):**

- Slight **three-quarter / top-down** hero pose (one frame, not a sheet).
- **Parchment-friendly** composition — subject centered, margin for UI frame.
- **Family-consistent** identifiers (slime core, bat ears, skull head, etc.).
- **Affinity** subtle on body; full clarity via separate **affinity icons** (implementation agent places icons in UI).
- Tone: dangerous but readable; **no gore**.

**Battle sheet style (gameplay):**

- Same character design as codex portrait but simplified for **4–6 frame loops**.
- Fewer highlights than codex; stronger outline for busy maps.
- Transparent background; no baked ground shadow in sheet cells (Godot handles y-sort).

If a reference image is provided in the repo under `docs/reference/`, match its **rendering quality and framing** for codex portraits.

---

## 3. Output paths and naming

Save all deliverables under:

```text
res://assets/sprites/monsters/
  battle/
    {monster_id}_sheet.png
  codex/
    {monster_id}_portrait.png
  icons/
    affinity_{affinity_id}.png    # shared UI icons, 16x16 or 24x24
```

**Monster IDs** (stable — do not rename):

`slime_green`, `slime_blue`, `bat`, `skeleton`, `swamp_monster`, `dark_knight`

Legacy paths may still exist at repo root of `monsters/` (e.g. `bat_spritesheet.png`). New art uses `battle/` and `codex/` subfolders. Implementation agent may symlink or update `monsters.json` paths after handoff.

---

## 4. Battle sprite sheet layout

### Grid (required)

```text
Columns: 4 frames per animation
Rows (normal monster):
  Row 1: idle
  Row 2: move
  Row 3: attack
  Row 4: hit
  Row 5: death
  Row 6: spawn

Elite/boss extra rows:
  Row 7: cast
  Row 8: special
  Row 9: enrage (optional)
```

### Godot animation names (mandatory)

Use exactly: **`idle`**, **`move`**, **`attack`**, **`hit`**, **`death`**, **`spawn`**.

Never use `walk` on monsters.

### Frame size per `size_class`

| size_class | Frame size |
|------------|------------|
| small | 48×48 |
| normal | 64×64 |
| elite | 96×96 |
| boss | 128×128 |

Document actual frame size in the manifest (see §7).

### Alignment rules

- Each cell: same canvas size; character feet/base centered on a consistent baseline.
- Use the median body-core bounds across the four `idle` frames as the scale reference.
- Keep body-core width and height within **+/-8%** for `idle`, `move`, and `hit`.
- Keep body-core width and height within **+/-10%** for `attack`, `cast`, `special`,
  and `enrage`.
- `death` and `spawn` are the only automatic body-scale exemptions.
- Attack silhouettes may grow wider or taller through stance, weapons, wings,
  limbs, projectiles, or VFX. Do not scale the entire monster up or down.
- Exclude weapons, wings, extended limbs, detached particles, and VFX when
  comparing body-core scale.
- Humanoid/beast root anchor variance: maximum 1 px for 48/64 px frames, 2 px
  for 96 px frames, and 3 px for 128 px frames.
- Keep outer alpha occupancy at or below 92% of either cell dimension and leave
  at least 2 transparent pixels at every edge.
- Slimes: eye/core size stays within **+/-8%** and opaque body-core area stays
  within **+/-12%**. A squash frame must widen enough to preserve perceived volume.
- Transparent PNG.
- No text, watermarks, or UI in cells.

### Scale review before handoff

1. Compare every non-exempt frame against the median `idle` body core.
2. Review body-core overlays separately from weapon, wing, particle, and VFX bounds.
3. Record the approved scale rules in the monster manifest under `scale_review`.
4. Treat automatic measurements as evidence only; visual review is authoritative.

---

## 5. Codex portrait rules

One PNG per monster: `{monster_id}_portrait.png`

Include in manifest:

- `codex_index` (001, 002, …)
- `description` — 1–2 sentences for the codex UI (flavor + combat hint)

**Example descriptions (tone reference):**

| ID | Description |
|----|-------------|
| slime_green | A basic blob creature that bounces and uses splash strikes. |
| slime_blue | A rarer water slime that can drain magical energy. |
| bat | A fast flying pest, dangerous in quick swooping attacks. |
| skeleton | A reanimated bone warrior found in ruins; dangerous in melee. |
| swamp_monster | An elite predator that uses poison bites and gas clouds. |
| dark_knight | A boss-tier cursed knight that delivers crushing strikes and drains life. |

**Weaknesses / resists** for codex UI are gameplay data — leave `weaknesses` and `resists` arrays empty in manifest unless the user provides a combat chart.

---

## 6. Affinity icons (shared)

Create small icons for UI and codex legend:

`neutral`, `fire`, `water`, `poison`, `lightning`, `ice`, `shadow`, `undead`, `armored`

- Size: 16×16 or 24×24 PNG, transparent.
- Style: simple glyph readable on parchment (see codex mockup legend).

---

## 7. Deliverables manifest (required handoff)

After each batch, update:

**`docs/sprite_deliverables/manifest.json`**

```json
{
  "version": 1,
  "style": "codex_mockup_v1",
  "monsters": {
    "slime_green": {
      "display_name": "Green Slime",
      "family": "slime",
      "size_class": "small",
      "affinities": ["neutral"],
      "codex_index": 1,
      "frame_size": [48, 48],
      "battle_sheet": "res://assets/sprites/monsters/battle/slime_green_sheet.png",
      "codex_portrait": "res://assets/sprites/monsters/codex/slime_green_portrait.png",
      "description": "A basic blob creature that bounces and uses splash strikes.",
      "animations_present": ["idle", "move", "attack", "hit", "death", "spawn"],
      "weaknesses": [],
      "resists": []
    }
  }
}
```

Implementation agent copies paths into `data/monsters/monsters.json` and builds `SpriteFrames`.

---

## 8. Master prompt template (battle sheet)

```text
Create a 2D pixel-art monster SPRITE SHEET for Umbral Explorers: Relics of Grimvale.

Monster ID: {monster_id}
Display name: {display_name}
Family: {family}
size_class: {size_class}
Frame size: {W}x{H} pixels per cell
Grid: 4 columns x 6 rows — rows are animations, columns are frames
Animations (row order): idle, move, attack, hit, death, spawn
View: top-down / three-quarter; feet centered per cell
Style: Match Monster Codex portrait quality — readable silhouette,
clear fantasy colour on the body, Grimvale relic/Umbral accents.
NOT gore. NOT realistic blood.
Affinities (max 2): {affinities} — subtle on sprite only

Family identifier: {identifier}
Motion notes: {e.g. slime wobble on idle/move, bat wing flap on move}

Output: single PNG, transparent background, consistent lighting from upper-left.
Keep the same monster body-core scale in every non-transform animation.
Attack/cast/special silhouettes may expand only through pose, weapons, limbs, or VFX.
Do not include text, UI, or parchment background in the sheet.
```

---

## 9. Master prompt template (codex portrait)

```text
Create a single 2D pixel-art CODEX PORTRAIT for a monster bestiary UI.

Monster ID: {monster_id}
Display name: {display_name}
Family: {family}
Affinities: {affinities}
Canvas: {96x96 or 128x128} PNG, transparent background

Style: Same universe as Umbral Explorers: Relics of Grimvale — rich pixel art,
strong outline, soft ground shadow, heroic mystery with readable Umbral accents,
broad-audience safe (no gore or horror-first imagery).

Pose: static hero pose, slight three-quarter top-down, centered for parchment card layout.
Show family identifier clearly: {identifier}
Affinity cues subtle on body; design must work with separate small affinity icons in UI.

Do not include parchment, book border, stat text, or index numbers in the image.
```

---

## 10. Per-monster briefs (early roster)

### 001 — slime_green

- **Battle:** 48×48, neutral, round blob + eye/core, rows per §4.  
- **Codex:** green translucent blob, shiny core, beginner-friendly.  
- **Identifier:** shiny core or single eye.

### 002 — slime_blue

- **Battle:** 48×48 or 64×64, water affinity, blue shimmer, distinct from green.  
- **Codex:** water droplets / cooler palette.  
- **Do not** clone green slime palette only.

### 003 — bat

- **Battle:** 48×48, wide wings, large ears, red/dark eyes.  
- **Codex:** flying pose, shadow under body optional in portrait only.

### 004 — skeleton

- **Battle:** 64×64, undead, skull head, sword/shield optional.  
- **Codex:** bone warrior, faint blue joint glow allowed.

### 005 — swamp_monster

- **Battle:** 96×96, beast family, poison, hunched reptilian bulk.  
- **Codex:** moss, warts, yellow eyes, elite menace.

### 006 — dark_knight

- **Battle:** 128×128, skeleton family boss, undead + armored, plate armor, glowing weapon.  
- **Codex:** black/gold armor, skull shield emblem, blue flame accents — darkest roster entry, still readable.

---

## 11. Quality checklist (sprite agent)

Before updating the manifest:

- [ ] Correct `monster_id` in filename  
- [ ] Battle sheet: 4 columns, row order matches §4  
- [ ] Animation name **`move`** used for locomotion row (not walk)  
- [ ] Body-core scale matches the median idle reference within the allowed tolerance  
- [ ] Action growth comes from pose/weapon/limb/VFX, not whole-monster scaling  
- [ ] Slime squash/stretch preserves eye/core size and approximate body area  
- [ ] Root anchor and 92% cell occupancy limits pass  
- [ ] Transparent PNG  
- [ ] Codex portrait matches §2 style  
- [ ] Same character readable in both battle sheet and portrait  
- [ ] Affinity count ≤ 2  
- [ ] `manifest.json` entry complete  
- [ ] No Godot code changes

---

## 12. What happens after handoff

The **implementation agent** (monster design bible §0):

1. Copies `battle_sheet` → `sprite` in `monsters.json`  
2. Sets `codex_portrait` and `description` from manifest  
3. Builds or updates `*_frames.tres` with animations `idle`, `move`, `attack`, …  
4. Points scenes at delivered PNGs — **does not redraw monsters**

If files are missing, implementation agent keeps placeholders and logs which IDs are pending in `docs/sprite_deliverables/manifest.json`.
