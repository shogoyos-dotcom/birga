extends Node

## O'yinchilar avatarlarini bitta teksturaga yig'adi va ularning
## hududdagi o'rnini shaderga uzatadi.
##
## Avatar emoji (yoki bayroq) bo'lgani uchun u shriftdan chiziladi:
## kichik `SubViewport` ichida har o'yinchiga bitta katak ajratilib,
## belgi bir marta chizib olinadi. Keyin arena shaderi shu teksturadan
## o'qiydi va avatarni **hudud shakliga kesib** qo'yadi — shuning uchun
## bitta avatar butun hududni egallaydi va chetidan chiqmaydi.
##
## Label3D lardan foydalanilmaydi: ular hudud shakliga kesilmaydi va
## har o'yinchi uchun alohida tugun kerak bo'lardi.

## Bitta avatar katagi (piksel).
const TILE := 192

## Teksturadagi ustunlar soni.
const COLS := 4

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

## Yangi o'yin: avatarlar qaytadan chiziladi.
func setup(world: GameWorld) -> void:
	_world = world
	_build_tiles()
	refresh()

func texture() -> Texture2D:
	return viewport.get_texture() if viewport != null else null

func grid_size() -> Vector2:
	return Vector2(COLS, rows)

func _build_tiles() -> void:
	if viewport != null:
		viewport.queue_free()
	rows = maxi(1, int(ceil(_world.players.size() / float(COLS))))

	viewport = SubViewport.new()
	viewport.size = Vector2i(COLS * TILE, rows * TILE)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	# Belgilar o'zgarmaydi — bir marta chizib olinadi.
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)

	var font := UiKit.emoji_font()
	for p in _world.players:
		var label := Label.new()
		label.text = Profile.map_glyph(p.avatar)
		label.position = Vector2(
			((p.id - 1) % COLS) * TILE, ((p.id - 1) / COLS) * TILE)
		label.size = Vector2(TILE, TILE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", int(TILE * 0.8))
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
		data_image.set_pixel(p.id, 0,
			Color(center.x, center.y, half, 1.0))
	data_texture.update(data_image)
