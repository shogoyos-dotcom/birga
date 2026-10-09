extends Node3D

## 3D sahna: arena, o'yinchilar, kamera va boshqaruv.
##
## Mantiq butunlay [GameWorld] ichida — bu yerda faqat chizish va
## kiritish. Shuning uchun qoidalar headless testlardan o'tadi.

## Kamera o'yinchidan qancha orqada va baland turadi.
const CAM_HEIGHT := 48.0
const CAM_BACK := 36.0
## Hudud ustidagi avatarning quyuqligi.
const AVATAR_ALPHA := 0.92
## Kamera o'yinchini qanchalik yumshoq kuzatadi (1/sekund).
const CAM_FOLLOW := 6.0
## Boshqaruv: barmoq shu masofadan uzoqlashsa yo'nalish hisoblanadi.
const DRAG_DEADZONE := 14.0
const DRAG_LEASH := 70.0

@onready var arena: MeshInstance3D = $Arena
@onready var ocean: MeshInstance3D = $Ocean
@onready var camera: Camera3D = $Camera3D
@onready var players_root: Node3D = $Players
@onready var ui: CanvasLayer = $Ui
@onready var sun: DirectionalLight3D = $Sun
@onready var world_env: WorldEnvironment = $WorldEnvironment

## Avatar teksturasi va poytaxt belgilari — kod bilan qo'shiladi,
## sahnada alohida tugun saqlanmaydi.
const ARENA_SHADER := preload("res://scripts/render/arena.gdshader")
const AvatarAtlasNode := preload("res://scripts/render/avatar_atlas.gd")
const TrailRibbonsNode := preload("res://scripts/render/trail_ribbons.gd")
const CapitalMarksNode := preload("res://scripts/render/capital_marks.gd")

var world: GameWorld
var paint: PaintLayer
var config := GameConfig.new()

var _heads: Array[MeshInstance3D] = []
var _avatars: Node
var _trails: MeshInstance3D
var _arena_material: ShaderMaterial
var _capitals: MultiMeshInstance3D
var _drag_origin := Vector2.ZERO
var _dragging := false
var _hud_timer := 0.0
## O'yin ketyaptimi. Boshlash va natija oynasida mantiq to'xtaydi.
var _playing := false

var store: SettingsStore
## O'limda bo'shagan kataklar — belet bilan davom etilganda qaytariladi.
var _cleared_on_death := PackedInt32Array()

func _ready() -> void:
	# Quyosh yuqoridan va yon tomondan tushadi: ustki yuzalar yorug',
	# yon devorlar to'q bo'lsin.
	sun.rotation_degrees = Vector3(-52.0, -38.0, 0.0)
	# Arena juda keng, shuning uchun standart bias bilan ustki yuza o'z
	# soyasiga tushib qoladi (shadow acne).
	sun.shadow_bias = 0.1
	sun.shadow_normal_bias = 3.0
	sun.directional_shadow_max_distance = 90.0

	_avatars = AvatarAtlasNode.new()
	add_child(_avatars)
	_trails = TrailRibbonsNode.new()
	add_child(_trails)
	_capitals = CapitalMarksNode.new()
	add_child(_capitals)

	store = SettingsStore.load_store()
	Strings.set_language(store.language if not store.language.is_empty()
		else Strings.detect_language())
	Palette.set_theme(store.theme_id)
	Audio.apply(store.music_enabled, store.sound_enabled,
		store.vibration_enabled)

	ui.setup(store)
	ui.play_pressed.connect(_on_play)
	ui.resume_pressed.connect(_on_resume)
	ui.menu_pressed.connect(_on_menu)
	ui.settings_changed.connect(_on_settings_changed)
	ui.view_changed.connect(_apply_view_settings)
	ui.continue_with_ticket.connect(_on_continue_with_ticket)
	_new_match()

func _config_from_store() -> GameConfig:
	var c := GameConfig.new()
	c.difficulty = Difficulty.from_name(store.difficulty_name)
	return c

## Yangi o'yin: dunyo, arena va o'yinchilar qaytadan quriladi.
func _new_match() -> void:
	config = _config_from_store()
	world = MatchBuilder.create(
		config, store.color_index, _player_name(), store.avatar, 0,
		_player_country())
	_clear_scene()
	_avatars.setup(world)
	_trails.setup(world)
	_build_arena()
	_build_players()
	_build_capitals()
	_apply_view_settings()
	_place_camera_instantly()

func _player_country() -> String:
	var saved := store.country
	return saved if not saved.is_empty() else Profile.detect_country()

func _player_name() -> String:
	var saved := store.nickname
	return saved if not saved.is_empty() else Strings.t("you")

func _on_play() -> void:
	_new_match()
	_playing = true
	ui.show_screen(ui.Screen.HUD)
	_apply_view_settings()

func _on_resume() -> void:
	_playing = true
	ui.show_screen(ui.Screen.HUD)
	_apply_view_settings()

