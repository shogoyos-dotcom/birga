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
	_test_marks(t)
	_test_continue(t)
	_test_profile(t)
	_test_strings(t)
	quit(0 if t.report() else 1)

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

# ——— Hudud ustidagi avatar naqshi ———

func _test_marks(t: TestRunner) -> void:
	t.group("avatar naqshi")

	t.test("belgilar faqat hudud ustiga tushadi", func() -> void:
		var grid := GameGrid.new(60, 60)
		grid.fill_block(10, 10, 40, 1)
		var plan := MarkLayout.plan(grid, 1)
		var points: PackedVector2Array = plan["points"]
		t.greater(points.size(), 1, "naqsh bir nechta belgidan iborat")
		var outside := 0
		for point in points:
			if grid.owner_at(int(point.x), int(point.y)) != 1:
				outside += 1
		t.equal(outside, 0, "hammasi hudud ichida")
	)

	t.test("naqsh butun hududga tarqaladi", func() -> void:
		var grid := GameGrid.new(80, 80)
		grid.fill_block(0, 0, 80, 1)
		var points: PackedVector2Array = MarkLayout.plan(grid, 1)["points"]
		var min_p := Vector2(1e9, 1e9)
		var max_p := Vector2(-1e9, -1e9)
		for point in points:
			min_p = min_p.min(point)
			max_p = max_p.max(point)
		# Belgilar bir burchakda to'planib qolmasin: eng chap va eng
		# o'ng belgi orasidagi masofa hududning yarmidan katta.
		t.greater(max_p.x - min_p.x, 40.0, "gorizontal bo'ylab")
		t.greater(max_p.y - min_p.y, 40.0, "vertikal bo'ylab")
	)

	t.test("egasiz hudud uchun belgi yo'q", func() -> void:
		var grid := GameGrid.new(20, 20)
		t.equal(MarkLayout.plan(grid, 3)["points"].size(), 0)
	)

	t.test("kichik hududda ham bitta belgi bo'ladi", func() -> void:
		var grid := GameGrid.new(20, 20)
		grid.fill_block(5, 5, 4, 1)
		t.equal(MarkLayout.plan(grid, 1)["points"].size(), 1)
	)

	t.test("belgilar soni chegaradan oshmaydi", func() -> void:
		var grid := GameGrid.new(300, 300)
		grid.fill_block(0, 0, 300, 1)
		var points: PackedVector2Array = MarkLayout.plan(grid, 1)["points"]
		t.check(points.size() <= MarkLayout.MAX_PER_PLAYER,
			"%d <= %d" % [points.size(), MarkLayout.MAX_PER_PLAYER])
		t.greater(points.size(), 8, "lekin naqsh siyrak emas")
	)

	t.test("suv ustiga belgi tushmaydi", func() -> void:
		var grid := MapHelpers.grid_from(PackedStringArray([
			"1111111111",
			"1111111111",
			"11~~~~~~11",
			"11~~~~~~11",
			"1111111111",
			"1111111111",
		]))
		for point: Vector2 in MarkLayout.plan(grid, 1)["points"]:
			t.check(grid.is_land(int(point.x), int(point.y)), "quruqlikda")
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
		var world := MapHelpers.make_world()
		var p := MapHelpers.place_player(world, 8, 8)
		# Hududdan chiqib, halqa chizamiz.
		p.steer_to(-PI / 2)
		p.angle = -PI / 2
		for i in 40:
			world.update(1.0 / 60.0)
		var angle := -PI / 2
		for i in 400:
			if not p.alive:
				break
			angle += 0.3
			p.steer_to(angle)
			world.update(1.0 / 60.0)
		t.check(not p.alive, "o'z iziga tegib o'lishi kerak")
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

# ——— Dunyo xaritasi ———

func _test_world_map(t: TestRunner) -> void:
	t.group("dunyo xaritasi")

	t.test("niqob o'qiladi va o'lchami to'g'ri", func() -> void:
		var map := WorldMap.load_default()
		t.equal(map.width, 520)
		t.equal(map.height, 205)
		t.equal(map.land.size(), map.width * map.height)
		var share: float = float(map.land_cells) / float(map.land.size())
		t.greater(share, 0.2, "quruqlik ulushi")
		t.less(share, 0.4, "quruqlik ulushi")
	)

	t.test("poytaxtlar xarita ichida va quruqlikda", func() -> void:
		var map := WorldMap.load_default()
		t.equal(map.capitals.size(), 236)
		var bad := 0
		for c in map.capitals:
			if not map.is_land(int(c["x"]), int(c["y"])):
				bad += 1
		t.equal(bad, 0, "suvda qolgan poytaxtlar")
	)

	t.test("mashhur poytaxtlar to'g'ri joyda", func() -> void:
		var map := WorldMap.load_default()
		var by_name := {}
		for c in map.capitals:
			by_name[c["name"]] = c
		var tashkent: Dictionary = by_name["Tashkent"]
		var ba: Dictionary = by_name["Buenos Aires"]
		t.greater(int(tashkent["x"]), int(ba["x"]), "Toshkent sharqroqda")
		t.less(int(tashkent["y"]), int(ba["y"]), "Toshkent shimolroqda")
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
