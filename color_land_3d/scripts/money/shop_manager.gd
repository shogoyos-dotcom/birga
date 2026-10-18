class_name ShopManager
extends Node

const SavePaths := preload("res://scripts/app/save_paths.gd")

## Kosmetika do'koni.
##
## **Muhim qoida:** do'kondagi hech narsa o'yinga ta'sir qilmaydi —
## tezlik, to'qnashuv o'lchami, hudud egallash kuchi va botlarning
## xatti-harakati hamma uchun bir xil. Sotiladigani faqat ko'rinish.
##
## Mantiq interfeysdan ajratilgan: ekran faqat [method catalogue] ni
## o'qiydi va [method buy] ni chaqiradi.

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

const PATH := "user://shop.cfg"
const SECTION := "shop"

## Toifalar — do'kondagi bo'limlar.
const SKINS := "skins"
const TRAILS := "trails"
const EFFECTS := "effects"
const SPECIAL := "special"

signal changed()

## Katalog. `unlock` bo'sh bo'lmasa, element faqat shart
## bajarilganda sotuvga chiqadi.
const ITEMS: Array[Dictionary] = [
	# ——— Qahramon ko'rinishi ———
	{"id": "skin_classic", "cat": SKINS, "name": "skinClassic",
		"coins": 0, "gems": 0, "rarity": Rarity.COMMON, "unlock": ""},
	{"id": "skin_glow", "cat": SKINS, "name": "skinGlow",
		"coins": 400, "gems": 0, "rarity": Rarity.COMMON, "unlock": ""},
	{"id": "skin_frost", "cat": SKINS, "name": "skinFrost",
		"coins": 1200, "gems": 0, "rarity": Rarity.RARE, "unlock": ""},
	{"id": "skin_magma", "cat": SKINS, "name": "skinMagma",
		"coins": 3000, "gems": 0, "rarity": Rarity.EPIC, "unlock": ""},
	{"id": "skin_prism", "cat": SKINS, "name": "skinPrism",
		"coins": 0, "gems": 120, "rarity": Rarity.LEGENDARY, "unlock": ""},
	{"id": "skin_melon", "cat": SKINS, "name": "skinMelon",
		"coins": 700, "gems": 0, "rarity": Rarity.COMMON, "unlock": ""},
	{"id": "skin_orange", "cat": SKINS, "name": "skinOrange",
		"coins": 900, "gems": 0, "rarity": Rarity.COMMON, "unlock": ""},
	{"id": "skin_donut", "cat": SKINS, "name": "skinDonut",
		"coins": 1600, "gems": 0, "rarity": Rarity.RARE, "unlock": ""},
	{"id": "skin_forest", "cat": SKINS, "name": "skinForest",
		"coins": 2200, "gems": 0, "rarity": Rarity.RARE, "unlock": ""},
	{"id": "skin_galaxy", "cat": SKINS, "name": "skinGalaxy",
		"coins": 0, "gems": 150, "rarity": Rarity.LEGENDARY, "unlock": ""},
	# ——— Iz ———
	{"id": "trail_plain", "cat": TRAILS, "name": "trailPlain",
		"coins": 0, "gems": 0, "rarity": Rarity.COMMON, "unlock": ""},
	{"id": "trail_neon", "cat": TRAILS, "name": "trailNeon",
		"coins": 600, "gems": 0, "rarity": Rarity.COMMON, "unlock": ""},
	{"id": "trail_spark", "cat": TRAILS, "name": "trailSpark",
		"coins": 1800, "gems": 0, "rarity": Rarity.RARE, "unlock": ""},
	{"id": "trail_aurora", "cat": TRAILS, "name": "trailAurora",
		"coins": 0, "gems": 80, "rarity": Rarity.EPIC, "unlock": ""},
	# ——— Effekt ———
	{"id": "fx_none", "cat": EFFECTS, "name": "fxNone",
		"coins": 0, "gems": 0, "rarity": Rarity.COMMON, "unlock": ""},
	{"id": "fx_confetti", "cat": EFFECTS, "name": "fxConfetti",
		"coins": 900, "gems": 0, "rarity": Rarity.COMMON, "unlock": ""},
	{"id": "fx_shock", "cat": EFFECTS, "name": "fxShock",
		"coins": 2400, "gems": 0, "rarity": Rarity.RARE, "unlock": ""},
	# ——— Maxsus: pulga emas, natijaga ———
	{"id": "special_pioneer", "cat": SPECIAL, "name": "specialPioneer",
		"coins": 0, "gems": 0, "rarity": Rarity.EPIC, "unlock": "percent:20"},
	{"id": "special_hunter", "cat": SPECIAL, "name": "specialHunter",
		"coins": 0, "gems": 0, "rarity": Rarity.LEGENDARY, "unlock": "kills:25"},
]

