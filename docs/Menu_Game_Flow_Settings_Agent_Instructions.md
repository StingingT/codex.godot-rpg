# Menu, Game Flow & Settings Agent Instructions

**Status:** Active canonical domain specification  
**Project:** Umbral Explorers: Relics of Grimvale  
**Source of truth:** `Main_ChatGPT-Godot_RPG_Implementation_Plan.md`  
**Agent name:** Menu, Game Flow & Settings Agent  
**Scope:** Title screen, new-game flow, continue/character selection, pause/menu flow, top-right in-game menu, settings, death screen, quest menu shell, character/menu navigation hooks, and mobile-friendly menu UX.

---

## Master Plan Integration Locks

- The shipping title is written as **Umbral Explorers: Relics of Grimvale** and displayed on two lines.
- The supplied title image is visual direction only, not a shipping asset.
- Warrior is the only playable v1 class. Ranger and Mage remain visible but disabled with **Coming Later**.
- V1 uses one character-ID autosave at `user://saves/char_0001.json`, indexed by `user://saves/index.json`.
- `SaveManager` owns character saves and migration from `user://saves/slot_1.json`; `SettingsManager` owns global settings at `user://settings.json`.
- `data/game_flow.json` owns new-game and respawn map/entry targets. `custom_kit_town` remains the current start map ID until a reviewed naming migration.
- The HUD owns one modal menu coordinator for Quests, Character, Inventory, Settings, pause, and death flow.
- Inventory remains a standalone window. Character owns Equipment and the canonical Skills/ability-loadout hook.
- The global categorized Quest Journal is separate from NPC quest offer/turn-in dialogue.
- Phase ownership is Main Phase 14 for persistence and Main Phase 15A-15D for menu/game flow.

---

## 0. Core Rules for This Agent

You are designing and implementing the menu and game-flow layer for a Godot 4.3+ top-down real-time RPG.

Follow these rules:

1. Follow the Main MD as the architecture and phase source of truth.
2. Use Godot 4.3+ and GDScript.
3. Do not introduce Python architecture.
4. Use `res://` paths.
5. Preserve existing HUD, inventory, quest, character, skill tree, save/load, map, and combat systems.
6. Patch additively.
7. Do not replace existing UI systems with disconnected alternatives unless explicitly approved.
8. Keep all menus mobile-friendly.
9. Every implementation handoff must be reviewed by the Lead Architect before integration.
10. Record reviewed integration results in `docs/agent_integration_log.md`.

Relevant Main MD responsibilities:

```text
Phase 8 / HUD:
- mobile-friendly HUD direction
- one HUD-owned menu coordinator
- top-right menu access

Phase 14 / Save/Load:
- character-ID autosave plus index
- atomic writes, backup, corruption fallback, and slot_1 migration
- global settings stored separately by SettingsManager

Phase 15A / Title Flow:
- title screen, character banner, New Game, Continue

Phase 15B / Top Menu:
- Quests, Character, Inventory, Settings

Phase 15C / Pause and Settings:
- pause/resume, settings, combat-blocked Return to Town

Phase 15D / Death Flow:
- revive through MapManager and metadata-driven respawn

Phase 11 / Quests:
- quest log UI

Skill tree domain doc:
- skill tree is accessed through the character/skills flow
```

---

## 1. Agent Goal

Create a coherent game-flow and menu system for:

```text
Title screen
Last-played character banner
New game flow
Class and name creation
Continue flow
Multiple-character selection, later
Top-right in-game menu
Pause / return-to-town flow
Settings menu
Death screen
Quest menu shell
Character/equipment/skills navigation hooks
Mobile menu responsiveness
```

The first implementation should be simple, readable, and stable. It must not overbuild account systems, cloud saves, monetization, or complex character management yet.

---

## 2. Visual Style Direction

Menus should mix:

```text
A. Clean mobile RPG readability
D. Dark fantasy, simple and readable for mobile
```

The title screen style should follow the approved recent mockup direction:

