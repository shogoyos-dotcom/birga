class_name PaintLayer
extends RefCounted

## Egalik teksturasi: har katak uchun bitta piksel.
##
## Hududlar va izlar alohida mesh emas, arena ustidagi tekstura bo'lib
## chiziladi — shuning uchun minglab katak o'zgarsa ham geometriya
## qayta qurilmaydi. Faqat o'zgargan kataklar qayta bo'yaladi.

var image: Image
var texture: ImageTexture
var _grid: GameGrid
var _colors: PackedColorArray

func _init(grid: GameGrid, color_index_by_id: PackedByteArray) -> void:
	_grid = grid
	image = Image.create_empty(grid.width, grid.height, false, Image.FORMAT_RGBA8)
	_rebuild_colors(color_index_by_id)
	_paint_all()
	texture = ImageTexture.create_from_image(image)

## O'yinchi ranglarini oldindan hisoblaydi: 0 — egasiz, 1..255 — hudud,
## 256..511 — o'sha ID ning izi.
##
## Tekstura to'liq noshaffof: material albedo rangini teksturaga
## ko'paytiradi, shuning uchun shaffof piksel qop-qora bo'lib qolardi.
func _rebuild_colors(color_index_by_id: PackedByteArray) -> void:
	_colors = PackedColorArray()
	_colors.resize(512)
	_colors[0] = Palette.LAND
	for id in range(1, 256):
		var ci: int = color_index_by_id[id]
		_colors[id] = Palette.territory(ci)
		_colors[256 + id] = Palette.trail(ci)

func _paint_all() -> void:
	for y in _grid.height:
		var row := y * _grid.width
		for x in _grid.width:
			image.set_pixel(x, y, _color_at(row + x))

func _color_at(i: int) -> Color:
	var t: int = _grid.trail_cells[i]
	if t != 0:
		return _colors[256 + t]
	return _colors[_grid.owner_cells[i]]

## Panjaradagi o'zgarishlarni teksturaga ko'chiradi.
## O'zgargan katak sonini qaytaradi.
func sync() -> int:
	var dirty := _grid.take_dirty()
	if dirty.is_empty():
		return 0
	var w := _grid.width
	for i: int in dirty:
		image.set_pixel(i % w, i / w, _color_at(i))
	texture.update(image)
	return dirty.size()
