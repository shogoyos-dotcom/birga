extends SceneTree

const TestRunner := preload("res://tests/test_runner.gd")
const MapHelpers := preload("res://tests/map_helpers.gd")

## Headless test kiruvchi nuqtasi:
##   godot --headless --script res://tests/run_tests.gd

func _initialize() -> void:
	var t := TestRunner.new()
	_test_capture(t)
	_test_death_rules(t)
	_test_water(t)
	_test_world_map(t)
	_test_match(t)
	_test_avatar_placement(t)
	_test_continue(t)
	_test_profile(t)
	_test_trail_path(t)
	_test_country(t)
	_test_strings(t)
	_test_paint(t)
	quit(0 if t.report() else 1)

# ——— Chizish qatlami ———

func _test_paint(t: TestRunner) -> void:
	t.group("egalik teksturasi")

	t.test("belgilar panjara bilan mos keladi", func() -> void:
		var grid := MapHelpers.grid_from(PackedStringArray([
			"....",
			".11.",
			".1~.",
			"....",
		]))
		grid.set_trail(3, 0, 2)
		var colors := PackedByteArray()
		colors.resize(256)
		var paint := PaintLayer.new(grid, colors)
		paint.sync()
		t.equal(paint.index_at(0, 0), 0, "egasiz katak")
		t.equal(paint.index_at(1, 1), 1, "hudud egasi")
		t.equal(paint.index_at(3, 0), 256 + 2, "iz egasi")
	)

	t.test("o'zgargan katak teksturada yangilanadi", func() -> void:
		var grid := GameGrid.new(8, 8)
		var colors := PackedByteArray()
		colors.resize(256)
		var paint := PaintLayer.new(grid, colors)
		paint.sync()
		grid.set_owner(4, 4, 7)
		t.equal(paint.sync(), 1, "bitta katak o'zgardi")
		t.equal(paint.index_at(4, 4), 7)
	)

	t.test("rang jadvali to'liq noshaffof", func() -> void:
		var grid := GameGrid.new(4, 4)
		var colors := PackedByteArray()
		colors.resize(256)
		var paint := PaintLayer.new(grid, colors)
		t.equal(paint.palette_image.get_width(), PaintLayer.PALETTE_SIZE)
		var clear := 0
		for i in PaintLayer.PALETTE_SIZE:
			if paint.palette_image.get_pixel(i, 0).a < 1.0:
				clear += 1
		t.equal(clear, 0, "shaffof rang yo'q")
	)

# ——— Iz yo'li ———

func _test_trail_path(t: TestRunner) -> void:
	t.group("iz yo'li")

	t.test("to'g'ri qism ikki nuqtada qoladi", func() -> void:
		var p := PlayerState.new(1, "P", 0, false, 1.0, 1.0)
		for i in 40:
			p.add_path_point(10.0 + i * 0.5, 10.0)
		t.equal(p.trail_path.size(), 2, "to'g'ri chiziq soddalashtirildi")
		t.check(p.trail_path[1].is_equal_approx(Vector2(29.5, 10.0)),
			"oxirgi nuqta joyida: %s" % p.trail_path[1])
	)

	t.test("burilish nuqtasi saqlanadi", func() -> void:
		var p := PlayerState.new(1, "P", 0, false, 1.0, 1.0)
		for i in 10:
			p.add_path_point(10.0 + i * 0.5, 10.0)
		for i in 10:
			p.add_path_point(14.5, 10.0 + (i + 1) * 0.5)
		t.equal(p.trail_path.size(), 3, "boshi, burchagi va oxiri")
	)

	t.test("juda yaqin nuqta qo'shilmaydi", func() -> void:
		var p := PlayerState.new(1, "P", 0, false, 1.0, 1.0)
		p.add_path_point(5.0, 5.0)
		p.add_path_point(5.05, 5.0)
		t.equal(p.trail_path.size(), 1)
	)

	t.test("egri yo'l nuqtalari saqlanadi", func() -> void:
		var p := PlayerState.new(1, "P", 0, false, 1.0, 1.0)
		for i in 60:
			var a := i * 0.1
			p.add_path_point(20.0 + cos(a) * 8.0, 20.0 + sin(a) * 8.0)
		t.greater(p.trail_path.size(), 4, "aylana nuqtalarga bo'linadi")
	)

	t.test("o'lim yo'lni tozalaydi", func() -> void:
		var world := MapHelpers.make_world(40, 40)
		var p := MapHelpers.place_player(world, 5, 5)
		p.add_path_point(9.0, 9.0)
		world.kill(p, PlayerState.DeathCause.TRAIL_HIT, null)
		t.equal(p.trail_path.size(), 0)
	)