func _on_menu() -> void:
	_playing = false
	ui.show_screen(ui.Screen.MENU)

## Rang, uslub yoki qiyinlik o'zgarsa — yangi o'yin tayyorlanadi.
func _on_settings_changed() -> void:
	Palette.set_theme(store.theme_id)
	_apply_sky()
	_new_match()

## Faqat ko'rinish kalitlari: o'yin to'xtamaydi.
func _apply_view_settings() -> void:
	if _arena_material != null:
		_arena_material.set_shader_parameter(
			"avatar_alpha", AVATAR_ALPHA if store.show_flags else 0.0)
	_capitals.enabled = store.show_capitals
	ui.set_minimap(paint.texture if store.show_minimap else null)

## Osmon va tuman rangi uslubdan olinadi.
func _apply_sky() -> void:
	var env := world_env.environment
	if env == null:
		return
	var sky := Palette.sky()
	env.background_color = sky
	env.fog_light_color = sky

func _on_continue_with_ticket() -> void:
	if not store.spend_ticket():
		ui.toast(Strings.t("noTickets"))
		return
	if world.revive(world.human(), _cleared_on_death):
		_avatars.refresh()
		_playing = true
		ui.show_screen(ui.Screen.HUD)
		return
	# Joy topilmadi — belet sarflanmagan hisoblanadi.
	store.add_tickets(1)
	ui.toast(Strings.t("noRoomToContinue"))

func _clear_scene() -> void:
	for head in _heads:
		head.queue_free()
	_heads.clear()

## Arena geometriyasi xaritaga bog'liq va o'yindan o'yinga o'zgarmaydi —
## bir marta quriladi. Har safar qayta qurish sezilarli sakrash berardi.
var _mesh_built := false

func _build_arena() -> void:
	if not _mesh_built:
		var built := ArenaBuilder.build(world.grid)
		arena.mesh = built["mesh"]
		_mesh_built = true
		print("Arena: %d to'rtburchak" % int(built["quads"]))

	paint = PaintLayer.new(world.grid, world.color_index_by_id)
	_apply_sky()

	# Ustki yuza: ranglarni shader hisoblaydi. Oddiy "nearest" filtrda
	# hudud chetlari zinapoya bo'lib qolardi — shader eng yaqin 4
	# katakning egasini taqqoslab, chegarani silliq chizadi.
	_arena_material = ShaderMaterial.new()
	_arena_material.shader = ARENA_SHADER
	_arena_material.set_shader_parameter("index_tex", paint.index_texture)
	_arena_material.set_shader_parameter("palette_tex", paint.palette_texture)
	_arena_material.set_shader_parameter("grid_size",
		Vector2(world.grid.width, world.grid.height))
	_arena_material.set_shader_parameter("avatar_tex", _avatars.texture())
	_arena_material.set_shader_parameter("avatar_data", _avatars.data_texture)
	_arena_material.set_shader_parameter("avatar_grid", _avatars.grid_size())
	arena.set_surface_override_material(0, _arena_material)

	var wall := StandardMaterial3D.new()
	wall.albedo_color = Palette.land_side()
	wall.roughness = 1.0
	arena.set_surface_override_material(1, wall)

	# Okean — xaritadan kattaroq tekis yuza.
	var plane := PlaneMesh.new()
	plane.size = Vector2(world.grid.width * 3.0, world.grid.height * 3.0)
	ocean.mesh = plane
	ocean.position = Vector3(world.grid.width / 2.0, 0.0, world.grid.height / 2.0)
	var sea := StandardMaterial3D.new()
	sea.albedo_color = Palette.ocean()
	sea.roughness = 0.3
	sea.metallic = 0.25
	ocean.set_surface_override_material(0, sea)

## Poytaxt belgilari xaritaga bog'liq — bir marta quriladi.
var _capitals_built := false

func _build_capitals() -> void:
	if _capitals_built:
		return
	_capitals_built = true
	var count: int = _capitals.build(world.capitals, world.grid)
	print("Poytaxtlar: %d belgi" % count)

## Bosh — o'yinchi rangidagi shar; ustida uning belgisi turadi.
const HEAD_RADIUS := 1.35