```text
- bright but still fantasy
- blue/gold palette
- pixel-art inspired
- friendly enough for younger players
- magical castle / adventure mood
- not too dark, not horror
- ornate fantasy buttons, but large and easy to tap
- player banner in the top-left
```

Overall menu style:

```text
RuneScape-like framed panels
Dark fantasy / PoE-inspired materials
Not too dark
Mobile-readable icons and labels
Warm brown/beige fantasy book panels for quest UI
Blue/gold title-screen identity
```

Do not copy any external game UI directly. Use references only as style direction.

---

## 3. Title Screen

### 3.1 Title

Use the game name:

```text
Umbral Explorers
Relics of Grimvale
```

Recommended layout:

```text
Top/center:
  UMBRAL EXPLORERS

Below:
  RELICS OF GRIMVALE

Center:
  New Game
  Continue
  Settings

Top-left:
  Last-played character banner

Background:
  friendly blue/gold fantasy pixel-art inspired scene
  castle / valley / moon / banners / explorer silhouette
```

### 3.2 Required buttons for v1

Only these title buttons are required:

```text
New Game
Continue
Settings
```

Do not add Credits, Quit, News, Patch Notes, Store, Login, or Account buttons for v1 unless separately requested.

### 3.3 Last-played character banner

The title screen has a hanging banner in the top-left, inspired by the approved mockup.

Banner content:

```text
Portrait or class icon
Character name
Level
Optional class name
```

Example:

```text
Guy
Level 12
Warrior
```

If no character exists:

```text
New Explorer
Level 1
```

or hide the banner and show a neutral guest/new-player banner.

Banner style:

```text
- falls from the top-left edge
- blue fabric or parchment-fabric mix
- gold trim
- small circular portrait/icon at top
- readable white/cream text
- pixel-art compatible
```

### 3.4 Continue behavior

If there is only one character/save:

```text
Continue immediately loads the latest autosave.
```

If multiple characters exist later:

```text
Continue opens a character list.
The player selects which character to continue.
```

Character list entries should show:

```text
Character name
Class
Level
Current map or area
Last played time, if available
```

Multiple-character support is future work. V1 must use exactly one character-ID autosave plus the index; do not fall back to an unindexed legacy slot.

---

## 4. Save and Character Flow

### 4.1 Save model

Use:

```text
One character-ID autosave for v1
Index metadata in user://saves/index.json
Multiple characters later
Global settings in user://settings.json
```

Do not create manual save slots in v1.
Do not store global settings inside the character autosave.

Autosave should trigger at safe points such as:

```text
- character creation completed
- entering town
- returning to town
- changing maps
- completing quests
- equipping or changing important persistent state, when safe
- opening/closing major menus if needed
```

Autosave must never corrupt the current save. Save writes should be atomic where possible.

### 4.2 New game flow

New Game opens a simple character creation flow:

```text
1. Enter character name.
2. Choose class.
3. Confirm.
4. Start at the first town / starting map.
```

Initial classes shown:

```text
Warrior
Ranger
Mage
```

Warrior is enabled. Ranger and Mage must be visible but disabled with:

```text
Coming Later
```

Do not hide or enable Ranger/Mage in v1.

Class selection card should show:

```text
Class name
Small icon/silhouette
Short role description
Difficulty or playstyle note, optional
```

Warrior description example:

```text
A durable melee fighter who uses Cleave and Charge to control groups of enemies.
```

### 4.3 Character name rules

Suggested first rules:

```text
1–16 characters
letters, numbers, spaces, hyphen allowed
trim leading/trailing spaces
no empty names
fallback display name: "Explorer"
```

Do not implement online-name moderation or account identity rules in v1.

---

## 5. In-Game Top-Right Menu

The game should have a compact top-right menu.

Required entries:

```text
Quests
Character
Inventory
Settings
```

### 5.1 Button style

Quests, Character, and Inventory are horizontal rectangle buttons.

Each button should include:

```text
small icon on the left
text label inside the rectangle
framed fantasy panel style
large enough for touch input
```

Example icons:

```text
Quests = scroll/book icon
Character = helmet/person icon
Inventory = bag icon
```

Settings is a cog icon only.

