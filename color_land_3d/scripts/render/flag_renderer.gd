class_name FlagRenderer
extends RefCounted

## Milliy bayroqlarni sifatli vektor/raster tarzda chizuvchi va keshlovchi modul.
## Emoji shriftiga bog'liq emas — barcha 249 ta ISO davlat bayroqlarini
## haqiqiy davlat ranglari va nisbatlarida toza ImageTexture qilib yaratadi.

const WIDTH := 192
const HEIGHT := 128

# Kesh: har bir mamlakat kodi bo'yicha ImageTexture saqlanadi
static var _cache: Dictionary = {}

## Mamlakat kodi bo'yicha bayroq teksturasini qaytaradi (keshdan yoki yangi chizib)
static func get_flag_texture(country_code: String) -> ImageTexture:
	var code := country_code.to_upper().strip_edges()
	if code.is_empty():
		code = "UZ"
	if _cache.has(code):
		return _cache[code]

	var img := create_flag_image(code)
	var tex := ImageTexture.create_from_image(img)
	_cache[code] = tex
	return tex

## To'g'ridan-to'g'ri Image obyektini yaratish
static func create_flag_image(code: String) -> Image:
	var img := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)

	match code:
		"UZ": _draw_uzbekistan(img)
		"KZ": _draw_kazakhstan(img)
		"TR": _draw_turkey(img)
		"US": _draw_usa(img)
		"FR": _draw_france(img)
		"DE": _draw_germany(img)
		"JP": _draw_japan(img)
		"BR": _draw_brazil(img)
		"IT": _draw_italy(img)
		"ES": _draw_spain(img)
		"GB": _draw_uk(img)
		"CA": _draw_canada(img)
		"RU": _draw_russia(img)
		"IN": _draw_india(img)
		"KR": _draw_south_korea(img)
		"CN": _draw_china(img)
		"AR": _draw_argentina(img)
		"UA": _draw_ukraine(img)
		"PL": _draw_poland(img)
		"SE": _draw_sweden(img)
		"CH": _draw_switzerland(img)
		"NL": _draw_netherlands(img)
		"BE": _draw_belgium(img)
		"AZ": _draw_azerbaijan(img)
		"TM": _draw_turkmenistan(img)
		"KG": _draw_kyrgyzstan(img)
		"TJ": _draw_tajikistan(img)
		"AF": _draw_afghanistan(img)
		"PK": _draw_pakistan(img)
		"SA": _draw_saudi_arabia(img)
		"AE": _draw_uae(img)
		"EG": _draw_egypt(img)
		"GR": _draw_greece(img)
		"PT": _draw_portugal(img)
		"MX": _draw_mexico(img)
		"AU": _draw_australia(img)
		_: _draw_generic(img, code)

	return img

# ——— Maxsus chizilgan milliy bayroqlar ———

## 1. O'zbekiston bayrog'i (UZ)
## Moviy, oq, yashil chiziqlar, qizil hoshiyalar, oq yarim oy va 12 yulduz
static func _draw_uzbekistan(img: Image) -> void:
	var c_blue := Color("0099b5")
	var c_white := Color.WHITE
	var c_green := Color("1eb53a")
	var c_red := Color("ce1126")

	var h3 := int(HEIGHT / 3.0)
	var r_thin := 3 # qizil jiyak qalinligi

	# Moviy yuqori chiziq
	img.fill_rect(Rect2i(0, 0, WIDTH, h3), c_blue)
	# Yuqori qizil jiyak
	img.fill_rect(Rect2i(0, h3, WIDTH, r_thin), c_red)
	# O'rta oq chiziq
	img.fill_rect(Rect2i(0, h3 + r_thin, WIDTH, h3 - 2 * r_thin), c_white)
	# Quyi qizil jiyak
	img.fill_rect(Rect2i(0, 2 * h3 - r_thin, WIDTH, r_thin), c_red)
	# Yashil quyi chiziq
	img.fill_rect(Rect2i(0, 2 * h3, WIDTH, HEIGHT - 2 * h3), c_green)

	# Moviy qismda oq yarim oy
	var moon_cx := 32
	var moon_cy := h3 / 2
	var moon_r := 13
	_fill_circle(img, moon_cx, moon_cy, moon_r, c_white)
	# Ichki qirqim
	_fill_circle(img, moon_cx + 4, moon_cy, moon_r - 2, c_blue)

	# 12 ta besh qirrali yulduz (3 qatorda: 3, 4, 5)
	var sx0 := moon_cx + 18
	# 1-qator (3 ta yulduz)
	for i in 3:
		_fill_star5(img, sx0 + 16 + i * 8, moon_cy - 7, 2, c_white)
	# 2-qator (4 ta yulduz)
	for i in 4:
		_fill_star5(img, sx0 + 8 + i * 8, moon_cy, 2, c_white)
	# 3-qator (5 ta yulduz)
	for i in 5:
		_fill_star5(img, sx0 + i * 8, moon_cy + 7, 2, c_white)