# ——— Davlat bayrog'i ———

func _test_country(t: TestRunner) -> void:
	t.group("davlat bayrog'i")

	t.test("noto'g'ri kod standart davlatga aylanadi", func() -> void:
		t.equal(Profile.sanitize_country("xx"), Profile.DEFAULT_COUNTRY)
		t.equal(Profile.sanitize_country(""), Profile.DEFAULT_COUNTRY)
		t.equal(Profile.sanitize_country("uz"), "UZ")
	)

	t.test("tasodifiy davlat ro'yxatdan olinadi", func() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for i in 20:
			var code := Profile.random_country(rng)
			t.equal(Profile.sanitize_country(code), code,
				"ro'yxatda bor: " + code)
	)

	t.test("botlarga avatar va bayroq beriladi", func() -> void:
		var config := GameConfig.new()
		config.bot_count = 6
		var world := MatchBuilder.create(config, 0, "Men", "emoji:\U01F98A", 3)
		var bad := 0
		for p in world.players:
			if Profile.map_glyph(p.avatar).is_empty():
				bad += 1
			if Profile.flag_emoji(p.country).is_empty():
				bad += 1
		t.equal(bad, 0, "hammasida belgi va bayroq bor")
	)

# ——— Matnlar ———

func _test_strings(t: TestRunner) -> void:
	t.group("matnlar")

	t.test("hamma tilda bir xil kalitlar bor", func() -> void:
		Strings.set_language("uz")
		var file := FileAccess.open(Strings.PATH, FileAccess.READ)
		var all: Dictionary = JSON.parse_string(file.get_as_text())
		file.close()
		var base: Array = all["uz"].keys()
		base.sort()
		for code: String in Strings.CODES:
			t.check(all.has(code), "til bor: " + code)
			var keys: Array = all[code].keys()
			keys.sort()
			t.equal(keys, base, "kalitlar mos: " + code)
	)

	t.test("uslub nomlari tarjima qilingan", func() -> void:
		for code: String in Strings.CODES:
			Strings.set_language(code)
			for id: String in Palette.ORDER:
				var name := Strings.theme_name(id)
				t.check(not name.begins_with("theme"),
					"%s / %s tarjimasi bor" % [code, id])
		Strings.set_language("uz")
	)

# ——— Hudud ustidagi avatar ———

func _test_avatar_placement(t: TestRunner) -> void:
	t.group("hududdagi avatar")

	t.test("kvadrat hududda markazga to'liq sig'adi", func() -> void:
		var grid := GameGrid.new(80, 80)
		grid.fill_block(10, 10, 40, 1)
		var place := AvatarPlacement.of(grid, 1)
		t.check(place["center"].distance_to(Vector2(30, 30)) < 1.0,
			"markaz hudud o'rtasida: %s" % place["center"])
		t.check(absf(float(place["half"]) - 20.0) < 1.0,
			"yarim o'lcham ~20: %s" % place["half"])
	)

	t.test("egasiz hudud uchun o'lcham nol", func() -> void:
		var grid := GameGrid.new(20, 20)
		t.equal(AvatarPlacement.of(grid, 3)["half"], 0.0)
	)

	t.test("cho'ziq hududda avatar cheklanadi", func() -> void:
		var grid := GameGrid.new(80, 80)
		for y in range(10, 70):
			for x in range(10, 20):
				grid.set_owner(x, y, 1)
		var half := float(AvatarPlacement.of(grid, 1)["half"])
		t.check(half <= 10.0 * AvatarPlacement.MAX_STRETCH * 0.5 + 0.01,
			"qisqa tomonidan ko'p cho'zilmaydi: %f" % half)
		t.greater(half, 5.0, "lekin kichkina ham emas")
	)

	t.test("\"L\" shaklida markaz hudud ichida qoladi", func() -> void:
		var grid := GameGrid.new(60, 60)
		grid.fill_block(5, 5, 20, 1)
		for y in range(25, 50):
			for x in range(5, 25):
				grid.set_owner(x, y, 1)
		var center: Vector2 = AvatarPlacement.of(grid, 1)["center"]
		t.equal(grid.owner_at(int(center.x), int(center.y)), 1,
			"markaz egallangan katakda")
	)

	t.test("avatar hududning katta qismini qoplaydi", func() -> void:
		var grid := GameGrid.new(80, 80)
		grid.fill_disc(40, 40, 18.0, 1)
		var place := AvatarPlacement.of(grid, 1)
		var center: Vector2 = place["center"]
		var half := float(place["half"])
		var inside := 0
		var total := 0
		for y in 80:
			for x in 80:
				if grid.owner_at(x, y) != 1:
					continue
				total += 1
				if absf(x + 0.5 - center.x) <= half \
						and absf(y + 0.5 - center.y) <= half:
					inside += 1
		t.greater(float(inside) / float(total), 0.75, "hududning 75%+ qismi")
	)

