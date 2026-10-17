class_name FlagRenderer
extends RefCounted

## Milliy bayroqlarni sifatli va haqiqiy rasmiy standartlar asosida yuklovchi modul.
## Barcha 249 ta ISO 3166-1 davlat va hududlari uchun haqiqiy (authentic) bayroqlar ishlatiladi.
## Soxta yoki taxminiy (generic/imaginary) bayroqlar yaratilmaydi.
## Rasmiy manba: lipis/flag-icons (MIT litsenziyasi asosida).

const WIDTH := 192
const HEIGHT := 128

const FLAGS_PNG_DIR := "res://assets/flags/png"
const FLAGS_SVG_DIR := "res://assets/flags/svg"

## Kesh: har bir mamlakat kodi bo'yicha ImageTexture saqlanadi
static var _cache: Dictionary = {}
## Image keshi: tezkor kirish uchun
static var _img_cache: Dictionary = {}

## Mamlakat kodi bo'yicha bayroq teksturasini qaytaradi (keshdan yoki yuklab)
static func get_flag_texture(country_code: String) -> ImageTexture:
	var code := sanitize_code(country_code)
	if _cache.has(code):
		return _cache[code]

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
		if img.get_width() != WIDTH or img.get_height() != HEIGHT:
			img.resize(WIDTH, HEIGHT, Image.INTERPOLATE_LANCZOS)
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
static func has_authentic_flag(country_code: String) -> bool:
	var code := sanitize_code(country_code)
	var png_path := "%s/%s.png" % [FLAGS_PNG_DIR, code]
	if FileAccess.file_exists(png_path) or ResourceLoader.exists(png_path):
		return true
	var svg_path := "%s/%s.svg" % [FLAGS_SVG_DIR, code]
	return FileAccess.file_exists(svg_path) or ResourceLoader.exists(svg_path)

## ISO kodini tozalash (2 ta bosh harf)
static func sanitize_code(raw: String) -> String:
	var clean := raw.strip_edges().to_upper()
	if clean.length() == 2:
		return clean
	return "UZ" if clean.is_empty() else clean.substr(0, 2)

## Haqiqiy bayroq faylini yuklash (PNG -> SVG)
static func _load_authentic_flag(code: String) -> Image:
	# 1. Tezkor PNG faylidan yuklash
	var png_path := "%s/%s.png" % [FLAGS_PNG_DIR, code]
	if FileAccess.file_exists(png_path) or ResourceLoader.exists(png_path):
		var img := Image.load_from_file(png_path)
		if img != null and not img.is_empty():
			return img

	# 2. Vektor SVG faylidan yuklash (fallback)
	var svg_path := "%s/%s.svg" % [FLAGS_SVG_DIR, code]
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
