class_name CosmeticView
extends Control

## Do'kondagi elementning kichik ko'rinishi.
##
## Ro'yxatda faqat nom turgan edi — "Frost" bilan "Prism" nimasi
## bilan farq qilishini bilib bo'lmasdi. Shu tugun elementni
## o'yinchining **o'z rangida** chizadi, shuning uchun sotib
## olishdan oldin nima olinayotgani ko'rinadi.
##
## Chizish `_draw` da: rasm fayli ham, 3D sahna ham kerak emas.

var category: String = ShopManager.SKINS
var item_id: String = ""
var tint: Color = Color.WHITE

func _init(p_category: String = ShopManager.SKINS, p_item: String = "",
		p_tint: Color = Color.WHITE, p_size: float = 54.0) -> void:
	category = p_category
	item_id = p_item
	tint = p_tint
	custom_minimum_size = Vector2(p_size, p_size)

func _draw() -> void:
	var box := Vector2(size.x, size.y)
	var mid := box * 0.5
	# Orqa fon — har qanday rang ostida bir xil ko'rinsin.
	draw_rect(Rect2(Vector2.ZERO, box), UiKit.SURFACE, true)
	match category:
		ShopManager.SKINS: _draw_skin(mid, minf(box.x, box.y))
		ShopManager.TRAILS: _draw_trail(box)
		ShopManager.EFFECTS: _draw_effect(mid, minf(box.x, box.y))
		_: _draw_special(mid, minf(box.x, box.y))

## Shar: porlashi tashqi halqa bilan, metall esa pastki soya va
## ustki yorug' dog' bilan ko'rsatiladi.
func _draw_skin(mid: Vector2, span: float) -> void:
	var look := Cosmetics.skin(item_id)
	var ball := Cosmetics.skin_color(tint, look)
	var r := span * 0.34
	var glow := float(look["glow"])
	if glow > 0.0:
		# Nur ikki qatlam: ichkarisi quyuqroq, tashqarisi suyuqroq.
		draw_circle(mid, r * 1.55, Color(ball.r, ball.g, ball.b,
			0.14 * minf(glow, 1.3)))
		draw_circle(mid, r * 1.24, Color(ball.r, ball.g, ball.b,
			0.26 * minf(glow, 1.3)))
	draw_circle(mid, r, ball)
	var metal := float(look["metal"])
	if metal > 0.0:
		# Yaltiroq yuza: pastdan to'q, ustdan ochiq.
		draw_circle(mid + Vector2(0.0, r * 0.40), r * 0.66,
			ball.darkened(0.5 * metal))
		draw_arc(mid, r * 0.86, PI * 1.15, PI * 1.75, 16,
			Color(1, 1, 1, 0.55 * metal), maxf(1.5, r * 0.12))
	draw_circle(mid - Vector2(r * 0.32, r * 0.36), r * 0.22,
		Color(1, 1, 1, 0.32 + 0.45 * metal))

## Iz: to'lqinli chiziq, rangi bo'ylab o'zgaradi.
func _draw_trail(box: Vector2) -> void:
	var look := Cosmetics.trail(item_id)
	var base := tint.lightened(0.3)
	var steps := 14
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for i in steps + 1:
		var t := float(i) / float(steps)
		points.append(Vector2(box.x * (0.12 + 0.76 * t),
			box.y * (0.5 + 0.22 * sin(t * TAU))))
		colors.append(Cosmetics.trail_color(base, look, t))
	draw_polyline_colors(points, colors, box.y * 0.16)

## Effekt: markazdan otilgan nuqtalar yoki halqa.
func _draw_effect(mid: Vector2, span: float) -> void:
	var look := Cosmetics.effect(item_id)
	if int(look["count"]) == 0:
		draw_arc(mid, span * 0.26, 0.0, TAU, 24, UiKit.TEXT_FAINT, 2.0)
		return
	var ring := bool(look["ring"])
	var dots := 9
	for i in dots:
		var a := TAU * float(i) / float(dots)
		var far := span * (0.34 if ring else (0.16 + 0.2 * fposmod(i * 0.37, 1.0)))
		var at := mid + Vector2(cos(a), sin(a)) * far
		draw_circle(at, span * (0.045 if ring else 0.06), tint.lightened(0.25))
	if ring:
		draw_arc(mid, span * 0.34, 0.0, TAU, 28,
			Color(tint.r, tint.g, tint.b, 0.45), 1.5)

## Maxsus nishon: halqa va uning ichida yulduzcha.
func _draw_special(mid: Vector2, span: float) -> void:
	var halo := Cosmetics.halo(item_id)
	if halo.a <= 0.0:
		halo = UiKit.TEXT_FAINT
	draw_arc(mid, span * 0.3, 0.0, TAU, 28, halo, 3.0)
	draw_circle(mid, span * 0.14, tint)
