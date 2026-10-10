class_name Palette
extends RefCounted

## O'yinchi ranglari va arena uslublari.
##
## Uslub faqat **arena** ko'rinishini o'zgartiradi (quruqlik, okean,
## osmon, o'yinchi ranglari). Interfeys ranglari [UiKit] da va ular
## hamma uslubda bir xil — shunda menyu va HUD doim bir xil o'qiladi.

## "Color Lands" to'plami — och muz maydonda yaxshi ko'rinadigan,
## to'yingan ranglar. Hudud bu ranglardan 18% to'qroq chiziladi,
## shuning uchun ular muz ustida aniq ajralib turadi.
const COLORLANDS: PackedColorArray = [
	Color("ff3d9a"), Color("3be8b0"), Color("2e9bff"), Color("ffd23f"),
	Color("9b4be0"), Color("ff8a3d"), Color("d8ff3e"), Color("00d6d1"),
	Color("ff6fc8"), Color("6ee07a"), Color("5c8cff"), Color("ffb020"),
	Color("c06bff"), Color("ff5f5f"), Color("1fc7a4"), Color("8ad0ff"),
]
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
	"colorlands": {
		"name": "Color Lands", "land": "cfe6f7", "land_side": "8fb6d2",
		"ocean": "1b0f3e", "sky": "241350", "heads": "colorlands",
	},
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

const ORDER: PackedStringArray = [
	"colorlands", "arcade", "neon", "night", "bright", "pastel",
]

const DEFAULT_THEME := "colorlands"

static var _theme_id := DEFAULT_THEME

static func set_theme(id: String) -> void:
	_theme_id = id if THEMES.has(id) else DEFAULT_THEME

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
		"colorlands": return COLORLANDS
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

## Quruqlik ustiga yoziladigan matn ranglari.
##
## "Color Lands" maydoni deyarli oq — oq yozuv unda yo'qoladi.
## Shuning uchun rang quruqlikning yorqinligiga qarab tanlanadi:
## ochiq maydonda to'q siyoh va oq kontur, to'q maydonda aksincha.
static func land_is_light() -> bool:
	return land().get_luminance() > 0.5

static func on_land() -> Color:
	return Color("1f1646") if land_is_light() else Color("f4f2ff")

static func on_land_dim() -> Color:
	return Color("4b3f80") if land_is_light() else Color("9a93bd")

static func on_land_outline() -> Color:
	return Color(1, 1, 1, 0.9) if land_is_light() else Color(0.04, 0.03, 0.09, 0.85)

## Shahar nuqtasining rangi.
static func city_dot() -> Color:
	return Color("6b5fa8") if land_is_light() else Color("b9c0e0")

static func land() -> Color:
	return Color(str(_current()["land"]))

static func land_side() -> Color:
	return Color(str(_current()["land_side"]))

static func ocean() -> Color:
	return Color(str(_current()["ocean"]))

static func sky() -> Color:
	return Color(str(_current()["sky"]))
