class_name HeroView
extends Control

## Qahramon (personaj) kartasi va uning shakli.
##
## Rasmlardagi (10 va 11-skrinshotlar) kabi 3 ustunli panjaraga mos:
## - Ochilgan bo'lsa: qahramonning 3D-uslubidagi shakli, tanlanganda yashil tasdiq.
## - Qulflangan bo'lsa: qulf belgisi, shart matni va yashil to'lish chizig'i (x/y).

var hero: Dictionary = {}
var is_unlocked: bool = false
var is_selected: bool = false
var progress: int = 0
var target: int = 0

func _init(p_hero: Dictionary, p_unlocked: bool, p_selected: bool,
		p_progress: int = 0, p_target: int = 0) -> void:
	hero = p_hero
	is_unlocked = p_unlocked
	is_selected = p_selected
	progress = p_progress
	target = p_target
	custom_minimum_size = Vector2(104, 138)
	mouse_filter = Control.MOUSE_FILTER_PASS

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	
	if is_unlocked:
		_draw_unlocked(rect)
	else:
		_draw_locked(rect)

func _draw_unlocked(rect: Rect2) -> void:
	# Fon — och ko'k / oq yuzali panel
	var bg_color := UiKit.SURFACE
	var border_color := UiKit.MINT if is_selected else UiKit.INK
	var border_w: float = 4.0 if is_selected else 2.0
	
	# Poydevor va panel
	draw_rect(rect, border_color, true)
	var inner := rect.grow(-border_w)
	draw_rect(inner, bg_color, true)
	
	# Qahramon shakli
	var center := Vector2(size.x * 0.5, size.y * 0.46)
	var color: Color = hero.get("color", Color("ffd23f"))
	var id: String = str(hero.get("id", "hero_cube"))
	_draw_hero_shape(id, center, color)
	
	# Tanlangan bo'lsa — pastki o'ng burchakda yashil tasdiq (check) belgisi
	if is_selected:
		var check_pos := Vector2(size.x - 22, size.y - 22)
		draw_circle(check_pos, 12, UiKit.MINT)
		draw_circle(check_pos, 10, UiKit.MINT.lightened(0.2))
		# Tasdiq chizig'i
		var pts := PackedVector2Array([
			check_pos + Vector2(-5, 0),
			check_pos + Vector2(-1, 4),
			check_pos + Vector2(5, -4)
		])
		draw_polyline(pts, UiKit.INK, 2.5)

func _draw_locked(rect: Rect2) -> void:
	# Qulflangan karta foni — chuqur to'q ko'k
	draw_rect(rect, UiKit.INK, true)
	var inner := rect.grow(-2.0)
	draw_rect(inner, Color("1a2a52"), true)
	
	# Qulf belgisi
	var lock_center := Vector2(size.x * 0.5, 52)
	# Qulf kamari
	draw_arc(lock_center + Vector2(0, -6), 11, PI, TAU, 16, UiKit.INK, 4.0)
	draw_arc(lock_center + Vector2(0, -6), 11, PI, TAU, 16, Color("e0e6ed"), 2.2)
	# Qulf to'rtburchagi
	draw_rect(Rect2(lock_center.x - 14, lock_center.y - 6, 28, 22), UiKit.INK, true)
	draw_rect(Rect2(lock_center.x - 12, lock_center.y - 4, 24, 18), Color("8c9cb8"), true)
	draw_circle(lock_center + Vector2(0, 4), 3, UiKit.INK)
	
	# Progress bar pastda
	if target > 0:
		var bar_rect := Rect2(12, size.y - 24, size.x - 24, 12)
		# Bar foni
		draw_rect(bar_rect, UiKit.INK, true)
		draw_rect(bar_rect.grow(-1.5), Color("0d1730"), true)
		# To'lish qismi
		var ratio := clampf(float(progress) / float(target), 0.0, 1.0)
		if ratio > 0.0:
			var fill_rect := Rect2(bar_rect.position + Vector2(1.5, 1.5),
				Vector2((bar_rect.size.x - 3.0) * ratio, bar_rect.size.y - 3.0))
			draw_rect(fill_rect, UiKit.MINT, true)

func _draw_hero_shape(id: String, center: Vector2, color: Color) -> void:
	match id:
		"hero_melon":
			# Tarvuz bo'lagi
			var melon := PackedVector2Array([
				center + Vector2(-28, 12),
				center + Vector2(28, 12),
				center + Vector2(0, -26)
			])
			# Yashil po'choq
			draw_line(center + Vector2(-30, 14), center + Vector2(30, 14), Color("2f7d32"), 5.0)
			# Qizil ichi
			draw_colored_polygon(melon, color)
			# Urug'lar
			draw_circle(center + Vector2(-8, 2), 2.0, UiKit.INK)
			draw_circle(center + Vector2(8, 2), 2.0, UiKit.INK)
			draw_circle(center + Vector2(0, -10), 2.0, UiKit.INK)
		_:
			# Izometrik kub
			var s: float = 24.0
			# Ustki tomon
			var top := PackedVector2Array([
				center + Vector2(0, -s * 0.9),
				center + Vector2(s * 0.9, -s * 0.45),
				center + Vector2(0, 0),
				center + Vector2(-s * 0.9, -s * 0.45)
			])
			# Chap tomon
			var left := PackedVector2Array([
				center + Vector2(-s * 0.9, -s * 0.45),
				center + Vector2(0, 0),
				center + Vector2(0, s * 0.9),
				center + Vector2(-s * 0.9, s * 0.45)
			])
			# O'ng tomon
			var right := PackedVector2Array([
				center + Vector2(0, 0),
				center + Vector2(s * 0.9, -s * 0.45),
				center + Vector2(s * 0.9, s * 0.45),
				center + Vector2(0, s * 0.9)
			])
			draw_colored_polygon(top, color.lightened(0.2))
			draw_colored_polygon(left, color.darkened(0.2))
			draw_colored_polygon(right, color)
			# Kontur
			draw_polyline(top, UiKit.INK, 1.8)
			draw_polyline(left, UiKit.INK, 1.8)
			draw_polyline(right, UiKit.INK, 1.8)
