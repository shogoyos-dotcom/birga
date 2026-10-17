class_name FlagRenderer
extends RefCounted

## Milliy bayroqlarni sifatli va haqiqiy rasmiy standartlar asosida yuklovchi modul.
## Barcha 249 ta ISO 3166-1 davlat va hududlari uchun haqiqiy (authentic) bayroqlar ishlatiladi.
## Soxta yoki taxminiy (generic/imaginary) bayroqlar yaratilmaydi.
## Rasmiy manba: lipis/flag-icons (MIT litsenziyasi asosida).
## Android APK va eksport paketlari bilan to'liq mos: ResourceLoader va FileAccess fallback.

const WIDTH := 192
const HEIGHT := 128

const FLAGS_PNG_DIR := "res://assets/flags/png"
const FLAGS_SVG_DIR := "res://assets/flags/svg"

## Rasmiy milliy bayroq mutanosibliklari (Width / Height nisbati):
## Ko'pchilik davlatlar 1.5:1 (3:2) yoki 1.33:1 (4:3) yoki 2:1 (1:2).
const OFFICIAL_ASPECT_RATIOS: Dictionary = {
	"CH": 1.0,   # Shveytsariya — kvadrat (1:1)
	"VA": 1.0,   # Vatikan — kvadrat (1:1)
	"NP": 0.82,  # Nepal — ikki pennantli, balandligi enidan katta (0.82:1)
	"US": 1.90,  # AQSH — 10:19 nisbat (1.90:1)
	"QA": 2.54,  # Qatar — 11:28 nisbat (2.54:1)
	"GB": 2.0,   # Buyuk Britaniya — 1:2 nisbat (2.0:1)
	"CA": 2.0,   # Kanada — 1:2 nisbat (2.0:1)
	"AU": 2.0,   # Avstraliya — 1:2 nisbat (2.0:1)
	"NZ": 2.0,   # Yangi Zelandiya — 1:2 nisbat (2.0:1)
	"UZ": 2.0,   # O'zbekiston — rasmiy qonuniy nisbati 1:2 (2.0:1)
	"IE": 2.0,   # Irlandiya — 1:2 (2.0:1)
	"JM": 2.0,   # Yamayka — 1:2 (2.0:1)
	"KW": 2.0,   # Quvayt — 1:2 (2.0:1)
	"MY": 2.0,   # Malayziya — 1:2 (2.0:1)
	"NG": 2.0,   # Nigeriya — 1:2 (2.0:1)
	"BE": 1.15,  # Belgiya — 13:15 nisbat (1.15:1)
	"MC": 1.25,  # Monako — 4:5 nisbat (1.25:1)
	"IL": 1.375, # Isroil — 8:11 nisbat (1.375:1)
	"BR": 1.43,  # Braziliya — 7:10 nisbat (1.43:1)
	"DE": 1.67,  # Germaniya — 3:5 nisbat (1.67:1)
}

## Kesh: har bir mamlakat kodi bo'yicha Texture2D saqlanadi
static var _cache: Dictionary = {}
## Image keshi: tezkor kirish uchun
static var _img_cache: Dictionary = {}

## Mamlakat kodi bo'yicha bayroqning rasmiy mutanosiblik (aspect ratio) nisbatini olish
static func get_flag_aspect_ratio(country_code: String) -> float:
	var code := sanitize_code(country_code)
	if OFFICIAL_ASPECT_RATIOS.has(code):
		return float(OFFICIAL_ASPECT_RATIOS[code])
	return 1.5

## To'rtburchak bo'lmagan (shaffof fonli) bayroq ekanini tekshirish (masalan Nepal)
static func is_non_rectangular(country_code: String) -> bool:
	var code := sanitize_code(country_code)
	return code == "NP"

## Mamlakat kodi bo'yicha bayroq teksturasini qaytaradi (keshdan yoki yuklab).
## Android APK ichida ResourceLoader orqali to'g'ridan-to'g'ri CompressedTexture2D yuklanadi.
static func get_flag_texture(country_code: String) -> Texture2D:
	var code := sanitize_code(country_code)
	if _cache.has(code):
		return _cache[code]

	# 1. ResourceLoader (Android APK va import qilingan paketlarda eng ishonchli usul)
	var png_path := "%s/%s.png" % [FLAGS_PNG_DIR, code]
	if ResourceLoader.exists(png_path):
		var res: Resource = ResourceLoader.load(png_path)
		if res is Texture2D:
			var tex: Texture2D = res as Texture2D
			_cache[code] = tex
			if not _img_cache.has(code):
				var img := tex.get_image()
				if img != null and not img.is_empty():
					_img_cache[code] = img
			return tex

	# 2. Image orqali yaratish (fallback)
	var img := get_flag_image(code)
	var tex := ImageTexture.create_from_image(img)
	_cache[code] = tex
	return tex

