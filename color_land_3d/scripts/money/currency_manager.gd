class_name CurrencyManager
extends Node

const SavePaths := preload("res://scripts/app/save_paths.gd")

## Ikki valyuta: **tanga** (bepul) va **gem** (premium).
##
## Faqat hisob yuritadi — o'yin qoidalariga ham, interfeysga ham
## bog'liq emas. `user://wallet.cfg` ga saqlanadi (sozlamalardan
## alohida fayl: sozlama o'chirilsa ham pul yo'qolmasin).
##
## Himoya:
##  * balans hech qachon manfiy bo'lmaydi;
##  * [constant MonetizationConfig.MAX_BALANCE] dan oshmaydi;
##  * har o'zgarish jurnalga yoziladi (id, vaqt, tur, miqdor);
##  * bir xil `transaction_id` ikki marta qabul qilinmaydi — shunda
##    kunlik mukofot yoki reklama mukofoti takror berilmaydi.
##  * tranzaksiya identifikatorlari doimiy (persistent) saqlanadi
##    (UI jurnalida 60 ta ko'rinsa ham, o'tgan tranzaksiyalar alohida saqlanadi);
##  * avtomatlashtirilgan testlar vaqtida haqiqiy o'yinchi balansi
##    alohida test fayliga yo'naltirilib to'liq himoyalanadi.

const DEFAULT_PATH := "user://wallet.cfg"
const TEST_PATH := "user://test_sandbox/wallet.cfg"
const PATH := DEFAULT_PATH
const SECTION := "wallet"
## Jurnalda saqlanadigan oxirgi yozuvlar soni (UI display).
const LOG_LIMIT := 60
## Tranzaksiyalarni xavfsiz tozalash chegarasi (faqat eskirganlari o'chiriladi).
const MAX_PROCESSED_TX := 2000

static var default_file_path: String = ""
static var is_test_mode: bool = false

var _file_path: String = ""
var _config := ConfigFile.new()
var _coins := 0
var _gems := 0
## [{id, at, type, amount, currency}] — oxirgisi oxirida (UI uchun).
var _log: Array = []
## Tranzaksiyalar dublikatini oldini olish uchun doimiy lug'at: id -> timestamp
var _processed_tx: Dictionary = {}

func _init(custom_path: String = "") -> void:
	if not custom_path.is_empty():
		_file_path = custom_path
	elif not default_file_path.is_empty():
		_file_path = default_file_path
	else:
		_file_path = SavePaths.path_for(SavePaths.WALLET)
	load_currency()

## Test rejimi: barcha yangi va mavjud hamyonlarni test muhitiga yo'naltiradi
static func set_test_mode(enabled: bool, test_path: String = "") -> void:
	is_test_mode = enabled
	if not test_path.is_empty():
		default_file_path = test_path
	elif enabled:
		default_file_path = SavePaths.path_for(SavePaths.WALLET)
	else:
		default_file_path = ""
	SavePaths.set_test_mode(enabled)

func get_file_path() -> String:
	if not _file_path.is_empty():
		return _file_path
	if not default_file_path.is_empty():
		return default_file_path
	return SavePaths.path_for(SavePaths.WALLET)

func set_file_path(path: String) -> void:
	_file_path = path
	load_currency()

# ——— O'qish ———

func get_coins() -> int:
	return _coins

func get_gems() -> int:
	return _gems

## Jurnalning nusxasi (tashqaridan o'zgartirib bo'lmaydi).
func history() -> Array:
	return _log.duplicate(true)

## Qayta ishlangan barcha tranzaksiya ID lar soni
func processed_transactions_count() -> int:
	return _processed_tx.size()

# ——— Yozish ———

## Tanga qo'shadi. Haqiqatda qo'shilgan miqdorni qaytaradi.
##
## `transaction_id` berilsa va u allaqachon ishlatilgan bo'lsa,
## hech narsa qo'shilmaydi va 0 qaytadi.
func add_coins(amount: int, reward_type: String = "generic",
		transaction_id: String = "") -> int:
	return _change("coins", amount, reward_type, transaction_id)

## Tanga yechadi. Yetarli bo'lmasa hech narsa yechilmaydi va
## `false` qaytadi.
func remove_coins(amount: int, reason: String = "spend") -> bool:
	return _spend("coins", amount, reason)

func add_gems(amount: int, reward_type: String = "generic",
		transaction_id: String = "") -> int:
	return _change("gems", amount, reward_type, transaction_id)

func remove_gems(amount: int, reason: String = "spend") -> bool:
	return _spend("gems", amount, reason)

## Shu id bilan mukofot allaqachon berilganmi.
## 60 tadan oshib ketgan eski tranzaksiyalar ham _processed_tx da eslab qolinadi.
func has_transaction(transaction_id: String) -> bool:
	if transaction_id.is_empty():
		return false
	if _processed_tx.has(transaction_id):
		return true
	for row: Dictionary in _log:
		if str(row.get("id", "")) == transaction_id:
			return true
	return false

# ——— Saqlash ———

func save_currency() -> bool:
	_config.set_value(SECTION, "coins", _coins)
	_config.set_value(SECTION, "gems", _gems)
	_config.set_value(SECTION, "log", _log)
	_config.set_value(SECTION, "processed_tx", _processed_tx)
	var path := get_file_path()
	SavePaths.ensure_dir_exists(path.get_base_dir())
	var err := _config.save(path)
	if err != OK:
		printerr("Hamyon saqlashda xatolik: ", err, " fayl: ", path)
		return false
	return true