# ——— Belet va reklama ———

func _test_continue(t: TestRunner) -> void:
	t.group("belet va reklama")

	t.test("to'plam sotib olinsa belet soni ortadi", func() -> void:
		var s := ContinueServices.new()
		t.equal(s.buy("tickets_5"), 5)
		t.equal(s.buy("tickets_15"), 15)
	)

	t.test("noma'lum to'plam xaridi o'tmaydi", func() -> void:
		t.equal(ContinueServices.new().buy("tickets_999"), 0)
	)

	t.test("reklama bir marta mukofot beradi", func() -> void:
		var s := ContinueServices.new()
		t.equal(s.show_rewarded(), ContinueServices.AD_REWARD)
		t.equal(s.show_rewarded(), 0, "qayta yuklanmaguncha yo'q")
		s.preload_ad()
		t.equal(s.show_rewarded(), ContinueServices.AD_REWARD)
	)

# ——— Profil ———

func _test_profile(t: TestRunner) -> void:
	t.group("profil")

	t.test("har bir avatar arenada belgiga ega", func() -> void:
		var empty := 0
		for e: String in Profile.EMOJIS:
			if Profile.map_glyph(Profile.encode(Profile.Kind.EMOJI, e)).is_empty():
				empty += 1
		for i in Profile.FIGURE_COUNT:
			if Profile.map_glyph(Profile.encode(
					Profile.Kind.FIGURE, str(i))).is_empty():
				empty += 1
		t.equal(empty, 0, "bo'sh belgi yo'q")
	)

	t.test("bayroq kodi emojiga aylanadi", func() -> void:
		t.equal(Profile.map_glyph("flag:UZ"), Profile.flag_emoji("UZ"))
		t.greater(Profile.flag_emoji("UZ").length(), 1, "ikki belgidan")
	)

# ——— Hudud egallash ———

func _test_capture(t: TestRunner) -> void:
	t.group("hudud egallash")

	t.test("yopiq halqa ichidagi bo'sh joy egallanadi", func() -> void:
		var grid := MapHelpers.grid_from(PackedStringArray([
			".....",
			".111.",
			".1.1.",
			".111.",
			".....",
		]))
		TerritoryCapturer.new(grid).capture(1, PackedInt32Array())
		t.equal(grid.owner_at(2, 2), 1, "o'rtadagi katak egallanadi")
		t.equal(grid.territory_of(1), 9)
	)

	t.test("tashqaridagi joy egallanmaydi", func() -> void:
		var grid := MapHelpers.grid_from(PackedStringArray([
			".....",
			".111.",
			".1.1.",
			".111.",
			".....",
		]))
		TerritoryCapturer.new(grid).capture(1, PackedInt32Array())
		t.equal(grid.owner_at(0, 0), 0)
		t.equal(grid.owner_at(4, 4), 0)
	)

	t.test("iz kataklari hududga qo'shiladi", func() -> void:
		var grid := MapHelpers.grid_from(PackedStringArray([
			"11...",
			"11...",
			".....",
		]))
		# Iz: (2,0) va (2,1) — hududni o'ngga kengaytiradi.
		var trail := PackedInt32Array([2, 5 + 2])
		for i: int in trail:
			grid.set_trail_index(i, 1)
		var result := TerritoryCapturer.new(grid).capture(1, trail)
		t.equal(grid.owner_at(2, 0), 1)
		t.equal(grid.owner_at(2, 1), 1)
		t.greater(result["captured"], 1)
	)

	t.test("raqib hududi ham o'raladi", func() -> void:
		var grid := MapHelpers.grid_from(PackedStringArray([
			".....",
			".111.",
			".121.",
			".111.",
			".....",
		]))
		var result := TerritoryCapturer.new(grid).capture(1, PackedInt32Array())
		t.equal(grid.owner_at(2, 2), 1, "raqib katagi tortib olinadi")
		t.equal(int((result["taken_from"] as Dictionary).get(2, 0)), 1)
	)

	t.test("katta maydonda ham tez ishlaydi", func() -> void:
		var grid := GameGrid.new(150, 150)
		for y in range(10, 140):
			for x in range(10, 140):
				if x == 10 or x == 139 or y == 10 or y == 139:
					grid.set_owner(x, y, 1)
		var started := Time.get_ticks_usec()
		TerritoryCapturer.new(grid).capture(1, PackedInt32Array())
		var took := Time.get_ticks_usec() - started
		t.equal(grid.owner_at(75, 75), 1, "ichkarisi to'ldi")
		t.less(took, 100000, "egallash 100 ms dan tez (%d µs)" % took)
	)