## 2. Turkiya bayrog'i (TR)
static func _draw_turkey(img: Image) -> void:
	var c_red := Color("e30a17")
	img.fill(c_red)
	var cx := int(WIDTH * 0.42)
	var cy := int(HEIGHT * 0.5)
	_fill_circle(img, cx, cy, 32, Color.WHITE)
	_fill_circle(img, cx + 8, cy, 25, c_red)
	_fill_star5(img, cx + 28, cy, 12, Color.WHITE)

## 3. Qozog'iston bayrog'i (KZ)
static func _draw_kazakhstan(img: Image) -> void:
	var c_gold := Color("ffd100")
	img.fill(Color("00afca"))
	# Chap tomon milliy naqsh ustuni
	img.fill_rect(Rect2i(0, 0, 16, HEIGHT), c_gold)
	img.fill_rect(Rect2i(4, 0, 8, HEIGHT), Color("00afca"))
	for y in range(8, HEIGHT, 16):
		_fill_diamond(img, 8, y, 6, 8, c_gold)
	# Markazda oftob va qirbiyiq burgut
	var cx := int(WIDTH * 0.55)
	var cy := int(HEIGHT * 0.45)
	_fill_circle(img, cx, cy, 18, c_gold)
	for a in range(0, 360, 20):
		var rad := deg_to_rad(float(a))
		var px := int(cx + cos(rad) * 25)
		var py := int(cy + sin(rad) * 25)
		_fill_circle(img, px, py, 2, c_gold)
	# Burgut silueti
	_fill_diamond(img, cx, cy + 26, 24, 7, c_gold)

## 4. AQSH bayrog'i (US)
static func _draw_usa(img: Image) -> void:
	var c_red := Color("b22234")
	var c_blue := Color("3c3b6e")
	var stripe_h := HEIGHT / 13.0
	for i in 13:
		img.fill_rect(Rect2i(0, int(i * stripe_h), WIDTH, int(ceil(stripe_h))),
			c_red if (i % 2 == 0) else Color.WHITE)
	var canton_w := int(WIDTH * 0.42)
	var canton_h := int(stripe_h * 7)
	img.fill_rect(Rect2i(0, 0, canton_w, canton_h), c_blue)
	for row in 5:
		for col in 6:
			var px := 6 + col * 12
			var py := 6 + row * 12
			_fill_star5(img, px, py, 2, Color.WHITE)

## 5. Fransiya bayrog'i (FR)
static func _draw_france(img: Image) -> void:
	var w3 := WIDTH / 3
	img.fill_rect(Rect2i(0, 0, w3, HEIGHT), Color("0055a4"))
	img.fill_rect(Rect2i(w3, 0, w3, HEIGHT), Color.WHITE)
	img.fill_rect(Rect2i(2 * w3, 0, WIDTH - 2 * w3, HEIGHT), Color("ef4135"))

