class_name WorldMap
extends RefCounted

## O'yin maydoni: mantiq niqobi, chizish niqobi va poytaxtlar.
##
## Ikki niqob bor:
##  * [land] — o'yin panjarasi. Harakat, iz va hudud shu bo'yicha.
##  * [render_land] — [scale] barobar maydaroq va silliqlangan niqob.
##    Arena geometriyasi shundan quriladi, shuning uchun qirg'oq
##    zinapoya bo'lib ko'rinmaydi.
##
## Ma'lumot `tool/make_maps.py` bilan Natural Earth 1:110m dan
## yaratiladi. Doira maydon esa fayldan emas, shu yerda hisoblanadi.

const INDEX_PATH := "res://data/maps/index.json"
const MAP_DIR := "res://data/maps/"

## Doira maydon — erkin, suvsiz o'yin uchun.
const CIRCLE_ID := "circle"
const CIRCLE_SIZE := 320
const CIRCLE_SCALE := 3

var id: String = "world"
var width: int
var height: int
## Chizish niqobi mantiq niqobidan shuncha marta maydaroq.
var scale: int = 1
## Har katak uchun 1 (quruqlik) yoki 0 (suv).
var land: PackedByteArray
var land_cells: int
var render_land: PackedByteArray
var render_width: int
var render_height: int
## Poytaxtlar: {name, code, x, y, pop}.
var capitals: Array[Dictionary] = []
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
	if magic != "CLM3":
		push_error("Maydon fayli buzilgan (sarlavha: %s)" % magic)
		file.close()
		return
	width = file.get_16()
	height = file.get_16()
	scale = file.get_8()
	file.get_8()
	render_width = file.get_16()
	render_height = file.get_16()
	if width <= 0 or height <= 0 or scale <= 0:
		push_error("Maydon o'lchami noto'g'ri: %s" % path)
		file.close()
		return
	land = _unpack(file.get_buffer((width * height + 7) / 8), width * height)
	render_land = _unpack(
		file.get_buffer((render_width * render_height + 7) / 8),
		render_width * render_height)
	file.close()
	if land.size() < width * height:
		push_error("Maydon niqobi to'liq emas: %s" % path)
		return
	land_cells = 0
	for v: int in land:
		land_cells += v
	var meta: Dictionary = _index[map_id]
	for c: Variant in meta.get("capitals", []):
		capitals.append(c as Dictionary)
	ok = true

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
	scale = CIRCLE_SCALE
	render_width = width * scale
	render_height = height * scale
	var radius := width * 0.47
	land = _disc(width, height, radius)
	render_land = _disc(render_width, render_height, radius * scale)
	land_cells = 0
	for v: int in land:
		land_cells += v
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

func is_land(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= width or y >= height:
		return false
	return land[y * width + x] == 1