func _build_players() -> void:
	var ball := SphereMesh.new()
	ball.radius = HEAD_RADIUS
	ball.height = HEAD_RADIUS * 2.0
	# Mobil qurilma uchun kamroq uchburchak — bosh baribir kichik.
	ball.radial_segments = 16
	ball.rings = 8

	for p in world.players:
		var head := MeshInstance3D.new()
		head.mesh = ball
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Palette.head(p.color_index)
		mat.roughness = 0.6
		# O'yinchining o'zi biroz yaltiraydi — raqiblardan ajralib tursin.
		if not p.is_bot:
			mat.emission_enabled = true
			mat.emission = Palette.head(p.color_index)
			mat.emission_energy_multiplier = 0.45
		head.set_surface_override_material(0, mat)

		# Belgi sharning ustida, doim kameraga qarab turadi.
		var glyph := Sprite3D.new()
		var tile := AtlasTexture.new()
		tile.atlas = _avatars.texture()
		tile.region = _avatars.tile_region(p.id, _avatars.KIND_HEAD)
		glyph.texture = tile
		glyph.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		glyph.shaded = false
		# Shar ichiga kirib ketmasin.
		glyph.no_depth_test = true
		glyph.render_priority = 1
		glyph.pixel_size = HEAD_RADIUS * 2.1 / float(_avatars.TILE)
		head.add_child(glyph)

		players_root.add_child(head)
		_heads.append(head)

func _process(delta: float) -> void:
	if _playing:
		world.update(delta)
		_handle_events()
		if not world.human().alive:
			_end_match()
	paint.sync()
	_sync_heads()
	_follow_camera(delta)

	_hud_timer -= delta
	if _hud_timer <= 0.0:
		_hud_timer = 0.12
		_refresh_hud()

## Mantiq chiqargan hodisalar: ovoz va o'limda bo'shagan kataklar.
func _handle_events() -> void:
	var human_id := world.human().id
	for event in world.drain_events():
		match event["type"]:
			"capture":
				if int(event["player"]) == human_id:
					Audio.capture()
					ui.flash(Palette.head(world.human().color_index), 0.18)
			"death":
				if int(event["player"]) == human_id:
					_cleared_on_death = event["cleared"]
					Audio.death()
					ui.flash(UiKit.CORAL, 0.34)
				elif int(event["killer"]) == human_id:
					Audio.kill()
					ui.flash(UiKit.MINT, 0.16)

func _end_match() -> void:
	_playing = false
	_dragging = false
	var p := world.human()
	var percent := world.percent_of(p)
	var is_record := store.submit_result(percent, p.kills)
	ui.set_result(percent, p.kills, world.elapsed,
		Strings.death_reason(p.death_cause), is_record)
	ui.show_screen(ui.Screen.RESULT)


func _sync_heads() -> void:
	for i in world.players.size():
		var p := world.players[i]
		var head := _heads[i]
		head.visible = p.alive
		if not p.alive:
			continue
		head.position = Vector3(
			p.x, ArenaBuilder.LAND_HEIGHT + HEAD_RADIUS, p.y)

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
	if not _playing:
		return
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

## Skrinshot vositasi uchun: kerakli ekranni ochadi.
func show_screen_for_demo(name: String) -> void:
	match name:
		"menu": ui.show_screen(ui.Screen.MENU)
		"settings": ui.show_screen(ui.Screen.SETTINGS)
		"profile": ui.show_screen(ui.Screen.PROFILE)
		"pause": ui.show_screen(ui.Screen.PAUSE)
		"shop": ui.open_shop(ui.Screen.MENU)
		"result":
			ui.set_result(12.34, 3, 95.0,
				Strings.death_reason(PlayerState.DeathCause.TRAIL_HIT), true)
			ui.show_screen(ui.Screen.RESULT)

## Skrinshot vositasi uchun: avatarni almashtiradi.
func set_avatar_for_demo(value: String) -> void:
	if store.avatar == value:
		return
	store.avatar = value
	_new_match()

## Skrinshot vositasi uchun: o'yinni boshlab yuboradi.
func start_for_demo() -> void:
	if not _playing:
		_on_play()

## Tashqaridan (skrinshot vositasidan) boshqarish uchun.
func steer_human(angle: float) -> void:
	world.human().steer_to(angle)

## Skrinshot vositasi uchun: o'lgan o'yinchini qaytadan joylashtiradi.
## Haqiqiy o'yinda bu yerda natija oynasi chiqadi (keyingi bosqich).
func revive_human_for_demo() -> void:
	var p := world.human()
	if not p.alive:
		world.spawn(p)
		_playing = true
		ui.show_screen(ui.Screen.HUD)

func _refresh_hud() -> void:
	var p := world.human()
	ui.update_hud(
		world.percent_of(p), p.kills, world.elapsed,
		world.rank_of(p), world.alive_count(), _leaderboard(),
		Vector2(p.x / world.grid.width, p.y / world.grid.height))

## Top-5 reyting.
func _leaderboard() -> Array:
	var sorted := world.players.duplicate()
	sorted.sort_custom(func(a: PlayerState, b: PlayerState) -> bool:
		return world.grid.territory_of(a.id) > world.grid.territory_of(b.id))
	var rows: Array = []
	for i in mini(5, sorted.size()):
		var p: PlayerState = sorted[i]
		rows.append({
			"name": p.player_name,
			"avatar": p.avatar,
			"color": p.color_index,
			"percent": world.grid.percent_of(p.id),
			"is_human": not p.is_bot,
		})
	return rows
