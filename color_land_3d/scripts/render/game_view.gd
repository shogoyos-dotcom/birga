extends Node3D

## 3D sahna: arena, o'yinchilar, kamera va boshqaruv.
##
## Mantiq butunlay [GameWorld] ichida — bu yerda faqat chizish va
## kiritish. Shuning uchun qoidalar headless testlardan o'tadi.

## Kamera o'yinchidan qancha orqada va baland turadi.
const CAM_HEIGHT := 48.0
const CAM_BACK := 36.0
## Kamera o'yinchini qanchalik yumshoq kuzatadi (1/sekund).
const CAM_FOLLOW := 6.0
## Boshqaruv: barmoq shu masofadan uzoqlashsa yo'nalish hisoblanadi.
const DRAG_DEADZONE := 14.0
const DRAG_LEASH := 70.0

@onready var arena: MeshInstance3D = $Arena
@onready var ocean: MeshInstance3D = $Ocean
@onready var camera: Camera3D = $Camera3D
@onready var players_root: Node3D = $Players
@onready var hud: Control = $Hud
@onready var sun: DirectionalLight3D = $Sun

var world: GameWorld
var paint: PaintLayer
var config := GameConfig.new()

var _heads: Array[MeshInstance3D] = []
var _drag_origin := Vector2.ZERO
var _dragging := false
var _hud_timer := 0.0

func _ready() -> void:
	# Quyosh yuqoridan va yon tomondan tushadi: ustki yuzalar yorug',
	# yon devorlar to'q bo'lsin.
	sun.rotation_degrees = Vector3(-52.0, -38.0, 0.0)
	# Arena juda keng (520x205), shuning uchun standart bias bilan ustki
	# yuza butunlay o'z soyasiga tushib qoladi (shadow acne). Bias va
	# soya masofasi arenaga moslab qo'yiladi.
	sun.shadow_bias = 0.1
	sun.shadow_normal_bias = 3.0
	sun.directional_shadow_max_distance = 90.0

	config.difficulty = Difficulty.new(Difficulty.Level.NORMAL)
	world = MatchBuilder.create(config, 0, "Siz", 3)

	_build_arena()
	_build_players()
	_place_camera_instantly()
	_refresh_hud()

func _build_arena() -> void:
	var built := ArenaBuilder.build(world.grid)
	arena.mesh = built["mesh"]
	print("Arena: %d to'rtburchak" % int(built["quads"]))

	paint = PaintLayer.new(world.grid, world.color_index_by_id)

	# Ustki yuza: egalik teksturasi quruqlik rangi ustiga tushadi.
	# Albedo oq: butun rang teksturadan keladi (material rangni
	# teksturaga ko'paytiradi).
	var top := StandardMaterial3D.new()
	top.albedo_color = Color.WHITE
	top.albedo_texture = paint.texture
	top.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	top.roughness = 0.9
	arena.set_surface_override_material(0, top)

	var wall := StandardMaterial3D.new()
	wall.albedo_color = Palette.LAND_SIDE
	wall.roughness = 1.0
	arena.set_surface_override_material(1, wall)

	# Okean — xaritadan kattaroq tekis yuza.
	var plane := PlaneMesh.new()
	plane.size = Vector2(world.grid.width * 3.0, world.grid.height * 3.0)
	ocean.mesh = plane
	ocean.position = Vector3(world.grid.width / 2.0, 0.0, world.grid.height / 2.0)
	var sea := StandardMaterial3D.new()
	sea.albedo_color = Palette.OCEAN
	sea.roughness = 0.3
	sea.metallic = 0.25
	ocean.set_surface_override_material(0, sea)

func _build_players() -> void:
	var box := BoxMesh.new()
	box.size = Vector3(2.2, 2.2, 2.2)
	for p in world.players:
		var head := MeshInstance3D.new()
		head.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Palette.head(p.color_index)
		mat.roughness = 0.6
		# O'yinchining o'zi biroz yaltiraydi — raqiblardan ajralib tursin.
		if not p.is_bot:
			mat.emission_enabled = true
			mat.emission = Palette.head(p.color_index)
			mat.emission_energy_multiplier = 0.45
		head.set_surface_override_material(0, mat)
		players_root.add_child(head)
		_heads.append(head)

func _process(delta: float) -> void:
	world.update(delta)
	paint.sync()
	_sync_heads()
	_follow_camera(delta)

	_hud_timer -= delta
	if _hud_timer <= 0.0:
		_hud_timer = 0.12
		_refresh_hud()

func _sync_heads() -> void:
	for i in world.players.size():
		var p := world.players[i]
		var head := _heads[i]
		head.visible = p.alive
		if not p.alive:
			continue
		head.position = Vector3(p.x, ArenaBuilder.LAND_HEIGHT + 1.1, p.y)
		# Kub yurish yo'nalishiga qarab biroz buriladi — jonli ko'rinadi.
		head.rotation.y = -p.angle

func _player_target() -> Vector3:
	var p := world.human()
	return Vector3(p.x, ArenaBuilder.LAND_HEIGHT, p.y)

func _place_camera_instantly() -> void:
	var target := _player_target()
	camera.position = target + Vector3(0.0, CAM_HEIGHT, CAM_BACK)
	camera.look_at(target, Vector3.UP)

func _follow_camera(delta: float) -> void:
	var target := _player_target()
	var want := target + Vector3(0.0, CAM_HEIGHT, CAM_BACK)
	camera.position = camera.position.lerp(want, minf(1.0, CAM_FOLLOW * delta))
	camera.look_at(target, Vector3.UP)

# ——— Boshqaruv: ekranni surish ———

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_drag_origin = touch.position
			_dragging = true
		else:
			_dragging = false
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index == MOUSE_BUTTON_LEFT:
			_drag_origin = click.position
			_dragging = click.pressed
	elif event is InputEventScreenDrag:
		_steer((event as InputEventScreenDrag).position)
	elif event is InputEventMouseMotion and _dragging:
		_steer((event as InputEventMouseMotion).position)

func _steer(at: Vector2) -> void:
	if not _dragging:
		return
	var delta := at - _drag_origin
	if delta.length() < DRAG_DEADZONE:
		return
	# Ekran o'qlari dunyo o'qlariga to'g'ri keladi: kamera tepadan
	# qaraydi va burilmaydi, shuning uchun qo'shimcha aylantirish kerak
	# emas.
	world.human().steer_to(atan2(delta.y, delta.x))
	# Barmoq uzoqlashsa boshlang'ich nuqtani ergashtiramiz.
	if delta.length() > DRAG_LEASH:
		_drag_origin = at - delta.normalized() * DRAG_LEASH

## Tashqaridan (skrinshot vositasidan) boshqarish uchun.
func steer_human(angle: float) -> void:
	world.human().steer_to(angle)

## Skrinshot vositasi uchun: o'lgan o'yinchini qaytadan joylashtiradi.
## Haqiqiy o'yinda bu yerda natija oynasi chiqadi (keyingi bosqich).
func revive_human_for_demo() -> void:
	var p := world.human()
	if not p.alive:
		world.spawn(p)

func _refresh_hud() -> void:
	var p := world.human()
	hud.set_stats(
		world.percent_of(p),
		p.kills,
		world.elapsed,
		world.rank_of(p),
		world.alive_count())
