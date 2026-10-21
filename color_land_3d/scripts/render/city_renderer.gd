class_name CityRenderer
extends Node3D

## Color Land 3D — 3D Shahar Vizualizatsiya va Istilo Rendereri (Phase 5)
##
## Haqiqiy batafsil 3D shahar modellarini dunyoga joylaydi:
##  - Small City: media_1792231859791_8d99adb0.png (cherkov, kottejlar, poliz, qarag'aylar)
##  - Medium City: media_1792231869893_242e34d3.png (kvadrat ko'cha to'ri, do'konlar, park, mashinalar)
##  - Large City: media_1792231878469_d7169169.png (skyscrapers, arka minora, vertolyot maydonchasi, kanal)
##  - Regional Landmarks: Parij (Eyfel), O'zbekiston (Registon gumbazi & minora), Rim (Kolizey), Yaponiya (Pagoda), Misr (Piramida)
##
## Android uchun optimizatsiya:
##  - Dinamik LOD (Kameraga yaqin shaharlar to'liq 3D, uzoqdagilar soddalashtirilgan)
##  - Bitta umumiy Vertex Color materiali orqali 0 ta ortiqcha tekstura
##  - Hilpiraydigan davlat bayrog'i shtokasi (FlagRenderer integratsiyasi)

const CitySystem = preload("res://scripts/logic/city_system.gd")
const CityMeshBuilder = preload("res://scripts/render/city_mesh_builder.gd")
const FlagRenderer = preload("res://scripts/render/flag_renderer.gd")
const ArenaBuilder = preload("res://scripts/render/arena_builder.gd")
const Palette = preload("res://scripts/render/palette.gd")
const UiKit = preload("res://scripts/ui/ui_kit.gd")

signal city_selected(city: CitySystem.CityData)

# LOD masofalari (dunyo birliklarida)
var _lod_close: float = 50.0
var _max_active_cities: int = 28
var _update_interval: float = 0.12
var quality_preset: String = "medium"

func set_quality_preset(preset: String) -> void:
	quality_preset = preset.to_lower()
	match quality_preset:
		"low":
			_lod_close = 36.0
			_max_active_cities = 14
			_update_interval = 0.20
		"high":
			_lod_close = 68.0
			_max_active_cities = 42
			_update_interval = 0.08
		_:
			_lod_close = 50.0
			_max_active_cities = 28
			_update_interval = 0.12


# Cached Shared Meshes
static var _mesh_small: ArrayMesh
static var _mesh_medium: ArrayMesh
static var _mesh_large: ArrayMesh
static var _mesh_paris: ArrayMesh
static var _mesh_uzbek: ArrayMesh
static var _mesh_rome: ArrayMesh
static var _mesh_japan: ArrayMesh
static var _mesh_egypt: ArrayMesh

static var _flag_shader: Shader
static var _pole_mesh: CylinderMesh
static var _pole_material: StandardMaterial3D

var _system: CitySystem
var _grid: GameGrid

# Faol 3D shahar tugunlari: {city_id (int): CityNode}
var _active_nodes: Dictionary = {}

# Soddalashtirilgan uzoq shahar nuqtalari (MultiMesh)
var _far_dots: MultiMeshInstance3D
var _all_cities: Array[CitySystem.CityData] = []
var _update_timer := 0.0

class CityNode extends Node3D:
	var city_data: CitySystem.CityData
	var model_inst: MeshInstance3D
	var landmark_inst: MeshInstance3D
	var flag_inst: MeshInstance3D
	var flag_mat: ShaderMaterial
	var label: Label3D
	var capture_ring: MeshInstance3D
	var base_scale := Vector3.ONE

	func update_owner_flag() -> void:
		if flag_mat == null or city_data == null:
			return
		var country := city_data.owner_country
		if country.is_empty():
			country = city_data.country_code
		var tex := FlagRenderer.get_flag_texture(country)
		flag_mat.set_shader_parameter("flag_tex", tex)

		if label != null:
			if city_data.is_captured():
				label.modulate = Palette.player_color(city_data.owner_id)
				label.text = "★ " + city_data.display_name + " ★"
			else:
				label.modulate = Color("ffffff")
				label.text = city_data.display_name

