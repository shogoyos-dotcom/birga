extends CanvasLayer

## O'yin interfeysi: boshlash ekrani, HUD va natija oynasi.
##
## Hamma element kod bilan quriladi — sahna fayli bo'lmagani uchun
## uslub bir joyda turadi va tasodifan buzilmaydi.

signal play_pressed

const BG := Color("100e1b")
const PANEL := Color("1a1728")
const STROKE := Color("2e2946")
const TEXT := Color("f4f2ff")
const TEXT_DIM := Color("9a93bd")
const BLUE := Color("3d7bff")
const CORAL := Color("ff6b5b")

var _start_root: Control
var _hud_root: Control
var _result_root: Control
var _percent: Label
var _info: Label
var _result_title: Label
var _result_reason: Label
var _result_stats: Label

func _ready() -> void:
	layer = 10
	_build_start()
	_build_hud()
	_build_result()
	show_start()

# ——— Qurish ———

func _panel(color: Color = PANEL) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = STROKE
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(20)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	return panel

## `wrap` faqat uzun matnlar uchun: HUD yorlig'ida u yoqilsa, panel
## tor bo'lgani uchun har bir harf yangi qatorga tushib ketadi.
func _label(text: String, size: int, color: Color = TEXT,
		spacing: int = 0, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if spacing > 0:
		label.add_theme_constant_override("line_spacing", spacing)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 74)
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = color
		if state == "pressed":
			style.bg_color = color.darkened(0.2)
		elif state == "hover":
			style.bg_color = color.lightened(0.1)
		style.set_corner_radius_all(16)
		style.set_content_margin_all(12)
		button.add_theme_stylebox_override(state, style)
	return button

## Ekranni egallaydigan, markazga tekislangan qatlam.
func _overlay(dim: bool) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP if dim \
		else Control.MOUSE_FILTER_IGNORE
	if dim:
		var shade := ColorRect.new()
		shade.color = Color(BG.r, BG.g, BG.b, 0.88)
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(shade)
	add_child(root)
	return root

func _centered_box(root: Control) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(center)

	var panel := _panel()
	panel.custom_minimum_size = Vector2(440, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	return box

func _build_start() -> void:
	_start_root = _overlay(true)
	var box := _centered_box(_start_root)
	box.add_child(_label("COLOR LAND", 46))
	box.add_child(_label(
		"Hududingizdan chiqing, halqa chizing va qaytib keling — "
		+ "ichidagi hamma narsa sizniki bo'ladi.", 19, TEXT_DIM, 0, true))
	box.add_child(_label(
		"Yurish uchun ekranni barmoq bilan suring.", 17, TEXT_DIM, 0, true))
	var play := _button("O'YNASH", BLUE)
	play.pressed.connect(func() -> void: play_pressed.emit())
	box.add_child(play)

func _build_hud() -> void:
	_hud_root = _overlay(false)
	var panel := _panel(Color(PANEL.r, PANEL.g, PANEL.b, 0.9))
	panel.position = Vector2(16, 16)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_hud_root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	_percent = _label("0.00%", 38, BLUE)
	_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(_percent)
	_info = _label("00:00", 18, TEXT_DIM)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(_info)

func _build_result() -> void:
	_result_root = _overlay(true)
	var box := _centered_box(_result_root)
	_result_title = _label("O'YIN TUGADI", 34)
	box.add_child(_result_title)
	_result_reason = _label("", 18, TEXT_DIM, 0, true)
	box.add_child(_result_reason)
	_result_stats = _label("", 22, TEXT, 6)
	box.add_child(_result_stats)
	var again := _button("QAYTA O'YNASH", CORAL)
	again.pressed.connect(func() -> void: play_pressed.emit())
	box.add_child(again)

# ——— Holatlar ———

func show_start() -> void:
	_start_root.visible = true
	_hud_root.visible = false
	_result_root.visible = false

func show_game() -> void:
	_start_root.visible = false
	_hud_root.visible = true
	_result_root.visible = false

func show_result(percent: float, kills: int, elapsed: float,
		reason: String) -> void:
	_start_root.visible = false
	_hud_root.visible = false
	_result_root.visible = true
	_result_reason.text = reason
	_result_stats.text = "Hudud: %.2f%%\nO'ldirishlar: %d\nVaqt: %s" % [
		percent, kills, _clock(elapsed)]

func set_stats(percent: float, kills: int, elapsed: float,
		rank: int, alive: int) -> void:
	_percent.text = "%.2f%%" % percent
	_info.text = "%s   %d kill   %d/%d" % [_clock(elapsed), kills, rank, alive]

static func _clock(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
