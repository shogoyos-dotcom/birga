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
const LIFT := 7

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

## Poydevorli shakl: tagida to'qroq qavat turadi.
##
## `lift` — poydevor balandligi; bosilgan tugmada u kichrayadi,
## shuning uchun tugma pastga bosilgandek ko'rinadi.
static func style_solid(bg: Color, radius: int = 18, lift: int = LIFT,
		margin: int = 14) -> StyleBoxFlat:
	var box := style(bg, radius, OUTLINE, margin)
	if lift > 0:
		# Poydevor — tugma rangining to'q, konturga tortilgan varianti.
		box.shadow_color = bg.darkened(0.42).lerp(INK, 0.35)
		box.shadow_size = 0
		box.shadow_offset = Vector2(0, lift)
	return box

static func panel(bg: Color = PANEL, margin: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(bg, 20, OUTLINE, margin))
	return p

## Tugmaning ustki yaltirashi — yuqoridagi oq yo'l.
##
## Tugmaning bolasi bo'lib qo'shiladi, shuning uchun matndan
## keyin chiziladi; alfa past, aks holda matnni oqartirib yuborardi.
static func _gloss(host: Control, height: int = 14) -> void:
	var shine := Panel.new()
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shine.anchor_right = 1.0
	shine.offset_left = 12
	shine.offset_right = -12
	shine.offset_top = 8
	shine.offset_bottom = 8 + height
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.26)
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

## Asosiy tugma: yumaloq, konturli, poydevorli.
static func button(text: String, color: Color, big: bool = false) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	var height := 84 if big else 70
	b.custom_minimum_size = Vector2(0, height)
	b.add_theme_font_size_override("font_size", 28 if big else 22)
	var font := display_font()
	if font != null:
		b.add_theme_font_override("font", font)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var bg := color
		var lift := LIFT
		match state:
			"pressed":
				bg = color.darkened(0.08)
				lift = 2
			"hover":
				bg = color.lightened(0.08)
			"disabled":
				bg = SURFACE.darkened(0.12)
				lift = 3
		var box := style_solid(bg, 20, lift, 12)
		box.content_margin_left = 18
		box.content_margin_right = 18
		b.add_theme_stylebox_override(state, box)
	_ink_text(b)
	_gloss(b, 12 if big else 10)
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

## Ikkinchi darajali tugma: och fon, to'q matn.
##
## Avval u shaffof edi — ko'k fon ustida yo'qolib ketardi va hamma
## tugma bir xil ko'rinardi. Endi fon och, matn to'q ko'k, urg'u
## rangi esa fonga ozgina aralashtiriladi.
static func ghost_button(text: String, color: Color = YELLOW) -> Button:
	var b := button(text, color)
	var face := SURFACE.lerp(color, 0.22)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var bg := face.lightened(0.08) if state == "hover" else face
		var box := style_solid(bg, 20, 2 if state == "pressed" else LIFT, 12)
		box.content_margin_left = 18
		box.content_margin_right = 18
		b.add_theme_stylebox_override(state, box)
	for state: String in ["font_color", "font_hover_color",
			"font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, INK)
	b.add_theme_constant_override("outline_size", 0)
	return b

## Bosh tugma — katta dumaloq, o'rtasida matn.
##
## Menyuda bitta shunaqa tugma bo'ladi: o'yinchi nimani bosishini
## bir qarashda bilsin.
static func round_button(text: String, color: Color,
		diameter: int = 150) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.custom_minimum_size = Vector2(diameter, diameter)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", maxi(22, diameter / 5))
	var font := display_font()
	if font != null:
		b.add_theme_font_override("font", font)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var bg := color
		var lift := LIFT + 3
		match state:
			"pressed":
				bg = color.darkened(0.08)
				lift = 3
			"hover":
				bg = color.lightened(0.08)
		b.add_theme_stylebox_override(state,
			style_solid(bg, diameter / 2, lift, 6))
	_ink_text(b)
	_gloss(b, 16)
	return b

## Pastki qatordagi tugma: ustida belgi, tagida nomi.
##
## Belgi tugmaning **bolasi** bo'lib qo'shiladi — Button matndan
## boshqa bolani joylashtirmaydi, shuning uchun ustiga qo'yiladi
## va sichqonchani o'tkazib yuboradi.
static func tab_button(icon: String, text: String,
		tint: Color = YELLOW) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 76)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var bg := PANEL.lightened(0.1) if state == "hover" else PANEL
		b.add_theme_stylebox_override(state,
			style_solid(bg, 18, 2 if state == "pressed" else 5, 4))
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark := GameIcon.new(icon, 28.0, tint)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(mark)
	box.add_child(label(text, 12, TEXT))
	b.add_child(box)
	return b

## Dumaloq tugma (orqaga, pauza, sozlama).
static func icon_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(68, 68)
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_font_override("font", ThemeDB.fallback_font)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var bg := PANEL.lightened(0.08) if state == "hover" else PANEL
		var box := style_solid(bg, 34, 2 if state == "pressed" else 5, 4)
		b.add_theme_stylebox_override(state, box)
	_ink_text(b)
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
		width: int = 0) -> PanelContainer:
	var shell := PanelContainer.new()
	shell.add_theme_stylebox_override("panel", style(TEXT, 24, OUTLINE, 5))
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	shell.add_child(row)
	row.add_child(GameIcon.new(icon, 38.0, tint))

	var text := title(value, 22, INK, HORIZONTAL_ALIGNMENT_CENTER)
	text.add_theme_constant_override("outline_size", 0)
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if width > 0:
		text.custom_minimum_size = Vector2(width, 0)
	row.add_child(text)
	return shell

## Keng progress chizig'i — egallangan foiz.
##
## Oxiridagi yulduz 100% belgisi; `mark` — eng yaxshi natija
## (uchburchak bilan belgilanadi), manfiy bo'lsa chizilmaydi.
static func progress_bar(percent: float, tint: Color,
		mark: float = -1.0) -> Control:
	var shell := PanelContainer.new()
	shell.add_theme_stylebox_override("panel", style(PANEL.darkened(0.25),
		20, OUTLINE, 5))
	shell.custom_minimum_size = Vector2(0, 52)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var lane := Control.new()
	lane.clip_contents = true
	shell.add_child(lane)

	var fill := Panel.new()
	fill.name = "Fill"
	fill.add_theme_stylebox_override("panel", style(tint, 15, 0, 0))
	fill.anchor_bottom = 1.0
	fill.anchor_right = clampf(percent / 100.0, 0.02, 1.0)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lane.add_child(fill)

	var text := title("%d%%" % int(round(percent)), 22, TEXT,
		HORIZONTAL_ALIGNMENT_LEFT)
	text.name = "Value"
	text.set_anchors_preset(Control.PRESET_FULL_RECT)
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.position = Vector2(14, 0)
	lane.add_child(text)
	if mark >= 0.0:
		var best := label("▲", 12, YELLOW)
		best.anchor_left = clampf(mark / 100.0, 0.0, 1.0)
		best.anchor_top = 1.0
		best.position = Vector2(-6, -6)
		lane.add_child(best)
	return shell

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
static func centered_column(root: Control, max_width: int = 460) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
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
