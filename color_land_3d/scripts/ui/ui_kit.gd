class_name UiKit
extends RefCounted

## Umumiy interfeys komponentlari — "yumshoq multfilm" uslubi.
##
## Uslubning uch qoidasi butun o'yinda bir xil:
##
##  1. **Qalin to'q ko'k kontur** ([constant INK]) — har bir tugma,
##     karta va matn atrofida. Shu kontur hamma narsani bir oilaga
##     bog'laydi.
##  2. **Pastki poydevor** — tugma ostidagi to'qroq qavat. Bosilganda
##     poydevor pasayadi va tugma "bosilgandek" ko'rinadi.
##  3. **Ustki yaltirash** — tugmaning yuqori qismidagi oq yo'l.
##
## Bu yerda faqat **ko'rinish** bor: funksiya nomlari va parametrlari
## o'zgarmaydi, shuning uchun ekranlar tuzilishi va o'yin qoidalari
## bu faylga bog'liq emas.

# ——— Ranglar ———
#
# Menyu foni ko'k gradient, o'yin maydoni esa och yalpiz. Tugmalar
# uchta rang: sariq (asosiy), yashil (tasdiq), qizil (ogohlantirish).

## Menyu fonining yuqorisi va pastki qismi.
const BG := Color("2e6bf0")
const BG_LOW := Color("5bc8f5")
## O'yin maydonining foni.
const FIELD := Color("eafbf4")
## Hamma narsaning konturi va matn soyasi.
const INK := Color("173a75")

const PANEL := Color("3c8bf5")
const SURFACE := Color("cfe9ff")
const STROKE := INK
const TEXT := Color("ffffff")
const TEXT_DIM := Color("dcefff")
const TEXT_FAINT := Color("8fb8dc")

const YELLOW := Color("ffd93b")
const GREEN := Color("7be04a")
const RED := Color("f04545")
const BLUE := Color("2e6bf0")
const SKY := Color("5bc8f5")
const VIOLET := Color("9b6bff")

## Eski nomlar — ekranlar shular bilan yozilgan.
const GOLD := YELLOW
const LIME := GREEN
const CORAL := RED
const MINT := GREEN

## Kontur qalinligi (piksel).
const OUTLINE := 4
## Tugma ostidagi poydevor balandligi.
const LIFT := 10

const FONT_PATH := "res://assets/fonts/Rubik-Medium.ttf"
const BOLD_FONT_PATH := "res://assets/fonts/Rubik-Bold.ttf"
## Sarlavha shrifti: qalin, yumaloq, o'yinbop.
##
## Lilita One va Fredoka da kirill yo'q (tekshirilgan), bizda esa
## rus va qozoq tillari bor — shuning uchun Nunito ExtraBold.
const DISPLAY_FONT_PATH := "res://assets/fonts/Nunito-ExtraBold.ttf"
## Rubik va Nunito lotin va kirillni biladi, lekin hamma belgini
## emas — topilmagani quyidagi zaxiralardan olinadi. Arabcha Rubik
## va DejaVuSans da bor; xitoy, yapon, koreys va hind yozuvlari
## uchun Noto shriftlari **faqat ishlatiladigan belgilarga**
## qisqartirilgan (`tool/`).
const FALLBACK_FONT_PATH := "res://assets/fonts/DejaVuSans.ttf"
const SCRIPT_FONT_PATHS: PackedStringArray = [
	"res://assets/fonts/NotoSC.ttf",
	"res://assets/fonts/NotoJP.ttf",
	"res://assets/fonts/NotoKR.ttf",
	"res://assets/fonts/NotoDevanagari.ttf",
]
const EMOJI_FONT_PATH := "res://assets/fonts/NotoColorEmoji.ttf"

static var _fonts_ready := false

## Shriftlarni bir marta o'rnatadi.
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
	for path: String in SCRIPT_FONT_PATHS:
		var extra: Font = load(path)
		if extra != null:
			spares.append(extra)
	if emoji != null:
		spares.append(emoji)
	base.fallbacks = spares
	if _display_font != null:
		_display_font.fallbacks = spares
	if _bold_font != null:
		_bold_font.fallbacks = spares
	ThemeDB.fallback_font = base
	ThemeDB.fallback_font_size = 20

## Sarlavha shrifti.
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
static func emoji_font() -> Font:
	ensure_fonts()
	return _emoji_font

static var _emoji_font: Font

# ——— Asosiy shakllar ———