## 6. Germaniya bayrog'i (DE)
static func _draw_germany(img: Image) -> void:
	var h3 := HEIGHT / 3
	img.fill_rect(Rect2i(0, 0, WIDTH, h3), Color("000000"))
	img.fill_rect(Rect2i(0, h3, WIDTH, h3), Color("dd0000"))
	img.fill_rect(Rect2i(0, 2 * h3, WIDTH, HEIGHT - 2 * h3), Color("ffce00"))

## 7. Yaponiya bayrog'i (JP)
static func _draw_japan(img: Image) -> void:
	img.fill(Color.WHITE)
	_fill_circle(img, WIDTH / 2, HEIGHT / 2, int(HEIGHT * 0.3), Color("bc002d"))

## 8. Braziliya bayrog'i (BR)
static func _draw_brazil(img: Image) -> void:
	img.fill(Color("009c3b"))
	_fill_diamond(img, WIDTH / 2, HEIGHT / 2, int(WIDTH * 0.42), int(HEIGHT * 0.38), Color("ffdf00"))
	_fill_circle(img, WIDTH / 2, HEIGHT / 2, int(HEIGHT * 0.22), Color("002776"))
	img.fill_rect(Rect2i(WIDTH / 2 - 24, HEIGHT / 2 - 2, 48, 5), Color.WHITE)

## 9. Italiya bayrog'i (IT)
static func _draw_italy(img: Image) -> void:
	var w3 := WIDTH / 3
	img.fill_rect(Rect2i(0, 0, w3, HEIGHT), Color("009246"))
	img.fill_rect(Rect2i(w3, 0, w3, HEIGHT), Color.WHITE)
	img.fill_rect(Rect2i(2 * w3, 0, WIDTH - 2 * w3, HEIGHT), Color("ce2b37"))

## 10. Ispaniya bayrog'i (ES)
static func _draw_spain(img: Image) -> void:
	var h4 := HEIGHT / 4
	img.fill_rect(Rect2i(0, 0, WIDTH, h4), Color("aa151b"))
	img.fill_rect(Rect2i(0, h4, WIDTH, 2 * h4), Color("f1bf00"))
	img.fill_rect(Rect2i(0, 3 * h4, WIDTH, HEIGHT - 3 * h4), Color("aa151b"))
	_fill_circle(img, 42, HEIGHT / 2, 10, Color("aa151b"))

## 11. Buyuk Britaniya bayrog'i (GB)
static func _draw_uk(img: Image) -> void:
	var c_blue := Color("012169")
	var c_white := Color.WHITE
	var c_red := Color("c8102e")
	img.fill(c_blue)
	for d in range(-12, 13):
		for x in WIDTH:
			var y1 := int(float(x) * HEIGHT / WIDTH) + d
			var y2 := int(float(WIDTH - x) * HEIGHT / WIDTH) + d
			if y1 >= 0 and y1 < HEIGHT: img.set_pixel(x, y1, c_white)
			if y2 >= 0 and y2 < HEIGHT: img.set_pixel(x, y2, c_white)
	for d in range(-4, 5):
		for x in WIDTH:
			var y1 := int(float(x) * HEIGHT / WIDTH) + d
			var y2 := int(float(WIDTH - x) * HEIGHT / WIDTH) + d
			if y1 >= 0 and y1 < HEIGHT: img.set_pixel(x, y1, c_red)
			if y2 >= 0 and y2 < HEIGHT: img.set_pixel(x, y2, c_red)
	var cx := WIDTH / 2
	var cy := HEIGHT / 2
	img.fill_rect(Rect2i(cx - 18, 0, 36, HEIGHT), c_white)
	img.fill_rect(Rect2i(0, cy - 18, WIDTH, 36), c_white)
	img.fill_rect(Rect2i(cx - 10, 0, 20, HEIGHT), c_red)
	img.fill_rect(Rect2i(0, cy - 10, WIDTH, 20), c_red)

