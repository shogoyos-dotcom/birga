class_name GameGrid
extends RefCounted

## Mantiqiy panjara. Har katakda egasi (`owner`) va iz egasi (`trail`)
## saqlanadi; 0 — bo'sh, aks holda o'yinchi ID (1..255).
##
## Suv kataklari (`land` niqobi) hech qachon egallanmaydi va harakatga
## to'siq bo'ladi.

var width: int
var height: int
var owner_cells: PackedByteArray
var trail_cells: PackedByteArray
## Quruqlik niqobi; bo'sh bo'lsa butun panjara o'ynaladi.
var land: PackedByteArray
var land_cells: int

## Oxirgi tozalashdan beri o'zgargan kataklar — chizish qatlami faqat
## shularni qayta bo'yaydi (butun xaritani emas).
var dirty_cells := PackedInt32Array()
## Xuddi shunday ro'yxat, lekin tarmoq uchun: chizish qatlami va
## tarmoq bir-biridan mustaqil bo'shatadi.
##
## Yolg'iz o'ynaganda hech kim bo'shatmaydi, shuning uchun u faqat
## tarmoq o'yinida yig'iladi — aks holda ro'yxat cheksiz o'sardi.
var net_tracking := false
var net_dirty := PackedInt32Array()

var _territory: PackedInt32Array
var _version: PackedInt32Array
var _min_x: PackedInt32Array
var _min_y: PackedInt32Array
var _max_x: PackedInt32Array
var _max_y: PackedInt32Array

## Har bir katak uchun suvdan masofa (katak birligida).
## 0 — suv, 1 — sohil quruqligi, 2+ — ichki quruqlik.
var coast_dist: PackedFloat32Array
## Suv kataklari uchun eng yaqin quruqlik katagining indeksi (-1 — yo'q).
## Quruqlik katagi uchun esa o'zining indeksi.
var nearest_land: PackedInt32Array

func _init(p_width: int, p_height: int, p_land: PackedByteArray = PackedByteArray()) -> void:
	assert(p_land.is_empty() or p_land.size() == p_width * p_height,
		"Quruqlik niqobi panjara o'lchamiga mos kelmadi")
	width = p_width
	height = p_height
	land = p_land
	owner_cells = PackedByteArray()
	owner_cells.resize(width * height)
	trail_cells = PackedByteArray()
	trail_cells.resize(width * height)

	land_cells = width * height
	if not land.is_empty():
		land_cells = 0
		for v: int in land:
			land_cells += v

	_territory = PackedInt32Array()
	_territory.resize(256)
	_territory[0] = width * height
	_version = PackedInt32Array()
	_version.resize(256)
	_min_x = PackedInt32Array()
	_min_x.resize(256)
	_min_y = PackedInt32Array()
	_min_y.resize(256)
	_max_x = PackedInt32Array()
	_max_x.resize(256)
	_max_y = PackedInt32Array()
	_max_y.resize(256)
	_reset_bounds()
	_build_distance_field()

func _reset_bounds() -> void:
	for i in 256:
		_min_x[i] = 1 << 30
		_min_y[i] = 1 << 30
		_max_x[i] = -1
		_max_y[i] = -1

func index(x: int, y: int) -> int:
	return y * width + x

