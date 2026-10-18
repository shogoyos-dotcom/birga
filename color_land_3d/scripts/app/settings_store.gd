class_name SettingsStore
extends RefCounted

const SavePaths := preload("res://scripts/app/save_paths.gd")

## O'yinchi sozlamalari va rekordi — `user://settings.cfg` da saqlanadi.
##
## Flutter variantidagi `shared_preferences` ning o'rnini bosadi: bir xil
## kalitlar, bir xil standart qiymatlar.

const PATH := "user://settings.cfg"
const SECTION := "game"

## Ilova birinchi marta ochilganda beriladigan beletlar.
const WELCOME_TICKETS := 3

var _file_path: String = ""
var _config := ConfigFile.new()

func get_file_path() -> String:
	if not _file_path.is_empty():
		return _file_path
	return SavePaths.path_for(SavePaths.SETTINGS)

func set_file_path(path: String) -> void:
	_file_path = path
	_config = ConfigFile.new()
	if FileAccess.file_exists(path):
		_config.load(path)

static func load_store(custom_path: String = "") -> SettingsStore:
	var store := SettingsStore.new()
	if not custom_path.is_empty():
		store._file_path = custom_path
	var path := store.get_file_path()
	if FileAccess.file_exists(path):
		store._config.load(path)
	return store

## `_get` / `_set` nomlari Godot'ning ichki virtual metodlari bilan
## to'qnashadi, shuning uchun `_read` / `_write`.
func _read(key: String, fallback: Variant) -> Variant:
	return _config.get_value(SECTION, key, fallback)

func _write(key: String, value: Variant) -> void:
	_config.set_value(SECTION, key, value)
	var path := get_file_path()
	SavePaths.ensure_dir_exists(path.get_base_dir())
	_config.save(path)

# ——— Rekord ———

var best_percent: float:
	get: return float(_read("best_percent", 0.0))
var best_kills: int:
	get: return int(_read("best_kills", 0))

## Natijani saqlaydi. Yangi rekord bo'lsa `true`.
func submit_result(percent: float, kills: int, m_id: String = "") -> bool:
	var is_record := percent > best_percent
	if is_record:
		_write("best_percent", percent)
	if kills > best_kills:
		_write("best_kills", kills)
	var active_map := m_id if not m_id.is_empty() else map_id
	set_map_record(active_map, percent)
	return is_record

## Har xarita bo'yicha alohida rekord
func get_map_record(id: String) -> float:
	return float(_read("map_record_" + id, 0.0))

func set_map_record(id: String, percent: float) -> void:
	var prev := get_map_record(id)
	if percent > prev:
		_write("map_record_" + id, percent)

## Rekordni boshidan boshlaydi.
func reset_record() -> void:
	_write("best_percent", 0.0)
	_write("best_kills", 0)

# ——— Ko'rinish va o'yin ———

var color_index: int:
	get: return int(_read("color", 0))
	set(value): _write("color", value)

var theme_id: String:
	get: return str(_read("theme", Palette.DEFAULT_THEME))
	set(value): _write("theme", value)

## Qaysi maydon o'ynaladi: "world", "africa", ..., "circle".
var map_id: String:
	get: return str(_read("map", "world"))
	set(value): _write("map", value)

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

## Arenada shahar nomlari yozilsinmi.
var show_city_names: bool:
	get: return bool(_read("city_names", true))
	set(value): _write("city_names", value)

## Hudud ustida avatar (bayroq) naqshi ko'rinadimi.
## Hudud ustida o'yinchi avatari ko'rinadimi.
##
## Boshlang'ich holat — **o'chiq**: hudud endi skin naqshi bilan
## bo'yaladi va ulkan avatar uni bosib ketardi.
var show_flags: bool:
	get: return bool(_read("flags", true))
	set(value): _write("flags", value)

## HUD da kichik xarita ko'rinadimi.
##
## Eski kalit: faqat bor/yo'q edi. Endi tomoni ham tanlanadi,
## shuning uchun [member minimap_side] asosiy kalit bo'ldi va bu
## xossa unga ishora qiladi.
var show_minimap: bool:
	get: return minimap_side != "off"
	set(value): minimap_side = "left" if value else "off"

## HUD da FPS va xotira monitoringi (test/QA uchun, odatda o'chiq).
var show_fps: bool:
	get: return bool(_read("show_fps", false))
	set(value): _write("show_fps", value)

## Kichik xarita qaysi tomonda: "left", "right" yoki "off".
var minimap_side: String:
	get:
		var saved := str(_read("minimap_side", ""))
		if MINIMAP_SIDES.has(saved):
			return saved
		# Eski sozlamadan ko'chirish.
		return "left" if bool(_read("minimap", true)) else "off"
	set(value):
		_write("minimap_side", value if MINIMAP_SIDES.has(value) else "left")

const MINIMAP_SIDES: PackedStringArray = ["left", "right", "off"]

# ——— Profil ———

## Bo'sh bo'lsa interfeys tilidagi "Siz" ishlatiladi.
var nickname: String:
	get: return str(_read("nickname", ""))
	set(value): _write("nickname", value)

## "emoji:X", "figure:N" yoki "flag:UZ".
var avatar: String:
	get: return str(_read("avatar", "figure:0"))
	set(value): _write("avatar", value)

## O'yinchi yuklagan avatar rasmi ("" — yo'q).
var avatar_image: String:
	get: return str(_read("avatar_image", ""))
	set(value): _write("avatar_image", value)

## O'yinchi yuklagan hudud rasmi ("" — bayroq ishlatiladi).
var flag_image: String:
	get: return str(_read("flag_image", ""))
	set(value): _write("flag_image", value)

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

