class_name CityMeshBuilder
extends RefCounted

## Color Land 3D — 3D Shahar Geometriyasi Yaratuvchisi
##
## Foydalanuvchi yuborgan 3 ta vizual namunaga (Small, Medium, Large)
## 100% mos keladigan haqiqiy 3D modellar.
##
## Barcha modellar bitta umumiy material va SurfaceTool orqali
## Vertex Color yordamida chiziladi:
##  - 0 ta ortiqcha tekstura
##  - Mobil telefonlar (Android) uchun yuqori FPS va past xotira sarfi
##  - Nozik soyalar va tabiiy yorug'lik

static var _shared_material: StandardMaterial3D

static func get_material() -> StandardMaterial3D:
	if _shared_material == null:
		_shared_material = StandardMaterial3D.new()
		_shared_material.vertex_color_use_as_albedo = true
		_shared_material.roughness = 0.52
		_shared_material.metallic = 0.05
		_shared_material.cull_mode = BaseMaterial3D.CULL_BACK
	return _shared_material

static func clear_cache() -> void:
	_shared_material = null

# ==============================================================================
# GEOMETRIYA ASOSLARI (PRIMITIVES)
# ==============================================================================

static func add_box(st: SurfaceTool, center: Vector3, size: Vector3, col: Color) -> void:
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5

	var p0 := center + Vector3(-hx, -hy, -hz)
	var p1 := center + Vector3( hx, -hy, -hz)
	var p2 := center + Vector3( hx,  hy, -hz)
	var p3 := center + Vector3(-hx,  hy, -hz)
	var p4 := center + Vector3(-hx, -hy,  hz)
	var p5 := center + Vector3( hx, -hy,  hz)
	var p6 := center + Vector3( hx,  hy,  hz)
	var p7 := center + Vector3(-hx,  hy,  hz)

	# Yuqori (Top) - yorqinroq
	_quad(st, p7, p6, p2, p3, Vector3.UP, col.lightened(0.08))
	# Pastki (Bottom) - to'qroq
	_quad(st, p4, p0, p1, p5, Vector3.DOWN, col.darkened(0.25))
	# Oldi (+Z)
	_quad(st, p5, p6, p7, p4, Vector3.BACK, col)
	# Orqa (-Z)
	_quad(st, p0, p3, p2, p1, Vector3.FORWARD, col.darkened(0.12))
	# Chap (-X)
	_quad(st, p4, p7, p3, p0, Vector3.LEFT, col.darkened(0.08))
	# O'ng (+X)
	_quad(st, p1, p2, p6, p5, Vector3.RIGHT, col.lightened(0.04))

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, norm: Vector3, col: Color) -> void:
	st.set_color(col)
	st.set_normal(norm)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(a)
	st.set_uv(Vector2(1, 0))
	st.add_vertex(b)
	st.set_uv(Vector2(1, 1))
	st.add_vertex(c)

	st.set_uv(Vector2(0, 0))
	st.add_vertex(a)
	st.set_uv(Vector2(1, 1))
	st.add_vertex(c)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(d)

static func add_cylinder(st: SurfaceTool, center: Vector3, r_bot: float, r_top: float, h: float, segs: int, col: Color) -> void:
	var half_h := h * 0.5
	var y_bot := center.y - half_h
	var y_top := center.y + half_h

	for i in segs:
		var a0 := float(i) * TAU / float(segs)
		var a1 := float(i + 1) * TAU / float(segs)

		var c0 := cos(a0)
		var s0 := sin(a0)
		var c1 := cos(a1)
		var s1 := sin(a1)

		var v_b0 := Vector3(center.x + c0 * r_bot, y_bot, center.z + s0 * r_bot)
		var v_b1 := Vector3(center.x + c1 * r_bot, y_bot, center.z + s1 * r_bot)
		var v_t0 := Vector3(center.x + c0 * r_top, y_top, center.z + s0 * r_top)
		var v_t1 := Vector3(center.x + c1 * r_top, y_top, center.z + s1 * r_top)

		var norm := Vector3((c0 + c1) * 0.5, 0.0, (s0 + s1) * 0.5).normalized()
		_quad(st, v_b0, v_b1, v_t1, v_t0, norm, col)

		# Yuqori qopqoq
		if r_top > 0.001:
			st.set_color(col.lightened(0.08))
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2.ZERO); st.add_vertex(Vector3(center.x, y_top, center.z))
			st.set_uv(Vector2.ZERO); st.add_vertex(v_t0)
			st.set_uv(Vector2.ZERO); st.add_vertex(v_t1)

		# Pastki qopqoq
		if r_bot > 0.001:
			st.set_color(col.darkened(0.2))
			st.set_normal(Vector3.DOWN)
			st.set_uv(Vector2.ZERO); st.add_vertex(Vector3(center.x, y_bot, center.z))
			st.set_uv(Vector2.ZERO); st.add_vertex(v_b1)
			st.set_uv(Vector2.ZERO); st.add_vertex(v_b0)

static func add_cone(st: SurfaceTool, center: Vector3, radius: float, h: float, segs: int, col: Color) -> void:
	var apex := center + Vector3(0, h, 0)
	var y_bot := center.y

	for i in segs:
		var a0 := float(i) * TAU / float(segs)
		var a1 := float(i + 1) * TAU / float(segs)

		var c0 := cos(a0)
		var s0 := sin(a0)
		var c1 := cos(a1)
		var s1 := sin(a1)

		var b0 := Vector3(center.x + c0 * radius, y_bot, center.z + s0 * radius)
		var b1 := Vector3(center.x + c1 * radius, y_bot, center.z + s1 * radius)

		var norm := Vector3((c0 + c1) * 0.5, 0.35, (s0 + s1) * 0.5).normalized()
		st.set_color(col)
		st.set_normal(norm)
		st.set_uv(Vector2.ZERO); st.add_vertex(apex)
		st.set_uv(Vector2.ZERO); st.add_vertex(b0)
		st.set_uv(Vector2.ZERO); st.add_vertex(b1)

		# Pastki taglik
		st.set_color(col.darkened(0.25))
		st.set_normal(Vector3.DOWN)
		st.set_uv(Vector2.ZERO); st.add_vertex(center)
		st.set_uv(Vector2.ZERO); st.add_vertex(b1)
		st.set_uv(Vector2.ZERO); st.add_vertex(b0)