## To'g'ridan-to'g'ri Image obyektini olish
static func get_flag_image(country_code: String) -> Image:
	var code := sanitize_code(country_code)
	if _img_cache.has(code):
		return _img_cache[code]

	var img := _load_authentic_flag(code)
	if img != null and not img.is_empty():
		_img_cache[code] = img
		return img

	# Agar haqiqiy bayroq topilmasa, soxta bayroq yaratilmaydi —
	# aniq xatolik qayd qilinadi va neytral placeholder beriladi.
	push_error("FlagRenderer: Haqiqiy milliy bayroq topilmadi: '%s'" % code)
	var placeholder := _create_missing_placeholder(code)
	_img_cache[code] = placeholder
	return placeholder

## Eski interfeys bilan moslik uchun
static func create_flag_image(code: String) -> Image:
	return get_flag_image(code)

## Mamlakat uchun haqiqiy rasmiy bayroq resursi mavjudligini tekshirish
## (ResourceLoader orqali APK ichini va FileAccess orqali xom fayllarni tekshiradi)
static func has_authentic_flag(country_code: String) -> bool:
	var code := sanitize_code(country_code)
	var png_path := "%s/%s.png" % [FLAGS_PNG_DIR, code]
	if ResourceLoader.exists(png_path) or FileAccess.file_exists(png_path):
		return true
	var svg_path := "%s/%s.svg" % [FLAGS_SVG_DIR, code]
	return ResourceLoader.exists(svg_path) or FileAccess.file_exists(svg_path)

## ISO kodini tozalash (2 ta bosh harf)
static func sanitize_code(raw: String) -> String:
	var clean := raw.strip_edges().to_upper()
	if clean.length() == 2:
		return clean
	return "UZ" if clean.is_empty() else clean.substr(0, 2)

## Haqiqiy bayroq faylini yuklash (ResourceLoader -> FileAccess PNG -> FileAccess SVG)
static func _load_authentic_flag(code: String) -> Image:
	var png_path := "%s/%s.png" % [FLAGS_PNG_DIR, code]

	# 1. ResourceLoader (Godot import qilgan .ctex / texture resurslari — APK ichida ishlaydi)
	if ResourceLoader.exists(png_path):
		var res: Resource = ResourceLoader.load(png_path)
		if res is Texture2D:
			var img: Image = (res as Texture2D).get_image()
			if img != null and not img.is_empty():
				return img

	# 2. FileAccess orqali xom PNG faylini xotira buferi orqali yuklash
	if FileAccess.file_exists(png_path):
		var bytes := FileAccess.get_file_as_bytes(png_path)
		if not bytes.is_empty():
			var img := Image.new()
			var err := img.load_png_from_buffer(bytes)
			if err == OK and not img.is_empty():
				return img

		var img_file := Image.load_from_file(png_path)
		if img_file != null and not img_file.is_empty():
			return img_file

	# 3. Vektor SVG resursini ResourceLoader orqali yuklash
	var svg_path := "%s/%s.svg" % [FLAGS_SVG_DIR, code]
	if ResourceLoader.exists(svg_path):
		var res: Resource = ResourceLoader.load(svg_path)
		if res is Texture2D:
			var img: Image = (res as Texture2D).get_image()
			if img != null and not img.is_empty():
				return img

	# 4. Xom SVG matnidan yuklash (fallback)
	if FileAccess.file_exists(svg_path):
		var f := FileAccess.open(svg_path, FileAccess.READ)
		if f != null:
			var svg_text := f.get_as_text()
			f.close()
			var img := Image.new()
			var err := img.load_svg_from_string(svg_text, 0.4)
			if err == OK and not img.is_empty():
				return img

	return null

## Haqiqiy bayroq topilmaganda aniq xato bildiruvchi neytral placeholder.
## Soxta yoki o'ylab topilgan davlat bayrog'i EMAS.
static func _create_missing_placeholder(code: String) -> Image:
	var img := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.18, 0.20, 0.25)) # To'q kulrang fon

	# Qizil xatolik hoshiyasi
	for x in WIDTH:
		img.set_pixel(x, 0, Color("ef4444"))
		img.set_pixel(x, 1, Color("ef4444"))
		img.set_pixel(x, HEIGHT - 1, Color("ef4444"))
		img.set_pixel(x, HEIGHT - 2, Color("ef4444"))
	for y in HEIGHT:
		img.set_pixel(0, y, Color("ef4444"))
		img.set_pixel(1, y, Color("ef4444"))
		img.set_pixel(WIDTH - 1, y, Color("ef4444"))
		img.set_pixel(WIDTH - 2, y, Color("ef4444"))

	# Markazda diagonalli xatolik chizig'i
	for i in mini(WIDTH, HEIGHT):
		var px := int(float(i) / float(HEIGHT) * float(WIDTH))
		if px >= 0 and px < WIDTH:
			img.set_pixel(px, i, Color("ef4444"))
			img.set_pixel(WIDTH - 1 - px, i, Color("ef4444"))

	return img

## Keshni tozalash
static func clear_cache() -> void:
	_cache.clear()
	_img_cache.clear()
