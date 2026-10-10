class_name UiKit
extends RefCounted

## "Neon Arcade" uslubidagi umumiy interfeys komponentlari.
## Hammasi kod bilan quriladi — uslub bir joyda turadi.
##
## Uslub: to'q binafsha fon, limon va malina neon urg'ular,
## qiyshaygan (skew) tugmalar va ularning tagidagi neon "rels".
## Bu yerda faqat **ko'rinish** bor — o'yin qoidalari va ekranlar
## tuzilishi o'zgarmaydi, chunki hamma funksiya nomi va parametri
## avvalgidek qoldi.

const BG := Color("120726")
const PANEL := Color("241b52")
const SURFACE := Color("15103a")
const STROKE := Color("473a7e")
const TEXT := Color("fff4fd")
const TEXT_DIM := Color("afa6d8")
const TEXT_FAINT := Color("756ca6")
const BLUE := Color("2e9bff")
const CORAL := Color("ff3d9a")
const MINT := Color("3be8b0")
const GOLD := Color("ffd23f")
const LIME := Color("d8ff3e")
const VIOLET := Color("9b4be0")

## Tugma qanchalik qiyshayadi (StyleBoxFlat.skew).
const SKEW := 0.23

const FONT_PATH := "res://assets/fonts/Rubik-Medium.ttf"
const BOLD_FONT_PATH := "res://assets/fonts/Rubik-Bold.ttf"
const DISPLAY_FONT_PATH := "res://assets/fonts/Exo2-BoldItalic.ttf"
## Rubik va Exo 2 kirill harflarini biladi, lekin hamma belgini emas —
## topilmagani DejaVuSans dan olinadi.
const FALLBACK_FONT_PATH := "res://assets/fonts/DejaVuSans.ttf"
const EMOJI_FONT_PATH := "res://assets/fonts/NotoColorEmoji.ttf"

static var _fonts_ready := false

## Shriftlarni bir marta o'rnatadi.
##
## Ikki shrift: interfeys matni Rubik, sarlavhalar esa Exo 2 (qalin
## kursiv). Ikkalasi ham kirill harflarini biladi, shuning uchun ruscha
## va qozoqcha ham bir xil ko'rinadi. Topilmagan belgi DejaVuSans dan,
## emoji esa NotoColorEmoji dan olinadi.
static func ensure_fonts() -> void:
	if _fonts_ready:
		return
	_fonts_ready = true
	# Shriftlar `load()` orqali olinadi: eksportda manba .ttf qolmaydi,
	# faqat Godot import qilgan nusxasi bo'ladi.
	var base: Font = load(FONT_PATH)
	var emoji: Font = load(EMOJI_FONT_PATH)
	var spare: Font = load(FALLBACK_FONT_PATH)
	_emoji_font = emoji
	_display_font = load(DISPLAY_FONT_PATH)
	_bold_font = load(BOLD_FONT_PATH)
	if base == null:
		push_error("Asosiy shrift yuklanmadi: %s" % FONT_PATH)
		base = spare
	if base == null:
		return
	var spares: Array[Font] = []
	if spare != null and spare != base:
		spares.append(spare)
	if emoji != null:
		spares.append(emoji)
	base.fallbacks = spares
	if _display_font != null:
		_display_font.fallbacks = spares
	if _bold_font != null:
		_bold_font.fallbacks = spares
	ThemeDB.fallback_font = base
	ThemeDB.fallback_font_size = 20

## Sarlavha shrifti — Exo 2 qalin kursiv.
static func display_font() -> Font:
	ensure_fonts()
	return _display_font

## Qalin interfeys shrifti.
static func bold_font() -> Font:
	ensure_fonts()
	return _bold_font

static var _display_font: Font
static var _bold_font: Font

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

static func style(bg: Color, radius: int = 14, border: int = 1,
		margin: int = 16) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = STROKE
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(margin)
	return box

static func panel(bg: Color = PANEL, margin: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(bg, 14, 1, margin))
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