static func style(bg: Color, radius: int = 18, border: int = OUTLINE,
		margin: int = 16) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = INK
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(margin)
	return box

## Poydevorli shakl: tagida to'qroq qavat turadi va 3D bo'rtgan hajm hosil qiladi.
##
## `lift` — poydevor balandligi; bosilgan tugmada u kichrayadi va matn
## pastga suriladi, shuning uchun tugma 3D bosilgandek ko'rinadi.
static func style_solid(bg: Color, radius: int = 22, lift: int = LIFT,
		margin: int = 14) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = INK
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(margin)
	box.border_width_left = OUTLINE
	box.border_width_top = OUTLINE
	box.border_width_right = OUTLINE
	# 3D taglik: pastki chegara qalinroq bo'lib, tugma ostidagi bo'rtgan qavatni hosil qiladi!
	box.border_width_bottom = OUTLINE + lift

	if lift > 0:
		# To'q 3D soya (drop shadow): tugma atrofidagi chuqurlik va hajm
		box.shadow_color = Color(0.04, 0.08, 0.22, 0.50)
		box.shadow_size = 8
		box.shadow_offset = Vector2(0, lift * 0.5 + 3)
	return box

static func panel(bg: Color = PANEL, margin: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style_solid(bg, 20, 6, margin))
	return p

## Tugmaning ustki yaltirashi — yuqoridagi yarim shaffof oq yo'l.
## Tugmaga 3D shaffof/yaltiroq hajm beradi.
static func _gloss(host: Control, height: int = 14, inset: int = 14) -> void:
	var shine := Panel.new()
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shine.anchor_right = 1.0
	shine.offset_left = inset
	shine.offset_right = -inset
	shine.offset_top = 6
	shine.offset_bottom = 6 + height
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.32)
	box.set_corner_radius_all(height / 2)
	shine.add_theme_stylebox_override("panel", box)
	host.add_child(shine)

# ——— Matn ———

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

