class_name WorldMap
extends RefCounted

## O'yin maydoni: mantiq niqobi, arena geometriyasi va shaharlar.
##
## Ikki qism bor:
##  * [land] — o'yin panjarasi. Harakat, iz va hudud shu bo'yicha.
##  * [top_points] / [wall_points] — tayyor arena geometriyasi.
##    Chegara generatorda uzluksiz maydonning 0.5 sathidan olingan
##    (marching squares + chiziqli interpolatsiya), shuning uchun
##    qirg'oq katakka yopishmaydi va zinapoya bo'lmaydi.
##
## Ma'lumot `tool/make_maps.py` bilan Natural Earth 1:110m dan
## yaratiladi. Doira maydon esa fayldan emas, shu yerda hisoblanadi.

const INDEX_PATH := "res://data/maps/index.json"
const MAP_DIR := "res://data/maps/"

## Doira maydon — erkin, suvsiz o'yin uchun.
const CIRCLE_ID := "circle"
const CIRCLE_SIZE := 320

## Koordinatalar faylda 1/FIXED katak aniqligida saqlanadi.
const FIXED := 64.0

const DEFAULT_SCALE := 2

var id: String = "world"
var scale_factor: int = DEFAULT_SCALE
var width: int
var height: int
## Har katak uchun 1 (quruqlik) yoki 0 (suv) — o'yin mantig'i shu
## niqob bo'yicha ishlaydi.
var land: PackedByteArray
var land_cells: int
## Arena geometriyasi: ustki yuza uchburchaklari (har uchtasi bitta
## uchburchak) va devor kesmalari (har ikkitasi bitta kesma). Ikkalasi
## ham katak birligida, chegara chiziqli interpolatsiya bilan
## topilgani uchun zinapoyasiz.
var top_points := PackedVector2Array()
var wall_points := PackedVector2Array()
## Xaritadagi shaharlar: {name, code, x, y, pop, cap}.
var places: Array[Dictionary] = []
## Niqob o'qildimi. `assert` ishlatilmaydi: u release qurilmasida
## o'chiriladi va keyin bo'sh niqobga murojaat qilib o'yin yiqilardi.
var ok: bool = false

static var _index: Dictionary = {}

## Mavjud maydonlar ro'yxati (tartib bilan).
static func ids() -> PackedStringArray:
	_load_index()
	var out := PackedStringArray()
	for key: String in _index.keys():
		out.append(key)
	out.append(CIRCLE_ID)
	return out

static func has_id(map_id: String) -> bool:
	return map_id == CIRCLE_ID or ids().has(map_id)

static func _load_index() -> void:
	if not _index.is_empty():
		return
	var file := FileAccess.open(INDEX_PATH, FileAccess.READ)
	if file == null:
		push_error("Maydonlar ro'yxati topilmadi: %s" % INDEX_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary) or not parsed.has("maps"):
		push_error("Maydonlar ro'yxati buzilgan")
		return
	for entry: Variant in parsed["maps"]:
		var meta: Dictionary = entry
		_index[str(meta["id"])] = meta

static func load_map(map_id: String, p_scale: int = DEFAULT_SCALE) -> WorldMap:
	var map := WorldMap.new()
	map.id = map_id
	map.scale_factor = p_scale
	if map_id == CIRCLE_ID:
		map._build_circle(p_scale)
	else:
		map._read(map_id, p_scale)
	return map

# ——— Fayldan o'qish ———