# ——— O'lim qoidalari ———

func _test_death_rules(t: TestRunner) -> void:
	t.group("o'lim qoidalari")

	t.test("o'z izini kesgan o'yinchi o'ladi", func() -> void:
		var world := MapHelpers.make_world(60, 60)
		var p := MapHelpers.place_player(world, 28, 28)
		# To'rtburchak halqa: oxirgi tomon birinchi tomonni kesadi.
		_walk(world, p, -PI / 2, 16)
		_walk(world, p, 0.0, 8)
		_walk(world, p, PI / 2, 12)
		_walk(world, p, PI, 12)
		t.check(not p.alive, "o'z izini kesib o'lishi kerak")
		t.equal(p.death_cause, PlayerState.DeathCause.SELF_CROSS)
	)

	t.test("iz bo'ylab ortga qaytgan o'yinchi o'lmaydi", func() -> void:
		# Ingichka bo'g'ozga yoki kichik orolga kirib qolgan o'yinchi
		# boshqa yo'ldan chiqolmaydi — qaytish o'lim bo'lmasligi kerak.
		var world := MapHelpers.make_world(60, 60)
		var p := MapHelpers.place_player(world, 28, 28)
		_walk(world, p, -PI / 2, 16)
		t.check(p.alive, "chiqishda tirik")
		t.greater(p.trail.size(), 10, "iz qoldi")
		_walk(world, p, PI / 2, 16)
		t.check(p.alive, "qaytishda ham tirik")
		t.equal(p.trail.size(), 0, "hududiga qaytib, iz yopildi")
	)

	t.test("izga boshqa joydan kirgan o'yinchi o'ladi", func() -> void:
		var world := MapHelpers.make_world(60, 60)
		var p := MapHelpers.place_player(world, 28, 28)
		_walk(world, p, -PI / 2, 16)
		# Izdan uzoqlashib, keyin uni yon tomondan kesadi.
		_walk(world, p, 0.0, 6)
		_walk(world, p, PI / 2, 6)
		_walk(world, p, PI, 10)
		t.check(not p.alive, "kesib o'tishda o'ladi")
		t.equal(p.death_cause, PlayerState.DeathCause.SELF_CROSS)
	)

	t.test("endigina qo'yilgan iz o'ldirmaydi", func() -> void:
		var world := MapHelpers.make_world()
		var p := MapHelpers.place_player(world, 8, 8)
		p.steer_to(-PI / 2)
		p.angle = -PI / 2
		for i in 60:
			world.update(1.0 / 60.0)
		t.check(p.alive, "to'g'ri yurganda tirik qoladi")
		t.greater(p.trail.size(), 0, "iz qoldirdi")
	)

	t.test("raqib izga tegsa iz egasi o'ladi", func() -> void:
		var world := MapHelpers.make_world(40, 40)
		var victim := MapHelpers.place_player(world, 5, 5)
		var killer := MapHelpers.place_player(world, 25, 5)
		# Qurbon hududdan chiqib iz qoldiradi.
		victim.steer_to(0.0)
		victim.angle = 0.0
		for i in 40:
			world.update(1.0 / 60.0)
		t.greater(victim.trail.size(), 0, "iz bor")

		# Qotil o'sha izning ustiga qadam qo'yadi.
		var cell: int = victim.trail[victim.trail.size() / 2]
		var tx: int = cell % world.grid.width
		var ty: int = cell / world.grid.width
		killer.place_at(tx - 1.5, ty + 0.5, 0.0)
		for i in 30:
			if not victim.alive:
				break
			world.update(1.0 / 60.0)
		t.check(not victim.alive, "iz egasi o'ladi")
		t.equal(victim.death_cause, PlayerState.DeathCause.TRAIL_HIT)
		t.equal(killer.kills, 1, "qotilga +1 kill")
	)

	t.test("chegara o'ldirmaydi, to'siq bo'ladi", func() -> void:
		var world := MapHelpers.make_world()
		var p := MapHelpers.place_player(world, 8, 8)
		p.steer_to(-PI / 2)
		p.angle = -PI / 2
		for i in 400:
			world.update(1.0 / 60.0)
		t.check(p.alive, "devorga tegib o'lmaydi")
		t.check(p.y >= 0.0 and p.y <= world.grid.height, "maydon ichida qoladi")
	)

	t.test("butun hududi egallangan o'yinchi o'ladi", func() -> void:
		var world := MapHelpers.make_world(30, 30)
		var big := MapHelpers.place_player(world, 5, 5, 20)
		var small := world.add_player("S", 1, false)
		# Kichkina o'yinchi kattaning ichida.
		world.grid.fill_block(12, 12, 2, small.id)
		small.place_at(12.5, 12.5, 0.0)
		small.alive = true
		t.equal(world.grid.territory_of(small.id), 4)

		TerritoryCapturer.new(world.grid).capture(big.id, PackedInt32Array())
		# Qoida tekshiruvi mantiqda `_finish_loop` ichida — bu yerda
		# natijani qo'lda tekshiramiz.
		t.equal(world.grid.territory_of(small.id), 0, "hududi yo'qoldi")
	)