static func add_pyramid(st: SurfaceTool, center: Vector3, size: Vector3, col: Color) -> void:
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	var y_bot := center.y - size.y * 0.5
	var apex := center + Vector3(0, size.y * 0.5, 0)

	var p0 := Vector3(center.x - hx, y_bot, center.z - hz)
	var p1 := Vector3(center.x + hx, y_bot, center.z - hz)
	var p2 := Vector3(center.x + hx, y_bot, center.z + hz)
	var p3 := Vector3(center.x - hx, y_bot, center.z + hz)

	# 4 ta qiya tomon
	var n_fwd := Vector3(0, 0.6, -1).normalized()
	var n_bck := Vector3(0, 0.6, 1).normalized()
	var n_lft := Vector3(-1, 0.6, 0).normalized()
	var n_rgt := Vector3(1, 0.6, 0).normalized()

	st.set_color(col.darkened(0.08))
	st.set_normal(n_fwd)
	st.set_uv(Vector2.ZERO); st.add_vertex(apex)
	st.set_uv(Vector2.ZERO); st.add_vertex(p0)
	st.set_uv(Vector2.ZERO); st.add_vertex(p1)

	st.set_color(col)
	st.set_normal(n_bck)
	st.set_uv(Vector2.ZERO); st.add_vertex(apex)
	st.set_uv(Vector2.ZERO); st.add_vertex(p2)
	st.set_uv(Vector2.ZERO); st.add_vertex(p3)

	st.set_color(col.darkened(0.04))
	st.set_normal(n_lft)
	st.set_uv(Vector2.ZERO); st.add_vertex(apex)
	st.set_uv(Vector2.ZERO); st.add_vertex(p3)
	st.set_uv(Vector2.ZERO); st.add_vertex(p0)

	st.set_color(col.lightened(0.06))
	st.set_normal(n_rgt)
	st.set_uv(Vector2.ZERO); st.add_vertex(apex)
	st.set_uv(Vector2.ZERO); st.add_vertex(p1)
	st.set_uv(Vector2.ZERO); st.add_vertex(p2)

	# Taglik
	_quad(st, p3, p2, p1, p0, Vector3.DOWN, col.darkened(0.2))

static func add_gable_roof(st: SurfaceTool, center: Vector3, size: Vector3, peak_h: float, col: Color, along_x: bool = false) -> void:
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	var y_base := center.y - size.y * 0.5
	var y_peak := center.y + size.y * 0.5 + peak_h

	if along_x:
		# Ridge x o'qi bo'ylab
		var r0 := Vector3(center.x - hx, y_peak, center.z)
		var r1 := Vector3(center.x + hx, y_peak, center.z)
		var e_l0 := Vector3(center.x - hx, y_base, center.z - hz)
		var e_l1 := Vector3(center.x + hx, y_base, center.z - hz)
		var e_r0 := Vector3(center.x - hx, y_base, center.z + hz)
		var e_r1 := Vector3(center.x + hx, y_base, center.z + hz)

		var n_l := Vector3(0, 0.7, -0.7).normalized()
		var n_r := Vector3(0, 0.7, 0.7).normalized()
		_quad(st, e_l0, e_l1, r1, r0, n_l, col.darkened(0.06))
		_quad(st, r0, r1, e_r1, e_r0, n_r, col.lightened(0.06))

		# Gable uchburchaklari
		st.set_color(col.darkened(0.12))
		st.set_normal(Vector3.LEFT)
		st.set_uv(Vector2.ZERO); st.add_vertex(r0)
		st.set_uv(Vector2.ZERO); st.add_vertex(e_r0)
		st.set_uv(Vector2.ZERO); st.add_vertex(e_l0)

		st.set_color(col.lightened(0.02))
		st.set_normal(Vector3.RIGHT)
		st.set_uv(Vector2.ZERO); st.add_vertex(r1)
		st.set_uv(Vector2.ZERO); st.add_vertex(e_l1)
		st.set_uv(Vector2.ZERO); st.add_vertex(e_r1)
	else:
		# Ridge z o'qi bo'ylab (standart)
		var r0 := Vector3(center.x, y_peak, center.z - hz)
		var r1 := Vector3(center.x, y_peak, center.z + hz)
		var e_l0 := Vector3(center.x - hx, y_base, center.z - hz)
		var e_l1 := Vector3(center.x - hx, y_base, center.z + hz)
		var e_r0 := Vector3(center.x + hx, y_base, center.z - hz)
		var e_r1 := Vector3(center.x + hx, y_base, center.z + hz)

		var n_l := Vector3(-0.7, 0.7, 0).normalized()
		var n_r := Vector3(0.7, 0.7, 0).normalized()
		_quad(st, e_l0, r0, r1, e_l1, n_l, col.darkened(0.06))
		_quad(st, r0, e_r0, e_r1, r1, n_r, col.lightened(0.06))

		# Gable uchburchaklari
		st.set_color(col.darkened(0.12))
		st.set_normal(Vector3.FORWARD)
		st.set_uv(Vector2.ZERO); st.add_vertex(r0)
		st.set_uv(Vector2.ZERO); st.add_vertex(e_l0)
		st.set_uv(Vector2.ZERO); st.add_vertex(e_r0)

		st.set_color(col.lightened(0.02))
		st.set_normal(Vector3.BACK)
		st.set_uv(Vector2.ZERO); st.add_vertex(r1)
		st.set_uv(Vector2.ZERO); st.add_vertex(e_r1)
		st.set_uv(Vector2.ZERO); st.add_vertex(e_l1)

