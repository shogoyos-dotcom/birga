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
	for i: int in trail:
		if trail_cells[i] == id:
			trail_cells[i] = 0
			dirty_cells.append(i)
			if net_tracking:
				net_dirty.append(i)
	_min_x[id] = 1 << 30
	_min_y[id] = 1 << 30
	_max_x[id] = -1
	_max_y[id] = -1
	return cleared

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
