class_name PaintLayer
extends RefCounted

## Egalik ma'lumoti: har katak uchun bitta piksel.
##
## Hududlar va izlar alohida mesh emas, arena ustidagi tekstura bo'lib
## chiziladi — shuning uchun minglab katak o'zgarsa ham geometriya
## qayta qurilmaydi. Faqat o'zgargan kataklar qayta bo'yaladi.
##
## Ikkita tekstura tayyorlanadi:
##  * [index_texture] — R: hudud egasi, G: iz egasi. Arena shaderi shuni
##    o'qib chegaralarni silliq chizadi;
##  * [texture] — tayyor ranglar; kichik xarita shuni ko'rsatadi.

## Rang jadvali o'lchami: 0 — egasiz, 1..255 — hudud, 256..511 — iz.
const PALETTE_SIZE := 512

var image: Image
var texture: ImageTexture
var index_image: Image
var index_texture: ImageTexture
## 512x1 rang jadvali — shader shundan rang oladi.
var palette_image: Image
var palette_texture: ImageTexture

var _grid: GameGrid
var _colors: PackedColorArray

func _init(grid: GameGrid, color_index_by_id: PackedByteArray) -> void:
	_grid = grid
	image = Image.create_empty(grid.width, grid.height, false, Image.FORMAT_RGBA8)
	index_image = Image.create_empty(
		grid.width, grid.height, false, Image.FORMAT_RG8)
	_rebuild_colors(color_index_by_id)
	_paint_all()
	texture = ImageTexture.create_from_image(image)
	index_texture = ImageTexture.create_from_image(index_image)
	palette_texture = ImageTexture.create_from_image(palette_image)

## O'yinchi ranglarini oldindan hisoblaydi: 0 — egasiz, 1..255 — hudud,
## 256..511 — o'sha ID ning izi.
##
## Rang jadvali to'liq noshaffof: shaffof piksel qop-qora bo'lib
## qolardi.
func _rebuild_colors(color_index_by_id: PackedByteArray) -> void:
	_colors = PackedColorArray()
	_colors.resize(PALETTE_SIZE)
	_colors[0] = Palette.land()
	for id in range(1, 256):
		var ci: int = color_index_by_id[id]
		_colors[id] = Palette.territory(ci)
		_colors[256 + id] = Palette.trail(ci)
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
	# Shaderga ID lar 0..1 oralig'ida uzatiladi.
	index_image.set_pixel(x, y, Color(own / 255.0, trail / 255.0, 0.0, 1.0))

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
	return int(round(texel.r * 255.0))
