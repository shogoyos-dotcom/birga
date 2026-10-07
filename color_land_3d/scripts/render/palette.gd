class_name Palette
extends RefCounted

## O'yinchi ranglari va arena uslublari.
##
## Uslub faqat **arena** ko'rinishini o'zgartiradi (quruqlik, okean,
## osmon, o'yinchi ranglari). Interfeys ranglari [UiKit] da va ular
## hamma uslubda bir xil — shunda menyu va HUD doim bir xil o'qiladi.

const ARCADE: PackedColorArray = [
	Color("3d7bff"), Color("ff6b5b"), Color("2fd6a6"), Color("ffc43d"),
	Color("9b6bff"), Color("22d3ee"), Color("ff5ca8"), Color("a3e635"),
	Color("6d8bff"), Color("ff8a4c"), Color("34d399"), Color("e879f9"),
	Color("4cc9f0"), Color("ffd166"), Color("f2545b"), Color("7dd3fc"),
]
const NEON: PackedColorArray = [
	Color("2bd9ff"), Color("ff2d78"), Color("3cffa8"), Color("ffb300"),
	Color("b14dff"), Color("00e5ff"), Color("ff4fd8"), Color("ffe93d"),
	Color("5c7bff"), Color("2effd5"), Color("ff7a1a"), Color("17c3ff"),
	Color("ff37b0"), Color("9cff2e"), Color("ff3355"), Color("5be9ff"),
]
const PASTEL: PackedColorArray = [
	Color("7fa6f0"), Color("f59ca9"), Color("86d6b4"), Color("f5c784"),
	Color("bfa2e8"), Color("8ed3dc"), Color("f2a7ce"), Color("f2dc8c"),
	Color("9faaf0"), Color("9ccbaf"), Color("f5b295"), Color("8fc9e0"),
	Color("d49bcb"), Color("b7ce8c"), Color("ee9dae"), Color("9fdbf0"),
]

## id -> {name, land, land_side, ocean, sky, heads}
const THEMES := {
	"arcade": {
		"name": "Arcade", "land": "3b3370", "land_side": "231c47",
		"ocean": "0b1038", "sky": "100e1b", "heads": "arcade",
	},
	"neon": {
		"name": "Neon", "land": "1d2a4d", "land_side": "0e1630",
		"ocean": "04060b", "sky": "05070d", "heads": "neon",
	},
	"night": {
		"name": "Tungi", "land": "2a3350", "land_side": "171d33",
		"ocean": "0d1120", "sky": "0d1120", "heads": "arcade",
	},
	"bright": {
		"name": "Yorqin", "land": "e8edf6", "land_side": "aab6cc",
		"ocean": "a9c4de", "sky": "cfe0f0", "heads": "arcade",
	},
	"pastel": {
		"name": "Pastel", "land": "f3e8d4", "land_side": "c9b795",
		"ocean": "b6d2dc", "sky": "e8dcc6", "heads": "pastel",
	},
}

const ORDER: PackedStringArray = ["arcade", "neon", "night", "bright", "pastel"]

static var _theme_id := "arcade"

static func set_theme(id: String) -> void:
	_theme_id = id if THEMES.has(id) else "arcade"

static func theme_id() -> String:
	return _theme_id

static func theme_names() -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in ORDER:
		out.append(str(THEMES[id]["name"]))
	return out

static func _current() -> Dictionary:
	return THEMES[_theme_id]

static func heads() -> PackedColorArray:
	match str(_current()["heads"]):
		"neon": return NEON
		"pastel": return PASTEL
		_: return ARCADE

static func head(index: int) -> Color:
	var list := heads()
	return list[index % list.size()]

static func color_count() -> int:
	return heads().size()

## Hudud rangi — bosh rangdan to'qroq.
static func territory(index: int) -> Color:
	return head(index).darkened(0.18)

## Iz rangi — bosh rangdan ochroq.
static func trail(index: int) -> Color:
	return head(index).lightened(0.3)

static func land() -> Color:
	return Color(str(_current()["land"]))

static func land_side() -> Color:
	return Color(str(_current()["land_side"]))

static func ocean() -> Color:
	return Color(str(_current()["ocean"]))

static func sky() -> Color:
	return Color(str(_current()["sky"]))
