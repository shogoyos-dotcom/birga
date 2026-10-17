class_name DesignDrawers
extends RefCounted

## Color Land 3D dizayn namunasidagi (Color Land 3D_Мир игры.png)
## 2D va 3D vizual elementlarni chizuvchi yordamchi to'plam.

# ——— 1. Multfilm Slime Qahramonlari (Screen 4 & Avatarlar) ———

class SlimeHeroControl extends Control:
	var skin_id: String = "default"
	var selected: bool = false
	var hero_name: String = ""

	func _init(p_id: String, p_name: String = "", p_selected: bool = false) -> void:
		skin_id = p_id
		hero_name = p_name
		selected = p_selected
		custom_minimum_size = Vector2(96, 114)
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _draw() -> void:
		var center := Vector2(size.x * 0.5, 46.0)
		var r := 38.0

		# 3D taglik soyasi
		draw_circle(center + Vector2(0, 5), r + 2.0, Color(0.04, 0.08, 0.20, 0.35))

		# Tashqi qalin kontur
		draw_circle(center, r + 3.0, UiKit.INK)

		# Asosiy shar tanasi va teksturasi
		_draw_slime_body(center, r)

		# Multfilm ko'zlari va yuzi
		_draw_slime_face(center, r)

		# Tanlanganlik belgisi (yashil checkmark)
		if selected:
			var badge_center := center + Vector2(r * 0.7, r * 0.7)
			draw_circle(badge_center, 12.0, UiKit.INK)
			draw_circle(badge_center, 10.0, UiKit.GREEN)
			# Oq checkmark belgi
			var pts := PackedVector2Array([
				badge_center + Vector2(-4, 0),
				badge_center + Vector2(-1, 4),
				badge_center + Vector2(5, -4)
			])
			draw_polyline(pts, Color.WHITE, 2.5)

		# Qahramon nomi
		if not hero_name.is_empty():
			var font := UiKit.display_font()
			if font != null:
				draw_string(font, Vector2(0, size.y - 4), hero_name, HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Color.WHITE)

	func _draw_slime_body(c: Vector2, r: float) -> void:
		match skin_id:
			"default":
				# Yorqin zangori / ko'k multfilm sferi
				draw_circle(c, r, Color("00a2ff"))
				draw_circle(c + Vector2(-r * 0.32, -r * 0.32), r * 0.40, Color(1, 1, 1, 0.45))
				draw_circle(c + Vector2(-r * 0.36, -r * 0.36), r * 0.18, Color(1, 1, 1, 0.85))
			"red":
				# Olovli qizil sfer
				draw_circle(c, r, Color("ff3b5c"))
				draw_circle(c + Vector2(-r * 0.32, -r * 0.32), r * 0.38, Color(1, 1, 1, 0.40))
				draw_circle(c + Vector2(-r * 0.36, -r * 0.36), r * 0.18, Color(1, 1, 1, 0.85))
			"yellow":
				# Quvnoq sariq sfer
				draw_circle(c, r, Color("ffcc00"))
				draw_circle(c + Vector2(-r * 0.32, -r * 0.32), r * 0.40, Color(1, 1, 1, 0.45))
				draw_circle(c + Vector2(-r * 0.36, -r * 0.36), r * 0.18, Color(1, 1, 1, 0.85))
			"melon":
				# Yashil yo'l-yo'l tarvuz (aylana ichida qat'iy chegaralangan)
				draw_circle(c, r, Color("22c55e"))
				for dx: float in [-22.0, -11.0, 0.0, 11.0, 22.0]:
					var half_h: float = sqrt(maxf(0.0, r * r - dx * dx)) * 0.94
					draw_line(c + Vector2(dx, -half_h), c + Vector2(dx, half_h), Color("15803d"), 4.5)
				draw_circle(c + Vector2(-r * 0.32, -r * 0.32), r * 0.35, Color(1, 1, 1, 0.40))
				draw_circle(c + Vector2(-r * 0.36, -r * 0.36), r * 0.16, Color(1, 1, 1, 0.85))
			"galaxy":
				# To'q binafsha kosmik galaktika
				draw_circle(c, r, Color("7c3aed"))
				draw_circle(c + Vector2(4, 4), r * 0.65, Color("ec4899"))
				draw_circle(c + Vector2(-6, -6), r * 0.50, Color("38bdf8"))
				# Mayda yulduzchalar
				draw_circle(c + Vector2(-12, 10), 2.0, Color.WHITE)
				draw_circle(c + Vector2(14, -12), 2.5, Color.WHITE)
				draw_circle(c + Vector2(10, 16), 1.8, Color.WHITE)
			"ice":
				# Muz kristall sferi
				draw_circle(c, r, Color("38bdf8"))
				draw_circle(c, r * 0.75, Color("7dd3fc"))
				var pts1 := PackedVector2Array([c + Vector2(-15, -15), c + Vector2(0, -25), c + Vector2(15, -10)])
				draw_polyline(pts1, Color(1, 1, 1, 0.7), 2.0)
				draw_circle(c + Vector2(-r * 0.32, -r * 0.32), r * 0.25, Color(1, 1, 1, 0.90))
			"lava":
				# Magma / lava qora va olovli yoriqlar
				draw_circle(c, r, Color("262626"))
				draw_circle(c + Vector2(0, 4), r * 0.7, Color("ea580c"))
				draw_circle(c + Vector2(0, 2), r * 0.4, Color("facc15"))
				draw_circle(c + Vector2(-10, -12), 8.0, Color("171717"))
				draw_circle(c + Vector2(12, 10), 9.0, Color("171717"))
			"football":
				# Klassik charm futbol to'pi
				draw_circle(c, r, Color("f8fafc"))
				draw_circle(c, 10.0, Color("0f172a"))
				draw_circle(c + Vector2(-18, -14), 7.0, Color("0f172a"))
				draw_circle(c + Vector2(18, -14), 7.0, Color("0f172a"))
				draw_circle(c + Vector2(-16, 16), 7.0, Color("0f172a"))
				draw_circle(c + Vector2(16, 16), 7.0, Color("0f172a"))
			_:
				draw_circle(c, r, Color("00a2ff"))
				draw_circle(c + Vector2(-r * 0.32, -r * 0.32), r * 0.35, Color(1, 1, 1, 0.40))

	func _draw_slime_face(c: Vector2, r: float) -> void:
		match skin_id:
			"red":
				# Qoshlari chimirilgan jangovar ko'zlar
				var le := c + Vector2(-r * 0.30, -2)
				var re := c + Vector2(r * 0.30, -2)
				draw_circle(le, 7.5, Color.WHITE)
				draw_circle(le + Vector2(1, 1), 4.5, Color.BLACK)
				draw_circle(re, 7.5, Color.WHITE)
				draw_circle(re + Vector2(-1, 1), 4.5, Color.BLACK)
				draw_line(le + Vector2(-8, -8), le + Vector2(8, -2), UiKit.INK, 3.5)
				draw_line(re + Vector2(-8, -2), re + Vector2(8, -8), UiKit.INK, 3.5)
				draw_line(c + Vector2(-7, 10), c + Vector2(7, 10), UiKit.INK, 3.0)
			"yellow":
				# Bir ko'zi qisilgan quvnoq tabassum
				var le := c + Vector2(-r * 0.30, -2)
				var re := c + Vector2(r * 0.30, -2)
				draw_circle(le, 8.0, Color.WHITE)
				draw_circle(le + Vector2(1, 0), 4.8, Color.BLACK)
				draw_circle(le + Vector2(2, -2), 2.2, Color.WHITE)
				draw_circle(c + Vector2(-r * 0.40, 7), 5.0, Color(1.0, 0.4, 0.4, 0.45))
				draw_circle(c + Vector2(r * 0.40, 7), 5.0, Color(1.0, 0.4, 0.4, 0.45))
				draw_arc(re, 6.5, PI * 0.8, PI * 1.8, 10, UiKit.INK, 3.2)
				draw_arc(c + Vector2(0, 9), 8.5, 0.2, PI - 0.2, 12, UiKit.INK, 3.0)
			"football", "lava":
				pass
			_:
				# Katta yoqimli multfilm ko'zlari, yaltirash va pushti yanoqlar
				var le := c + Vector2(-r * 0.30, -2)
				var re := c + Vector2(r * 0.30, -2)
				draw_circle(le, 8.5, Color.WHITE)
				draw_circle(le + Vector2(1, 0), 5.2, Color.BLACK)
				draw_circle(le + Vector2(2.5, -2.5), 2.5, Color.WHITE)
				draw_circle(le + Vector2(-2.0, 2.0), 1.2, Color.WHITE)

				draw_circle(re, 8.5, Color.WHITE)
				draw_circle(re + Vector2(-1, 0), 5.2, Color.BLACK)
				draw_circle(re + Vector2(1.5, -2.5), 2.5, Color.WHITE)
				draw_circle(re + Vector2(-2.5, 2.0), 1.2, Color.WHITE)

				# Pushti yanoqlar (blush)
				draw_circle(c + Vector2(-r * 0.42, 7), 5.5, Color(1.0, 0.4, 0.6, 0.5))
				draw_circle(c + Vector2(r * 0.42, 7), 5.5, Color(1.0, 0.4, 0.6, 0.5))

				# Kichik quvnoq og'izcha
				draw_arc(c + Vector2(0, 9), 7.5, 0.25, PI - 0.25, 12, UiKit.INK, 3.0)

