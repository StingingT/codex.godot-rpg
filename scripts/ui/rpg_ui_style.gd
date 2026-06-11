extends RefCounted

const BG := Color(0.035, 0.038, 0.045, 0.96)
const PANEL := Color(0.095, 0.083, 0.07, 0.96)
const PANEL_DARK := Color(0.045, 0.047, 0.055, 0.98)
const PANEL_WARM := Color(0.15, 0.105, 0.065, 0.96)
const BORDER := Color(0.55, 0.42, 0.22, 1.0)
const BORDER_DARK := Color(0.18, 0.16, 0.13, 1.0)
const TEXT := Color(0.92, 0.87, 0.76, 1.0)
const TEXT_MUTED := Color(0.67, 0.62, 0.52, 1.0)
const GOLD := Color(0.98, 0.72, 0.25, 1.0)
const GREEN := Color(0.33, 0.78, 0.45, 1.0)
const BLUE := Color(0.35, 0.62, 0.95, 1.0)
const RED := Color(0.82, 0.18, 0.16, 1.0)
const SLOT := Color(0.055, 0.06, 0.066, 1.0)
const SLOT_HOVER := Color(0.12, 0.105, 0.08, 1.0)
const BUTTON := Color(0.13, 0.10, 0.075, 1.0)
const BUTTON_HOVER := Color(0.22, 0.15, 0.08, 1.0)
const BUTTON_PRESSED := Color(0.08, 0.07, 0.06, 1.0)

static func apply_screen(control: Control) -> void:
	if control == null:
		return
	control.add_theme_color_override("font_color", TEXT)
	control.add_theme_color_override("font_disabled_color", TEXT_MUTED)

static func apply_panel(panel: Control, warm: bool = false) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", panel_box(warm))

static func apply_dark_panel(panel: Control) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", panel_box(false, true))

static func apply_button(button: Button, accent: Color = BORDER) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", button_box(BUTTON, accent))
	button.add_theme_stylebox_override("hover", button_box(BUTTON_HOVER, GOLD))
	button.add_theme_stylebox_override("pressed", button_box(BUTTON_PRESSED, accent.darkened(0.12)))
	button.add_theme_stylebox_override("disabled", button_box(Color(0.055, 0.055, 0.06, 0.72), BORDER_DARK))
	button.add_theme_stylebox_override("focus", button_box(Color(0.16, 0.12, 0.08, 0.9), GOLD))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	button.add_theme_font_size_override("font_size", 14)

static func apply_slot_button(button: Button, accent: Color = BORDER_DARK) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", button_box(SLOT, accent, 2))
	button.add_theme_stylebox_override("hover", button_box(SLOT_HOVER, GOLD, 2))
	button.add_theme_stylebox_override("pressed", button_box(BUTTON_PRESSED, accent, 2))
	button.add_theme_stylebox_override("disabled", button_box(Color(0.03, 0.032, 0.036, 0.85), BORDER_DARK, 2))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.34, 0.32, 0.29, 1.0))
	button.add_theme_font_size_override("font_size", 13)

static func apply_title(label: Label, size: int = 24) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", GOLD)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

static func apply_label(label: Label, muted: bool = false) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", TEXT_MUTED if muted else TEXT)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

static func apply_progress_bar(bar: ProgressBar, fill_color: Color) -> void:
	if bar == null:
		return
	bar.add_theme_stylebox_override("background", bar_box(Color(0.025, 0.027, 0.032, 0.95), BORDER_DARK))
	bar.add_theme_stylebox_override("fill", bar_box(fill_color, fill_color.darkened(0.35)))

static func apply_tab_container(tab_container: TabContainer) -> void:
	if tab_container == null:
		return
	tab_container.add_theme_stylebox_override("panel", panel_box(false, true))
	tab_container.add_theme_stylebox_override("tab_selected", button_box(PANEL_WARM, GOLD, 2))
	tab_container.add_theme_stylebox_override("tab_unselected", button_box(Color(0.055, 0.055, 0.06, 1.0), BORDER_DARK, 2))
	tab_container.add_theme_color_override("font_selected_color", GOLD)
	tab_container.add_theme_color_override("font_unselected_color", TEXT_MUTED)
	tab_container.add_theme_font_size_override("font_size", 14)

static func apply_item_list(item_list: ItemList) -> void:
	if item_list == null:
		return
	item_list.add_theme_stylebox_override("panel", panel_box(false, true))
	item_list.add_theme_stylebox_override("focus", button_box(Color(0.16, 0.12, 0.08, 0.9), GOLD, 3))
	item_list.add_theme_stylebox_override("selected", button_box(Color(0.18, 0.13, 0.08, 1.0), GOLD, 3))
	item_list.add_theme_stylebox_override("selected_focus", button_box(Color(0.22, 0.15, 0.08, 1.0), GOLD, 3))
	item_list.add_theme_color_override("font_color", TEXT)
	item_list.add_theme_color_override("font_selected_color", GOLD)
	item_list.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	item_list.add_theme_font_size_override("font_size", 14)

static func panel_box(warm: bool = false, dark: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_DARK if dark else (PANEL_WARM if warm else PANEL)
	box.border_color = BORDER
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.shadow_color = Color(0, 0, 0, 0.45)
	box.shadow_size = 8
	box.set_expand_margin_all(1.0)
	return box

static func button_box(color: Color, border: Color, radius: int = 4) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 3
	return box

static func bar_box(color: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	return box
