class_name PickupField
extends RefCounted

## Xaritada tarqalgan **olinadigan** narsalar: tanga va sferalar.
##
## Shaharlardagi tangadan farqi: bular ustidan yurib olinadi.
## Shahar tangasi hudud egallaganda olinadi ([CoinField]) —
## ikkalasi bir-birini to'ldiradi: shahar katta mukofot beradi,
## yo'ldagi tanga esa harakatni qiziqarli qiladi.
##
## Sof mantiq — Godot tugunlariga bog'liq emas, headless testdan
## o'tadi. Chizish `render/pickup_marks.gd` da.

enum Kind { COIN, SHIELD, DASH }

## Olingan narsa shuncha soniyadan keyin boshqa joyda qayta
## paydo bo'ladi.
const RESPAWN := 12.0
## Sferalarning ulushi: har sakkizinchisi kuchaytirgich.
const SPHERE_EVERY := 8

## [{x, y, kind, taken}]
var items: Array = []

var _grid: GameGrid
var _rng := RandomNumberGenerator.new()
var _clock := 0.0
## Qaytishini kutayotganlar: [{index, at}] — vaqt bo'yicha
## tartiblangan, chunki kutish muddati hammasida bir xil.
var _waiting: Array = []
var _returned := PackedInt32Array()
var _taken_now := PackedInt32Array()

## `count` — xaritada bir vaqtda turadigan narsalar soni.
func build(grid: GameGrid, count: int, seed_value: int = 0) -> void:
	_grid = grid
	_rng.seed = seed_value if seed_value != 0 else 20260101
	_clock = 0.0
	items.clear()
	_waiting.clear()
	_returned.clear()
	_taken_now.clear()
	for i in count:
		var kind := Kind.COIN
		if i % SPHERE_EVERY == SPHERE_EVERY - 1:
			kind = Kind.SHIELD if i % (SPHERE_EVERY * 2) == SPHERE_EVERY - 1 \
				else Kind.DASH
		var spot := _free_spot()
		items.append({
			"x": spot.x, "y": spot.y, "kind": kind, "taken": false,
		})

## Tasodifiy o'ynaladigan katak. Topilmasa xaritaning o'rtasi.
func _free_spot() -> Vector2:
	for _try in 40:
		var x := _rng.randi_range(1, _grid.width - 2)
		var y := _rng.randi_range(1, _grid.height - 2)
		if _grid.playable(x, y):
			return Vector2(x + 0.5, y + 0.5)
	return Vector2(_grid.width * 0.5, _grid.height * 0.5)

func size() -> int:
	return items.size()

## Shu nuqtadan `radius` katak ichidagi narsalarni oladi.
##
## Natija — olingan narsalarning turlari ro'yxati; indekslarini
## [method flush_taken] beradi.
func take_near(x: float, y: float, radius: float) -> Array:
	return take_along(x, y, x, y, radius)

## Bir kadrda o'tilgan **kesma** bo'ylab oladi.
##
## Faqat oxirgi nuqtani tekshirish yetmaydi: kadr uzun bo'lsa
## (yoki tezlik kuchaytirgichi ishlayotgan bo'lsa) o'yinchi bir
## kadrda ikki katak o'tadi va tanganing ustidan sakrab o'tib
## ketardi.
func take_along(x0: float, y0: float, x1: float, y1: float,
		radius: float) -> Array:
	var got: Array = []
	var r2 := radius * radius
	var dx := x1 - x0
	var dy := y1 - y0
	var len2 := dx * dx + dy * dy
	for i in items.size():
		var item: Dictionary = items[i]
		if item["taken"]:
			continue
		var ix: float = float(item["x"])
		var iy: float = float(item["y"])
		# Kesmaga eng yaqin nuqtadagi masofa.
		var t := 0.0
		if len2 > 0.0:
			t = clampf(((ix - x0) * dx + (iy - y0) * dy) / len2, 0.0, 1.0)
		var ox := ix - (x0 + dx * t)
		var oy := iy - (y0 + dy * t)
		if ox * ox + oy * oy > r2:
			continue
		item["taken"] = true
		got.append(int(item["kind"]))
		_taken_now.append(i)
		_waiting.append({"index": i, "at": _clock + RESPAWN})
	return got

## Soatni suradi; muddati yetganlar **boshqa joyda** qayta paydo
## bo'ladi, shuning uchun xarita bir xil bo'lib qolmaydi.
func advance(delta: float) -> PackedInt32Array:
	_clock += delta
	_returned.clear()
	while not _waiting.is_empty() \
			and float((_waiting[0] as Dictionary)["at"]) <= _clock:
		var row: Dictionary = _waiting.pop_front()
		var index := int(row["index"])
		var item: Dictionary = items[index]
		var spot := _free_spot()
		item["x"] = spot.x
		item["y"] = spot.y
		item["taken"] = false
		_returned.append(index)
	return _returned

## Oxirgi chaqiriqdan beri olinganlar indeksi.
func flush_taken() -> PackedInt32Array:
	var out := _taken_now.duplicate()
	_taken_now.clear()
	return out

func taken_count() -> int:
	var count := 0
	for item: Dictionary in items:
		if item["taken"]:
			count += 1
	return count