# ——— 2. 3D Bayroq Pedestallari (Screen 4: Flag Themes) ———

class FlagPedestalControl extends Control:
	var code: String = "crown"
	var flag_name: String = "Default"

	func _init(p_code: String, p_name: String) -> void:
		code = p_code
		flag_name = p_name
		custom_minimum_size = Vector2(80, 78)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# 3D taglik poydevori (dumaloq / ko'p qirrali oltin asos)
		var base_y := h - 22.0
		# Qoramtir taglik soyasi
		draw_rect(Rect2(Vector2(w * 0.16, base_y + 4.0), Vector2(w * 0.68, 6.0)), Color("78350f"))
		# Oltin qavatli taglik
		draw_rect(Rect2(Vector2(w * 0.14, base_y), Vector2(w * 0.72, 5.0)), Color("b45309"))
		draw_rect(Rect2(Vector2(w * 0.18, base_y - 3.0), Vector2(w * 0.64, 4.0)), Color("facc15"))

		if code == "crown":
			# Moviy baxmal yostiqcha
			draw_circle(Vector2(w * 0.5, base_y - 6.0), 12.0, Color("1e3a8a"))
			# Oltin toj
			var crown_c := Vector2(w * 0.5, base_y - 18.0)
			var shape := PackedVector2Array([
				crown_c + Vector2(-15, 8), crown_c + Vector2(-15, -6),
				crown_c + Vector2(-7, 0), crown_c + Vector2(0, -14),
				crown_c + Vector2(7, 0), crown_c + Vector2(15, -6),
				crown_c + Vector2(15, 8)
			])
			draw_colored_polygon(shape, Color("facc15"))
			draw_polyline(shape, UiKit.INK, 2.0)
			# Tojdagi qimmatbaho toshlar
			draw_circle(crown_c + Vector2(-15, -6), 2.5, Color("ef4444"))
			draw_circle(crown_c + Vector2(0, -14), 3.0, Color("38bdf8"))
			draw_circle(crown_c + Vector2(15, -6), 2.5, Color("ef4444"))
		else:
			# Oltin bayroq ustuni
			var pole_x := w * 0.28
			draw_line(Vector2(pole_x, base_y - 2.0), Vector2(pole_x, 8.0), Color("92400e"), 3.5)
			draw_circle(Vector2(pole_x, 7.0), 3.0, Color("facc15"))
			# Bayroq matosi
			var flag_rect := Rect2(Vector2(pole_x + 2.0, 10.0), Vector2(34.0, 22.0))
			_draw_flag_cloth(flag_rect, code)

		# Nomi
		var font := UiKit.display_font()
		if font != null:
			draw_string(font, Vector2(0, h - 3), flag_name, HORIZONTAL_ALIGNMENT_CENTER, w, 11, Color.WHITE)

	func _draw_flag_cloth(rect: Rect2, c_code: String) -> void:
		var tex := FlagRenderer.get_flag_texture(c_code)
		if tex != null:
			draw_texture_rect(tex, rect, false)
			draw_rect(rect, UiKit.INK, false, 1.5)
			return
		draw_rect(rect, Color.WHITE)
		match c_code.to_upper():
			"US":
				for i in 6:
					var y_col := Color("b22234") if i % 2 == 0 else Color.WHITE
					draw_rect(Rect2(rect.position + Vector2(0, i * 3.6), Vector2(rect.size.x, 3.6)), y_col)
				draw_rect(Rect2(rect.position, Vector2(rect.size.x * 0.45, 11.0)), Color("1e3a8a"))
			"FR":
				var sw := rect.size.x / 3.0
				draw_rect(Rect2(rect.position, Vector2(sw, rect.size.y)), Color("002395"))
				draw_rect(Rect2(rect.position + Vector2(sw, 0), Vector2(sw, rect.size.y)), Color.WHITE)
				draw_rect(Rect2(rect.position + Vector2(sw * 2, 0), Vector2(sw, rect.size.y)), Color("ed2939"))
			"JP":
				draw_rect(rect, Color.WHITE)
				draw_circle(rect.get_center(), 6.5, Color("bc002d"))
			"DE":
				var sh := rect.size.y / 3.0
				draw_rect(Rect2(rect.position, Vector2(rect.size.x, sh)), Color("111111"))
				draw_rect(Rect2(rect.position + Vector2(0, sh), Vector2(rect.size.x, sh)), Color("dd0000"))
				draw_rect(Rect2(rect.position + Vector2(0, sh * 2), Vector2(rect.size.x, sh)), Color("ffce00"))
			_:
				draw_rect(rect, Color("0284c7"))
		draw_rect(rect, UiKit.INK, false, 1.5)

