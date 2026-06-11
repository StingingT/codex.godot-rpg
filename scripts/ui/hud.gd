extends CanvasLayer

const RPGUIStyle := preload("res://scripts/ui/rpg_ui_style.gd")

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/HealthLabel
@onready var health_flash: Panel = $HealthBar/FlashOverlay
@onready var mana_bar: ProgressBar = $ManaBar
@onready var mana_label: Label = $ManaBar/ManaLabel
@onready var mana_flash: Panel = $ManaBar/FlashOverlay
@onready var xp_bar: ProgressBar = $XPBar
@onready var xp_flash: Panel = $XPBar/XPFlash
@onready var level_label: Label = $LevelLabel
@onready var map_label: Label = $MapLabel
@onready var ap_label: Label = $APLabel
@onready var sp_label: Label = $SPLabel
@onready var character_button: Button = $CharacterButton
@onready var level_up_notification: Panel = $LevelUpNotification

@onready var pause_button: Button = $PauseButton

var player: Player = null
var _player_connected: bool = false
var _manual_pause_active: bool = false
var character_screen: Control = null
var minimap: Control = null

func _ready():
    _apply_style()

    # Connect to game signals via GameManager
    GameManager.player_health_changed.connect(_on_health_changed)
    GameManager.player_mana_changed.connect(_on_mana_changed)
    GameManager.player_xp_changed.connect(_on_xp_changed)
    GameManager.player_level_up.connect(_on_level_up)
    MapManager.map_changed.connect(_on_map_changed)

    # Connect to map transition to reconnect player signals
    MapManager.map_transition_finished.connect(_on_map_transition_finished)

    # Character button
    character_button.pressed.connect(_on_character_button_pressed)

    # Create minimap
    minimap = preload("res://scenes/ui/minimap.tscn").instantiate()
    add_child(minimap)

    pause_button.pressed.connect(_on_pause_button_pressed)

    # Initial player connection attempt
    call_deferred("_connect_to_player")

func _apply_style() -> void:
    RPGUIStyle.apply_progress_bar(health_bar, RPGUIStyle.RED)
    RPGUIStyle.apply_progress_bar(mana_bar, RPGUIStyle.BLUE)
    RPGUIStyle.apply_progress_bar(xp_bar, RPGUIStyle.GOLD)
    RPGUIStyle.apply_label(health_label)
    RPGUIStyle.apply_label(mana_label)
    RPGUIStyle.apply_title(level_label, 18)
    RPGUIStyle.apply_title(map_label, 18)
    RPGUIStyle.apply_label(ap_label)
    RPGUIStyle.apply_label(sp_label)
    RPGUIStyle.apply_panel(level_up_notification, true)
    RPGUIStyle.apply_button(character_button, RPGUIStyle.GOLD)
    RPGUIStyle.apply_button(pause_button, RPGUIStyle.GOLD)

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.is_echo():
        return
    if event.is_action_pressed("pause"):
        _toggle_manual_pause()
        get_viewport().set_input_as_handled()
        return
    if get_tree().paused:
        return
    if event.is_action_pressed("character"):
        _on_character_button_pressed()
    elif event.is_action_pressed("open_inventory"):
        # Open character screen to inventory tab
        _on_inventory_button_pressed()
    elif event.is_action_pressed("open_skill_tree"):
        # Open character screen to skills tab
        _on_skill_tree_pressed()
    elif event.is_action_pressed("toggle_minimap"):
        if minimap:
            minimap.toggle()

func _on_inventory_button_pressed() -> void:
    if character_screen and character_screen.visible:
        character_screen.close()
    elif player:
        _show_character_screen()
        # Switch to inventory tab (index 1)
        if character_screen:
            character_screen.tab_container.current_tab = 1

func _on_skill_tree_pressed() -> void:
    if character_screen and character_screen.visible:
        character_screen.close()
    elif player:
        _show_character_screen()
        # Switch to skills tab (index 2)
        if character_screen:
            character_screen.tab_container.current_tab = 2

func _on_character_button_pressed() -> void:
    if character_screen and character_screen.visible:
        character_screen.close()
    elif player:
        _show_character_screen()
        # Switch to stats tab (index 0)
        if character_screen:
            character_screen.tab_container.current_tab = 0

func _show_character_screen() -> void:
    if not character_screen:
        character_screen = preload("res://scenes/ui/character_screen.tscn").instantiate()
        add_child(character_screen)
    character_screen.open(player)

func _connect_to_player() -> void:
    if _player_connected:
        return

    player = get_tree().get_first_node_in_group("player")
    if player and player.stats:
        # Connect to stats signals (check if already connected)
        if not player.stats.hp_changed.is_connected(_on_player_health_changed):
            player.stats.hp_changed.connect(_on_player_health_changed)
        if not player.stats.mana_changed.is_connected(_on_player_mana_changed):
            player.stats.mana_changed.connect(_on_player_mana_changed)
        if not player.stats.xp_changed.is_connected(_on_player_xp_changed):
            player.stats.xp_changed.connect(_on_player_xp_changed)
        if not player.stats.level_up.is_connected(_on_player_level_up):
            player.stats.level_up.connect(_on_player_level_up)
        if not player.stats.ap_changed.is_connected(_on_ap_changed):
            player.stats.ap_changed.connect(_on_ap_changed)
        if not player.stats.sp_changed.is_connected(_on_sp_changed):
            player.stats.sp_changed.connect(_on_sp_changed)

        # Initialize values
        _update_health_bar(player.stats.current_hp, player.stats.get_max_hp())
        _update_mana_bar(player.stats.current_mana, player.stats.get_max_mana())
        _update_xp_bar(player.stats.current_xp, player.stats.get_xp_for_next_level())
        _update_points_display()
        level_label.text = "Level %d" % player.stats.level

        _player_connected = true

