class_name WorldMap
extends RefCounted

## Dunyo xaritasi: quruqlik niqobi va poytaxtlar.
##
## Ma'lumot `tool/make_world_map.py` (Flutter loyihasidagi) bilan Natural
## Earth 1:110m dan yaratiladi. Niqob har katak uchun bitta bit —
## 520x205 xarita atigi 13 KB.

const LAND_PATH := "res://data/world_land.bin"
const CAPITALS_PATH := "res://data/capitals.json"

var width: int
var height: int
## Har katak uchun 1 (quruqlik) yoki 0 (suv).
var land: PackedByteArray
var land_cells: int
## Poytaxtlar: {name, code, x, y, pop}.
var capitals: Array[Dictionary] = []

static func load_default() -> WorldMap:
	var map := WorldMap.new()
	map._read_land()
	map._read_capitals()
	return map

## Niqob o'qildimi. `assert` ishlatilmaydi: u release qurilmasida
## o'chiriladi va keyin `null` ga murojaat qilib o'yin yiqilardi.
var ok: bool = false

func _read_land() -> void:
	var file := FileAccess.open(LAND_PATH, FileAccess.READ)
	if file == null:
		push_error("Quruqlik niqobi topilmadi: %s" % LAND_PATH)
		return
	if file.get_length() < 8:
		push_error("Quruqlik niqobi juda kichik: %s" % LAND_PATH)
		file.close()
		return
	var magic := file.get_buffer(4).get_string_from_ascii()
	if magic != "CLND":
		push_error("Quruqlik niqobi buzilgan (sarlavha: %s)" % magic)
		file.close()
		return
	width = file.get_16()
	height = file.get_16()
	var packed := file.get_buffer(file.get_length() - 8)
	file.close()
	if width <= 0 or height <= 0 or packed.size() * 8 < width * height:
		push_error("Quruqlik niqobi to'liq emas")
		return
	ok = true

	land = PackedByteArray()
	land.resize(width * height)
	land_cells = 0
	for i in land.size():
		var bit: int = (packed[i >> 3] >> (i & 7)) & 1
		land[i] = bit
		land_cells += bit

func _read_capitals() -> void:
	var file := FileAccess.open(CAPITALS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary and parsed.has("capitals"):
		for c: Variant in parsed["capitals"]:
			capitals.append(c as Dictionary)

func is_land(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= width or y >= height:
		return false
	return land[y * width + x] == 1
