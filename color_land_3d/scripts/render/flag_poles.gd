class_name FlagPoles
extends Node3D

## 3D milliy bayroq ustunlari tizimi:
## - Boshlang'ich baza va yirik bog'langan hududlar uchun
## - Suvda yoki raqib hududida aslo turmaydi (avtomatik tekshiruv va tozalash)
## - Raqib bosib olganda eskirgan ustunlar darhol o'chiriladi
## - Takroriy (dublikat) bayroqlar qo'yilmaydi
## - GameGrid.version_of() orqali faqat hudud o'zgarganda hisoblanadi (keshlangan optimizatsiya)

const ArenaBuilder := preload("res://scripts/render/arena_builder.gd")
const FlagRenderer := preload("res://scripts/render/flag_renderer.gd")

const POLE_HEIGHT := 6.8
const POLE_RADIUS := 0.14
const FLAG_WIDTH := 4.2
const FLAG_HEIGHT := 2.8

## To'lqinlanuvchi mato shaderi (ikkala tomondan ko'rinuvchi, mayin shamol)
const FLAG_SHADER := """
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D flag_tex : source_color, filter_linear;
uniform float wave_speed = 4.2;
uniform float wave_freq = 3.0;
uniform float wave_amp = 0.28;

void vertex() {
	// UV.x = 0 (ustun tomoni) mahkamlangan, UV.x = 1 (uch tomoni) kuchliroq to'lqinlanadi
	float dist = UV.x;
	VERTEX.z += sin(TIME * wave_speed + UV.x * wave_freq) * wave_amp * dist;
	VERTEX.y += cos(TIME * (wave_speed * 0.75) + UV.x * 2.2) * (wave_amp * 0.18) * dist;
}

void fragment() {
	vec4 col = texture(flag_tex, UV);
	ALBEDO = col.rgb;
	ROUGHNESS = 0.45;
	SPECULAR = 0.25;
}
"""

var _pole_material: StandardMaterial3D
var _finial_material: StandardMaterial3D
var _pole_mesh: CylinderMesh
var _finial_mesh: SphereMesh
var _cloth_mesh: PlaneMesh
var _flag_shader_res: Shader

var _world: GameWorld
## Har bir o'yinchining boshlang'ich baza bayrog'i {player_id: Node3D}
var _base_poles: Dictionary = {}
## Har bir o'yinchining yirik hudud bayrog'i {player_id: Node3D}
var _territory_poles: Dictionary = {}

## Profiling va optimizatsiya: har kadrda qayta hisoblamaslik uchun
var _last_grid_versions: Dictionary = {}
var _last_update_usec: int = 0
var _total_updates: int = 0
var _total_usec: int = 0
var average_update_usec: float = 0.0

func _ready() -> void:
	_init_resources()

func _init_resources() -> void:
	if _cloth_mesh != null:
		return

	# Ustun materiali: yaltiroq kumushrang metall
	_pole_material = StandardMaterial3D.new()
	_pole_material.albedo_color = Color("d1d5db")
	_pole_material.metallic = 0.85
	_pole_material.roughness = 0.25

	# Cho'qqi shar (finial): oltin
	_finial_material = StandardMaterial3D.new()
	_finial_material.albedo_color = Color("f59e0b")
	_finial_material.metallic = 0.90
	_finial_material.roughness = 0.20

	_pole_mesh = CylinderMesh.new()
	_pole_mesh.top_radius = POLE_RADIUS * 0.85
	_pole_mesh.bottom_radius = POLE_RADIUS
	_pole_mesh.height = POLE_HEIGHT
	_pole_mesh.radial_segments = 12
	_pole_mesh.material = _pole_material

	_finial_mesh = SphereMesh.new()
	_finial_mesh.radius = POLE_RADIUS * 2.4
	_finial_mesh.height = POLE_RADIUS * 4.8
	_finial_mesh.radial_segments = 12
	_finial_mesh.rings = 6
	_finial_mesh.material = _finial_material

	_flag_shader_res = Shader.new()
	_flag_shader_res.code = FLAG_SHADER

	# Mato to'ri: mayin to'lqinlanish uchun
	_cloth_mesh = PlaneMesh.new()
	_cloth_mesh.size = Vector2(FLAG_WIDTH, FLAG_HEIGHT)
	_cloth_mesh.subdivide_width = 8
	_cloth_mesh.subdivide_depth = 4
	_cloth_mesh.orientation = PlaneMesh.FACE_Z

