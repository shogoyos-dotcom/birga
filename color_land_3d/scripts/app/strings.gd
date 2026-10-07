class_name Strings
extends RefCounted

## Interfeys matnlari: 5 til. Ma'lumot `data/strings.json` dan keladi va
## Flutter variantidagi `AppStrings` dan generatsiya qilingan — ikkala
## o'yinda matnlar bir xil.

const PATH := "res://data/strings.json"

const CODES: PackedStringArray = ["uz", "en", "ru", "tr", "kk"]
const NATIVE_NAMES: PackedStringArray = [
	"O'zbekcha", "English", "Русский", "Türkçe", "Қазақша",
]

static var _all: Dictionary = {}
static var _current: Dictionary = {}
static var _code: String = "uz"

static func _load_all() -> void:
	if not _all.is_empty():
		return
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_error("Matnlar topilmadi: %s" % PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_all = parsed

## Tilni o'rnatadi. Kod noma'lum bo'lsa o'zbekcha qoladi.
static func set_language(code: String) -> void:
	_load_all()
	if not _all.has(code):
		code = "uz"
	_code = code
	_current = _all[code]

static func language() -> String:
	return _code

## Tizim tiliga moslashtiradi (til hali tanlanmagan bo'lsa).
static func detect_language() -> String:
	var locale := OS.get_locale_language()
	return locale if CODES.has(locale) else "uz"

static func native_name(code: String) -> String:
	var i := CODES.find(code)
	return NATIVE_NAMES[i] if i >= 0 else code

## Matnni kalit bo'yicha oladi. Topilmasa kalitning o'zini qaytaradi —
## shunda yetishmayotgan satr ekranda darhol ko'rinadi.
static func t(key: String) -> String:
	if _current.is_empty():
		set_language(_code)
	return str(_current.get(key, key))

## Arena uslubi nomi — tarjima qilinadi, [Palette] dagi nom emas.
static func theme_name(id: String) -> String:
	return t("theme" + id.capitalize())

## Uslublar ro'yxati — [Palette.ORDER] tartibida.
static func theme_names() -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in Palette.ORDER:
		out.append(theme_name(id))
	return out

static func difficulty_name(level: Difficulty.Level) -> String:
	match level:
		Difficulty.Level.EASY: return t("easy")
		Difficulty.Level.HARD: return t("hard")
		_: return t("normal")

static func death_reason(cause: PlayerState.DeathCause) -> String:
	match cause:
		PlayerState.DeathCause.SELF_CROSS: return t("diedSelfCross")
		PlayerState.DeathCause.TRAIL_HIT: return t("diedTrailHit")
		PlayerState.DeathCause.TERRITORY_LOST: return t("diedTerritoryLost")
		_: return ""