## Musiqa balandligi, 0..100.
var music_volume: int:
	get: return clampi(int(_read("music_volume", 70)), 0, 100)
	set(value): _write("music_volume", clampi(value, 0, 100))

## Ovoz effektlari balandligi, 0..100.
var sound_volume: int:
	get: return clampi(int(_read("sound_volume", 85)), 0, 100)
	set(value): _write("sound_volume", clampi(value, 0, 100))

## Tanlangan kuy: "pulse", "neon", "sprint" yoki "retro".
var music_track: String:
	get: return str(_read("music_track", "pulse"))
	set(value): _write("music_track", value)

# ——— Tarmoq ———

## Oxirgi kiritilgan xona manzili (mahalliy tarmoq).
var last_room: String:
	get: return str(_read("last_room", ""))
	set(value): _write("last_room", value)

## Internetdagi server manzili.
var server_address: String:
	get: return str(_read("server", ""))
	set(value): _write("server", value)

## Reyting serveri manzili (http://...). Bo'sh — reyting o'chiq.
var leaderboard_url: String:
	get: return str(_read("board_url", ""))
	set(value): _write("board_url", value)

## O'yinchi shahri — shahar bo'yicha reyting uchun.
var city: String:
	get: return str(_read("city", ""))
	set(value): _write("city", value)

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

# ——— Qahramon va o'yinchi statistikasi ———

## Tanlangan qahramon ID si.
var selected_hero: String:
	get: return str(_read("selected_hero", "hero_cube"))
	set(value): _write("selected_hero", value)

## O'yinchi unikal identifikatori ("Color-XXXXX").
var player_id: String:
	get:
		var pid := str(_read("player_id", ""))
		if pid.is_empty():
			pid = "Color-%05d" % (randi() % 90000 + 10000)
			_write("player_id", pid)
		return pid

var total_matches: int:
	get: return int(_read("total_matches", 0))

var total_kills: int:
	get: return int(_read("total_kills", 0))

var total_spheres: int:
	get: return int(_read("total_spheres", 0))

var total_upgrades: int:
	get: return int(_read("total_upgrades", 0))

var total_revives: int:
	get: return int(_read("total_revives", 0))

var total_countries_won: int:
	get: return int(_read("total_countries_won", 0))

var total_perfect_wins: int:
	get: return int(_read("total_perfect_wins", 0))

var daily_streak: int:
	get: return int(_read("daily_streak", 1))
	set(v): _write("daily_streak", v)

var total_city_conquest_coins: int:
	get: return int(_read("total_city_conquest_coins", 0))

var total_pickup_coins: int:
	get: return int(_read("total_pickup_coins", 0))

var total_cities_rewarded: int:
	get: return int(_read("total_cities_rewarded", 0))

var total_duplicates_prevented: int:
	get: return int(_read("total_duplicates_prevented", 0))

## Liga nomi (rekord va o'yinlar bo'yicha).
func league_name() -> String:
	var kills := total_kills
	var best := best_percent
	if best >= 100.0 or kills >= 300:
		return "leagueDiamond"
	if best >= 50.0 or kills >= 150:
		return "leagueGold"
	if best >= 25.0 or kills >= 50:
		return "leagueSilver"
	return "leagueBronze"

## Qahramonlar va profil uchun to'liq statistika lug'ati.
func stats_dict(daily_streak: int = 0) -> Dictionary:
	return {
		"matches": total_matches,
		"kills": total_kills,
		"spheres": total_spheres,
		"upgrades": total_upgrades,
		"revives": total_revives,
		"countries": total_countries_won,
		"perfect_wins": total_perfect_wins,
		"streak": daily_streak,
		"city_conquest_coins": total_city_conquest_coins,
		"pickup_coins": total_pickup_coins,
		"cities_rewarded": total_cities_rewarded,
		"duplicates_prevented": total_duplicates_prevented,
	}

## O'yin tugaganda statistikani yangilash.
func record_match_stats(kills: int, spheres: int, revived: bool, country_won: bool, is_perfect: bool) -> void:
	_write("total_matches", total_matches + 1)
	_write("total_kills", total_kills + kills)
	if spheres > 0:
		_write("total_spheres", total_spheres + spheres)
	if revived:
		_write("total_revives", total_revives + 1)
	if country_won:
		_write("total_countries_won", total_countries_won + 1)
	if is_perfect:
		_write("total_perfect_wins", total_perfect_wins + 1)

## Kuchaytirgich ishlatilganda sonini oshirish.
func record_upgrade_used(count: int = 1) -> void:
	_write("total_upgrades", total_upgrades + count)

## O'yin tugaganda shahar istilosi va tanga statistikasini saqlash (PHASE 6).
func record_economy_stats(conquest_coins: int, pickup_coins: int, cities_rewarded: int, duplicates_prevented: int = 0) -> void:
	if conquest_coins > 0:
		_write("total_city_conquest_coins", total_city_conquest_coins + conquest_coins)
	if pickup_coins > 0:
		_write("total_pickup_coins", total_pickup_coins + pickup_coins)
	if cities_rewarded > 0:
		_write("total_cities_rewarded", total_cities_rewarded + cities_rewarded)
	if duplicates_prevented > 0:
		_write("total_duplicates_prevented", total_duplicates_prevented + duplicates_prevented)

## Grafika sifati ("low" / "medium" / "high").
var graphics_quality: String:
	get:
		var q := str(_read("graphics_quality", "medium")).to_lower()
		if q in ["low", "medium", "high"]:
			return q
		return "medium"
	set(value):
		var v := value.to_lower()
		if v in ["low", "medium", "high"]:
			_write("graphics_quality", v)
		else:
			_write("graphics_quality", "medium")

