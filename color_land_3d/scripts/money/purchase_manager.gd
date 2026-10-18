class_name PurchaseManager
extends Node

const SavePaths := preload("res://scripts/app/save_paths.gd")

## Haqiqiy pulga qilinadigan xaridlar.
##
## Hozircha bitta mahsulot bor: **NO ADS**. U majburiy va banner
## reklamani o'chiradi, lekin **mukofotli** reklamani qoldiradi —
## uni o'yinchi o'zi xohlab bosadi.
##
## ⚠️ Bu yerdagi amalga oshirish — namuna. Haqiqiy xarid uchun Play
## Billing plagini kerak; u ulangach faqat [method _ask_store] ichi
## almashtiriladi, qolgan kod o'zgarmaydi.

const PATH := "user://purchases.cfg"
const SECTION := "purchases"

## Mahsulot ID si — Play Console dagi nom bilan bir xil bo'lishi kerak.
const NO_ADS := "no_ads"

signal changed()

var _file_path: String = ""
var _config := ConfigFile.new()
var _owned: Dictionary = {}

func _init(custom_path: String = "") -> void:
	if not custom_path.is_empty():
		_file_path = custom_path
	_load()

func get_file_path() -> String:
	if not _file_path.is_empty():
		return _file_path
	return SavePaths.path_for(SavePaths.PURCHASES)

func set_file_path(path: String) -> void:
	_file_path = path
	_load()

func _load() -> void:
	_config = ConfigFile.new()
	var path := get_file_path()
	if FileAccess.file_exists(path):
		_config.load(path)
	var saved: Variant = _config.get_value(SECTION, "owned", {})
	_owned = (saved as Dictionary).duplicate() if saved is Dictionary else {}

func has_no_ads() -> bool:
	return bool(_owned.get(NO_ADS, false))

## Xarid. Muvaffaqiyatli bo'lsa `true`.
func purchase_no_ads() -> bool:
	if has_no_ads():
		return true
	if not _ask_store(NO_ADS):
		return false
	_grant(NO_ADS)
	_metrics().send(Analytics.NO_ADS_PURCHASE)
	return true

## Oldin qilingan xaridlarni qaytaradi. Qaytarilgan mahsulot sonini
## beradi. Yangi qurilmada yoki ilova qayta o'rnatilganda kerak.
func restore_purchases() -> int:
	var found := 0
	for id: String in _ask_store_owned():
		if not bool(_owned.get(id, false)):
			_grant(id)
			found += 1
	_metrics().send(Analytics.NO_ADS_RESTORE, {"restored": found})
	return found

## Sinov uchun: hamma xaridni o'chiradi.
func reset() -> void:
	_owned.clear()
	_save()
	changed.emit()

func _grant(id: String) -> void:
	_owned[id] = true
	_save()
	changed.emit()

func _save() -> void:
	_config.set_value(SECTION, "owned", _owned)
	var path := get_file_path()
	SavePaths.ensure_dir_exists(path.get_base_dir())
	_config.save(path)

# ——— Do'kon bilan aloqa (namuna) ———

## Haqiqiy do'konda bu yerda Play Billing chaqiriladi.
func _ask_store(_id: String) -> bool:
	return true

## Haqiqiy do'konda bu yerda o'yinchining xaridlari so'raladi.
func _ask_store_owned() -> PackedStringArray:
	return PackedStringArray()

# ——— Qo'shni modullar ———
#
# Avtoyuklangan modullar bir-birini **kompilyatsiya paytida**
# ko'rmaydi (`--script` rejimida global nom hali yo'q), shuning
# uchun ular daraxtdan ish paytida olinadi.

func _metrics() -> Analytics:
	return get_node("/root/Metrics") as Analytics
