extends Node3D

const WorldPacing = preload("res://scripts/logic/world_pacing.gd")

## 3D sahna: arena, o'yinchilar, kamera va boshqaruv.
##
## Mantiq butunlay [GameWorld] ichida — bu yerda faqat chizish va
## kiritish. Shuning uchun qoidalar headless testlardan o'tadi.

## Kamera o'yinchidan qancha orqada va baland turadi.
const CAM_HEIGHT := WorldPacing.CAM_HEIGHT_EXPANDED
const CAM_BACK := WorldPacing.CAM_BACK_EXPANDED
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
const WATER_SHADER := preload("res://scripts/render/water.gdshader")
const AvatarAtlasNode := preload("res://scripts/render/avatar_atlas.gd")
const TrailRibbonsNode := preload("res://scripts/render/trail_ribbons.gd")
const CapitalMarksNode := preload("res://scripts/render/capital_marks.gd")
const CityCoinsNode := preload("res://scripts/render/city_coins.gd")
const PickupMarksNode := preload("res://scripts/render/pickup_marks.gd")
const CaptureBurstNode := preload("res://scripts/render/capture_burst.gd")
const FlagPolesNode := preload("res://scripts/render/flag_poles.gd")
const CityRendererNode := preload("res://scripts/render/city_renderer.gd")
const CitySystem := preload("res://scripts/logic/city_system.gd")
const DesignDrawers := preload("res://scripts/ui/design_drawers.gd")

var _crown_image: ImageTexture
var _slime_face_image: ImageTexture
var _flag_poles: FlagPoles

var world: GameWorld
var paint: PaintLayer
var config := GameConfig.new()

var _heads: Array[MeshInstance3D] = []
## Bosh ustidagi yorliqlar: ism va foiz.
var _name_tags: Array[Label3D] = []
## Yetakchining tojlari — har o'yinchida bor, lekin faqat
## birinchi o'rindagisi ko'rinadi.
var _crowns: Array[Sprite3D] = []
var _percent_tags: Array[Label3D] = []
var _shadow_discs: Array[MeshInstance3D] = []
var _avatars: Node
var _trails: MeshInstance3D
var _arena_material: ShaderMaterial
var _capitals: MultiMeshInstance3D
var _city_renderer: Node3D
## Shaharlar ustidagi tangalar: mantiq va chizuvchi.
var _coin_field := CoinField.new()
## Shu o'yinda nechta marta hudud egallandi — kunlik topshiriq uchun.
var _captures := 0
var _coins: MultiMeshInstance3D
## Yo'lda yotgan tangalar va kuchaytirgich sferalari.
var _pickup_field := PickupField.new()
var _pickups: Node3D
## Shu o'yinda yo'ldan terilgan tanga.
var _loose_coins := 0
## Shu o'yinda olingan sferalar (qalqon va tezlik).
var _spheres_collected := 0
## Shu o'yinda tirilish amalga oshirilganmi.
var _human_revived := false
## Tezlik kuchaytirgichi shu vaqtgacha ishlaydi (dunyo soati).
var _boost_until := 0.0
## O'yinchining asl tezligi — kuchaytirgich tugagach shunga qaytadi.
var _base_speed := 0.0
## Hudud egallaganda chiqadigan effekt (do'kondan tanlanadi).
var _burst: CPUParticles3D
var _drag_origin := Vector2.ZERO
var _dragging := false
var _hud_timer := 0.0
## Mahalliy o'yinchi boshqaruvdami (o'lsa yoki pauzada — yo'q).
var _playing := false
## Dunyo shu qurilmada hisoblanadimi.
##
## Uy egasida bu `_playing` dan ajralib turadi: uning o'zi o'lsa ham
## yoki natija oynasini ochsa ham, xonadagi boshqalar uchun o'yin
## davom etishi kerak. Mehmonda esa hech qachon `true` bo'lmaydi —
## hamma hisob uy egasida.
var _match_running := false

## Boshqaruvni yoqadi/o'chiradi va dunyo hisoblanishini shunga moslaydi.
func _set_playing(value: bool) -> void:
	_playing = value
	_match_running = Net.is_host() if Net.is_online() else value

var store: SettingsStore
## O'limda bo'shagan kataklar — belet bilan davom etilganda qaytariladi.
var _cleared_on_death := PackedInt32Array()

# ——— Phase 6: Shahar istilolari va o'yin iqtisodiyoti ———
var _match_id: String = ""
var _city_reward_tracker: CitySystem.CityRewardTracker = CitySystem.CityRewardTracker.new()
var _match_conquest_coins: int = 0
var _duplicates_prevented_count: int = 0

func _ready() -> void:
	# Quyosh yuqoridan va yon tomondan tushadi: yorqin va toza kunduzgi yorug'lik
	sun.rotation_degrees = Vector3(-56.0, -35.0, 0.0)
	sun.light_color = Color(1.0, 0.98, 0.94)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_blend_splits = true
	sun.shadow_bias = 0.05
	sun.shadow_normal_bias = 0.8
	sun.shadow_blur = 1.2

	# Kamera ko'rinishi: kengaytirilgan dunyoni to'liq qamrab olish uchun
	camera.near = 0.5
	camera.far = WorldPacing.CAM_FAR_EXPANDED

	# Yer va okean tekisliklari o'z ustiga qora chiziqli soya tashlamasligi uchun
	arena.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ocean.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_avatars = AvatarAtlasNode.new()
	add_child(_avatars)
	_trails = TrailRibbonsNode.new()
	add_child(_trails)
	_capitals = CapitalMarksNode.new()
	add_child(_capitals)
	_coins = CityCoinsNode.new()
	add_child(_coins)
	_pickups = PickupMarksNode.new()
	add_child(_pickups)
	_burst = CaptureBurstNode.new()
	add_child(_burst)
	_flag_poles = FlagPolesNode.new()
	add_child(_flag_poles)
	_city_renderer = CityRendererNode.new()
	add_child(_city_renderer)
	_city_renderer.city_selected.connect(_on_city_selected)

	store = SettingsStore.load_store()
	Strings.set_language(store.language if not store.language.is_empty()
		else Strings.detect_language())
	CityNames.use(Strings.language())
	Palette.set_theme(store.theme_id)
	Audio.apply(store)

	ui.setup(store)
	if _server_mode():
		_start_dedicated_server()
		return
	ui.play_pressed.connect(_on_play)
	ui.pause_pressed.connect(_on_pause)
	ui.resume_pressed.connect(_on_resume)
	ui.menu_pressed.connect(_on_menu)
	ui.settings_changed.connect(_on_settings_changed)
	ui.view_changed.connect(_apply_view_settings)
	ui.continue_with_ticket.connect(_on_continue_with_ticket)
	ui.host_pressed.connect(_on_host)
	ui.join_pressed.connect(_on_join)
	Net.joined.connect(_on_joined)
	Net.roster_changed.connect(_sync_net_players)
	Net.stopped.connect(_on_net_stopped)
	Board.loaded.connect(func(_scope: String, rows: Array) -> void:
		ui.set_board(rows))
	Board.failed.connect(func(reason: String) -> void:
		ui.set_board_error(reason))
	_new_match()

func _config_from_store() -> GameConfig:
	var c := GameConfig.new()
	c.difficulty = Difficulty.from_name(store.difficulty_name)
	c.map_id = store.map_id
	return c

## Yangi o'yin: dunyo, arena va o'yinchilar qaytadan quriladi.
func _new_match() -> void:
	_captures = 0
	_match_id = "%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 100000]
	_city_reward_tracker.reset(_match_id)
	_match_conquest_coins = 0
	_duplicates_prevented_count = 0
	config = _config_from_store()
	world = MatchBuilder.create(
		config, store.color_index, _player_name(), store.avatar, 0,
		_player_country(),
		PackedStringArray([store.avatar_image, store.flag_image]))
	_clear_scene()
	_avatars.setup(world)
	_trails.setup(world)
	_build_arena()
	_build_players()
	_flag_poles.setup(world)
	_build_capitals()
	_build_coins()
	_build_pickups()
	_apply_view_settings()
	_place_camera_instantly()