# ——— 3. 3D Xarita Kartochkasi Miniaturasi (Screen 3) ———

class MapThumbnailControl extends Control:
	var map_id: String = "world"

	func _init(p_id: String) -> void:
		map_id = p_id
		custom_minimum_size = Vector2(190, 80)
		clip_contents = true

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		match map_id:
			"featured_promo":
				# Asosiy menyu World Expedition bannari: tropik orollar, qal'a va bayroqlar
				draw_rect(rect, Color("0284c7"))
				# Moviy okean va to'lqinlar
				draw_rect(Rect2(0, size.y * 0.5, size.x, size.y * 0.5), Color("0369a1"))
				# Yashil tropik orolcha
				draw_circle(Vector2(size.x * 0.5, size.y * 0.8), 38.0, Color("4ade80"))
				draw_circle(Vector2(size.x * 0.5, size.y * 0.75), 32.0, Color("22c55e"))
				# Orol ustidagi kichik Eyfel minorasi va Qal'a silueti
				var tw := PackedVector2Array([
					Vector2(size.x * 0.45, size.y * 0.65), Vector2(size.x * 0.5, size.y * 0.25),
					Vector2(size.x * 0.55, size.y * 0.65)
				])
				draw_colored_polygon(tw, Color("b45309"))
				# Mini bayroqlar
				draw_rect(Rect2(Vector2(size.x * 0.32, size.y * 0.35), Vector2(12, 8)), Color("002395"))
				draw_rect(Rect2(Vector2(size.x * 0.62, size.y * 0.35), Vector2(12, 8)), Color("b22234"))
				# Bulutlar
				draw_circle(Vector2(size.x * 0.2, size.y * 0.25), 10.0, Color(1, 1, 1, 0.8))
				draw_circle(Vector2(size.x * 0.8, size.y * 0.3), 12.0, Color(1, 1, 1, 0.8))
			"world":
				draw_rect(rect, Color("0284c7"))
				var gc := Vector2(size.x * 0.5, size.y * 0.5)
				# 3D Globus
				draw_circle(gc, 33.0, Color("0ea5e9"))
				draw_circle(gc + Vector2(-10, -8), 13.0, Color("22c55e"))
				draw_circle(gc + Vector2(10, 6), 15.0, Color("22c55e"))
				draw_circle(gc + Vector2(-6, 15), 10.0, Color("22c55e"))
				# Globus konturi va soyasi
				draw_arc(gc, 33.0, 0.0, TAU, 32, UiKit.INK, 2.0)
				# Oq bulutlar
				draw_circle(gc + Vector2(-22, -16), 8.0, Color(1, 1, 1, 0.75))
				draw_circle(gc + Vector2(24, 12), 9.0, Color(1, 1, 1, 0.75))
			"europe":
				draw_rect(rect, Color("38bdf8"))
				# Yashil adirlar
				draw_circle(Vector2(size.x * 0.25, size.y + 14), 58.0, Color("4ade80"))
				draw_circle(Vector2(size.x * 0.75, size.y + 14), 62.0, Color("22c55e"))
				# Qal'a minorasi (Castle turret)
				draw_rect(Rect2(Vector2(size.x * 0.28, size.y - 42), Vector2(18, 30)), Color("f8fafc"))
				var cone := PackedVector2Array([
					Vector2(size.x * 0.26, size.y - 42), Vector2(size.x * 0.34, size.y - 58),
					Vector2(size.x * 0.42, size.y - 42)
				])
				draw_colored_polygon(cone, Color("dc2626"))
				# Eyfel minorasi silueti
				var ec := Vector2(size.x * 0.65, size.y - 12)
				var tower := PackedVector2Array([
					ec + Vector2(-12, 10), ec + Vector2(-4, -28),
					ec + Vector2(0, -44), ec + Vector2(4, -28),
					ec + Vector2(12, 10)
				])
				draw_colored_polygon(tower, Color("b45309"))
			"asia":
				draw_rect(rect, Color("f472b6"))
				# Fudzi tog'i
				var mc := Vector2(size.x * 0.42, size.y - 12)
				var mtn := PackedVector2Array([
					mc + Vector2(-38, 12), mc + Vector2(0, -34), mc + Vector2(38, 12)
				])
				draw_colored_polygon(mtn, Color("6366f1"))
				# Tog' cho'qqisidagi oppoq qor
				var snow := PackedVector2Array([
					mc + Vector2(-13, -18), mc + Vector2(0, -34), mc + Vector2(13, -18)
				])
				draw_colored_polygon(snow, Color.WHITE)
				# Qizil pagoda ibodatxonasi
				var pc := Vector2(size.x * 0.78, size.y - 10)
				draw_rect(Rect2(pc + Vector2(-10, -28), Vector2(20, 28)), Color("dc2626"))
				draw_line(pc + Vector2(-18, -20), pc + Vector2(18, -20), Color("991b1b"), 3.5)
				draw_line(pc + Vector2(-15, -30), pc + Vector2(15, -30), Color("991b1b"), 3.5)
			"africa":
				draw_rect(rect, Color("fb923c"))
				# Cho'l sariq qumlari
				draw_circle(Vector2(size.x * 0.4, size.y + 20), 70.0, Color("fde047"))
				draw_circle(Vector2(size.x * 0.8, size.y + 20), 65.0, Color("facc15"))
				# 3D Qirrali Ehromlar (Pyramids)
				var pyr_light := PackedVector2Array([
					Vector2(35, size.y), Vector2(70, size.y - 34), Vector2(85, size.y)
				])
				draw_colored_polygon(pyr_light, Color("fde047"))
				var pyr_dark := PackedVector2Array([
					Vector2(70, size.y - 34), Vector2(110, size.y), Vector2(85, size.y)
				])
				draw_colored_polygon(pyr_dark, Color("ca8a04"))
				# Akatsiya daraxti
				var tc := Vector2(size.x * 0.78, size.y - 12)
				draw_line(tc, tc + Vector2(0, -22), Color("78350f"), 3.5)
				draw_circle(tc + Vector2(0, -24), 14.0, Color("15803d"))
			"north_america":
				draw_rect(rect, Color("60a5fa"))
				# Shahar osmono'par binolari
				var sc := Vector2(25, size.y)
				draw_rect(Rect2(sc + Vector2(0, -36), Vector2(16, 36)), Color("1e3a8a"))
				draw_rect(Rect2(sc + Vector2(18, -48), Vector2(20, 48)), Color("1d4ed8"))
				draw_rect(Rect2(sc + Vector2(40, -32), Vector2(14, 32)), Color("1e40af"))
				# Deraza yorug'liklari
				draw_rect(Rect2(sc + Vector2(24, -42), Vector2(3, 3)), Color("fde047"))
				draw_rect(Rect2(sc + Vector2(24, -34), Vector2(3, 3)), Color("fde047"))
				# Ozodlik haykali mash'ali
				var stat := Vector2(size.x * 0.78, size.y - 10)
				draw_line(stat, stat + Vector2(0, -32), Color("0d9488"), 4.0)
				draw_circle(stat + Vector2(4, -36), 5.5, Color("f59e0b"))
			"south_america":
				draw_rect(rect, Color("34d399"))
				# Tropik tog'lar
				draw_circle(Vector2(size.x * 0.35, size.y + 15), 65.0, Color("059669"))
				draw_circle(Vector2(size.x * 0.80, size.y + 15), 60.0, Color("047857"))
				# Qutqaruvchi Iso haykali (oq siluet)
				var jc := Vector2(size.x * 0.5, size.y - 12)
				draw_line(jc, jc + Vector2(0, -30), Color.WHITE, 4.5)
				draw_line(jc + Vector2(-16, -24), jc + Vector2(16, -24), Color.WHITE, 4.0)
				draw_circle(jc + Vector2(0, -33), 4.0, Color.WHITE)
			"oceania":
				# Okeaniya: moviy tropik marjon orollari va Sidney teatri silueti
				draw_rect(rect, Color("06b6d4"))
				draw_circle(Vector2(size.x * 0.45, size.y + 12), 52.0, Color("22c55e"))
				draw_circle(Vector2(size.x * 0.82, size.y + 16), 46.0, Color("16a34a"))
				var so := Vector2(size.x * 0.38, size.y - 10)
				for si in 3:
					var ox: float = so.x + si * 10.0
					var arc_poly := PackedVector2Array([
						Vector2(ox - 8, so.y), Vector2(ox, so.y - 18 - si * 3),
						Vector2(ox + 8, so.y)
					])
					draw_colored_polygon(arc_poly, Color.WHITE)
				var palm := Vector2(size.x * 0.78, size.y - 10)
				draw_line(palm, palm + Vector2(-3, -22), Color("78350f"), 3.0)
				draw_circle(palm + Vector2(-3, -24), 8.0, Color("15803d"))
			"circle":
				# Erkin aylana jang maydoni
				draw_rect(rect, Color("1e1b4b"))
				var cc := Vector2(size.x * 0.5, size.y * 0.5)
				draw_circle(cc, 34.0, Color("4338ca"))
				draw_circle(cc, 26.0, Color("6366f1"))
				draw_circle(cc, 18.0, Color("a5b4fc"))
				draw_circle(cc, 8.0, Color.WHITE)
			"small_city":
				# Shaharcha: tarixiy uychalar va qo'ng'iroq minorasi
				draw_rect(rect, Color("38bdf8"))
				draw_circle(Vector2(size.x * 0.5, size.y + 10), 45.0, Color("4ade80"))
				draw_rect(Rect2(Vector2(size.x * 0.25, size.y - 28), Vector2(18, 20)), Color("ea580c"))
				draw_rect(Rect2(Vector2(size.x * 0.55, size.y - 36), Vector2(14, 28)), Color("d97706"))
			"medium_city":
				# O'rta shahar: biznes markazi va ko'k minoralar
				draw_rect(rect, Color("1e3a8a"))
				for i in 5:
					var bx: float = 12.0 + i * 16.0
					var bh: float = 20.0 + (i % 3) * 12.0
					draw_rect(Rect2(Vector2(bx, size.y - bh), Vector2(13, bh)), Color("38bdf8"))
			"large_city", "cities":
				# Megapolis shahar: tungi chiroqlar va osmono'parlar
				draw_rect(rect, Color("0f172a"))
				for i in 6:
					var bx: float = 12.0 + i * 26.0
					var bh: float = 24.0 + (i % 3) * 14.0
					draw_rect(Rect2(Vector2(bx, size.y - bh), Vector2(19, bh)), Color("2563eb"))
					draw_rect(Rect2(Vector2(bx + 4, size.y - bh + 6), Vector2(3, 3)), Color("fde047"))
					draw_rect(Rect2(Vector2(bx + 11, size.y - bh + 6), Vector2(3, 3)), Color("fde047"))
			"ancient":
				# Qadimgi dunyo: tosh ibodatxona va lianalar
				draw_rect(rect, Color("14532d"))
				var pyr := PackedVector2Array([
					Vector2(size.x * 0.2, size.y), Vector2(size.x * 0.5, size.y - 34),
					Vector2(size.x * 0.8, size.y)
				])
				draw_colored_polygon(pyr, Color("78716c"))
			_:
				draw_rect(rect, Color("0284c7"))
				draw_circle(Vector2(size.x * 0.5, size.y * 0.5), 28.0, Color("38bdf8"))