static func add_tree_pine(st: SurfaceTool, center: Vector3, trunk_h: float, trunk_r: float, fol_r: float, fol_h: float) -> void:
	# Dastak (Trunk)
	var t_col := Color("6d4c41")
	add_cylinder(st, center + Vector3(0, trunk_h * 0.5, 0), trunk_r, trunk_r * 0.9, trunk_h, 6, t_col)

	# 3 pog'onali ignabarg konuslari
	var c_col1 := Color("1b5e20")
	var c_col2 := Color("2e7d32")
	var c_col3 := Color("388e3c")

	var step_h := fol_h * 0.42
	var y0 := center.y + trunk_h * 0.7
	add_cone(st, Vector3(center.x, y0, center.z), fol_r, step_h * 1.3, 7, c_col1)
	add_cone(st, Vector3(center.x, y0 + step_h * 0.65, center.z), fol_r * 0.82, step_h * 1.15, 7, c_col2)
	add_cone(st, Vector3(center.x, y0 + step_h * 1.35, center.z), fol_r * 0.60, step_h * 1.0, 7, c_col3)

static func add_tree_round(st: SurfaceTool, center: Vector3, trunk_h: float, trunk_r: float, fol_r: float, col: Color) -> void:
	# Dastak
	add_cylinder(st, center + Vector3(0, trunk_h * 0.5, 0), trunk_r, trunk_r, trunk_h, 6, Color("795548"))
	# Dumaloq barg tojisi (prizma/dodekaedr)
	add_cylinder(st, center + Vector3(0, trunk_h + fol_r * 0.75, 0), fol_r * 0.7, fol_r * 0.95, fol_r * 1.1, 7, col)
	add_cylinder(st, center + Vector3(0, trunk_h + fol_r * 1.45, 0), fol_r * 0.95, fol_r * 0.4, fol_r * 0.8, 7, col.lightened(0.08))

static func add_car(st: SurfaceTool, center: Vector3, size: Vector3, body_col: Color, rot_y: float) -> void:
	# Oddiy stilizatsiya qilingan mini-avtomobil
	var base_h := size.y * 0.45
	var cab_h := size.y * 0.55

	var cos_r := cos(rot_y)
	var sin_r := sin(rot_y)

	# Asosiy kuzov
	add_box(st, center + Vector3(0, base_h * 0.5, 0), size, body_col)
	# Kabina
	var cab_size := Vector3(size.x * 0.78, cab_h, size.z * 0.58)
	var cab_pos := center + Vector3(0, base_h + cab_h * 0.5, -size.z * 0.08)
	add_box(st, cab_pos, cab_size, body_col.lightened(0.1))
	# Qoraytirilgan oyna
	add_box(st, cab_pos + Vector3(0, 0, cab_size.z * 0.52), Vector3(cab_size.x * 0.85, cab_h * 0.7, 0.04), Color("1e293b"))
	add_box(st, cab_pos - Vector3(0, 0, cab_size.z * 0.52), Vector3(cab_size.x * 0.85, cab_h * 0.7, 0.04), Color("1e293b"))
	# Fara
	add_box(st, center + Vector3(size.x * 0.28, base_h * 0.55, size.z * 0.51), Vector3(size.x * 0.22, base_h * 0.35, 0.04), Color("fef08a"))
	add_box(st, center + Vector3(-size.x * 0.28, base_h * 0.55, size.z * 0.51), Vector3(size.x * 0.22, base_h * 0.35, 0.04), Color("fef08a"))

static func add_striped_awning(st: SurfaceTool, center: Vector3, size: Vector3, col1: Color, col2: Color, stripes: int = 5) -> void:
	var stripe_w := size.x / float(stripes)
	var start_x := center.x - size.x * 0.5
	for s in stripes:
		var c := col1 if (s % 2 == 0) else col2
		var pos := Vector3(start_x + (float(s) + 0.5) * stripe_w, center.y, center.z)
		# Qiya ayvon (sloped)
		var hx := stripe_w * 0.5
		var hy := size.y * 0.5
		var hz := size.z * 0.5

		var p0 := pos + Vector3(-hx, hy, -hz)
		var p1 := pos + Vector3( hx, hy, -hz)
		var p2 := pos + Vector3( hx, -hy, hz)
		var p3 := pos + Vector3(-hx, -hy, hz)
		var n := Vector3(0, 0.6, 0.8).normalized()
		_quad(st, p0, p1, p2, p3, n, c)

# ==============================================================================
# 1. KICHIK SHAHAR MODELI (SMALL CITY) — media_1792231859791_8d99adb0.png
# ==============================================================================

