class_name AdMobManager
extends Node

## Reklama SDK si bilan **yagona** aloqa nuqtasi.
##
## ⚠️ Hozircha namuna: haqiqiy video o'rniga qisqa kutish. Godot
## uchun AdMob plagini qo'shilganda faqat shu fayl almashtiriladi —
## [AdManager] va o'yin kodi o'zgarmaydi.
##
## Ishlab chiqishda **faqat sinov** reklama ID lari ishlatiladi.
## Haqiqiy ID larni hech qachon kodga yozmang: ular do'konga
## chiqarishdan oldin [constant RELEASE_UNIT_IDS] ga qo'yiladi va
## o'sha fayl maxfiy saqlanadi.

## Google ning ochiq sinov bloklari — ularni bosish xavfsiz.
const TEST_UNIT_IDS := {
	"rewarded": "ca-app-pub-3940256099942544/5224354917",
	"interstitial": "ca-app-pub-3940256099942544/1033173712",
	"banner": "ca-app-pub-3940256099942544/6300978111",
}

## Do'konga chiqarishdan oldin to'ldiriladi.
const RELEASE_UNIT_IDS := {
	"rewarded": "", "interstitial": "", "banner": "",
}

## Namunadagi "video" shuncha davom etadi.
const FAKE_AD_SECONDS := 0.6

var _banner_on := false

## Shu qurilishda qaysi ID lar ishlatiladi.
##
## Nosozlik qidirish qurilishida har doim sinov ID lari — tasodifan
## haqiqiy reklama ko'rsatib, hisobni bloklab qo'ymaslik uchun.
static func unit_ids() -> Dictionary:
	if OS.is_debug_build():
		return TEST_UNIT_IDS
	# Haqiqiy ID lar to'ldirilmagan bo'lsa ham sinovga tushamiz —
	# bo'sh ID bilan SDK xato beradi va reklama umuman chiqmaydi.
	if str(RELEASE_UNIT_IDS["rewarded"]).is_empty():
		return TEST_UNIT_IDS
	return RELEASE_UNIT_IDS

## Mukofotli video. To'liq ko'rilsa `true`.
func play_rewarded() -> bool:
	await get_tree().create_timer(FAKE_AD_SECONDS).timeout
	return true

func play_interstitial() -> void:
	await get_tree().create_timer(FAKE_AD_SECONDS).timeout

func set_banner(on: bool) -> void:
	_banner_on = on

func banner_on() -> bool:
	return _banner_on