func _ready() -> void:
	_init_resources()
	_far_dots = MultiMeshInstance3D.new()
	_far_dots.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_far_dots)

static func _init_resources() -> void:
	if _mesh_small != null:
		return

	_mesh_small = CityMeshBuilder.build_small_city_mesh()
	_mesh_medium = CityMeshBuilder.build_medium_city_mesh()
	_mesh_large = CityMeshBuilder.build_large_city_mesh()

	_mesh_paris = CityMeshBuilder.build_landmark_paris()
	_mesh_uzbek = CityMeshBuilder.build_landmark_uzbek()
	_mesh_rome = CityMeshBuilder.build_landmark_rome()
	_mesh_japan = CityMeshBuilder.build_landmark_japan()
	_mesh_egypt = CityMeshBuilder.build_landmark_egypt()

	_flag_shader = Shader.new()
	_flag_shader.code = """
	shader_type spatial;
	render_mode cull_disabled, depth_draw_opaque;

	uniform sampler2D flag_tex : source_color, filter_linear;
	uniform float wave_speed = 4.2;
	uniform float wave_freq = 3.2;
	uniform float wave_amp = 0.22;

	void vertex() {
		float dist = UV.x;
		VERTEX.z += sin(TIME * wave_speed + UV.x * wave_freq) * wave_amp * dist;
		VERTEX.y += cos(TIME * (wave_speed * 0.75) + UV.x * 2.2) * (wave_amp * 0.15) * dist;
	}

	void fragment() {
		vec4 col = texture(flag_tex, UV);
		if (col.a < 0.1) {
			discard;
		}
		ALBEDO = col.rgb;
		ALPHA = col.a;
		ROUGHNESS = 0.45;
		SPECULAR = 0.25;
	}
	"""

	_pole_material = StandardMaterial3D.new()
	_pole_material.albedo_color = Color("e2e8f0")
	_pole_material.metallic = 0.85
	_pole_material.roughness = 0.25

	_pole_mesh = CylinderMesh.new()
	_pole_mesh.top_radius = 0.08
	_pole_mesh.bottom_radius = 0.10
	_pole_mesh.height = 4.5
	_pole_mesh.radial_segments = 10
	_pole_mesh.material = _pole_material

static func clear_cache() -> void:
	_flag_shader = null
	_pole_mesh = null
	_pole_material = null
	_mesh_small = null
	_mesh_medium = null
	_mesh_large = null
	_mesh_paris = null
	_mesh_uzbek = null
	_mesh_rome = null
	_mesh_japan = null
	_mesh_egypt = null

## Dunyoni va barcha shaharlarni sozlash
func setup(p_system: CitySystem, p_grid: GameGrid) -> void:
	_system = p_system
	_grid = p_grid
	_all_cities.clear()
	for n in _active_nodes.values():
		if is_instance_valid(n):
			n.queue_free()
	_active_nodes.clear()

	if _system == null:
		return

	_all_cities = _system.cities.duplicate()
	_build_far_dots()

## Uzoqdagi shaharlar uchun yengil MultiMesh nuqtalari
func _build_far_dots() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = 0.75
	disc.bottom_radius = 0.85
	disc.height = 0.22
	disc.radial_segments = 10
	disc.rings = 0

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("f1f5f9")
	mat.roughness = 0.6
	disc.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = disc
	mm.instance_count = _all_cities.size()

	for i in _all_cities.size():
		var c: CitySystem.CityData = _all_cities[i]
		var tr := Transform3D(Basis.IDENTITY, Vector3(c.pos.x, ArenaBuilder.LAND_HEIGHT + 0.1, c.pos.y))
		mm.set_instance_transform(i, tr)

	_far_dots.multimesh = mm

