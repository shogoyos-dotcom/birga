class_name PaintLayer
extends RefCounted

## Egalik ma'lumoti: har katak uchun bitta piksel.
##
## Hududlar va izlar alohida mesh emas, arena ustidagi tekstura bo'lib
## chiziladi — shuning uchun minglab katak o'zgarsa ham geometriya
## qayta qurilmaydi. Faqat o'zgargan kataklar qayta bo'yaladi.
##
## Ikkita tekstura tayyorlanadi:
##  * [index_texture] — R: hudud egasi ([constant WATER] — suv),
##    G: iz egasi. Arena shaderi shuni o'qib chegaralarni silliq
##    chizadi;
##  * [texture] — tayyor ranglar; kichik xarita shuni ko'rsatadi.

## Rang jadvali o'lchami: 0 — egasiz, 1..255 — hudud, 256..511 — iz.
const PALETTE_SIZE := 768

## Suv kataklarining belgisi egalik kanalida.
##
## Shaderdagi ovoz berish 4x4 oynadan foydalanadi; qirg'oqda oynaga
## suv kataklari ham tushadi va ular "egasiz" bo'lib ovoz berardi —
## natijada hudud rangini qirg'oq bo'ylab oq hoshiya kesib o'tardi.
## Endi suv alohida belgilanadi va ovoz berishda umuman qatnashmaydi.
## O'yinchi ID lari 1..16 oralig'ida, shuning uchun 255 bo'sh turadi.
const WATER := 255

var image: Image
var texture: ImageTexture
var index_image: Image
var index_texture: ImageTexture
## 512x1 rang jadvali — shader shundan rang oladi.
var palette_image: Image
var palette_texture: ImageTexture

var _grid: GameGrid
var _colors: PackedColorArray
## O'yinchi ID -> skin nomi.
var _skins := PackedStringArray()
## Sohil chizig'igacha bo'lgan masofa xaritasi (katak birligida).
var _coast_dist := PackedFloat32Array()

## `skin_by_id` — har o'yinchining hudud naqshi (skin nomi).
## Bo'sh bo'lsa hudud tekis rangda qoladi.
func _init(grid: GameGrid, color_index_by_id: PackedByteArray,
		skin_by_id: PackedStringArray = PackedStringArray()) -> void:
	_grid = grid
	_skins = skin_by_id
	image = Image.create_empty(grid.width, grid.height, false, Image.FORMAT_RGBA8)
	index_image = Image.create_empty(
		grid.width, grid.height, false, Image.FORMAT_RGBA8)
	_build_coast_distance()
	_rebuild_colors(color_index_by_id)
	_paint_all()
	texture = ImageTexture.create_from_image(image)
	index_texture = ImageTexture.create_from_image(index_image)
	palette_texture = ImageTexture.create_from_image(palette_image)

## O'yinchi ranglarini oldindan hisoblaydi.
##
## Jadvalning tuzilishi:
##  * `0` — egasiz quruqlik;
##  * `1..255` — hudud rangi (skinga tortilgan);
##  * `256..511` — o'sha ID ning naqsh va hoshiya rangi;
##  * `512..767` — naqsh raqami, **alfa** kanalida.
##
## Hammasi bitta 768x1 teksturada: yangi shader parametri kerak
## emas.
func _rebuild_colors(color_index_by_id: PackedByteArray) -> void:
	_colors = PackedColorArray()
	_colors.resize(PALETTE_SIZE)
	_colors[0] = Palette.land()
	for id in range(1, 256):
		var ci: int = color_index_by_id[id]
		var skin := _skins[id] if id < _skins.size() else ""
		# Hudud rangi skinga tortiladi — tarvuz qizil, muz moviy
		# bo'ladi. O'yinchining o'z rangi butunlay yo'qolmaydi:
		# aralashma shar pardozidagidek (`blend`), shuning uchun
		# maydonda kim kimligi baribir bilinadi.
		var base := Palette.territory(ci)
		if not skin.is_empty():
			base = Cosmetics.skin_color(base, Cosmetics.skin(skin))
		_colors[id] = base
		var accent := Cosmetics.accent_of(skin)
		accent.a = 1.0
		_colors[256 + id] = accent
		# Naqsh raqami **alfada**: rang kanallari `source_color`
		# bilan o'qiladi va sRGB dan chiziqliga o'giriladi — butun
		# son undan omon chiqmaydi. Alfa esa o'girilmaydi.
		_colors[512 + id] = Color(1.0, 1.0, 1.0,
			Cosmetics.pattern_of(skin) / 255.0)
	palette_image = Image.create_empty(
		PALETTE_SIZE, 1, false, Image.FORMAT_RGBA8)
	for i in PALETTE_SIZE:
		palette_image.set_pixel(i, 0, _colors[i])