### 5.2 Settings dropdown

Clicking/tapping the cog opens a small dropdown menu.

Possible dropdown entries:

```text
Settings
Pause
Return to Town, if allowed
Exit to Title, if allowed
```

The first implementation may simply open the settings menu directly if dropdown logic is not yet needed, but the target design is a dropdown.

### 5.3 Visibility and interaction

The top-right menu can be visible during normal exploration.

Combat safety:

```text
- Opening menus during combat may pause the game if the current game supports pause safely.
- Return to Town from pause is only allowed when not in combat.
- Portal-based return to town is allowed even during combat if the player reaches and activates the portal.
```

---

## 6. Pause and Return-to-Town Flow

### 6.1 Pause menu

Pause should provide:

```text
Resume
Settings
Return to Town
Exit to Title
```

Optional later:

```text
Inventory
Character
Quests
```

Because top-right menu buttons already open those windows, the pause menu should stay uncluttered.

### 6.2 Return to Town

Return to Town is available from pause only when the player is not in combat.

If selected:

```text
1. Show confirmation dialog.
2. Explain the current repeatable area may reset.
3. On confirm, move the player to nearest town or configured town entry.
4. Save after successful transfer.
```

Suggested confirmation text:

```text
Return to the nearest town?
The current area may reset.
```

Portal behavior:

```text
The player can use a town/back portal during combat if they physically reach and activate it.
```

Do not allow pause-menu Return to Town as an escape button during active combat.

---

## 7. Death Screen

When the player dies, use the combat spec rule:

```text
Player returns to town.
Repeatable dungeon/monster-map run resets.
No v1 death penalty unless later enabled.
```

### 7.1 Death screen layout

Show:

```text
"You have fainted"
Revive in nearest town
Loss summary
```

Text style:

```text
"You have fainted" should be italic and red.
```

Button:

```text
Revive in nearest town
```

Under the button, show what was lost:

```text
Gold lost: 0
XP lost: 0
Items lost: None
```

For v1, if no penalties exist, show:

```text
Gold lost: 0
XP lost: 0
Items lost: None
```

or a cleaner line:

```text
No items, gold, or XP were lost.
```

Future penalties:

```text
XP progress loss
Dropped non-locked inventory items
Gold loss
```

Do not implement future penalties unless the combat/domain spec has approved them.

### 7.2 Area reset message

Also show a small note:

```text
The area has reset.
```

Repeatable dungeons:

```text
- monsters reset
- boss state resets
- temporary dropped loot resets
- chests can be reopened
- completed quest objectives do not reset
```

---

## 8. Settings Menu

Settings categories for v1:

```text
Audio
Language
Gameplay
Controls
```

Controls can be removed later when the game becomes fully mobile-focused, but remains useful during prototype and desktop testing.

### 8.1 Audio settings

Include:

```text
Master volume
Music volume
SFX volume
Mute all
```

### 8.2 Language settings

Include:

```text
Language dropdown
```

The first implementation may only support English, but the UI should be structured so localization can be added later.

### 8.3 Gameplay settings

Include:

```text
Show damage numbers
Show "Not enough mana" text
Larger text
```

Recommended toggles:

```text
Damage numbers: on/off
Not enough mana text: on/off
Larger text: on/off
```

### 8.4 Controls settings

Prototype controls settings:

```text
Joystick size
Joystick opacity
Attack button size
Ability button size
Left/right-handed layout
Tap enemy/ground to aim
```

Implementation priority:

```text
- joystick/button scale first
- left/right-handed layout later
- tap enemy/ground to aim later when mobile targeting is implemented
```

Controls category may be removed or simplified later when the project becomes fully mobile-only.

### 8.5 Future accessibility settings

Do not implement unless requested:

```text
colorblind-friendly rarity colors
larger cooldown numbers
screen shake intensity
disable on-hit particles
```

Only **larger text** is required now.

---

## 9. Inventory and Equipment Window Relationship

Inventory and Equipment are separate windows but should work together.

Target behavior:

