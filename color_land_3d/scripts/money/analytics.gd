class_name Analytics
extends Node

## O'yin hodisalarini qayd qiladi.
##
## Shaxsiy ma'lumot yig'ilmaydi: faqat hodisa nomi va sonlar.
## Hozircha hodisalar xotirada turadi va nosozlik qidirishda
## bosiladi — tashqi xizmatga yuborilmaydi. Xizmat ulanganda faqat
## [method send] ichi almashtiriladi, chaqiruvchilar o'zgarmaydi.

## Xotirada saqlanadigan oxirgi hodisalar soni.
const LIMIT := 120

## Interfeys va pul modullari ishlatadigan hodisa nomlari.
const AD_REWARD_REQUESTED := "ad_reward_requested"
const AD_REWARD_COMPLETED := "ad_reward_completed"
const AD_REWARD_FAILED := "ad_reward_failed"
const INTERSTITIAL_SHOWN := "interstitial_shown"
const BANNER_SHOWN := "banner_shown"
const NO_ADS_PURCHASE := "no_ads_purchase"
const NO_ADS_RESTORE := "no_ads_restore"
const COIN_EARNED := "coin_earned"
const COIN_SPENT := "coin_spent"
const GEM_EARNED := "gem_earned"
const GEM_SPENT := "gem_spent"
const SKIN_PURCHASED := "skin_purchased"
const SKIN_UNLOCKED := "skin_unlocked"
const DAILY_REWARD_CLAIMED := "daily_reward_claimed"
const MISSION_COMPLETED := "mission_completed"

var _events: Array = []

## Hodisani qayd qiladi. `data` — faqat sonlar va qisqa kalitlar.
func send(name: String, data: Dictionary = {}) -> void:
	_events.append({
		"name": name,
		"at": int(Time.get_unix_time_from_system()),
		"data": data,
	})
	if _events.size() > LIMIT:
		_events = _events.slice(_events.size() - LIMIT)
	if OS.is_debug_build():
		print("[analytics] %s %s" % [name, data])

## Qayd qilingan hodisalar (sinov va nosozlik qidirish uchun).
func events() -> Array:
	return _events.duplicate(true)

func count_of(name: String) -> int:
	var n := 0
	for e: Dictionary in _events:
		if str(e["name"]) == name:
			n += 1
	return n

func clear() -> void:
	_events.clear()