# ——— 4. 3D O'yin Maydonidagi Obidalar (Landmarks) ———

static func build_landmark_node(kind: String, country_flag: String = "", coin_reward: int = 0) -> Node3D:
	var root := Node3D.new()

	match kind:
		"eiffel":
			# Eyfel minorasi — 4 burchak tayanch oyoqlari, kuzatuv maydoni, minora va shpil
			var dark_bronze := _make_mat(Color("78350f"))
			var gold_spire := _make_mat(Color("f59e0b"))
			for dx: float in [-0.85, 0.85]:
				for dz: float in [-0.85, 0.85]:
					var leg := BoxMesh.new()
					leg.size = Vector3(0.42, 1.3, 0.42)
					var lmi := MeshInstance3D.new()
					lmi.mesh = leg
					lmi.position = Vector3(dx, 0.65, dz)
					lmi.set_surface_override_material(0, dark_bronze)
					root.add_child(lmi)
			var plat1 := BoxMesh.new()
			plat1.size = Vector3(2.1, 0.28, 2.1)
			var p1mi := MeshInstance3D.new()
			p1mi.mesh = plat1
			p1mi.position = Vector3(0, 1.4, 0)
			p1mi.set_surface_override_material(0, dark_bronze)
			root.add_child(p1mi)

			var mid_tower := CylinderMesh.new()
			mid_tower.top_radius = 0.45
			mid_tower.bottom_radius = 0.85
			mid_tower.height = 1.6
			var mt_mi := MeshInstance3D.new()
			mt_mi.mesh = mid_tower
			mt_mi.position = Vector3(0, 2.3, 0)
			mt_mi.set_surface_override_material(0, dark_bronze)
			root.add_child(mt_mi)

			var plat2 := BoxMesh.new()
			plat2.size = Vector3(1.1, 0.22, 1.1)
			var p2mi := MeshInstance3D.new()
			p2mi.mesh = plat2
			p2mi.position = Vector3(0, 3.2, 0)
			p2mi.set_surface_override_material(0, dark_bronze)
			root.add_child(p2mi)

			var spire := CylinderMesh.new()
			spire.top_radius = 0.08
			spire.bottom_radius = 0.35
			spire.height = 2.4
			var s_mi := MeshInstance3D.new()
			s_mi.mesh = spire
			s_mi.position = Vector3(0, 4.4, 0)
			s_mi.set_surface_override_material(0, gold_spire)
			root.add_child(s_mi)

		"pagoda":
			# Osiyo pagodasi — 3 bosqichli qizil tom va zarhal shpil
			for tier in 3:
				var body := BoxMesh.new()
				var s: float = 1.8 - tier * 0.45
				body.size = Vector3(s, 0.7, s)
				var bmi := MeshInstance3D.new()
				bmi.mesh = body
				bmi.position = Vector3(0, 0.4 + tier * 1.1, 0)
				bmi.set_surface_override_material(0, _make_mat(Color("dc2626")))
				root.add_child(bmi)

				var roof := CylinderMesh.new()
				roof.top_radius = 0.1
				roof.bottom_radius = s + 0.5
				roof.height = 0.35
				var rmi := MeshInstance3D.new()
				rmi.mesh = roof
				rmi.position = Vector3(0, 0.85 + tier * 1.1, 0)
				rmi.set_surface_override_material(0, _make_mat(Color("991b1b")))
				root.add_child(rmi)

		"colosseum":
			# Qadimgi Rim Kolizeyi — oval devorlar, ichki maydon va arkalar
			var stone := _make_mat(Color("fef08a"))
			var dark_stone := _make_mat(Color("ca8a04"))
			var sand := _make_mat(Color("b45309"))
			var outer := CylinderMesh.new()
			outer.top_radius = 2.0
			outer.bottom_radius = 2.1
			outer.height = 1.4
			var o_mi := MeshInstance3D.new()
			o_mi.mesh = outer
			o_mi.position = Vector3(0, 0.7, 0)
			o_mi.set_surface_override_material(0, stone)
			root.add_child(o_mi)

			var arena_floor := CylinderMesh.new()
			arena_floor.top_radius = 1.4
			arena_floor.bottom_radius = 1.4
			arena_floor.height = 1.44
			var af_mi := MeshInstance3D.new()
			af_mi.mesh = arena_floor
			af_mi.position = Vector3(0, 0.72, 0)
			af_mi.set_surface_override_material(0, sand)
			root.add_child(af_mi)

			var top_rim := TorusMesh.new()
			top_rim.inner_radius = 1.7
			top_rim.outer_radius = 2.05
			var tr_mi := MeshInstance3D.new()
			tr_mi.mesh = top_rim
			tr_mi.position = Vector3(0, 1.42, 0)
			tr_mi.set_surface_override_material(0, dark_stone)
			root.add_child(tr_mi)

		"christ":
			# Qutqaruvchi Iso obidasi — oppoq siluet va yoyilgan qo'llar
			var ped := BoxMesh.new()
			ped.size = Vector3(1.2, 1.4, 1.2)
			var pmi := MeshInstance3D.new()
			pmi.mesh = ped
			pmi.position = Vector3(0, 0.7, 0)
			pmi.set_surface_override_material(0, _make_mat(Color("94a3b8")))
			root.add_child(pmi)

			var body := CylinderMesh.new()
			body.top_radius = 0.35
			body.bottom_radius = 0.45
			body.height = 2.2
			var bmi := MeshInstance3D.new()
			bmi.mesh = body
			bmi.position = Vector3(0, 2.5, 0)
			bmi.set_surface_override_material(0, _make_mat(Color.WHITE))
			root.add_child(bmi)

			var arms := BoxMesh.new()
			arms.size = Vector3(3.2, 0.35, 0.4)
			var ami := MeshInstance3D.new()
			ami.mesh = arms
			ami.position = Vector3(0, 3.2, 0)
			ami.set_surface_override_material(0, _make_mat(Color.WHITE))
			root.add_child(ami)

		"statue", "statue_liberty":
			# Ozodlik haykali — yashil mis haykal va oltin mash'ala
			var ped := BoxMesh.new()
			ped.size = Vector3(1.4, 1.6, 1.4)
			var pmi := MeshInstance3D.new()
			pmi.mesh = ped
			pmi.position = Vector3(0, 0.8, 0)
			pmi.set_surface_override_material(0, _make_mat(Color("64748b")))
			root.add_child(pmi)

			var statue := CylinderMesh.new()
			statue.top_radius = 0.35
			statue.bottom_radius = 0.5
			statue.height = 2.6
			var smi := MeshInstance3D.new()
			smi.mesh = statue
			smi.position = Vector3(0, 2.7, 0)
			smi.set_surface_override_material(0, _make_mat(Color("14b8a6")))
			root.add_child(smi)

			var torch := CylinderMesh.new()
			torch.top_radius = 0.15
			torch.bottom_radius = 0.05
			torch.height = 0.6
			var tmi := MeshInstance3D.new()
			tmi.mesh = torch
			tmi.position = Vector3(0.5, 4.1, 0)
			tmi.set_surface_override_material(0, _make_mat(Color("f59e0b")))
			root.add_child(tmi)

		"sailboat":
			# Okeandagi oq yelkanli qayiqcha
			var hull := BoxMesh.new()
			hull.size = Vector3(0.9, 0.4, 1.9)
			var hmi := MeshInstance3D.new()
			hmi.mesh = hull
			hmi.set_surface_override_material(0, _make_mat(Color.WHITE))
			root.add_child(hmi)

			var mast := CylinderMesh.new()
			mast.top_radius = 0.05
			mast.bottom_radius = 0.05
			mast.height = 1.8
			var mmi := MeshInstance3D.new()
			mmi.mesh = mast
			mmi.position = Vector3(0, 1.0, -0.1)
			mmi.set_surface_override_material(0, _make_mat(Color("78350f")))
			root.add_child(mmi)

			var sail := PrismMesh.new()
			sail.size = Vector3(0.04, 1.4, 1.2)
			var smi := MeshInstance3D.new()
			smi.mesh = sail
			smi.position = Vector3(0, 1.1, 0.4)
			smi.rotation_degrees = Vector3(0, 90, 0)
			smi.set_surface_override_material(0, _make_mat(Color(1, 1, 1, 0.95)))
			root.add_child(smi)
			return root

	# Bayroq ustuni va hilpirash
	if not country_flag.is_empty():
		var pole := CylinderMesh.new()
		pole.top_radius = 0.05
		pole.bottom_radius = 0.06
		pole.height = 3.8
		var pmi := MeshInstance3D.new()
		pmi.mesh = pole
		pmi.position = Vector3(1.3, 2.5, 0)
		pmi.set_surface_override_material(0, _make_mat(Color("ffd700")))
		root.add_child(pmi)

		var flag_sprite := Sprite3D.new()
		flag_sprite.texture = _flag_texture(country_flag)
		flag_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		flag_sprite.pixel_size = 0.024
		flag_sprite.position = Vector3(1.3, 4.4, 0)
		root.add_child(flag_sprite)

	# Tanga mukofoti nishoni (+500, +300, ...)
	if coin_reward > 0:
		var badge := Label3D.new()
		badge.text = "+%d" % coin_reward
		badge.font_size = 42
		badge.modulate = Color("ffd700")
		badge.outline_modulate = Color("173a75")
		badge.outline_size = 12
		badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		badge.position = Vector3(0, 5.8, 0)
		root.add_child(badge)

	return root