```text
Inventory opens inventory window.
Character opens character/equipment window.
Inventory window has a button to open equipment/character window.
Equipment/character window has a button to open the standalone inventory window.
```

This is similar to option C from the planning discussion, but uses a direct button to open the equipment window rather than switching inside the same panel.

Do not duplicate the inventory/equipment logic owned by the Inventory/Itemization agent.

This agent may:

```text
- add menu buttons
- add open/close hooks
- ensure panels layer correctly
- define shared panel style
```

This agent must not:

```text
- redesign item data
- rewrite inventory storage
- rewrite equipment stat logic
- create a parallel inventory system
```

---

## 10. Character Screen and Skills Tab

The Character window opens to the Equipment tab by default.

Character screen target tabs:

```text
Equipment
Skills
```

Optional later:

```text
Stats
Cosmetics
Titles
```

### 10.1 Skills tab

The Skills tab should show:

```text
Full skill tree
Ability loadout
```

This follows option D from planning:

```text
Skill tree + ability loadout
```

The Skill Tree Agent owns the full visual skill tree and unlock logic.  
The Menu Agent only owns navigation/opening/closing and tab placement.

Do not replace the skill tree UI with a simple list.
During migration, remove the duplicate Character inventory tab and any local placeholder skill list after their canonical replacements are wired.

---

## 11. Quest Menu

The quest menu should be inspired by MapleStory organization but with a darker, warmer fantasy-book presentation.

This is the global categorized Quest Journal. It must not replace or absorb the NPC quest offer/turn-in dialog used during direct NPC interaction.

### 11.1 Quest book layout

The quest menu opens as a book:

```text
Left page:
  category tabs
  quest list
  selected quest lore / description

Right page:
  objectives
  rewards
  action/status area
  Monster Codex button
```

Visual style:

```text
brown/beige fantasy book
dark fantasy trim
readable parchment pages
not too dark
clear category tabs
```

### 11.2 Quest categories

Use these categories:

```text
Available Quests
Active Quests
Completed Quests
Finished Quests
```

Definitions:

```text
Available:
  quests the player can accept but has not started

Active:
  accepted quests still in progress

Completed:
  objective requirements met, but reward not yet redeemed

Finished:
  reward already redeemed / fully turned in
```

### 11.3 Left page content

Left page should show:

```text
category tabs
quest names under the selected category
selected quest lore / description
```

### 11.4 Right page content

Right page should show:

```text
objectives
quest rewards
turn-in/accept/completion status
```

Quest rewards should show:

```text
XP
Gold
Items
```

### 11.5 Monster Codex button

Add a button in the top-right area of the quest book or right page:

```text
Monster Codex
```

This opens the Monster Codex when implemented.

The Monster Codex itself is owned by the monster/codex implementation work.  
This menu agent may add the button and placeholder hook only.

---

## 12. Monster Codex Hook

The quest menu should include a Monster Codex button.

For v1:

```text
- If Monster Codex UI exists, open it.
- If it does not exist, show placeholder text: "Monster Codex coming soon."
```

Do not implement the full Monster Codex unless explicitly assigned. The Monster Bible defines codex data and portrait behavior.

---

## 13. Scene and File Ownership

This agent may create or update:

```text
res://scenes/ui/title_screen.tscn
res://scripts/ui/title_screen.gd

res://scenes/ui/character_creation_screen.tscn
res://scripts/ui/character_creation_screen.gd

res://scenes/ui/character_select_screen.tscn
res://scripts/ui/character_select_screen.gd

res://scenes/ui/pause_menu.tscn
res://scripts/ui/pause_menu.gd

res://scenes/ui/settings_menu.tscn
res://scripts/ui/settings_menu.gd

res://scenes/ui/top_menu_bar.tscn
res://scripts/ui/top_menu_bar.gd

res://scenes/ui/death_screen.tscn
res://scripts/ui/death_screen.gd

res://scenes/ui/quest_book_ui.tscn
res://scripts/ui/quest_book_ui.gd
```

This agent may update additively:

