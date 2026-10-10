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

const PATH := "user://wallet.cfg"
const SECTION := "wallet"
## Jurnalda saqlanadigan oxirgi yozuvlar soni.
const LOG_LIMIT := 60

var _config := ConfigFile.new()
var _coins := 0
var _gems := 0
## [{id, at, type, amount, currency}] — oxirgisi oxirida.
var _log: Array = []

func _init() -> void:
	# Avtoyuklanadigan tugun sifatida ham, testda `.new()` bilan ham
	# ishlashi kerak — shuning uchun `_ready` emas, `_init`.
	load_currency()

# ——— O'qish ———

func get_coins() -> int:
	return _coins

func get_gems() -> int:
	return _gems

## Jurnalning nusxasi (tashqaridan o'zgartirib bo'lmaydi).
func history() -> Array:
	return _log.duplicate(true)

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
func has_transaction(transaction_id: String) -> bool:
	if transaction_id.is_empty():
		return false
	for row: Dictionary in _log:
		if str(row.get("id", "")) == transaction_id:
			return true
	return false

# ——— Saqlash ———

func save_currency() -> void:
	_config.set_value(SECTION, "coins", _coins)
	_config.set_value(SECTION, "gems", _gems)
	_config.set_value(SECTION, "log", _log)
	_config.save(PATH)

func load_currency() -> void:
	_config = ConfigFile.new()
	_config.load(PATH)
	_coins = _clamp(int(_config.get_value(SECTION, "coins", 0)))
	_gems = _clamp(int(_config.get_value(SECTION, "gems", 0)))
	var saved: Variant = _config.get_value(SECTION, "log", [])
	_log = saved if saved is Array else []

## Hammasini boshidan boshlaydi — faqat sinov va "ma'lumotni
## tozalash" tugmasi uchun.
func reset() -> void:
	_coins = 0
	_gems = 0
	_log.clear()
	save_currency()

# ——— Ichki ———

static func _clamp(value: int) -> int:
	return clampi(value, 0, MonetizationConfig.MAX_BALANCE)

func _change(currency: String, amount: int, reward_type: String,
		transaction_id: String) -> int:
	if amount <= 0:
		return 0
	if has_transaction(transaction_id):
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
	_log.append({
		"id": transaction_id if not transaction_id.is_empty()
			else _new_id(reward_type),
		"at": int(Time.get_unix_time_from_system()),
		"type": reward_type,
		"amount": amount,
		"currency": currency,
	})
	if _log.size() > LOG_LIMIT:
		_log = _log.slice(_log.size() - LOG_LIMIT)

static func _new_id(reward_type: String) -> String:
	return "%s-%d-%d" % [reward_type,
		int(Time.get_unix_time_from_system()), randi() % 100000]
