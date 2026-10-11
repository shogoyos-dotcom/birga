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
## Odam o'yinchining izi do'kondan tanlangan ko'rinishda chiziladi.
var _human_id := -1
var _human_look: Dictionary = Cosmetics.TRAILS["trail_plain"]
var _human_material: StandardMaterial3D = null

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
	_human_id = world.human().id
	apply_cosmetics()

## Do'kondan tanlangan iz ko'rinishini oladi.
##
## Oddiy iz uchun alohida material kerak emas — rang hamma uchun
## bir xil. Qolgan uchtasida rang har nuqtada o'zgaradi, shuning
## uchun u cho'qqi rangi orqali beriladi.
func apply_cosmetics() -> void:
	var id := Shop.worn_in(ShopManager.TRAILS)
	_human_look = Cosmetics.trail(id)
	if id == "trail_plain":
		_human_material = null
		return
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	# Shaffoflik "Spark" uchun kerak: uning dumi asta yo'qoladi.
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_human_material = mat

func _process(_delta: float) -> void:
	_mesh.clear_surfaces()
	if _world == null:
		return
	for p in _world.players:
		if p.alive and p.trail_path.size() >= 2:
			_add_ribbon(p)

func _add_ribbon(p: PlayerState) -> void:
	var path := p.trail_path
	# Pardozli iz faqat odam o'yinchida; botlarniki oddiy qoladi.
	var fancy := p.id == _human_id and _human_material != null
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP,
		_human_material if fancy else _materials[p.color_index])
	var base := Palette.trail(p.color_index)
	var y := ArenaBuilder.LAND_HEIGHT + LIFT
	var last := maxi(path.size() - 1, 1)
	for i in path.size():
		# Burchakda ikki kesmaning o'rtacha yo'nalishi olinadi, shunda
		# lenta uzilmaydi.
		var dir := _direction(path, i)
		var side := Vector2(-dir.y, dir.x) * (WIDTH * 0.5)
		var point := path[i]
		if fancy:
			_mesh.surface_set_color(Cosmetics.trail_color(
				base, _human_look, float(i) / float(last)))
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
