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
static func of(grid: GameGrid, id: int) -> Dictionary:
	var none := {"center": Vector2.ZERO, "half": 0.0}
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

	return {"center": _center(grid, id, b), "half": side * 0.5}

## Hududning o'rtasi. To'rtburchak markazi emas, egallangan kataklarning
## o'rtacha nuqtasi olinadi — "L" shaklidagi hududda to'rtburchak
## markazi hududdan tashqarida qolib ketadi.
static func _center(grid: GameGrid, id: int,
		b: PackedInt32Array) -> Vector2:
	var w := b[2] - b[0] + 1
	var h := b[3] - b[1] + 1
	# Katta hududni to'liq aylanib chiqish shart emas — qadam bilan
	# o'tiladi, markaz baribir deyarli bir xil chiqadi.
	var step: int = maxi(1, int(ceil(sqrt(float(w * h) / float(SAMPLES)))))
	var sum := Vector2.ZERO
	var count := 0
	var y := b[1]
	while y <= b[3]:
		var x := b[0]
		while x <= b[2]:
			if grid.owner_at(x, y) == id:
				sum += Vector2(x + 0.5, y + 0.5)
				count += 1
			x += step
		y += step
	if count == 0:
		return Vector2((b[0] + b[2] + 1) * 0.5, (b[1] + b[3] + 1) * 0.5)
	return sum / float(count)
