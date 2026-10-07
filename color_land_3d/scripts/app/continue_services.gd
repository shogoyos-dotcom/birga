class_name ContinueServices
extends RefCounted

## O'limdan keyin davom etishning ikki yo'li: belet va mukofotli reklama.
##
## ⚠️ Bu yerdagi amalga oshirish — **namuna**. Haqiqiy reklama va
## xaridlar uchun quyidagilar kerak va ularni faqat ilova egasi qila
## oladi:
##
##  * **Reklama** — Google AdMob akkaunti, ilova ID si va "rewarded"
##    reklama bloki. Godot uchun AdMob plagini qo'shiladi,
##    `AndroidManifest` ga ilova ID si yoziladi va [show_rewarded]
##    o'rniga plagin chaqiriladi.
##  * **Xaridlar** — Play Console da "Managed product" lar yaratiladi
##    (`tickets_1`, `tickets_5`, `tickets_15`), Godot Play Billing
##    plagini qo'shiladi va [buy] o'rniga plagin chaqiriladi.
##
## Interfeys shuning uchun alohida turadi: plagin ulangach o'yin kodi
## o'zgarmaydi, faqat shu fayl almashtiriladi.

## Do'kondagi belet to'plamlari: {id, tickets, price, best}.
##
## Narx haqiqiy do'konda Play'dan keladi, namunada "—".
const PACKS: Array[Dictionary] = [
	{"id": "tickets_1", "tickets": 1, "price": "—", "best": false},
	{"id": "tickets_5", "tickets": 5, "price": "—", "best": true},
	{"id": "tickets_15", "tickets": 15, "price": "—", "best": false},
]

## Reklama ko'rsatilgandan keyin beriladigan belet.
const AD_REWARD := 1

## Reklama yuklanganmi. Haqiqiy xizmatda yuklash tugamaguncha `false`.
var ad_ready := true

func packs() -> Array[Dictionary]:
	return PACKS

static func pack_by_id(id: String) -> Dictionary:
	for pack: Dictionary in PACKS:
		if str(pack["id"]) == id:
			return pack
	return {}

## Xarid. Muvaffaqiyatli bo'lsa olingan belet sonini, aks holda 0
## qaytaradi (namunada xarid doim o'tadi).
func buy(pack_id: String) -> int:
	var pack := pack_by_id(pack_id)
	if pack.is_empty():
		return 0
	return int(pack["tickets"])

## Reklama. To'liq ko'rilsa beriladigan beletni, aks holda 0 qaytaradi.
##
## Namunada kutish yo'q: chaqirgan ekran o'zi qisqa kutish qo'yadi,
## shunda bu yerdagi mantiq headless testdan o'tadi.
func show_rewarded() -> int:
	if not ad_ready:
		return 0
	ad_ready = false
	return AD_REWARD

## Keyingi safar uchun oldindan yuklab qo'yadi.
func preload_ad() -> void:
	ad_ready = true