# ——— Maxsus server ———

## Buyruq satrida `--server` berilganmi.
##
## Shu rejimda o'yin interfeyssiz ishlaydi va faqat xona bo'lib
## xizmat qiladi: VPS da shu bilan doimiy server ko'tariladi.
##   colorland.x86_64 --server --headless [--port 7777]
static func _server_mode() -> bool:
	return OS.get_cmdline_args().has("--server")

static func _server_port() -> int:
	var args := OS.get_cmdline_args()
	var at := args.find("--port")
	if at >= 0 and at + 1 < args.size():
		return int(args[at + 1])
	return Net.PORT

func _start_dedicated_server() -> void:
	var port := _server_port()
	var error := Net.host_room(port)
	if not error.is_empty():
		push_error("Server ochilmadi: %s" % error)
		get_tree().quit(1)
		return
	_new_match()
	# Serverning o'z o'yinchisi bo'sh turmasin — u ham bot bo'lib
	# o'ynaydi, shunda xona jonli ko'rinadi.
	var owner_player := world.human()
	owner_player.is_bot = true
	owner_player.player_name = "Server"
	owner_player.brain = BotBrain.new(config.difficulty, RandomNumberGenerator.new())
	Net.attach_world(world, _profile())
	_match_running = true
	ui.visible = false
	print("Color Land server: %s port %d, maydon %s" % [
		Net.local_address(), port, config.map_id])

# ——— Tarmoq ———

## Tarmoqqa yuboriladigan profil.
func _profile() -> Dictionary:
	return {
		"name": _player_name(), "color": store.color_index,
		"avatar": store.avatar, "country": _player_country(),
	}

## Xona ochish: o'yin odatdagidek boshlanadi, lekin tarmoqqa ulanadi.
func _on_host() -> void:
	var error := Net.host_room()
	if not error.is_empty():
		ui.set_room_status(Strings.t("connectFailed"))
		return
	_new_match()
	Net.attach_world(world, _profile())
	_set_playing(true)
	ui.show_screen(ui.Screen.HUD)
	_apply_view_settings()

func _on_join(address: String) -> void:
	var error := Net.join_room(address, _profile())
	if not error.is_empty():
		ui.set_room_status(Strings.t("connectFailed"))

## Uy egasi qabul qildi: uning maydonida bo'sh dunyo quriladi va
## o'yinchilar ro'yxat bilan to'ldiriladi.
func _on_joined(player_id: int, map_id: String) -> void:
	config = _config_from_store()
	config.map_id = map_id
	config.bot_count = 0
	world = GameWorld.new(config, 0)
	world.local_index = 0
	_clear_scene()
	_avatars.setup(world)
	_trails.setup(world)
	_build_arena()
	_build_capitals()
	Net.attach_world(world, _profile())
	_sync_net_players()
	_set_playing(true)
	ui.show_screen(ui.Screen.HUD)
	_apply_view_settings()

## Ro'yxat o'zgardi: mehmonda o'yinchilar qo'shiladi, uy egasida esa
## yangi kelganlar uchun bosh va avatar tayyorlanadi.
func _sync_net_players() -> void:
	if world == null or not Net.is_online():
		return
	if Net.is_host():
		_rebuild_actors()
		return
	var known := {}
	for p in world.players:
		known[p.id] = true
	var added := false
	for row: Dictionary in Net.roster:
		if known.has(int(row["id"])):
			continue
		var player := world.add_human(
			str(row["name"]), int(row["color"]), str(row["avatar"]),
			str(row["country"]))
		if player == null:
			continue
		player.is_bot = bool(row["bot"])
		player.alive = true
		added = true
	if added:
		world.set_local(Net.local_player_id)
		_rebuild_actors()
		_place_camera_instantly()

## O'yinchilar ro'yxati o'zgargach boshlarni va avatar teksturasini
## qaytadan tayyorlaydi.
func _rebuild_actors() -> void:
	_avatars.setup(world)
	_clear_scene()
	_build_players()
	if _arena_material != null:
		_arena_material.set_shader_parameter("avatar_tex", _avatars.texture())
		_arena_material.set_shader_parameter(
			"avatar_grid", _avatars.grid_size())

func _on_net_stopped(reason: String) -> void:
	_set_playing(false)
	_match_running = false
	ui.open_room(false)
	ui.set_room_status(Strings.t(reason))

func _player_country() -> String:
	var saved := store.country
	return saved if not saved.is_empty() else Profile.detect_country()

func _player_name() -> String:
	var saved := store.nickname
	return saved if not saved.is_empty() else Strings.t("you")

func _on_play() -> void:
	Net.leave()
	_new_match()
	_set_playing(true)
	ui.show_screen(ui.Screen.HUD)
	_apply_view_settings()

## Pauza: o'yin to'xtaydi.
##
## Avval pauza faqat oynani ochardi, dunyo esa orqada hisoblanishda
## davom etardi — o'yinchi menyuda turganda ham oldinga yurib,
## raqib iziga urilib o'lib qolishi mumkin edi.
##
## Tarmoq o'yinida uy egasi hisoblashni to'xtatmaydi: xonadagi
## boshqalar uchun o'yin davom etishi kerak. Buni [method
## _set_playing] o'zi hal qiladi.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			if _playing and _city_reward_tracker != null:
				_city_reward_tracker.save_state()
				_on_pause()
		NOTIFICATION_APPLICATION_RESUMED:
			if _city_reward_tracker != null:
				_city_reward_tracker.load_state()
		NOTIFICATION_WM_CLOSE_REQUEST:
			if _playing and _city_reward_tracker != null:
				_city_reward_tracker.save_state()

func _on_pause() -> void:
	if _playing and _city_reward_tracker != null:
		_city_reward_tracker.save_state()
	_set_playing(false)
	_dragging = false
	ui.show_screen(ui.Screen.PAUSE)

func _on_resume() -> void:
	if _city_reward_tracker != null:
		_city_reward_tracker.load_state()
	_set_playing(true)
	ui.show_screen(ui.Screen.HUD)
	_apply_view_settings()

func _on_menu() -> void:
	if _city_reward_tracker != null:
		_city_reward_tracker.clear_saved_state()
	_set_playing(false)
	_match_running = false
	Net.leave()
	_apply_view_settings()
	_place_camera_instantly()
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
	if camera != null:
		var is_classic: bool = (world != null and world.config != null and world.config.world_scale == WorldPacing.SCALE_CLASSIC)
		camera.far = WorldPacing.CAM_FAR_CLASSIC if is_classic else WorldPacing.CAM_FAR_EXPANDED

	# Til o'zgargan bo'lsa shahar nomlari qayta tuziladi; maydon
	# o'sha-o'sha bo'lsa bu chaqiriq darhol qaytadi.
	_build_capitals()
	_capitals.enabled = (_city_renderer == null) and store.show_capitals and _playing
	_capitals.names_visible = (_city_renderer == null) and store.show_city_names and _playing
	if _city_renderer != null:
		_city_renderer.visible = true
	if players_root != null:
		players_root.visible = true
	if _pickups != null:
		_pickups.visible = _playing
	if _flag_poles != null:
		_flag_poles.visible = _playing and store.show_flags
	var q: String = store.graphics_quality if store != null else "medium"
	if sun != null:
		match q:
			"low":
				sun.shadow_enabled = false
			"high":
				sun.shadow_enabled = true
				sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
				sun.directional_shadow_blend_splits = true
				sun.shadow_bias = 0.05
				sun.shadow_normal_bias = 0.8
				sun.shadow_blur = 1.2
			_: # medium
				sun.shadow_enabled = true
				sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
				sun.shadow_bias = 0.08
				sun.shadow_normal_bias = 0.6
				sun.shadow_blur = 0.6

	if ocean != null and ocean.get_surface_override_material(0) != null:
		var w_mat := ocean.get_surface_override_material(0) as ShaderMaterial
		if w_mat != null:
			var q_val := 0 if q == "low" else (2 if q == "high" else 1)
			w_mat.set_shader_parameter("quality_level", q_val)

	if _city_renderer != null and _city_renderer.has_method("set_quality_preset"):
		_city_renderer.set_quality_preset(q)

	if _flag_poles != null and _flag_poles.has_method("set_quality_preset"):
		_flag_poles.set_quality_preset(q)

	ui.set_minimap(paint.texture if store.show_minimap else null)