static func build_small_city_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 1. Dumaloq yashil orolcha (Island base)
	var base_col := Color("84cc16") # Chiroyli maysa yashil
	add_cylinder(st, Vector3(0, 0.10, 0), 3.25, 3.15, 0.20, 22, base_col)

	# 2. Qumloq / tuproqli qishloq yo'laklari (Curved village path)
	var path_col := Color("e5d7ad")
	# Asosiy markaziy yo'l
	add_cylinder(st, Vector3(0.1, 0.21, 0.1), 1.25, 1.25, 0.02, 14, path_col)
	add_box(st, Vector3(-0.9, 0.21, 0.4), Vector3(1.6, 0.02, 0.65), path_col)
	add_box(st, Vector3(0.8, 0.21, -0.6), Vector3(0.7, 0.02, 1.6), path_col)
	add_box(st, Vector3(0.4, 0.21, 1.3), Vector3(1.8, 0.02, 0.6), path_col)

	# 3. Sabzavot / ekin polizi (Garden plot)
	var soil_col := Color("795548")
	var crop_col := Color("4caf50")
	var garden_pos := Vector3(1.7, 0.22, 1.4)
	add_box(st, garden_pos, Vector3(1.3, 0.04, 0.95), soil_col)
	for r in 2:
		for c in 3:
			var cx := garden_pos.x - 0.4 + float(c) * 0.4
			var cz := garden_pos.z - 0.2 + float(r) * 0.4
			add_cylinder(st, Vector3(cx, 0.27, cz), 0.09, 0.07, 0.08, 6, crop_col)

	# 4. Stylized qarag'aylar va butalar (Trees & bushes)
	add_tree_pine(st, Vector3(1.8, 0.20, -1.8), 0.7, 0.09, 0.55, 1.3)
	add_tree_pine(st, Vector3(2.4, 0.20, -1.0), 0.9, 0.11, 0.70, 1.6)
	add_tree_pine(st, Vector3(2.6, 0.20, 0.1), 0.75, 0.10, 0.60, 1.4)

	# Dumaloq butalar
	var bush_col := Color("4ade80")
	add_tree_round(st, Vector3(-2.2, 0.20, -0.3), 0.2, 0.06, 0.38, bush_col)
	add_tree_round(st, Vector3(-2.0, 0.20, 0.4), 0.15, 0.05, 0.32, bush_col.lightened(0.06))
	add_tree_round(st, Vector3(-1.8, 0.20, -1.1), 0.18, 0.05, 0.35, bush_col.darkened(0.06))
	add_tree_round(st, Vector3(1.9, 0.20, 2.3), 0.12, 0.04, 0.28, bush_col)

	# 5. Markaziy Qishloq Cherkovi / Ibodatxonasi (Central village church)
	var wall_cream := Color("fdfbf7")
	var roof_terra := Color("ea580c")
	var door_wood := Color("5c3d2e")
	var win_blue := Color("38bdf8")
	var gold_col := Color("fbbf24")

	# Cherkov minorasi
	var tower_pos := Vector3(-0.6, 0.90, -0.9)
	add_box(st, tower_pos, Vector3(0.85, 1.4, 0.85), wall_cream)
	# Minoradagi piramida tom
	add_pyramid(st, tower_pos + Vector3(0, 1.05, 0), Vector3(1.0, 0.7, 1.0), roof_terra)
	# Cho'qqidagi oltin shtil / xoch
	add_cylinder(st, tower_pos + Vector3(0, 1.5, 0), 0.04, 0.01, 0.2, 6, gold_col)
	# Minora eshigi va oynasi
	add_box(st, tower_pos + Vector3(0, -0.35, 0.44), Vector3(0.3, 0.6, 0.04), door_wood)
	add_box(st, tower_pos + Vector3(0, 0.35, 0.44), Vector3(0.24, 0.45, 0.04), win_blue)

	# Cherkov asosiy zali (Nave)
	var hall_pos := Vector3(0.25, 0.80, -0.9)
	add_box(st, hall_pos, Vector3(1.0, 1.2, 0.85), wall_cream)
	add_gable_roof(st, hall_pos, Vector3(1.15, 0.3, 0.95), 0.55, roof_terra, true)
	# Zal oynalari
	add_box(st, hall_pos + Vector3(-0.25, 0.1, 0.44), Vector3(0.2, 0.35, 0.03), win_blue)
	add_box(st, hall_pos + Vector3( 0.25, 0.1, 0.44), Vector3(0.2, 0.35, 0.03), win_blue)

	# 6. Ikki qavatli katta qishloq uyi (Two-story village house)
	var h1_pos := Vector3(1.4, 0.95, -0.3)
	add_box(st, h1_pos, Vector3(1.25, 1.5, 1.15), wall_cream)
	add_gable_roof(st, h1_pos, Vector3(1.4, 0.2, 1.3), 0.65, roof_terra, false)
	# Eshik va derazalar
	add_box(st, h1_pos + Vector3(-0.25, -0.45, 0.59), Vector3(0.28, 0.55, 0.03), door_wood)
	add_box(st, h1_pos + Vector3( 0.32, -0.45, 0.59), Vector3(0.22, 0.28, 0.03), win_blue)
	add_box(st, h1_pos + Vector3(-0.32,  0.30, 0.59), Vector3(0.22, 0.28, 0.03), win_blue)
	add_box(st, h1_pos + Vector3( 0.32,  0.30, 0.59), Vector3(0.22, 0.28, 0.03), win_blue)
	add_box(st, h1_pos + Vector3(-0.64,  0.30, 0.0), Vector3(0.03, 0.28, 0.22), win_blue)
	add_box(st, h1_pos + Vector3(-0.64, -0.40, 0.0), Vector3(0.03, 0.28, 0.22), win_blue)

	# 7. Oldingi kichik kottej (Front cottage)
	var h2_pos := Vector3(-0.2, 0.65, 0.8)
	add_box(st, h2_pos, Vector3(1.05, 0.9, 0.95), wall_cream)
	add_gable_roof(st, h2_pos, Vector3(1.2, 0.2, 1.1), 0.55, roof_terra, false)
	add_box(st, h2_pos + Vector3(-0.22, -0.2, 0.49), Vector3(0.25, 0.50, 0.03), door_wood)
	add_box(st, h2_pos + Vector3( 0.24, -0.15, 0.49), Vector3(0.20, 0.25, 0.03), win_blue)

	# 8. Chapdagi kichik kottej (Left cottage)
	var h3_pos := Vector3(-1.6, 0.60, -0.3)
	add_box(st, h3_pos, Vector3(0.95, 0.8, 0.90), wall_cream)
	add_gable_roof(st, h3_pos, Vector3(1.1, 0.2, 1.0), 0.50, roof_terra, false)
	add_box(st, h3_pos + Vector3(0.22, -0.15, 0.46), Vector3(0.25, 0.45, 0.03), door_wood)
	add_box(st, h3_pos + Vector3(-0.22, -0.10, 0.46), Vector3(0.20, 0.24, 0.03), win_blue)

	# 9. Qishloq maydonidagi bayroq poydevori
	add_cylinder(st, Vector3(0.1, 0.32, 0.0), 0.35, 0.28, 0.16, 12, Color("cbd5e1"))

	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, get_material())
	return m