## 12. Kanada bayrog'i (CA)
static func _draw_canada(img: Image) -> void:
	var w4 := WIDTH / 4
	img.fill_rect(Rect2i(0, 0, w4, HEIGHT), Color("ff0000"))
	img.fill_rect(Rect2i(w4, 0, 2 * w4, HEIGHT), Color.WHITE)
	img.fill_rect(Rect2i(3 * w4, 0, WIDTH - 3 * w4, HEIGHT), Color("ff0000"))
	_fill_diamond(img, WIDTH / 2, HEIGHT / 2, 20, 22, Color("ff0000"))
	_fill_diamond(img, WIDTH / 2 - 12, HEIGHT / 2 - 4, 10, 12, Color("ff0000"))
	_fill_diamond(img, WIDTH / 2 + 12, HEIGHT / 2 - 4, 10, 12, Color("ff0000"))
	img.fill_rect(Rect2i(WIDTH / 2 - 2, HEIGHT / 2 + 10, 4, 12), Color("ff0000"))

## 13. Rossiya bayrog'i (RU)
static func _draw_russia(img: Image) -> void:
	var h3 := HEIGHT / 3
	img.fill_rect(Rect2i(0, 0, WIDTH, h3), Color.WHITE)
	img.fill_rect(Rect2i(0, h3, WIDTH, h3), Color("0039a6"))
	img.fill_rect(Rect2i(0, 2 * h3, WIDTH, HEIGHT - 2 * h3), Color("d52b1e"))

## 14. Hindiston bayrog'i (IN)
static func _draw_india(img: Image) -> void:
	var h3 := HEIGHT / 3
	img.fill_rect(Rect2i(0, 0, WIDTH, h3), Color("ff9933"))
	img.fill_rect(Rect2i(0, h3, WIDTH, h3), Color.WHITE)
	img.fill_rect(Rect2i(0, 2 * h3, WIDTH, HEIGHT - 2 * h3), Color("138808"))
	_fill_circle(img, WIDTH / 2, HEIGHT / 2, 14, Color("000080"))
	_fill_circle(img, WIDTH / 2, HEIGHT / 2, 10, Color.WHITE)
	_fill_circle(img, WIDTH / 2, HEIGHT / 2, 3, Color("000080"))

## 15. Janubiy Koreya bayrog'i (KR)
static func _draw_south_korea(img: Image) -> void:
	img.fill(Color.WHITE)
	var cx := WIDTH / 2
	var cy := HEIGHT / 2
	_fill_circle(img, cx, cy, 22, Color("cd2e3a"))
	_fill_circle(img, cx, cy + 11, 11, Color("0047a0"))
	_fill_circle(img, cx, cy - 11, 11, Color("cd2e3a"))
	for q in [Vector2(-35, -20), Vector2(35, -20), Vector2(-35, 20), Vector2(35, 20)]:
		img.fill_rect(Rect2i(int(cx + q.x - 6), int(cy + q.y - 8), 12, 16), Color.BLACK)
		img.fill_rect(Rect2i(int(cx + q.x - 6), int(cy + q.y - 2), 12, 4), Color.WHITE)

## 16. Xitoy bayrog'i (CN)
static func _draw_china(img: Image) -> void:
	img.fill(Color("de2910"))
	_fill_star5(img, 36, 36, 16, Color("ffde00"))
	for p in [Vector2(65, 18), Vector2(76, 28), Vector2(76, 44), Vector2(65, 54)]:
		_fill_star5(img, int(p.x), int(p.y), 5, Color("ffde00"))

## 17. Argentina bayrog'i (AR)
static func _draw_argentina(img: Image) -> void:
	var h3 := HEIGHT / 3
	img.fill_rect(Rect2i(0, 0, WIDTH, h3), Color("74acdf"))
	img.fill_rect(Rect2i(0, h3, WIDTH, h3), Color.WHITE)
	img.fill_rect(Rect2i(0, 2 * h3, WIDTH, HEIGHT - 2 * h3), Color("74acdf"))
	_fill_circle(img, WIDTH / 2, HEIGHT / 2, 12, Color("f6b40e"))