## Dunyo o'yinchilari bo'yicha bayroqlarni qayta qurish
func setup(world: GameWorld) -> void:
	_world = world
	clear()
	if _world == null:
		return
	_init_resources()

	for p in _world.players:
		_create_base_flag(p)

func clear() -> void:
	for node: Node3D in _base_poles.values():
		if is_instance_valid(node):
			node.queue_free()
	_base_poles.clear()

	for node: Node3D in _territory_poles.values():
		if is_instance_valid(node):
			node.queue_free()
	_territory_poles.clear()
	_last_grid_versions.clear()

## Boshlang'ich baza bayrog'ini o'rnatish
func _create_base_flag(p: PlayerState) -> void:
	_init_resources()
	var valid_pt := _find_valid_owned_cell(Vector2(p.x, p.y), p.id)
	if valid_pt == Vector2.ZERO:
		return

	var base_node := _build_flagpole_node(p.country)
	base_node.position = Vector3(valid_pt.x, ArenaBuilder.LAND_HEIGHT, valid_pt.y)
	add_child(base_node)
	_base_poles[p.id] = base_node

	# Ko'tarilish (raising) animatsiyasi
	base_node.scale = Vector3(0.1, 0.0, 0.1)
	var tw := base_node.create_tween()
	tw.tween_property(base_node, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Bitta to'liq 3D bayroq ustuni obyektini yig'ish (fizik to'qnashuvsiz)
func _build_flagpole_node(country_code: String) -> Node3D:
	var root := Node3D.new()

	# Ustun
	var pole := MeshInstance3D.new()
	pole.mesh = _pole_mesh
	pole.material_override = _pole_material
	pole.position = Vector3(0.0, POLE_HEIGHT * 0.5, 0.0)
	pole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(pole)

	# Cho'qqi oltin shar
	var finial := MeshInstance3D.new()
	finial.mesh = _finial_mesh
	finial.material_override = _finial_material
	finial.position = Vector3(0.0, POLE_HEIGHT, 0.0)
	finial.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(finial)

	# Bayroq matosi
	var flag_mat := ShaderMaterial.new()
	flag_mat.shader = _flag_shader_res
	var tex := FlagRenderer.get_flag_texture(country_code)
	flag_mat.set_shader_parameter("flag_tex", tex)

	var cloth := MeshInstance3D.new()
	cloth.mesh = _cloth_mesh
	cloth.material_override = flag_mat
	cloth.position = Vector3(FLAG_WIDTH * 0.5, POLE_HEIGHT - FLAG_HEIGHT * 0.5 - 0.25, 0.0)
	cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(cloth)

	return root

func pole_count() -> int:
	return _base_poles.size() + _territory_poles.size()

## O'yinchiga tegishli va suv bo'lmagan eng yaqin to'g'ri katakni topish.
## Hech qachon suvga yoki dushman hududiga o'rnatilmaydi.
func _find_valid_owned_cell(center: Vector2, player_id: int) -> Vector2:
	if _world == null or _world.grid == null:
		return Vector2.ZERO
	var grid := _world.grid
	var cx := int(center.x)
	var cy := int(center.y)

	# 1. To'g'ridan-to'g'ri markaz tekshiruvi
	if grid.playable(cx, cy) and grid.owner_at(cx, cy) == player_id:
		return Vector2(cx + 0.5, cy + 0.5)

	# 2. Tashqariga qarab spiral qidiruv (radius 1 dan 18 katakgacha)
	for r: int in range(1, 19):
		for dy: int in range(-r, r + 1):
			var x1: int = cx - r
			var x2: int = cx + r
			var y: int = cy + dy
			if grid.playable(x1, y) and grid.owner_at(x1, y) == player_id:
				return Vector2(x1 + 0.5, y + 0.5)
			if grid.playable(x2, y) and grid.owner_at(x2, y) == player_id:
				return Vector2(x2 + 0.5, y + 0.5)
		for dx: int in range(-r + 1, r):
			var y1: int = cy - r
			var y2: int = cy + r
			var x: int = cx + dx
			if grid.playable(x, y1) and grid.owner_at(x, y1) == player_id:
				return Vector2(x + 0.5, y1 + 0.5)
			if grid.playable(x, y2) and grid.owner_at(x, y2) == player_id:
				return Vector2(x + 0.5, y2 + 0.5)

	return Vector2.ZERO

## Kadr yangilanishi — OPTIMALLASHGAN:
## Faqat GameGrid.version_of() o'zgarganda ishlaydi.
func update_poles() -> void:
	if _world == null or _world.grid == null:
		return

	# Tezkor tekshiruv: hech qanday o'yinchining hudud versiyasi o'zgarmagan bo'lsa, chiqish ($O(1)$)
	var any_changed := false
	for p in _world.players:
		var current_ver := _world.grid.version_of(p.id)
		if _last_grid_versions.get(p.id, -1) != current_ver:
			_last_grid_versions[p.id] = current_ver
			any_changed = true

	if not any_changed:
		return

	var start_time := Time.get_ticks_usec()

	for p in _world.players:
		# 1. Baza bayrog'ini tekshirish
		if _base_poles.has(p.id):
			var b_node: Node3D = _base_poles[p.id]
			if not p.alive:
				b_node.visible = false
			else:
				var bx := int(b_node.position.x)
				var bz := int(b_node.position.z)
				# Baza yeri dushman tomonidan bosib olinganmi yoki suvga aylanib qolganmi?
				if not _world.grid.playable(bx, bz) or _world.grid.owner_at(bx, bz) != p.id:
					# Eskirgan joydan o'yinchi egallab turgan boshqa haqiqiy yeriga ko'chirish
					var new_pt := _find_valid_owned_cell(Vector2(p.x, p.y), p.id)
					if new_pt != Vector2.ZERO:
						b_node.position = Vector3(new_pt.x, ArenaBuilder.LAND_HEIGHT, new_pt.y)
						b_node.visible = true
					else:
						# O'yinchining umuman yeri qolmagan bo'lsa — dushman yerida qoldirilmaydi!
						b_node.visible = false
				else:
					b_node.visible = true

		# 2. Yirik hudud bayrog'ini tekshirish (> 250 katak)
		var owned := _world.grid.territory_of(p.id)
		if p.alive and owned >= 250:
			var place := AvatarPlacement.of(_world.grid, p.id)
			var center: Vector2 = place["center"]
			var valid_pt := _find_valid_owned_cell(center, p.id)

			# Baza ustuniga juda yaqin bo'lsa takroriy (duplicate) bo'lmasin (kamida 20 katak masofa)
			var too_close := false
			if _base_poles.has(p.id) and is_instance_valid(_base_poles[p.id]):
				var bp: Node3D = _base_poles[p.id]
				if bp.visible and Vector2(bp.position.x, bp.position.z).distance_to(valid_pt) < 20.0:
					too_close = true

			if valid_pt != Vector2.ZERO and not too_close:
				if not _territory_poles.has(p.id):
					var t_node := _build_flagpole_node(p.country)
					t_node.position = Vector3(valid_pt.x, ArenaBuilder.LAND_HEIGHT, valid_pt.y)
					add_child(t_node)
					_territory_poles[p.id] = t_node
					# Paydo bo'lish animatsiyasi
					t_node.scale = Vector3(0.01, 0.0, 0.01)
					var tw := t_node.create_tween()
					tw.tween_property(t_node, "scale", Vector3(1.15, 1.15, 1.15), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				else:
					var t_node: Node3D = _territory_poles[p.id]
					var target_pos := Vector3(valid_pt.x, ArenaBuilder.LAND_HEIGHT, valid_pt.y)
					t_node.position = t_node.position.lerp(target_pos, 0.1)
			elif _territory_poles.has(p.id):
				# Agar hudud qisqarib ketgan bo'lsa yoki dushmanga o'tgan bo'lsa — darhol o'chirish!
				var t_node: Node3D = _territory_poles[p.id]
				t_node.queue_free()
				_territory_poles.erase(p.id)
		elif _territory_poles.has(p.id):
			var t_node: Node3D = _territory_poles[p.id]
			t_node.queue_free()
			_territory_poles.erase(p.id)

	_last_update_usec = Time.get_ticks_usec() - start_time
	_total_usec += _last_update_usec
	_total_updates += 1
	average_update_usec = float(_total_usec) / float(_total_updates)
