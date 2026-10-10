extends Node

## O'yinchilarning belgilarini bitta teksturaga yig'adi va hududdagi
## o'rnini shaderga uzatadi.
##
## Har o'yinchiga ikkita katak ajratiladi:
##  * [KIND_HEAD] — bosh ustidagi belgi (emoji yoki odam tasviri);
##  * [KIND_FLAG] — hududni egallaydigan davlat bayrog'i.
##
## Belgilar emoji shriftidan chiziladi, shuning uchun ular kichik
## `SubViewport` ichida bir marta chizib olinadi. Keyin arena shaderi
## bayroqni o'qiydi va **hudud shakliga kesib** qo'yadi, bosh ustidagi
## belgi esa shu teksturaning bir bo'lagi sifatida ishlatiladi.

## Bitta katak (piksel). Emoji shrifti bitmap bo'lgani uchun undan
## kattaroq qilishning foydasi yo'q.
const TILE := 192

## Teksturadagi ustunlar soni.
const COLS := 8

## Katak turlari.
const KIND_HEAD := 0
const KIND_FLAG := 1

## Joylashuv sekundda shuncha marta qayta hisoblanadi.
const REFRESH := 0.25

var viewport: SubViewport
## O'yinchi ID bo'yicha joylashuv: R — markaz X, G — markaz Y,
## B — yarim o'lcham (katakda).
var data_image: Image
var data_texture: ImageTexture
var rows := 1

var _world: GameWorld
var _timer := 0.0

func _ready() -> void:
	data_image = Image.create_empty(256, 1, false, Image.FORMAT_RGBAF)
	data_texture = ImageTexture.create_from_image(data_image)

## Yangi o'yin: belgilar qaytadan chiziladi.
func setup(world: GameWorld) -> void:
	_world = world
	_build_tiles()
	refresh()

func texture() -> Texture2D:
	return viewport.get_texture() if viewport != null else null

func grid_size() -> Vector2:
	return Vector2(COLS, rows)

## Katak raqami: har o'yinchiga ikkita.
static func tile_index(id: int, kind: int) -> int:
	return (id - 1) * 2 + kind

## Bosh ustidagi belgi uchun teksturadan kesib olinadigan to'rtburchak.
func tile_region(id: int, kind: int) -> Rect2:
	var index := tile_index(id, kind)
	return Rect2((index % COLS) * TILE, (index / COLS) * TILE, TILE, TILE)

func _build_tiles() -> void:
	if viewport != null:
		viewport.queue_free()
	var count := _world.players.size() * 2
	rows = maxi(1, int(ceil(count / float(COLS))))

	viewport = SubViewport.new()
	viewport.size = Vector2i(COLS * TILE, rows * TILE)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	# Belgilar o'yin davomida o'zgarmaydi — bir marta chizib olinadi.
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)

	for p in _world.players:
		_add_tile(tile_index(p.id, KIND_HEAD),
			Profile.map_glyph(p.avatar), p.avatar_image)
		_add_tile(tile_index(p.id, KIND_FLAG),
			Profile.flag_emoji(p.country), p.flag_image)

## Katakka o'yinchi rasmini yoki belgisini chizadi.
func _add_tile(index: int, glyph: String, image_path: String) -> void:
	var at := Vector2((index % COLS) * TILE, (index / COLS) * TILE)
	var texture := ImagePicker.load_texture(image_path)
	if texture != null:
		var picture := TextureRect.new()
		picture.texture = texture
		picture.position = at
		picture.size = Vector2(TILE, TILE)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		viewport.add_child(picture)
		return
	var label := Label.new()
	label.text = glyph
	label.position = at
	label.size = Vector2(TILE, TILE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", int(TILE * 0.8))
	var font := UiKit.emoji_font()
	if font != null:
		label.add_theme_font_override("font", font)
	viewport.add_child(label)

func _process(delta: float) -> void:
	if _world == null:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = REFRESH
		refresh()

## Har o'yinchining hududidagi markazi va o'lchamini yangilaydi.
func refresh() -> void:
	if _world == null:
		return
	for p in _world.players:
		var place := AvatarPlacement.of(_world.grid, p.id)
		var half: float = place["half"] if p.alive else 0.0
		var center: Vector2 = place["center"]
		data_image.set_pixel(p.id, 0, Color(center.x, center.y, half, 1.0))
	data_texture.update(data_image)