func _on_map_transition_finished() -> void:
    # Reconnect to new player instance after map change
    _player_connected = false
    call_deferred("_connect_to_player")

# Health updates with flash effect
func _on_health_changed(new_hp: int, max_hp: int):
    _update_health_bar(new_hp, max_hp)

func _on_player_health_changed(new_hp: int, max_hp: int):
    _on_health_changed(new_hp, max_hp)

func _update_health_bar(new_hp: int, max_hp: int) -> void:
    # Smooth transition
    var tween = create_tween()
    tween.tween_property(health_bar, "max_value", max_hp, 0.1)
    tween.parallel().tween_property(health_bar, "value", new_hp, 0.2)

    health_label.text = "%d/%d" % [new_hp, max_hp]

    # Flash on damage (when HP decreases)
    if new_hp < health_bar.value:
        _flash_bar(health_flash)

# Mana updates with flash effect
func _on_mana_changed(new_mana: int, max_mana: int):
    _update_mana_bar(new_mana, max_mana)

func _on_player_mana_changed(new_mana: int, max_mana: int):
    _on_mana_changed(new_mana, max_mana)

func _update_mana_bar(new_mana: int, max_mana: int) -> void:
    var tween = create_tween()
    tween.tween_property(mana_bar, "max_value", max_mana, 0.1)
    tween.parallel().tween_property(mana_bar, "value", new_mana, 0.2)

    mana_label.text = "%d/%d" % [new_mana, max_mana]

# Flash mana bar when insufficient mana (called externally)
func flash_mana_insufficient() -> void:
    _flash_bar(mana_flash, Color(1, 0.5, 0.5, 0.6))

# XP updates with glow effect
func _on_xp_changed(current_xp: int, xp_to_next: int, _level: int):
    _update_xp_bar(current_xp, xp_to_next)

func _on_player_xp_changed(current_xp: int, xp_to_next: int, level: int):
    _on_xp_changed(current_xp, xp_to_next, level)

func _update_xp_bar(current_xp: int, xp_to_next: int) -> void:
    var old_value = xp_bar.value

    var tween = create_tween()
    tween.tween_property(xp_bar, "max_value", xp_to_next, 0.1)
    tween.parallel().tween_property(xp_bar, "value", current_xp, 0.3)

    # Glow on XP gain
    if current_xp > old_value:
        _flash_bar(xp_flash, Color(1, 0.9, 0.5, 0.4), 0.3)

# Level up
func _on_level_up(new_level: int):
    level_label.text = "Level %d" % new_level
    _show_level_up_notification()

func _on_player_level_up(new_level: int, _ap_gained: int, _sp_gained: int):
    _on_level_up(new_level)
    _update_points_display()

func _show_level_up_notification() -> void:
    level_up_notification.visible = true
    level_up_notification.modulate = Color(1, 1, 1, 1)

    var tween = create_tween()
    tween.tween_interval(2.0)
    tween.tween_property(level_up_notification, "modulate:a", 0.0, 0.5)
    tween.finished.connect(_hide_level_up_notification)

# Points display
func _on_ap_changed(_new_ap: int):
    _update_points_display()

func _on_sp_changed(_new_sp: int):
    _update_points_display()

func _update_points_display() -> void:
    if not player:
        return

    var stats = player.stats
    ap_label.text = "AP: %d" % stats.attribute_points
    sp_label.text = "SP: %d" % stats.skill_points

    # Pulse if points available
    ap_label.modulate = Color(0.3, 1.0, 0.3) if stats.attribute_points > 0 else Color(0.3, 0.8, 0.3)
    sp_label.modulate = Color(0.3, 0.8, 1.0) if stats.skill_points > 0 else Color(0.3, 0.6, 0.9)

# Map name updates
func _on_map_changed(_map_id: String, map_name: String):
    map_label.text = map_name

# Helper: Flash a bar overlay
func _flash_bar(overlay: Panel, color: Color = Color(1, 1, 1, 0.5), duration: float = 0.15) -> void:
    overlay.visible = true
    overlay.modulate = color

    var tween = create_tween()
    tween.tween_property(overlay, "modulate:a", 0.0, duration)
    tween.finished.connect(_hide_overlay.bind(overlay))

func _hide_level_up_notification() -> void:
    level_up_notification.visible = false

func _hide_overlay(overlay: Panel) -> void:
    if is_instance_valid(overlay):
        overlay.visible = false

func _on_pause_button_pressed() -> void:
    _toggle_manual_pause()

func _toggle_manual_pause() -> void:
    if _manual_pause_active:
        _manual_pause_active = false
        if GameManager.is_paused:
            GameManager.resume_game()
    elif not GameManager.is_paused:
        _manual_pause_active = true
        GameManager.pause_game()