func load_currency() -> void:
	_config = ConfigFile.new()
	var path := get_file_path()
	if not FileAccess.file_exists(path):
		_coins = 0
		_gems = 0
		_log.clear()
		_processed_tx.clear()
		return
	_config.load(path)
	_coins = _clamp(int(_config.get_value(SECTION, "coins", 0)))
	_gems = _clamp(int(_config.get_value(SECTION, "gems", 0)))
	var saved: Variant = _config.get_value(SECTION, "log", [])
	_log = saved if saved is Array else []

	# Tranzaksiyalar lug'atini yuklash
	_processed_tx.clear()
	var saved_tx: Variant = _config.get_value(SECTION, "processed_tx", {})
	if saved_tx is Dictionary:
		_processed_tx = (saved_tx as Dictionary).duplicate()
	elif saved_tx is Array:
		for id in saved_tx:
			_processed_tx[str(id)] = int(Time.get_unix_time_from_system())

	# Jurnaldagi mavjud ID larni ham qo'shib qo'yamiz (orqaga moslik)
	for row in _log:
		if row is Dictionary:
			var tid: String = str(row.get("id", ""))
			if not tid.is_empty() and not _processed_tx.has(tid):
				_processed_tx[tid] = int(row.get("at", Time.get_unix_time_from_system()))

## Hammasini boshidan boshlaydi — faqat sinov va "ma'lumotni
## tozalash" tugmasi uchun. Joriy faylga saqlaydi.
func reset() -> void:
	_coins = 0
	_gems = 0
	_log.clear()
	_processed_tx.clear()
	save_currency()

# ——— Ichki ———

static func _clamp(value: int) -> int:
	return clampi(value, 0, MonetizationConfig.MAX_BALANCE)

func _change(currency: String, amount: int, reward_type: String,
		transaction_id: String) -> int:
	if amount <= 0:
		return 0
	if not transaction_id.is_empty() and has_transaction(transaction_id):
		# Takroriy mukofot: rad etiladi, balans o'zgarmaydi.
		return 0
	var before := _coins if currency == "coins" else _gems
	var after := _clamp(before + amount)
	var gained := after - before
	if currency == "coins":
		_coins = after
	else:
		_gems = after
	_write_log(transaction_id, reward_type, gained, currency)
	var ok := save_currency()
	if not ok:
		printerr("Ogohlantirish: hamyon o'zgarishi diskka saqlanmadi!")
	return gained

func _spend(currency: String, amount: int, reason: String) -> bool:
	if amount <= 0:
		return false
	var before := _coins if currency == "coins" else _gems
	if before < amount:
		return false
	if currency == "coins":
		_coins = before - amount
	else:
		_gems = before - amount
	_write_log("", reason, -amount, currency)
	save_currency()
	return true

func _write_log(transaction_id: String, reward_type: String, amount: int,
		currency: String) -> void:
	var now := int(Time.get_unix_time_from_system())
	var tx_key := transaction_id if not transaction_id.is_empty() else _new_id(reward_type)
	if not transaction_id.is_empty():
		_processed_tx[transaction_id] = now
		_prune_processed_tx()

	_log.append({
		"id": tx_key,
		"at": now,
		"type": reward_type,
		"amount": amount,
		"currency": currency,
	})
	if _log.size() > LOG_LIMIT:
		_log = _log.slice(_log.size() - LOG_LIMIT)

## Tranzaksiya identifikatorining munosiblik muddati tugaganligini aniqlaydi.
## Faqatgina qayta da'vo qilinishi 100% imkonsiz bo'lgan eskirgan tranzaksiyalar tozalanishi mumkin.
static func is_transaction_expired(tx_id: String, tx_time: int, now: int) -> bool:
	if tx_id.begins_with("daily-"):
		# Kunlik kirish mukofoti: 7 kundan keyin qayta talab qilib bo'lmaydi (Daily.claim faqat bugunni so'raydi)
		return (now - tx_time) > (7 * 86400)
	elif tx_id.begins_with("mission-"):
		# Kunlik topshiriq: 7 kundan keyin muddati tugagan
		return (now - tx_time) > (7 * 86400)
	elif tx_id.begins_with("conquest_"):
		# O'yin istilosi: yakunlangan match tranzaksiyalari 30 kundan keyin eskiradi
		return (now - tx_time) > (30 * 86400)
	elif tx_id.begins_with("promo_") or tx_id.begins_with("lifetime_"):
		# Bir martalik doimiy mukofotlar: HECH QACHON O'CHIRILMAYDI
		return false
	# Noma'lum yoki umumiy tranzaksiyalar dublikatdan himoya uchun saqlanadi
	return false

## Tranzaksiyalar soni MAX_PROCESSED_TX dan oshsa, FAQAT eskirganlarini xavfsiz tozalash.
## Hech qanday faol yoki bir martalik mukofot ID si yo'qotilmaydi.
func _prune_processed_tx() -> void:
	if _processed_tx.size() <= MAX_PROCESSED_TX:
		return
	var now := int(Time.get_unix_time_from_system())
	var expired_keys: Array[String] = []
	for k in _processed_tx:
		var t_at := int(_processed_tx[k])
		if is_transaction_expired(str(k), t_at, now):
			expired_keys.append(str(k))

	for k in expired_keys:
		_processed_tx.erase(k)

static func _new_id(reward_type: String) -> String:
	return "%s-%d-%d" % [reward_type,
		int(Time.get_unix_time_from_system()), randi() % 100000]
