class_name GameIcon
extends Control

## O'yin belgilari — rasm fayli emas, kod bilan chiziladi.
##
## Emoji shriftidan voz kechildi: rangli emoji o'lchamga yomon
## moslashadi, rangini o'zgartirib bo'lmaydi va u boshqa
## mahsulotning belgisi. Bu yerdagilar o'ziniki va istalgan
## o'lchamda toza chiqadi.
##
## Uslub butun o'yindagidek: to'q ko'k kontur, ichida yorqin rang.

enum Kind { SKULL, COIN, GEM, STAR, CROWN, TICKET }

const NAMES := {
	"skull": Kind.SKULL, "coin": Kind.COIN, "gem": Kind.GEM,
	"star": Kind.STAR, "crown": Kind.CROWN, "ticket": Kind.TICKET,
}

var kind: Kind = Kind.COIN
var tint: Color = UiKit.YELLOW

func _init(p_kind: String = "coin", p_size: float = 32.0,
		p_tint: Color = UiKit.YELLOW) -> void:
	kind = NAMES.get(p_kind, Kind.COIN)
	tint = p_tint
	custom_minimum_size = Vector2(p_size, p_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var span: float = minf(size.x, size.y)
	draw_set_transform(size * 0.5 - Vector2(span, span) * 0.5,
		0.0, Vector2(span, span))
	match kind:
		Kind.SKULL: _skull()
		Kind.GEM: _gem()
		Kind.STAR: _star()
		Kind.CROWN: _crown()
		Kind.TICKET: _ticket()
		_: _coin()

## Hamma belgi 0..1 kvadratida chiziladi, shuning uchun qalinlik
## ham shu o'lchamda beriladi.
const LINE := 0.075

func _coin() -> void:
	draw_circle(Vector2(0.5, 0.5), 0.46, UiKit.INK)
	draw_circle(Vector2(0.5, 0.5), 0.46 - LINE, tint)
	draw_arc(Vector2(0.5, 0.5), 0.29, 0.0, TAU, 24,
		tint.darkened(0.3), LINE * 0.8)
	# Markazdagi romb — tangani boshqa dumaloq belgidan ajratadi.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.5, 0.33), Vector2(0.64, 0.5),
		Vector2(0.5, 0.67), Vector2(0.36, 0.5)]), tint.darkened(0.3))

func _skull() -> void:
	draw_circle(Vector2(0.5, 0.43), 0.42, UiKit.INK)
	draw_rect(Rect2(0.3, 0.6, 0.4, 0.3), UiKit.INK, true)
	draw_circle(Vector2(0.5, 0.43), 0.42 - LINE, tint)
	draw_rect(Rect2(0.3 + LINE, 0.6, 0.4 - LINE * 2.0, 0.26 - LINE), tint,
		true)
	# Ko'z va burun.
	draw_circle(Vector2(0.36, 0.42), 0.12, UiKit.INK)
	draw_circle(Vector2(0.64, 0.42), 0.12, UiKit.INK)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.5, 0.52), Vector2(0.57, 0.64), Vector2(0.43, 0.64)]),
		UiKit.INK)
	# Tishlar orasidagi tirqishlar.
	for x: float in [0.44, 0.56]:
		draw_rect(Rect2(x - 0.02, 0.72, 0.04, 0.14), UiKit.INK, true)

func _gem() -> void:
	var points := PackedVector2Array()
	for i in 6:
		var a := TAU * (float(i) / 6.0) - PI * 0.5
		points.append(Vector2(0.5, 0.5) + Vector2(cos(a), sin(a)) * 0.46)
	draw_colored_polygon(points, UiKit.INK)
	var inner := PackedVector2Array()
	for i in 6:
		var a := TAU * (float(i) / 6.0) - PI * 0.5
		inner.append(Vector2(0.5, 0.5)
			+ Vector2(cos(a), sin(a)) * (0.46 - LINE))
	draw_colored_polygon(inner, tint)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.5, 0.1), Vector2(0.74, 0.3), Vector2(0.5, 0.42)]),
		tint.lightened(0.35))

func _star() -> void:
	draw_colored_polygon(_star_points(0.48, 0.2), UiKit.INK)
	draw_colored_polygon(_star_points(0.48 - LINE, 0.2 - LINE * 0.4), tint)

static func _star_points(outer: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var a := TAU * (float(i) / 10.0) - PI * 0.5
		var r := outer if i % 2 == 0 else inner
		points.append(Vector2(0.5, 0.5) + Vector2(cos(a), sin(a)) * r)
	return points

func _crown() -> void:
	var shape := PackedVector2Array([
		Vector2(0.08, 0.78), Vector2(0.08, 0.26), Vector2(0.29, 0.48),
		Vector2(0.5, 0.18), Vector2(0.71, 0.48), Vector2(0.92, 0.26),
		Vector2(0.92, 0.78)])
	draw_colored_polygon(shape, UiKit.INK)
	var inner := PackedVector2Array()
	for v: Vector2 in shape:
		inner.append(Vector2(0.5, 0.52) + (v - Vector2(0.5, 0.52)) * 0.82)
	draw_colored_polygon(inner, tint)

func _ticket() -> void:
	draw_rect(Rect2(0.06, 0.24, 0.88, 0.52), UiKit.INK, true)
	draw_rect(Rect2(0.06 + LINE, 0.24 + LINE,
		0.88 - LINE * 2.0, 0.52 - LINE * 2.0), tint, true)
	# Chetidagi ikki o'yiq — chipta shaklini beradi.
	for x: float in [0.06, 0.94]:
		draw_circle(Vector2(x, 0.5), 0.1, UiKit.INK)
