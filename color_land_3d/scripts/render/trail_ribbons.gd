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

## Lenta kengligi (katak) va uning oq hoshiyasi.
const WIDTH := 1.15
const EDGE := 0.42

## Arena yuzasidan balandligi — z-fighting bo'lmasin.
const LIFT := 0.07

var _mesh := ImmediateMesh.new()
var _world: GameWorld
var _materials: Array[StandardMaterial3D] = []
## Odam o'yinchining izi do'kondan tanlangan ko'rinishda chiziladi.
var _human_id := -1
var _human_look: Dictionary = Cosmetics.TRAILS["trail_plain"]
var _human_material: StandardMaterial3D = null
## Izning oq hoshiyasi — hamma o'yinchi uchun bitta material.
var _edge_material: StandardMaterial3D = null

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
	if _edge_material == null:
		# Oq hoshiya hamma iz uchun bitta material — iz rangidan
		# qat'i nazar bir xil.
		_edge_material = StandardMaterial3D.new()
		_edge_material.albedo_color = Color(1, 1, 1, 0.95)
		_edge_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_edge_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_edge_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_human_id = world.human().id
	_smooth_cache.clear()
	apply_cosmetics()

## Do'kondan tanlangan iz ko'rinishini oladi.
##
## Oddiy iz uchun alohida material kerak emas — rang hamma uchun
## bir xil. Qolgan uchtasida rang har nuqtada o'zgaradi, shuning
## uchun u cho'qqi rangi orqali beriladi.
func apply_cosmetics() -> void:
	# Do'kon daraxtdan olinadi, `Shop.` deb emas: avtoyuklangan
	# nomlar `--script` rejimida kompilyatsiya paytida yo'q, va bu
	# fayl testdan ham yuklanadi.
	var shop := get_node_or_null("/root/Shop")
	var id := "trail_plain"
	if shop != null:
		id = str(shop.worn_in(ShopManager.TRAILS))
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
			# Avval kengroq oq lenta, ustiga rangli — iz oq
			# chetli bo'lib chiqadi.
			_add_ribbon(p, true)
			_add_ribbon(p, false)

## Iz lentasini silliqlash: nechta marta o'tiladi va har o'tishda
## nuqta qo'shnilarining o'rtasiga qanchalik tortiladi.
const SMOOTH_PASSES := 8
const SMOOTH_PULL := 0.5
## Nuqta asl joyidan shuncha katakdan uzoqqa siljimaydi.
##
## Lentaning yarim kengligi 0.575 katak, shuning uchun bu chegarada
## lenta baribir o'z kataklarining ustida qoladi — ko'rinish
## yumshaydi, lekin iz boshqa joyga ko'chib ketmaydi.
const SMOOTH_LIMIT := 0.45
## Har kadrda yo'lning oxirgi shuncha nuqtasi qayta hisoblanadi.
##
## Yo'l faqat oxiridan o'sadi, silliqlash esa mahalliy: bir
## o'tishda o'zgarish bitta nuqta nariga ko'chadi, demak
## [constant SMOOTH_PASSES] o'tishdan keyin u eng ko'pi bilan
## shuncha nuqta orqaga yetadi. Oynadan chiqqan nuqta tinchigan
## bo'ladi va boshqa hisoblanmaydi — shuning uchun narx yo'lning
## uzunligiga emas, oynaga bog'liq.
const SMOOTH_WINDOW := 24

## Har o'yinchining silliqlangan yo'li.
##
## Oddiy [Array] ataylab: [PackedVector2Array] nusxa bilan ishlaydi
## (copy-on-write), oddiy massiv esa havola — har kadrda yuzlab
## nuqtani ko'chirish shart emas.
var _smooth_cache: Dictionary = {}

## Bir o'tish: `[from, to)` oralig'idagi nuqtalar qo'shnilarining
## o'rtasiga tortiladi. Joyida ishlaydi.
##
## Har nuqta **asl** joyidan [constant SMOOTH_LIMIT] dan uzoqqa
## ketmaydi, shuning uchun o'yinchi ataylab qilgan keskin burilish
## yo'qolmaydi — faqat katakdan kichik tishlar tekislanadi.
static func _sweep(out: Array, path: PackedVector2Array,
		from: int, to: int) -> void:
	for i in range(from, to):
		var before: Vector2 = out[i - 1]
		var after: Vector2 = out[i + 1]
		var here: Vector2 = out[i]
		var raw: Vector2 = path[i]
		var off: Vector2 = here.lerp((before + after) * 0.5, SMOOTH_PULL) - raw
		if off.length() > SMOOTH_LIMIT:
			off = off.normalized() * SMOOTH_LIMIT
		out[i] = raw + off

## Butun yo'lni boshidan silliqlaydi — testlar uchun.
##
## Qirg'oq bo'ylab yurganda suvga qaragan o'q to'siladi: o'yinchi
## bir oz gorizontal, keyin bir oz vertikal siljiydi va yo'l
## zinapoya bo'lib qoladi. Bu yerda u faqat **chizish uchun**
## tekislanadi — to'qnashuv va hudud baribir kataklar bo'yicha
## hisoblanadi, shuning uchun o'yin qoidalari o'zgarmaydi.
static func smooth_all(path: PackedVector2Array) -> Array:
	var out: Array = []
	out.resize(path.size())
	for i in path.size():
		out[i] = path[i]
	for _pass in SMOOTH_PASSES:
		_sweep(out, path, 1, path.size() - 1)
	return out

## O'yinchining silliqlangan yo'li — faqat oxirgi oyna qayta
## hisoblanadi.
func _smoothed(p: PlayerState) -> Array:
	var path := p.trail_path
	var n := path.size()
	var out: Array = _smooth_cache.get(p.id, [])
	# Yo'l qisqargan bo'lsa (yangi iz boshlangan) kesh yaroqsiz.
	if out.size() > n:
		out = []
	var from: int = 1 if out.size() < 2 else maxi(1, n - SMOOTH_WINDOW)
	out.resize(n)
	out[0] = path[0]
	for i in range(from, n):
		out[i] = path[i]
	for _pass in SMOOTH_PASSES:
		_sweep(out, path, from, n - 1)
	_smooth_cache[p.id] = out
	return out

func _add_ribbon(p: PlayerState, edge: bool) -> void:
	var path := _smoothed(p)
	# Pardozli iz faqat odam o'yinchida; botlarniki oddiy qoladi.
	var fancy := not edge and p.id == _human_id and _human_material != null
	var material: StandardMaterial3D = _edge_material if edge \
		else (_human_material if fancy else _materials[p.color_index])
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, material)
	var half := (WIDTH + (EDGE if edge else 0.0)) * 0.5
	var base := Palette.trail(p.color_index)
	var y := ArenaBuilder.LAND_HEIGHT + LIFT + (0.0 if edge else 0.012)
	var last := maxi(path.size() - 1, 1)
	for i in path.size():
		# Burchakda ikki kesmaning o'rtacha yo'nalishi olinadi, shunda
		# lenta uzilmaydi.
		var dir := _direction(path, i)
		var side := Vector2(-dir.y, dir.x) * half
		var point: Vector2 = path[i]
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

static func _direction(path: Array, i: int) -> Vector2:
	var here: Vector2 = path[i]
	var before: Vector2 = here - (path[maxi(i - 1, 0)] as Vector2)
	var after: Vector2 = (path[mini(i + 1, path.size() - 1)] as Vector2) - here
	var dir := before + after
	if dir.length_squared() < 1e-6:
		dir = after if after.length_squared() > 1e-6 else Vector2.RIGHT
	return dir.normalized()