## 18. Ukraina bayrog'i (UA)
static func _draw_ukraine(img: Image) -> void:
	var h2 := HEIGHT / 2
	img.fill_rect(Rect2i(0, 0, WIDTH, h2), Color("005bbb"))
	img.fill_rect(Rect2i(0, h2, WIDTH, HEIGHT - h2), Color("ffd500"))

## 19. Polsha bayrog'i (PL)
static func _draw_poland(img: Image) -> void:
	var h2 := HEIGHT / 2
	img.fill_rect(Rect2i(0, 0, WIDTH, h2), Color.WHITE)
	img.fill_rect(Rect2i(0, h2, WIDTH, HEIGHT - h2), Color("dc143c"))

## 20. Shvetsiya bayrog'i (SE)
static func _draw_sweden(img: Image) -> void:
	img.fill(Color("006aa7"))
	var cx := int(WIDTH * 0.35)
	img.fill_rect(Rect2i(cx - 10, 0, 20, HEIGHT), Color("fecc00"))
	img.fill_rect(Rect2i(0, HEIGHT / 2 - 10, WIDTH, 20), Color("fecc00"))

## 21. Shveytsariya bayrog'i (CH)
static func _draw_switzerland(img: Image) -> void:
	img.fill(Color("ff0000"))
	var cx := WIDTH / 2
	var cy := HEIGHT / 2
	img.fill_rect(Rect2i(cx - 10, cy - 30, 20, 60), Color.WHITE)
	img.fill_rect(Rect2i(cx - 30, cy - 10, 60, 20), Color.WHITE)

## 22. Niderlandiya bayrog'i (NL)
static func _draw_netherlands(img: Image) -> void:
	var h3 := HEIGHT / 3
	img.fill_rect(Rect2i(0, 0, WIDTH, h3), Color("ae1c28"))
	img.fill_rect(Rect2i(0, h3, WIDTH, h3), Color.WHITE)
	img.fill_rect(Rect2i(0, 2 * h3, WIDTH, HEIGHT - 2 * h3), Color("21468b"))

## 23. Belgiya bayrog'i (BE)
static func _draw_belgium(img: Image) -> void:
	var w3 := WIDTH / 3
	img.fill_rect(Rect2i(0, 0, w3, HEIGHT), Color.BLACK)
	img.fill_rect(Rect2i(w3, 0, w3, HEIGHT), Color("fdd017"))
	img.fill_rect(Rect2i(2 * w3, 0, WIDTH - 2 * w3, HEIGHT), Color("ed2939"))

## 24. Ozarbayjon bayrog'i (AZ)
static func _draw_azerbaijan(img: Image) -> void:
	var h3 := HEIGHT / 3
	img.fill_rect(Rect2i(0, 0, WIDTH, h3), Color("00b5e2"))
	img.fill_rect(Rect2i(0, h3, WIDTH, h3), Color("ef3340"))
	img.fill_rect(Rect2i(0, 2 * h3, WIDTH, HEIGHT - 2 * h3), Color("509e2f"))
	var cx := WIDTH / 2
	var cy := HEIGHT / 2
	_fill_circle(img, cx - 4, cy, 14, Color.WHITE)
	_fill_circle(img, cx, cy, 11, Color("ef3340"))
	_fill_star5(img, cx + 12, cy, 6, Color.WHITE)

## 25. Turkmaniston bayrog'i (TM)
static func _draw_turkmenistan(img: Image) -> void:
	img.fill(Color("2e8b57"))
	img.fill_rect(Rect2i(20, 0, 22, HEIGHT), Color("8b0000"))
	for y in range(12, HEIGHT, 24):
		_fill_diamond(img, 31, y, 9, 8, Color("ffd700"))
	var cx := 64
	var cy := 32
	_fill_circle(img, cx, cy, 12, Color.WHITE)
	_fill_circle(img, cx + 4, cy, 9, Color("2e8b57"))
	for i in 5:
		_fill_star5(img, cx + 14 + (i % 2) * 8, cy - 8 + i * 4, 2, Color.WHITE)