## Sarlavha — qalin yumaloq shrift, oq matn va to'q ko'k kontur.
static func title(text: String, size: int, color: Color = TEXT,
		align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := label(text.to_upper(), size, color, align)
	var font := display_font()
	if font != null:
		l.add_theme_font_override("font", font)
	l.add_theme_constant_override("outline_size", maxi(4, size / 4))
	l.add_theme_color_override("font_outline_color", INK)
	return l

## Bo'lim sarlavhasi: kichik, katta harflar.
static func section(text: String) -> Label:
	var l := label(text.to_upper(), 14, TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	var font := display_font()
	if font != null:
		l.add_theme_font_override("font", font)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", INK)
	return l

# ——— Tugmalar ———
 
## Asosiy tugma: katta, yumaloq, qalin 3D poydevorli va yaltiroq.
static func button(text: String, color: Color, big: bool = false) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	var height := 104 if big else 88
	b.custom_minimum_size = Vector2(0, height)
	b.add_theme_font_size_override("font_size", 30 if big else 24)
	var font := display_font()
	if font != null:
		b.add_theme_font_override("font", font)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var bg := color
		var lift := LIFT + (4 if big else 2)
		var m_top := 14
		match state:
			"pressed":
				bg = color.darkened(0.08)
				lift = 3
				m_top = 22
			"hover":
				bg = color.lightened(0.08)
			"disabled":
				bg = SURFACE.darkened(0.12)
				lift = 4
		var box := style_solid(bg, 24, lift, 16)
		box.content_margin_left = 22
		box.content_margin_right = 22
		box.content_margin_top = m_top
		b.add_theme_stylebox_override(state, box)
	_ink_text(b)
	b.add_theme_constant_override("outline_size", 10)
	_gloss(b, 16 if big else 13, 18)
	return b

## Matn: oq, atrofida to'q ko'k kontur — har qanday rang ustida
## o'qiladi.
static func _ink_text(b: Button) -> void:
	for state: String in ["font_color", "font_hover_color",
			"font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, TEXT)
	b.add_theme_color_override("font_disabled_color", TEXT_FAINT)
	b.add_theme_constant_override("outline_size", 8)
	b.add_theme_color_override("font_outline_color", INK)

## Ikkinchi darajali tugma: 3D bo'rtgan rangli fon va to'q ko'k konturli matn.
static func ghost_button(text: String, color: Color = YELLOW) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.custom_minimum_size = Vector2(0, 86)
	b.add_theme_font_size_override("font_size", 22)
	var font := display_font()
	if font != null:
		b.add_theme_font_override("font", font)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var bg := color
		var lift := LIFT + 2
		var m_top := 13
		match state:
			"pressed":
				bg = color.darkened(0.1)
				lift = 3
				m_top = 18
			"hover":
				bg = color.lightened(0.08)
		var box := style_solid(bg, 24, lift, 14)
		box.content_margin_left = 20
		box.content_margin_right = 20
		box.content_margin_top = m_top
		b.add_theme_stylebox_override(state, box)
	_ink_text(b)
	_gloss(b, 14, 16)
	return b

## Bosh tugma — katta 3D bo'rtgan dumaloq, o'rtasida matn va yuqorisida yaltiroq doira.
static func round_button(text: String, color: Color,
		diameter: int = 240) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.custom_minimum_size = Vector2(diameter, diameter)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", maxi(32, int(diameter / 5.0)))
	var font := display_font()
	if font != null:
		b.add_theme_font_override("font", font)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var bg := color
		var lift := LIFT + 8
		var m_top := 8
		match state:
			"pressed":
				bg = color.darkened(0.08)
				lift = 4
				m_top = 18
			"hover":
				bg = color.lightened(0.08)
		var box := style_solid(bg, diameter / 2, lift, 8)
		box.content_margin_top = m_top
		b.add_theme_stylebox_override(state, box)
	_ink_text(b)
	b.add_theme_constant_override("outline_size", 12)

	# 3D doirasimon yaltirash (sferik shisha/konfet effekti)
	var shine := Panel.new()
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shine.set_anchors_preset(Control.PRESET_TOP_WIDE)
	shine.offset_left = diameter * 0.20
	shine.offset_right = -diameter * 0.20
	shine.offset_top = diameter * 0.08
	shine.offset_bottom = diameter * 0.26
	var shine_box := StyleBoxFlat.new()
	shine_box.bg_color = Color(1, 1, 1, 0.45)
	shine_box.set_corner_radius_all(int(diameter * 0.12))
	shine.add_theme_stylebox_override("panel", shine_box)
	b.add_child(shine)
	return b

## Pastki qatordagi tugma: ustida belgi, tagida nomi va 3D bo'rtgan ko'rinish.
static func tab_button(icon: String, text: String,
		tint: Color = YELLOW, is_active: bool = false) -> Button:
	var b := Button.new()
	var height: int = 104 if is_active else 94
	b.custom_minimum_size = Vector2(0, height)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var base_bg := PANEL.lightened(0.22) if is_active else PANEL
	var lift_norm := 12 if is_active else 8
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var bg := base_bg
		var lift := lift_norm
		var m_top := 0
		match state:
			"pressed":
				bg = base_bg.darkened(0.08)
				lift = 3
				m_top = 6
			"hover":
				bg = base_bg.lightened(0.08)
		var box := style_solid(bg, 22, lift, 6)
		box.content_margin_top = m_top
		b.add_theme_stylebox_override(state, box)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 3)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_size: float = 38.0 if is_active else 34.0
	var mark := GameIcon.new(icon, icon_size, tint if not is_active else tint.lightened(0.15))
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(mark)

	var lbl := label(text, 14 if is_active else 13, TEXT if is_active else TEXT_DIM)
	lbl.add_theme_constant_override("outline_size", 4 if is_active else 2)
	lbl.add_theme_color_override("font_outline_color", INK)
	box.add_child(lbl)
	b.add_child(box)

	_gloss(b, 12, 10)
	return b

## Dumaloq 3D tugma (orqaga, pauza, sozlama, avatar).
static func icon_button(text: String, size: int = 84) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(size, size)
	b.add_theme_font_size_override("font_size", maxi(28, int(size * 0.42)))
	b.add_theme_font_override("font", ThemeDB.fallback_font)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var bg := PANEL.lightened(0.08) if state == "hover" else PANEL
		var lift := LIFT + 2
		var m_top := 0
		match state:
			"pressed":
				bg = PANEL.darkened(0.08)
				lift = 3
				m_top = 6
		var box := style_solid(bg, size / 2, lift, 4)
		box.content_margin_top = m_top
		b.add_theme_stylebox_override(state, box)
	_ink_text(b)
	_gloss(b, 12, int(size * 0.20))
	return b

## Tanlov chiplari qatori. Tanlangan indeks bilan signal beradi.
## Tanlangan chip **doim yashil**: o'yinchining o'z rangi ko'k fonda
## yo'qolib ketardi va tanlangani bilinmasdi. Yashil — "yoqilgan"
## rangi, butun o'yinda bir xil.
static func chips(values: PackedStringArray, selected: int,
		on_select: Callable, accent: Color = GREEN, height: int = 52,
		font_size: int = 17) -> FlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	for i in values.size():
		var chip := Button.new()
		chip.text = values[i]
		chip.add_theme_font_size_override("font_size", font_size)
		chip.custom_minimum_size = Vector2(0, height)
		var font := display_font()
		if font != null:
			chip.add_theme_font_override("font", font)
		var is_on := i == selected
		for state: String in ["normal", "hover", "pressed", "focus"]:
			var bg := GREEN if is_on else SURFACE
			if state == "hover":
				bg = bg.lightened(0.08)
			var box := style_solid(bg, 16, 4 if is_on else 3, 8)
			box.content_margin_left = 14
			box.content_margin_right = 14
			chip.add_theme_stylebox_override(state, box)
		for state: String in ["font_color", "font_hover_color",
				"font_pressed_color", "font_focus_color"]:
			chip.add_theme_color_override(state, TEXT if is_on else INK)
		chip.add_theme_constant_override("outline_size", 6 if is_on else 0)
		chip.add_theme_color_override("font_outline_color", INK)
		var index := i
		chip.pressed.connect(func() -> void: on_select.call(index))
		row.add_child(chip)
	return row

## Yoqish/o'chirish qatori.
static func switch_row(title: String, value: bool, on_toggle: Callable,
		accent: Color = GREEN) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_label := label(title, 18, INK, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var toggle := Button.new()
	toggle.text = Strings.t("switchOn") if value else Strings.t("switchOff")
	toggle.custom_minimum_size = Vector2(96, 52)
	toggle.add_theme_font_size_override("font_size", 16)
	var font := display_font()
	if font != null:
		toggle.add_theme_font_override("font", font)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var bg := (accent if value else RED)
		if state == "hover":
			bg = bg.lightened(0.08)
		toggle.add_theme_stylebox_override(state,
			style_solid(bg, 14, 2 if state == "pressed" else 5, 8))
	_ink_text(toggle)
	toggle.pressed.connect(func() -> void: on_toggle.call(not value))
	row.add_child(toggle)
	return row

## Dumaloq "tutqich" teksturasi — slayder uchun.
##
## Statik ro'yxatda saqlanmaydi: statik o'zgaruvchidagi resurs
## ilova yopilguncha turib qoladi va Godot chiqishda "resurs hali
## ishlatilmoqda" deb ogohlantiradi.
static func _grabber(color: Color, size: int = 34) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var mid := (size - 1) * 0.5
	var r := mid - 1.0
	for y in size:
		for x in size:
			var d := Vector2(x - mid, y - mid).length()
			if d > r:
				continue
			# Chetida kontur, ichida rang.
			image.set_pixel(x, y, INK if d > r - OUTLINE else color)
	return ImageTexture.create_from_image(image)

## Slayder qatori: nomi, qiymati (foiz) va o'zi.
static func slider_row(title: String, value: int, on_change: Callable,
		accent: Color = GREEN) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var head := HBoxContainer.new()
	var name_label := label(title, 17, INK, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	var value_label := label("%d%%" % value, 17, INK)
	head.add_child(value_label)
	box.add_child(head)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = value
	slider.custom_minimum_size = Vector2(0, 40)

	var back := style(SURFACE.darkened(0.08), 9, OUTLINE, 0)
	back.content_margin_top = 9
	back.content_margin_bottom = 9
	slider.add_theme_stylebox_override("slider", back)
	var fill := style(accent, 9, 0, 0)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	var knob := _grabber(accent.lightened(0.25))
	slider.add_theme_icon_override("grabber", knob)
	slider.add_theme_icon_override("grabber_highlight", knob)

	slider.value_changed.connect(func(v: float) -> void:
		value_label.text = "%d%%" % int(v)
		on_change.call(int(v)))
	box.add_child(slider)
	return box

## Rang tanlash kvadrati.
static func color_chip(index: int, selected: bool,
		on_tap: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(54, 54)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := style_solid(Palette.head(index), 14,
			2 if state == "pressed" else 4, 0)
		if selected:
			box.border_color = TEXT
			box.set_border_width_all(OUTLINE + 2)
		b.add_theme_stylebox_override(state, box)
	b.pressed.connect(func() -> void: on_tap.call(index))
	return b

static func spacer(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c

# ——— HUD komponentlari ———

## Kapsula: chizilgan belgi va yonida son. HUD va menyu hisoblari.
##
## `icon` — [GameIcon] nomi ("coin", "skull", "gem", "ticket").
static func capsule(icon: String, value: String, tint: Color = YELLOW,
		width: int = 0, with_plus: bool = false, on_plus: Callable = Callable()) -> PanelContainer:
	var shell := PanelContainer.new()
	shell.add_theme_stylebox_override("panel", style_solid(TEXT, 26, 6, 8))
	shell.mouse_filter = Control.MOUSE_FILTER_PASS if with_plus else Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	shell.add_child(row)
	row.add_child(GameIcon.new(icon, 38.0, tint))

	var text := title(value, 22, INK, HORIZONTAL_ALIGNMENT_CENTER)
	text.add_theme_constant_override("outline_size", 0)
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if width > 0:
		text.custom_minimum_size = Vector2(width, 0)
	row.add_child(text)

	if with_plus:
		var plus_btn := Button.new()
		plus_btn.text = "+"
		plus_btn.custom_minimum_size = Vector2(28, 28)
		plus_btn.add_theme_stylebox_override("normal", style_solid(GREEN, 14, 2, 2))
		plus_btn.add_theme_stylebox_override("hover", style_solid(GREEN.lightened(0.1), 14, 2, 2))
		plus_btn.add_theme_stylebox_override("pressed", style_solid(GREEN.darkened(0.1), 14, 1, 1))
		plus_btn.add_theme_font_size_override("font_size", 18)
		var font := display_font()
		if font != null:
			plus_btn.add_theme_font_override("font", font)
		_ink_text(plus_btn)
		if on_plus.is_valid():
			plus_btn.pressed.connect(on_plus)
		row.add_child(plus_btn)
	return shell

## Katta 3D Play tugmasi — Screen 1 dagi oq uchburchak va "PLAY" yozuvi bilan.
static func play_button(text: String = "PLAY", color: Color = YELLOW,
		p_width: int = 340, p_height: int = 88) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(p_width, p_height)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var bg := color if state != "pressed" else color.darkened(0.12)
		var lift := 10 if state != "pressed" else 3
		var m_top := 10 if state != "pressed" else 18
		var box := style_solid(bg, 32, lift, 18)
		box.content_margin_top = m_top
		b.add_theme_stylebox_override(state, box)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)

	var tri := Control.new()
	tri.custom_minimum_size = Vector2(28, 32)
	tri.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tri.draw.connect(func() -> void:
		var pts := PackedVector2Array([
			Vector2(4, 2), Vector2(26, 16), Vector2(4, 30)
		])
		tri.draw_colored_polygon(pts, Color.WHITE)
		tri.draw_polyline(pts, INK, 4.0, true))
	row.add_child(tri)

	var lbl := title(text.to_upper(), 38, Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 12)
	lbl.add_theme_color_override("font_outline_color", INK)
	row.add_child(lbl)

	_gloss(b, 20, 22)
	return b

## Keng progress chizig'i — egallangan foiz.
##
## Oxiridagi yulduz 100% belgisi; `mark` — eng yaxshi natija
## (uchburchak bilan belgilanadi), manfiy bo'lsa chizilmaydi.
static func progress_bar(percent: float, tint: Color,
		mark: float = -1.0) -> Control:
	var shell := PanelContainer.new()
	shell.add_theme_stylebox_override("panel", style_solid(PANEL.darkened(0.35),
		24, 7, 6))
	shell.custom_minimum_size = Vector2(0, 62)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var lane := Control.new()
	lane.clip_contents = true
	shell.add_child(lane)

	var fill := Panel.new()
	fill.name = "Fill"
	fill.add_theme_stylebox_override("panel", style(tint, 17, 0, 0))
	fill.anchor_bottom = 1.0
	fill.anchor_right = clampf(percent / 100.0, 0.02, 1.0)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lane.add_child(fill)

	var text := title("%d%%" % int(round(percent)), 24, TEXT,
		HORIZONTAL_ALIGNMENT_LEFT)
	text.name = "Value"
	text.set_anchors_preset(Control.PRESET_FULL_RECT)
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.position = Vector2(16, 0)
	lane.add_child(text)
	if mark >= 0.0:
		var best := label("▲", 14, YELLOW)
		best.anchor_left = clampf(mark / 100.0, 0.0, 1.0)
		best.anchor_top = 1.0
		best.position = Vector2(-7, -7)
		lane.add_child(best)
	return shell

const DonutProgressNode := preload("res://scripts/ui/donut_progress.gd")

## Dumaloq hudud ko'rsatkichi (Donut Chart) — HUD uchun.
static func donut_chart(percent: float, tint: Color) -> Control:
	return DonutProgressNode.new(percent, tint)

## O'yinchi profil kartasi (bosh menyu yuqori chap burchagi): avatar, daraja, ism va XP.
static func profile_pill(avatar: String, avatar_img: String, nickname: String, level: int, xp: int, xp_max: int, on_tap: Callable) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(210, 68)
	btn.flat = true
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var bg := PANEL.darkened(0.18) if state == "normal" else PANEL
		var lift := 5 if state != "pressed" else 2
		var m_top := 4 if state != "pressed" else 7
		var box := style_solid(bg, 22, lift, 6)
		box.content_margin_top = m_top
		box.content_margin_left = 6
		box.content_margin_right = 14
		btn.add_theme_stylebox_override(state, box)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(row)

	var avatar_box := Control.new()
	avatar_box.custom_minimum_size = Vector2(52, 52)
	avatar_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	avatar_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var av_mark := AvatarView.new(avatar, 48.0, avatar_img)
	av_mark.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar_box.add_child(av_mark)

	var lvl_badge := Panel.new()
	lvl_badge.add_theme_stylebox_override("panel", style(YELLOW, 8, 2, 0))
	lvl_badge.anchor_top = 1.0
	lvl_badge.anchor_bottom = 1.0
	lvl_badge.offset_left = -2
	lvl_badge.offset_right = 28
	lvl_badge.offset_top = -18
	lvl_badge.offset_bottom = 2
	var lvl_lbl := label(str(level), 11, INK, HORIZONTAL_ALIGNMENT_CENTER)
	lvl_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lvl_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var f := display_font()
	if f != null:
		lvl_lbl.add_theme_font_override("font", f)
	lvl_badge.add_child(lvl_lbl)
	avatar_box.add_child(lvl_badge)
	row.add_child(avatar_box)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var name_lbl := title(nickname, 16, TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	name_lbl.clip_text = true
	info.add_child(name_lbl)

	# XP bar
	var xp_lane := PanelContainer.new()
	xp_lane.add_theme_stylebox_override("panel", style(Color(0.06, 0.12, 0.25, 0.8), 6, 2, 2))
	xp_lane.custom_minimum_size = Vector2(0, 14)
	xp_lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var xp_clip := Control.new()
	xp_clip.clip_contents = true
	xp_lane.add_child(xp_clip)
	var xp_fill := Panel.new()
	xp_fill.add_theme_stylebox_override("panel", style(GREEN, 4, 0, 0))
	xp_fill.anchor_bottom = 1.0
	var xp_ratio := clampf(float(xp) / maxf(1.0, float(xp_max)), 0.05, 1.0)
	xp_fill.anchor_right = xp_ratio
	xp_clip.add_child(xp_fill)
	info.add_child(xp_lane)

	row.add_child(info)
	_gloss(btn, 10, 8)
	btn.pressed.connect(on_tap)
	return btn


# ——— Fon va joylashuv ———

## Ekranni egallaydigan qatlam. Menyuda — ko'k gradient fon.
static func overlay(dim: bool = true) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP if dim \
		else Control.MOUSE_FILTER_IGNORE
	if dim:
		var sky := TextureRect.new()
		sky.texture = _sky_texture()
		sky.set_anchors_preset(Control.PRESET_FULL_RECT)
		sky.stretch_mode = TextureRect.STRETCH_SCALE
		sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sky.modulate = Color(1, 1, 1, 0.97)
		root.add_child(sky)
	return root

## Ko'k gradient fon. Resurs statik saqlanmaydi (chiqishda
## ogohlantirish bermasin), 2x64 piksel esa arzon.
static func _sky_texture() -> GradientTexture2D:
	var ramp := Gradient.new()
	ramp.set_color(0, BG)
	ramp.set_color(1, BG_LOW)
	var tex := GradientTexture2D.new()
	tex.gradient = ramp
	tex.width = 2
	tex.height = 64
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	return tex

## Markazda, cheklangan kenglikdagi, aylanuvchi ustun.
static func centered_column(root: Control, max_width: int = 560) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	root.add_child(margin)

	# Barmoq bilan surib aylantirish uchun — oddiy ScrollContainer da
	# bosilgan tugma surish hodisasini yeb qo'yadi.
	var scroll := DragScroll.new()
	margin.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(max_width, 0)
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	return box