## Har kadrda kameraga yaqin shaharlar uchun 3D modellarni yangilash (LOD menejeri)
func update_lod(cam_pos: Vector3, dt: float) -> void:
	_update_timer -= dt
	if _update_timer > 0.0:
		return
	_update_timer = _update_interval

	if _all_cities.is_empty():
		return

	var cam_2d := Vector2(cam_pos.x, cam_pos.z)

	# Shaharlarni kameragacha bo'lgan masofa bo'yicha baholash
	var visible_candidates: Array[Dictionary] = []
	for c: CitySystem.CityData in _all_cities:
		var d := c.pos.distance_to(cam_2d)
		if d < _lod_close:
			# Katta shaharlarga va yaqinlarga ustunlik
			var priority := d - (15.0 if c.category == CitySystem.Category.LARGE else 0.0)
			visible_candidates.append({"city": c, "dist": d, "prio": priority})

	visible_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["prio"]) < float(b["prio"]))

	var needed_ids: Dictionary = {}
	var count := mini(visible_candidates.size(), _max_active_cities)
	for i in count:
		var c: CitySystem.CityData = visible_candidates[i]["city"]
		needed_ids[c.id] = true
		if not _active_nodes.has(c.id):
			_spawn_city_node(c)

	# Uzoqlashgan tugunlarni o'chirish
	var to_remove: Array[int] = []
	for cid: int in _active_nodes.keys():
		if not needed_ids.has(cid):
			to_remove.append(cid)

	for cid: int in to_remove:
		var n: CityNode = _active_nodes[cid]
		if is_instance_valid(n):
			n.queue_free()
		_active_nodes.erase(cid)

	# Yozuvlar ustunligi va to'qnashuvini boshqarish (Anti-overlap & zoom prioritet)
	_update_label_visibility_and_priorities(cam_pos)

## Zoom va masofaga qarab shahar nomlarini tartibga solish (Chalkashmaslik uchun)
func _update_label_visibility_and_priorities(cam_pos: Vector3) -> void:
	if _active_nodes.is_empty():
		return

	var cam_altitude := cam_pos.y
	var label_candidates: Array[Dictionary] = []

	for cid: int in _active_nodes.keys():
		var node: CityNode = _active_nodes[cid]
		if not is_instance_valid(node) or node.label == null:
			continue
		var c := node.city_data
		if c == null:
			continue

		# Zoom bo'yicha saralash:
		# - Juda uzoqda (cam_altitude > 30.0): Faqat Poytaxtlar va Katta shaharlar
		# - O'rtacha balandlikda (cam_altitude > 20.0): Faqat Katta, O'rta va egallangan shaharlar
		# - Yaqinda (cam_altitude <= 20.0): Barcha toifalar
		if cam_altitude > 30.0 and not (c.capital or c.category == CitySystem.Category.LARGE):
			node.label.visible = false
			continue
		elif cam_altitude > 20.0 and c.category == CitySystem.Category.SMALL and not c.is_captured():
			node.label.visible = false
			continue

		var dist := c.pos.distance_to(Vector2(cam_pos.x, cam_pos.z))
		var prio := (2.5 if c.capital else 0.0) \
			+ (1.8 if c.category == CitySystem.Category.LARGE else (1.0 if c.category == CitySystem.Category.MEDIUM else 0.0)) \
			+ (1.2 if c.is_captured() else 0.0) \
			- dist * 0.04

		label_candidates.append({
			"node": node,
			"city": c,
			"prio": prio,
			"pos": c.pos,
		})

	label_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["prio"]) > float(b["prio"]))

	var accepted_positions: Array[Vector2] = []
	var min_gap := 7.5 if cam_altitude > 24.0 else (5.2 if cam_altitude > 15.0 else 3.8)

	for item: Dictionary in label_candidates:
		var node: CityNode = item["node"]
		var pos: Vector2 = item["pos"]

		var overlaps := false
		for acc_pos: Vector2 in accepted_positions:
			if pos.distance_to(acc_pos) < min_gap:
				overlaps = true
				break

		if overlaps:
			node.label.visible = false
		else:
			node.label.visible = true
			accepted_positions.append(pos)

