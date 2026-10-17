class_name FlagPoles
extends Node3D

## 3D milliy bayroq ustunlari: boshlang'ich baza va egallangan yirik hududlar uchun.
## Har bir o'yinchi va botning bazasida to'lqinlanuvchi haqiqiy 3D davlat bayrog'i turadi.

const ArenaBuilder := preload("res://scripts/render/arena_builder.gd")
const FlagRenderer := preload("res://scripts/render/flag_renderer.gd")

const POLE_HEIGHT := 5.2
const POLE_RADIUS := 0.11
const FLAG_WIDTH := 3.2
const FLAG_HEIGHT := 2.13

## To'lqinlanuvchi mato shaderi (engil vertex animatsiyasi)
const FLAG_SHADER := """
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D flag_tex : source_color, filter_linear;
uniform float wave_speed = 5.0;
uniform float wave_freq = 3.2;
uniform float wave_amp = 0.24;

void vertex() {
	// UV.x = 0 (ustun tomoni) qimirlamaydi, UV.x = 1 (uch tomoni) kuchli to'lqinlanadi
	float dist = UV.x;
	VERTEX.z += sin(TIME * wave_speed + UV.x * wave_freq) * wave_amp * dist;
	VERTEX.y += cos(TIME * (wave_speed * 0.75) + UV.x * 2.2) * (wave_amp * 0.2) * dist;
}

void fragment() {
	vec4 col = texture(flag_tex, UV);
	ALBEDO = col.rgb;
	ROUGHNESS = 0.55;
	SPECULAR = 0.2;
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

func _ready() -> void:
	_init_resources()

func _init_resources() -> void:
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
	_pole_mesh.top_radius = POLE_RADIUS * 0.8
	_pole_mesh.bottom_radius = POLE_RADIUS
	_pole_mesh.height = POLE_HEIGHT
	_pole_mesh.radial_segments = 10
	_pole_mesh.material = _pole_material

	_finial_mesh = SphereMesh.new()
	_finial_mesh.radius = POLE_RADIUS * 2.2
	_finial_mesh.height = POLE_RADIUS * 4.4
	_finial_mesh.radial_segments = 10
	_finial_mesh.rings = 6
	_finial_mesh.material = _finial_material

	_flag_shader_res = Shader.new()
	_flag_shader_res.code = FLAG_SHADER

	# Mato to'ri: mayin to'lqinlanish uchun bir necha bo'lakka bo'lingan
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

## Boshlang'ich baza bayrog'ini o'rnatish
func _create_base_flag(p: PlayerState) -> void:
	var base_node := _build_flagpole_node(p.country)
	base_node.position = Vector3(p.x, ArenaBuilder.LAND_HEIGHT, p.y)
	add_child(base_node)
	_base_poles[p.id] = base_node

	# Boshlang'ich bayroq ko'tarilish (raising) animatsiyasi
	base_node.scale = Vector3(0.1, 0.0, 0.1)
	var tw := base_node.create_tween()
	tw.tween_property(base_node, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Bitta to'liq 3D bayroq ustuni obyektini yig'ish
func _build_flagpole_node(country_code: String) -> Node3D:
	var root := Node3D.new()

	# Ustun
	var pole := MeshInstance3D.new()
	pole.mesh = _pole_mesh
	pole.position = Vector3(0.0, POLE_HEIGHT * 0.5, 0.0)
	pole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(pole)

	# Cho'qqi oltin shar
	var finial := MeshInstance3D.new()
	finial.mesh = _finial_mesh
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
	# Bayroq ustunining o'ng tomoniga (shamol esayotgandek) ilinadi
	cloth.position = Vector3(FLAG_WIDTH * 0.5, POLE_HEIGHT - FLAG_HEIGHT * 0.5 - 0.2, 0.0)
	cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(cloth)

	return root

func pole_count() -> int:
	return _base_poles.size() + _territory_poles.size()

## Kadr yangilanishi: bazalar va yirik hududlar holatini tekshirish
func update_poles() -> void:
	if _world == null:
		return

	for p in _world.players:
		# Baza bayrog'i holati
		if _base_poles.has(p.id):
			var base_node: Node3D = _base_poles[p.id]
			if not p.alive:
				if base_node.visible:
					base_node.visible = false
			else:
				base_node.visible = true

		# Yirik hudud bayrog'i (> 250 katak bo'lsa yangi hudud markazida paydo bo'ladi)
		var owned := _world.grid.territory_of(p.id)
		if p.alive and owned >= 250:
			if not _territory_poles.has(p.id):
				var place := AvatarPlacement.of(_world.grid, p.id)
				var center: Vector2 = place["center"]
				if _world.grid.playable(int(center.x), int(center.y)):
					var t_node := _build_flagpole_node(p.country)
					t_node.position = Vector3(center.x, ArenaBuilder.LAND_HEIGHT, center.y)
					t_node.scale = Vector3(1.2, 1.2, 1.2)
					add_child(t_node)
					_territory_poles[p.id] = t_node
					# Paydo bo'lish animatsiyasi
					var tw := t_node.create_tween()
					t_node.scale = Vector3(0.01, 0.0, 0.01)
					tw.tween_property(t_node, "scale", Vector3(1.2, 1.2, 1.2), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			else:
				var t_node: Node3D = _territory_poles[p.id]
				var place := AvatarPlacement.of(_world.grid, p.id)
				var center: Vector2 = place["center"]
				t_node.position = t_node.position.lerp(Vector3(center.x, ArenaBuilder.LAND_HEIGHT, center.y), 0.08)
		elif _territory_poles.has(p.id):
			var t_node: Node3D = _territory_poles[p.id]
			t_node.queue_free()
			_territory_poles.erase(p.id)
