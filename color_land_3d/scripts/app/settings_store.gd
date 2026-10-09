class_name SettingsStore
extends RefCounted

## O'yinchi sozlamalari va rekordi — `user://settings.cfg` da saqlanadi.
##
## Flutter variantidagi `shared_preferences` ning o'rnini bosadi: bir xil
## kalitlar, bir xil standart qiymatlar.

const PATH := "user://settings.cfg"
const SECTION := "game"

## Ilova birinchi marta ochilganda beriladigan beletlar.
const WELCOME_TICKETS := 3

var _config := ConfigFile.new()

static func load_store() -> SettingsStore:
	var store := SettingsStore.new()
	store._config.load(PATH)
	return store

## `_get` / `_set` nomlari Godot'ning ichki virtual metodlari bilan
## to'qnashadi, shuning uchun `_read` / `_write`.
func _read(key: String, fallback: Variant) -> Variant:
	return _config.get_value(SECTION, key, fallback)

func _write(key: String, value: Variant) -> void:
	_config.set_value(SECTION, key, value)
	_config.save(PATH)

# ——— Rekord ———

var best_percent: float:
	get: return float(_read("best_percent", 0.0))
var best_kills: int:
	get: return int(_read("best_kills", 0))

## Natijani saqlaydi. Yangi rekord bo'lsa `true`.
func submit_result(percent: float, kills: int) -> bool:
	var is_record := percent > best_percent
	if is_record:
		_write("best_percent", percent)
	if kills > best_kills:
		_write("best_kills", kills)
	return is_record

## Rekordni boshidan boshlaydi.
func reset_record() -> void:
	_write("best_percent", 0.0)
	_write("best_kills", 0)

# ——— Ko'rinish va o'yin ———

var color_index: int:
	get: return int(_read("color", 0))
	set(value): _write("color", value)

var theme_id: String:
	get: return str(_read("theme", "arcade"))
	set(value): _write("theme", value)

var difficulty_name: String:
	get: return str(_read("difficulty", "normal"))
	set(value): _write("difficulty", value)

var language: String:
	get: return str(_read("language", ""))
	set(value): _write("language", value)

## Arenada poytaxt belgilari ko'rinadimi.
var show_capitals: bool:
	get: return bool(_read("capitals", true))
	set(value): _write("capitals", value)

## Hudud ustida avatar (bayroq) naqshi ko'rinadimi.
var show_flags: bool:
	get: return bool(_read("flags", true))
	set(value): _write("flags", value)

## HUD da kichik xarita ko'rinadimi.
var show_minimap: bool:
	get: return bool(_read("minimap", true))
	set(value): _write("minimap", value)

# ——— Profil ———

## Bo'sh bo'lsa interfeys tilidagi "Siz" ishlatiladi.
var nickname: String:
	get: return str(_read("nickname", ""))
	set(value): _write("nickname", value)

## "emoji:X", "figure:N" yoki "flag:UZ".
var avatar: String:
	get: return str(_read("avatar", "figure:0"))
	set(value): _write("avatar", value)

## Hududda ko'rinadigan bayroq (ISO 3166-1 alpha-2).
var country: String:
	get: return str(_read("country", ""))
	set(value): _write("country", value)

# ——— Ovoz ———

var music_enabled: bool:
	get: return bool(_read("music", true))
	set(value): _write("music", value)

var sound_enabled: bool:
	get: return bool(_read("sound", true))
	set(value): _write("sound", value)

var vibration_enabled: bool:
	get: return bool(_read("vibration", true))
	set(value): _write("vibration", value)

# ——— Beletlar ———

var tickets: int:
	get: return int(_read("tickets", WELCOME_TICKETS))

## Bitta belet sarflaydi. Belet qolmagan bo'lsa `false`.
func spend_ticket() -> bool:
	var left := tickets
	if left <= 0:
		return false
	_write("tickets", left - 1)
	return true

func add_tickets(count: int) -> void:
	_write("tickets", tickets + count)
