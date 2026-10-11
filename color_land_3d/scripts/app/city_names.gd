class_name CityNames
extends RefCounted

## Shahar nomlarining tarjimasi.
##
## Ma'lumot Natural Earth ning o'zidan keladi (`NAME_RU`, `NAME_ZH`
## va hokazo) va `tool/make_maps.py` uni `data/city_names.json` ga
## yozadi. Faylda faqat **inglizchadan farq qiladigan** nomlar bor,
## shuning uchun u 235 KB.
##
## O'zbekcha va qozoqcha Natural Earth da yo'q — u tillarda nomlar
## inglizchasicha qoladi.

const PATH := "res://data/city_names.json"

static var _loaded := ""
static var _table: Dictionary = {}

## Tanlangan tilga o'tkazadi. Til o'zgarsa jadval qayta yuklanadi.
static func use(code: String) -> void:
	if _loaded == code:
		return
	_loaded = code
	_table = {}
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary and parsed.has(code):
		_table = parsed[code]

## Inglizcha nomni joriy tilga o'giradi. Tarjimasi bo'lmasa
## inglizchasini qaytaradi.
static func of(english: String) -> String:
	return str(_table.get(english, english))

## Nechta nom tarjima qilingan (sinov uchun).
static func size() -> int:
	return _table.size()