# ==============================================================================
# 2. O'RTA SHAHAR MODELI (MEDIUM CITY) — media_1792231869893_242e34d3.png
# ==============================================================================

static func build_medium_city_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 1. Katta kvadrat yo'l tarmog'i (Street grid block) - 5.6 x 5.6
	var road_col := Color("334155") # To'q asfalt
	var curb_col := Color("cbd5e1") # Beton trotuar
	var park_col := Color("65a30d") # Park maysasi
	var line_col := Color("f8fafc") # Oq chiziqlar

	# Pastki plita
	add_box(st, Vector3(0, 0.08, 0), Vector3(5.6, 0.16, 5.6), road_col)

	# Trotuarlar (4 ta asosiy blok poydevori)
	var b_offset := 1.7
	var b_size := 1.8
	var b_h := 0.22
	add_box(st, Vector3(-b_offset, b_h * 0.5, -b_offset), Vector3(b_size, b_h, b_size), curb_col)
	add_box(st, Vector3( b_offset, b_h * 0.5, -b_offset), Vector3(b_size, b_h, b_size), curb_col)
	add_box(st, Vector3(-b_offset, b_h * 0.5,  b_offset), Vector3(b_size, b_h, b_size), curb_col)
	add_box(st, Vector3( b_offset, b_h * 0.5,  b_offset), Vector3(b_size, b_h, b_size), curb_col)

	# Markaziy park maydoni (Central public square)
	add_box(st, Vector3(0, 0.22, 0), Vector3(1.3, 0.06, 1.3), park_col)
	add_cylinder(st, Vector3(0, 0.32, 0), 0.35, 0.26, 0.16, 12, curb_col) # Bayroq poydevori

	# Yo'l chiziqlari (Crosswalks va Lane markings)
	# Zebra chiziqlari chorrahada
	for i in 4:
		var zx := -0.35 + float(i) * 0.23
		add_box(st, Vector3(zx, 0.17, -0.75), Vector3(0.12, 0.01, 0.35), line_col)
		add_box(st, Vector3(zx, 0.17,  0.75), Vector3(0.12, 0.01, 0.35), line_col)
		add_box(st, Vector3(-0.75, 0.17, zx), Vector3(0.35, 0.01, 0.12), line_col)
		add_box(st, Vector3( 0.75, 0.17, zx), Vector3(0.35, 0.01, 0.12), line_col)

	# 2. Shahar daraxtlari (Street & park trees)
	var tree_col := Color("22c55e")
	add_tree_round(st, Vector3(-0.45, 0.24, -0.45), 0.3, 0.05, 0.22, tree_col)
	add_tree_round(st, Vector3( 0.45, 0.24, -0.45), 0.3, 0.05, 0.22, tree_col)
	add_tree_round(st, Vector3(-0.45, 0.24,  0.45), 0.3, 0.05, 0.22, tree_col)
	add_tree_round(st, Vector3( 0.45, 0.24,  0.45), 0.3, 0.05, 0.22, tree_col)
	# Trotuar daraxtlari
	add_tree_round(st, Vector3(-2.6, 0.22, 0.0), 0.35, 0.06, 0.25, tree_col)
	add_tree_round(st, Vector3( 2.6, 0.22, 0.0), 0.35, 0.06, 0.25, tree_col)

	# 3. Binolar to'plami (Mixed-rise Town Buildings)
	var b_red := Color("b91c1c")
	var b_tan := Color("d97706")
	var b_blue := Color("0284c7")
	var b_cream := Color("fef3c7")
	var b_brown := Color("78350f")
	var roof_gray := Color("475569")
	var awning_red := Color("ef4444")
	var awning_wht := Color("ffffff")
	var awning_org := Color("f97316")

	# --- BLOK 1: Yuqori-Chap (Top-Left) ---
	# Moviy zamonaviy ma'muriyat binosi va Soat minorasi (Blue civic building & Clock tower)
	var b1_pos := Vector3(-1.8, 1.25, -2.0)
	add_box(st, b1_pos, Vector3(1.1, 2.1, 0.95), b_blue)
	add_box(st, b1_pos + Vector3(0, 1.08, 0), Vector3(1.15, 0.08, 1.0), roof_gray)
	# Fasad oynalari
	for f in 3:
		var fy := b1_pos.y - 0.5 + float(f) * 0.55
		add_box(st, Vector3(b1_pos.x, fy, b1_pos.z + 0.49), Vector3(0.85, 0.25, 0.02), Color("bae6fd"))
	# Soat minorasi (Town Hall Clock Tower - 4.5u balandlik)
	var tower_pos := Vector3(-1.8, 2.6, -2.0)
	add_box(st, tower_pos, Vector3(0.65, 1.8, 0.65), b_blue.darkened(0.12))
	add_pyramid(st, tower_pos + Vector3(0, 1.3, 0), Vector3(0.85, 0.9, 0.85), Color("0d9488"))
	add_box(st, tower_pos + Vector3(0, 0.45, 0.33), Vector3(0.28, 0.28, 0.03), Color("fef08a")) # Soat siferblati

	# Qo'shni kottej binosi
	var b2_pos := Vector3(-2.0, 0.85, -1.1)
	add_box(st, b2_pos, Vector3(0.8, 1.3, 0.75), b_cream)
	add_gable_roof(st, b2_pos, Vector3(0.9, 0.15, 0.85), 0.35, Color("ea580c"), true)

	# --- BLOK 2: Yuqori-O'ng (Top-Right) ---
	# Qizil g'ishtli 4-qavatli turar joy (Red brick apartment)
	var b3_pos := Vector3(1.9, 1.45, -1.8)
	add_box(st, b3_pos, Vector3(1.0, 2.5, 0.95), b_red)
	add_box(st, b3_pos + Vector3(0, 1.28, 0), Vector3(1.06, 0.1, 1.01), roof_gray)
	# Tomdagi ventilyatsiya / uskuna
	add_box(st, b3_pos + Vector3(0.15, 1.45, 0.1), Vector3(0.3, 0.25, 0.3), Color("64748b"))
	# Oynalar qatori
	for f in 4:
		var fy := b3_pos.y - 0.8 + float(f) * 0.52
		add_box(st, Vector3(b3_pos.x, fy, b3_pos.z + 0.49), Vector3(0.75, 0.22, 0.02), Color("fef08a"))

	# Do'kon binosi (Shop with striped awning)
	var b4_pos := Vector3(1.4, 0.95, -1.0)
	add_box(st, b4_pos, Vector3(0.9, 1.5, 0.75), b_tan)
	add_striped_awning(st, b4_pos + Vector3(0, -0.2, 0.42), Vector3(0.8, 0.22, 0.28), awning_red, awning_wht, 5)

	# --- BLOK 3: Pastki-Chap (Bottom-Left) ---
	# Qahvaxona / Kafe (Cafe with orange awning)
	var b5_pos := Vector3(-1.4, 0.85, 1.3)
	add_box(st, b5_pos, Vector3(0.95, 1.3, 0.8), b_cream)
	add_striped_awning(st, b5_pos + Vector3(0, -0.15, 0.44), Vector3(0.85, 0.22, 0.26), awning_org, awning_wht, 5)

	# Jigarrang mansard tomli bino
	var b6_pos := Vector3(-2.0, 1.25, 1.9)
	add_box(st, b6_pos, Vector3(0.95, 2.1, 0.9), b_brown)
	add_box(st, b6_pos + Vector3(0, 1.1, 0), Vector3(1.0, 0.12, 0.95), Color("334155"))

	# --- BLOK 4: Pastki-O'ng (Bottom-Right) ---
	# Zamonaviy ofis binosi (Modern commercial block)
	var b7_pos := Vector3(1.8, 1.15, 1.5)
	add_box(st, b7_pos, Vector3(1.2, 1.9, 1.1), Color("0369a1"))
	add_box(st, b7_pos + Vector3(0, 0.98, 0), Vector3(1.25, 0.08, 1.15), roof_gray)
	add_box(st, b7_pos + Vector3(0.2, 1.15, -0.2), Vector3(0.35, 0.25, 0.35), Color("94a3b8"))
	# Vitrina oynasi
	add_box(st, b7_pos + Vector3(0, -0.5, 0.57), Vector3(0.95, 0.5, 0.02), Color("38bdf8"))

	# 4. Kichik avtomobillar (Miniature cars on streets)
	add_car(st, Vector3(0.4, 0.22, -1.8), Vector3(0.28, 0.22, 0.55), Color("eab308"), 0.0) # Sariq taksi
	add_car(st, Vector3(-0.4, 0.22, 1.8), Vector3(0.28, 0.22, 0.55), Color("ef4444"), PI) # Qizil sedan
	add_car(st, Vector3(1.8, 0.22, 0.4), Vector3(0.55, 0.22, 0.28), Color("3b82f6"), PI * 0.5) # Moviy xetchbek

	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, get_material())
	return m