var _file_path: String = ""
var _config := ConfigFile.new()
var _owned: Dictionary = {}
var _worn: Dictionary = {}

func _init(custom_path: String = "") -> void:
	if not custom_path.is_empty():
		_file_path = custom_path
	_load()

func get_file_path() -> String:
	if not _file_path.is_empty():
		return _file_path
	return SavePaths.path_for(SavePaths.SHOP)

func set_file_path(path: String) -> void:
	_file_path = path
	_load()

func _load() -> void:
	_config = ConfigFile.new()
	var path := get_file_path()
	if FileAccess.file_exists(path):
		_config.load(path)
	var owned: Variant = _config.get_value(SECTION, "owned", {})
	_owned = (owned as Dictionary).duplicate() if owned is Dictionary else {}
	var worn: Variant = _config.get_value(SECTION, "worn", {})
	_worn = (worn as Dictionary).duplicate() if worn is Dictionary else {}
	_apply_defaults()

## Bepul elementlar har doim ochiq va har bo'limda bittasi kiyilgan.
func _apply_defaults() -> void:
	for item: Dictionary in ITEMS:
		if int(item["coins"]) == 0 and int(item["gems"]) == 0 \
				and str(item["unlock"]).is_empty():
			_owned[item["id"]] = true
			if not _worn.has(item["cat"]):
				_worn[item["cat"]] = item["id"]

## Bo'limdagi elementlar.
func catalogue(category: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item: Dictionary in ITEMS:
		if str(item["cat"]) == category:
			out.append(item)
	return out

static func item_by_id(id: String) -> Dictionary:
	for item: Dictionary in ITEMS:
		if str(item["id"]) == id:
			return item
	return {}

func owns(id: String) -> bool:
	return bool(_owned.get(id, false))

func worn_in(category: String) -> String:
	return str(_worn.get(category, ""))

## Shart bajarilganmi. `best_percent` va `best_kills` — rekordlar.
static func unlocked_by(item: Dictionary, best_percent: float,
		best_kills: int) -> bool:
	var rule := str(item.get("unlock", ""))
	if rule.is_empty():
		return true
	var parts := rule.split(":")
	if parts.size() != 2:
		return true
	if parts[0] == "percent":
		return best_percent >= float(parts[1])
	if parts[0] == "kills":
		return best_kills >= int(parts[1])
	return true

## Sotib oladi. Natija: "ok", "owned", "locked", "poor" yoki "none".
func buy(id: String, best_percent: float = 0.0, best_kills: int = 0) -> String:
	var item := item_by_id(id)
	if item.is_empty():
		return "none"
	if owns(id):
		return "owned"
	if not unlocked_by(item, best_percent, best_kills):
		return "locked"
	var coins := int(item["coins"])
	var gems := int(item["gems"])
	if coins > 0:
		if not _wallet().remove_coins(coins, "shop:" + id):
			return "poor"
		_metrics().send(Analytics.COIN_SPENT, {"amount": coins, "item": id})
	elif gems > 0:
		if not _wallet().remove_gems(gems, "shop:" + id):
			return "poor"
		_metrics().send(Analytics.GEM_SPENT, {"amount": gems, "item": id})
	_owned[id] = true
	_worn[str(item["cat"])] = id
	_save()
	_metrics().send(Analytics.SKIN_PURCHASED, {"item": id})
	changed.emit()
	return "ok"

## Sotib olingan elementni kiyadi.
func wear(id: String) -> bool:
	if not owns(id):
		return false
	var item := item_by_id(id)
	if item.is_empty():
		return false
	_worn[str(item["cat"])] = id
	_save()
	changed.emit()
	return true

## Shart bajarilganda bepul ochiladi.
func unlock(id: String) -> bool:
	if owns(id):
		return false
	_owned[id] = true
	_save()
	_metrics().send(Analytics.SKIN_UNLOCKED, {"item": id})
	changed.emit()
	return true

func reset() -> void:
	_owned.clear()
	_worn.clear()
	_apply_defaults()
	_save()

func _save() -> void:
	_config.set_value(SECTION, "owned", _owned)
	_config.set_value(SECTION, "worn", _worn)
	var path := get_file_path()
	SavePaths.ensure_dir_exists(path.get_base_dir())
	_config.save(path)

# ——— Qo'shni modullar ———
#
# Avtoyuklangan modullar bir-birini **kompilyatsiya paytida**
# ko'rmaydi (`--script` rejimida global nom hali yo'q), shuning
# uchun ular daraxtdan ish paytida olinadi.

func _wallet() -> CurrencyManager:
	return get_node("/root/Wallet") as CurrencyManager

func _metrics() -> Analytics:
	return get_node("/root/Metrics") as Analytics