## Osmon va tuman rangi uslubdan olinadi.
func _apply_sky() -> void:
	var env := world_env.environment
	if env == null:
		return
	var sky := Palette.sky()
	env.background_color = sky
	env.fog_light_color = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = sky.lerp(Color.WHITE, 0.4)
	env.ambient_light_energy = 0.50

func _on_continue_with_ticket() -> void:
	if not store.spend_ticket():
		ui.toast(Strings.t("noTickets"))
		return
	if world.revive(world.human(), _cleared_on_death):
		_human_revived = true
		_avatars.refresh()
		_set_playing(true)
		ui.show_screen(ui.Screen.HUD)
		return
	# Joy topilmadi — belet sarflanmagan hisoblanadi.
	store.add_tickets(1)
	ui.toast(Strings.t("noRoomToContinue"))

func _clear_scene() -> void:
	for head in _heads:
		head.queue_free()
	_heads.clear()
	for s in _shadow_discs:
		if is_instance_valid(s):
			s.queue_free()
	_shadow_discs.clear()
	_name_tags.clear()
	_percent_tags.clear()
	_crowns.clear()
	if _props_root != null and is_instance_valid(_props_root):
		_props_root.queue_free()
		_props_root = null
	if _flag_poles != null:
		_flag_poles.clear()

## Arena geometriyasi faqat maydonga bog'liq: o'yindan o'yinga
## o'zgarmaydi va qayta qurilmaydi. Maydon almashtirilgandagina
## qaytadan quriladi.
var _built_map := ""

func _build_arena() -> void:
	if world.map != null and world.map.ok and _built_map != world.map.id:
		var started := Time.get_ticks_msec()
		var built := ArenaBuilder.build(world.map)
		arena.mesh = built["mesh"]
		_built_map = world.map.id
		print("Arena (%s): %d to'rtburchak, %d ms" % [
			world.map.id, int(built["quads"]),
			Time.get_ticks_msec() - started])

	paint = PaintLayer.new(world.grid, world.color_index_by_id,
		_skins_by_id())
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
	var beach_c := Palette.beach()
	_arena_material.set_shader_parameter("beach_color", Vector3(beach_c.r, beach_c.g, beach_c.b))
	arena.set_surface_override_material(0, _arena_material)

	var wall := StandardMaterial3D.new()
	wall.albedo_color = Palette.land_side()
	wall.roughness = 0.95
	arena.set_surface_override_material(1, wall)

	# Okean — xaritadan kattaroq tekis yuza (yorqin tropik moviy okean to'lqinlari).
	var plane := PlaneMesh.new()
	plane.size = Vector2(world.grid.width * 3.4, world.grid.height * 3.4)
	ocean.mesh = plane
	ocean.position = Vector3(world.grid.width / 2.0, 0.0, world.grid.height / 2.0)
	var water_mat := ShaderMaterial.new()
	water_mat.shader = WATER_SHADER
	var deep := Palette.ocean().darkened(0.22)
	var shallow := Palette.ocean().lightened(0.18)
	water_mat.set_shader_parameter("deep_color", deep)
	water_mat.set_shader_parameter("shallow_color", shallow)
	ocean.set_surface_override_material(0, water_mat)
	_build_props()

var _props_root: Node3D

func _build_props() -> void:
	if _props_root != null and is_instance_valid(_props_root):
		_props_root.queue_free()
	_props_root = Node3D.new()
	add_child(_props_root)

	# 1. Keng bargli multfilm daraxti
	var tree_trunk_mesh := CylinderMesh.new()
	tree_trunk_mesh.top_radius = 0.18
	tree_trunk_mesh.bottom_radius = 0.24
	tree_trunk_mesh.height = 0.9
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color("6d4c41")
	trunk_mat.roughness = 0.85
	tree_trunk_mesh.material = trunk_mat

	var foliage_mesh := SphereMesh.new()
	foliage_mesh.radius = 0.85
	foliage_mesh.height = 1.35
	foliage_mesh.radial_segments = 10
	foliage_mesh.rings = 6
	var foliage_mat := StandardMaterial3D.new()
	foliage_mat.albedo_color = Color("22c55e")
	foliage_mat.roughness = 0.45
	foliage_mesh.material = foliage_mat

	# 2. Multfilm archasi (Pine / Conifer)
	var pine_cone_mesh := CylinderMesh.new()
	pine_cone_mesh.top_radius = 0.05
	pine_cone_mesh.bottom_radius = 0.90
	pine_cone_mesh.height = 1.7
	pine_cone_mesh.radial_segments = 7
	var pine_mat := StandardMaterial3D.new()
	pine_mat.albedo_color = Color("1e5e3a")
	pine_mat.roughness = 0.50
	pine_cone_mesh.material = pine_mat

	# 3. Yaxlit daryo toshlari (Low-poly boulders)
	var rock_mesh := SphereMesh.new()
	rock_mesh.radius = 0.65
	rock_mesh.height = 0.70
	rock_mesh.radial_segments = 6
	rock_mesh.rings = 4
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color("64748b")
	rock_mat.roughness = 0.85
	rock_mesh.material = rock_mat

	var grid := world.grid
	var tree_transforms: Array[Transform3D] = []
	var foliage_transforms: Array[Transform3D] = []
	var pine_transforms: Array[Transform3D] = []
	var rock_transforms: Array[Transform3D] = []

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var step := clampi(grid.width / 55, 7, 13)
	for y in range(4, grid.height - 4, step):
		for x in range(4, grid.width - 4, step):
			var px := x + rng.randi_range(-2, 2)
			var py := y + rng.randi_range(-2, 2)
			if grid.playable(px, py) and grid.is_land(px, py):
				var on_capital := false
				for place in world.places:
					if absi(int(place.get("x", -1)) - px) < 4 and absi(int(place.get("y", -1)) - py) < 4:
						on_capital = true
						break
				if not on_capital:
					var base_pos := Vector3(px + 0.5, ArenaBuilder.LAND_HEIGHT, py + 0.5)
					var roll := rng.randf()
					if roll < 0.45:
						# Keng bargli daraxt
						tree_transforms.append(Transform3D(Basis.IDENTITY, base_pos + Vector3(0, 0.45, 0)))
						foliage_transforms.append(Transform3D(Basis.IDENTITY, base_pos + Vector3(0, 1.25, 0)))
					elif roll < 0.85:
						# Archa (Pine)
						tree_transforms.append(Transform3D(Basis.IDENTITY, base_pos + Vector3(0, 0.35, 0)))
						pine_transforms.append(Transform3D(Basis.IDENTITY, base_pos + Vector3(0, 1.20, 0)))
					else:
						# Qoya tosh
						var r_scale := Vector3(rng.randf_range(0.8, 1.4), rng.randf_range(0.6, 1.0), rng.randf_range(0.8, 1.4))
						var r_rot := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
						var r_trans := Transform3D(r_rot.scaled(r_scale), base_pos + Vector3(0, 0.35, 0))
						rock_transforms.append(r_trans)

	if not tree_transforms.is_empty():
		var trunk_mm := MultiMeshInstance3D.new()
		trunk_mm.multimesh = _make_multimesh(tree_trunk_mesh, tree_transforms)
		_props_root.add_child(trunk_mm)

		if not foliage_transforms.is_empty():
			var foliage_mm := MultiMeshInstance3D.new()
			foliage_mm.multimesh = _make_multimesh(foliage_mesh, foliage_transforms)
			_props_root.add_child(foliage_mm)

		if not pine_transforms.is_empty():
			var pine_mm := MultiMeshInstance3D.new()
			pine_mm.multimesh = _make_multimesh(pine_cone_mesh, pine_transforms)
			_props_root.add_child(pine_mm)

	if not rock_transforms.is_empty():
		var rock_mm := MultiMeshInstance3D.new()
		rock_mm.multimesh = _make_multimesh(rock_mesh, rock_transforms)
		_props_root.add_child(rock_mm)

	# 3D Mashhur Obidalar (Landmarks): Eyfel, Kolizey, Pagoda, Iso haykali, Ozodlik, Big Ben va Ehrom
	var landmarks_placed := 0
	var lg_reward: int = MonetizationConfig.CITY_REWARDS["large"]["coins"]
	var landmark_types := [
		["eiffel", "FR", lg_reward],
		["colosseum", "IT", lg_reward],
		["pagoda", "JP", lg_reward],
		["christ", "BR", lg_reward],
		["statue", "US", lg_reward],
		["big_ben", "GB", lg_reward],
		["pyramid", "EG", lg_reward]
	]
	for lt: Array in landmark_types:
		var placed_one := false
		for place in world.places:
			var code := str(place.get("code", "")).to_upper()
			if code == str(lt[1]):
				var px := int(place.get("x", -1))
				var py := int(place.get("y", -1))
				if grid.playable(px, py) and grid.is_land(px, py):
					var lm := DesignDrawers.build_landmark_node(str(lt[0]), str(lt[1]), int(lt[2]))
					lm.position = Vector3(px + 0.5, ArenaBuilder.LAND_HEIGHT, py + 0.5)
					_props_root.add_child(lm)
					placed_one = true
					landmarks_placed += 1
					break
		# Agar xaritada mos mamlakat bo'lmasa, quruqlikdagi markaziy nuqtaga qo'yamiz
		if not placed_one and landmarks_placed < 5:
			var cx := int(grid.width * (0.3 + landmarks_placed * 0.12))
			var cy := int(grid.height * (0.35 + (landmarks_placed % 2) * 0.2))
			if grid.playable(cx, cy) and grid.is_land(cx, cy):
				var lm := DesignDrawers.build_landmark_node(str(lt[0]), str(lt[1]), int(lt[2]))
				lm.position = Vector3(cx + 0.5, ArenaBuilder.LAND_HEIGHT, cy + 0.5)
				_props_root.add_child(lm)
				landmarks_placed += 1

	# Okeanda suzib yuruvchi oq yelkanli qayiqlar
	var boats_count := 0
	for by in range(6, grid.height - 6, 14):
		for bx in range(6, grid.width - 6, 14):
			if boats_count >= 14:
				break
			if grid.playable(bx, by) and not grid.is_land(bx, by):
				var near_land := false
				for dy in range(-4, 5, 2):
					for dx in range(-4, 5, 2):
						if grid.playable(bx + dx, by + dy) and grid.is_land(bx + dx, by + dy):
							near_land = true
							break
					if near_land:
						break
				if near_land:
					var boat := DesignDrawers.build_landmark_node("sailboat")
					boat.position = Vector3(bx + 0.5, 0.15, by + 0.5)
					boat.rotation_degrees.y = rng.randf_range(0.0, 360.0)
					_props_root.add_child(boat)
					boats_count += 1