func contains(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height

func is_land(x: int, y: int) -> bool:
	if land.is_empty():
		return true
	return land[y * width + x] == 1

func is_land_index(i: int) -> bool:
	return land.is_empty() or land[i] == 1

## Katak o'ynaladigan joyda — panjara ichida va quruqlikda.
func playable(x: int, y: int) -> bool:
	return contains(x, y) and is_land(x, y)

func owner_at(x: int, y: int) -> int:
	return owner_cells[y * width + x]

func trail_at(x: int, y: int) -> int:
	return trail_cells[y * width + x]

func territory_of(id: int) -> int:
	return _territory[id]

## Egallangan maydon foizi — okean hisobga olinmaydi.
func percent_of(id: int) -> float:
	return _territory[id] * 100.0 / float(land_cells)

func version_of(id: int) -> int:
	return _version[id]

## `id` hududini o'rab turgan to'rtburchak [min_x, min_y, max_x, max_y]
## yoki bo'sh massiv.
func bounds_of(id: int) -> PackedInt32Array:
	if _max_x[id] < 0:
		return PackedInt32Array()
	return PackedInt32Array([_min_x[id], _min_y[id], _max_x[id], _max_y[id]])

func set_owner_index(i: int, id: int) -> void:
	var prev: int = owner_cells[i]
	if prev == id:
		return
	_territory[prev] -= 1
	_territory[id] += 1
	owner_cells[i] = id
	dirty_cells.append(i)
	if net_tracking:
		net_dirty.append(i)
	_version[prev] += 1
	_version[id] += 1
	if id != 0:
		var x: int = i % width
		var y: int = i / width
		if x < _min_x[id]: _min_x[id] = x
		if y < _min_y[id]: _min_y[id] = y
		if x > _max_x[id]: _max_x[id] = x
		if y > _max_y[id]: _max_y[id] = y

func set_owner(x: int, y: int, id: int) -> void:
	set_owner_index(index(x, y), id)

func set_trail_index(i: int, id: int) -> void:
	if trail_cells[i] == id:
		return
	trail_cells[i] = id
	dirty_cells.append(i)
	if net_tracking:
		net_dirty.append(i)

func set_trail(x: int, y: int, id: int) -> void:
	set_trail_index(index(x, y), id)

## `id` ning butun hududi va izini bo'shatadi. Bo'shagan kataklarni
## qaytaradi — o'lim animatsiyasi uchun.
## `trail` — o'sha o'yinchining iz kataklari (tartib bilan). U alohida
## beriladi, chunki iz hududdan tashqarida yotadi.
##
## Hudud faqat o'zining to'rtburchagi ichida qidiriladi: butun
## panjarani (100 000 dan ortiq katak) aylanib chiqish o'lim paytida
## sezilarli sakrash berardi.
func clear_player(id: int,
		trail: PackedInt32Array = PackedInt32Array()) -> PackedInt32Array:
	var cleared := PackedInt32Array()
	if id == 0:
		return cleared
	var box := bounds_of(id)
	if not box.is_empty():
		for y in range(box[1], box[3] + 1):
			var row := y * width
			for x in range(box[0], box[2] + 1):
				var i := row + x
				if owner_cells[i] == id:
					cleared.append(i)
					set_owner_index(i, 0)
	clear_trail(id, trail)
	_min_x[id] = 1 << 30
	_min_y[id] = 1 << 30
	_max_x[id] = -1
	_max_y[id] = -1
	return cleared

## `id` ning iz kataklarini bo'shatadi, hududiga tegmaydi.
##
## Qalqon urilishni yutganda shu ishlatiladi: o'yinchi tirik
## qoladi, lekin chizgan izi yo'qoladi.
func clear_trail(id: int, trail: PackedInt32Array) -> void:
	for i: int in trail:
		if trail_cells[i] == id:
			trail_cells[i] = 0
			dirty_cells.append(i)
			if net_tracking:
				net_dirty.append(i)

## Markazi (cx, cy) bo'lgan doirani to'ldiradi. Egallangan katak sonini
## qaytaradi.
func fill_disc(cx: int, cy: int, radius: float, id: int) -> int:
	var r2: float = radius * radius
	var from: int = int(ceil(radius))
	var count := 0
	for dy in range(-from, from + 1):
		for dx in range(-from, from + 1):
			if dx * dx + dy * dy > r2:
				continue
			var x: int = cx + dx
			var y: int = cy + dy
			if not playable(x, y):
				continue
			set_owner(x, y, id)
			count += 1
	return count

func fill_block(left: int, top: int, size: int, id: int) -> void:
	for y in range(top, top + size):
		for x in range(left, left + size):
			if playable(x, y):
				set_owner(x, y, id)

## Blok bo'sh va butunlay quruqlikdami.
func is_block_free(left: int, top: int, size: int) -> bool:
	for y in range(top, top + size):
		for x in range(left, left + size):
			if not playable(x, y):
				return false
			var i: int = index(x, y)
			if owner_cells[i] != 0 or trail_cells[i] != 0:
				return false
	return true

## O'zgargan kataklarni olib, ro'yxatni bo'shatadi.
func take_dirty() -> PackedInt32Array:
	if dirty_cells.is_empty():
		return PackedInt32Array()
	var copy := dirty_cells
	dirty_cells = PackedInt32Array()
	return copy

## Xuddi shunday, lekin tarmoq ro'yxati uchun.
func take_net_dirty() -> PackedInt32Array:
	if net_dirty.is_empty():
		return PackedInt32Array()
	var copy := net_dirty
	net_dirty = PackedInt32Array()
	return copy

func _build_distance_field() -> void:
	var total := width * height
	coast_dist = PackedFloat32Array()
	coast_dist.resize(total)
	nearest_land = PackedInt32Array()
	nearest_land.resize(total)

	if land.is_empty():
		for y in height:
			var row := y * width
			for x in width:
				var idx := row + x
				var d: float = minf(minf(float(x), float(width - 1 - x)), minf(float(y), float(height - 1 - y)))
				coast_dist[idx] = d
				nearest_land[idx] = idx
		return

	coast_dist.fill(999.0)
	for i in total:
		if land[i] == 1:
			nearest_land[i] = i
		else:
			nearest_land[i] = -1
			coast_dist[i] = 0.0

	# 1-o'tish: yuqori-chapdan pastki-o'ngga (quruqlik masofasi)
	for y in height:
		var row := y * width
		for x in width:
			var idx := row + x
			if land[idx] == 1:
				var m: float = coast_dist[idx]
				if x > 0:
					m = minf(m, coast_dist[idx - 1] + 1.0)
				if y > 0:
					m = minf(m, coast_dist[idx - width] + 1.0)
					if x > 0:
						m = minf(m, coast_dist[idx - width - 1] + 1.414)
					if x < width - 1:
						m = minf(m, coast_dist[idx - width + 1] + 1.414)
				coast_dist[idx] = m

	# 2-o'tish: pastki-o'ngdan yuqori-chapga (quruqlik masofasi)
	for y in range(height - 1, -1, -1):
		var row := y * width
		for x in range(width - 1, -1, -1):
			var idx := row + x
			if land[idx] == 1:
				var m: float = coast_dist[idx]
				if x < width - 1:
					m = minf(m, coast_dist[idx + 1] + 1.0)
				if y < height - 1:
					m = minf(m, coast_dist[idx + width] + 1.0)
					if x < width - 1:
						m = minf(m, coast_dist[idx + width + 1] + 1.414)
					if x > 0:
						m = minf(m, coast_dist[idx + width - 1] + 1.414)
				coast_dist[idx] = m

	# Suv kataklari uchun eng yaqin quruqlik katagini topish (Voronoi)
	var water_dist := PackedFloat32Array()
	water_dist.resize(total)
	water_dist.fill(999.0)
	for i in total:
		if land[i] == 1:
			water_dist[i] = 0.0

	for y in height:
		var row := y * width
		for x in width:
			var idx := row + x
			if land[idx] == 0:
				var m: float = water_dist[idx]
				var nl: int = nearest_land[idx]
				if x > 0 and water_dist[idx - 1] + 1.0 < m:
					m = water_dist[idx - 1] + 1.0
					nl = nearest_land[idx - 1]
				if y > 0:
					if water_dist[idx - width] + 1.0 < m:
						m = water_dist[idx - width] + 1.0
						nl = nearest_land[idx - width]
					if x > 0 and water_dist[idx - width - 1] + 1.414 < m:
						m = water_dist[idx - width - 1] + 1.414
						nl = nearest_land[idx - width - 1]
					if x < width - 1 and water_dist[idx - width + 1] + 1.414 < m:
						m = water_dist[idx - width + 1] + 1.414
						nl = nearest_land[idx - width + 1]
				water_dist[idx] = m
				nearest_land[idx] = nl

	for y in range(height - 1, -1, -1):
		var row := y * width
		for x in range(width - 1, -1, -1):
			var idx := row + x
			if land[idx] == 0:
				var m: float = water_dist[idx]
				var nl: int = nearest_land[idx]
				if x < width - 1 and water_dist[idx + 1] + 1.0 < m:
					m = water_dist[idx + 1] + 1.0
					nl = nearest_land[idx + 1]
				if y < height - 1:
					if water_dist[idx + width] + 1.0 < m:
						m = water_dist[idx + width] + 1.0
						nl = nearest_land[idx + width]
					if x < width - 1 and water_dist[idx + width + 1] + 1.414 < m:
						m = water_dist[idx + width + 1] + 1.414
						nl = nearest_land[idx + width + 1]
					if x > 0 and water_dist[idx + width - 1] + 1.414 < m:
						m = water_dist[idx + width - 1] + 1.414
						nl = nearest_land[idx + width - 1]
				water_dist[idx] = m
				nearest_land[idx] = nl

## Uzluksiz koordinata (px, py) da suvdan masofani chiziqli interpolatsiya bilan qaytaradi.
func sample_coast_dist(px: float, py: float) -> float:
	if coast_dist.is_empty():
		return 10.0
	var sx: float = clampf(px - 0.5, 0.0, float(width - 1))
	var sy: float = clampf(py - 0.5, 0.0, float(height - 1))
	var x0: int = int(floor(sx))
	var y0: int = int(floor(sy))
	var x1: int = mini(x0 + 1, width - 1)
	var y1: int = mini(y0 + 1, height - 1)
	var fx: float = sx - float(x0)
	var fy: float = sy - float(y0)
	var d00: float = coast_dist[y0 * width + x0]
	var d10: float = coast_dist[y0 * width + x1]
	var d01: float = coast_dist[y1 * width + x0]
	var d11: float = coast_dist[y1 * width + x1]
	var d0: float = d00 + (d10 - d00) * fx
	var d1: float = d01 + (d11 - d01) * fx
	return d0 + (d1 - d0) * fy

## Qirg'oqning ichki tomonga (quruqlikka) qaragan silliq normalini qaytaradi.
func sample_coast_normal(px: float, py: float) -> Vector2:
	if coast_dist.is_empty():
		return Vector2.ZERO
	var sx: float = clampf(px - 0.5, 0.0, float(width - 1))
	var sy: float = clampf(py - 0.5, 0.0, float(height - 1))
	var x0: int = int(floor(sx))
	var y0: int = int(floor(sy))
	var x1: int = mini(x0 + 1, width - 1)
	var y1: int = mini(y0 + 1, height - 1)
	var fx: float = sx - float(x0)
	var fy: float = sy - float(y0)
	var d00: float = coast_dist[y0 * width + x0]
	var d10: float = coast_dist[y0 * width + x1]
	var d01: float = coast_dist[y1 * width + x0]
	var d11: float = coast_dist[y1 * width + x1]
	var gx: float = (1.0 - fy) * (d10 - d00) + fy * (d11 - d01)
	var gy: float = (1.0 - fx) * (d01 - d00) + fx * (d11 - d10)
	var len2: float = gx * gx + gy * gy
	if len2 < 1e-6:
		return Vector2.ZERO
	return Vector2(gx, gy) / sqrt(len2)

