class_name FlagPoles
extends Node3D

## 3D Davlat bayroqlari ustuni va hilpiraydigan mato rendereri.
## Har bir o'yinchi va botning boshlang'ich bazasida 3D bayroq ustuni o'rnatiladi.
## Yirik ajralgan (disconnected) hududlar alohida aniqlanib, ularga ham qo'shimcha bayroqlar o'rnatiladi.
## Suvga yoki dushman hududiga aslo qo'yilmaydi.
## Fizik to'qnashuvsiz (faqat vizual render).

const FlagRenderer = preload("res://scripts/render/flag_renderer.gd")
const AvatarPlacement = preload("res://scripts/logic/avatar_placement.gd")

const POLE_HEIGHT := 3.6
const POLE_RADIUS := 0.07
const BASE_FLAG_WIDTH := 1.8
const BASE_FLAG_HEIGHT := 1.2

const FLAG_SHADER := """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform sampler2D flag_tex : source_color, filter_linear;
uniform float wave_speed = 4.2;
uniform float wave_freq = 3.0;
uniform float wave_amp = 0.22;
uniform float fade_alpha = 1.0;

void vertex() {
	// UV.x = 0 (ustun tomoni) mahkamlangan, UV.x = 1 (uch tomoni) kuchliroq to'lqinlanadi
	float dist = UV.x;
	VERTEX.z += sin(TIME * wave_speed + UV.x * wave_freq) * wave_amp * dist;
	VERTEX.y += cos(TIME * (wave_speed * 0.75) + UV.x * 2.2) * (wave_amp * 0.16) * dist;
}

void fragment() {
	vec4 col = texture(flag_tex, UV);
	// Nepal kabi to'rtburchak bo'lmagan bayroqlar uchun shaffoflikni saqlash
	if (col.a < 0.1) {
		discard;
	}
	ALBEDO = col.rgb;
	ALPHA = col.a * fade_alpha;
	ROUGHNESS = 0.45;
	SPECULAR = 0.25;
}
"""

var _pole_material: StandardMaterial3D
var _finial_material: StandardMaterial3D
var _pole_mesh: CylinderMesh
var _finial_mesh: SphereMesh
var _flag_shader_res: Shader

var _world: GameWorld
## Har bir o'yinchining boshlang'ich baza bayrog'i {player_id: Node3D}
var _base_poles: Dictionary = {}
## Har bir o'yinchining yirik ajralgan hudud bayroqlari {player_id: Array[Node3D]}
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
	if _pole_material != null:
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

	for poles_list in _territory_poles.values():
		if poles_list is Array:
			for node in poles_list:
				if is_instance_valid(node):
					(node as Node3D).queue_free()
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

## Bitta to'liq 3D bayroq ustuni obyektini yig'ish (fizik to'qnashuvsiz).
## Har bir mamlakatning rasmiy proporsiyasi (aspect ratio) va shaffofligini saqlaydi.
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

	# Bayroq matosi — davlatning rasmiy nisbatiga mos o'lchamda
	var aspect: float = FlagRenderer.get_flag_aspect_ratio(country_code)
	var flag_h := BASE_FLAG_HEIGHT
	var flag_w := flag_h * aspect

	var cloth_mesh := PlaneMesh.new()
	cloth_mesh.size = Vector2(flag_w, flag_h)
	cloth_mesh.subdivide_width = 8
	cloth_mesh.subdivide_depth = 4
	cloth_mesh.orientation = PlaneMesh.FACE_Z

	var flag_mat := ShaderMaterial.new()
	flag_mat.shader = _flag_shader_res
	var tex := FlagRenderer.get_flag_texture(country_code)
	flag_mat.set_shader_parameter("flag_tex", tex)

	var cloth := MeshInstance3D.new()
	cloth.mesh = cloth_mesh
	cloth.material_override = flag_mat
	cloth.position = Vector3(flag_w * 0.5, POLE_HEIGHT - flag_h * 0.5 - 0.25, 0.0)
	cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(cloth)

	return root

func pole_count() -> int:
	var count := _base_poles.size()
	for p_list in _territory_poles.values():
		if p_list is Array:
			count += (p_list as Array).size()
	return count

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

