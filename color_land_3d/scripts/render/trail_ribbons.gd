extends MeshInstance3D

## Izlar — arena ustidagi lenta.
##
## Iz panjarada kataklar bo'yicha saqlanadi, lekin kataklardan chizilsa
## chiziq zinapoyaga aylanadi va silliqlangandan keyin ham to'lqinli
## ko'rinadi. Shuning uchun lenta o'yinchining **uzluksiz yo'li**
## (`PlayerState.trail_path`) bo'yicha quriladi: to'g'ri borgan joyda
## chiziq ham to'g'ri bo'ladi.
##
## Yo'l mantiq qatlamida soddalashtirib boriladi, shuning uchun bir
## o'yinchida odatda o'nlab emas, bir nechta nuqta bo'ladi va lentani
## har kadrda qaytadan qurish arzon.

## Lenta kengligi (katak).
const WIDTH := 1.15

## Arena yuzasidan balandligi — z-fighting bo'lmasin.
const LIFT := 0.07

var _mesh := ImmediateMesh.new()
var _world: GameWorld
var _materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	mesh = _mesh
	# Lenta soya bermaydi: ingichka chiziqning soyasi faqat shovqin.
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func setup(world: GameWorld) -> void:
	_world = world
	# ImmediateMesh har kadrda qaytadan quriladi va uning chegarasi
	# kech yangilanadi — kamera ko'rish maydonidan chiqib qolmasin
	# uchun chegara qo'lda beriladi.
	custom_aabb = AABB(Vector3.ZERO,
		Vector3(world.grid.width, 8.0, world.grid.height))
	_materials.clear()
	for i in Palette.color_count():
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Palette.trail(i)
		# Yoritilmaydi: lenta arena yuzasiga juda yaqin turadi va
		# uning soyasiga tushib, qorayib qolardi. Yoritilmagan holda
		# iz doim bir xil yorqin ko'rinadi — o'yinchi o'z yo'lini
		# uzoqdan ham ajratadi.
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		# Lenta — tekis yuza; chiziq yo'nalishiga qarab uchburchaklar
		# teskari tomonga qarab qolishi mumkin, shuning uchun ikki
		# tomoni ham chiziladi.
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials.append(mat)

func _process(_delta: float) -> void:
	_mesh.clear_surfaces()
	if _world == null:
		return
	for p in _world.players:
		if p.alive and p.trail_path.size() >= 2:
			_add_ribbon(p)

func _add_ribbon(p: PlayerState) -> void:
	var path := p.trail_path
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP,
		_materials[p.color_index])
	var y := ArenaBuilder.LAND_HEIGHT + LIFT
	for i in path.size():
		# Burchakda ikki kesmaning o'rtacha yo'nalishi olinadi, shunda
		# lenta uzilmaydi.
		var dir := _direction(path, i)
		var side := Vector2(-dir.y, dir.x) * (WIDTH * 0.5)
		var point := path[i]
		_mesh.surface_set_normal(Vector3.UP)
		_mesh.surface_add_vertex(
			Vector3(point.x - side.x, y, point.y - side.y))
		_mesh.surface_set_normal(Vector3.UP)
		_mesh.surface_add_vertex(
			Vector3(point.x + side.x, y, point.y + side.y))
	_mesh.surface_end()

static func _direction(path: PackedVector2Array, i: int) -> Vector2:
	var before := path[i] - path[maxi(i - 1, 0)]
	var after := path[mini(i + 1, path.size() - 1)] - path[i]
	var dir := before + after
	if dir.length_squared() < 1e-6:
		dir = after if after.length_squared() > 1e-6 else Vector2.RIGHT
	return dir.normalized()