## O'yinchini berilgan yo'nalishda shuncha katak yurgizadi.
func _walk(world: GameWorld, p: PlayerState, angle: float,
		cells: float) -> void:
	p.angle = angle
	p.steer_to(angle)
	var steps := int(cells / (p.speed / 60.0))
	for i in steps:
		if not p.alive:
			return
		world.update(1.0 / 60.0)

# ——— Suv ———

func _test_water(t: TestRunner) -> void:
	t.group("suv — to'siq")

	t.test("foiz quruqlikka nisbatan hisoblanadi", func() -> void:
		var grid := MapHelpers.grid_from(PackedStringArray([
			"~~~~",
			"~11~",
			"~11~",
			"~~~~",
		]))
		t.equal(grid.land_cells, 4)
		t.equal(grid.territory_of(1), 4)
		t.close_to(grid.percent_of(1), 100.0)
	)

	t.test("o'ralgan ko'l egallanmaydi", func() -> void:
		var grid := MapHelpers.grid_from(PackedStringArray([
			".....",
			".111.",
			".1~1.",
			".111.",
			".....",
		]))
		TerritoryCapturer.new(grid).capture(1, PackedInt32Array())
		t.equal(grid.owner_at(2, 2), 0, "ko'l ko'l bo'lib qoladi")
		t.equal(grid.territory_of(1), 8)
	)

	t.test("suv katagi o'ynalmaydi", func() -> void:
		var grid := MapHelpers.grid_from(PackedStringArray(["~.~"]))
		t.check(not grid.playable(0, 0))
		t.check(grid.playable(1, 0))
		t.check(not grid.playable(2, 0))
	)

# ——— Maydonlar ———

