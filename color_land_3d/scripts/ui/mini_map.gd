class_name MiniMap
extends Control

## HUD dagi kichik xarita.
##
## Alohida rasm chizilmaydi: arena ustidagi egalik teksturasining o'zi
## kichraytirib ko'rsatiladi — har katak bitta piksel, shuning uchun
## xarita hech qanday qo'shimcha hisobsiz doim yangi turadi.

## Kichik xarita kengligi (piksel).
const WIDTH := 168.0

## O'yinchi nuqtasining o'lchami.
const DOT := 3.4

var map_texture: Texture2D:
	set(value):
		map_texture = value
		_resize()
		queue_redraw()

## O'yinchi joyi — 0..1 oralig'ida.
var marker := Vector2.ZERO:
	set(value):
		marker = value
		queue_redraw()

var marker_color := Color.WHITE:
	set(value):
		marker_color = value
		queue_redraw()

func _init(texture: Texture2D = null, color: Color = Color.WHITE) -> void:
	# NEAREST: kataklar aniq ko'rinsin, ranglar aralashib ketmasin.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker_color = color
	map_texture = texture

func _resize() -> void:
	if map_texture == null:
		custom_minimum_size = Vector2.ZERO
		return
	var size := map_texture.get_size()
	if size.x <= 0.0:
		return
	custom_minimum_size = Vector2(WIDTH, round(WIDTH * size.y / size.x))

func _draw() -> void:
	if map_texture == null:
		return
	var rect := Rect2(Vector2.ZERO, size)
	draw_texture_rect(map_texture, rect, false)
	draw_rect(rect, UiKit.STROKE, false, 1.0)
	var at := Vector2(marker.x * size.x, marker.y * size.y)
	# Oq halqa ichida o'yinchi rangi — qaysi fonda ham ko'rinadi.
	draw_circle(at, DOT + 1.4, Color(1.0, 1.0, 1.0, 0.9))
	draw_circle(at, DOT, marker_color)
