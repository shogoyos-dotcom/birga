class_name AvatarPlacement
extends RefCounted

## Hudud ustidagi avatar qayerda va qanchalik katta chizilishini
## hisoblaydi.
##
## Avatar bitta bo'ladi va butun hududni egallaydi: u hududning
## markaziga qo'yilib, o'lchami hudud kattaligidan olinadi. Hudud
## shakliga mos kesishni arena shaderi bajaradi, shuning uchun bu yerda
## faqat markaz va o'lcham kerak.
##
## Sof mantiq (chizish yo'q) — headless testdan o'tadi.

## Cho'ziq hududda avatar qisqa tomonidan shuncha ulushga kattalashadi.
const SPREAD := 0.45

## Lekin qisqa tomonidan shuncha martadan ortiq emas — aks holda
## ingichka hududda avatarning faqat bir bo'lagi ko'rinib qoladi.
const MAX_STRETCH := 2.2

## Markazni topish uchun hududdan shuncha nuqta olinadi.
const SAMPLES := 400

## Natija: {"center": Vector2, "half": float}. Hudud bo'sh bo'lsa
## `half` nolga teng.
static func of(grid: GameGrid, id: int, country_code: String = "") -> Dictionary:
	var none := {"center": Vector2.ZERO, "half": 0.0, "half_w": 0.0, "half_h": 0.0}
	var b := grid.bounds_of(id)
	if b.is_empty():
		return none

	var w := float(b[2] - b[0] + 1)
	var h := float(b[3] - b[1] + 1)
	var small := minf(w, h)
	var large := maxf(w, h)
	# Doira shaklidagi hududda avatar to'liq sig'adi; cho'ziq hududda
	# biroz kattalashadi va chetlari kesiladi.
	var side := minf(small + (large - small) * SPREAD, small * MAX_STRETCH)

	var stats := _calculate_territory_stats(grid, id, b)
	var center: Vector2 = stats["center"]
	var raw_w: float = stats["span_w"]
	var raw_h: float = stats["span_h"]

	# Milliy bayroqning rasmiy mutanosiblik nisbatini saqlash
	var target_ratio: float = FlagRenderer.get_flag_aspect_ratio(country_code) if not country_code.is_empty() else 1.5
	var span_w := maxf(raw_w, 6.0)
	var span_h := maxf(raw_h, 4.0)
	var ratio := span_w / maxf(span_h, 0.01)
	if ratio < target_ratio * 0.95:
		# Hudud bo'yiga cho'ziq yoki kvadrat bo'lsa: eniga qarab bo'yini moslaymiz
		span_h = span_w / target_ratio
	elif ratio > target_ratio * 1.05:
		# Hudud eniga juda keng bo'lsa: bo'yiga qarab enini moslaymiz
		span_w = span_h * target_ratio

	return {
		"center": center,
		"half": side * 0.5,
		"half_w": span_w,
		"half_h": span_h
	}

## Hududning markazi va o'lchamini hisoblaydi.
## Agar hudud bir nechta ajralgan bo'laklarga (disconnected) bo'linsa,
## dispersiya orqali asosiy massani aniqlaydi va bayroqni butun xaritaga yoyilib ketishidan saqlaydi.
static func _calculate_territory_stats(grid: GameGrid, id: int,
		b: PackedInt32Array) -> Dictionary:
	var w := b[2] - b[0] + 1
	var h := b[3] - b[1] + 1
	var step: int = maxi(1, int(ceil(sqrt(float(w * h) / float(SAMPLES)))))
	var sum := Vector2.ZERO
	var count := 0
	var points: Array[Vector2] = []

	var y := b[1]
	while y <= b[3]:
		var x := b[0]
		while x <= b[2]:
			if grid.owner_at(x, y) == id:
				var pt := Vector2(x + 0.5, y + 0.5)
				sum += pt
				count += 1
				points.append(pt)
			x += step
		y += step

	if count == 0:
		var c := Vector2((b[0] + b[2] + 1) * 0.5, (b[1] + b[3] + 1) * 0.5)
		return {"center": c, "span_w": float(w) * 0.52, "span_h": float(h) * 0.52}

	var center := sum / float(count)

	var var_x := 0.0
	var var_y := 0.0
	for pt in points:
		var dx := pt.x - center.x
		var dy := pt.y - center.y
		var_x += dx * dx
		var_y += dy * dy
	var sigma_x := sqrt(var_x / float(count))
	var sigma_y := sqrt(var_y / float(count))

	# Bog'langan hududda bounds (w * 0.52) ishlatiladi;
	# Ajralgan (disconnected) bo'laklar bo'lsa, dispersiya (sigma * 2.0) asosiy massani o'raydi.
	var span_w := minf(float(w) * 0.52, maxf(float(w) * 0.35, sigma_x * 2.0))
	var span_h := minf(float(h) * 0.52, maxf(float(h) * 0.35, sigma_y * 2.0))

	return {
		"center": center,
		"span_w": span_w,
		"span_h": span_h
	}