# ==============================================================================
# 3. KATTA SHAHAR MODELI (LARGE METROPOLIS) — media_1792231878469_d7169169.png
# ==============================================================================

static func build_large_city_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 1. Metropol poydevori (Urban Podium base) - 8.0 x 8.0
	var pod_col := Color("1e293b") # To'q metall / granit
	var pave_col := Color("475569") # Asfalt
	var curb_col := Color("94a3b8") # Beton
	var water_col := Color("0284c7") # Moviy kanal suvi
	var lawn_col := Color("4d7c0f") # Bog' maysasi

	# Asosiy poydevor
	add_box(st, Vector3(0, 0.12, 0), Vector3(8.0, 0.24, 8.0), pod_col)
	add_box(st, Vector3(0, 0.26, 0), Vector3(7.8, 0.06, 7.8), pave_col)

	# Suv kanali / Marina (Water canal corner)
	var water_pos := Vector3(2.5, 0.26, 2.5)
	add_box(st, water_pos, Vector3(2.6, 0.06, 2.6), water_col)
	# Kichik yaxta / kater (Boat)
	add_box(st, water_pos + Vector3(0.4, 0.10, 0.3), Vector3(0.55, 0.14, 0.28), Color("f8fafc"))
	add_box(st, water_pos + Vector3(0.4, 0.20, 0.3), Vector3(0.28, 0.12, 0.20), Color("38bdf8"))

	# Yashil park zonasi (Avenue Park buffer)
	var park_pos := Vector3(-2.2, 0.30, 2.2)
	add_box(st, park_pos, Vector3(2.8, 0.04, 2.8), lawn_col)
	# Konusli teraklar qatori
	for tx in 3:
		for tz in 3:
			var px := park_pos.x - 0.9 + float(tx) * 0.9
			var pz := park_pos.z - 0.9 + float(tz) * 0.9
			add_cone(st, Vector3(px, 0.32, pz), 0.28, 0.95, 7, Color("15803d"))

	# 2. Skyscraper 1: Supertall zamonaviy shisha minora (Glass Supertall with Helipad)
	var s1_pos := Vector3(-1.2, 3.5, -1.2)
	var s1_h := 6.6
	add_box(st, Vector3(s1_pos.x, s1_h * 0.5 + 0.3, s1_pos.z), Vector3(1.5, s1_h, 1.5), Color("0f172a"))
	# Vertikal ustunlar (Mullions)
	add_box(st, Vector3(s1_pos.x - 0.72, s1_h * 0.5 + 0.3, s1_pos.z - 0.72), Vector3(0.12, s1_h, 0.12), Color("cbd5e1"))
	add_box(st, Vector3(s1_pos.x + 0.72, s1_h * 0.5 + 0.3, s1_pos.z - 0.72), Vector3(0.12, s1_h, 0.12), Color("cbd5e1"))
	add_box(st, Vector3(s1_pos.x - 0.72, s1_h * 0.5 + 0.3, s1_pos.z + 0.72), Vector3(0.12, s1_h, 0.12), Color("cbd5e1"))
	add_box(st, Vector3(s1_pos.x + 0.72, s1_h * 0.5 + 0.3, s1_pos.z + 0.72), Vector3(0.12, s1_h, 0.12), Color("cbd5e1"))
	# Oynali fasad chiziqlari
	for l in 8:
		var ly := 1.0 + float(l) * 0.7
		add_box(st, Vector3(s1_pos.x, ly, s1_pos.z + 0.76), Vector3(1.3, 0.18, 0.02), Color("38bdf8"))
	# Tomdagi vertolyot maydonchasi (Helipad)
	var heli_y := s1_h + 0.32
	add_cylinder(st, Vector3(s1_pos.x, heli_y, s1_pos.z), 0.65, 0.65, 0.05, 14, Color("334155"))
	# "H" belgisi (Sariq)
	add_box(st, Vector3(s1_pos.x - 0.18, heli_y + 0.04, s1_pos.z), Vector3(0.08, 0.02, 0.36), Color("facc15"))
	add_box(st, Vector3(s1_pos.x + 0.18, heli_y + 0.04, s1_pos.z), Vector3(0.08, 0.02, 0.36), Color("facc15"))
	add_box(st, Vector3(s1_pos.x, heli_y + 0.04, s1_pos.z), Vector3(0.28, 0.02, 0.08), Color("facc15"))

	# 3. Skyscraper 2: Monumental Katta Arka Minora (Grand Gateway Arch Tower)
	var s2_pos := Vector3(1.3, 2.9, -1.3)
	var s2_h := 5.4
	# 2 ta baquvvat ustun va ustidagi portal ko'prigi
	add_box(st, Vector3(s2_pos.x - 0.65, s2_h * 0.5 + 0.3, s2_pos.z), Vector3(0.65, s2_h, 1.2), Color("f8fafc"))
	add_box(st, Vector3(s2_pos.x + 0.65, s2_h * 0.5 + 0.3, s2_pos.z), Vector3(0.65, s2_h, 1.2), Color("f8fafc"))
	# Yuqorigi ko'prik (Bridge)
	add_box(st, Vector3(s2_pos.x, s2_h - 0.2, s2_pos.z), Vector3(1.95, 1.1, 1.25), Color("0d9488")) # Feruza / Mis toj

	# 4. Skyscraper 3: Art Deco Zinali Shpil Minora (Empire State / Chrysler style)
	var s3_pos := Vector3(2.5, 2.5, 0.2)
	# 1-zina
	add_box(st, Vector3(s3_pos.x, 1.3, s3_pos.z), Vector3(1.4, 2.0, 1.4), Color("475569"))
	# 2-zina
	add_box(st, Vector3(s3_pos.x, 2.8, s3_pos.z), Vector3(1.05, 1.6, 1.05), Color("64748b"))
	# 3-zina
	add_box(st, Vector3(s3_pos.x, 3.9, s3_pos.z), Vector3(0.75, 1.0, 0.75), Color("94a3b8"))
	# Cho'qqidagi piramida shpil
	add_pyramid(st, Vector3(s3_pos.x, 4.9, s3_pos.z), Vector3(0.85, 1.2, 0.85), Color("0d9488"))
	add_cylinder(st, Vector3(s3_pos.x, 5.7, s3_pos.z), 0.05, 0.01, 0.5, 6, Color("e2e8f0"))

	# 5. Skyscraper 4: Moviy Vitrinali Tijorat Majmuasi (Azure Commercial Tower)
	var s4_pos := Vector3(-2.6, 2.0, -1.2)
	add_box(st, Vector3(s4_pos.x, 2.0, s4_pos.z), Vector3(1.2, 3.5, 1.3), Color("0284c7"))
	add_box(st, Vector3(s4_pos.x, 3.8, s4_pos.z), Vector3(1.25, 0.1, 1.35), Color("f8fafc"))

	# 6. Mehmonxona va Reklama Belgilari (Hotel & Neon signs)
	var s5_pos := Vector3(-1.3, 1.5, 0.6)
	add_box(st, Vector3(s5_pos.x, 1.4, s5_pos.z), Vector3(1.1, 2.3, 1.1), Color("831843"))
	# "PIZZA" yoki Neon yozuv kartoshi
	add_box(st, Vector3(s5_pos.x + 0.58, 1.8, s5_pos.z), Vector3(0.04, 0.8, 0.35), Color("f43f5e"))

	# 7. Katta maydon va Bayroq Shtokkasi poydevori (Grand Civic Plaza)
	var plaza_pos := Vector3(0.2, 0.30, 0.2)
	add_cylinder(st, plaza_pos, 0.65, 0.55, 0.22, 14, Color("cbd5e1"))

	# 8. Katta xiyobon transporti (Avenue cars)
	add_car(st, Vector3(0.0, 0.28, 2.0), Vector3(0.32, 0.24, 0.65), Color("facc15"), PI * 0.5)
	add_car(st, Vector3(-0.8, 0.28, 2.0), Vector3(0.32, 0.24, 0.65), Color("ef4444"), PI * 0.5)
	add_car(st, Vector3(0.0, 0.28, -2.8), Vector3(0.65, 0.24, 0.32), Color("3b82f6"), 0.0)

	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, get_material())
	return m