```text
res://scenes/ui/hud.tscn
res://scripts/ui/hud.gd
res://scripts/autoload/save_manager.gd
res://scripts/autoload/game_manager.gd
res://scripts/autoload/map_manager.gd
res://scripts/autoload/quest_manager.gd
res://project.godot
```

Restrictions:

```text
- Do not replace HUD.
- Do not replace inventory UI.
- Do not replace skill tree UI.
- Do not replace quest manager logic.
- Do not replace save manager with a parallel save system.
- Do not create cloud/account features.
```

---

## 14. Save Data Expectations

The menu system needs access to save metadata.

Suggested character metadata:

```json
{
  "character_id": "char_0001",
  "character_name": "Guy",
  "class_id": "warrior",
  "level": 12,
  "current_map_id": "custom_kit_town",
  "last_played_unix": 0,
  "autosave_path": "user://saves/char_0001.json"
}
```

Suggested save index:

```json
{
  "save_index_version": 1,
  "last_played_character_id": "char_0001",
  "characters": [
    {
      "character_id": "char_0001",
      "character_name": "Guy",
      "class_id": "warrior",
      "level": 12,
      "current_map_id": "custom_kit_town",
      "last_played_unix": 0,
      "autosave_path": "user://saves/char_0001.json"
    }
  ]
}
```

V1 has one character but should avoid hardcoding that forever.

Autosave file naming should use character IDs, not display names.
Character writes must be atomic and preserve a recoverable backup. Migrate `user://saves/slot_1.json` only through `SaveManager`.
Global settings are loaded and saved independently through `SettingsManager` at `user://settings.json`.

---

## 15. Implementation Priority

Implement in this order:

```text
15A. Title screen + New Game / Continue
15B. Top menu overlay
15C. Pause menu + Settings
15D. Death screen
```

Expanded order:

### Phase 15A — Title and character start flow

```text
- title_screen.tscn / title_screen.gd
- New Game button
- Continue button
- Settings button
- top-left last-played character banner
- character creation screen
- name + class selection
- autosave metadata/index support
```

### Phase 15B — Top-right in-game menu

```text
- top_menu_bar.tscn / top_menu_bar.gd
- Quests button
- Character button
- Inventory button
- Settings cog/dropdown
- hooks into existing HUD/menu systems
```

### Phase 15C — Pause and settings

```text
- pause_menu.tscn / pause_menu.gd
- settings_menu.tscn / settings_menu.gd
- audio/language/gameplay/controls categories
- Return to Town, only when not in combat
```

### Phase 15D — Death screen

```text
- death_screen.tscn / death_screen.gd
- "You have fainted" text
- Revive in nearest town button
- loss summary
- area reset note
```

Each phase must be reviewed before moving to the next if it changes save flow or HUD bindings.

---

## 16. Input Actions

Required or recommended inputs:

```text
pause
open_inventory
open_quest_log
open_character
open_settings
open_skill_tree
```

If an input does not exist, add it additively to `project.godot`.

Suggested desktop keys:

```text
Pause: Escape / P
Inventory: I / Tab
Quest Log: L
Character: C
Skill Tree: T
Settings: optional via Pause menu
```

Mobile relies on buttons.

---

## 17. UI Scaling and Mobile Rules

Menus must support the base gameplay resolution:

```text
640x360
```

Rules:

```text
- Touch targets should be large and readable.
- Avoid tiny close buttons.
- Use clear button states.
- Do not rely only on hover.
- Use large enough labels for mobile.
- Support Larger Text setting.
- Avoid panels that require horizontal scrolling on mobile.
- If a menu is too complex, show one primary panel at a time.
```

Quest book, skill tree, and inventory may need responsive layouts.

---

## 18. Settings Persistence

Settings must be saved locally.

Suggested settings data:

```json
{
  "settings_version": 1,
  "audio": {
    "master_volume": 1.0,
    "music_volume": 1.0,
    "sfx_volume": 1.0,
    "mute_all": false
  },
  "language": {
    "language_id": "en"
  },
  "gameplay": {
    "show_damage_numbers": true,
    "show_not_enough_mana_text": true,
    "larger_text": false
  },
  "controls": {
    "joystick_size": 1.0,
    "joystick_opacity": 0.8,
    "attack_button_size": 1.0,
    "ability_button_size": 1.0,
    "left_handed_layout": false,
    "tap_aim_enabled": true
  }
}
```

