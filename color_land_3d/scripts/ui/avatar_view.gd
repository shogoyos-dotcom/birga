class_name AvatarView
extends Control

## Avatarni ko'rsatadi: emoji va bayroqlar shriftdan, odam tasvirlari
## esa shakllardan chiziladi (rasm fayli kerak emas).

const SKINS: PackedColorArray = [
	Color("f2c79b"), Color("e0a878"), Color("c68642"),
	Color("8d5524"), Color("5c3a21"), Color("ffe0bd"),
]
const SHIRTS: PackedColorArray = [
	Color("2e7bff"), Color("ff4d6d"), Color("14c38e"),
	Color("ffa62b"), Color("9b5de5"), Color("00c2d1"),
]
const HAIRS: PackedColorArray = [
	Color("2b2118"), Color("55331a"), Color("8c5a2b"),
	Color("d9a441"), Color("9e9e9e"), Color("3b2b5a"),
]

var avatar: String = "figure:0":
	set(value):
		avatar = value
		_refresh()

var _label: Label

func _init(p_avatar: String = "figure:0", size: float = 44.0) -> void:
	custom_minimum_size = Vector2(size, size)
	avatar = p_avatar

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	if not is_inside_tree():
		return
	var glyph := Profile.glyph(avatar)
	if glyph.is_empty():
		if _label != null:
			_label.visible = false
		queue_redraw()
		return
	if _label == null:
		_label = Label.new()
		_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Emoji shrifti bevosita qo'yiladi — bayroq ligaturasi
		# zaxira shrift orqali hosil bo'lmaydi.
		var font := UiKit.emoji_font()
		if font != null:
			_label.add_theme_font_override("font", font)
		add_child(_label)
	_label.visible = true
	_label.text = glyph
	_label.add_theme_font_size_override(
		"font_size", int(custom_minimum_size.y * 0.72))
	queue_redraw()

func _draw() -> void:
	if not Profile.glyph(avatar).is_empty():
		return
	_draw_figure(Profile.figure_index(avatar))

## Oddiy odam tasviri: tana, soch, bosh, ko'zlar.
func _draw_figure(index: int) -> void:
	var s := minf(size.x, size.y)
	if s <= 0.0:
		s = custom_minimum_size.y
	var center := Vector2(size.x, size.y) * 0.5
	var skin := SKINS[index % SKINS.size()]
	var shirt := SHIRTS[(index / 2) % SHIRTS.size()]
	var hair := HAIRS[(index / 3) % HAIRS.size()]

	var head_r := s * 0.26
	var head := center + Vector2(0, -s * 0.12)

	# Tana — yelkadan pastga kengayadigan shakl.
	var body := PackedVector2Array([
		center + Vector2(-s * 0.34, s * 0.45),
		center + Vector2(-s * 0.30, s * 0.08),
		center + Vector2(0, s * 0.02),
		center + Vector2(s * 0.30, s * 0.08),
		center + Vector2(s * 0.34, s * 0.45),
	])
	draw_colored_polygon(body, shirt)

	draw_circle(head + Vector2(0, -s * 0.04), head_r * 1.08, hair)
	draw_circle(head, head_r, skin)
	# Peshonadagi soch.
	draw_arc(head, head_r * 0.98, PI, TAU, 18, hair, head_r * 0.42)
	draw_circle(head + Vector2(-head_r * 0.33, head_r * 0.1),
		head_r * 0.12, Color("2b2118"))
	draw_circle(head + Vector2(head_r * 0.33, head_r * 0.1),
		head_r * 0.12, Color("2b2118"))

## Tanlash uchun bosiladigan katakcha.
static func chip(avatar_value: String, selected: bool, on_tap: Callable,
		caption: String = "", accent: Color = UiKit.BLUE) -> Control:
	var button := Button.new()
	button.custom_minimum_size = Vector2(64, 76 if caption.is_empty() else 86)
	button.flat = false
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := UiKit.style(
			accent.lerp(UiKit.SURFACE, 0.78) if selected else UiKit.SURFACE,
			12, 2, 4)
		box.border_color = accent if selected else UiKit.STROKE
		button.add_theme_stylebox_override(state, box)
	button.pressed.connect(on_tap)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(box)

	var view := AvatarView.new(avatar_value, 40.0)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(view)

	if not caption.is_empty():
		var text := UiKit.label(caption, 10, UiKit.TEXT_DIM)
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.clip_text = true
		text.custom_minimum_size = Vector2(60, 0)
		box.add_child(text)
	return button