# ==============================================================================
# 4. REGIONAL LANDMARK MESHES (Iconic Cities Architecture)
# ==============================================================================

## Fransiya / Parij — Eyfel minorasi ilhomlangan panjarali minora
static func build_landmark_paris() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var iron_col := Color("78716c") # Bronza-kulrang po'lat
	var gold_col := Color("fbbf24")

	# 4 oyoqli arka asosi (Tapering 4-leg base)
	var foot := 0.7
	add_box(st, Vector3(-foot, 0.6, -foot), Vector3(0.26, 1.2, 0.26), iron_col)
	add_box(st, Vector3( foot, 0.6, -foot), Vector3(0.26, 1.2, 0.26), iron_col)
	add_box(st, Vector3(-foot, 0.6,  foot), Vector3(0.26, 1.2, 0.26), iron_col)
	add_box(st, Vector3( foot, 0.6,  foot), Vector3(0.26, 1.2, 0.26), iron_col)

	# 1-platforma
	add_box(st, Vector3(0, 1.25, 0), Vector3(1.65, 0.15, 1.65), iron_col.lightened(0.08))

	# 2-qavat (O'rta qism)
	add_box(st, Vector3(0, 2.05, 0), Vector3(1.0, 1.5, 1.0), iron_col)
	# 2-platforma
	add_box(st, Vector3(0, 2.85, 0), Vector3(1.15, 0.12, 1.15), iron_col.lightened(0.08))

	# Yuqori nayza shpili (Spire)
	add_pyramid(st, Vector3(0, 3.85, 0), Vector3(0.65, 1.9, 0.65), iron_col)
	add_cylinder(st, Vector3(0, 5.0, 0), 0.06, 0.01, 0.6, 6, gold_col)

	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, get_material())
	return m