## Sarlavha — Exo 2 qalin kursiv, katta harflar bilan.
##
## [method label] dan farqi faqat shrift va harf oralig'ida; qolgan
## hammasi bir xil, shuning uchun uni istalgan sarlavha o'rniga
## qo'yish mumkin.
static func title(text: String, size: int, color: Color = TEXT,
		align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := label(text.to_upper(), size, color, align)
	var font := display_font()
	if font != null:
		l.add_theme_font_override("font", font)
	l.add_theme_constant_override("line_spacing", -2)
	return l

## Bo'lim sarlavhasi: kichik, katta harflar, siyrak oraliq.
static func section(text: String) -> Label:
	var l := label(text.to_upper(), 13, TEXT_FAINT, HORIZONTAL_ALIGNMENT_LEFT)
	l.add_theme_constant_override("line_spacing", 2)
	return l

## Asosiy tugma: qiyshaygan to'rtburchak, tagida neon "rels".
##
## Rels — StyleBoxFlat soyasi: o'lchami nol, lekin pastga surilgan,
## shuning uchun tugma ostida ingichka yorqin chiziq bo'lib ko'rinadi.
## Matn qiyshaymaydi — Godot uni stildan alohida chizadi.
static func button(text: String, color: Color, big: bool = false) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.custom_minimum_size = Vector2(0, 64 if big else 54)
	b.add_theme_font_size_override("font_size", 23 if big else 18)
	var font := display_font()
	if font != null:
		b.add_theme_font_override("font", font)
	# Och rangli tugmada limon rels ko'rinmaydi — malina qo'yiladi.
	var rail := CORAL if color.get_luminance() > 0.52 else LIME
	var ink := Color("1a0f36") if color.get_luminance() > 0.52 else Color.WHITE
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var bg := color
		var lift := 5
		if state == "pressed":
			bg = color.darkened(0.2)
			lift = 2
		elif state == "hover":
			bg = color.lightened(0.12)
		elif state == "disabled":
			bg = SURFACE
		var box := style(bg, 7, 0, 12)
		box.skew = Vector2(SKEW, 0.0)
		box.content_margin_left = 20
		box.content_margin_right = 20
		if state != "disabled":
			box.shadow_color = Color(rail.r, rail.g, rail.b, 0.95)
			box.shadow_offset = Vector2(0, lift)
		b.add_theme_stylebox_override(state, box)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color",
			"font_focus_color"]:
		b.add_theme_color_override(state, ink)
	b.add_theme_color_override("font_disabled_color", TEXT_FAINT)
	return b

## Chekkasi chizilgan, ikkinchi darajali tugma. Relssiz.
static func ghost_button(text: String, color: Color = LIME) -> Button:
	var b := button(text, PANEL)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := style(Color(color.r, color.g, color.b,
			0.12 if state == "hover" else 0.0), 7, 2, 12)
		box.skew = Vector2(SKEW, 0.0)
		box.content_margin_left = 20
		box.content_margin_right = 20
		box.border_color = color
		b.add_theme_stylebox_override(state, box)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color",
			"font_focus_color"]:
		b.add_theme_color_override(state, color)
	return b