## 3D shahar tugunini yaratish
func _spawn_city_node(city: CitySystem.CityData) -> void:
	_init_resources()
	var node := CityNode.new()
	node.city_data = city
	node.position = Vector3(city.pos.x, ArenaBuilder.LAND_HEIGHT, city.pos.y)

	# 1. Asosiy shahar arxitekturasi mesh
	var m_inst := MeshInstance3D.new()
	m_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var target_mesh: ArrayMesh = null
	var scale_factor := 1.0

	match city.category:
		CitySystem.Category.LARGE:
			target_mesh = _mesh_large
			scale_factor = 0.95
		CitySystem.Category.MEDIUM:
			target_mesh = _mesh_medium
			scale_factor = 0.90
		_:
			target_mesh = _mesh_small
			scale_factor = 0.85

	# Zich joylashgan qo'shni shaharlar bir-birini yopib qo'ymasligi uchun moslashuvchan o'lcham
	var density_scale := 1.0
	if city.neighbor_dist < 12.0:
		density_scale = clampf(city.neighbor_dist / 12.0, 0.52, 1.0)
		if city.category == CitySystem.Category.SMALL and city.neighbor_dist < 10.0:
			density_scale = minf(density_scale, 0.65)
	scale_factor *= density_scale

	m_inst.mesh = target_mesh
	node.add_child(m_inst)
	node.model_inst = m_inst

	# 2. Regional Landmark (Parij, Samarqand, Rim, Yaponiya, Misr)
	var landmark_mesh := _get_landmark_mesh(city.regional_style)
	if landmark_mesh != null:
		var l_inst := MeshInstance3D.new()
		l_inst.mesh = landmark_mesh
		l_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Landmarkni markaziy maydonga joylash
		l_inst.position = Vector3(0.0, 0.25, 0.0)
		node.add_child(l_inst)
		node.landmark_inst = l_inst

	# 3. Davlat bayrog'i shtokasi va hilpiraydigan bayroq matosi
	var flag_group := Node3D.new()
	var pole := MeshInstance3D.new()
	pole.mesh = _pole_mesh
	pole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flag_group.add_child(pole)

	# Shtoka balandligi toifaga qarab
	var flag_w := 0.75
	var pole_h := 1.9
	if city.category == CitySystem.Category.LARGE:
		pole_h = 3.2
		flag_w = 1.2
	elif city.category == CitySystem.Category.MEDIUM:
		pole_h = 2.5
		flag_w = 0.95

	pole.position = Vector3(0, pole_h * 0.5, 0)
	pole.scale = Vector3(0.7, pole_h / 4.5, 0.7)

	# Bayroq matosi (QuadMesh)
	var flag_quad := QuadMesh.new()
	var flag_h := flag_w * 0.65
	flag_quad.size = Vector2(flag_w, flag_h)
	var f_mat := ShaderMaterial.new()
	f_mat.shader = _flag_shader

	var c_code := city.owner_country if not city.owner_country.is_empty() else city.country_code
	var f_tex := FlagRenderer.get_flag_texture(c_code)
	f_mat.set_shader_parameter("flag_tex", f_tex)

	var flag_mesh_inst := MeshInstance3D.new()
	flag_mesh_inst.mesh = flag_quad
	flag_mesh_inst.material_override = f_mat
	flag_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Bayroq ustunning yuqori qismidan o'ngga qarab hilpiraydi
	flag_mesh_inst.position = Vector3(flag_w * 0.5, pole_h - flag_h * 0.5 - 0.05, 0.0)
	flag_group.add_child(flag_mesh_inst)

	# Maydondagi joylashuv
	flag_group.position = Vector3(0.2, 0.0, 0.2)
	node.add_child(flag_group)
	node.flag_inst = flag_mesh_inst
	node.flag_mat = f_mat

	# 4. Shahar nomi yozuvi (3D Label)
	var lbl := Label3D.new()
	lbl.font = UiKit.display_font()
	lbl.font_size = 44
	lbl.outline_size = 10
	lbl.outline_modulate = UiKit.INK
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.render_priority = 5
	lbl.outline_render_priority = 4
	lbl.pixel_size = 0.024
	lbl.position = Vector3(0, pole_h + 1.2, 0)

	if city.is_captured():
		lbl.modulate = Palette.player_color(city.owner_id)
		lbl.text = "★ " + city.display_name + " ★"
	else:
		lbl.modulate = Color("f8fafc")
		lbl.text = city.display_name

	node.add_child(lbl)
	node.label = lbl

	# Paydo bo'lish animatsiyasi (Tug'ilish / Kirish)
	node.scale = Vector3(scale_factor * 0.2, 0.01, scale_factor * 0.2)
	node.base_scale = Vector3.ONE * scale_factor
	add_child(node)
	_active_nodes[city.id] = node

	var tw := create_tween()
	tw.tween_property(node, "scale", node.base_scale, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func _get_landmark_mesh(reg: String) -> ArrayMesh:
	match reg:
		"paris": return _mesh_paris
		"uzbek": return _mesh_uzbek
		"rome": return _mesh_rome
		"japan": return _mesh_japan
		"egypt": return _mesh_egypt
		_: return null

## Shahar egallanganda vizual effektlar (To'lqin, bayroq almashishi, ovoz, partikl)
func on_city_captured(city: CitySystem.CityData) -> void:
	var node: CityNode = _active_nodes.get(city.id, null)
	if node != null and is_instance_valid(node):
		node.update_owner_flag()
		_play_capture_pulse(node)

## Shahar qo'ldan ketganda yoki egasi o'lganda neytral holatga qaytish
func on_city_lost(city: CitySystem.CityData) -> void:
	var node: CityNode = _active_nodes.get(city.id, null)
	if node != null and is_instance_valid(node):
		node.update_owner_flag()

## Til o'zgarganda barcha 3D shahar yozuvlarini yangi tilga o'tkazish
func refresh_labels() -> void:
	for node: CityNode in _active_nodes.values():
		if node != null and is_instance_valid(node) and node.label != null and node.city_data != null:
			if node.city_data.is_captured():
				node.label.text = "★ " + node.city_data.display_name + " ★"
			else:
				node.label.text = node.city_data.display_name

## To'lqinli kengayuvchi impuls (Capture Pulse Ring)
func _play_capture_pulse(node: CityNode) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.8
	torus.outer_radius = 1.05
	torus.rings = 16
	torus.ring_segments = 12

	var mat := StandardMaterial3D.new()
	var col := Palette.player_color(node.city_data.owner_id)
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	torus.material = mat
	ring.mesh = torus
	ring.position = Vector3(0, 0.3, 0)
	node.add_child(ring)

	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(4.5, 1.0, 4.5), 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.75)
	tw.chain().tween_callback(ring.queue_free)

## O'yinchi shaharni bosganda yoki yaqinlashganda
func get_city_at_screen_ray(camera: Camera3D, screen_pos: Vector2) -> CitySystem.CityData:
	if _system == null or camera == null:
		return null
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.001:
		return null

	# Yer tekisligi (Y = LAND_HEIGHT) bilan kesishish
	var t := (ArenaBuilder.LAND_HEIGHT - from.y) / dir.y
	if t < 0.0:
		return null
	var hit := from + dir * t
	var hit_2d := Vector2(hit.x, hit.z)
	return _system.get_city_at_world_pos(hit_2d, 4.0)
