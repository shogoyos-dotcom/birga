class_name MonetizationConfig
extends RefCounted

## Pul ishlash tizimining **hamma** sozlamasi shu yerda.
##
## Qoida: bu qiymatlar loyihaning boshqa joyida takrorlanmaydi.
## Balansni o'zgartirish uchun faqat shu fayl tahrirlanadi — o'yin
## mantig'iga tegilmaydi.

# ——— Reklama ———

const INTERSTITIAL_ENABLED := false
const BANNER_ENABLED := false
const REWARDED_ENABLED := true

## Majburiy reklama orasidagi eng kam o'yin soni.
const INTERSTITIAL_COOLDOWN_RUNS := 3
## Ikki reklama orasidagi eng kam vaqt (soniya).
const AD_COOLDOWN_SECONDS := 90.0

const DOUBLE_COIN_MULTIPLIER := 2.0
const DAILY_REWARD_MULTIPLIER := 2.0

# ——— O'yindan tushadigan tanga ———
#
# Hamma qiymat "kamtarona" tanlangan: bir o'yin odatda 60–250 tanga
# beradi, eng arzon kosmetika esa 400 tanga turadi. Shunda do'kon
# bir-ikki o'yindan keyin ochiladi, lekin qadrini yo'qotmaydi.

## Har o'yin uchun asos (omon qolgan vaqtga qarab).
const RUN_MIN := 10
const RUN_MAX := 100
## Shu soniyada RUN_MAX ga yetadi (PHASE 3: 8-12 daqiqalik o'yin sur'ati).
const RUN_FULL_SECONDS := 600.0

## Hudud uchun: egallangan foizga qarab.
const TERRITORY_MIN := 10
const TERRITORY_MAX := 500
## Shu foizda TERRITORY_MAX ga yetadi.
const TERRITORY_FULL_PERCENT := 40.0

## Bitta raqib uchun; ketma-ket yiqitilsa bir oz ko'proq.
const KILL_MIN := 25
const KILL_MAX := 150
const KILL_FULL_COUNT := 8

## Kunlik topshiriq va daraja.
const DAILY_CHALLENGE_MIN := 500
const DAILY_CHALLENGE_MAX := 2000
const LEVEL_UP := 500

## Kunlik kirish: 7 kunlik aylanma.
const DAILY_LOGIN: PackedInt32Array = [100, 150, 200, 300, 500, 750, 1000]

# ——— Xaritadagi tangalar ———

## Shahar ustidagi tanganing qiymati aholi soniga qarab shu
## oraliqda bo'ladi.
const CITY_COIN_MIN := 1
const CITY_COIN_MAX := 25
## Olingan tanga shuncha soniyadan keyin shaharda qayta paydo
## bo'ladi. Shu sabab xaritaning bir joyida uzoq turish foydasiz:
## tanga qaytguncha boshqa yerdan yer egallash kerak.
const CITY_COIN_RESPAWN := 30.0

# ——— Shahar istilosi mukofotlari (PHASE 6) ———

## Shahar toifasi bo'yicha beriladigan rasmiy istilo mukofotlari
## Kichik = 50, O'rta = 200, Katta = 500
const CITY_CAPTURE_REWARDS := {
	0: 50,  # Category.SMALL
	1: 200, # Category.MEDIUM
	2: 500, # Category.LARGE
}

static func get_city_capture_reward(category: int) -> int:
	match category:
		1: return 200
		2: return 500
		_: return 50

## Shahar toifalari va ulardan olinadigan haqiqiy tangalar (PHASE 6 va UI uchun markaziy konfiguratsiya)
const CITY_REWARDS := {
	"small": {
		"title": "Small City",
		"desc": "Aholisi 200k gacha shaharchalar",
		"coins": 50,
		"icon": "village"
	},
	"medium": {
		"title": "Medium City",
		"desc": "Aholisi 200k - 1M o'rta shaharlar",
		"coins": 200,
		"icon": "city"
	},
	"large": {
		"title": "Large City",
		"desc": "Aholisi 1M+ poytaxt va megapolislar",
		"coins": 500,
		"icon": "metropolis"
	}
}

# ——— Chegaralar ———

## Bitta o'yindan olinadigan eng ko'p tanga — xatodan himoya.
const RUN_COIN_CAP := 3000
## Hamyondagi eng ko'p qiymat.
const MAX_BALANCE := 99_999_999