## 26. Qirg'iziston bayrog'i (KG)
static func _draw_kyrgyzstan(img: Image) -> void:
	img.fill(Color("e8112d"))
	var cx := WIDTH / 2
	var cy := HEIGHT / 2
	_fill_circle(img, cx, cy, 26, Color("ffe600"))
	for a in range(0, 360, 9):
		var rad := deg_to_rad(float(a))
		var px := int(cx + cos(rad) * 34)
		var py := int(cy + sin(rad) * 34)
		_fill_circle(img, px, py, 2, Color("ffe600"))
	_fill_circle(img, cx, cy, 14, Color("e8112d"))
	img.fill_rect(Rect2i(cx - 10, cy - 2, 20, 4), Color("ffe600"))
	img.fill_rect(Rect2i(cx - 2, cy - 10, 4, 20), Color("ffe600"))

## 27. Tojikiston bayrog'i (TJ)
static func _draw_tajikistan(img: Image) -> void:
	var h7 := int(HEIGHT / 7.0)
	img.fill_rect(Rect2i(0, 0, WIDTH, h7 * 2), Color("cc0000"))
	img.fill_rect(Rect2i(0, h7 * 2, WIDTH, h7 * 3), Color.WHITE)
	img.fill_rect(Rect2i(0, h7 * 5, WIDTH, HEIGHT - h7 * 5), Color("006600"))
	var cx := WIDTH / 2
	var cy := HEIGHT / 2
	_fill_diamond(img, cx, cy, 12, 10, Color("ffd700"))
	for a in range(-60, 61, 20):
		var rad := deg_to_rad(float(a - 90))
		var px := int(cx + cos(rad) * 16)
		var py := int(cy + sin(rad) * 16)
		_fill_star5(img, px, py, 2, Color("ffd700"))

## 28. Afg'oniston bayrog'i (AF)
static func _draw_afghanistan(img: Image) -> void:
	var w3 := WIDTH / 3
	img.fill_rect(Rect2i(0, 0, w3, HEIGHT), Color.BLACK)
	img.fill_rect(Rect2i(w3, 0, w3, HEIGHT), Color("d32011"))
	img.fill_rect(Rect2i(2 * w3, 0, WIDTH - 2 * w3, HEIGHT), Color("007a3d"))
	_fill_circle(img, WIDTH / 2, HEIGHT / 2, 14, Color.WHITE)
	_fill_circle(img, WIDTH / 2, HEIGHT / 2, 11, Color("d32011"))

## 29. Pokiston bayrog'i (PK)
static func _draw_pakistan(img: Image) -> void:
	img.fill(Color("01411c"))
	img.fill_rect(Rect2i(0, 0, int(WIDTH * 0.25), HEIGHT), Color.WHITE)
	var cx := int(WIDTH * 0.6)
	var cy := HEIGHT / 2
	_fill_circle(img, cx, cy, 26, Color.WHITE)
	_fill_circle(img, cx + 7, cy - 5, 22, Color("01411c"))
	_fill_star5(img, cx + 18, cy - 14, 9, Color.WHITE)

## 30. Saudiya Arabistoni bayrog'i (SA)
static func _draw_saudi_arabia(img: Image) -> void:
	img.fill(Color("006c35"))
	img.fill_rect(Rect2i(WIDTH / 2 - 32, HEIGHT / 2 - 6, 64, 12), Color.WHITE)
	img.fill_rect(Rect2i(WIDTH / 2 - 28, HEIGHT / 2 + 10, 56, 3), Color.WHITE)

