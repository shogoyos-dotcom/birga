class_name DonutProgress
extends Control

## Dumaloq hudud ko'rsatkichi (Donut Chart) — foiz va "Your Territory" yorlig'i.
##
## Ekranning yuqori chap burchagida turadi va o'yinchining
## real vaqtda egallagan hududi foizini chiroyli multfilm uslubida ko'rsatadi.

var percent: float = 0.0:
	set(value):
		percent = clampf(value, 0.0, 100.0)
		_update_labels()
		queue_redraw()

var tint: Color = UiKit.YELLOW:
	set(value):
		tint = value
		queue_redraw()

var _value_label: Label
var _sub_label: Label

const RADIUS := 44.0
const THICKNESS := 11.0
const OUTLINE_THICK := 3.5

func _init(p_percent: float = 0.0, p_tint: Color = UiKit.YELLOW) -> void:
	custom_minimum_size = Vector2(136, 142)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint = p_tint
	percent = p_percent

	_value_label = Label.new()
	_value_label.text = "%d%%" % int(round(percent))
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_value_label.add_theme_font_size_override("font_size", 25)
	var font := UiKit.display_font()
	if font != null:
		_value_label.add_theme_font_override("font", font)
	_value_label.add_theme_color_override("font_color", UiKit.TEXT)
	_value_label.add_theme_constant_override("outline_size", 7)
	_value_label.add_theme_color_override("font_outline_color", UiKit.INK)
	_value_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_value_label.offset_top = 35
	_value_label.offset_bottom = 69
	_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_value_label)

	_sub_label = Label.new()
	_sub_label.text = Strings.t("yourTerritory")
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sub_label.add_theme_font_size_override("font_size", 12)
	if font != null:
		_sub_label.add_theme_font_override("font", font)
	_sub_label.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	_sub_label.add_theme_constant_override("outline_size", 4)
	_sub_label.add_theme_color_override("font_outline_color", UiKit.INK)
	_sub_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_sub_label.offset_top = -24
	_sub_label.offset_bottom = 0
	_sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sub_label)

func _update_labels() -> void:
	if _value_label != null:
		_value_label.text = "%d%%" % int(round(percent))

func _draw() -> void:
	var center := Vector2(size.x * 0.5, 52.0)
	# 3D taglik soyasi
	draw_circle(center + Vector2(0, 4), RADIUS + OUTLINE_THICK + 2.0, Color(0.04, 0.08, 0.22, 0.45))
	# Tashqi kontur
	draw_arc(center, RADIUS + OUTLINE_THICK, 0.0, TAU, 36, UiKit.INK, OUTLINE_THICK)
	# Ichki quyuq fon doirasi
	draw_circle(center, RADIUS, Color(0.08, 0.16, 0.35, 0.90))
	# Doira orqa yo'lchasi (bo'sh halqa)
	draw_arc(center, RADIUS - THICKNESS * 0.5, 0.0, TAU, 36, Color(0.12, 0.24, 0.48, 0.75), THICKNESS)
	# Ichki chegara konturi
	draw_arc(center, RADIUS - THICKNESS, 0.0, TAU, 36, UiKit.INK, OUTLINE_THICK * 0.8)

	# To'lish halqasi: tepadan (-PI/2) soat yo'nalishida
	var frac := clampf(percent / 100.0, 0.0, 1.0)
	if frac > 0.005:
		var start_angle := -PI * 0.5
		var sweep := frac * TAU
		draw_arc(center, RADIUS - THICKNESS * 0.5, start_angle, start_angle + sweep, 36, tint, THICKNESS)
		# Boshlanish va tugash silliq dumaloqlari
		var start_pos := center + Vector2(cos(start_angle), sin(start_angle)) * (RADIUS - THICKNESS * 0.5)
		draw_circle(start_pos, THICKNESS * 0.5, tint.lightened(0.2))
		var end_angle := start_angle + sweep
		var end_pos := center + Vector2(cos(end_angle), sin(end_angle)) * (RADIUS - THICKNESS * 0.5)
		draw_circle(end_pos, THICKNESS * 0.5, tint.lightened(0.35))