func _paint_all() -> void:
	for y in _grid.height:
		var row := y * _grid.width
		for x in _grid.width:
			_paint(x, y, row + x)

func _paint(x: int, y: int, i: int) -> void:
	var own: int = _grid.owner_cells[i]
	var trail: int = _grid.trail_cells[i]
	var index: int = 256 + trail if trail != 0 else own
	image.set_pixel(x, y, _colors[index])
	# Shaderga ID lar 0..1 oralig'ida uzatiladi; suv alohida
	# belgilanadi, chunki u ovoz berishda qatnashmasligi kerak.
	var mark: int = WATER if not _grid.is_land_index(i) else own
	var c_dist: float = clampf(_coast_dist[i] / 4.0, 0.0, 1.0) if not _coast_dist.is_empty() else 0.0
	index_image.set_pixel(x, y,
		Color(mark / 255.0, trail / 255.0, c_dist, 1.0))

## Butun xarita bo'ylab suvdan masofani 2-o'tishli Chamfer algoritmi bilan
## bir marta hisoblaydi. Bu shaderda 25 ta tekstura tekshirish loopini yo'qotadi
## va sohilda silliq sand o'tishini ta'minlaydi.
func _build_coast_distance() -> void:
	var w := _grid.width
	var h := _grid.height
	var total := w * h
	_coast_dist = PackedFloat32Array()
	_coast_dist.resize(total)
	_coast_dist.fill(99.0)

	# 1-o'tish: yuqori-chapdan pastki-o'ngga
	for y in h:
		var row := y * w
		for x in w:
			var idx := row + x
			if not _grid.is_land_index(idx):
				_coast_dist[idx] = 0.0
			else:
				var m: float = _coast_dist[idx]
				if x > 0:
					m = minf(m, _coast_dist[idx - 1] + 1.0)
				if y > 0:
					m = minf(m, _coast_dist[idx - w] + 1.0)
					if x > 0:
						m = minf(m, _coast_dist[idx - w - 1] + 1.414)
					if x < w - 1:
						m = minf(m, _coast_dist[idx - w + 1] + 1.414)
				_coast_dist[idx] = m

	# 2-o'tish: pastki-o'ngdan yuqori-chapga
	for y in range(h - 1, -1, -1):
		var row := y * w
		for x in range(w - 1, -1, -1):
			var idx := row + x
			if _grid.is_land_index(idx):
				var m: float = _coast_dist[idx]
				if x < w - 1:
					m = minf(m, _coast_dist[idx + 1] + 1.0)
				if y < h - 1:
					m = minf(m, _coast_dist[idx + w] + 1.0)
					if x < w - 1:
						m = minf(m, _coast_dist[idx + w + 1] + 1.414)
					if x > 0:
						m = minf(m, _coast_dist[idx + w - 1] + 1.414)
				_coast_dist[idx] = m

## Panjaradagi o'zgarishlarni teksturaga ko'chiradi.
## O'zgargan katak sonini qaytaradi.
func sync() -> int:
	var dirty := _grid.take_dirty()
	if dirty.is_empty():
		return 0
	var w := _grid.width
	for i: int in dirty:
		_paint(i % w, i / w, i)
	texture.update(image)
	index_texture.update(index_image)
	return dirty.size()

## Katakdagi belgini qaytaradi (0 — egasiz, 256+ — iz). Testlar uchun.
func index_at(x: int, y: int) -> int:
	var texel := index_image.get_pixel(x, y)
	var trail := int(round(texel.g * 255.0))
	if trail != 0:
		return 256 + trail
	var own := int(round(texel.r * 255.0))
	return 0 if own == WATER else own