static func _make_multimesh(mesh: Mesh, transforms: Array[Transform3D]) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	return mm

## Poytaxt belgilari ham faqat maydonga bog'liq.
var _capitals_map := ""

func _build_capitals() -> void:
	# Til o'zgarsa nomlar ham qayta tuziladi, shuning uchun kalitda
	# maydon bilan birga til ham turadi.
	CityNames.use(Strings.language())
	var key := world.config.map_id + "/" + Strings.language()
	if _capitals_map == key:
		return
	_capitals_map = key
	_capitals.build(world.places, world.grid)
	if _city_renderer != null and world.cities != null:
		_city_renderer.setup(world.cities, world.grid)

## Har o'yinchining hudud naqshi.
##
## Odam o'yinchiniki — do'kondan tanlangani. Botlarga ID bo'yicha
## turg'un naqsh beriladi: maydon rang-barang bo'ladi, lekin
## o'yindan o'yinga o'zgarib ketmaydi.
func _skins_by_id() -> PackedStringArray:
	var out := PackedStringArray()
	out.resize(256)
	var worn := Shop.worn_in(ShopManager.SKINS)
	var pool: Array = Cosmetics.SKIN_LOOK.keys()
	var human_id := world.human().id
	for p in world.players:
		out[p.id] = worn if p.id == human_id \
			else str(pool[p.id % pool.size()])
	return out

## Har o'yin boshida tangalar qaytadan to'kiladi.
##
## Faqat [method _new_match] dan chaqiriladi. Avval u shahar
## nomlari bilan birga qurilardi, nomlar esa ko'rinish sozlamasi
## o'zgarganda ham qayta tuzilardi — shuning uchun pauzadan
## qaytgach yig'ilgan tangalar nolga tushib, xaritadagi hamma
## tanga qaytadan paydo bo'lardi.
func _build_coins() -> void:
	_coin_field.build(world.places, world.grid)
	_coins.build(_coin_field)

## Xaritada bir vaqtda yotadigan narsalar zichligi: har shuncha
## quruqlik katagiga bittadan. Soni maydonga qarab o'zgaradi —
## aks holda dunyo xaritasida ularni topib bo'lmasdi, kichik
## maydonda esa ustma-ust tushardi.
const PICKUP_PER_CELLS := 450
const PICKUP_MIN := 40
const PICKUP_MAX := 180
## Yashil sfera tezlikni shuncha soniya oshiradi.
const DASH_SECONDS := 4.0

## Yo'ldagi tangalar va sferalar. Shahar tangasidan farqi: bular
## ustidan yurib olinadi, shuning uchun har o'yinda qayta
## joylashtiriladi.
func _build_pickups() -> void:
	_loose_coins = 0
	_spheres_collected = 0
	_human_revived = false
	_base_speed = world.human().speed
	# Fever: o'yin boshida qisqa vaqt tezlik oshadi. Darajasi nol
	# bo'lsa hech narsa o'zgarmaydi.
	var fever := _upgrades_seconds()
	_boost_until = fever if fever > 0.0 else 0.0
	_pickup_field.build(world.grid, pickup_count(world.grid),
		int(Time.get_unix_time_from_system()))
	_pickups.build(_pickup_field)

## Shu maydonga nechta narsa to'kiladi.
static func pickup_count(grid: GameGrid) -> int:
	return clampi(grid.land_cells / PICKUP_PER_CELLS,
		PICKUP_MIN, PICKUP_MAX)

## Avtoyuklangan modul `--script` rejimida global bo'lmaydi,
## shuning uchun daraxtdan olinadi.
func _upgrades() -> Node:
	return get_node_or_null("/root/Upgrades")

func _upgrades_seconds() -> float:
	var up := _upgrades()
	return 0.0 if up == null else float(up.fever_seconds())

func _magnet_radius() -> float:
	var up := _upgrades()
	return 1.1 if up == null else float(up.magnet_radius())

## Yo'ldagi narsalarni yig'adi va ta'sirini qo'llaydi.
##
## Faqat **odam** o'yinchi yig'adi: botlar ham yiqqanda xaritada
## hech narsa qolmasdi va o'yin natijasi tasodifga aylanardi.
func _collect_pickups(from: Vector2) -> void:
	var p := world.human()
	if not p.alive:
		return
	# O'tilgan yo'l bo'ylab yig'iladi: uzun kadrda yoki tezlik
	# kuchaytirgichi bilan narsa ustidan sakrab o'tib ketmasin.
	var got := _pickup_field.take_along(
		from.x, from.y, p.x, p.y, _magnet_radius())
	if got.is_empty():
		return
	var taken := _pickup_field.flush_taken()
	if not taken.is_empty():
		_pickups.take(taken)
	for kind: int in got:
		match kind:
			PickupField.Kind.COIN:
				_loose_coins += 1
				Audio.tap()
			PickupField.Kind.SHIELD:
				p.shield = true
				_spheres_collected += 1
				ui.flash(UiKit.BG_LOW, 0.14)
				ui.toast(Strings.t("gotShield"))
			PickupField.Kind.DASH:
				_boost_until = maxf(_boost_until,
					world.elapsed + DASH_SECONDS)
				_spheres_collected += 1
				ui.flash(UiKit.GREEN, 0.14)
				ui.toast(Strings.t("gotDash"))