## Kichik dumaloq tugma (orqaga, pauza).
static func icon_button(text: String) -> Button:
	var b := button(text, PANEL)
	b.custom_minimum_size = Vector2(52, 52)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_font_override("font", ThemeDB.fallback_font)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := style(SURFACE if state != "hover" else PANEL, 26, 2, 4)
		box.border_color = Color(1, 1, 1, 0.26)
		b.add_theme_stylebox_override(state, box)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color",
			"font_focus_color"]:
		b.add_theme_color_override(state, TEXT)
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
		chip.add_theme_font_size_override("font_size", 15)
		chip.custom_minimum_size = Vector2(0, 42)
		var is_on := i == selected
		var ink := Color("1a0f36") if (is_on and accent.get_luminance() > 0.52) \
			else (Color.WHITE if is_on else TEXT_DIM)
		for state: String in ["normal", "hover", "pressed", "focus"]:
			var box := style(accent if is_on else SURFACE, 6, 1, 9)
			box.skew = Vector2(0.14, 0.0)
			box.content_margin_left = 14
			box.content_margin_right = 14
			box.border_color = accent if is_on else STROKE
			chip.add_theme_stylebox_override(state, box)
		for state: String in ["font_color", "font_hover_color",
				"font_pressed_color", "font_focus_color"]:
			chip.add_theme_color_override(state, ink)
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
	toggle.custom_minimum_size = Vector2(80, 40)
	toggle.add_theme_font_size_override("font_size", 14)
	var on_font := bold_font()
	if on_font != null:
		toggle.add_theme_font_override("font", on_font)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := style(LIME if value else SURFACE, 5, 1, 7)
		box.skew = Vector2(0.17, 0.0)
		box.content_margin_left = 12
		box.content_margin_right = 12
		box.border_color = LIME if value else STROKE
		toggle.add_theme_stylebox_override(state, box)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color",
			"font_focus_color"]:
		toggle.add_theme_color_override(state,
			Color("1a0f36") if value else TEXT_DIM)
	toggle.pressed.connect(func() -> void: on_toggle.call(not value))
	row.add_child(toggle)
	return row

## Dumaloq "tutqich" teksturasi — slayder uchun.
##
## Statik ro'yxatda saqlanmaydi: statik o'zgaruvchidagi resurs
## ilova yopilguncha turib qoladi va Godot chiqishda "resurs hali
## ishlatilmoqda" deb ogohlantiradi. 30x30 piksel esa shunchalik
## arzon — har slayderga qayta yasash muammo emas.
static func _grabber(color: Color, size: int = 30) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var r := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			# Chetida bir piksel yumshoq o'tish — "zinapoya" ko'rinmaydi.
			var alpha := clampf(r - d, 0.0, 1.0)
			if alpha <= 0.0:
				continue
			var tint := color if d < r - 4.0 else color.lightened(0.25)
			image.set_pixel(x, y, Color(tint.r, tint.g, tint.b, alpha))
	return ImageTexture.create_from_image(image)

## Balandlik kabi sonli sozlama uchun slayder qatori.
##
## `on_change` har qadamda chaqiriladi — ovoz darhol o'zgaradi.
## Qadam 5% bo'lgani uchun bir surishda 20 tadan ko'p chaqiriq
## bo'lmaydi, shuning uchun sozlamani shu yerda saqlash ham arzon.
static func slider_row(title: String, value: int, on_change: Callable,
		accent: Color = BLUE, step: int = 5) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var name_label := label(title, 18, TEXT if value > 0 else TEXT_DIM,
		HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	var value_label := label("%d%%" % value, 16,
		LIME if value > 0 else TEXT_FAINT, HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.custom_minimum_size = Vector2(54, 0)
	head.add_child(value_label)
	box.add_child(head)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(0, 40)
	# Barmoq uchun kengroq ushlash maydoni.
	slider.add_theme_constant_override("center_grabber", 1)
	slider.add_theme_constant_override("grabber_offset", 0)
	var rail := style(SURFACE, 4, 1, 0)
	rail.border_color = STROKE
	rail.content_margin_top = 4
	rail.content_margin_bottom = 4
	slider.add_theme_stylebox_override("slider", rail)
	var filled := style(LIME, 4, 0, 0)
	filled.content_margin_top = 4
	filled.content_margin_bottom = 4
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	for key: String in ["grabber", "grabber_highlight", "grabber_disabled"]:
		slider.add_theme_icon_override(key, _grabber(TEXT))
	slider.value_changed.connect(func(new_value: float) -> void:
		var percent := int(new_value)
		value_label.text = "%d%%" % percent
		value_label.add_theme_color_override("font_color",
			LIME if percent > 0 else TEXT_FAINT)
		name_label.add_theme_color_override("font_color",
			TEXT if percent > 0 else TEXT_DIM)
		on_change.call(percent))
	box.add_child(slider)
	return box

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
		shade.color = Color(0.047, 0.027, 0.125, 0.88)
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