static func _make_mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.35
	return mat

static func _flag_texture(code: String) -> Texture2D:
	var img := Image.create(64, 44, false, Image.FORMAT_RGBA8)
	var upper := code.to_upper()
	match upper:
		"FR":
			for x in 64:
				var c := Color("002395") if x < 21 else (Color.WHITE if x < 42 else Color("ed2939"))
				for y in 44: img.set_pixel(x, y, c)
		"IT":
			for x in 64:
				var c := Color("009246") if x < 21 else (Color.WHITE if x < 42 else Color("ce2b37"))
				for y in 44: img.set_pixel(x, y, c)
		"US":
			for y in 44:
				var c := Color("b22234") if (y / 4) % 2 == 0 else Color.WHITE
				for x in 64: img.set_pixel(x, y, c)
			for x in 28:
				for y in 22: img.set_pixel(x, y, Color("3c3b6e"))
		"JP":
			img.fill(Color.WHITE)
			var center := Vector2(32, 22)
			for x in 64:
				for y in 44:
					if Vector2(x, y).distance_to(center) <= 13.0:
						img.set_pixel(x, y, Color("bc002d"))
		"BR":
			img.fill(Color("009c3b"))
			var center := Vector2(32, 22)
			for x in 64:
				for y in 44:
					var dx := absf(x - 32) / 28.0
					var dy := absf(y - 22) / 18.0
					if dx + dy <= 1.0:
						img.set_pixel(x, y, Color("ffdf00"))
					if Vector2(x, y).distance_to(center) <= 9.0:
						img.set_pixel(x, y, Color("002776"))
		"DE":
			for y in 44:
				var c := Color("111111") if y < 15 else (Color("dd0000") if y < 30 else Color("ffce00"))
				for x in 64: img.set_pixel(x, y, c)
		_:
			img.fill(Color("0284c7"))
			for x in 64:
				img.set_pixel(x, 0, Color("ffd700"))
				img.set_pixel(x, 43, Color("ffd700"))
			for y in 44:
				img.set_pixel(0, y, Color("ffd700"))
				img.set_pixel(63, y, Color("ffd700"))

	return ImageTexture.create_from_image(img)