## Tezlik kuchaytirgichi: faqat odam o'yinchiga ta'sir qiladi.
func _apply_boost() -> void:
	var p := world.human()
	var fast := world.elapsed < _boost_until
	var want: float = _base_speed * (UpgradeManager.FEVER_SPEED \
		if fast else 1.0)
	if not is_equal_approx(p.speed, want):
		p.speed = want

## Bosh — o'yinchi rangidagi shar; ustida uning belgisi turadi.
const HEAD_RADIUS := 1.35

func _build_players() -> void:
	# Egallash effekti ham do'kondan olinadi — har o'yin boshida.
	_burst.apply_cosmetics(Palette.head(world.human().color_index))
	var ball := SphereMesh.new()
	ball.radius = HEAD_RADIUS
	ball.height = HEAD_RADIUS * 2.0
	# Silliq va sifatli 3D shar shakli
	ball.radial_segments = 32
	ball.rings = 16

	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = HEAD_RADIUS * 0.82
	shadow_mesh.bottom_radius = HEAD_RADIUS * 0.82
	shadow_mesh.height = 0.02
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.albedo_color = Color(0.02, 0.06, 0.14, 0.38)

	for p in world.players:
		var shadow := MeshInstance3D.new()
		shadow.mesh = shadow_mesh
		shadow.material_override = shadow_mat
		shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		players_root.add_child(shadow)
		_shadow_discs.append(shadow)

		var head := MeshInstance3D.new()
		head.mesh = ball
		head.set_surface_override_material(0, _head_material(p))

		# Multfilm slime ko'zlari va yuzi
		var glyph := Sprite3D.new()
		glyph.texture = _slime_face_texture()
		glyph.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		glyph.shaded = false
		glyph.no_depth_test = true
		glyph.render_priority = 2
		glyph.pixel_size = 0.012
		head.add_child(glyph)

		# Maxsus nishon kiyilgan bo'lsa — bosh ustida halqa.
		var halo := _halo_for(p)
		if halo != null:
			head.add_child(halo)

		# Ism va foiz yorliqlari boshning bolasi: bosh qimirlasa
		# ular ham ergashadi, alohida joylashtirish shart emas.
		var name_tag := _tag(p.player_name, 46, Color.WHITE)
		name_tag.position = Vector3(0.0, HEAD_RADIUS * 2.9, 0.0)
		head.add_child(name_tag)
		_name_tags.append(name_tag)
		var percent_tag := _tag("", 52, Palette.head(p.color_index))
		percent_tag.position = Vector3(0.0, HEAD_RADIUS * 2.0, 0.0)
		head.add_child(percent_tag)
		_percent_tags.append(percent_tag)

		var crown := Sprite3D.new()
		crown.texture = _crown_texture()
		crown.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		crown.shaded = false
		crown.no_depth_test = true
		crown.render_priority = 3
		crown.pixel_size = 0.034
		crown.position = Vector3(0.0, HEAD_RADIUS * 1.30, 0.0)
		crown.visible = not p.is_bot
		head.add_child(crown)
		_crowns.append(crown)

		players_root.add_child(head)
		_heads.append(head)

## Toj teksturasi — bir marta chiziladi va hamma o'yinchi
## ishlatadi. Rasm fayli emas: belgi [GameIcon] dagidek kod bilan.
func _crown_texture() -> ImageTexture:
	if _crown_image != null:
		return _crown_image
	const SIZE := 48
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	# Toj silueti: pastki tasma va uchta tish.
	var shape := PackedVector2Array([
		Vector2(0.08, 0.80), Vector2(0.08, 0.26), Vector2(0.30, 0.52),
		Vector2(0.50, 0.16), Vector2(0.70, 0.52), Vector2(0.92, 0.26),
		Vector2(0.92, 0.80)])
	for y in SIZE:
		for x in SIZE:
			var at := Vector2(x + 0.5, y + 0.5) / float(SIZE)
			if not Geometry2D.is_point_in_polygon(at, shape):
				continue
			# Chetga yaqin piksel — kontur.
			var edge := _near_edge(at, shape)
			image.set_pixel(x, y, UiKit.INK if edge else UiKit.YELLOW)
	_crown_image = ImageTexture.create_from_image(image)
	return _crown_image

func _slime_face_texture() -> ImageTexture:
	if _slime_face_image != null:
		return _slime_face_image
	const SIZE := 128
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var le := Vector2(40, 48)
	var re := Vector2(88, 48)
	var l_cheek := Vector2(24, 76)
	var r_cheek := Vector2(104, 76)
	for y in SIZE:
		for x in SIZE:
			var pt := Vector2(x, y)
			# Rosy blushing cheeks (pushti yanoqlar)
			var dl_c := (pt - l_cheek).length()
			var dr_c := (pt - r_cheek).length()
			if dl_c <= 12.0:
				var alpha := (1.0 - dl_c / 12.0) * 0.55
				img.set_pixel(x, y, Color(0.98, 0.45, 0.65, alpha))
			elif dr_c <= 12.0:
				var alpha := (1.0 - dr_c / 12.0) * 0.55
				img.set_pixel(x, y, Color(0.98, 0.45, 0.65, alpha))

			# Big cute cartoon eyes
			var dl_e := (pt - le).length()
			var dr_e := (pt - re).length()
			if dl_e <= 16.0 or dr_e <= 16.0:
				img.set_pixel(x, y, Color("141c2b"))
			# Primary sparkle
			if (pt - (le + Vector2(4, -4))).length() <= 5.5 or (pt - (re + Vector2(4, -4))).length() <= 5.5:
				img.set_pixel(x, y, Color.WHITE)
			# Secondary cute sparkle
			if (pt - (le + Vector2(-4, 5))).length() <= 2.8 or (pt - (re + Vector2(-4, 5))).length() <= 2.8:
				img.set_pixel(x, y, Color.WHITE)

			# Cheerful curved mouth
			var mouth_c := Vector2(64, 74)
			var dm := (pt - mouth_c).length()
			if dm >= 14.0 and dm <= 20.0 and y >= 74 and absf(x - 64) <= 16:
				img.set_pixel(x, y, Color("141c2b"))
			# Inside open mouth with tongue
			if dm < 15.0 and y >= 75 and absf(x - 64) <= 12:
				img.set_pixel(x, y, Color("e54261"))
	_slime_face_image = ImageTexture.create_from_image(img)
	return _slime_face_image

## Nuqta ko'pburchak chetiga yaqinmi (kontur uchun).
static func _near_edge(at: Vector2, shape: PackedVector2Array) -> bool:
	for step: Vector2 in [Vector2(0.05, 0), Vector2(-0.05, 0),
			Vector2(0, 0.05), Vector2(0, -0.05)]:
		if not Geometry2D.is_point_in_polygon(at + step, shape):
			return true
	return false

## Bosh ustidagi yorliq: oq matn, to'q ko'k kontur, doim kameraga
## qarab turadi.
func _tag(text: String, size: int, tint: Color) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.font = UiKit.display_font()
	tag.font_size = size
	tag.outline_size = maxi(8, size / 4)
	tag.modulate = tint
	tag.outline_modulate = UiKit.INK
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.render_priority = 2
	tag.outline_render_priority = 1
	tag.pixel_size = 0.022
	tag.shaded = false
	return tag

