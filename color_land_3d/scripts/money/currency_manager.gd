class_name CurrencyManager
extends Node

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
const TEST_PATH := "user://test_wallet.cfg"
const PATH := DEFAULT_PATH
const SECTION := "wallet"
## Jurnalda saqlanadigan oxirgi yozuvlar soni (UI display).
const LOG_LIMIT := 60
## Xotirada va faylda saqlanadigan maksimal tranzaksiyalar ID soni.
const MAX_PROCESSED_TX := 2000

static var default_file_path: String = DEFAULT_PATH
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
	# Avtoyuklanadigan tugun sifatida ham, testda `.new()` bilan ham
	# ishlashi kerak — shuning uchun `_ready` emas, `_init`.
	if not custom_path.is_empty():
		_file_path = custom_path
	elif is_test_mode:
		_file_path = TEST_PATH
	else:
		_file_path = default_file_path
	load_currency()

## Test rejimi: barcha yangi va mavjud hamyonlarni test_wallet.cfg ga yo'naltiradi
static func set_test_mode(enabled: bool, test_path: String = TEST_PATH) -> void:
	is_test_mode = enabled
	if enabled:
		default_file_path = test_path
	else:
		default_file_path = DEFAULT_PATH

func get_file_path() -> String:
	if not _file_path.is_empty():
		return _file_path
	return TEST_PATH if is_test_mode else default_file_path

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

func save_currency() -> void:
	_config.set_value(SECTION, "coins", _coins)
	_config.set_value(SECTION, "gems", _gems)
	_config.set_value(SECTION, "log", _log)
	_config.set_value(SECTION, "processed_tx", _processed_tx)
	_config.save(get_file_path())

func load_currency() -> void:
	_config = ConfigFile.new()
	_config.load(get_file_path())
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
		# Takroriy mukofot: jim o'tkazib yuboriladi.
		return 0
	var before := _coins if currency == "coins" else _gems
	var after := _clamp(before + amount)
	var gained := after - before
	if currency == "coins":
		_coins = after
	else:
		_gems = after
	_write_log(transaction_id, reward_type, gained, currency)
	save_currency()
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

## Tranzaksiyalar haddan tashqari ko'payib ketsa, eng eskilarini xavfsiz tozalash.
func _prune_processed_tx() -> void:
	if _processed_tx.size() <= MAX_PROCESSED_TX:
		return
	# Saralab eng yangi 1500 tasini saqlab qolamiz
	var entries: Array = []
	for k in _processed_tx:
		entries.append({"id": k, "at": int(_processed_tx[k])})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["at"]) < int(b["at"]))
	var remove_count := _processed_tx.size() - 1500
	for i in range(mini(remove_count, entries.size())):
		_processed_tx.erase(entries[i]["id"])

static func _new_id(reward_type: String) -> String:
	return "%s-%d-%d" % [reward_type,
		int(Time.get_unix_time_from_system()), randi() % 100000]
