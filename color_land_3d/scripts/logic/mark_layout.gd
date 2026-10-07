class_name MarkLayout
extends RefCounted

## Hudud ustiga avatar (bayroq) naqshini qanday joylashni hisoblaydi.
##
## Flutter variantidagi naqsh bilan bir xil g'oya: belgilar hududning
## hamma yeriga takrorlanadi, lekin faqat o'sha o'yinchiga tegishli
## kataklar ustiga tushadi — shuning uchun naqsh chetdan chiqmaydi.
##
## Bu sof mantiq (chizish yo'q), shuning uchun headless testdan o'tadi.

## Qadam chegaralari (katak hisobida): belgi juda mayda ham, juda yirik
## ham bo'lmasin.
const MIN_STEP := 5.0
const MAX_STEP := 18.0

## Bitta o'yinchiga tushadigan belgilar soni chegarasi.
const MAX_PER_PLAYER := 30

## Belgi atrofidagi tekshiruv nuqtalari qadamning shu ulushida turadi.
const PROBE := 0.22

## Natija: {"step": float, "points": PackedVector2Array}.
## Nuqtalar — katak markazlari (dunyo koordinatalari).
static func plan(grid: GameGrid, id: int,
		limit: int = MAX_PER_PLAYER) -> Dictionary:
	var empty := {"step": 0.0, "points": PackedVector2Array()}
	var b := grid.bounds_of(id)
	if b.is_empty() or limit <= 0:
		return empty

	var w := float(b[2] - b[0] + 1)
	var h := float(b[3] - b[1] + 1)
	var step := clampf(minf(w, h) / 4.0, MIN_STEP, MAX_STEP)

	# To'r hudud ichiga markazlab joylashtiriladi: qatorlar va ustunlar
	# soni oldin hisoblanadi, keyin oraliq shu songa teng bo'linadi —
	# shunda naqsh hududning bir chetida to'planib qolmaydi.
	var cols: int = maxi(1, int(round(w / step)))
	var rows: int = maxi(1, int(round(h / step)))
	var gap_x := w / float(cols)
	var gap_y := h / float(rows)

	# Hududning o'zi ichida qolgan ("kuchli") va faqat markazi mos
	# kelgan ("bo'sh") nuqtalar alohida yig'iladi: kichik hududda
	# birinchisi topilmasa, ikkinchisidan bittasi olinadi.
	var strong := PackedVector2Array()
	var weak := PackedVector2Array()
	var probe := step * PROBE

	for row in rows:
		var y := float(b[1]) + gap_y * (row + 0.5)
		# Toq qatorlar yarim oraliqqa suriladi — naqsh jonliroq
		# ko'rinadi; chetga chiqib ketmasligi uchun bitta ustun kam.
		var shifted: bool = row % 2 == 1 and cols > 1
		var count: int = cols - 1 if shifted else cols
		for col in count:
			var x := float(b[0]) + gap_x * (col + 0.5) \
				+ (gap_x * 0.5 if shifted else 0.0)
			if not _owned(grid, id, x, y):
				continue
			if _owned(grid, id, x - probe, y) \
					and _owned(grid, id, x + probe, y) \
					and _owned(grid, id, x, y - probe) \
					and _owned(grid, id, x, y + probe):
				strong.append(Vector2(x, y))
			else:
				weak.append(Vector2(x, y))

	var points := strong if not strong.is_empty() else weak.slice(0, 1)
	return {"step": step, "points": _thin(points, limit)}

static func _owned(grid: GameGrid, id: int, x: float, y: float) -> bool:
	var cx := int(floor(x))
	var cy := int(floor(y))
	if not grid.contains(cx, cy):
		return false
	return grid.owner_at(cx, cy) == id

## Chegaradan oshgan nuqtalarni teng oraliqda qisqartiradi — naqsh bir
## joyda to'planib qolmasin.
static func _thin(points: PackedVector2Array,
		limit: int) -> PackedVector2Array:
	if points.size() <= limit:
		return points
	var out := PackedVector2Array()
	var stride := float(points.size()) / float(limit)
	for i in limit:
		out.append(points[int(i * stride)])
	return out