## O'yinchiga tegishli ajralgan (connected components) bo'laklarni aniqlash.
## min_size dan kichik mayda bo'laklar hisobga olinmaydi.
static func find_connected_components(grid: GameGrid, player_id: int, min_size: int = 100) -> Array[Dictionary]:
	var b := grid.bounds_of(player_id)
	if b.is_empty():
		return []
	var min_x := b[0]
	var min_y := b[1]
	var max_x := b[2]
	var max_y := b[3]
	var bw := max_x - min_x + 1
	var bh := max_y - min_y + 1
	if bw <= 0 or bh <= 0:
		return []

	var visited := PackedByteArray()
	visited.resize(bw * bh)

	var components: Array[Dictionary] = []

	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var loc_idx := (y - min_y) * bw + (x - min_x)
			if visited[loc_idx] != 0:
				continue
			visited[loc_idx] = 1
			if grid.owner_at(x, y) != player_id:
				continue

			# BFS navbati
			var queue: Array[Vector2i] = [Vector2i(x, y)]
			var comp_count := 0
			var sum_x := 0.0
			var sum_y := 0.0

			var q_head := 0
			while q_head < queue.size():
				var pt: Vector2i = queue[q_head]
				q_head += 1
				comp_count += 1
				sum_x += pt.x
				sum_y += pt.y

				# 4 ta yo'nalish
				var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
				for off in offsets:
					var nx: int = pt.x + off.x
					var ny: int = pt.y + off.y
					if nx >= min_x and nx <= max_x and ny >= min_y and ny <= max_y:
						var n_loc := (ny - min_y) * bw + (nx - min_x)
						if visited[n_loc] == 0:
							visited[n_loc] = 1
							if grid.owner_at(nx, ny) == player_id:
								queue.append(Vector2i(nx, ny))

			if comp_count >= min_size:
				var center := Vector2(sum_x / float(comp_count) + 0.5, sum_y / float(comp_count) + 0.5)
				components.append({
					"size": comp_count,
					"center": center,
					"sample_cell": Vector2i(x, y)
				})

	# Hajmi bo'yicha kamayish tartibida saralash
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["size"]) > int(b["size"])
	)
	return components

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
		# 1. Boshlang'ich baza bayrog'ini tekshirish
		var base_pos_2d := Vector2.ZERO
		if _base_poles.has(p.id):
			var b_node: Node3D = _base_poles[p.id]
			if not p.alive:
				b_node.visible = false
			else:
				var bx := int(b_node.position.x)
				var bz := int(b_node.position.z)
				# Baza yeri dushman tomonidan bosib olinganmi yoki suvga aylanib qolganmi?
				if not _world.grid.playable(bx, bz) or _world.grid.owner_at(bx, bz) != p.id:
					var new_pt := _find_valid_owned_cell(Vector2(p.x, p.y), p.id)
					if new_pt != Vector2.ZERO:
						b_node.position = Vector3(new_pt.x, ArenaBuilder.LAND_HEIGHT, new_pt.y)
						b_node.visible = true
						base_pos_2d = new_pt
					else:
						# O'yinchining umuman yeri qolmagan bo'lsa — dushman yerida qoldirilmaydi!
						b_node.visible = false
				else:
					b_node.visible = true
					base_pos_2d = Vector2(b_node.position.x, b_node.position.z)

		# 2. Yirik ajralgan (disconnected) hududlar bayrog'ini tekshirish
		var owned := _world.grid.territory_of(p.id)
		if not p.alive or owned < 120:
			if _territory_poles.has(p.id):
				for node in _territory_poles[p.id]:
					if is_instance_valid(node):
						(node as Node3D).queue_free()
				_territory_poles.erase(p.id)
			continue

		# Yirik ajralgan qismlarni qidirish
		var comps := find_connected_components(_world.grid, p.id, 100)
		var desired_points: Array[Vector2] = []

		for comp in comps:
			var c_pt: Vector2 = comp["center"]
			var valid_pt := _find_valid_owned_cell(c_pt, p.id)
			if valid_pt == Vector2.ZERO:
				continue
			# Baza ustuniga juda yaqin bo'lmasin (kamida 22 katak masofa)
			if base_pos_2d != Vector2.ZERO and valid_pt.distance_to(base_pos_2d) < 22.0:
				continue
			# Boshqa ajralgan ustunlarga ham juda yaqin bo'lmasin (duplicate prevention)
			var too_close := false
			for d_pt in desired_points:
				if valid_pt.distance_to(d_pt) < 22.0:
					too_close = true
					break
			if not too_close:
				desired_points.append(valid_pt)
				if desired_points.size() >= 2: # O'yinchi uchun ko'pi bilan 2 ta qo'shimcha bayroq
					break

		# Mavjud ustunlar bilan moslashtirish
		var current_list: Array = _territory_poles.get(p.id, [])
		var next_list: Array = []
		var used_pts := {}

		for node in current_list:
			if not is_instance_valid(node):
				continue
			var node_3d: Node3D = node as Node3D
			var n_pos := Vector2(node_3d.position.x, node_3d.position.z)
			var best_idx := -1
			var best_dist := 16.0
			for i in desired_points.size():
				if used_pts.has(i):
					continue
				var d := n_pos.distance_to(desired_points[i])
				if d < best_dist:
					best_dist = d
					best_idx = i
			if best_idx >= 0:
				used_pts[best_idx] = true
				var target_pos := Vector3(desired_points[best_idx].x, ArenaBuilder.LAND_HEIGHT, desired_points[best_idx].y)
				node_3d.position = node_3d.position.lerp(target_pos, 0.1)
				next_list.append(node_3d)
			else:
				# Bu ajralgan qism dushman tomonidan egallangan yoki yo'qolgan — ustun o'chiriladi
				node_3d.queue_free()

		# Yangi ajralgan hududlar uchun yangi ustunlar yaratish
		for i in desired_points.size():
			if not used_pts.has(i):
				var target_pt := desired_points[i]
				var t_node := _build_flagpole_node(p.country)
				t_node.position = Vector3(target_pt.x, ArenaBuilder.LAND_HEIGHT, target_pt.y)
				add_child(t_node)
				next_list.append(t_node)
				# Paydo bo'lish animatsiyasi
				t_node.scale = Vector3(0.01, 0.0, 0.01)
				var tw := t_node.create_tween()
				tw.tween_property(t_node, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		if next_list.is_empty():
			_territory_poles.erase(p.id)
		else:
			_territory_poles[p.id] = next_list

	_last_update_usec = Time.get_ticks_usec() - start_time
	_total_usec += _last_update_usec
	_total_updates += 1
	average_update_usec = float(_total_usec) / float(_total_updates)

var quality_preset: String = "medium"
var _cull_distance: float = 90.0

func set_quality_preset(preset: String) -> void:
	quality_preset = preset.to_lower()
	match quality_preset:
		"low":
			_cull_distance = 50.0
		"high":
			_cull_distance = 150.0
		_:
			_cull_distance = 90.0

## Kamera yaqinlashganda bayroqlarni ko'rish maydonini to'sib qo'ymasligi uchun moslashtirish
func update_camera_culling(cam: Camera3D) -> void:
	if cam == null:
		return
	var cam_pos := cam.global_position
	for node in _base_poles.values():
		if is_instance_valid(node):
			_apply_proximity_culling(node as Node3D, cam_pos, true)
	for poles_list in _territory_poles.values():
		if poles_list is Array:
			for node in poles_list:
				if is_instance_valid(node):
					_apply_proximity_culling(node as Node3D, cam_pos, false)

func _apply_proximity_culling(node: Node3D, cam_pos: Vector3, is_base: bool = false) -> void:
	var dist := node.global_position.distance_to(cam_pos)
	if not is_base and dist > _cull_distance:
		node.visible = false
		return
	if dist < 5.5:
		var factor := clampf((dist - 2.0) / 3.5, 0.2, 1.0)
		node.scale = Vector3(factor, factor, factor)
		node.visible = dist > 2.0
	else:
		node.scale = Vector3.ONE
		node.visible = true
