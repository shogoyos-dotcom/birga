class_name UiKit
extends RefCounted

## "Arcade Grid" uslubidagi umumiy interfeys komponentlari.
## Hammasi kod bilan quriladi — uslub bir joyda turadi.

const BG := Color("100e1b")
const PANEL := Color("1a1728")
const SURFACE := Color("231f38")
const STROKE := Color("2e2946")
const TEXT := Color("f4f2ff")
const TEXT_DIM := Color("9a93bd")
const TEXT_FAINT := Color("635c85")
const BLUE := Color("3d7bff")
const CORAL := Color("ff6b5b")
const MINT := Color("2fd6a6")
const GOLD := Color("ffc43d")

const FONT_PATH := "res://assets/fonts/DejaVuSans.ttf"
const EMOJI_FONT_PATH := "res://assets/fonts/NotoColorEmoji.ttf"

static var _fonts_ready := false

## Shriftlarni bir marta o'rnatadi.
##
## Godot'ning ichki shrifti emoji va bayroqlarni bilmaydi, kengaytirilgan
## kirill harflarini ham to'liq qoplamaydi — shuning uchun DejaVuSans
## asosiy, NotoColorEmoji esa zaxira qilib qo'yiladi.
static func ensure_fonts() -> void:
	if _fonts_ready:
		return
	_fonts_ready = true
	# Shriftlar `load()` orqali olinadi: eksportda manba .ttf qolmaydi,
	# faqat Godot import qilgan nusxasi bo'ladi.
	var base: Font = load(FONT_PATH)
	var emoji: Font = load(EMOJI_FONT_PATH)
	_emoji_font = emoji
	if base == null:
		push_error("Asosiy shrift yuklanmadi: %s" % FONT_PATH)
		return
	if emoji != null:
		base.fallbacks = [emoji]
	ThemeDB.fallback_font = base
	ThemeDB.fallback_font_size = 20

## Emoji shrifti — alohida.
##
## Zaxira shrift sifatida ishlatilganda bayroqlar buziladi: ikki
## "regional indicator" belgisi alohida-alohida zaxiraga tushadi va
## ligatura (ya'ni bayroq) hosil bo'lmay, qutichali harflar chiqadi.
## Shuning uchun faqat emoji yoziladigan joylarda shu shrift
## bevosita qo'yiladi.
static func emoji_font() -> Font:
	ensure_fonts()
	return _emoji_font

static var _emoji_font: Font

static func style(bg: Color, radius: int = 18, border: int = 2,
		margin: int = 18) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = STROKE
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(margin)
	return box

static func panel(bg: Color = PANEL, margin: int = 18) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(bg, 18, 2, margin))
	return p

static func label(text: String, size: int, color: Color = TEXT,
		align: int = HORIZONTAL_ALIGNMENT_CENTER, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

## Bo'lim sarlavhasi: kichik, katta harflar, siyrak oraliq.
static func section(text: String) -> Label:
	var l := label(text.to_upper(), 13, TEXT_FAINT, HORIZONTAL_ALIGNMENT_LEFT)
	l.add_theme_constant_override("line_spacing", 2)
	return l

static func button(text: String, color: Color, big: bool = false) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.custom_minimum_size = Vector2(0, 68 if big else 56)
	b.add_theme_font_size_override("font_size", 24 if big else 18)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var bg := color
		if state == "pressed":
			bg = color.darkened(0.22)
		elif state == "hover":
			bg = color.lightened(0.1)
		elif state == "disabled":
			bg = SURFACE
		var box := style(bg, 16, 0, 10)
		b.add_theme_stylebox_override(state, box)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color",
			"font_focus_color"]:
		b.add_theme_color_override(state, Color.WHITE)
	b.add_theme_color_override("font_disabled_color", TEXT_FAINT)
	return b

## Chekkasi chizilgan, ikkinchi darajali tugma.
static func ghost_button(text: String, color: Color = TEXT_DIM) -> Button:
	var b := button(text, PANEL)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := style(PANEL if state != "hover" else SURFACE, 16, 2, 10)
		box.border_color = color
		b.add_theme_stylebox_override(state, box)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color",
			"font_focus_color"]:
		b.add_theme_color_override(state, color)
	return b

## Kichik kvadrat tugma (sozlamalar, orqaga).
static func icon_button(text: String) -> Button:
	var b := button(text, PANEL)
	b.custom_minimum_size = Vector2(56, 52)
	b.add_theme_font_size_override("font_size", 22)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state,
			style(PANEL if state != "hover" else SURFACE, 14, 2, 6))
	return b

## Tanlov chiplari qatori. Tanlangan indeks bilan signal beradi.
static func chips(values: PackedStringArray, selected: int,
		on_select: Callable, accent: Color = BLUE) -> FlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	for i in values.size():
		var chip := Button.new()
		chip.text = values[i]
		chip.add_theme_font_size_override("font_size", 16)
		chip.custom_minimum_size = Vector2(0, 46)
		var is_on := i == selected
		for state: String in ["normal", "hover", "pressed", "focus"]:
			var box := style(accent if is_on else SURFACE, 12, 2, 10)
			box.border_color = accent if is_on else STROKE
			chip.add_theme_stylebox_override(state, box)
		for state: String in ["font_color", "font_hover_color",
				"font_pressed_color", "font_focus_color"]:
			chip.add_theme_color_override(state, Color.WHITE if is_on else TEXT_DIM)
		var index := i
		chip.pressed.connect(func() -> void: on_select.call(index))
		row.add_child(chip)
	return row

## Yoqish/o'chirish qatori.
static func switch_row(title: String, value: bool, on_toggle: Callable,
		accent: Color = BLUE) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_label := label(title, 18, TEXT if value else TEXT_DIM,
		HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var toggle := Button.new()
	toggle.text = "ON" if value else "OFF"
	toggle.custom_minimum_size = Vector2(86, 46)
	toggle.add_theme_font_size_override("font_size", 16)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := style(accent if value else SURFACE, 12, 2, 8)
		box.border_color = accent if value else STROKE
		toggle.add_theme_stylebox_override(state, box)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color",
			"font_focus_color"]:
		toggle.add_theme_color_override(state, Color.WHITE if value else TEXT_DIM)
	toggle.pressed.connect(func() -> void: on_toggle.call(not value))
	row.add_child(toggle)
	return row

## Rang tanlash katakchasi.
static func color_chip(index: int, selected: bool,
		on_tap: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(46, 46)
	var color := Palette.head(index)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := style(color, 12, 3, 0)
		box.border_color = TEXT if selected else Color(0, 0, 0, 0)
		b.add_theme_stylebox_override(state, box)
	b.pressed.connect(func() -> void: on_tap.call(index))
	return b

static func spacer(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c

## Ekranni egallaydigan, qorong'ilashtirilgan qatlam.
static func overlay(dim: bool = true) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP if dim \
		else Control.MOUSE_FILTER_IGNORE
	if dim:
		var shade := ColorRect.new()
		shade.color = Color(BG.r, BG.g, BG.b, 0.9)
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(shade)
	return root

## Markazda, cheklangan kenglikdagi, aylanuvchi ustun.
static func centered_column(root: Control, max_width: int = 460) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	root.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(max_width, 0)
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	return box