## Bosh materiali: rang o'yinchiniki, pardoz esa do'kondan.
##
## Pardoz faqat **ko'rinish** — shar o'lchami ham, to'qnashuv ham
## o'zgarmaydi, shuning uchun do'kon o'yin qoidalariga tegmaydi.
func _head_material(p: PlayerState) -> StandardMaterial3D:
	var base := Palette.head(p.color_index)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base
	mat.roughness = 0.12
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.92
	mat.clearcoat_roughness = 0.08
	mat.rim_enabled = true
	mat.rim = 0.75
	mat.rim_tint = 0.5
	# O'yinchining o'zi biroz yaltiraydi — raqiblardan ajralib tursin.
	if p.is_bot:
		return mat
	mat.emission_enabled = true
	mat.emission = base
	mat.emission_energy_multiplier = 0.40
	if p.id != world.human().id:
		return mat
	var look := Cosmetics.skin(Shop.worn_in(ShopManager.SKINS))
	mat.albedo_color = Cosmetics.skin_color(base, look)
	mat.roughness = float(look["rough"]) * 0.25
	mat.metallic = float(look["metal"])
	mat.emission = mat.albedo_color
	# Nur me'yorida: to'liq kuchda shar oqarib ketadi va rangi
	# bilinmay qoladi.
	mat.emission_energy_multiplier = 0.35 + 0.35 * float(look["glow"])
	return mat