Settings are independent of character-specific save data in v1.

---

## 19. Non-Goals

Do not implement yet:

```text
manual save slots
cloud saves
login/account UI
monetization/store UI
credits screen
news/patch notes
full Monster Codex
full localization system
colorblind mode
character deletion
character rename
complex class story intro
respec menu
full mobile-only control redesign
```

These can be future menu subprojects.

---

## 20. Required Deliverables

The agent should provide:

```text
1. Menu flow implementation notes.
2. Added/changed Godot scenes and scripts.
3. Save metadata/index changes if needed.
4. New input actions if needed.
5. UI style notes explaining how the title/menu style follows the approved visual direction.
6. Testing notes.
7. Architect handoff using docs/agent_handoff_template.md.
```

Expected implementation zip may include:

```text
res://scenes/ui/title_screen.tscn
res://scripts/ui/title_screen.gd
res://scenes/ui/character_creation_screen.tscn
res://scripts/ui/character_creation_screen.gd
res://scenes/ui/top_menu_bar.tscn
res://scripts/ui/top_menu_bar.gd
res://scenes/ui/pause_menu.tscn
res://scripts/ui/pause_menu.gd
res://scenes/ui/settings_menu.tscn
res://scripts/ui/settings_menu.gd
res://scenes/ui/death_screen.tscn
res://scripts/ui/death_screen.gd
res://scenes/ui/quest_book_ui.tscn
res://scripts/ui/quest_book_ui.gd
res://project.godot
MENU_FLOW_IMPLEMENTATION_NOTES.md
```

Only include quest book implementation if it is explicitly part of the assigned phase.

---

## 21. Validation Checklist

Before handoff, confirm:

```text
- Project opens in Godot 4.3+.
- No scene parse errors.
- No script parse errors.
- Title screen loads as main scene or can be opened from boot flow.
- Title displays Umbral Explorers: Relics of Grimvale.
- Top-left last-played character banner works with no save and with a save.
- New Game opens character creation.
- Character name validation works.
- Warrior is enabled; Ranger and Mage are visible, disabled, and labeled Coming Later.
- Confirming character creation starts the game and creates autosave metadata.
- Continue works with one character.
- Continue opens a selection list if multiple characters exist.
- Settings opens from title screen.
- Top-right in-game menu opens Quests, Character, Inventory, Settings.
- Character window opens Equipment by default and supports Skills tab navigation.
- Inventory and Equipment windows can open each other with dedicated buttons.
- Pause opens and resumes correctly.
- Return to Town is disabled during combat from pause/menu.
- Portal-based town return remains possible when implemented.
- Settings categories exist: Audio, Language, Gameplay, Controls.
- Larger Text option affects menu labels or is safely stubbed with implementation note.
- Death screen shows italic red “You have fainted”.
- Revive in nearest town moves the player correctly.
- Loss summary shows correct current penalties, or zero/none in v1.
- Area reset note appears.
- Menus fit 640x360 without unusable tiny controls.
- Existing HUD is not replaced.
- Existing inventory system is not replaced.
- Existing quest system is not replaced.
- Existing skill tree implementation is not replaced.
- Existing save/load is not broken.
```

---

## 22. Architect Review Notes

The Lead Architect should verify:

```text
- The implementation follows Main MD Phase 15 and does not skip unrelated phases.
- The title/menu style matches the approved friendly pixel-fantasy direction.
- The new top-right menu does not conflict with existing HUD mobile buttons.
- Save metadata does not corrupt old saves.
- Character creation cannot select Ranger or Mage in v1.
- Menu windows call existing systems instead of duplicating them.
- Return-to-town rules match combat/death/reset design.
- Quest book UI remains a shell/hook unless Quest Agent has approved deeper changes.
- Monster Codex button is only a hook unless Monster Codex is assigned.
```

Do not merge until architect review passes.
