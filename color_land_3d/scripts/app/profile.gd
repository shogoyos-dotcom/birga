class_name Profile
extends RefCounted

## O'yinchi avatari: emoji, kod bilan chiziladigan odam tasviri yoki
## davlat bayrog'i.
##
## Rasm fayllari saqlanmaydi — emoji va bayroqlar shriftdan chiziladi
## (bayroq kodi ikki "regional indicator" belgisiga aylantiriladi).

enum Kind { EMOJI, FIGURE, FLAG }

const COUNTRIES_PATH := "res://data/countries.json"

## Taxallus uzunligi chegarasi.
const MAX_NICKNAME := 12

## Tanlash uchun emoji to'plami.
const EMOJIS: PackedStringArray = [
	"😀", "😎", "🤩", "🥳", "😈", "🤖", "👻", "💀",
	"🦊", "🐱", "🐶", "🐼", "🐸", "🦁", "🐯", "🐵",
	"🦄", "🐙", "🦖", "🐢", "🦅", "🐝", "🦋", "🐬",
	"🔥", "⚡", "💎", "🌟", "🍀", "🌈", "🍕", "🍩",
	"⚽", "🏀", "🎮", "🎧", "🚀", "👑", "🎯", "🏆",
]

## Odam tasvirlari soni.
const FIGURE_COUNT := 12

## 3D arenada hudud ustiga qo'yiladigan odam belgilari.
##
## Interfeysda odam tasviri shakllardan chiziladi, lekin arenada belgi
## shriftdan keladi — shuning uchun har bir tasvirga mos emoji olinadi.
const FIGURE_GLYPHS: PackedStringArray = [
	"\U01F9D1", "\U01F468", "\U01F469", "\U01F9D2",
	"\U01F466", "\U01F467", "\U01F9D3", "\U01F474",
	"\U01F475", "\U01F9D4", "\U01F46E", "\U01F9B8",
]

static var _countries: Array = []

## [{code, name}] — ISO 3166-1 bo'yicha 249 davlat.
static func countries() -> Array:
	if not _countries.is_empty():
		return _countries
	var file := FileAccess.open(COUNTRIES_PATH, FileAccess.READ)
	if file == null:
		push_error("Davlatlar ro'yxati topilmadi: %s" % COUNTRIES_PATH)
		return _countries
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Array:
		_countries = parsed
	return _countries

static func search_countries(query: String) -> Array:
	var needle := query.strip_edges().to_lower()
	if needle.is_empty():
		return countries()
	var out: Array = []
	for c: Dictionary in countries():
		if str(c["name"]).to_lower().contains(needle) \
				or str(c["code"]).to_lower() == needle:
			out.append(c)
	return out

static func country_name(code: String) -> String:
	for c: Dictionary in countries():
		if str(c["code"]) == code.to_upper():
			return str(c["name"])
	return code

## Davlat kodidan bayroq emojisi: "UZ" -> 🇺🇿
static func flag_emoji(code: String) -> String:
	if code.length() != 2:
		return ""
	var offset := 0x1F1E6 - 0x41
	var upper := code.to_upper()
	return String.chr(upper.unicode_at(0) + offset) \
		+ String.chr(upper.unicode_at(1) + offset)

## "emoji:🦊" / "figure:3" / "flag:UZ" -> {kind, value}
static func decode(raw: String) -> Dictionary:
	var parts := raw.split(":", true, 1)
	if parts.size() != 2:
		return {"kind": Kind.FIGURE, "value": "0"}
	match parts[0]:
		"emoji": return {"kind": Kind.EMOJI, "value": parts[1]}
		"flag": return {"kind": Kind.FLAG, "value": parts[1]}
		_: return {"kind": Kind.FIGURE, "value": parts[1]}

static func encode(kind: Kind, value: String) -> String:
	match kind:
		Kind.EMOJI: return "emoji:" + value
		Kind.FLAG: return "flag:" + value
		_: return "figure:" + value

## Ekranda ko'rsatiladigan belgi. Odam tasviri uchun bo'sh — u
## shakllardan chiziladi.
static func glyph(raw: String) -> String:
	var a := decode(raw)
	match a["kind"]:
		Kind.EMOJI: return str(a["value"])
		Kind.FLAG: return flag_emoji(str(a["value"]))
		_: return ""

## Arenada chiziladigan belgi — odam tasviri uchun ham bo'sh emas.
static func map_glyph(raw: String) -> String:
	var g := glyph(raw)
	if not g.is_empty():
		return g
	var i := figure_index(raw)
	return FIGURE_GLYPHS[clampi(i, 0, FIGURE_GLYPHS.size() - 1)]

static func figure_index(raw: String) -> int:
	var a := decode(raw)
	return int(str(a["value"])) if a["kind"] == Kind.FIGURE else 0

## Bo'sh yoki faqat probel bo'lsa, standart nom ishlatiladi.
static func sanitize(raw: String, fallback: String) -> String:
	var trimmed := raw.strip_edges()
	if trimmed.is_empty():
		return fallback
	return trimmed.substr(0, MAX_NICKNAME)

## Tasodifiy avatar — botlar uchun.
static func random_avatar(rng: RandomNumberGenerator) -> String:
	match rng.randi_range(0, 2):
		0: return encode(Kind.EMOJI, EMOJIS[rng.randi_range(0, EMOJIS.size() - 1)])
		1: return encode(Kind.FIGURE, str(rng.randi_range(0, FIGURE_COUNT - 1)))
		_:
			var list := countries()
			if list.is_empty():
				return encode(Kind.FIGURE, "0")
			var c: Dictionary = list[rng.randi_range(0, list.size() - 1)]
			return encode(Kind.FLAG, str(c["code"]))
