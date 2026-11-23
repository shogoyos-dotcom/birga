class_name AdManager
extends Node

## Reklamani **boshqaradi** — ko'rsatmaydi.
##
## O'yin kodi hech qachon reklama SDK siga murojaat qilmaydi:
## hamma narsa shu modul orqali o'tadi, u esa [AdMobManager] ni
## chaqiradi. SDK almashtirilsa faqat o'sha fayl o'zgaradi.
##
## Qoidalar [MonetizationConfig] da va shu yerda:
##  * mukofotli reklama **hech qachon o'z-o'zidan** chiqmaydi —
##    o'yinchi tugmani bosishi shart;
##  * mukofot faqat video **to'liq ko'rilgani** tasdiqlangandan
##    keyin beriladi;
##  * reklama o'yin ketayotganda chiqmaydi;
##  * ikki reklama ketma-ket chiqmaydi — orada sovish vaqti bor;
##  * NO ADS olingan bo'lsa majburiy reklama va banner umuman yo'q.

enum Reward { DOUBLE_COINS, CONTINUE_RUN, BONUS_COINS, DAILY_REWARD_MULTIPLIER }

signal banner_changed(visible: bool)

var _last_ad_at := -1000.0
var _runs_since_interstitial := 0
var _banner_on := false
var _busy := false
var _mob: AdMobManager

func _init() -> void:
	_mob = AdMobManager.new()

func _ready() -> void:
	add_child(_mob)

# ——— Mukofotli reklama ———

## Mukofotli reklamani ko'rsatadi va natijani qaytaradi:
## {ok: bool, reward: Reward, error: String}.
##
## `ok` faqat video oxirigacha ko'rilganda `true` bo'ladi. Xato
## bo'lsa o'yinchidan hech narsa olinmaydi.
func show_rewarded(reward: Reward) -> Dictionary:
	_metrics().send(Analytics.AD_REWARD_REQUESTED, {"reward": reward})
	if not MonetizationConfig.REWARDED_ENABLED:
		return _failed(reward, "adNotReady")
	if _busy:
		return _failed(reward, "adNotReady")
	_busy = true
	var done: bool = await _mob.play_rewarded()
	_busy = false
	if not done:
		return _failed(reward, "adNotReady")
	_last_ad_at = _now()
	_metrics().send(Analytics.AD_REWARD_COMPLETED, {"reward": reward})
	return {"ok": true, "reward": reward, "error": ""}

func _failed(reward: Reward, error: String) -> Dictionary:
	_metrics().send(Analytics.AD_REWARD_FAILED, {"reward": reward})
	return {"ok": false, "reward": reward, "error": error}

# ——— Majburiy reklama ———

## Har o'yin tugaganda chaqiriladi.
func note_run_finished() -> void:
	_runs_since_interstitial += 1

## Majburiy reklama hozir chiqsa bo'ladimi.
func can_show_interstitial() -> bool:
	if not MonetizationConfig.INTERSTITIAL_ENABLED:
		return false
	if _purchases().has_no_ads():
		return false
	if _busy:
		return false
	if _runs_since_interstitial < MonetizationConfig.INTERSTITIAL_COOLDOWN_RUNS:
		return false
	return _now() - _last_ad_at >= MonetizationConfig.AD_COOLDOWN_SECONDS

## Shart bajarilsa majburiy reklamani ko'rsatadi. Ko'rsatilgan
## bo'lsa `true`.
func show_interstitial() -> bool:
	if not can_show_interstitial():
		return false
	_busy = true
	await _mob.play_interstitial()
	_busy = false
	_runs_since_interstitial = 0
	_last_ad_at = _now()
	_metrics().send(Analytics.INTERSTITIAL_SHOWN)
	return true

# ——— Banner ———

## Bannerni ko'rsatadi yoki yashiradi. O'yin ekranida hech qachon
## chaqirilmaydi — menyu, do'kon va sozlamalarda.
func show_banner(on: bool) -> void:
	var allowed: bool = on and MonetizationConfig.BANNER_ENABLED \
		and not _purchases().has_no_ads()
	if allowed == _banner_on:
		return
	_banner_on = allowed
	_mob.set_banner(allowed)
	banner_changed.emit(allowed)
	if allowed:
		_metrics().send(Analytics.BANNER_SHOWN)

func banner_visible() -> bool:
	return _banner_on

static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

# ——— Qo'shni modullar ———
#
# Avtoyuklangan modullar bir-birini **kompilyatsiya paytida**
# ko'rmaydi (`--script` rejimida global nom hali yo'q), shuning
# uchun ular daraxtdan ish paytida olinadi.

func _metrics() -> Analytics:
	return get_node("/root/Metrics") as Analytics

func _purchases() -> PurchaseManager:
	return get_node("/root/Purchases") as PurchaseManager