func _read(map_id: String, p_scale: int = DEFAULT_SCALE) -> void:
	_load_index()
	if not _index.has(map_id):
		push_error("Noma'lum maydon: %s" % map_id)
		return
	var path := MAP_DIR + map_id + ".bin"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Maydon fayli topilmadi: %s" % path)
		return
	var magic := file.get_buffer(4).get_string_from_ascii()
	if magic != "CLM4":
		push_error("Maydon fayli buzilgan (sarlavha: %s)" % magic)
		file.close()
		return
	var plain_size := file.get_32()
	var squeezed := file.get_buffer(file.get_length() - 8)
	file.close()
	var body := squeezed.decompress(plain_size, FileAccess.COMPRESSION_DEFLATE)
	if body.size() < plain_size:
		push_error("Maydon fayli ochilmadi: %s" % path)
		return

	var raw_w := body.decode_u16(0)
	var raw_h := body.decode_u16(2)
	if raw_w <= 0 or raw_h <= 0:
		push_error("Maydon o'lchami noto'g'ri: %s" % path)
		return
	var raw_cells := raw_w * raw_h
	var at := 4 + (raw_cells + 7) / 8
	var raw_land := _unpack(body.slice(4, at), raw_cells)

	# Geometriya: uchburchaklar va devor kesmalari. Koordinatalar
	# 1/FIXED katak aniqligida uint16 bo'lib yozilgan.
	var tri_count := body.decode_u32(at)
	at += 4
	var raw_top := _read_points(body, at, tri_count * 3)
	at += tri_count * 3 * 4
	var wall_count := body.decode_u32(at)
	at += 4
	var raw_wall := _read_points(body, at, wall_count * 2)

	var meta: Dictionary = _index[map_id]
	var raw_places: Array = meta.get("places", [])

	scale_factor = maxi(1, p_scale)
	if scale_factor == 1:
		width = raw_w
		height = raw_h
		land = raw_land
		land_cells = 0
		for v: int in land:
			land_cells += v
		top_points = raw_top
		wall_points = raw_wall
		places.clear()
		for c: Variant in raw_places:
			places.append(c as Dictionary)
	else:
		width = raw_w * scale_factor
		height = raw_h * scale_factor
		land = PackedByteArray()
		land.resize(width * height)
		land_cells = 0
		for y in height:
			var orig_y: int = y / scale_factor
			var row_out := y * width
			var row_in := orig_y * raw_w
			for x in width:
				var val: int = raw_land[row_in + (x / scale_factor)]
				land[row_out + x] = val
				land_cells += val

		top_points = PackedVector2Array()
		top_points.resize(raw_top.size())
		var sf := float(scale_factor)
		for i in raw_top.size():
			top_points[i] = raw_top[i] * sf

		wall_points = PackedVector2Array()
		wall_points.resize(raw_wall.size())
		for i in raw_wall.size():
			wall_points[i] = raw_wall[i] * sf

		places.clear()
		for c: Variant in raw_places:
			var d := (c as Dictionary).duplicate()
			d["x"] = int(d.get("x", 0)) * scale_factor + (scale_factor / 2)
			d["y"] = int(d.get("y", 0)) * scale_factor + (scale_factor / 2)
			places.append(d)

	ok = true

## Ikkilik ma'lumotdan (x, z) juftliklarini o'qiydi.
static func _read_points(body: PackedByteArray, at: int,
		count: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(count)
	for i in count:
		out[i] = Vector2(
			body.decode_u16(at) / FIXED, body.decode_u16(at + 2) / FIXED)
		at += 4
	return out

static func _unpack(packed: PackedByteArray, count: int) -> PackedByteArray:
	var out := PackedByteArray()
	if packed.size() * 8 < count:
		return out
	out.resize(count)
	for i in count:
		out[i] = (packed[i >> 3] >> (i & 7)) & 1
	return out

# ——— Doira maydon ———

## Erkin maydon: xaritasiz, bitta katta doira. Chizish niqobi ham shu
## yerda hisoblanadi, shuning uchun cheti o'z-o'zidan silliq.
func _build_circle(p_scale: int = DEFAULT_SCALE) -> void:
	scale_factor = maxi(1, p_scale)
	width = CIRCLE_SIZE * scale_factor
	height = CIRCLE_SIZE * scale_factor
	var radius := width * 0.47
	land = _disc(width, height, radius)
	land_cells = 0
	for v: int in land:
		land_cells += v
	_circle_mesh(radius)
	ok = true

static func _disc(w: int, h: int, radius: float) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(w * h)
	var cx := w * 0.5
	var cy := h * 0.5
	var r2 := radius * radius
	for y in h:
		var dy := y + 0.5 - cy
		var row := y * w
		for x in w:
			var dx := x + 0.5 - cx
			out[row + x] = 1 if dx * dx + dy * dy <= r2 else 0
	return out

## Doiraning geometriyasi — oddiy aylana, shuning uchun to'g'ridan
## to'g'ri uchburchaklarga bo'linadi.
func _circle_mesh(radius: float) -> void:
	var center := Vector2(width * 0.5, height * 0.5)
	var steps := 360
	top_points = PackedVector2Array()
	wall_points = PackedVector2Array()
	for i in steps:
		var a0 := TAU * i / steps
		var a1 := TAU * (i + 1) / steps
		var p0 := center + Vector2(cos(a0), sin(a0)) * radius
		var p1 := center + Vector2(cos(a1), sin(a1)) * radius
		top_points.append(center)
		top_points.append(p0)
		top_points.append(p1)
		wall_points.append(p0)
		wall_points.append(p1)

func is_land(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= width or y >= height:
		return false
	return land[y * width + x] == 1
