class_name MiniMap
extends Control

## HUD dagi kichik xarita — dumaloq radar multfilm uslubida.
##
## Egalik teksturasi dumaloq doira ichida markazlashtirib ko'rsatiladi,
## o'yinchi joylashuvi yorqin oq-rangli nuqta bilan belgilanadi.

const WIDTH := 148.0
const DOT := 4.2

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

## Botlar joyi — [{pos: Vector2, color: Color}]
var bot_markers: Array = []:
	set(value):
		bot_markers = value
		queue_redraw()

func _init(texture: Texture2D = null, color: Color = Color.WHITE) -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker_color = color
	map_texture = texture
	_resize()

func _resize() -> void:
	custom_minimum_size = Vector2(WIDTH, WIDTH)

func _draw() -> void:
	var center := Vector2(WIDTH * 0.5, WIDTH * 0.5)
	var radius := WIDTH * 0.46
	# 3D pastki soya
	draw_circle(center + Vector2(0, 4), radius + 4.0, Color(0.04, 0.08, 0.22, 0.45))
	# Qalin hoshiya konturi (INK)
	draw_circle(center, radius + 3.0, UiKit.INK)
	# Ichki quyuq ko'k fon
	draw_circle(center, radius, Color(0.08, 0.16, 0.35, 0.92))

	if map_texture != null:
		var t_size := map_texture.get_size()
		if t_size.x > 0.0 and t_size.y > 0.0:
			var max_dim := maxf(t_size.x, t_size.y)
			var draw_w := (t_size.x / max_dim) * (radius * 1.62)
			var draw_h := (t_size.y / max_dim) * (radius * 1.62)
			var rect := Rect2(center - Vector2(draw_w * 0.5, draw_h * 0.5), Vector2(draw_w, draw_h))
			draw_texture_rect(map_texture, rect, false)

			# Botlar nuqtalari
			for bm: Dictionary in bot_markers:
				var bpos: Vector2 = bm.get("pos", Vector2.ZERO)
				var bcol: Color = bm.get("color", Color("f43f5e"))
				var bat := rect.position + Vector2(bpos.x * draw_w, bpos.y * draw_h)
				if bat.distance_to(center) <= radius - 2.0:
					draw_circle(bat, DOT * 0.75, bcol)

			# O'yinchi nuqtasi
			var at := rect.position + Vector2(marker.x * draw_w, marker.y * draw_h)
			if at.distance_to(center) <= radius - 2.0:
				draw_circle(at, DOT + 2.0, Color(1.0, 1.0, 1.0, 0.95))
				draw_circle(at, DOT, marker_color)

	# Radar hoshiyasi yaltirashi (yuqoridagi yarim oy)
	draw_arc(center, radius - 1.5, -PI * 0.85, -PI * 0.15, 24, Color(1.0, 1.0, 1.0, 0.40), 2.5)
	# Tashqi kontur
	draw_arc(center, radius, 0.0, TAU, 36, UiKit.INK, 3.2)