## Maxsus nishon halqasi; nishon kiyilmagan bo'lsa — null.
func _halo_for(p: PlayerState) -> MeshInstance3D:
	if p.id != world.human().id:
		return null
	var tint := Cosmetics.halo(Shop.worn_in(ShopManager.SPECIAL))
	if tint.a <= 0.0:
		return null
	var torus := TorusMesh.new()
	torus.inner_radius = HEAD_RADIUS * 1.15
	torus.outer_radius = HEAD_RADIUS * 1.42
	torus.rings = 24
	torus.ring_segments = 6
	var ring := MeshInstance3D.new()
	ring.mesh = torus
	ring.position = Vector3(0.0, -HEAD_RADIUS * 0.72, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.set_surface_override_material(0, mat)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ring

func _process(delta: float) -> void:
	if _match_running and world != null:
		# Tanga soati dunyo soatidan yuradi: `world.update()` juda
		# uzun kadrni qisqartiradi, shuning uchun xom `delta` ni
		# ishlatsak ikki soat bir-biridan uzoqlashib ketardi.
		var was := world.elapsed
		var from := Vector2(world.human().x, world.human().y)
		world.update(delta)
		_handle_events()
		# Olingan tangalar shaharlarda qayta paydo bo'ladi.
		var back := _coin_field.advance(world.elapsed - was)
		if not back.is_empty():
			_coins.give_back(back)
		# Yo'ldagi narsalar ham o'sha soat bo'yicha qaytadi.
		var again := _pickup_field.advance(world.elapsed - was)
		if not again.is_empty():
			_pickups.give_back(again)
		_collect_pickups(from)
		_apply_boost()
	# Mehmonda holat uy egasidan keladi, lekin o'lim baribir shu yerda
	# seziladi — natija oynasi ochiladi.
	if _playing and not world.human().alive:
		_end_match()
	if paint != null:
		paint.sync()
	if world != null and world.human() != null:
		# Shahar nomlari kamera atrofida almashib turadi.
		if _capitals != null:
			_capitals.update_focus(Vector2(world.human().x, world.human().y), delta)
		_sync_heads()
		_follow_camera(delta)
		if _flag_poles != null and _playing:
			_flag_poles.update_poles()
			_flag_poles.update_camera_culling(camera)
		if _city_renderer != null and _playing:
			_city_renderer.update_lod(camera.global_position, delta)

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
				# Egallangan hududdagi shaharlarning tangasi
				# egallagan o'yinchiga o'tadi — raqib sening
				# yeringga kirib olib keta oladi. Faqat odam
				# o'yinchinikisi hisobga yoziladi.
				var mine := int(event["player"]) == human_id
				if mine:
					Audio.capture()
					ui.flash(Palette.head(world.human().color_index), 0.18)
					_burst.burst(Vector3(world.human().x,
						ArenaBuilder.LAND_HEIGHT + HEAD_RADIUS,
						world.human().y))
					_captures += 1
				var coins_gained := _coin_field.collect_cells(event["cells"], mine)
				if mine and coins_gained > 0:
					_spawn_floating_coin(Vector3(world.human().x, ArenaBuilder.LAND_HEIGHT + 2.5, world.human().y), "+%d" % coins_gained)
				var taken := _coin_field.flush_taken()
				if not taken.is_empty():
					_coins.take(taken)
			"city_captured":
				var c_cap: CitySystem.CityData = event["city"]
				var is_starting: bool = bool(event.get("initial", false))
				var is_human: bool = (int(event["player"]) == human_id)
				if _city_renderer != null:
					_city_renderer.on_city_captured(c_cap)

				if is_human and not is_starting:
					var claim_res: Dictionary = _city_reward_tracker.claim_city(c_cap, true)
					if bool(claim_res.get("eligible", false)):
						var reward_amount: int = int(claim_res.get("coins", 0))
						var tx_id: String = str(claim_res.get("tx_id", ""))
						var credited := Wallet.add_coins(reward_amount, "city_conquest", tx_id)
						if credited > 0:
							_match_conquest_coins += credited
							Metrics.send(Analytics.COIN_EARNED, {"amount": credited, "source": "city_conquest", "city": c_cap.name})
							Audio.capture()
							if Audio.has_method("coin"):
								Audio.coin()
							ui.flash(Color("facc15"), 0.25)
							_spawn_conquest_reward_fx(c_cap, credited)
							ui.toast("★ %s EGALLANDI! (+%d 🪙)" % [c_cap.display_name.to_upper(), credited])
					else:
						_duplicates_prevented_count += 1
						Audio.capture()
						ui.flash(Color("38bdf8"), 0.16)
						ui.toast("★ %s EGALLANDI!" % c_cap.display_name.to_upper())
				elif is_human and is_starting:
					# Boshlang'ich hudud doirasi - bepul
					pass
				else:
					# Bot egallagan bo'lsa
					pass
				_refresh_hud()
			"city_lost":
				var c_lost: CitySystem.CityData = event["city"]
				if _city_renderer != null:
					_city_renderer.on_city_lost(c_lost)
				if int(event["player"]) == human_id:
					ui.toast("⚠️ %s QO'LDAN BOY BERILDI!" % c_lost.display_name.to_upper())
				_refresh_hud()
			"shield_used":
				if int(event["player"]) == human_id:
					Audio.kill()
					ui.flash(UiKit.BG_LOW, 0.3)
					ui.toast(Strings.t("shieldSaved"))
			"death":
				if int(event["player"]) == human_id:
					_cleared_on_death = event["cleared"]
					Audio.death()
					ui.flash(UiKit.CORAL, 0.34)
				elif int(event["killer"]) == human_id:
					Audio.kill()
					ui.flash(UiKit.MINT, 0.16)
				_refresh_hud()

func _spawn_floating_coin(at: Vector3, text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = UiKit.display_font()
	label.font_size = 46
	label.outline_size = 10
	label.modulate = UiKit.YELLOW
	label.outline_modulate = UiKit.INK
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 4
	label.outline_render_priority = 3
	label.pixel_size = 0.026
	label.position = at
	add_child(label)

	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", at.y + 3.2, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "scale", Vector3(1.2, 1.2, 1.2), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(label.queue_free)

func _spawn_conquest_reward_fx(city: CitySystem.CityData, amount: int) -> void:
	var at := Vector3(city.pos.x, ArenaBuilder.LAND_HEIGHT + 2.5, city.pos.y)
	var label := Label3D.new()
	label.text = "+%d 🪙\n%s" % [amount, city.display_name.to_upper()]
	label.font = UiKit.display_font()
	label.font_size = 50
	label.outline_size = 12
	label.modulate = UiKit.GOLD
	label.outline_modulate = UiKit.INK
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 6
	label.outline_render_priority = 5
	label.pixel_size = 0.026
	label.position = at
	add_child(label)

	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", at.y + 3.8, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "scale", Vector3(1.25, 1.25, 1.25), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(label.queue_free)

	_spawn_coin_particles(at)

func _spawn_coin_particles(at: Vector3) -> void:
	var q: String = store.graphics_quality if store != null else "medium"
	var parts := CPUParticles3D.new()
	parts.position = at
	parts.emitting = true
	parts.one_shot = true
	parts.explosiveness = 0.85
	parts.lifetime = 1.1
	parts.amount = 6 if q == "low" else (18 if q == "high" else 12)
	parts.direction = Vector3(0, 1, 0)
	parts.spread = 45.0
	parts.initial_velocity_min = 4.0
	parts.initial_velocity_max = 7.0
	parts.gravity = Vector3(0, -9.8, 0)

	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.2
	mesh.bottom_radius = 0.2
	mesh.height = 0.06
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("fbbf24")
	mesh.material = mat
	parts.mesh = mesh

	add_child(parts)
	get_tree().create_timer(1.3).timeout.connect(parts.queue_free)

func _end_match() -> void:
	_set_playing(false)
	_dragging = false
	var p := world.human()
	var percent := world.percent_of(p)
	var is_record := store.submit_result(percent, p.kills)
	# Natija onlayn reytingga ham yuboriladi (server sozlangan bo'lsa).
	Board.submit(store, percent, p.kills)
	# Tanga: o'yin natijasidan hisoblanadi va hamyonga qo'shiladi.
	# Yo'ldan terilgan tanga shahar tangasi bilan birga sanaladi,
	# "passiv tanga" darajasi esa alohida qator bo'lib qo'shiladi.
	var up := _upgrades()
	var reward := RewardManager.run_reward(world.elapsed, percent, p.kills,
		_coin_field.collected() + _loose_coins,
		0 if up == null else int(up.passive_bonus()))
	Wallet.add_coins(int(reward["total"]), "run")
	Metrics.send(Analytics.COIN_EARNED, {"amount": int(reward["total"])})
	# Kunlik topshiriqlar shu natijadan hisoblanadi.
	var finished := Missions.report(percent, p.kills, _captures,
		world.elapsed, _coin_field.collected())
	if not finished.is_empty():
		ui.toast(Strings.t("missionDone"))
	# Majburiy reklama oralig'i shu yerda sanaladi (hozircha o'chiq).
	Ads.note_run_finished()
	# Mamlakatlar yo'li shu natijadan oldinga siljiydi.
	var journey := get_node_or_null("/root/Journey")
	var moved: Dictionary = {}
	if journey != null:
		# Natija ekrani eski holatni ko'rsatib, keyin o'sib borsin.
		moved = {
			"before": float(journey.percent()),
			"country": journey.current(),
		}
		moved.merge(journey.report(percent, p.kills))
		moved["after"] = float(journey.percent())
	var country_won: bool = moved.has("done") and not (moved["done"] as Array).is_empty()
	var is_perfect: bool = (percent >= 99.9)
	store.record_match_stats(p.kills, _spheres_collected, _human_revived, country_won, is_perfect)
	store.record_economy_stats(_match_conquest_coins, _coin_field.collected(), _city_reward_tracker.get_claimed_count(), _duplicates_prevented_count)

	var s_cnt := _city_reward_tracker.get_rewarded_count(CitySystem.Category.SMALL)
	var m_cnt := _city_reward_tracker.get_rewarded_count(CitySystem.Category.MEDIUM)
	var l_cnt := _city_reward_tracker.get_rewarded_count(CitySystem.Category.LARGE)
	var city_conquest_data: Dictionary = {
		"small_count": s_cnt,
		"medium_count": m_cnt,
		"large_count": l_cnt,
		"small_coins": s_cnt * MonetizationConfig.get_city_capture_reward(CitySystem.Category.SMALL),
		"medium_coins": m_cnt * MonetizationConfig.get_city_capture_reward(CitySystem.Category.MEDIUM),
		"large_coins": l_cnt * MonetizationConfig.get_city_capture_reward(CitySystem.Category.LARGE),
		"total": _match_conquest_coins,
		"cities_owned": world.cities.get_player_captured_count(p.id) if world.cities != null else 0,
		"total_cities": world.cities.get_total_cities_count() if world.cities != null else 0,
		"duplicates_prevented": _duplicates_prevented_count,
	}
	ui.set_result(percent, p.kills, world.elapsed,
		Strings.death_reason(p.death_cause), is_record, reward, moved, city_conquest_data)
	if _city_reward_tracker != null:
		_city_reward_tracker.clear_saved_state()
	ui.show_screen(ui.Screen.RESULT)


func _sync_heads() -> void:
	for i in world.players.size():
		var p := world.players[i]
		var head := _heads[i]
		head.visible = _playing and p.alive
		if i < _shadow_discs.size() and _shadow_discs[i] != null:
			_shadow_discs[i].visible = _playing and p.alive
		if not head.visible:
			continue
		head.position = Vector3(
			p.x, ArenaBuilder.LAND_HEIGHT + HEAD_RADIUS, p.y)
		var bounce := sin(world.elapsed * 12.0 + float(i) * 1.5) * 0.08
		head.scale = Vector3(1.0 + bounce, 1.0 - bounce * 0.85, 1.0 + bounce)

		# Kontakt soya diski
		if i < _shadow_discs.size() and _shadow_discs[i] != null:
			var s := _shadow_discs[i]
			s.position = Vector3(p.x, ArenaBuilder.LAND_HEIGHT + 0.03, p.y)
			var s_scale := 1.0 - bounce * 0.5
			s.scale = Vector3(s_scale, 1.0, s_scale)

		# Harakatlanish tomonga burilish va multfilm qiyaligi (movement tilt)
		var dir_angle: float = p.angle
		head.rotation.y = -dir_angle + PI * 0.5
		head.rotation.z = sin(world.elapsed * 10.0 + float(i)) * 0.04

		# Oltin tojning bosh ustida mayin muallaq suzishi (floating crown bob)
		if i < _crowns.size() and _crowns[i] != null and _crowns[i].visible:
			var crown_bob := sin(world.elapsed * 4.5) * 0.08
			_crowns[i].position.y = HEAD_RADIUS * 1.45 + crown_bob

func _cam_height() -> float:
	if world != null and world.config != null and world.config.world_scale == WorldPacing.SCALE_CLASSIC:
		return WorldPacing.CAM_HEIGHT_CLASSIC
	return WorldPacing.CAM_HEIGHT_EXPANDED

func _cam_back() -> float:
	if world != null and world.config != null and world.config.world_scale == WorldPacing.SCALE_CLASSIC:
		return WorldPacing.CAM_BACK_CLASSIC
	return WorldPacing.CAM_BACK_EXPANDED

func _player_target() -> Vector3:
	var p := world.human()
	return Vector3(p.x, ArenaBuilder.LAND_HEIGHT, p.y)

func _scenic_menu_target() -> Vector3:
	if world == null or world.grid == null:
		return Vector3(100.0, ArenaBuilder.LAND_HEIGHT, 60.0)
	return Vector3(float(world.grid.width) * 0.5, ArenaBuilder.LAND_HEIGHT, float(world.grid.height) * 0.5)

func _place_camera_instantly() -> void:
	var ch := _cam_height()
	var cb := _cam_back()
	if not _playing and world != null:
		var target := _scenic_menu_target()
		camera.position = target + Vector3(-16.0, 28.0, 34.0)
		camera.look_at(target + Vector3(0.0, 1.5, 0.0), Vector3.UP)
		return
	var target := _player_target()
	camera.position = target + Vector3(0.0, ch, cb)
	camera.look_at(target, Vector3.UP)

var demo_camera_override := false

func set_camera_demo_pose(pos: Vector3, look_at_pt: Vector3) -> void:
	demo_camera_override = true
	camera.position = pos
	camera.look_at(look_at_pt, Vector3.UP)

func _follow_camera(delta: float) -> void:
	if demo_camera_override:
		return
	var ch := _cam_height()
	var cb := _cam_back()
	if not _playing and world != null:
		var target := _scenic_menu_target()
		var drift_x := sin(Time.get_ticks_msec() * 0.00015) * 6.0
		var drift_z := cos(Time.get_ticks_msec() * 0.00012) * 5.0
		var want := target + Vector3(-16.0 + drift_x, 28.0, 34.0 + drift_z)
		camera.position = camera.position.lerp(want, minf(1.0, 1.5 * delta))
		camera.look_at(target + Vector3(0.0, 1.5, 0.0), Vector3.UP)
		return
	var target := _player_target()
	var want := target + Vector3(0.0, ch, cb)
	if world != null and world.grid != null:
		want.x = clampf(want.x, 15.0, float(world.grid.width) - 15.0)
		want.z = clampf(want.z, cb + 5.0, float(world.grid.height) + cb - 5.0)
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
			if _city_renderer != null:
				var hit_c = _city_renderer.get_city_at_screen_ray(camera, touch.position)
				if hit_c != null:
					_on_city_selected(hit_c)
		else:
			_dragging = false
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index == MOUSE_BUTTON_LEFT:
			_drag_origin = click.position
			_dragging = click.pressed
			if click.pressed and _city_renderer != null:
				var hit_c = _city_renderer.get_city_at_screen_ray(camera, click.position)
				if hit_c != null:
					_on_city_selected(hit_c)
	elif event is InputEventScreenDrag:
		_steer((event as InputEventScreenDrag).position)
	elif event is InputEventMouseMotion and _dragging:
		_steer((event as InputEventMouseMotion).position)

func _on_city_selected(city: CitySystem.CityData) -> void:
	if city == null or world == null or world.grid == null:
		return
	var cell := int(city.y) * world.grid.width + int(city.x)
	var avail: bool = _coin_field.is_coin_available_at_cell(cell) if _coin_field != null else false
	var already_claimed: bool = not _city_reward_tracker.is_city_eligible(city) if _city_reward_tracker != null else false
	var h = world.human()
	var human_id: int = h.id if h != null else 1
	var is_owned: bool = city.is_owned_by(human_id)
	ui.show_city_info_modal(city, avail, already_claimed, is_owned)

func _steer(at: Vector2) -> void:
	if not _dragging:
		return
	var delta := at - _drag_origin
	if delta.length() < DRAG_DEADZONE:
		return
	# Ekran o'qlari dunyo o'qlariga to'g'ri keladi: kamera tepadan
	# qaraydi va burilmaydi, shuning uchun qo'shimcha aylantirish kerak
	# emas.
	var angle := atan2(delta.y, delta.x)
	world.human().steer_to(angle)
	Net.send_steer(angle)
	# Barmoq uzoqlashsa boshlang'ich nuqtani ergashtiramiz.
	if delta.length() > DRAG_LEASH:
		_drag_origin = at - delta.normalized() * DRAG_LEASH

## Skrinshot vositasi uchun: kerakli ekranni ochadi.
func show_screen_for_demo(name: String) -> void:
	match name:
		"menu": ui.show_screen(ui.Screen.MENU)
		"settings": ui.show_screen(ui.Screen.SETTINGS)
		"profile": ui.show_screen(ui.Screen.PROFILE)
		"pause": _on_pause()
		"shop": ui.open_shop(ui.Screen.MENU)
		"maps": ui.open_maps("play")
		"room": ui.open_room(false)
		"board": ui.open_board()
		"gear": ui.show_screen(ui.Screen.GEAR)
		"heroes": ui.show_screen(ui.Screen.HEROES)
		"noads": ui.show_screen(ui.Screen.NOADS)
		"result":
			# Namuna natija: mukofot va mamlakat yo'li ham
			# ko'rinsin, aks holda ekranning yarmi tekshirilmay
			# qolardi.
			var journey := get_node_or_null("/root/Journey")
			var moved: Dictionary = {}
			if journey != null:
				moved = {
					"country": journey.current(),
					"before": float(journey.percent()),
					"after": minf(float(journey.percent()) + 18.0, 100.0),
					"gained": 123, "done": [],
				}
			ui.set_result(12.34, 3, 95.0,
				Strings.death_reason(PlayerState.DeathCause.TRAIL_HIT), true,
				RewardManager.run_reward(95.0, 12.34, 3, 40, 15), moved)
			ui.show_screen(ui.Screen.RESULT)

## Skrinshot vositasi uchun: reyting serveri manzilini qo'yadi.
func set_board_url_for_demo(url: String) -> void:
	store.leaderboard_url = url

## Skrinshot vositasi uchun: maydonni almashtiradi.
func set_map_for_demo(map_id: String) -> void:
	if store.map_id == map_id:
		return
	store.map_id = map_id
	_new_match()

## Skrinshot vositasi uchun: avatarni almashtiradi.
func set_avatar_for_demo(value: String) -> void:
	if store.avatar == value:
		return
	store.avatar = value
	_new_match()

## Skrinshot vositasi uchun: davlat bayrog'ini almashtiradi.
func set_country_for_demo(code: String) -> void:
	if store.country == code:
		return
	store.country = code
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
		_set_playing(true)
		ui.show_screen(ui.Screen.HUD)

## Yorliq shuncha katakdan narida ko'rinmaydi — aks holda ekran
## uzoqdagi o'yinchilarning ismlari bilan to'lib ketardi.
const TAG_RANGE := 54.0

func _refresh_tags() -> void:
	var eye := Vector2(world.human().x, world.human().y)
	# Yetakchi o'yin davomida almashadi, shuning uchun toj har
	# yangilashda qaytadan topiladi.
	var leader := 0
	var best := -1
	for i in world.players.size():
		var owned := world.grid.territory_of(world.players[i].id)
		if owned > best:
			best = owned
			leader = i
	for i in world.players.size():
		if i >= _percent_tags.size():
			break
		var p := world.players[i]
		var near := _playing and p.alive and Vector2(p.x, p.y).distance_to(eye) < TAG_RANGE
		_name_tags[i].visible = near
		_percent_tags[i].visible = near
		_crowns[i].visible = p.alive and i == leader
		if near:
			_percent_tags[i].text = "%.1f%%" % world.grid.percent_of(p.id)

func _refresh_hud() -> void:
	_refresh_tags()
	var p := world.human()
	var bot_pts: Array = []
	for pl in world.players:
		if pl != p and pl.alive:
			bot_pts.append({
				"pos": Vector2(pl.x / world.grid.width, pl.y / world.grid.height),
				"color": Palette.head(pl.color_index)
			})
	ui.update_hud(
		world.percent_of(p), p.kills, world.elapsed,
		world.rank_of(p), world.alive_count(), _leaderboard(),
		Vector2(p.x / world.grid.width, p.y / world.grid.height),
		Wallet.get_coins(),
		bot_pts,
		_match_conquest_coins + _coin_field.collected() + _loose_coins)
	if world.cities != null:
		ui.update_hud_cities(world.cities.get_player_captured_count(p.id), world.cities.get_total_cities_count())

## Top-5 reyting.
## Reyting: eng kuchli uchtasi va o'yinchining o'z qatori.
##
## O'yinchi uchlikka kirmasa ham o'z o'rnini ko'rib tursin —
## shuning uchun uning qatori har doim oxiriga qo'shiladi.
func _leaderboard() -> Array:
	var sorted := world.players.duplicate()
	sorted.sort_custom(func(a: PlayerState, b: PlayerState) -> bool:
		return world.grid.territory_of(a.id) > world.grid.territory_of(b.id))
	var human_id := world.human().id
	var rows: Array = []
	for i in sorted.size():
		var p: PlayerState = sorted[i]
		var mine := p.id == human_id
		if i >= 3 and not mine:
			continue
		rows.append({
			"place": i + 1,
			"name": p.player_name,
			"avatar": p.avatar,
			"color": p.color_index,
			"percent": world.grid.percent_of(p.id),
			"is_human": mine,
			"country": p.country,
		})
	return rows
