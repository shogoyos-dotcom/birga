class_name UpgradeManager
extends Node

const SavePaths := preload("res://scripts/app/save_paths.gd")

## Kuchaytirgichlar: har birining darajasi tanga evaziga oshadi.
##
## **Faqat tanga** — kristall emas. Tanga o'yinda topiladi, demak
## kuchaytirgich pulga emas, o'ynashga beriladi: "to'lab yutish"
## bo'lmaydi.
##
## Uchtasi bor:
##  * `fever` — o'yin boshida qisqa vaqt tezlik oshadi;
##  * `magnet` — yo'ldagi tangani uzoqdan tortadi;
##  * `passive` — har o'yin oxirida qo'shimcha tanga.

const PATH := "user://upgrades.cfg"
const SECTION := "upgrades"

const KINDS: PackedStringArray = ["fever", "magnet", "passive"]

## Eng yuqori daraja.
const MAX_LEVEL := 5
## Birinchi darajaning narxi va har darajada necha barobar oshishi.
const BASE_PRICE := 50
const PRICE_STEP := 1.8

signal changed()

var _file_path: String = ""
var _config := ConfigFile.new()
var _levels: Dictionary = {}

func _init(custom_path: String = "") -> void:
	if not custom_path.is_empty():
		_file_path = custom_path
	_load()

func get_file_path() -> String:
	if not _file_path.is_empty():
		return _file_path
	return SavePaths.path_for(SavePaths.UPGRADES)

func set_file_path(path: String) -> void:
	_file_path = path
	_load()

func _load() -> void:
	_config = ConfigFile.new()
	var path := get_file_path()
	if FileAccess.file_exists(path):
		_config.load(path)
	for kind: String in KINDS:
		_levels[kind] = clampi(
			int(_config.get_value(SECTION, kind, 0)), 0, MAX_LEVEL)

func level(kind: String) -> int:
	return int(_levels.get(kind, 0))

## Keyingi darajaning narxi. Eng yuqorida bo'lsa — 0.
func price(kind: String) -> int:
	var at := level(kind)
	if at >= MAX_LEVEL:
		return 0
	return int(round(BASE_PRICE * pow(PRICE_STEP, at)))

## Darajani oshiradi. Natija: "ok", "max" yoki "poor".
func buy(kind: String) -> String:
	if not KINDS.has(kind):
		return "none"
	if level(kind) >= MAX_LEVEL:
		return "max"
	var cost := price(kind)
	if not _wallet().remove_coins(cost, "upgrade:" + kind):
		return "poor"
	_levels[kind] = level(kind) + 1
	_save()
	_metrics().send(Analytics.UPGRADE_BOUGHT,
		{"kind": kind, "level": level(kind)})
	changed.emit()
	return "ok"

# ——— Ta'siri ———

## Tezlik kuchaytirgichi necha soniya ishlaydi (0 — yo'q).
func fever_seconds() -> float:
	var at := level("fever")
	return 0.0 if at == 0 else 2.0 + 1.5 * float(at)

## Fever paytidagi tezlik ko'paytirgichi.
const FEVER_SPEED := 1.35

## Tanga olinadigan radius (katak). Nol darajada — faqat ustidan
## yurganda.
func magnet_radius() -> float:
	return 1.1 + 0.55 * float(level("magnet"))

## O'yin oxirida qo'shiladigan tanga.
func passive_bonus() -> int:
	return 15 * level("passive")

func reset() -> void:
	for kind: String in KINDS:
		_levels[kind] = 0
	_save()

func _save() -> void:
	for kind: String in KINDS:
		_config.set_value(SECTION, kind, _levels[kind])
	var path := get_file_path()
	SavePaths.ensure_dir_exists(path.get_base_dir())
	_config.save(path)

# ——— Qo'shni modullar ———
#
# Avtoyuklangan modullar bir-birini kompilyatsiya paytida
# ko'rmaydi, shuning uchun daraxtdan ish paytida olinadi.

func _wallet() -> CurrencyManager:
	return get_node("/root/Wallet") as CurrencyManager

func _metrics() -> Analytics:
	return get_node("/root/Metrics") as Analytics