## O'zbekiston / Toshkent & Samarqand — Registon uslubidagi moviy gumbaz va minora
static func build_landmark_uzbek() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sand_col := Color("d4a373") # Pishiq g'ishtli peshtoq
	var dome_col := Color("06b6d4") # Feruza moviy gumbaz
	var tile_col := Color("0284c7") # Samarqand moviysi
	var gold_col := Color("fbbf24") # Oltin yarim oy

	# Peshtoq / Eyvon (Grand Iwan Arch)
	add_box(st, Vector3(0, 1.2, 0), Vector3(2.2, 2.4, 0.8), sand_col)
	# Arka teshigi
	add_box(st, Vector3(0, 0.8, 0.1), Vector3(1.1, 1.6, 0.82), Color("1e293b"))
	# Feruza koshinli naqsh hoshiyasi
	add_box(st, Vector3(0, 2.3, 0.1), Vector3(2.1, 0.22, 0.82), tile_col)

	# Orqasidagi moviy gumbaz (Ribbed Turquoise Dome)
	add_cylinder(st, Vector3(0, 2.4, -0.6), 0.9, 0.9, 0.8, 14, tile_col)
	add_cylinder(st, Vector3(0, 3.1, -0.6), 0.95, 0.65, 0.7, 14, dome_col)
	add_pyramid(st, Vector3(0, 3.7, -0.6), Vector3(0.75, 0.6, 0.75), dome_col.lightened(0.08))
	add_cylinder(st, Vector3(0, 4.15, -0.6), 0.06, 0.01, 0.35, 6, gold_col)

	# Yon minora (Slender Minaret with balcony)
	var m_x := 1.4
	add_cylinder(st, Vector3(m_x, 1.7, 0), 0.32, 0.24, 3.4, 10, sand_col)
	# Minora koshin belbog'i
	add_cylinder(st, Vector3(m_x, 2.2, 0), 0.29, 0.28, 0.35, 10, tile_col)
	# Minora maydonchasi (Muqarnas balcony)
	add_cylinder(st, Vector3(m_x, 3.45, 0), 0.36, 0.36, 0.12, 10, sand_col.lightened(0.08))
	# Minora gumbazchasi
	add_cone(st, Vector3(m_x, 3.55, 0), 0.30, 0.55, 10, dome_col)
	add_cylinder(st, Vector3(m_x, 4.2, 0), 0.04, 0.01, 0.25, 6, gold_col)

	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, get_material())
	return m

## Italiya / Rim — Kolizey uslubidagi doiraviy arkali amfiteatr
static func build_landmark_rome() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stone_col := Color("e2d9c8") # Travertin oq-sariq tosh
	var dark_col := Color("78716c")

	# Tashqi doira 1-qavat
	add_cylinder(st, Vector3(0, 0.6, 0), 1.8, 1.75, 1.2, 16, stone_col)
	# Tashqi doira 2-qavat
	add_cylinder(st, Vector3(0, 1.6, 0), 1.7, 1.65, 0.9, 16, stone_col.lightened(0.04))
	# Ichki arena (hollow arena pit)
	add_cylinder(st, Vector3(0, 1.2, 0), 1.15, 1.15, 1.8, 14, dark_col)
	add_cylinder(st, Vector3(0, 0.4, 0), 1.05, 1.05, 0.1, 14, Color("d4a373"))

	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, get_material())
	return m

## Yaponiya / Tokio & Kioto — Ko'p pog'onali egri tomli Pagoda
static func build_landmark_japan() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var red_col := Color("dc2626") # Yapon to'q qizil ustunlari
	var roof_col := Color("1e293b") # Qora qavariq koshin
	var gold_col := Color("fbbf24")

	# 3 qavatli Pagoda
	for tier in 3:
		var y := 0.5 + float(tier) * 0.9
		var w := 1.2 - float(tier) * 0.22
		# Yog'och bino korpusi
		add_box(st, Vector3(0, y, 0), Vector3(w, 0.8, w), red_col)
		# Keng qavariq tom (Flared eaves roof)
		add_box(st, Vector3(0, y + 0.42, 0), Vector3(w + 0.7, 0.14, w + 0.7), roof_col)

	# Tepasidagi oltin shpil
	add_cylinder(st, Vector3(0, 3.4, 0), 0.08, 0.02, 0.9, 6, gold_col)

	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, get_material())
	return m

## Misr / Qohira — Oltin Ohaktosh Piramidasi
static func build_landmark_egypt() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gold_stone := Color("d97706") # Oltin qumtosh
	add_pyramid(st, Vector3(0, 1.3, 0), Vector3(2.8, 2.6, 2.8), gold_stone)
	# Cho'qqi (Pyramidion)
	add_pyramid(st, Vector3(0, 2.45, 0), Vector3(0.65, 0.65, 0.65), Color("fde047"))

	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, get_material())
	return m