func _test_world_map(t: TestRunner) -> void:
	t.group("maydonlar")

	t.test("hamma maydon o'qiladi", func() -> void:
		for map_id: String in WorldMap.ids():
			var map := WorldMap.load_map(map_id)
			t.check(map.ok, "o'qildi: " + map_id)
			t.equal(map.land.size(), map.width * map.height,
				"mantiq niqobi to'liq: " + map_id)
			t.greater(map.top_points.size(), 30,
				"ustki yuza uchburchaklari: " + map_id)
			t.equal(map.top_points.size() % 3, 0,
				"uchburchaklar to'liq: " + map_id)
			t.greater(map.wall_points.size(), 10,
				"devor kesmalari: " + map_id)
			t.equal(map.wall_points.size() % 2, 0,
				"kesmalar to'liq: " + map_id)
			var share: float = float(map.land_cells) / float(map.land.size())
			t.greater(share, 0.1, "quruqlik ulushi: " + map_id)
			t.less(share, 0.95, "quruqlik ulushi: " + map_id)
	)

	t.test("geometriya xarita ichida qoladi", func() -> void:
		# Chegara uzluksiz maydondan olinadi, shuning uchun u
		# kataklarga yopishmaydi — lekin xaritadan chiqib ketmasligi
		# kerak.
		var map := WorldMap.load_map("world")
		var outside := 0
		for p: Vector2 in map.top_points:
			if p.x < -0.6 or p.y < -0.6 \
					or p.x > map.width + 0.6 or p.y > map.height + 0.6:
				outside += 1
		t.equal(outside, 0, "chegaradan chiqqan nuqta")
	)

	t.test("shaharlar quruqlikda va poytaxtlar belgilangan", func() -> void:
		var map := WorldMap.load_map("world")
		t.greater(map.places.size(), 900, "dunyoda shaharlar ko'p")
		var water := 0
		var capitals := 0
		for c in map.places:
			if not map.is_land(int(c["x"]), int(c["y"])):
				water += 1
			if int(c.get("cap", 0)) == 1:
				capitals += 1
		t.equal(water, 0, "suvda qolgan shahar")
		t.greater(capitals, 150, "davlat poytaxtlari")
	)

	t.test("doira maydon kod bilan quriladi", func() -> void:
		var map := WorldMap.load_map(WorldMap.CIRCLE_ID)
		t.check(map.ok)
		t.check(map.is_land(map.width / 2, map.height / 2), "markazi quruqlik")
		t.check(not map.is_land(0, 0), "burchagi suv")
		var share: float = float(map.land_cells) / float(map.land.size())
		t.greater(share, 0.6, "doira maydonning katta qismini egallaydi")
	)

	t.test("mashhur poytaxtlar to'g'ri joyda", func() -> void:
		var map := WorldMap.load_map("world")
		var by_name := {}
		for c in map.places:
			by_name[c["name"]] = c
		var tashkent: Dictionary = by_name["Tashkent"]
		var ba: Dictionary = by_name["Buenos Aires"]
		t.greater(int(tashkent["x"]), int(ba["x"]), "Toshkent sharqroqda")
		t.less(int(tashkent["y"]), int(ba["y"]), "Toshkent shimolroqda")
	)

	t.test("materik maydonida o'yin boshlanadi", func() -> void:
		var config := GameConfig.new()
		config.map_id = "africa"
		config.bot_count = 5
		var world := MatchBuilder.create(config, 0, "Men", "figure:0", 9)
		t.equal(world.grid.width, world.map.width, "panjara xaritaga mos")
		var bad := 0
		for p in world.players:
			if not p.alive or not world.grid.playable(p.cx, p.cy):
				bad += 1
		t.equal(bad, 0, "hamma quruqlikda")
	)

# ——— To'liq o'yin ———

func _test_match(t: TestRunner) -> void:
	t.group("dunyo xaritasidagi o'yin")

	t.test("o'yinchilar quruqlikda tug'iladi", func() -> void:
		var config := GameConfig.new()
		config.bot_count = 8
		var world := GameWorld.new(config, 5)
		for i in 9:
			world.add_player("P%d" % i, i, i > 0)
		world.spawn_all()
		var bad := 0
		for p in world.players:
			if not p.alive or not world.grid.playable(p.cx, p.cy):
				bad += 1
		t.equal(bad, 0, "hamma quruqlikda")
	)

	t.test("o'yinchi okeanga chiqib keta olmaydi", func() -> void:
		var config := GameConfig.new()
		config.bot_count = 0
		var world := GameWorld.new(config, 5)
		var p := world.add_player("P", 0, false)
		world.spawn_all()
		var bad := 0
		for dir in 8:
			p.angle = dir * PI / 4.0
			p.steer_to(p.angle)
			for i in 400:
				world.update(1.0 / 60.0)
				if not p.alive:
					break
				if not world.grid.playable(p.cx, p.cy):
					bad += 1
					break
			if not p.alive or bad > 0:
				break
		t.equal(bad, 0, "suvga tushmadi")
	)
