class_name Cosmetics
extends RefCounted

## Do'kondagi elementlarning **ko'rinish** tavsifi.
##
## Bu jadvalda faqat chizish parametrlari bor: yaltirashi, porlashi,
## izning yorqinligi, effektning zarrachalari. Tezlik, to'qnashuv
## o'lchami, hudud egallash kuchi va botlarning aqli bu yerga
## umuman tegmaydi — shuning uchun kiyimni almashtirish o'yin
## natijasini o'zgartira olmaydi.
##
## Rang ham sotilmaydi: shar va iz doim o'yinchining **o'z rangida**
## qoladi, pardoz esa shu rang ustiga qo'yiladi. Aks holda maydonda
## kim kimligi bilinmay qolardi.

## Bosh pardozi.
##
## `mix` va `blend` — pardozning o'z rangi va u o'yinchi rangiga
## qanchalik aralashishi. Aralashma kichik: shar baribir
## o'yinchining rangida qoladi, aks holda maydonda kim kimligi
## bilinmay qolardi. `metal` va `rough` — yaltirashi, `glow` esa
## o'z nuri.
const SKINS := {
	"skin_classic": {
		"mix": Color("ffffff"), "blend": 0.00, "metal": 0.00,
		"rough": 0.60, "glow": 0.00,
	},
	"skin_glow": {
		"mix": Color("ffffff"), "blend": 0.12, "metal": 0.00,
		"rough": 0.40, "glow": 1.30,
	},
	"skin_frost": {
		"mix": Color("c6efff"), "blend": 0.38, "metal": 0.45,
		"rough": 0.08, "glow": 0.25,
	},
	"skin_magma": {
		"mix": Color("ff6a12"), "blend": 0.45, "metal": 0.00,
		"rough": 0.85, "glow": 1.00,
	},
	"skin_prism": {
		"mix": Color("ffffff"), "blend": 0.16, "metal": 1.00,
		"rough": 0.05, "glow": 0.45,
	},
}

## Pardoz qo'yilgan shar rangi.
static func skin_color(base: Color, look: Dictionary) -> Color:
	return base.lerp(look["mix"], float(look["blend"]))

## Iz ko'rinishi.
##
## `bright` — rangning kuchi, `fade` izning dumi qanchalik
## shaffoflashishi, `shift` esa bo'ylab rang tovlanishi (rang
## doirasi bo'yicha, 0..1).
##
## Qo'shuvchi (additive) aralashma ishlatilmaydi: "Color Lands"
## maydonining quruqligi deyarli oq, oqqa yorug'lik qo'shib
## bo'lmaydi — iz ko'rinmay qolardi.
const TRAILS := {
	"trail_plain": {"bright": 1.00, "fade": 0.00, "shift": 0.00},
	"trail_neon": {"bright": 1.50, "fade": 0.00, "shift": 0.00},
	"trail_spark": {"bright": 1.30, "fade": 0.80, "shift": 0.00},
	"trail_aurora": {"bright": 1.20, "fade": 0.30, "shift": 0.55},
}

## Hudud egallaganda chiqadigan effekt.
##
## `count` — zarracha soni, `ring` halqa bo'lib tarqalishi,
## `fly` zarrachaning uchish tezligi, `life` umri (soniya).
## Nomi ataylab `speed` emas: o'yinchi tezligi bilan adashmasin.
const EFFECTS := {
	"fx_none": {"count": 0, "ring": false, "fly": 0.0, "life": 0.0},
	"fx_confetti": {"count": 26, "ring": false, "fly": 7.0, "life": 0.9},
	"fx_shock": {"count": 40, "ring": true, "fly": 12.0, "life": 0.55},
}

## Maxsus nishonlar — ular bosh ustidagi halqa bilan ko'rinadi.
const SPECIAL := {
	"special_pioneer": {"halo": Color("45e8ff")},
	"special_hunter": {"halo": Color("ffd23f")},
}

static func skin(id: String) -> Dictionary:
	return SKINS.get(id, SKINS["skin_classic"])

static func trail(id: String) -> Dictionary:
	return TRAILS.get(id, TRAILS["trail_plain"])

static func effect(id: String) -> Dictionary:
	return EFFECTS.get(id, EFFECTS["fx_none"])

## Nishon rangi; nishon kiyilmagan bo'lsa — shaffof.
static func halo(id: String) -> Color:
	var row: Variant = SPECIAL.get(id, null)
	return (row as Dictionary)["halo"] if row != null else Color(0, 0, 0, 0)

## Izning `t` nuqtasidagi rangi (`t`: dumda 0, boshda 1).
static func trail_color(base: Color, look: Dictionary, t: float) -> Color:
	var c := base
	var shift := float(look["shift"])
	if shift > 0.0:
		c = Color.from_hsv(fposmod(c.h + shift * (1.0 - t), 1.0), c.s, c.v)
	c = Color(c.r, c.g, c.b) * float(look["bright"])
	c.a = lerpf(1.0 - float(look["fade"]), 1.0, t)
	return c
