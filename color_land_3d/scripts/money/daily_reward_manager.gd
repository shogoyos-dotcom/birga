class_name DailyRewardManager
extends Node

## Kunlik sovg'a va kirish ketma-ketligi (streak).
##
## Yetti kunlik aylanma; yettinchi kundan keyin boshidan boshlanadi.
## Bir kun o'tkazib yuborilsa ketma-ketlik birga qaytadi — lekin
## **hech narsa yo'qolmaydi**: olingan tanga ham, kosmetika ham
## qoladi. Shoshiltiradigan taymer yoki "oxirgi imkoniyat" yo'q.

const PATH := "user://daily.cfg"
const SECTION := "daily"

signal changed()

var _config := ConfigFile.new()
## Oxirgi olingan kun, "YYYY-MM-DD".
var _last := ""
## Hozirgi ketma-ketlik: 1..7 aylanma ichidagi kun.
var _day := 0
## Eng uzun ketma-ketlik — faqat ko'rsatish uchun.
var _best := 0

func _init() -> void:
	_config.load(PATH)
	_last = str(_config.get_value(SECTION, "last", ""))
	_day = int(_config.get_value(SECTION, "day", 0))
	_best = int(_config.get_value(SECTION, "best", 0))

## Bugungi sana, "YYYY-MM-DD".
static func today() -> String:
	return Time.get_date_string_from_system(true)

static func _yesterday_of(date: String) -> String:
	var unix := Time.get_unix_time_from_datetime_string(date + "T12:00:00")
	return Time.get_date_string_from_unix_time(int(unix) - 86400)

## Bugun olinganmi.
func claimed_today() -> bool:
	return _last == today()

## Hozirgi ketma-ketlik (0 — hali boshlanmagan).
func streak() -> int:
	return _day

func best_streak() -> int:
	return _best

## Bugun olinadigan kun raqami (1..7).
func next_day() -> int:
	if claimed_today():
		return _wrap(_day)
	if _last == _yesterday_of(today()):
		return _wrap(_day + 1)
	return 1

static func _wrap(day: int) -> int:
	var size := MonetizationConfig.DAILY_LOGIN.size()
	if size <= 0:
		return 1
	return ((day - 1) % size) + 1

## Bugungi mukofot miqdori.
func reward_for_today() -> int:
	return RewardManager.daily_login(next_day())

## Sovg'ani oladi. `doubled` — o'yinchi reklama ko'rgan bo'lsa.
##
## Natija: {ok, amount, day}. Bugun allaqachon olingan bo'lsa
## `ok` — `false` va hech narsa qo'shilmaydi.
func claim(doubled: bool = false) -> Dictionary:
	if claimed_today():
		return {"ok": false, "amount": 0, "day": _wrap(_day)}
	var day := next_day()
	var amount := RewardManager.daily_login(day)
	if doubled:
		amount = int(round(amount * MonetizationConfig.DAILY_REWARD_MULTIPLIER))
	# Sana bilan birga ID: bir kun ichida ikki marta olib bo'lmaydi
	# — ilova qayta ochilsa ham.
	_wallet().add_coins(amount, "daily", "daily-" + today())
	_day = day
	_last = today()
	_best = maxi(_best, _day)
	_save()
	_metrics().send(Analytics.DAILY_REWARD_CLAIMED,
		{"day": day, "amount": amount, "doubled": doubled})
	changed.emit()
	return {"ok": true, "amount": amount, "day": day}

func reset() -> void:
	_last = ""
	_day = 0
	_best = 0
	_save()

func _save() -> void:
	_config.set_value(SECTION, "last", _last)
	_config.set_value(SECTION, "day", _day)
	_config.set_value(SECTION, "best", _best)
	_config.save(PATH)

# ——— Qo'shni modullar ———
#
# Avtoyuklangan modullar bir-birini **kompilyatsiya paytida**
# ko'rmaydi (`--script` rejimida global nom hali yo'q), shuning
# uchun ular daraxtdan ish paytida olinadi.

func _wallet() -> CurrencyManager:
	return get_node("/root/Wallet") as CurrencyManager

func _metrics() -> Analytics:
	return get_node("/root/Metrics") as Analytics
