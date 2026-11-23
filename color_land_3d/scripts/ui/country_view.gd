class_name CountryView
extends Control

## Mamlakat shakli: pastdan yuqoriga to'lib boradigan konturi.
##
## To'lish darajasi — shu mamlakatda yig'ilgan ochko foizi.
## Shakl `data/country_shapes.json` dan keladi va 0..1 kvadratida
## yotadi, shuning uchun istalgan o'lchamda chiziladi.

## Rangi: to'lmagan qismi xira **och**, to'lgani yorqin.
##
## Avval xira rang to'q ko'k edi — och fonda u "to'lgan"dek
## ko'rinardi va shakl teskari o'qilardi.
const PALE := Color("a9c8e8")
const EDGE := Color("0f2c5e")
const LINE := 3.0

var _rings: Array[PackedVector2Array] = []
var _fill: Array[PackedVector2Array] = []
var _percent := 0.0
var _tint: Color = UiKit.GREEN

func _init(country: Dictionary = {}, box: float = 140.0,
		percent: float = 0.0, tint: Color = UiKit.GREEN) -> void:
	custom_minimum_size = Vector2(box, box)
	_tint = tint
	_percent = clampf(percent, 0.0, 100.0)
	_rings = CountryPath.rings_of(country, box)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## To'lish darajasini o'zgartiradi (animatsiya shu orqali).
func set_percent(value: float) -> void:
	var next := clampf(value, 0.0, 100.0)
	if is_equal_approx(next, _percent):
		return
	_percent = next
	queue_redraw()

func _draw() -> void:
	if _rings.is_empty():
		return
	var span: float = minf(size.x, size.y)
	var box: float = _rings_box()
	if box > 0.0 and not is_equal_approx(box, span):
		# Tugun o'lchami o'zgargan bo'lsa shakl moslanadi.
		draw_set_transform(Vector2.ZERO, 0.0,
			Vector2.ONE * (span / box))
	for ring: PackedVector2Array in _rings:
		draw_colored_polygon(ring, PALE)
	# To'lgan qism: shakl pastdan `_percent` balandlikda kesiladi.
	var top: float = box * (1.0 - _percent / 100.0)
	var window := PackedVector2Array([
		Vector2(-box, top), Vector2(box * 2.0, top),
		Vector2(box * 2.0, box * 2.0), Vector2(-box, box * 2.0)])
	for ring: PackedVector2Array in _rings:
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(
				ring, window):
			draw_colored_polygon(piece, _tint)
	for ring: PackedVector2Array in _rings:
		# Kontur yopiq bo'lsin — oxirgi nuqta birinchisiga ulanadi.
		var closed := ring.duplicate()
		if closed.size() > 1:
			closed.append(closed[0])
		draw_polyline(closed, EDGE, LINE)

## Shakl qaysi kvadratda chizilgan (`_init` dagi `box`).
func _rings_box() -> float:
	var widest := 0.0
	for ring: PackedVector2Array in _rings:
		for p: Vector2 in ring:
			widest = maxf(widest, maxf(p.x, p.y))
	return widest