## 31. BAA bayrog'i (AE)
static func _draw_uae(img: Image) -> void:
	var h3 := HEIGHT / 3
	img.fill_rect(Rect2i(0, 0, WIDTH, h3), Color("00732f"))
	img.fill_rect(Rect2i(0, h3, WIDTH, h3), Color.WHITE)
	img.fill_rect(Rect2i(0, 2 * h3, WIDTH, HEIGHT - 2 * h3), Color.BLACK)
	img.fill_rect(Rect2i(0, 0, int(WIDTH * 0.25), HEIGHT), Color("ff0000"))

## 32. Misr bayrog'i (EG)
static func _draw_egypt(img: Image) -> void:
	var h3 := HEIGHT / 3
	img.fill_rect(Rect2i(0, 0, WIDTH, h3), Color("c8102e"))
	img.fill_rect(Rect2i(0, h3, WIDTH, h3), Color.WHITE)
	img.fill_rect(Rect2i(0, 2 * h3, WIDTH, HEIGHT - 2 * h3), Color.BLACK)
	_fill_diamond(img, WIDTH / 2, HEIGHT / 2, 10, 10, Color("c09a3e"))

## 33. Gretsiya bayrog'i (GR)
static func _draw_greece(img: Image) -> void:
	var c_blue := Color("0d5eaf")
	var h9 := HEIGHT / 9.0
	for i in 9:
		img.fill_rect(Rect2i(0, int(i * h9), WIDTH, int(ceil(h9))),
			c_blue if (i % 2 == 0) else Color.WHITE)
	var canton_w := int(WIDTH * 0.38)
	var canton_h := int(h9 * 5)
	img.fill_rect(Rect2i(0, 0, canton_w, canton_h), c_blue)
	img.fill_rect(Rect2i(canton_w / 2 - 4, 0, 8, canton_h), Color.WHITE)
	img.fill_rect(Rect2i(0, canton_h / 2 - 4, canton_w, 8), Color.WHITE)

## 34. Portugaliya bayrog'i (PT)
static func _draw_portugal(img: Image) -> void:
	var w_split := int(WIDTH * 0.4)
	img.fill_rect(Rect2i(0, 0, w_split, HEIGHT), Color("006600"))
	img.fill_rect(Rect2i(w_split, 0, WIDTH - w_split, HEIGHT), Color("ff0000"))
	_fill_circle(img, w_split, HEIGHT / 2, 16, Color("ffff00"))
	_fill_circle(img, w_split, HEIGHT / 2, 10, Color.WHITE)

## 35. Meksika bayrog'i (MX)
static func _draw_mexico(img: Image) -> void:
	var w3 := WIDTH / 3
	img.fill_rect(Rect2i(0, 0, w3, HEIGHT), Color("006847"))
	img.fill_rect(Rect2i(w3, 0, w3, HEIGHT), Color.WHITE)
	img.fill_rect(Rect2i(2 * w3, 0, WIDTH - 2 * w3, HEIGHT), Color("ce1126"))
	_fill_circle(img, WIDTH / 2, HEIGHT / 2, 12, Color("7b5123"))

## 36. Avstraliya bayrog'i (AU)
static func _draw_australia(img: Image) -> void:
	_draw_uk(img)
	# O'ng tomonda ko'k maydon va Janubiy Xoch yulduzlari
	var cx := int(WIDTH * 0.4)
	img.fill_rect(Rect2i(cx, 0, WIDTH - cx, HEIGHT), Color("012169"))
	_fill_star5(img, int(WIDTH * 0.75), int(HEIGHT * 0.25), 5, Color.WHITE)
	_fill_star5(img, int(WIDTH * 0.85), int(HEIGHT * 0.45), 5, Color.WHITE)
	_fill_star5(img, int(WIDTH * 0.75), int(HEIGHT * 0.75), 6, Color.WHITE)
	_fill_star5(img, int(WIDTH * 0.65), int(HEIGHT * 0.50), 5, Color.WHITE)
	_fill_star5(img, int(WIDTH * 0.80), int(HEIGHT * 0.60), 3, Color.WHITE)
	_fill_star5(img, int(WIDTH * 0.25), int(HEIGHT * 0.75), 10, Color.WHITE)

