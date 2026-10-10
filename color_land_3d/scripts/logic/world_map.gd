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

var id: String = "world"
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

static func load_map(map_id: String) -> WorldMap:
	var map := WorldMap.new()
	map.id = map_id
	if map_id == CIRCLE_ID:
		map._build_circle()
	else:
		map._read(map_id)
	return map

# ——— Fayldan o'qish ———

func _read(map_id: String) -> void:
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

	width = body.decode_u16(0)
	height = body.decode_u16(2)
	if width <= 0 or height <= 0:
		push_error("Maydon o'lchami noto'g'ri: %s" % path)
		return
	var cells := width * height
	var at := 4 + (cells + 7) / 8
	land = _unpack(body.slice(4, at), cells)
	land_cells = 0
	for v: int in land:
		land_cells += v

	# Geometriya: uchburchaklar va devor kesmalari. Koordinatalar
	# 1/FIXED katak aniqligida uint16 bo'lib yozilgan.
	var tri_count := body.decode_u32(at)
	at += 4
	top_points = _read_points(body, at, tri_count * 3)
	at += tri_count * 3 * 4
	var wall_count := body.decode_u32(at)
	at += 4
	wall_points = _read_points(body, at, wall_count * 2)

	var meta: Dictionary = _index[map_id]
	for c: Variant in meta.get("places", []):
		places.append(c as Dictionary)
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
func _build_circle() -> void:
	width = CIRCLE_SIZE
	height = CIRCLE_SIZE
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