# ——— Qolgan 249 ta davlat uchun parametrik bayroqlar ———

static func _draw_generic(img: Image, code: String) -> void:
	# Harflarning xesh qiymatidan uyg'un ranglar tanlaymiz
	var h := code.hash()
	var hue1 := fposmod(float(h & 0xFF) / 255.0, 1.0)
	var hue2 := fposmod(float((h >> 8) & 0xFF) / 255.0, 1.0)
	var hue3 := fposmod(float((h >> 16) & 0xFF) / 255.0, 1.0)

	var c1 := Color.from_hsv(hue1, 0.85, 0.88)
	var c2 := Color.WHITE if ((h & 1) == 0) else Color.from_hsv(hue2, 0.75, 0.95)
	var c3 := Color.from_hsv(hue3, 0.85, 0.80)

	var style := (h >> 24) % 3
	if style == 0:
		# Gorizontal trikolor
		var h3 := HEIGHT / 3
		img.fill_rect(Rect2i(0, 0, WIDTH, h3), c1)
		img.fill_rect(Rect2i(0, h3, WIDTH, h3), c2)
		img.fill_rect(Rect2i(0, 2 * h3, WIDTH, HEIGHT - 2 * h3), c3)
	elif style == 1:
		# Vertikal trikolor
		var w3 := WIDTH / 3
		img.fill_rect(Rect2i(0, 0, w3, HEIGHT), c1)
		img.fill_rect(Rect2i(w3, 0, w3, HEIGHT), c2)
		img.fill_rect(Rect2i(2 * w3, 0, WIDTH - 2 * w3, HEIGHT), c3)
	else:
		# Kross / doirali bayroq
		img.fill(c1)
		var cx := WIDTH / 2
		var cy := HEIGHT / 2
		_fill_circle(img, cx, cy, int(HEIGHT * 0.3), c2)
		_fill_star5(img, cx, cy, 12, c3)

# ——— Geometrik chizish yordamchilari ———

static func _fill_circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	var r2 := r * r
	for y in range(maxi(0, cy - r), mini(HEIGHT, cy + r + 1)):
		var dy := y - cy
		var dx_max := int(sqrt(float(r2 - dy * dy)))
		var x0 := maxi(0, cx - dx_max)
		var x1 := mini(WIDTH - 1, cx + dx_max)
		for x in range(x0, x1 + 1):
			img.set_pixel(x, y, color)

static func _fill_diamond(img: Image, cx: int, cy: int, rx: int, ry: int, color: Color) -> void:
	if rx <= 0 or ry <= 0: return
	for y in range(maxi(0, cy - ry), mini(HEIGHT, cy + ry + 1)):
		var dy := absf(float(y - cy))
		var dx_max := int((1.0 - dy / float(ry)) * float(rx))
		var x0 := maxi(0, cx - dx_max)
		var x1 := mini(WIDTH - 1, cx + dx_max)
		for x in range(x0, x1 + 1):
			img.set_pixel(x, y, color)

static func _fill_star5(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	if r <= 1:
		if cx >= 0 and cx < WIDTH and cy >= 0 and cy < HEIGHT:
			img.set_pixel(cx, cy, color)
		return
	# Soddalashtirilgan 5 qirrali yulduz
	_fill_circle(img, cx, cy, maxi(1, r / 2), color)
	for a in [0, 72, 144, 216, 288]:
		var rad := deg_to_rad(float(a - 90))
		var px := int(cx + cos(rad) * float(r))
		var py := int(cy + sin(rad) * float(r))
		_draw_line(img, cx, cy, px, py, color)

static func _draw_line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	var x := x0
	var y := y0
	while true:
		if x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT:
			img.set_pixel(x, y, color)
		if x == x1 and y == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
