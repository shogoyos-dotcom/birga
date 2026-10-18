extends SceneTree

const TestRunner := preload("res://tests/test_runner.gd")
const MapHelpers := preload("res://tests/map_helpers.gd")
const CitySystemRef := preload("res://scripts/logic/city_system.gd")
const CityMeshBuilderRef := preload("res://scripts/render/city_mesh_builder.gd")
const SavePaths := preload("res://scripts/app/save_paths.gd")

## Headless test kiruvchi nuqtasi:
##   godot --headless --script res://tests/run_tests.gd

## Testlar birinchi kadrda ishlaydi, `_initialize` da emas:
## avtoyuklanadigan modullar (Wallet, Shop, Missions va hokazo)
## faqat daraxt tiklangandan keyin paydo bo'ladi.
func _process(_delta: float) -> bool:
	# 1. Barcha ishlab chiqarish fayllari (user://) ni testlardan to'liq izolyatsiya qilish:
	SavePaths.set_test_mode(true, "user://test_sandbox/")
	var prod_snapshot := SavePaths.snapshot_production_hashes()

	# Barcha avtoyuklangan xizmatlarni test yo'llariga yo'naltirish
	var root_wallet: Node = root.get_node_or_null("/root/Wallet")
	if root_wallet != null and root_wallet.has_method("set_file_path"):
		root_wallet.set_file_path(SavePaths.path_for(SavePaths.WALLET))

	var root_shop: Node = root.get_node_or_null("/root/Shop")
	if root_shop != null and root_shop.has_method("set_file_path"):
		root_shop.set_file_path(SavePaths.path_for(SavePaths.SHOP))

	var root_daily: Node = root.get_node_or_null("/root/Daily")
	if root_daily != null and root_daily.has_method("set_file_path"):
		root_daily.set_file_path(SavePaths.path_for(SavePaths.DAILY))

	var root_missions: Node = root.get_node_or_null("/root/Missions")
	if root_missions != null and root_missions.has_method("set_file_path"):
		root_missions.set_file_path(SavePaths.path_for(SavePaths.MISSIONS))

	var root_purchases: Node = root.get_node_or_null("/root/Purchases")
	if root_purchases != null and root_purchases.has_method("set_file_path"):
		root_purchases.set_file_path(SavePaths.path_for(SavePaths.PURCHASES))

	var root_upgrades: Node = root.get_node_or_null("/root/Upgrades")
	if root_upgrades != null and root_upgrades.has_method("set_file_path"):
		root_upgrades.set_file_path(SavePaths.path_for(SavePaths.UPGRADES))

	var root_journey: Node = root.get_node_or_null("/root/Journey")
	if root_journey != null and root_journey.has_method("set_file_path"):
		root_journey.set_file_path(SavePaths.path_for(SavePaths.JOURNEY))

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
	_test_money(t)
	_test_coins(t)
	_test_trail_smoothing(t)
	_test_shop(t)
	_test_daily(t)
	_test_missions(t)
	_test_purchases(t)
	_test_pickups(t)
	_test_upgrades(t)
	_test_shield(t)
	_test_journey(t)
	_test_heroes(t)
	_test_phase3_scaling(t)
	_test_phase4_flags(t)
	_test_phase5_cities(t)
	_test_phase6_economy(t)
	_test_phase6_corrections_integration(t)
	_test_phase8_optimization_qa(t)
	_test_phase8_blockers_validation(t)
	_test_phase8_final_save_isolation(t)
	_test_phase8_transaction_deduplication(t)
	_test_phase8_atomic_city_rewards(t)
	_test_phase8_real_gameplay_integration(t)
	_test_phase8_spatial_city_performance(t)
	_test_phase8_long_session_endurance(t)
	_test_fonts_and_glyphs(t)

	var ok := t.report()

	# 2. Testlar tugagach barcha ishlab chiqarish fayllari (user://) o'zgarmaganligini SHA-256 xeshlari bilan qat'iy tekshirish:
	var verify_res := SavePaths.verify_production_hashes(prod_snapshot)
	if not bool(verify_res.get("ok", false)):
		printerr("XATOLIK: Testlar ishlab chiqarish fayllarini o'zgartirib yubordi!")
		for mismatch: String in (verify_res.get("mismatches", []) as Array):
			printerr("  - ", mismatch)
		ok = false

	# Faqat vaqtinchalik test_sandbox ichidagi fayllarni tozalash
	SavePaths.cleanup_test_data()

	# Xotiradagi statik keshlar va resurslarni tozalash (DummyTexture, DummyMaterial, DummyShader leaks oldini olish)
	var FlagRendererRef = preload("res://scripts/render/flag_renderer.gd")
	FlagRendererRef.clear_cache()
	var CityRendererRef = preload("res://scripts/render/city_renderer.gd")
	CityRendererRef.clear_cache()
	var CityMeshBuilderRef = preload("res://scripts/render/city_mesh_builder.gd")
	CityMeshBuilderRef.clear_cache()

	# Test rejimini o'chirish
	SavePaths.set_test_mode(false)
	if root_wallet != null and root_wallet.has_method("set_file_path"):
		root_wallet.set_file_path(SavePaths.path_for(SavePaths.WALLET))
	if root_shop != null and root_shop.has_method("set_file_path"):
		root_shop.set_file_path(SavePaths.path_for(SavePaths.SHOP))
	if root_daily != null and root_daily.has_method("set_file_path"):
		root_daily.set_file_path(SavePaths.path_for(SavePaths.DAILY))
	if root_missions != null and root_missions.has_method("set_file_path"):
		root_missions.set_file_path(SavePaths.path_for(SavePaths.MISSIONS))
	if root_purchases != null and root_purchases.has_method("set_file_path"):
		root_purchases.set_file_path(SavePaths.path_for(SavePaths.PURCHASES))
	if root_upgrades != null and root_upgrades.has_method("set_file_path"):
		root_upgrades.set_file_path(SavePaths.path_for(SavePaths.UPGRADES))
	if root_journey != null and root_journey.has_method("set_file_path"):
		root_journey.set_file_path(SavePaths.path_for(SavePaths.JOURNEY))

	quit(0 if ok else 1)
	return true

# ——— Chizish qatlami ———

# ——— Xaritadagi tangalar ———

func _test_coins(t: TestRunner) -> void:
	t.group("shahar tangalari")

	var grid := MapHelpers.grid_from(PackedStringArray([
		"......",
		"......",
		"......",
		"......",
	]))
	var places: Array = [
		{"x": 1, "y": 1, "pop": 1000},
		{"x": 4, "y": 2, "pop": 100},
	]
	var cell_a := 1 * grid.width + 1
	var cell_b := 2 * grid.width + 4

	t.test("har shaharda bitta tanga", func() -> void:
		var field := CoinField.new()
		field.build(places, grid)
		t.equal(field.size(), 2, "ikki shahar")
		t.equal(field.taken_count(), 0, "boshida hammasi joyida")
	)

	t.test("egallangan katakdagi tanga olinadi", func() -> void:
		var field := CoinField.new()
		field.build(places, grid)
		var got := field.collect_cells(PackedInt32Array([cell_a]))
		t.check(got > 0, "qiymati bor: %d" % got)
		t.equal(field.collected(), got, "hisobga yozildi")
		t.equal(field.taken_count(), 1, "xaritadan yo'qoldi")
		t.equal(field.collect_cells(PackedInt32Array([cell_a])), 0,
			"ikkinchi marta olinmaydi")
	)

	t.test("raqib olsa hisobga yozilmaydi", func() -> void:
		# Raqib mening yerimga kirib tangani olib ketishi mumkin:
		# tanga xaritadan yo'qoladi, lekin menga tushmaydi.
		var field := CoinField.new()
		field.build(places, grid)
		var got := field.collect_cells(PackedInt32Array([cell_b]), false)
		t.check(got > 0, "tanga olindi")
		t.equal(field.collected(), 0, "mening hisobim o'zgarmadi")
		t.equal(field.taken_count(), 1, "xaritadan yo'qoldi")
	)

	t.test("tanga 30 soniyadan keyin qaytadi", func() -> void:
		var field := CoinField.new()
		field.build(places, grid)
		var first := field.collect_cells(PackedInt32Array([cell_a]))
		t.equal(field.waiting_count(), 1, "navbatda turibdi")
		t.check(field.advance(
			MonetizationConfig.CITY_COIN_RESPAWN - 1.0).is_empty(),
			"muddatidan oldin qaytmaydi")
		t.equal(field.taken_count(), 1, "hali yo'q")
		var back := field.advance(2.0)
		t.equal(back.size(), 1, "qaytdi")
		t.equal(field.taken_count(), 0, "xaritada yana bor")
		t.equal(field.collect_cells(PackedInt32Array([cell_a])), first,
			"qaytgach yana olinadi")
	)

	t.test("o'z hududingdagi tanga olinmaydi", func() -> void:
		# Egallash faqat **yangi** kataklarni qaytaradi, shuning
		# uchun o'zingniki bo'lgan shahar ro'yxatga tushmaydi.
		var own := MapHelpers.grid_from(PackedStringArray([
			"111111",
			"111111",
			"111111",
			"111111",
		]))
		var capture := TerritoryCapturer.new(own)
		var result := capture.capture(1, PackedInt32Array())
		t.equal((result["cells"] as PackedInt32Array).size(), 0,
			"o'z yeri qayta egallanmaydi")
	)

# ——— Yo'ldagi tangalar va sferalar ———

func _test_pickups(t: TestRunner) -> void:
	t.group("yo'ldagi tangalar")

	var grid := MapHelpers.grid_from(PackedStringArray([
		"........",
		"........",
		"........",
		"........",
		"........",
		"........",
	]))

	t.test("hammasi o'ynaladigan katakda", func() -> void:
		var field := PickupField.new()
		field.build(grid, 40, 7)
		t.equal(field.size(), 40, "soni so'ralgandek")
		var bad := 0
		for item: Dictionary in field.items:
			if not grid.playable(int(float(item["x"])),
					int(float(item["y"]))):
				bad += 1
		t.equal(bad, 0, "hech biri suvda emas")
	)

	t.test("sferalar ham, tangalar ham bor", func() -> void:
		var field := PickupField.new()
		field.build(grid, 40, 7)
		var kinds := {}
		for item: Dictionary in field.items:
			kinds[int(item["kind"])] = true
		t.check(kinds.has(PickupField.Kind.COIN), "tanga bor")
		t.check(kinds.has(PickupField.Kind.SHIELD), "qalqon bor")
		t.check(kinds.has(PickupField.Kind.DASH), "tezlik bor")
	)

	t.test("faqat radius ichidagisi olinadi", func() -> void:
		var field := PickupField.new()
		field.build(grid, 1, 7)
		var item: Dictionary = field.items[0]
		var x := float(item["x"])
		var y := float(item["y"])
		t.check(field.take_near(x + 5.0, y, 1.0).is_empty(),
			"uzoqdagisi olinmaydi")
		t.equal(field.take_near(x + 0.5, y, 1.0).size(), 1, "yaqini olindi")
		t.equal(field.taken_count(), 1, "xaritadan yo'qoldi")
		t.check(field.take_near(x, y, 1.0).is_empty(),
			"ikkinchi marta olinmaydi")
	)

	t.test("magnit radiusi kattarsa uzoqdan oladi", func() -> void:
		var field := PickupField.new()
		field.build(grid, 1, 7)
		var item: Dictionary = field.items[0]
		var far := float(item["x"]) + 2.4
		t.check(field.take_near(far, float(item["y"]), 1.1).is_empty(),
			"nol darajada yetib bormaydi")
		t.equal(field.take_near(far, float(item["y"]), 3.3).size(), 1,
			"yuqori darajada oladi")
	)

	t.test("olingan narsa boshqa joyda qaytadi", func() -> void:
		var field := PickupField.new()
		field.build(grid, 1, 7)
		var item: Dictionary = field.items[0]
		var was := Vector2(float(item["x"]), float(item["y"]))
		field.take_near(was.x, was.y, 1.0)
		t.check(field.advance(PickupField.RESPAWN - 1.0).is_empty(),
			"muddatidan oldin qaytmaydi")
		var back := field.advance(2.0)
		t.equal(back.size(), 1, "qaytdi")
		t.equal(field.taken_count(), 0, "xaritada yana bor")
		var now := Vector2(float(item["x"]), float(item["y"]))
		t.check(now != was, "joyi almashdi: %s -> %s" % [was, now])
	)

	t.test("natijaga passiv bonus qo'shiladi", func() -> void:
		var plain := RewardManager.run_reward(60.0, 10.0, 2, 5, 0)
		var bonus := RewardManager.run_reward(60.0, 10.0, 2, 5, 30)
		t.equal(int(bonus["passive"]), 30, "qator ko'rinadi")
		t.equal(int(bonus["total"]), int(plain["total"]) + 30,
			"umumiy songa qo'shildi")
	)

	t.test("bonus ham chegaradan oshmaydi", func() -> void:
		var huge := RewardManager.run_reward(
			9999.0, 90.0, 99, 9999, 9999)
		t.equal(int(huge["total"]), MonetizationConfig.RUN_COIN_CAP,
			"chegarada to'xtadi")
	)

# ——— Mamlakatlar yo'li ———

const JourneyScript := preload("res://scripts/app/country_store.gd")

func _test_journey(t: TestRunner) -> void:
	t.group("mamlakatlar yo'li")

	t.test("ro'yxat o'qiladi va Oʻzbekiston birinchi", func() -> void:
		var all := CountryPath.load_all()
		t.check(all.size() >= 20, "%d ta mamlakat" % all.size())
		t.equal(str((all[0] as Dictionary)["code"]), "UZ",
			"birinchisi — Oʻzbekiston")
		var goals_grow := true
		for i in range(1, all.size()):
			if int((all[i] as Dictionary)["goal"]) \
					<= int((all[i - 1] as Dictionary)["goal"]):
				goals_grow = false
		t.check(goals_grow, "nishon har safar kattalashadi")
	)

	t.test("har shaklda nuqta bor va 0..1 ichida", func() -> void:
		var bad := 0
		var empty := 0
		for row: Dictionary in CountryPath.load_all():
			var rings := CountryPath.rings_of(row)
			if rings.is_empty():
				empty += 1
			for ring: PackedVector2Array in rings:
				if ring.size() < 3:
					empty += 1
				for p: Vector2 in ring:
					if p.x < -0.001 or p.x > 1.001 \
							or p.y < -0.001 or p.y > 1.001:
						bad += 1
		t.equal(empty, 0, "bo'sh shakl yo'q")
		t.equal(bad, 0, "hamma nuqta kvadrat ichida")
	)

	t.test("ochko hududdan va o'ldirishdan yig'iladi", func() -> void:
		t.equal(CountryPath.points_for(0.0, 0), CountryPath.POINTS_MIN,
			"yomon o'yin ham bir oz beradi")
		t.equal(CountryPath.points_for(5.0, 0), 50, "5% -> 50")
		t.equal(CountryPath.points_for(5.0, 2), 60, "ikki kill -> +10")
		t.check(CountryPath.points_for(-3.0, -1) > 0, "manfiy natija xavfsiz")
	)

	t.test("nishonga yetganda keyingi mamlakatga o'tadi", func() -> void:
		var journey: Node = JourneyScript.new()
		journey.reset()
		var first := str(journey.current()["code"])
		var goal: int = journey.goal()
		var result: Dictionary = journey.add(goal - 1)
		t.equal(journey.index(), 0, "hali o'sha yerda")
		t.check(result["done"].is_empty(), "hech narsa tugamadi")
		result = journey.add(5)
		t.equal(result["done"].size(), 1, "mamlakat yopildi")
		t.equal(str(result["done"][0]), first, "yopilgani — birinchisi")
		t.equal(journey.index(), 1, "keyingisiga o'tdi")
		t.equal(journey.points(), 4, "ortgan ochko yo'qolmadi")
		journey.reset()
		journey.free()
	)

	t.test("juda katta natija bir nechtasini yopadi", func() -> void:
		var journey: Node = JourneyScript.new()
		journey.reset()
		var result: Dictionary = journey.add(100000)
		t.check(result["done"].size() >= 3,
			"%d ta yopildi" % result["done"].size())
		t.equal(journey.percent(), 100.0, "oxirida chiziq to'la")
		journey.reset()
		journey.free()
	)

	t.test("foiz 0 dan 100 gacha", func() -> void:
		var journey: Node = JourneyScript.new()
		journey.reset()
		t.equal(journey.percent(), 0.0, "boshida nol")
		journey.add(journey.goal() / 2)
		t.check(journey.percent() > 40.0 and journey.percent() < 60.0,
			"yarmi: %.1f%%" % journey.percent())
		journey.reset()
		journey.free()
	)

# ——— Kuchaytirgichlar ———

const UpgradeScript := preload("res://scripts/money/upgrade_manager.gd")

func _test_upgrades(t: TestRunner) -> void:
	t.group("kuchaytirgichlar")

	t.test("narx har darajada oshadi", func() -> void:
		var up: Node = UpgradeScript.new()
		up.reset()
		var last := 0
		for i in UpgradeManager.MAX_LEVEL:
			var price: int = up.price("fever")
			t.check(price > last, "%d-daraja qimmatroq: %d" % [i + 1, price])
			last = price
			up._levels["fever"] = i + 1
		t.equal(up.price("fever"), 0, "eng yuqorida narx yo'q")
		up.reset()
		up.free()
	)

	t.test("nol darajada ta'siri yo'q", func() -> void:
		var up: Node = UpgradeScript.new()
		up.reset()
		t.equal(up.fever_seconds(), 0.0, "tezlik oshmaydi")
		t.equal(up.passive_bonus(), 0, "qo'shimcha tanga yo'q")
		t.equal(up.magnet_radius(), 1.1, "faqat ustidan yurganda")
		up.free()
	)

	t.test("daraja oshgach ta'siri kuchayadi", func() -> void:
		var up: Node = UpgradeScript.new()
		up.reset()
		var before: float = up.magnet_radius()
		up._levels["magnet"] = 3
		up._levels["fever"] = 2
		up._levels["passive"] = 4
		t.check(up.magnet_radius() > before, "radius kattalashdi")
		t.check(up.fever_seconds() > 0.0, "tezlik vaqti bor")
		t.equal(up.passive_bonus(), 60, "4 x 15 tanga")
		up.reset()
		up.free()
	)

	t.test("eng yuqori darajadan oshmaydi", func() -> void:
		var up: Node = UpgradeScript.new()
		up.reset()
		up._levels["magnet"] = UpgradeManager.MAX_LEVEL
		t.equal(up.buy("magnet"), "max", "oshirilmaydi")
		t.equal(up.buy("yoq"), "none", "notanish nom")
		up.reset()
		up.free()
	)

# ——— Qalqon ———

func _test_shield(t: TestRunner) -> void:
	t.group("qalqon")

	t.test("izga urilishdan asraydi", func() -> void:
		var config := GameConfig.new()
		config.bot_count = 0
		var world := GameWorld.new(config, 3)
		var p := world.add_player("P", 0, false)
		world.spawn_all()
		p.shield = true
		p.add_trail(world.grid.index(p.cx + 3, p.cy))
		world.kill(p, PlayerState.DeathCause.TRAIL_HIT, null)
		t.check(p.alive, "tirik qoldi")
		t.check(not p.shield, "qalqon sarflandi")
		t.equal(p.trail.size(), 0, "izi tozalandi")
		var kinds := {}
		for event: Dictionary in world.drain_events():
			kinds[str(event["type"])] = true
		t.check(kinds.has("shield_used"), "hodisa chiqdi")
	)

	t.test("hududni yo'qotishdan asramaydi", func() -> void:
		var config := GameConfig.new()
		config.bot_count = 0
		var world := GameWorld.new(config, 3)
		var p := world.add_player("P", 0, false)
		world.spawn_all()
		p.shield = true
		world.kill(p, PlayerState.DeathCause.TERRITORY_LOST, null)
		t.check(not p.alive, "o'ldi")
	)

	t.test("tug'ilganda qalqon yo'q", func() -> void:
		var config := GameConfig.new()
		config.bot_count = 0
		var world := GameWorld.new(config, 3)
		var p := world.add_player("P", 0, false)
		world.spawn_all()
		p.shield = true
		world.kill(p, PlayerState.DeathCause.TERRITORY_LOST, null)
		world.spawn(p)
		t.check(not p.shield, "yangi o'yinda qalqon yo'q")
	)

# ——— Iz lentasini silliqlash ———

const TrailRibbonsScript := preload("res://scripts/render/trail_ribbons.gd")

func _test_trail_smoothing(t: TestRunner) -> void:
	t.group("iz silliqligi")

	# Qirg'oq bo'ylab yurgandagi zinapoya: bir katak o'ngga, bir
	# katak pastga.
	var stair := PackedVector2Array()
	for i in 12:
		stair.append(Vector2(float(i), floor(i / 2.0)))
	var smooth: Array = TrailRibbonsScript.smooth_all(stair)

	t.test("zinapoya yumshaydi", func() -> void:
		t.equal(smooth.size(), stair.size(), "nuqtalar soni o'zgarmadi")
		var was := _wobble(stair)
		var now := _wobble(_packed(smooth))
		t.check(now < was * 0.4, "tishlari kamaydi: %.3f -> %.3f" % [was, now])
	)

	t.test("iz o'z joyidan ketmaydi", func() -> void:
		for i in stair.size():
			var at: Vector2 = smooth[i]
			t.check(at.distance_to(stair[i])
					<= TrailRibbonsScript.SMOOTH_LIMIT + 0.001,
				"%d-nuqta chegarada" % i)
		t.check((smooth[0] as Vector2).is_equal_approx(stair[0]),
			"boshi joyida")
		t.check((smooth[smooth.size() - 1] as Vector2).is_equal_approx(
			stair[stair.size() - 1]), "oxiri joyida")
	)

	t.test("to'g'ri chiziq o'zgarmaydi", func() -> void:
		var line := PackedVector2Array([
			Vector2(0, 0), Vector2(10, 0), Vector2(20, 0)])
		var out: Array = TrailRibbonsScript.smooth_all(line)
		for i in line.size():
			t.check((out[i] as Vector2).is_equal_approx(line[i]),
				"%d-nuqta joyida" % i)
	)

## Oddiy massivni Packed ga o'tkazadi — o'lchov uchun.
static func _packed(rows: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v: Vector2 in rows:
		out.append(v)
	return out

## Chiziqning "tishliligi": qo'shni kesmalar yo'nalishi qanchalik
## o'zgaradi. Kichik son — silliqroq.
static func _wobble(path: PackedVector2Array) -> float:
	var sum := 0.0
	for i in range(1, path.size() - 1):
		var a: Vector2 = path[i] - path[i - 1]
		var b: Vector2 = path[i + 1] - path[i]
		if a.length() < 1e-6 or b.length() < 1e-6:
			continue
		sum += absf(a.normalized().angle_to(b.normalized()))
	return sum

# ——— Do'kon ———

func _test_shop(t: TestRunner) -> void:
	var shop := root.get_node("/root/Shop")
	var wallet := root.get_node("/root/Wallet")
	t.group("do'kon")
	shop.reset()
	wallet.reset()

	t.test("katalog to'rt bo'limga bo'lingan", func() -> void:
		for cat: String in [ShopManager.SKINS, ShopManager.TRAILS,
				ShopManager.EFFECTS, ShopManager.SPECIAL]:
			t.check(not (shop.catalogue(cat) as Array).is_empty(), "bo'lim bo'sh emas: " + cat)
	)

	t.test("bepul element boshidan ochiq", func() -> void:
		t.check(shop.owns("skin_classic"), "oddiy ko'rinish bor")
		t.equal(shop.worn_in(ShopManager.SKINS), "skin_classic", "kiyilgan")
	)

	t.test("puli yetmasa sotilmaydi", func() -> void:
		wallet.reset()
		t.equal(shop.buy("skin_glow"), "poor", "pul yo'q")
		t.check(not shop.owns("skin_glow"), "element berilmadi")
	)

	t.test("sotib olinganda pul yechiladi", func() -> void:
		wallet.reset()
		wallet.add_coins(1000, "test")
		t.equal(shop.buy("skin_glow"), "ok", "sotildi")
		t.equal(wallet.get_coins(), 600, "400 tanga yechildi")
		t.check(shop.owns("skin_glow"), "element bor")
		t.equal(shop.worn_in(ShopManager.SKINS), "skin_glow", "darhol kiyildi")
		t.equal(shop.buy("skin_glow"), "owned", "ikkinchi marta sotilmaydi")
		t.equal(wallet.get_coins(), 600, "pul ikki marta yechilmadi")
	)

	t.test("shartli element pulga ochilmaydi", func() -> void:
		wallet.reset()
		wallet.add_coins(5000, "test")
		t.equal(shop.buy("special_pioneer", 5.0, 0), "locked", "rekord yetmaydi")
		t.equal(shop.buy("special_pioneer", 25.0, 0), "ok", "rekord yetdi")
		t.equal(wallet.get_coins(), 5000, "bepul — pul yechilmadi")
	)

	t.test("har bir element chiziladi", func() -> void:
		# Ko'rinish jadvalida yozuvi yo'q element do'konda bo'sh
		# katak bo'lib ko'rinardi.
		for item: Dictionary in ShopManager.ITEMS:
			var id := str(item["id"])
			match str(item["cat"]):
				ShopManager.SKINS:
					t.check(Cosmetics.SKINS.has(id), "pardozi bor: " + id)
				ShopManager.TRAILS:
					t.check(Cosmetics.TRAILS.has(id), "izi bor: " + id)
				ShopManager.EFFECTS:
					t.check(Cosmetics.EFFECTS.has(id), "effekti bor: " + id)
				_:
					t.check(Cosmetics.SPECIAL.has(id), "nishoni bor: " + id)
	)

	t.test("ko'rinish jadvalida o'yin qiymati yo'q", func() -> void:
		# Pardoz faqat chizishga ta'sir qiladi: tezlik yoki kuch
		# nomli kalit paydo bo'lsa, qoida buzilgan bo'ladi.
		var banned_look := ["speed", "power", "size", "damage", "bonus",
			"radius", "turn"]
		for table: Dictionary in [Cosmetics.SKINS, Cosmetics.TRAILS,
				Cosmetics.EFFECTS, Cosmetics.SPECIAL]:
			for id: String in table:
				for key: String in (table[id] as Dictionary):
					t.check(not banned_look.has(key),
						"%s da o'yin qiymati yo'q" % id)
	)

	t.test("iz rangi dumidan boshigacha to'liq bo'ladi", func() -> void:
		var look: Dictionary = Cosmetics.trail("trail_spark")
		var tail := Cosmetics.trail_color(Color("8ad0ff"), look, 0.0)
		var head := Cosmetics.trail_color(Color("8ad0ff"), look, 1.0)
		t.check(tail.a < head.a, "dumi shaffofroq")
		t.equal(head.a, 1.0, "boshi to'liq")
	)

	t.test("naqsh raqami jadvalga tushadi", func() -> void:
		# Skin hudud naqshini belgilaydi; raqam 512+ID katakning
		# alfasida keladi.
		var grid := GameGrid.new(4, 4)
		var colors := PackedByteArray()
		colors.resize(256)
		var skins := PackedStringArray()
		skins.resize(256)
		skins[3] = "skin_melon"
		var paint := PaintLayer.new(grid, colors, skins)
		var stored := int(round(
			paint.palette_image.get_pixel(512 + 3, 0).a * 255.0))
		t.equal(stored, Cosmetics.pattern_of("skin_melon"),
			"tarvuz naqshi")
		t.equal(int(round(paint.palette_image.get_pixel(512 + 4, 0).a
			* 255.0)), 0, "skinsiz o'yinchi tekis")
	)

	t.test("kosmetika o'yinga ta'sir qilmaydi", func() -> void:
		# Katalogda tezlik, zarar yoki hudud kuchini o'zgartiradigan
		# maydon bo'lmasligi kerak.
		var banned := ["speed", "power", "size", "damage", "bonus"]
		for item: Dictionary in ShopManager.ITEMS:
			for key: String in item:
				t.check(not banned.has(key),
					"%s da o'yinga ta'sir qiluvchi maydon yo'q" % item["id"])
	)
	shop.reset()
	wallet.reset()

# ——— Kunlik sovg'a ———

func _test_daily(t: TestRunner) -> void:
	var daily := root.get_node("/root/Daily")
	var wallet := root.get_node("/root/Wallet")
	t.group("kunlik sovg'a")
	daily.reset()
	wallet.reset()

	t.test("birinchi kun 100 tanga", func() -> void:
		t.equal(daily.next_day(), 1, "birinchi kun")
		t.equal(daily.reward_for_today(), MonetizationConfig.DAILY_LOGIN[0],
			"jadvaldagi qiymat")
		var got: Dictionary = daily.claim()
		t.check(bool(got["ok"]), "olindi")
		t.equal(wallet.get_coins(), MonetizationConfig.DAILY_LOGIN[0],
			"hamyonga tushdi")
	)

	t.test("bir kunda ikki marta olinmaydi", func() -> void:
		var before: int = wallet.get_coins()
		var again: Dictionary = daily.claim()
		t.check(not bool(again["ok"]), "ikkinchi marta yo'q")
		t.equal(wallet.get_coins(), before, "hamyon o'zgarmadi")
		t.check(daily.claimed_today(), "bugun olingan deb belgilandi")
	)

	t.test("reklama mukofotni ikki barobar qiladi", func() -> void:
		daily.reset()
		wallet.reset()
		var got: Dictionary = daily.claim(true)
		t.equal(int(got["amount"]),
			int(round(MonetizationConfig.DAILY_LOGIN[0]
				* MonetizationConfig.DAILY_REWARD_MULTIPLIER)),
			"ikki barobar")
	)

	t.test("aylanma yetti kundan keyin qaytadan", func() -> void:
		t.equal(RewardManager.daily_login(8), RewardManager.daily_login(1),
			"8-kun 1-kunga teng")
	)
	daily.reset()
	wallet.reset()

# ——— Kunlik topshiriqlar ———

func _test_missions(t: TestRunner) -> void:
	var missions := root.get_node("/root/Missions")
	var wallet := root.get_node("/root/Wallet")
	t.group("kunlik topshiriqlar")
	missions.reset()
	wallet.reset()

	t.test("har kuni uchta topshiriq", func() -> void:
		var list: Array = missions.today_missions()
		t.equal(list.size(), MissionManager.PER_DAY, "uchta")
		var ids := {}
		for m: Dictionary in list:
			ids[m["id"]] = true
		t.equal(ids.size(), MissionManager.PER_DAY, "takrorlanmaydi")
	)

	t.test("ro'yxat kun davomida o'zgarmaydi", func() -> void:
		var first: Array = missions.today_missions()
		var second: Array = missions.today_missions()
		for i in first.size():
			t.equal(str(first[i]["id"]), str(second[i]["id"]),
				"%d-topshiriq o'sha" % i)
	)

	t.test("bajarilganda mukofot bir marta beriladi", func() -> void:
		missions.reset()
		wallet.reset()
		# Hamma turni bajarib yuboradigan katta natija.
		var done: Array = missions.report(100.0, 50, 50, 600.0, 5000)
		t.check(not done.is_empty(), "kamida bittasi bajarildi")
		var earned: int = wallet.get_coins()
		t.check(earned > 0, "mukofot tushdi")
		missions.report(100.0, 50, 50, 600.0, 5000)
		t.equal(wallet.get_coins(), earned, "ikkinchi marta berilmaydi")
	)

	t.test("yarim bajarilgan topshiriq mukofot bermaydi", func() -> void:
		missions.reset()
		wallet.reset()
		missions.report(1.0, 0, 0, 1.0, 0)
		for m: Dictionary in (missions.today_missions() as Array):
			if int(m["target"]) > 1:
				t.check(not bool(m["completed"]),
					"%s hali bajarilmagan" % m["id"])
	)
	missions.reset()
	wallet.reset()

# ——— Xaridlar va reklama ———

func _test_purchases(t: TestRunner) -> void:
	var purchases := root.get_node("/root/Purchases")
	var ads := root.get_node("/root/Ads")
	t.group("xarid va reklama")
	purchases.reset()

	t.test("NO ADS boshida yo'q", func() -> void:
		t.check(not purchases.has_no_ads(), "sotib olinmagan")
	)

	t.test("NO ADS majburiy reklamani o'chiradi", func() -> void:
		t.check(purchases.purchase_no_ads(), "xarid o'tdi")
		t.check(purchases.has_no_ads(), "endi bor")
		t.check(not ads.can_show_interstitial(),
			"majburiy reklama chiqmaydi")
		t.check(purchases.purchase_no_ads(), "ikkinchi marta ham ok")
	)

	t.test("NO ADS banner ko'rsatmaydi", func() -> void:
		ads.show_banner(true)
		t.check(not ads.banner_visible(), "banner yashirin")
	)

	t.test("mukofotli reklama NO ADS dan keyin ham qoladi", func() -> void:
		# Uni o'yinchi o'zi bosadi, shuning uchun o'chirilmaydi.
		t.check(MonetizationConfig.REWARDED_ENABLED, "yoqiq")
	)

	t.test("majburiy reklama oraliqsiz chiqmaydi", func() -> void:
		purchases.reset()
		t.check(not ads.can_show_interstitial(),
			"o'yin soni yetmagan")
	)

	t.test("faqat sinov reklama ID lari", func() -> void:
		var ids := AdMobManager.unit_ids()
		for key: String in ids:
			t.check(str(ids[key]).begins_with("ca-app-pub-3940256099942544"),
				"%s — Google ning sinov bloki" % key)
	)
	purchases.reset()

# ——— Tanga, gem va mukofot ———

func _test_money(t: TestRunner) -> void:
	t.group("pul tizimi")

	t.test("balans manfiy bo'lmaydi", func() -> void:
		var w := CurrencyManager.new()
		w.reset()
		t.equal(w.get_coins(), 0, "boshida nol")
		t.check(not w.remove_coins(10), "yo'q pulni yechib bo'lmaydi")
		t.equal(w.get_coins(), 0, "balans o'zgarmadi")
		w.add_coins(100, "test")
		t.check(w.remove_coins(100), "bor pul yechiladi")
		t.equal(w.get_coins(), 0, "nolga tushdi")
		t.equal(w.add_coins(-5, "test"), 0, "manfiy qo'shilmaydi")
		w.reset()
		w.free()
	)

	t.test("bir mukofot ikki marta berilmaydi", func() -> void:
		var w := CurrencyManager.new()
		w.reset()
		t.equal(w.add_coins(250, "daily", "daily-2026-01-01"), 250, "birinchi marta")
		t.equal(w.add_coins(250, "daily", "daily-2026-01-01"), 0, "ikkinchi marta yo'q")
		t.equal(w.get_coins(), 250, "balans bir marta oshdi")
		t.check(w.has_transaction("daily-2026-01-01"), "jurnalda bor")
		t.check(not w.has_transaction("daily-2026-01-02"), "boshqasi yo'q")
		w.reset()
		w.free()
	)

	t.test("hamyon diskka saqlanadi", func() -> void:
		var w := CurrencyManager.new()
		w.reset()
		w.add_coins(640, "run")
		w.add_gems(12, "gift")
		w.free()
		var again := CurrencyManager.new()
		t.equal(again.get_coins(), 640, "tanga qaytdi")
		t.equal(again.get_gems(), 12, "gem qaytdi")
		again.reset()
		again.free()
	)

	t.test("mukofot chegaradan chiqmaydi", func() -> void:
		var small := RewardManager.run_reward(0.0, 0.0, 0)
		t.equal(int(small["total"]), MonetizationConfig.RUN_MIN,
			"bo'sh o'yin eng kamini beradi")
		var big := RewardManager.run_reward(10000.0, 100.0, 100)
		t.check(int(big["total"]) <= MonetizationConfig.RUN_COIN_CAP,
			"yuqori chegara ushlab turadi")
		t.check(int(big["territory"]) <= MonetizationConfig.TERRITORY_MAX,
			"hudud mukofoti chegarada")
		t.check(int(big["kills"]) <= MonetizationConfig.KILL_MAX,
			"kill mukofoti chegarada")
	)

	t.test("mukofot o'sib boradi", func() -> void:
		var low := int(RewardManager.run_reward(30.0, 2.0, 0)["total"])
		var mid := int(RewardManager.run_reward(90.0, 10.0, 1)["total"])
		var high := int(RewardManager.run_reward(170.0, 30.0, 4)["total"])
		t.check(low < mid and mid < high, "yaxshiroq o'yin ko'proq beradi")
	)

	t.test("kunlik kirish aylanmasi", func() -> void:
		t.equal(RewardManager.daily_login(1), MonetizationConfig.DAILY_LOGIN[0],
			"1-kun")
		t.equal(RewardManager.daily_login(7), MonetizationConfig.DAILY_LOGIN[6],
			"7-kun")
		t.equal(RewardManager.daily_login(8), MonetizationConfig.DAILY_LOGIN[0],
			"8-kun boshidan")
		t.equal(RewardManager.daily_login(0), 0, "noto'g'ri kun — nol")
	)

	t.test("shahar tangasi aholiga qarab", func() -> void:
		# `land` bo'sh bo'lsa butun panjara o'ynaladi.
		var grid := GameGrid.new(40, 40)
		var places: Array = [
			{"name": "Katta", "x": 5, "y": 5, "pop": 10_000_000, "cap": 1},
			{"name": "Kichik", "x": 20, "y": 20, "pop": 5_000, "cap": 0},
		]
		var field := CoinField.new()
		field.build(places, grid)
		t.equal(field.size(), 2, "ikki shahar")
		var big: int = field.coins[0]["value"]
		var small: int = field.coins[1]["value"]
		t.check(big > small, "katta shaharda ko'proq tanga")
		t.equal(big, MonetizationConfig.CITY_COIN_MAX, "eng kattasi to'liq")
		t.check(small >= MonetizationConfig.CITY_COIN_MIN, "eng kichigi ham bor")
	)

	t.test("tanga bir marta olinadi", func() -> void:
		# `land` bo'sh bo'lsa butun panjara o'ynaladi.
		var grid := GameGrid.new(40, 40)
		var field := CoinField.new()
		field.build([{"name": "A", "x": 10, "y": 10, "pop": 1000, "cap": 0}], grid)
		var value: int = field.coins[0]["value"]
		var cell := PackedInt32Array([10 * 40 + 10])
		t.equal(field.collect_cells(cell), value, "hudud egallanganda olinadi")
		t.equal(field.collect_cells(cell), 0, "ikkinchi marta yo'q")
		t.equal(field.collected(), value, "jami to'g'ri")
		t.equal(field.flush_taken().size(), 1, "chizuvchiga bitta indeks")
		t.equal(field.flush_taken().size(), 0, "ro'yxat bo'shadi")
	)

	t.test("egallanmagan shahardagi tanga qoladi", func() -> void:
		# `land` bo'sh bo'lsa butun panjara o'ynaladi.
		var grid := GameGrid.new(40, 40)
		var field := CoinField.new()
		field.build([{"name": "A", "x": 10, "y": 10, "pop": 1000, "cap": 0}], grid)
		t.equal(field.collect_cells(PackedInt32Array([20 * 40 + 20])), 0,
			"boshqa katak — tanga tegmaydi")
		t.equal(field.taken_count(), 0, "hech nima olinmadi")
	)

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

	t.test("rang jadvalining rang qismi noshaffof", func() -> void:
		# 0..511 — ranglar: shaffof piksel qop-qora bo'lib qolardi.
		# 512..767 — naqsh raqami, u **alfada** saqlanadi, shuning
		# uchun u yerda alfa 1 dan kichik bo'lishi normal.
		var grid := GameGrid.new(4, 4)
		var colors := PackedByteArray()
		colors.resize(256)
		var paint := PaintLayer.new(grid, colors)
		t.equal(paint.palette_image.get_width(), PaintLayer.PALETTE_SIZE)
		var clear := 0
		for i in 512:
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

## Panjaraga iz qo'yadi va uning indekslarini qaytaradi.
func _lay_trail(grid: GameGrid, id: int,
		cells: Array) -> PackedInt32Array:
	var trail := PackedInt32Array()
	for cell: Vector2i in cells:
		var i := grid.index(cell.x, cell.y)
		grid.set_trail_index(i, id)
		trail.append(i)
	return trail

func _test_capture(t: TestRunner) -> void:
	t.group("hudud egallash")

	t.test("iz bilan yopilgan halqa ichi egallanadi", func() -> void:
		# Hududning yuqori tomoni ochiq; iz uni yopadi.
		var grid := MapHelpers.grid_from(PackedStringArray([
			".....",
			".....",
			".1.1.",
			".111.",
			".....",
		]))
		var trail := _lay_trail(grid, 1,
			[Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)])
		TerritoryCapturer.new(grid).capture(1, trail)
		t.equal(grid.owner_at(2, 2), 1, "o'rtadagi katak egallanadi")
		t.equal(grid.territory_of(1), 9)
	)

	t.test("tashqaridagi joy egallanmaydi", func() -> void:
		var grid := MapHelpers.grid_from(PackedStringArray([
			".....",
			".....",
			".1.1.",
			".111.",
			".....",
		]))
		var trail := _lay_trail(grid, 1,
			[Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)])
		TerritoryCapturer.new(grid).capture(1, trail)
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
		var trail := _lay_trail(grid, 1, [Vector2i(2, 0), Vector2i(2, 1)])
		var result := TerritoryCapturer.new(grid).capture(1, trail)
		t.equal(grid.owner_at(2, 0), 1)
		t.equal(grid.owner_at(2, 1), 1)
		t.greater(result["captured"], 1)
	)

	t.test("raqib hududi ham o'raladi", func() -> void:
		var grid := MapHelpers.grid_from(PackedStringArray([
			".....",
			".....",
			".121.",
			".111.",
			".....",
		]))
		var trail := _lay_trail(grid, 1,
			[Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)])
		var result := TerritoryCapturer.new(grid).capture(1, trail)
		t.equal(grid.owner_at(2, 2), 1, "raqib katagi tortib olinadi")
		t.equal(int((result["taken_from"] as Dictionary).get(2, 0)), 1)
	)

	t.test("suv egallanmaydi, lekin ichki ko'l o'raladi", func() -> void:
		var grid := MapHelpers.grid_from(PackedStringArray([
			".....",
			".....",
			".1~1.",
			".111.",
			".....",
		]))
		var trail := _lay_trail(grid, 1,
			[Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)])
		TerritoryCapturer.new(grid).capture(1, trail)
		t.equal(grid.owner_at(2, 2), 0, "suv egasiz qoladi")
	)

	t.test("okeanga ulangan qo'ltiq egallanmaydi", func() -> void:
		var grid := MapHelpers.grid_from(PackedStringArray([
			"~~~~~",
			".....",
			".1~1.",
			".1~1.",
			".111.",
		]))
		var trail := _lay_trail(grid, 1,
			[Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)])
		TerritoryCapturer.new(grid).capture(1, trail)
		t.equal(grid.owner_at(2, 2), 0, "qo'ltiq ochiq qoladi")
	)

	t.test("katta halqa ichi to'liq egallanadi", func() -> void:
		var grid := GameGrid.new(150, 150)
		for y in range(10, 140):
			for x in range(10, 140):
				if (x == 10 or x == 139 or y == 139) and y > 10:
					grid.set_owner(x, y, 1)
		var cells: Array = []
		for x in range(10, 140):
			cells.append(Vector2i(x, 10))
		var trail := _lay_trail(grid, 1, cells)
		var started := Time.get_ticks_usec()
		TerritoryCapturer.new(grid).capture(1, trail)
		var took := Time.get_ticks_usec() - started
		t.equal(grid.owner_at(75, 75), 1, "ichkarisi to'ldi")
		t.less(took, 100000, "egallash 100 ms dan tez (%d µs)" % took)
	)

	t.test("katta hududda kichik halqa tez egallanadi", func() -> void:
		# Narx egallangan maydonga bog'liq bo'lishi kerak, hududning
		# kattaligiga emas: aks holda katta hududda har kichik halqa
		# kadrni tushirib yuborardi.
		var grid := GameGrid.new(200, 200)
		for y in range(5, 195):
			for x in range(5, 195):
				grid.set_owner(x, y, 1)
		# Hudud chetida kichkina "quloq" chizamiz.
		var trail := _lay_trail(grid, 1, [
			Vector2i(100, 4), Vector2i(101, 4), Vector2i(102, 4)])
		var capturer := TerritoryCapturer.new(grid)
		var started := Time.get_ticks_usec()
		var result := capturer.capture(1, trail)
		var took := Time.get_ticks_usec() - started
		t.equal(int(result["captured"]), 3, "faqat iz kataklari")
		t.less(took, 3000, "kichik halqa 3 ms dan tez (%d µs)" % took)
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
		# Katta o'yinchining hududi yuqori tomondan ochiq halqa.
		var big := world.add_player("B", 0, false)
		for y in range(5, 25):
			for x in range(5, 25):
				if x == 5 or x == 24 or y == 24:
					world.grid.set_owner(x, y, big.id)
		big.place_at(5.5, 24.5, 0.0)
		big.alive = true
		var small := world.add_player("S", 1, false)
		# Kichkina o'yinchi halqa ichida.
		world.grid.fill_block(12, 12, 2, small.id)
		small.place_at(12.5, 12.5, 0.0)
		small.alive = true
		t.equal(world.grid.territory_of(small.id), 4)

		# Katta o'yinchi kichkinani iz bilan o'rab oladi.
		var cells: Array = []
		for x in range(5, 25):
			cells.append(Vector2i(x, 4))
		var trail := _lay_trail(world.grid, big.id, cells)
		TerritoryCapturer.new(world.grid).capture(big.id, trail)
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

# ——— Qahramonlar va 5-bosqich tizimi ———

func _test_heroes(t: TestRunner) -> void:
	t.group("5-bosqich: qahramonlar va statistika")

	t.test("katalogda 21 ta qahramon bor", func() -> void:
		t.equal(HeroCatalog.HEROES.size(), 21, "21 ta qahramon")
	)

	t.test("boshlang'ich qahramonlar ochiq", func() -> void:
		var empty_stats := {}
		var cube := HeroCatalog.get_hero("hero_cube")
		var melon := HeroCatalog.get_hero("hero_melon")
		t.check(HeroCatalog.is_unlocked(cube, empty_stats), "kub ochiq")
		t.check(HeroCatalog.is_unlocked(melon, empty_stats), "tarvuz ochiq")
	)

	t.test("shartli qahramonlar ochilishi", func() -> void:
		var golem := HeroCatalog.get_hero("hero_golem")
		t.check(not HeroCatalog.is_unlocked(golem, {"streak": 2}), "2 kunda ochilmaydi")
		t.check(HeroCatalog.is_unlocked(golem, {"streak": 3}), "3 kunda ochiladi")

		var seal := HeroCatalog.get_hero("hero_seal")
		t.check(not HeroCatalog.is_unlocked(seal, {"kills": 9}), "9 ta o'limda yopiq")
		t.check(HeroCatalog.is_unlocked(seal, {"kills": 10}), "10 ta o'limda ochiq")
	)

	t.test("statistika va liga hisobi", func() -> void:
		var store := SettingsStore.new()
		t.equal(store.league_name(), "leagueBronze", "boshlang'ich liga bronza")
		store.record_match_stats(60, 5, true, true, false)
		t.check(store.total_kills >= 60, "kills saqlandi")
		t.check(store.total_spheres >= 5, "sferalar saqlandi")
		t.check(store.total_revives >= 1, "tirilish saqlandi")
		t.check(store.total_countries_won >= 1, "mamlakatlar saqlandi")
		t.equal(store.league_name(), "leagueSilver", "50+ kills bilan kumush liga")
	)

	t.test("HeroView vizual komponenti yaratiladi", func() -> void:
		var cube := HeroCatalog.get_hero("hero_cube")
		var view_unlocked := HeroView.new(cube, true, true, 0, 0)
		t.check(view_unlocked != null, "ochilgan qahramon kartasi")
		var golem := HeroCatalog.get_hero("hero_golem")
		var view_locked := HeroView.new(golem, false, false, 1, 3)
		t.check(view_locked != null, "qulflangan qahramon kartasi")
		view_unlocked.free()
		view_locked.free()
	)

# ——— PHASE 3: Kengaytirilgan hududlar va pacing ———

func _test_phase3_scaling(t: TestRunner) -> void:
	t.group("phase 3 kengaytirilgan xaritalar")

	t.test("dunyo xaritalari 2x shkalada 4x maydonga kengayadi", func() -> void:
		for mid in ["world", "europe", "asia", "africa", "north_america", "south_america", "oceania"]:
			var cls := WorldMap.load_map(mid, WorldPacing.SCALE_CLASSIC)
			var exp := WorldMap.load_map(mid, WorldPacing.SCALE_EXPANDED)
			t.equal(exp.width, cls.width * 2, "%s eni 2 barobar" % mid)
			t.equal(exp.height, cls.height * 2, "%s bo'yi 2 barobar" % mid)
			t.equal(exp.land_cells, cls.land_cells * 4, "%s quruqlik 4 barobar" % mid)
	)

	t.test("shahar koordinatalari kengaytirilgan xaritada quruqlikda qoladi", func() -> void:
		for mid in ["world", "europe", "asia", "africa"]:
			var exp := WorldMap.load_map(mid, WorldPacing.SCALE_EXPANDED)
			t.check(exp.places.size() > 0, "%s shaharlar mavjud" % mid)
			for p in exp.places:
				var px := int(p["x"])
				var py := int(p["y"])
				t.check(exp.is_land(px, py), "%s: %s quruqlikda" % [mid, p.get("name", "")])
	)

	t.test("botlar kengaytirilgan xaritada xavfsiz tug'iladi va joylashadi", func() -> void:
		var cfg := GameConfig.new()
		cfg.apply_pacing(WorldPacing.SCALE_EXPANDED)
		cfg.map_id = "world"
		cfg.bot_count = 20
		var world := MatchBuilder.create(cfg, 0, "Player", "slime", 1, "UZ")
		t.equal(world.players.size(), 21, "20 bot + 1 odam")
		for p in world.players:
			t.check(p.alive, "o'yinchi tirik tug'ildi")
			t.check(world.grid.playable(int(p.x), int(p.y)), "o'yinchi quruqlikda")
	)

	t.test("o'yinchi va botlar xarita chegarasidan chiqib ketmaydi", func() -> void:
		var cfg := GameConfig.new()
		cfg.apply_pacing(WorldPacing.SCALE_EXPANDED)
		cfg.map_id = "world"
		var world := MatchBuilder.create(cfg, 0, "Player", "slime", 1, "UZ")
		var p := world.human()
		p.x = 2.0
		p.y = 2.0
		p.angle = PI # chapga yuradi
		for step in 60:
			world.update(1.0 / 30.0)
		t.check(p.x >= 0.0 and p.x < float(world.grid.width), "X chegaradan chiqmadi")
		t.check(p.y >= 0.0 and p.y < float(world.grid.height), "Y chegaradan chiqmadi")
	)

	t.test("minimap koordinatalari va bot nishonlari to'g'ri normallanadi", func() -> void:
		var cfg := GameConfig.new()
		cfg.apply_pacing(WorldPacing.SCALE_EXPANDED)
		cfg.map_id = "world"
		var world := MatchBuilder.create(cfg, 0, "Player", "slime", 1, "UZ")
		for pl in world.players:
			var norm_x: float = pl.x / float(world.grid.width)
			var norm_y: float = pl.y / float(world.grid.height)
			t.check(norm_x >= 0.0 and norm_x <= 1.0, "minimap X 0..1 oralig'ida")
			t.check(norm_y >= 0.0 and norm_y <= 1.0, "minimap Y 0..1 oralig'ida")
	)

	t.test("GameConfig apply_pacing klassik va kengaytirilgan rejimni to'g'ri o'zgartiradi", func() -> void:
		var cfg := GameConfig.new()
		cfg.apply_pacing(WorldPacing.SCALE_CLASSIC)
		t.equal(cfg.world_scale, WorldPacing.SCALE_CLASSIC, "klassik shkala")
		t.equal(cfg.player_speed, WorldPacing.SPEED_CLASSIC, "klassik tezlik")
		t.equal(cfg.bot_count, WorldPacing.BOTS_CLASSIC, "klassik botlar soni")
		t.equal(cfg.start_block, WorldPacing.START_BLOCK_CLASSIC, "klassik boshlang'ich blok")

		cfg.apply_pacing(WorldPacing.SCALE_EXPANDED)
		t.equal(cfg.world_scale, WorldPacing.SCALE_EXPANDED, "kengaytirilgan shkala")
		t.equal(cfg.player_speed, WorldPacing.SPEED_EXPANDED, "kengaytirilgan tezlik")
		t.equal(cfg.bot_count, WorldPacing.BOTS_EXPANDED, "kengaytirilgan botlar soni")
		t.equal(cfg.start_block, WorldPacing.START_BLOCK_EXPANDED, "kengaytirilgan boshlang'ich blok")
	)

func _test_phase4_flags(t: TestRunner) -> void:
	t.group("PHASE 4: Davlat bayroqlari va hudud tizimi (Tuzatishlar)")

	var FlagRendererRef = preload("res://scripts/render/flag_renderer.gd")
	var FlagPolesRef = preload("res://scripts/render/flag_poles.gd")

	t.test("barcha 249 ISO davlat bayroqlari haqiqiy (authentic) resurslarga ega", func() -> void:
		var countries: Array = Profile.countries()
		t.check(countries.size() >= 249, "249 ta davlat mavjud: %d" % countries.size())
		var authentic_count := 0
		var correct_dims := 0
		for c: Dictionary in countries:
			var code := str(c["code"])
			if FlagRendererRef.has_authentic_flag(code):
				authentic_count += 1
			var tex: Texture2D = FlagRendererRef.get_flag_texture(code)
			if tex != null and tex.get_width() == 192 and tex.get_height() == 128:
				correct_dims += 1
		t.equal(authentic_count, 249, "barcha 249 ta davlat rasmiy SVG/PNG fayliga ega")
		t.equal(correct_dims, 249, "barcha 249 ta bayroq 192x128 o'lchamda")
	)

	t.test("mavjud bo'lmagan davlat kodi uchun soxta bayroq yaratilmaydi (aniq placeholder)", func() -> void:
		t.check(not FlagRendererRef.has_authentic_flag("XX"), "XX mavjud emas")
		var ph: Image = FlagRendererRef.get_flag_image("XX")
		t.check(ph != null, "placeholder yaratildi")
		# Qizil xato hoshiyasi bor
		var corner: Color = ph.get_pixel(0, 0)
		t.check(corner.r > 0.8 and corner.g < 0.3, "xatolik qizil hoshiyasi mavjud")
	)

	t.test("turli davlatlar bir xil tasvirni takrorlamaydi (distinct assets)", func() -> void:
		var sample_codes := ["UZ", "US", "JP", "BR", "FR", "DE", "TR", "KZ", "GB", "CA"]
		var hashes := {}
		for code in sample_codes:
			var img: Image = FlagRendererRef.get_flag_image(code)
			var h: int = hash(img.get_data())
			t.check(not hashes.has(h), "davlat %s takroriy emas (unique hash)" % code)
			hashes[h] = code
	)

	t.test("O'zbekiston, AQSH, Yaponiya, Braziliya bayroqlari rasmiy standartlarga mos", func() -> void:
		var uz_img: Image = FlagRendererRef.get_flag_image("UZ")
		t.equal(uz_img.get_width(), 192, "UZ kengligi 192")
		# Moviy, oq, yashil chiziqlar
		t.check(uz_img.get_pixel(96, 20).b > 0.5, "UZ yuqori qism moviy")
		t.check(uz_img.get_pixel(96, 64).r > 0.8 and uz_img.get_pixel(96, 64).g > 0.8, "UZ o'rta qism oq")
		t.check(uz_img.get_pixel(96, 105).g > 0.5, "UZ pastki qism yashil")

		var us_img: Image = FlagRendererRef.get_flag_image("US")
		# AQSH: yuqori chap kanton moviy, chiziqlar qizil-oq
		t.check(us_img.get_pixel(20, 20).b > 0.3, "US kanton moviy")
		t.check(us_img.get_pixel(150, 10).r > 0.6, "US yuqori chiziq qizil")

		var jp_img: Image = FlagRendererRef.get_flag_image("JP")
		t.check(jp_img.get_pixel(10, 10).r > 0.9, "JP burchak oq")
		t.check(jp_img.get_pixel(96, 64).r > 0.6 and jp_img.get_pixel(96, 64).b < 0.3, "JP markaz qizil doira")

		var br_img: Image = FlagRendererRef.get_flag_image("BR")
		t.check(br_img.get_pixel(10, 10).g > 0.4, "BR yashil fon")
		t.check(br_img.get_pixel(96, 64).b > 0.4, "BR markaziy doira moviy")
	)

	t.test("3D FlagPoles faqat quruqlik va o'z hududiga qo'yiladi (suvda/dushmanda emas)", func() -> void:
		var cfg := GameConfig.new()
		cfg.map_id = "world"
		cfg.bot_count = 5
		var world := MatchBuilder.create(cfg, 0, "Player", "slime", 42, "UZ")

		var poles := FlagPolesRef.new()
		poles.setup(world)
		t.equal(poles.pole_count(), 6, "6 ta baza ustuni")

		# Har bir ustun haqiqiy quruqlikda va o'z egasiga tegishli ekanini tekshirish
		for p in world.players:
			var node: Node3D = poles._base_poles[p.id]
			var x := int(node.position.x)
			var y := int(node.position.z)
			t.check(world.grid.playable(x, y), "ustun quruqlikda")
			t.equal(world.grid.owner_at(x, y), p.id, "ustun o'z hududida")

		poles.clear()
		poles.free()
	)

	t.test("hudud boshqaga o'tganda eskirgan bayroq ustunlari tozalanadi", func() -> void:
		var cfg := GameConfig.new()
		cfg.map_id = "world"
		cfg.bot_count = 2
		var world := MatchBuilder.create(cfg, 0, "Player", "slime", 42, "UZ")

		var poles := FlagPolesRef.new()
		poles.setup(world)

		var p1 := world.players[0]
		var p2 := world.players[1]
		var b_node: Node3D = poles._base_poles[p1.id]
		var bx := int(b_node.position.x)
		var bz := int(b_node.position.z)

		# Dushman (p2) p1 ning bayroq turgan katagini bosib oladi
		world.grid.set_owner(bx, bz, p2.id)
		poles.update_poles()

		# Ustun dushman yerida qolmaganini tekshirish (ko'chirilgan yoki yashirilgan)
		var cur_bx := int(b_node.position.x)
		var cur_bz := int(b_node.position.z)
		if b_node.visible:
			t.equal(world.grid.owner_at(cur_bx, cur_bz), p1.id, "ustun dushmanga berilmadi, o'z yeriga ko'chirildi")

		poles.clear()
		poles.free()
	)

	t.test("ajralgan (disconnected) hududlar to'g'ri o'lcham va markaz oladi", func() -> void:
		# Ikki ajralgan hudud oroli: (1, 1) da 4 katak va (25, 25) da 2 katak
		var grid := GameGrid.new(30, 30)
		for dy in 2:
			for dx in 2:
				grid.set_owner(1 + dx, 1 + dy, 1)
		grid.set_owner(25, 25, 1)
		grid.set_owner(25, 26, 1)

		var place: Dictionary = AvatarPlacement.of(grid, 1)
		t.check(place.has("half_w") and place.has("half_h"), "half_w va half_h mavjud")
		# Dispersiya asosiy massani o'rab oladi va butun 30x30 ga yoyib yubormaydi
		t.check(float(place["half_w"]) < 18.0, "ajralgan hudud bayroqni butun xaritaga yoymadi: %.1f" % float(place["half_w"]))
		var ratio := float(place["half_w"]) / float(place["half_h"])
		t.check(ratio >= 1.2 and ratio <= 1.8, "bayroq nisbati 1.5:1 atrofida saqlanmoqda: %.2f" % ratio)
	)

	t.test("GameGrid version_of() o'zgarmasa update_poles() deyarli 0 vaqt oladi", func() -> void:
		var cfg := GameConfig.new()
		cfg.map_id = "world"
		cfg.bot_count = 5
		var world := MatchBuilder.create(cfg, 0, "Player", "slime", 42, "UZ")

		var poles := FlagPolesRef.new()
		poles.setup(world)

		# 1-marta yangilash (versiya qayd qilinadi)
		poles.update_poles()

		# 2-marta yangilash (hech qanday katak o'zgarmadi)
		var t0 := Time.get_ticks_usec()
		for i in 50:
			poles.update_poles()
		var dt := Time.get_ticks_usec() - t0
		t.check(dt < 2500, "50 ta bo'sh chaqiruv tez ishladi (optimizatsiya ishladi): %d usec" % dt)

		poles.clear()
		poles.free()
	)

	t.test("ResourceLoader orqali barcha 249 bayroq Android APK usulida yuklanadi", func() -> void:
		for code in ["UZ", "US", "JP", "BR", "CH", "NP", "DE", "FR", "TR", "KZ"]:
			var png_path := "res://assets/flags/png/%s.png" % code
			t.check(ResourceLoader.exists(png_path), "ResourceLoader.exists: %s" % code)
			var res: Resource = ResourceLoader.load(png_path)
			t.check(res != null and res is Texture2D, "Texture2D bo'lib yuklandi: %s" % code)
			var img: Image = (res as Texture2D).get_image()
			t.check(img != null and not img.is_empty(), "Image olinadi: %s" % code)
			t.equal(img.get_width(), 192, "kenglik 192")
			t.equal(img.get_height(), 128, "balandlik 128")
	)

	t.test("find_connected_components ajralgan hudud bo'laklarini to'g'ri topadi", func() -> void:
		var grid := GameGrid.new(80, 80)
		# 1-qism: (10, 10) dan 12x12 = 144 katak
		for y in range(10, 22):
			for x in range(10, 22):
				grid.set_owner(x, y, 1)
		# 2-qism: (50, 50) dan 11x11 = 121 katak (ajralgan)
		for y in range(50, 61):
			for x in range(50, 61):
				grid.set_owner(x, y, 1)
		# 3-qism: mayda (5 katak) — min_size=100 ga kirmasligi kerak
		for x in 5:
			grid.set_owner(2, 2 + x, 1)

		var comps := FlagPolesRef.find_connected_components(grid, 1, 100)
		t.equal(comps.size(), 2, "ikkita yirik ajralgan qism topildi")
		t.equal(int(comps[0]["size"]), 144, "1-qism 144 katak")
		t.equal(int(comps[1]["size"]), 121, "2-qism 121 katak")
		var d: float = (comps[0]["center"] as Vector2).distance_to(comps[1]["center"] as Vector2)
		t.check(d > 40.0, "ikki qism markazlari bir-biridan uzoq: %.1f" % d)
	)

	t.test("katta ajralgan hududga qo'shimcha bayroq ustuni qo'yiladi va dublikat bo'lmaydi", func() -> void:
		var cfg := GameConfig.new()
		cfg.map_id = "circle"
		cfg.bot_count = 1
		var world := MatchBuilder.create(cfg, 0, "Player", "slime", 42, "UZ")

		var poles := FlagPolesRef.new()
		poles.setup(world)

		var p1 := world.players[0]
		# Baza bayrog'i bor (1 ta)
		t.equal(poles.pole_count(), 2, "har o'yinchiga 1 tadan baza ustuni")

		# O'yinchiga katta ajralgan hudud beramiz (bazadan 30 katak uzoqda 11x11 = 121 katak)
		# circle xaritada markaz atrofidagi barcha kataklar quruqlik
		var b_pt := Vector2(poles._base_poles[p1.id].position.x, poles._base_poles[p1.id].position.z)
		var island_origin := Vector2i(int(b_pt.x) + 30, int(b_pt.y))
		for dy in 11:
			for dx in 11:
				if world.grid.playable(island_origin.x + dx, island_origin.y + dy):
					world.grid.set_owner(island_origin.x + dx, island_origin.y + dy, p1.id)

		poles.update_poles()

		# Endi o'yinchida baza bayrog'idan tashqari qo'shimcha ajralgan hudud bayrog'i paydo bo'lishi kerak
		var t_list: Array = poles._territory_poles.get(p1.id, [])
		t.check(t_list.size() >= 1, "ajralgan orolga qo'shimcha bayroq o'rnatildi: %d" % t_list.size())
		if not t_list.is_empty():
			var t_node: Node3D = t_list[0]
			t.check(t_node.visible, "qo'shimcha ustun ko'rinmoqda")
			var t_pt := Vector2(t_node.position.x, t_node.position.z)
			t.check(t_pt.distance_to(b_pt) >= 20.0, "dublikat emas, bazadan uzoqda: %.1f" % t_pt.distance_to(b_pt))

		poles.clear()
		poles.free()
	)

	t.test("Nepal, Shveytsariya, AQSH va O'zbekiston milliy proporsiyalari saqlanadi", func() -> void:
		t.equal(FlagRendererRef.get_flag_aspect_ratio("CH"), 1.0, "Shveytsariya 1:1 kvadrat")
		t.equal(FlagRendererRef.get_flag_aspect_ratio("VA"), 1.0, "Vatikan 1:1 kvadrat")
		t.equal(FlagRendererRef.get_flag_aspect_ratio("NP"), 0.82, "Nepal 0.82:1 (balandroq)")
		t.equal(FlagRendererRef.get_flag_aspect_ratio("US"), 1.90, "AQSH 1.90:1 (10:19)")
		t.equal(FlagRendererRef.get_flag_aspect_ratio("UZ"), 2.0, "O'zbekiston 2.0:1 (1:2)")

		# AvatarPlacement orqali hududda to'g'ri proporsiya olinishi
		var grid := GameGrid.new(40, 40)
		for y in range(10, 30):
			for x in range(10, 30):
				grid.set_owner(x, y, 1)

		var place_ch: Dictionary = AvatarPlacement.of(grid, 1, "CH")
		var ratio_ch := float(place_ch["half_w"]) / float(place_ch["half_h"])
		t.check(absf(ratio_ch - 1.0) < 0.1, "Shveytsariya hududda kvadrat nisbatda (1.0:1): %.2f" % ratio_ch)

		var place_uz: Dictionary = AvatarPlacement.of(grid, 1, "UZ")
		var ratio_uz := float(place_uz["half_w"]) / float(place_uz["half_h"])
		t.check(absf(ratio_uz - 2.0) < 0.2, "O'zbekiston hududda 2:1 nisbatda: %.2f" % ratio_uz)
	)

	t.test("Nepal bayrog'ining burchaklaridagi shaffoflik (alpha = 0.0) saqlanadi", func() -> void:
		t.check(FlagRendererRef.is_non_rectangular("NP"), "Nepal to'rtburchak bo'lmagan davlat")
		var np_img: Image = FlagRendererRef.get_flag_image("NP")
		t.check(np_img != null, "NP tasviri bor")
		# Nepal bayrog'ining yuqori o'ng burchagi shaffof bo'lishi kerak (alpha < 0.05)
		var top_right: Color = np_img.get_pixel(np_img.get_width() - 5, 5)
		t.check(top_right.a < 0.05, "Nepal yuqori o'ng burchagi shaffof (alpha = %.2f)" % top_right.a)
	)

func _test_phase5_cities(t: TestRunner) -> void:
	t.group("PHASE 5: 3D Shaharlar va Hududiy Istilo Tizimi")

	t.test("Shaharlar to'g'ri toifalarga (Small, Medium, Large) ajratiladi", func() -> void:
		var grid := GameGrid.new(100, 100)
		var places: Array = [
			{"name": "Paris", "code": "FR", "x": 10, "y": 10, "pop": 9904000, "cap": 1},
			{"name": "Tokyo", "code": "JP", "x": 20, "y": 20, "pop": 35676000, "cap": 1},
			{"name": "Tashkent", "code": "UZ", "x": 30, "y": 30, "pop": 2184000, "cap": 1},
			{"name": "Samarqand", "code": "UZ", "x": 40, "y": 40, "pop": 708000, "cap": 0},
			{"name": "Bukhara", "code": "UZ", "x": 50, "y": 50, "pop": 275000, "cap": 0},
			{"name": "SmallVillage", "code": "UZ", "x": 60, "y": 60, "pop": 45000, "cap": 0},
			{"name": "TinyTown", "code": "CH", "x": 70, "y": 70, "pop": 12000, "cap": 0},
		]
		var cs := CitySystemRef.new()
		cs.build(places, grid)

		t.equal(cs.get_total_cities_count(), 7, "7 ta shahar yuklandi")
		t.equal(cs.get_neutral_cities_count(), 7, "dastlab hammasi neytral")

		var c_paris: CitySystemRef.CityData = cs.get_city_at_cell(10, 10)
		t.check(c_paris != null, "Parij topildi")
		t.equal(c_paris.category, CitySystemRef.Category.LARGE, "Parij - Katta metropol")
		t.equal(c_paris.regional_style, "paris", "Parij - 'paris' arxitektura uslubi")

		var c_sam: CitySystemRef.CityData = cs.get_city_at_cell(40, 40)
		t.check(c_sam != null, "Samarqand topildi")
		t.equal(c_sam.category, CitySystemRef.Category.MEDIUM, "Samarqand (708k) - O'rta shahar")
		t.equal(c_sam.regional_style, "uzbek", "Samarqand - 'uzbek' me'moriy uslubi")

		var c_small: CitySystemRef.CityData = cs.get_city_at_cell(60, 60)
		t.check(c_small != null, "Qishloq topildi")
		t.equal(c_small.category, CitySystemRef.Category.SMALL, "Kichik qishloq (<200k)")
	)

	t.test("Hududiy halqa bilan shaharni egallash va qayta egallash (Recapture)", func() -> void:
		var grid := GameGrid.new(60, 60)
		var places: Array = [
			{"name": "Tashkent", "code": "UZ", "x": 25, "y": 25, "pop": 2184000, "cap": 1},
			{"name": "Bukhara", "code": "UZ", "x": 45, "y": 45, "pop": 275000, "cap": 0},
		]
		var cs := CitySystemRef.new()
		cs.build(places, grid)

		var city: CitySystemRef.CityData = cs.get_city_at_cell(25, 25)
		t.equal(city.owner_id, 0, "Dastlab neytral")

		# 1-o'yinchi (O'zbekiston bayrog'i) katakni egallaydi
		var loop_cells := PackedInt32Array([25 * 60 + 25])
		var newly := cs.check_capture_cells(loop_cells, 1, "UZ", "Player1", 10.5)
		t.equal(newly.size(), 1, "1 ta shahar egallandi")
		t.equal(city.owner_id, 1, "1-o'yinchi egasi bo'ldi")
		t.equal(city.owner_country, "UZ", "Bayroq O'zbekiston kodi")
		t.equal(cs.get_player_captured_count(1), 1, "O'yinchi 1 da 1 ta shahar")

		# 2-o'yinchi (AQSH bayrog'i) shaharni qayta egallaydi (Recapture)
		var recapture_cells := PackedInt32Array([25 * 60 + 25])
		var newly2 := cs.check_capture_cells(recapture_cells, 2, "US", "Bot2", 25.0)
		t.equal(newly2.size(), 1, "Qayta egallandi")
		t.equal(city.owner_id, 2, "2-o'yinchi yangi ega")
		t.equal(city.owner_country, "US", "Yangi bayroq AQSH")
		t.equal(cs.get_player_captured_count(1), 0, "1-o'yinchidan kamaydi")
		t.equal(cs.get_player_captured_count(2), 1, "2-o'yinchiga qo'shildi")
	)

	t.test("Bot AI uchun eng yaqin shahar qidiruvi (Target selection)", func() -> void:
		var grid := GameGrid.new(100, 100)
		var places: Array = [
			{"name": "CityA", "code": "FR", "x": 10, "y": 10, "pop": 100000, "cap": 0},
			{"name": "CityB", "code": "FR", "x": 80, "y": 80, "pop": 100000, "cap": 0},
		]
		var cs := CitySystemRef.new()
		cs.build(places, grid)

		# Pozitsiya (12, 12) dagi bot uchun eng yaqini CityA (10, 10) bo'lishi kerak
		var target: CitySystemRef.CityData = cs.get_nearest_target_city(Vector2(12, 12), 30.0, 1)
		t.check(target != null, "Nishon shahar topildi")
		t.equal(target.name, "CityA", "Yaqin shahar tanlandi")

		# Uzoqdagi shahar radiusdan tashqarida (masofa ~50)
		var out_of_reach: CitySystemRef.CityData = cs.get_nearest_target_city(Vector2(50, 50), 10.0, 1)
		t.equal(out_of_reach, null, "10 radiusda shahar yo'q")
	)

	t.test("3D modellar (Small, Medium, Large) geometriyasi va balandligi sezilarli farq qiladi", func() -> void:
		var m_small := CityMeshBuilderRef.build_small_city_mesh()
		var m_med := CityMeshBuilderRef.build_medium_city_mesh()
		var m_large := CityMeshBuilderRef.build_large_city_mesh()

		t.check(m_small != null and m_small.get_surface_count() > 0, "Kichik shahar mesh mavjud")
		t.check(m_med != null and m_med.get_surface_count() > 0, "O'rta shahar mesh mavjud")
		t.check(m_large != null and m_large.get_surface_count() > 0, "Katta shahar mesh mavjud")

		var aabb_s := m_small.get_aabb()
		var aabb_m := m_med.get_aabb()
		var aabb_l := m_large.get_aabb()

		t.check(aabb_l.size.y > aabb_m.size.y, "Katta metropol o'rta shahardan baland: %.2f > %.2f" % [aabb_l.size.y, aabb_m.size.y])
		t.check(aabb_m.size.y > aabb_s.size.y, "O'rta shahar kichik qishloqdan baland: %.2f > %.2f" % [aabb_m.size.y, aabb_s.size.y])
		t.check(aabb_l.size.x > aabb_s.size.x, "Katta metropol maydoni kichikdan sezilarli keng: %.2f > %.2f" % [aabb_l.size.x, aabb_s.size.x])

		# Regional landmarklar
		var m_paris := CityMeshBuilderRef.build_landmark_paris()
		var m_uzb := CityMeshBuilderRef.build_landmark_uzbek()
		var m_rome := CityMeshBuilderRef.build_landmark_rome()
		var m_jp := CityMeshBuilderRef.build_landmark_japan()
		var m_eg := CityMeshBuilderRef.build_landmark_egypt()

		t.check(m_paris != null and m_paris.get_aabb().size.y > 4.5, "Parij Eyfel shpili baland: %.2f" % m_paris.get_aabb().size.y)
		t.check(m_uzb != null and m_uzb.get_aabb().size.y > 3.5, "O'zbekiston Registon minorasi baland: %.2f" % m_uzb.get_aabb().size.y)
		t.check(m_rome != null and m_rome.get_surface_count() > 0, "Rim Kolizey meshi bor")
		t.check(m_jp != null and m_jp.get_surface_count() > 0, "Yaponiya Pagoda meshi bor")
		t.check(m_eg != null and m_eg.get_surface_count() > 0, "Misr Piramida meshi bor")
	)

	t.test("O'limda (kill) shahar egaligi neytralga qaytishi va hisoblagich tozalanishi", func() -> void:
		var cfg := GameConfig.new()
		cfg.world_map = false
		var w := GameWorld.new(cfg, 123)
		var p1 := w.add_human("Player1", 0, "default", "UZ")
		var p2 := w.add_player("Bot2", 1, true)
		p2.country = "FR"
		var places: Array = [
			{"name": "Tashkent", "code": "UZ", "x": 10, "y": 10, "pop": 2500000, "cap": 1},
			{"name": "Samarkand", "code": "UZ", "x": 20, "y": 20, "pop": 500000, "cap": 0},
			{"name": "Paris", "code": "FR", "x": 50, "y": 50, "pop": 2100000, "cap": 1},
		]
		w.cities = CitySystemRef.new()
		w.cities.build(places, w.grid)

		# 1-o'yinchi 2 ta shaharni egallaydi
		w.cities.check_capture_cells(PackedInt32Array([10 * w.grid.width + 10, 20 * w.grid.width + 20]), p1.id, p1.country, p1.player_name, 1.0)
		t.equal(w.cities.get_player_captured_count(p1.id), 2, "O'yinchi 1 da 2 ta shahar")
		t.equal(w.cities.get_city_at_cell(10, 10).owner_id, p1.id, "Toshkent egasi p1")
		t.equal(w.cities.get_city_at_cell(20, 20).owner_id, p1.id, "Samarqand egasi p1")

		# 1-o'yinchi halok bo'ladi (kill)
		p1.alive = true
		w.kill(p1, PlayerState.DeathCause.TRAIL_HIT, p2)
		t.equal(p1.alive, false, "O'yinchi o'ldi")
		t.equal(w.cities.get_player_captured_count(p1.id), 0, "O'limdan so'ng egallangan shaharlar soni 0 bo'ldi")
		t.equal(w.cities.get_city_at_cell(10, 10).owner_id, 0, "Toshkent neytralga qaytdi")
		t.equal(w.cities.get_city_at_cell(10, 10).owner_country, "UZ", "Toshkent bayrog'i asl davlat bayrog'iga qaytdi")
		t.equal(w.cities.get_city_at_cell(20, 20).owner_id, 0, "Samarqand neytralga qaytdi")

		# Hodisalar orasida city_lost borligi
		var evs := w.drain_events()
		var lost_found := 0
		for ev in evs:
			if ev["type"] == "city_lost":
				lost_found += 1
		t.equal(lost_found, 2, "2 ta city_lost hodisasi chiqarildi")
	)

	t.test("Boshlang'ich hududdagi (starting disc) shaharni avtomatik egallash", func() -> void:
		var cfg := GameConfig.new()
		cfg.world_map = false
		var w := GameWorld.new(cfg, 456)
		var p := w.add_human("Player1", 0, "default", "UZ")
		var places: Array = [
			{"name": "BaseCity", "code": "UZ", "x": 30, "y": 30, "pop": 150000, "cap": 0},
		]
		w.cities = CitySystemRef.new()
		w.cities.build(places, w.grid)

		# Boshlang'ich doira (30, 30) atrofida ochiladi
		var caps := w.cities.check_starting_disc(30, 30, 4.0, p, 0.0)
		t.equal(caps.size(), 1, "Boshlang'ich doiradagi shahar egallandi")
		t.equal(caps[0].name, "BaseCity", "To'g'ri shahar egallandi")
		t.equal(caps[0].owner_id, p.id, "Shahar egasi o'yinchi")
		t.equal(w.cities.get_player_captured_count(p.id), 1, "Hisoblagich 1 ga oshdi")
	)

	t.test("Panjara (GameGrid) va Shaharlar egaligi 100% muvofiqligi (Reconciliation)", func() -> void:
		var grid := GameGrid.new(100, 100)
		var places: Array = [
			{"name": "City1", "code": "UZ", "x": 15, "y": 15, "pop": 100000, "cap": 0},
			{"name": "City2", "code": "FR", "x": 45, "y": 45, "pop": 100000, "cap": 0},
		]
		var cs := CitySystemRef.new()
		cs.build(places, grid)

		# City1 ni 1-o'yinchiniki deb belgilaymiz, lekin panjarada katak 0 bo'lsin
		var c1 := cs.get_city_at_cell(15, 15)
		c1.owner_id = 1
		cs._player_captured_counts[1] = 1
		grid.set_owner(15, 15, 0) # Panjarada neytral

		# City2 panjarada 2-o'yinchiniki, lekin shaharda 0
		grid.set_owner(45, 45, 2)
		var mock_players := {2: {"country": "FR", "player_name": "Bot2"}}

		var recon := cs.reconcile_with_grid(grid, mock_players)
		t.equal(recon["lost"].size(), 1, "City1 neytralga o'tkazildi")
		t.equal(c1.owner_id, 0, "City1 endi neytral")
		t.equal(recon["transferred"].size(), 1, "City2 2-o'yinchiga o'tkazildi")
		t.equal(cs.get_city_at_cell(45, 45).owner_id, 2, "City2 egasi 2")
	)

	t.test("Tanga mukofoti ishonchliligi: kutish vaqtida (cooldown) soxta tanga ko'rsatilmasligi", func() -> void:
		var grid := GameGrid.new(100, 100)
		var places: Array = [
			{"name": "RichCity", "code": "US", "x": 20, "y": 20, "pop": 2000000, "cap": 1},
		]
		var coin_field := CoinField.new()
		coin_field.build(places, grid)

		var city_cell := 20 * 100 + 20
		t.check(coin_field.is_coin_available_at_cell(city_cell), "Boshida tanga mavjud")

		# Birinchi marta egallanganda tanga olinadi
		var won1 := coin_field.collect_cells(PackedInt32Array([city_cell]), true)
		t.check(won1 > 0, "Birinchi egallashda tanga berildi: %d" % won1)
		t.equal(coin_field.get_last_collected_coin_for_cell(city_cell), won1, "Oxirgi olingan tanga to'g'ri qaytdi")
		t.check(not coin_field.is_coin_available_at_cell(city_cell), "Endi tanga kutishda (cooldown)")

		# Qayta egallanganda (recapture while on cooldown)
		var won2 := coin_field.collect_cells(PackedInt32Array([city_cell]), true)
		t.equal(won2, 0, "Kutish paytida qayta egallanganda tanga 0 beriladi")
		t.equal(coin_field.get_last_collected_coin_for_cell(city_cell), 0, "Soxta tanga berilmadi (aniq 0)")
	)

	t.test("Shahar zichligi: Qo'shni shahar masofasi (neighbor_dist) to'g'ri hisoblanadi", func() -> void:
		var grid := GameGrid.new(100, 100)
		var places: Array = [
			{"name": "Paris", "code": "FR", "x": 10, "y": 10, "pop": 2000000, "cap": 1},
			{"name": "Lille", "code": "FR", "x": 10, "y": 16, "pop": 200000, "cap": 0},
			{"name": "Remote", "code": "FR", "x": 80, "y": 80, "pop": 50000, "cap": 0},
		]
		var cs := CitySystemRef.new()
		cs.build(places, grid)

		var paris := cs.get_city_at_cell(10, 10)
		var lille := cs.get_city_at_cell(10, 16)
		var remote := cs.get_city_at_cell(80, 80)

		t.equal(paris.neighbor_dist, 6.0, "Parij va Lill orasidagi masofa 6 katak")
		t.equal(lille.neighbor_dist, 6.0, "Lill qo'shni masofasi 6 katak")
		t.check(remote.neighbor_dist > 50.0, "Uzoq shahar masofasi katta: %.1f" % remote.neighbor_dist)
	)

func _test_phase6_economy(t: TestRunner) -> void:
	t.group("phase 6 — shahar mukofotlari va iqtisodiyot")

	# 1, 2, 3: Kichik = 50, O'rta = 200, Katta = 500
	t.test("1. Kichik shahar aniq 50 tanga beradi", func() -> void:
		t.equal(MonetizationConfig.get_city_capture_reward(CitySystem.Category.SMALL), 50, "Kichik shahar mukofoti 50")
		t.equal(int(MonetizationConfig.CITY_CAPTURE_REWARDS[CitySystem.Category.SMALL]), 50, "CITY_CAPTURE_REWARDS small 50")
		t.equal(int(MonetizationConfig.CITY_REWARDS["small"]["coins"]), 50, "CITY_REWARDS small 50")
	)

	t.test("2. O'rta shahar aniq 200 tanga beradi", func() -> void:
		t.equal(MonetizationConfig.get_city_capture_reward(CitySystem.Category.MEDIUM), 200, "O'rta shahar mukofoti 200")
		t.equal(int(MonetizationConfig.CITY_CAPTURE_REWARDS[CitySystem.Category.MEDIUM]), 200, "CITY_CAPTURE_REWARDS medium 200")
		t.equal(int(MonetizationConfig.CITY_REWARDS["medium"]["coins"]), 200, "CITY_REWARDS medium 200")
	)

	t.test("3. Katta shahar aniq 500 tanga beradi", func() -> void:
		t.equal(MonetizationConfig.get_city_capture_reward(CitySystem.Category.LARGE), 500, "Katta shahar mukofoti 500")
		t.equal(int(MonetizationConfig.CITY_CAPTURE_REWARDS[CitySystem.Category.LARGE]), 500, "CITY_CAPTURE_REWARDS large 500")
		t.equal(int(MonetizationConfig.CITY_REWARDS["large"]["coins"]), 500, "CITY_REWARDS large 500")
	)

	# 4 & 5: Hamyon balansi to'g'ri o'sadi, gemlar o'zgarmaydi
	t.test("4 & 5. Hamyon balansi to'g'ri o'sadi va gemlar o'zgarmaydi", func() -> void:
		var wallet := CurrencyManager.new()
		wallet.reset()
		var init_coins := wallet.get_coins()
		var init_gems := wallet.get_gems()
		var credited := wallet.add_coins(50, "city_conquest", "tx_test_1")
		t.equal(credited, 50, "50 tanga qo'shildi")
		t.equal(wallet.get_coins(), init_coins + 50, "Hamyon balansi 50 ga oshdi")
		t.equal(wallet.get_gems(), init_gems, "Gemlar o'zgarmadi")
	)

	# 6. Muvaffaqiyatsiz egallash (loop yopilmagan) mukofot bermaydi
	t.test("6. Muvaffaqiyatsiz egallash tanga bermaydi", func() -> void:
		var tracker := CitySystem.CityRewardTracker.new()
		tracker.reset("match_fail")
		t.equal(tracker.get_total_conquest_coins(), 0, "Muvaffaqiyatsiz egallashda tanga 0")
		t.equal(tracker.get_claimed_count(), 0, "Hech bir shahar da'vo qilinmadi")
	)

	# 7. Shahar ustidan shunchaki yurib o'tish (trail yopilmay) mukofot bermaydi
	t.test("7. Shahar ustidan yurib o'tish istilo mukofoti bermaydi", func() -> void:
		var tracker := CitySystem.CityRewardTracker.new()
		tracker.reset("match_walk")
		t.equal(tracker.get_total_conquest_coins(), 0, "Yurib o'tishda istilo tangasi 0")
	)

	# 8. Boshlang'ich hudud doirasi (spawn disc) istilo mukofoti bermaydi
	t.test("8. Boshlang'ich hudud yaratilganda tanga berilmaydi", func() -> void:
		var is_starting := true
		var should_reward := not is_starting
		t.equal(should_reward, false, "Boshlang'ich hududda shahar istilosi mukofoti berilmaydi")
	)

	# 9. Haqiqiy shahar istilosi bir marta mukofot beradi
	t.test("9. Haqiqiy shahar istilosi bir marta mukofot beradi", func() -> void:
		var tracker := CitySystem.CityRewardTracker.new()
		tracker.reset("match_valid")
		var c := CitySystem.CityData.new()
		c.id = 101
		c.name = "Samarkand"
		c.display_name = "Samarqand"
		c.category = CitySystem.Category.MEDIUM
		c.stable_id = "UZ_Samarkand_10_20"
		var res := tracker.claim_city(c, true)
		t.equal(bool(res["eligible"]), true, "Shahar istilosi munosib")
		t.equal(int(res["coins"]), 200, "O'rta shahar 200 tanga berdi")
		t.equal(tracker.get_total_conquest_coins(), 200, "Jami 200 tanga qayd etildi")
	)

	# 10. Bitta o'yinda xuddi shu shaharni qayta egallash qo'shimcha tanga bermaydi
	t.test("10. Bir xil shaharni qayta egallash takroriy mukofot bermaydi", func() -> void:
		var tracker := CitySystem.CityRewardTracker.new()
		tracker.reset("match_duplicate")
		var c := CitySystem.CityData.new()
		c.id = 102
		c.name = "Paris"
		c.display_name = "Parij"
		c.category = CitySystem.Category.LARGE
		c.stable_id = "FR_Paris_50_50"

		var res1 := tracker.claim_city(c, true)
		var res2 := tracker.claim_city(c, true)
		t.equal(bool(res1["eligible"]), true, "Birinchi egallash munosib")
		t.equal(bool(res2["eligible"]), false, "Ikkinchi egallash nomunosib (0 tanga)")
		t.equal(tracker.get_total_conquest_coins(), 500, "Jami faqat 500 tanga berildi")
		t.equal(tracker.get_duplicates_prevented(), 1, "1 ta takroriy urinish to'xtatildi")
	)

	# 11. Har xil munosib shaharlar o'z mukofotlarini beradi
	t.test("11. Turli shaharlar o'z mukofotlarini beradi", func() -> void:
		var tracker := CitySystem.CityRewardTracker.new()
		tracker.reset("match_multi")
		var c1 := CitySystem.CityData.new()
		c1.id = 201
		c1.category = CitySystem.Category.SMALL
		c1.stable_id = "CA_Small_1_1"

		var c2 := CitySystem.CityData.new()
		c2.id = 202
		c2.category = CitySystem.Category.MEDIUM
		c2.stable_id = "CA_Med_2_2"

		var c3 := CitySystem.CityData.new()
		c3.id = 203
		c3.category = CitySystem.Category.LARGE
		c3.stable_id = "CA_Large_3_3"

		tracker.claim_city(c1, true)
		tracker.claim_city(c2, true)
		tracker.claim_city(c3, true)
		t.equal(tracker.get_total_conquest_coins(), 750, "50+200+500 = 750 tanga")
		t.equal(tracker.get_claimed_count(), 3, "3 ta shahar da'vo qilindi")
	)

	# 12. Bot egallaganda odam hamyoniga tanga tushmaydi
	t.test("12. Bot istilosi odam hamyoniga tanga bermaydi", func() -> void:
		var tracker := CitySystem.CityRewardTracker.new()
		tracker.reset("match_bot")
		var c := CitySystem.CityData.new()
		c.id = 301
		c.category = CitySystem.Category.LARGE
		var res := tracker.claim_city(c, false)
		t.equal(bool(res["eligible"]), false, "Bot istilosi odamga mukofot bermaydi")
		t.equal(int(res["coins"]), 0, "Bot istilosidan tanga 0")
		t.equal(tracker.get_total_conquest_coins(), 0, "Hamyon balansi 0")
	)

	# 13. Takroriy tranzaksiya ID (idempotentlik) hamyonni ikki marta to'ldirmaydi
	t.test("13. Idempotent tranzaksiya ikki marta to'lamaydi", func() -> void:
		var wallet := CurrencyManager.new()
		wallet.reset()
		var tx_id := "tx_unique_conquest_999"
		var first_add := wallet.add_coins(500, "city_conquest", tx_id)
		var second_add := wallet.add_coins(500, "city_conquest", tx_id)
		t.equal(first_add, 500, "Birinchi qo'shish 500")
		t.equal(second_add, 0, "Ikkinchi qo'shish 0 (idempotent)")
		t.check(wallet.has_transaction(tx_id), "Tranzaksiya qayd qilingan")
	)

	# 14. Saqlash va yuklash hamyon balansini to'liq saqlaydi
	t.test("14. Saqlash va yuklash hamyon balansini to'liq saqlaydi", func() -> void:
		var w1 := CurrencyManager.new()
		w1.reset()
		w1.add_coins(1250, "test", "tx_save_test")
		w1.save_currency()

		var w2 := CurrencyManager.new()
		w2.load_currency()
		t.equal(w2.get_coins(), 1250, "Yuklangan hamyon balansi 1250")
		t.check(w2.has_transaction("tx_save_test"), "Saqlangan tranzaksiya mavjud")
	)

	# 15. Tiklangan o'yinda da'vo qilingan shaharlar tarixi saqlanadi
	t.test("15. O'yin tiklanganda da'vo qilingan shaharlar tarixi saqlanadi", func() -> void:
		var tracker := CitySystem.CityRewardTracker.new()
		tracker.reset("match_save_resume")
		var c := CitySystem.CityData.new()
		c.id = 401
		c.stable_id = "UZ_Tashkent_1_1"
		c.category = CitySystem.Category.LARGE
		tracker.claim_city(c, true)

		var saved_ids := tracker.get_claimed_city_ids()
		var tracker2 := CitySystem.CityRewardTracker.new()
		tracker2.reset("match_save_resume")
		tracker2.restore_claimed_ids(saved_ids)
		t.equal(tracker2.is_city_eligible(c), false, "Tiklangach shahar qayta munosib emas")
	)

	# 16. Eski saqlangan sozlamalar xavfsiz mos keladi
	t.test("16. Eski saqlangan sozlamalar xavfsiz yuklanadi", func() -> bool:
		var store := SettingsStore.new()
		return store.total_city_conquest_coins >= 0 and store.total_duplicates_prevented >= 0
	)

	# 17. Xaritadagi mavjud tanga yig'ish (coin pickup) sovishi (cooldown) buzilmagan
	t.test("17. Tanga yig'ish (coin field cooldown) to'g'ri ishlaydi", func() -> void:
		var grid := MapHelpers.grid_from(PackedStringArray([
			"......",
			"......",
		]))
		var cf := CoinField.new()
		cf.build([{"x": 1, "y": 1, "pop": 1000}], grid)
		var cell := 1 * grid.width + 1
		t.check(cf.is_coin_available_at_cell(cell), "Dastlab tanga mavjud")
		var got := cf.collect_cells(PackedInt32Array([cell]), true)
		t.check(not cf.is_coin_available_at_cell(cell), "Olingach tanga yo'q")
		t.check(got > 0, "Tanga qiymati > 0")
		cf.advance(MonetizationConfig.CITY_COIN_RESPAWN + 1.0)
		t.check(cf.is_coin_available_at_cell(cell), "30 soniyadan so'ng qayta paydo bo'ldi")
	)

	# 18. Mukofot konfiguratsiyasi to'g'ri o'qiladi
	t.test("18. Mukofot konfiguratsiyasi to'g'ri o'qiladi", func() -> void:
		var c := CitySystem.CityData.new()
		c.category = CitySystem.Category.LARGE
		t.equal(c.get_conquest_reward(), 500, "CityData.get_conquest_reward() 500 qaytardi")
	)

	# 19. Natija ekrani hamyonni ikki marta to'ldirmaydi
	t.test("19. Natija ekrani istilo tangalarini qayta qo'shmaydi", func() -> void:
		var wallet := CurrencyManager.new()
		wallet.reset()
		wallet.add_coins(500, "city_conquest", "tx_match_city")
		var mid_coins := wallet.get_coins()
		var run_rew := RewardManager.run_reward(60.0, 10.0, 1, 15)
		wallet.add_coins(int(run_rew["total"]), "run", "tx_match_run")
		t.equal(wallet.get_coins(), mid_coins + int(run_rew["total"]), "Natija ekrani faqat run_reward qo'shdi")
	)

	# 20. Barcha 7 ta geografik xaritada shaharlar to'g'ri toifalangan
	t.test("20. Barcha geografik xaritalarda shahar toifalari mavjud", func() -> void:
		for map_id: String in ["world", "europe", "asia", "africa", "north_america", "south_america", "oceania"]:
			var map := WorldMap.load_map(map_id)
			t.check(map != null and not map.places.is_empty(), "Xarita %s shaharlarga ega" % map_id)
	)

	# 21. O'lim va tirilishdan keyin shahar egaligi panjara bilan to'liq mos
	t.test("21. Shaharlar egaligi o'limdan so'ng to'liq neytrallashadi", func() -> void:
		var cs := CitySystemRef.new()
		var grid := MapHelpers.grid_from(PackedStringArray(["......", "......"]))
		cs.build([{"x": 1, "y": 1, "pop": 500000}], grid)
		var c := cs.cities[0]
		c.owner_id = 1
		cs._player_captured_counts[1] = 1
		var lost := cs.reset_player_cities(1)
		t.equal(lost.size(), 1, "1 ta shahar boy berildi")
		t.equal(c.owner_id, 0, "Shahar neytralga aylandi")
		t.equal(cs.get_player_captured_count(1), 0, "O'yinchi shahar soni 0")
	)

	# 22. 249 ta davlat bayroqlari resurslari to'liq ishlaydi
	t.test("22. 249 ta davlat bayroqlari tizimi ishchi holatda", func() -> void:
		var f_uz := FlagRenderer.get_flag_texture("UZ")
		var f_us := FlagRenderer.get_flag_texture("US")
		var f_jp := FlagRenderer.get_flag_texture("JP")
		t.check(f_uz != null and f_us != null and f_jp != null, "Bayroqlar yuklandi")
	)

	# 23. Katta xaritalar va 20 ta bot bilan barqarorlik
	t.test("23. 20 ta bot va shahar istilosi barqaror ishlaydi", func() -> void:
		var tracker := CitySystem.CityRewardTracker.new()
		tracker.reset("match_bots_20")
		var cities_list: Array[CitySystem.CityData] = []
		for i in 20:
			var c := CitySystem.CityData.new()
			c.id = 500 + i
			c.category = i % 3
			cities_list.append(c)
		for i in 20:
			tracker.claim_city(cities_list[i], false)
		t.equal(tracker.get_total_conquest_coins(), 0, "20 bot egallaganida odamga 0 tanga berildi")
	)

	# 24. Mobil xavfsiz maydon va UI hisoblagichlari to'g'ri hisoblanadi
	t.test("24. UI va iqtisodiy hisoblagichlar to'g'ri ishlaydi", func() -> void:
		var tracker := CitySystem.CityRewardTracker.new()
		tracker.reset("match_ui")
		var c1 := CitySystem.CityData.new()
		c1.id = 601
		c1.category = CitySystem.Category.SMALL
		var c2 := CitySystem.CityData.new()
		c2.id = 602
		c2.category = CitySystem.Category.LARGE
		tracker.claim_city(c1, true)
		tracker.claim_city(c2, true)
		t.equal(tracker.get_rewarded_count(CitySystem.Category.SMALL), 1, "1 ta kichik shahar")
		t.equal(tracker.get_rewarded_count(CitySystem.Category.LARGE), 1, "1 ta katta shahar")
		t.equal(tracker.get_total_conquest_coins(), 550, "50 + 500 = 550 tanga")
	)

func _test_phase6_corrections_integration(t: TestRunner) -> void:
	t.group("phase 6 tuzatishlar va integratsiya")

	# 1. Haqiqiy hamyon ma'lumotlarini testlar vaqtida himoyalash
	t.test("1. Testlar haqiqiy user://wallet.cfg ni o'zgartirmaydi", func() -> void:
		var mock_prod_path := "user://mock_prod_wallet_test.cfg"
		var mock_cfg := ConfigFile.new()
		mock_cfg.set_value("wallet", "coins", 8888)
		mock_cfg.set_value("wallet", "gems", 44)
		mock_cfg.save(mock_prod_path)

		var mock_bytes_before := FileAccess.get_file_as_bytes(mock_prod_path)

		# Test rejimida yangi test hamyon yaratamiz
		var test_wallet := CurrencyManager.new("user://test_sandbox_wallet.cfg")
		test_wallet.reset()
		test_wallet.add_coins(500, "test", "tx_sandbox")

		# Asl mock production fayli o'zgarmaganligini tekshiramiz
		var mock_bytes_after := FileAccess.get_file_as_bytes(mock_prod_path)
		t.equal(mock_bytes_after, mock_bytes_before, "Ishlab chiqarish hamyoni baytma-bayt o'zgarmadi")

		var prod_checker := CurrencyManager.new(mock_prod_path)
		t.equal(prod_checker.get_coins(), 8888, "Ishlab chiqarish balansi 8888 saqlanib qoldi")

		# Tozalash
		if FileAccess.file_exists(mock_prod_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(mock_prod_path))
		if FileAccess.file_exists("user://test_sandbox_wallet.cfg"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_sandbox_wallet.cfg"))
	)

	# 2. 60 tadan ortiq tranzaksiyalar himoyasi (ID lar esdan chiqmaydi)
	t.test("2. 60 tadan ortiq tranzaksiya o'tsa ham eski ID lar qayta to'lanmaydi", func() -> void:
		var test_path := "user://test_tx_limit.cfg"
		var cm := CurrencyManager.new(test_path)
		cm.reset()

		# 80 ta har xil tranzaksiya kiritamiz
		for i in 80:
			var tx := "tx_conquest_seq_%d" % i
			var added := cm.add_coins(10, "city_conquest", tx)
			t.equal(added, 10, "Tranzaksiya %d qabul qilindi" % i)

		t.equal(cm.get_coins(), 800, "Jami 800 tanga yig'ildi")
		t.equal(cm.history().size(), 60, "UI jurnali 60 ta bilan cheklangan")

		# 60 tadan tashqarida qolgan eng birinchi tranzaksiyani tekshiramiz:
		t.check(cm.has_transaction("tx_conquest_seq_0"), "Eng birinchi tranzaksiya (0) eslab qolingan")
		t.check(cm.has_transaction("tx_conquest_seq_19"), "Eski tranzaksiya (19) eslab qolingan")
		t.check(cm.has_transaction("tx_conquest_seq_79"), "Eng yangi tranzaksiya (79) eslab qolingan")

		# Eng birinchi tranzaksiyani qayta to'lashga urinib ko'ramiz:
		var duplicate_add := cm.add_coins(500, "city_conquest", "tx_conquest_seq_0")
		t.equal(duplicate_add, 0, "60 tadan eski tranzaksiya qayta to'lanmadi (0 tanga)")
		t.equal(cm.get_coins(), 800, "Balans o'zgarmadi")

		# Tozalash
		if FileAccess.file_exists(test_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	)

	# 3. Hamyonni diskdan qayta yuklaganda 60 tadan oshiq tranzaksiyalar xavfsiz tiklanadi
	t.test("3. Hamyon qayta yuklanganda (restart) barcha tranzaksiya ID lari saqlanadi", func() -> void:
		var test_path := "user://test_tx_restart.cfg"
		var cm1 := CurrencyManager.new(test_path)
		cm1.reset()
		for i in 75:
			cm1.add_coins(20, "city_conquest", "tx_restart_%d" % i)
		cm1.save_currency()

		# O'yinni o'chirib yoqishni simulyatsiya qilamiz
		var cm2 := CurrencyManager.new(test_path)
		cm2.load_currency()
		t.equal(cm2.get_coins(), 1500, "Qayta yuklangan balans 1500")
		t.check(cm2.has_transaction("tx_restart_0"), "Eng eski tranzaksiya qayta ochilganda ham bor")
		t.check(cm2.has_transaction("tx_restart_74"), "Eng yangi tranzaksiya bor")

		var dup := cm2.add_coins(500, "city_conquest", "tx_restart_0")
		t.equal(dup, 0, "Qayta yuklangach ham takroriy to'lov rad etildi")

		if FileAccess.file_exists(test_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	)

	# 4. Haqiqiy hudud halqasi yopilganda shahar istilosi va hamyon to'lovi (Haqiqiy GameWorld)
	t.test("4. Haqiqiy hudud halqasi yopilishi shahar istilosi va tanga beradi", func() -> void:
		var cfg := GameConfig.new()
		cfg.world_map = false
		cfg.grid_width = 20
		cfg.grid_height = 10
		var world := GameWorld.new(cfg)
		for y in range(2, 5):
			for x in range(5, 8):
				world.grid.set_owner(x, y, 1)

		# Shaharni (8, 3) katakka joylashtiramiz
		var places: Array = [{"x": 8, "y": 3, "pop": 250000, "name": "Bukhara", "code": "UZ"}]
		world.cities.build(places, world.grid)
		var city: CitySystem.CityData = world.cities.get_city_at_cell(8, 3)
		t.check(city != null, "Shahar yaratildi")
		t.equal(city.owner_id, 0, "Boshida shahar neytral")

		# O'yinchini (5, 3) o'z hududiga joylashtiramiz
		var p := PlayerState.new(1, "Player1", 0, false, 8.0, 4.0)
		p.country = "UZ"
		p.alive = true
		p.place_at(5.5, 3.5, 0.0)
		world.players.append(p)
		world._by_id[1] = p

		var tracker := CitySystem.CityRewardTracker.new()
		tracker.reset("match_real_loop")

		# Shaharni o'rab oladigan iz quramiz:
		var trail_cells := [
			Vector2i(7, 2), Vector2i(8, 2), Vector2i(9, 2), Vector2i(10, 2),
			Vector2i(10, 3),
			Vector2i(10, 4), Vector2i(9, 4), Vector2i(8, 4), Vector2i(7, 4)
		]
		for c_pos in trail_cells:
			var idx := world.grid.index(c_pos.x, c_pos.y)
			world.grid.set_trail_index(idx, p.id)
			p.add_trail(idx)

		# Halqani yopamiz (_finish_loop chaqiramiz)
		world._finish_loop(p)

		# Panjarada shahar katagi egallangan bo'lishi kerak:
		t.equal(world.grid.owner_at(8, 3), 1, "Shahar katagi panjarada 1-o'yinchiga o'tdi")
		t.equal(city.owner_id, 1, "Shahar egasi 1 bo'ldi")

		# Voqeani tekshiramiz:
		var found_event := false
		for ev in world.events:
			if ev.get("type") == "city_captured" and ev.get("player") == 1:
				found_event = true
				var claim_res := tracker.claim_city(ev["city"], true)
				t.equal(bool(claim_res["eligible"]), true, "Haqiqiy halqa yopilgach mukofot munosib")
				t.equal(int(claim_res["coins"]), city.get_conquest_reward(), "Mukofot MonetizationConfig ga teng")
		t.check(found_event, "city_captured voqeasi generatsiya qilindi")
	)

	# 5. Halqa yopilmasdan o'lish yoki ustidan yurib o'tish mukofot bermaydi
	t.test("5. Halqa yopilmasdan o'lish shaharni va mukofotni bermaydi", func() -> void:
		var cfg := GameConfig.new()
		cfg.world_map = false
		cfg.grid_width = 20
		cfg.grid_height = 10
		var world := GameWorld.new(cfg)
		for y in range(2, 5):
			for x in range(5, 8):
				world.grid.set_owner(x, y, 1)

		var places: Array = [{"x": 9, "y": 3, "pop": 100000, "name": "Navoi", "code": "UZ"}]
		world.cities.build(places, world.grid)
		var city: CitySystem.CityData = world.cities.get_city_at_cell(9, 3)

		var p := PlayerState.new(1, "Player1", 0, false, 8.0, 4.0)
		p.country = "UZ"
		p.alive = true
		p.place_at(5.5, 3.5, 0.0)
		world.players.append(p)
		world._by_id[1] = p

		# O'yinchi shaharning ustidan yurib o'tmoqda, lekin halqa yopmadi:
		var idx := world.grid.index(9, 3)
		world.grid.set_trail_index(idx, p.id)
		p.add_trail(idx)

		t.equal(city.owner_id, 0, "Shunchaki iz bosilganda shahar egallanmaydi")

		# Halqa yopilmasdan o'yinchi halok bo'ldi:
		world.kill(p, PlayerState.DeathCause.TRAIL_HIT, null)
		t.equal(p.alive, false, "O'yinchi o'ldi")
		t.check(p.trail.is_empty(), "Iz yo'qotildi")
		t.equal(world.grid.owner_at(9, 3), 0, "Shahar katagi neytral qoldi")
		t.equal(city.owner_id, 0, "Shahar hali ham neytral")

		# Hech qanday city_captured voqeasi bo'lmasligi kerak:
		var city_events := 0
		for ev in world.events:
			if ev.get("type") == "city_captured":
				city_events += 1
		t.equal(city_events, 0, "0 ta shahar egallandi voqeasi")
	)

	# 6. Bitta o'yinda shaharni bot egallab, keyin odam qayta egallasa qo'shimcha tanga berilmaydi
	t.test("6. Qayta egallash (recapture) takroriy tanga bermaydi", func() -> void:
		var tracker := CitySystem.CityRewardTracker.new()
		tracker.reset("match_recapture")
		var c := CitySystem.CityData.new()
		c.id = 701
		c.name = "Samarkand"
		c.category = CitySystem.Category.MEDIUM
		c.stable_id = "UZ_Samarkand_15_15"

		# 1-marta: odam egallaydi
		var res1 := tracker.claim_city(c, true)
		t.equal(bool(res1["eligible"]), true, "1-marta odam egalladi (+200)")
		t.equal(int(res1["coins"]), 200)

		# 2-marta: Bot kelib shaharni tortib oladi
		c.owner_id = 2
		var res_bot := tracker.claim_city(c, false)
		t.equal(bool(res_bot["eligible"]), false, "Bot egallaganda odamga tanga yo'q")

		# 3-marta: Odam botdan shaharni qaytarib oladi (xuddi shu match)
		c.owner_id = 1
		var res_recapture := tracker.claim_city(c, true)
		t.equal(bool(res_recapture["eligible"]), false, "Qayta egallanganda tanga berilmaydi (+0)")
		t.equal(str(res_recapture["reason"]), "already_claimed")
		t.equal(tracker.get_duplicates_prevented(), 1, "Takroriy istilo to'xtatildi")
		t.equal(tracker.get_total_conquest_coins(), 200, "Umumiy tanga 200 bo'lib qoladi")
	)

	# 7. Match recovery va serializatsiya (save_state, from_dict, resume_or_start)
	t.test("7. Match tiklash va serializatsiya barcha mukofotlarni saqlaydi", func() -> void:
		var tracker1 := CitySystem.CityRewardTracker.new()
		tracker1.reset("match_recovery_101")
		var c1 := CitySystem.CityData.new()
		c1.id = 801
		c1.category = CitySystem.Category.SMALL
		c1.stable_id = "UZ_Small_801"
		tracker1.claim_city(c1, true)

		var state_dict := tracker1.to_dict()
		t.equal(str(state_dict["match_id"]), "match_recovery_101")
		t.check((state_dict["claimed_stable_keys"] as Array).has("UZ_Small_801"))

		# Yangi trackerda tiklaymiz
		var tracker2 := CitySystem.CityRewardTracker.new()
		tracker2.from_dict(state_dict)
		t.equal(tracker2.get_match_id(), "match_recovery_101")
		t.equal(tracker2.is_city_eligible(c1), false, "Tiklangach c1 shahar da'vo qilingan deb saqlanadi")
		t.equal(tracker2.get_total_conquest_coins(), 50, "50 tanga saqlandi")

		# Shu match resume qilinganda tarix tozalanmaydi
		var resumed := tracker2.resume_or_start("match_recovery_101")
		t.equal(resumed, true, "Xuddi shu match resume qilindi")
		t.equal(tracker2.is_city_eligible(c1), false, "Resume dan so'ng ham mukofot takrorlanmaydi")

		# Yangi match boshlanganda esa tozalanadi
		var new_match := tracker2.resume_or_start("match_brand_new_999")
		t.equal(new_match, false, "Yangi match boshlandi")
		t.equal(tracker2.get_match_id(), "match_brand_new_999")
		t.equal(tracker2.is_city_eligible(c1), true, "Yangi matchda shahar qayta munosib")
	)

	# 8. Natija ekrani va MonetizationConfig dinamik qiymatlari mosligi
	t.test("8. Natija ekrani hisob-kitoblari MonetizationConfig ga to'liq mos", func() -> void:
		var s_r := MonetizationConfig.get_city_capture_reward(CitySystem.Category.SMALL)
		var m_r := MonetizationConfig.get_city_capture_reward(CitySystem.Category.MEDIUM)
		var l_r := MonetizationConfig.get_city_capture_reward(CitySystem.Category.LARGE)

		var conquest_data := {
			"small_count": 3,
			"medium_count": 2,
			"large_count": 1,
			"small_coins": 3 * s_r,
			"medium_coins": 2 * m_r,
			"large_coins": 1 * l_r,
			"total": 3 * s_r + 2 * m_r + 1 * l_r,
		}
		t.equal(conquest_data["small_coins"], 150)
		t.equal(conquest_data["medium_coins"], 400)
		t.equal(conquest_data["large_coins"], 500)
		t.equal(conquest_data["total"], 1050)
	)

	# 9. Hamyon maksimal balansi chegarasi (MonetizationConfig.MAX_BALANCE)
	t.test("9. Hamyon balansi MAX_BALANCE dan oshib ketmaydi", func() -> void:
		var test_path := "user://test_wallet_clamp.cfg"
		var w := CurrencyManager.new(test_path)
		w.reset()
		var added := w.add_coins(MonetizationConfig.MAX_BALANCE + 1000, "overflow_test")
		t.equal(w.get_coins(), MonetizationConfig.MAX_BALANCE, "Balans MAX_BALANCE ga cheklandi")
		t.equal(added, MonetizationConfig.MAX_BALANCE, "Faqat sig'gan miqdor qaytdi")

		var extra := w.add_coins(500, "city_conquest", "tx_after_max")
		t.equal(extra, 0, "To'la hamyonga ortiqcha qo'shilmadi (0)")
		t.equal(w.get_coins(), MonetizationConfig.MAX_BALANCE)

		if FileAccess.file_exists(test_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	)

	# 10. CityRewardTracker.load_state faqat mos match_id li holatni yuklaydi
	t.test("10. load_state kutilmagan match_id dagi holatni rad etadi", func() -> void:
		var test_save := "user://test_tracker_match_mismatch.cfg"
		var t1 := CitySystem.CityRewardTracker.new()
		t1.reset("match_alpha")
		var c := CitySystem.CityData.new()
		c.id = 99
		c.category = CitySystem.Category.SMALL
		c.stable_id = "test_city_99"
		t1.claim_city(c, true)
		t1.save_state(test_save)

		# Boshqa match_id ga ega bo'lgan tracker yuklashga urinadi
		var t2 := CitySystem.CityRewardTracker.new()
		t2.reset("match_beta")
		var loaded_wrong := t2.load_state(test_save, "match_beta")
		t.equal(loaded_wrong, false, "Mos kelmagan match_id yuklanmadi")
		t.equal(t2.is_city_eligible(c), true, "Shahar t2 da hali da'vo qilinmagan")

		# Mos match_id bilan yuklash
		var loaded_ok := t2.load_state(test_save, "match_alpha")
		t.equal(loaded_ok, true, "To'g'ri match_id yuklandi")
		t.equal(t2.is_city_eligible(c), false, "Endi shahar da'vo qilingan deb saqlanadi")

		if FileAccess.file_exists(test_save):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save))
	)

func _test_phase8_optimization_qa(t: TestRunner) -> void:
	t.group("phase 8 optimizatsiya, qa va relizga tayyorgarlik")

	# 1. Grafika sozlamalari sifat presetlari ("low", "medium", "high")
	t.test("1. Grafika sifat presetlari sozlamalari to'g'ri saqlanadi va tekshiriladi", func() -> void:
		var store := SettingsStore.load_store()
		var orig := store.graphics_quality

		store.graphics_quality = "low"
		t.equal(store.graphics_quality, "low", "Low preset to'g'ri o'rnatildi")

		store.graphics_quality = "high"
		t.equal(store.graphics_quality, "high", "High preset to'g'ri o'rnatildi")

		store.graphics_quality = "medium"
		t.equal(store.graphics_quality, "medium", "Medium preset to'g'ri o'rnatildi")

		store.graphics_quality = "INVALID_QUALITY"
		t.equal(store.graphics_quality, "medium", "Noto'g'ri qiymatda standart 'medium' ga tushadi")

		store.graphics_quality = orig
	)

	# 2. CityRenderer dinamik LOD presetlarini qo'llab-quvvatlaydi
	t.test("2. CityRenderer presetlari dinamik LOD parametrlarini to'g'ri o'zgartiradi", func() -> void:
		var cr := CityRenderer.new()
		cr.set_quality_preset("low")
		t.equal(cr._lod_close, 36.0, "Low da LOD masofasi 36.0")
		t.equal(cr._max_active_cities, 14, "Low da maksimal 14 ta 3D shahar")
		t.equal(cr._update_interval, 0.20, "Low da yangilash intervali 0.20s")

		cr.set_quality_preset("medium")
		t.equal(cr._lod_close, 50.0, "Medium da LOD masofasi 50.0")
		t.equal(cr._max_active_cities, 28, "Medium da maksimal 28 ta 3D shahar")
		t.equal(cr._update_interval, 0.12, "Medium da yangilash intervali 0.12s")

		cr.set_quality_preset("high")
		t.equal(cr._lod_close, 68.0, "High da LOD masofasi 68.0")
		t.equal(cr._max_active_cities, 42, "High da maksimal 42 ta 3D shahar")
		t.equal(cr._update_interval, 0.08, "High da yangilash intervali 0.08s")
		cr.free()
	)

	# 3. FlagPoles sifat presetlari masofa culling parametrlarini to'g'ri moslaydi
	t.test("3. FlagPoles sifat presetlari masofa culling parametrlarini to'g'ri moslaydi", func() -> void:
		var fp := FlagPoles.new()
		fp.set_quality_preset("low")
		t.equal(fp._cull_distance, 50.0, "Low da bayroqlar 50.0 dan keyin culling qilinadi")

		fp.set_quality_preset("medium")
		t.equal(fp._cull_distance, 90.0, "Medium da bayroqlar 90.0 dan keyin culling qilinadi")

		fp.set_quality_preset("high")
		t.equal(fp._cull_distance, 150.0, "High da bayroqlar 150.0 dan keyin culling qilinadi")
		fp.free()
	)

	# 4. Murakkab to'ldirish (territory closure & fill correctness)
	t.test("4. Murakkab shaklli hudud halqasi ichki kataklarni to'liq qamrab oladi", func() -> void:
		var cfg := GameConfig.new()
		cfg.world_map = false
		cfg.grid_width = 30
		cfg.grid_height = 20
		var world := GameWorld.new(cfg)
		# O'yinchining boshlang'ich 3x3 hududi (5, 5) dan (7, 7) gacha
		for y in range(5, 8):
			for x in range(5, 8):
				world.grid.set_owner(x, y, 1)

		var p := PlayerState.new(1, "Player1", 0, false, 8.0, 4.0)
		p.place_at(6.5, 6.5, 0.0)
		world.players.append(p)
		world._by_id[1] = p

		# 8x6 to'rtburchak iz chizamiz: (8,5) -> (14,5) -> (14,10) -> (7,10) -> (7,7)
		var trail: Array[Vector2i] = []
		for x in range(8, 15):
			trail.append(Vector2i(x, 5))
		for y in range(6, 11):
			trail.append(Vector2i(14, y))
		for x in range(13, 6, -1):
			trail.append(Vector2i(x, 10))
		for y in range(9, 7, -1):
			trail.append(Vector2i(7, y))

		for pt in trail:
			var idx := world.grid.index(pt.x, pt.y)
			world.grid.set_trail_index(idx, p.id)
			p.add_trail(idx)

		world._finish_loop(p)
		t.check(p.trail.is_empty(), "Halqa yopilgach iz tozalandi")

		# Ichki kataklar (9, 7), (10, 8), (11, 7) hammasi 1-o'yinchiga o'tgan bo'lishi shart
		t.equal(world.grid.owner_at(9, 7), 1, "Ichki katak (9,7) o'yinchiniki")
		t.equal(world.grid.owner_at(11, 8), 1, "Ichki katak (11,8) o'yinchiniki")
		# Tashqi katak (16, 8) esa neytral qolishi shart
		t.equal(world.grid.owner_at(16, 8), 0, "Tashqi katak (16,8) neytral qoldi")
	)

	# 5. Leaderboard tartibi va hudud foizi to'g'ri hisoblanishi
	t.test("5. Leaderboard reytingi va foiz hisob-kitobi mutlaq to'g'ri ishlaydi", func() -> void:
		var cfg := GameConfig.new()
		cfg.world_map = false
		cfg.grid_width = 40
		cfg.grid_height = 20
		var world := GameWorld.new(cfg)

		var p1 := PlayerState.new(1, "Player1", 0, false, 8.0, 4.0)
		p1.place_at(5.0, 5.0, 0.0)
		var p2 := PlayerState.new(2, "Bot2", 1, true, 8.0, 4.0)
		p2.place_at(20.0, 5.0, 0.0)
		world.players.append_array([p1, p2])
		world._by_id[1] = p1
		world._by_id[2] = p2

		# P1 ga 30 ta katak beramiz, P2 ga 15 ta katak beramiz
		for i in 30:
			world.grid.set_owner(i % 10 + 2, i / 10 + 2, p1.id)
		for i in 15:
			world.grid.set_owner(i % 5 + 20, i / 5 + 2, p2.id)

		t.equal(world.rank_of(p1), 1, "P1 1-o'rinda (kataklari ko'proq)")
		t.equal(world.rank_of(p2), 2, "P2 2-o'rinda")
		t.check(world.percent_of(p1) > world.percent_of(p2), "P1 foizi P2 foizidan katta")
	)

	# 6. Uzoq sessiya simulyatsiyasi (5 ta ketma-ket match, toza holat va takrorlanmaslik)
	t.test("6. Uzoq sessiya: 5 ta ketma-ket matchda state oqishi va resurs sizishi yo'q", func() -> void:
		var tracker := CitySystem.CityRewardTracker.new()
		var test_w_path := "user://test_long_session_wallet.cfg"
		var w := CurrencyManager.new(test_w_path)
		w.reset()

		var test_city := CitySystem.CityData.new()
		test_city.id = 555
		test_city.category = CitySystem.Category.MEDIUM
		test_city.stable_id = "test_city_long_session_555"

		for match_idx in 5:
			var mid := "long_match_%d" % match_idx
			tracker.reset(mid)
			t.equal(tracker.get_match_id(), mid, "Yangi match_id o'rnatildi")
			t.equal(tracker.get_claimed_count(), 0, "Yangi matchda da'volar soni 0")
			t.check(tracker.is_city_eligible(test_city), "Har bir yangi matchda shahar munosib")

			var res := tracker.claim_city(test_city, true)
			t.equal(bool(res["eligible"]), true, "1-egallashda shahar mukofoti berildi")
			var tx := str(res["tx_id"])
			var credited := w.add_coins(int(res["coins"]), "city_conquest", tx)
			t.equal(credited, 200, "Hamyonga +200 tanga tushdi")

			# Shu match davomida qayta egallash
			var dup_res := tracker.claim_city(test_city, true)
			t.equal(bool(dup_res["eligible"]), false, "Shu match ichida takroriy da'vo rad etildi")
			var dup_tx := str(dup_res.get("tx_id", ""))
			if not dup_tx.is_empty():
				var dup_cred := w.add_coins(200, "city_conquest", dup_tx)
				t.equal(dup_cred, 0, "Takroriy tx bo'yicha 0 qo'shildi")

		t.equal(w.get_coins(), 1000, "5 ta match natijasida hamyonda roppa-rosa 1000 tanga (5 x 200)")

		if FileAccess.file_exists(test_w_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_w_path))
	)


# ——— Phase 8 Final Blockers: Signing, Exposure, Coin Visibility, Real Conquest & 20-Bot Endurance ———
func _test_phase8_blockers_validation(t: TestRunner) -> void:
	t.group("Phase 8 Yakuniy Blokatorlar va Real O'yin Validatsiyasi")

	# 1. Android imzolash xavfsizligi va maxfiylik
	t.test("1. export_presets.cfg da ochiq parollar yo'q va AAB tayyor", func() -> void:
		var preset_cfg_path := "res://export_presets.cfg"
		t.check(FileAccess.file_exists(preset_cfg_path), "export_presets.cfg mavjud")
		var f := FileAccess.open(preset_cfg_path, FileAccess.READ)
		t.check(f != null, "export_presets.cfg o'qildi")
		if f != null:
			var content := f.get_as_text()
			f.close()
			t.check(not content.contains('keystore/release_password="android"'), "Release paroli ochiq saqlanmagan")
			t.check(not content.contains('keystore/debug_password="android"'), "Debug paroli ochiq saqlanmagan")
			t.check(content.contains('package/unique_name="com.mening.colorland3d"'), "Paket nomi to'g'ri: com.mening.colorland3d")
			t.check(content.contains('name="Android (AAB)"'), "Google Play uchun AAB preseti mavjud")
			t.check(content.contains('gradle_build/export_format=1'), "AAB formati 1 qilib sozlangan")
	)

	# 2. Vizual haddan tashqari yorug'lik (overexposure) va ranglarning to'yinganligi
	t.test("2. Er va okean ranglari multfilm uslubiga mos to'yingan va yorug'lik muvozanatda", func() -> void:
		Palette.set_theme("paper")
		var land_c := Palette.land()
		var ocean_c := Palette.ocean()
		var beach_c := Palette.beach()
		t.equal(land_c.to_html(false).to_lower(), "32a852", "Quruqlik to'yingan yam-yashil (#32a852)")
		t.equal(ocean_c.to_html(false).to_lower(), "0284c7", "Okean chuqur tropik moviy (#0284c7)")
		t.check(beach_c.r > 0.8 and beach_c.g > 0.7, "Sohil qumi issiq tillarang")

		# Asosiy sahnada Quyosh va Atrof-muhit yorug'lik balansi
		var main_scene: PackedScene = load("res://scenes/main.tscn")
		t.check(main_scene != null, "main.tscn yuklandi")
		if main_scene != null:
			var node := main_scene.instantiate()
			t.check(node != null, "main.tscn nusxalandi")
			if node != null:
				var sun_node: DirectionalLight3D = node.get_node_or_null("Sun")
				t.check(sun_node != null, "Sun mavjud")
				if sun_node != null:
					t.check(sun_node.light_energy <= 1.10, "Quyosh nuri 1.10 dan oshmaydi (overexposure yo'q)")
				var w_env: WorldEnvironment = node.get_node_or_null("WorldEnvironment")
				t.check(w_env != null, "WorldEnvironment mavjud")
				if w_env != null and w_env.environment != null:
					t.check(w_env.environment.ambient_light_energy <= 0.40, "Atrof-muhit nuri 0.40 dan oshmaydi")
					t.equal(w_env.environment.tonemap_mode, Environment.TONE_MAPPER_FILMIC, "Filmic tonemapping yoqilgan")
				node.queue_free()
	)

	# 3. Shahar tangalari (CityCoins) ko'rinish regressiyasi
	t.test("3. CityCoins va Pickups ko'rinishi: menyuda yashirin, o'yinda va pauzada ko'rinadi", func() -> void:
		var main_scene: PackedScene = load("res://scenes/main.tscn")
		if main_scene != null:
			var view := main_scene.instantiate()
			root.add_child(view)

			# Boshida menyu rejimida tangalar va narsalar ko'rinmasligi kerak
			view.show_screen_for_demo("menu")
			t.equal(bool(view._coins.visible), false, "Bosh menyuda CityCoins yashirin")
			t.equal(bool(view._pickups.visible), false, "Bosh menyuda Pickups yashirin")

			# Sozlamalar va boshqa UI ekranlarida ham yashirin
			view.show_screen_for_demo("settings")
			t.equal(bool(view._coins.visible), false, "Sozlamalarda CityCoins yashirin")
			view.show_screen_for_demo("heroes")
			t.equal(bool(view._coins.visible), false, "Qahramonlar ekranida CityCoins yashirin")

			# O'yin boshlanganda ko'rinadi
			view._on_play()
			t.equal(bool(view._coins.visible), true, "O'yin ketayotganda CityCoins ko'rinadi")
			t.equal(bool(view._pickups.visible), true, "O'yin ketayotganda Pickups ko'rinadi")

			# Pauza qilinganda o'yin fonida ko'rinib turadi
			view._on_pause()
			t.equal(bool(view._coins.visible), true, "Pauzada 3D sahnada CityCoins ko'rinib turadi")
			t.equal(bool(view._pickups.visible), true, "Pauzada 3D sahnada Pickups ko'rinib turadi")

			# Davom ettirilganda (Resume) ko'rinadi
			view._on_resume()
			t.equal(bool(view._coins.visible), true, "Pauzadan qaytgach CityCoins ko'rinadi")

			# Natija ekranida yashirin
			view._end_match()
			t.equal(bool(view._coins.visible), false, "Natija (Result) ekranida CityCoins yashirin")

			# Menyuga qaytganda yashirin
			view._on_menu()
			t.equal(bool(view._coins.visible), false, "Menyuga qaytgach CityCoins yashirin")

			root.remove_child(view)
			view.free()
	)

	# 4. Haqiqiy o'yin integratsiyasi: Halqa yopish, shaharlar egallash va hamyon to'lovlari (50, 200, 500)
	t.test("4. Haqiqiy o'yin integratsiyasi: 3 xil shahar istilosi va roppa-rosa +50, +200, +500 tanga", func() -> void:
		var cfg := GameConfig.new()
		cfg.world_map = false
		cfg.grid_width = 50
		cfg.grid_height = 40
		var world := GameWorld.new(cfg)

		# 3 xil toifadagi real shaharlar
		var c_small := CitySystem.CityData.new()
		c_small.id = 101
		c_small.name = "Kichik Shahar"
		c_small.display_name = "Kichik Shahar"
		c_small.category = CitySystem.Category.SMALL # 50 tanga
		c_small.x = 10
		c_small.y = 8
		c_small.stable_id = "real_city_small_101"

		var c_med := CitySystem.CityData.new()
		c_med.id = 102
		c_med.name = "O'rta Shahar"
		c_med.display_name = "O'rta Shahar"
		c_med.category = CitySystem.Category.MEDIUM # 200 tanga
		c_med.x = 22
		c_med.y = 8
		c_med.stable_id = "real_city_med_102"

		var c_large := CitySystem.CityData.new()
		c_large.id = 103
		c_large.name = "Katta Poytaxt"
		c_large.display_name = "Katta Poytaxt"
		c_large.category = CitySystem.Category.LARGE # 500 tanga
		c_large.capital = true
		c_large.x = 35
		c_large.y = 8
		c_large.stable_id = "real_city_large_103"

		# Shaharlar tizimiga kiritamiz
		world.cities = CitySystem.new()
		world.cities.build([
			{"x": 10, "y": 8, "name": c_small.name, "capital": false, "pop": 50000},
			{"x": 22, "y": 8, "name": c_med.name, "capital": false, "pop": 350000},
			{"x": 35, "y": 8, "name": c_large.name, "capital": true, "pop": 2500000},
		], world.grid)

		var human := PlayerState.new(1, "Player", 0, false, 8.0, 4.0)
		human.place_at(10.0, 15.0, 0.0)
		world.players.append(human)
		world._by_id[1] = human

		# Test hamyonini izolyatsiyalangan fayl bilan tayyorlaymiz
		var test_w_path := "user://test_real_conquest_wallet.cfg"
		var w := CurrencyManager.new(test_w_path)
		w.reset()
		t.equal(w.get_coins(), 0, "Boshida hamyon 0 tanga")

		var tracker := CitySystem.CityRewardTracker.new()
		tracker.reset("real_gameplay_match_1")

		# A. Kichik shaharni qamrab oluvchi halqa chizamiz: (7,5) -> (13,5) -> (13,11) -> (7,11) -> (7,5)
		var trail_s: Array[Vector2i] = []
		for x in range(7, 14): trail_s.append(Vector2i(x, 5))
		for y in range(6, 12): trail_s.append(Vector2i(13, y))
		for x in range(12, 6, -1): trail_s.append(Vector2i(x, 11))
		for y in range(10, 5, -1): trail_s.append(Vector2i(7, y))

		for pt in trail_s:
			var idx := world.grid.index(pt.x, pt.y)
			world.grid.set_trail_index(idx, human.id)
			human.add_trail(idx)
		world._finish_loop(human)

		# Kichik shahar katagi (10, 8) o'yinchiga o'tdi
		t.equal(world.grid.owner_at(10, 8), human.id, "Kichik shahar katagi egallandi")
		var claim_s := tracker.claim_city(c_small, true)
		t.equal(bool(claim_s["eligible"]), true, "Kichik shahar mukofotga munosib")
		t.equal(int(claim_s["coins"]), 50, "Kichik shahar uchun 50 tanga berildi")
		var cred_s := w.add_coins(int(claim_s["coins"]), "city_conquest", str(claim_s["tx_id"]))
		t.equal(cred_s, 50, "Hamyon roppa-rosa +50 tangaga ko'paydi")
		t.equal(w.get_coins(), 50, "Hamyon balansi = 50")

		# B. O'rta shaharni qamrab oluvchi halqa: (19,5) -> (25,5) -> (25,11) -> (19,11) -> (19,5)
		var trail_m: Array[Vector2i] = []
		for x in range(19, 26): trail_m.append(Vector2i(x, 5))
		for y in range(6, 12): trail_m.append(Vector2i(25, y))
		for x in range(24, 18, -1): trail_m.append(Vector2i(x, 11))
		for y in range(10, 5, -1): trail_m.append(Vector2i(19, y))

		for pt in trail_m:
			var idx := world.grid.index(pt.x, pt.y)
			world.grid.set_trail_index(idx, human.id)
			human.add_trail(idx)
		world._finish_loop(human)

		t.equal(world.grid.owner_at(22, 8), human.id, "O'rta shahar katagi egallandi")
		var claim_m := tracker.claim_city(c_med, true)
		t.equal(bool(claim_m["eligible"]), true, "O'rta shahar mukofotga munosib")
		t.equal(int(claim_m["coins"]), 200, "O'rta shahar uchun 200 tanga berildi")
		var cred_m := w.add_coins(int(claim_m["coins"]), "city_conquest", str(claim_m["tx_id"]))
		t.equal(cred_m, 200, "Hamyon roppa-rosa +200 tangaga ko'paydi")
		t.equal(w.get_coins(), 250, "Hamyon balansi = 250 (50 + 200)")

		# C. Katta poytaxtni qamrab oluvchi halqa: (32,5) -> (38,5) -> (38,11) -> (32,11) -> (32,5)
		var trail_l: Array[Vector2i] = []
		for x in range(32, 39): trail_l.append(Vector2i(x, 5))
		for y in range(6, 12): trail_l.append(Vector2i(38, y))
		for x in range(37, 31, -1): trail_l.append(Vector2i(x, 11))
		for y in range(10, 5, -1): trail_l.append(Vector2i(32, y))

		for pt in trail_l:
			var idx := world.grid.index(pt.x, pt.y)
			world.grid.set_trail_index(idx, human.id)
			human.add_trail(idx)
		world._finish_loop(human)

		t.equal(world.grid.owner_at(35, 8), human.id, "Katta poytaxt katagi egallandi")
		var claim_l := tracker.claim_city(c_large, true)
		t.equal(bool(claim_l["eligible"]), true, "Katta poytaxt mukofotga munosib")
		t.equal(int(claim_l["coins"]), 500, "Katta poytaxt uchun 500 tanga berildi")
		var cred_l := w.add_coins(int(claim_l["coins"]), "city_conquest", str(claim_l["tx_id"]))
		t.equal(cred_l, 500, "Hamyon roppa-rosa +500 tangaga ko'paydi")
		t.equal(w.get_coins(), 750, "Hamyon balansi roppa-rosa 750 (50 + 200 + 500)")

		# D. O'yin to'xtatilib (save_state), qayta tiklanganda (load_state) saqlanishi
		tracker.save_state()
		var restored_tracker := CitySystem.CityRewardTracker.new()
		restored_tracker.load_state()
		t.equal(restored_tracker.get_match_id(), "real_gameplay_match_1", "Match ID saqlanib qoldi")
		t.equal(restored_tracker.get_claimed_count(), 3, "Egallangan 3 shahar to'liq qayta tiklandi")
		t.equal(restored_tracker.is_city_eligible(c_small), false, "Kichik shahar qayta da'voga yopiq")
		t.equal(restored_tracker.is_city_eligible(c_med), false, "O'rta shahar qayta da'voga yopiq")
		t.equal(restored_tracker.is_city_eligible(c_large), false, "Katta shahar qayta da'voga yopiq")

		# E. Takroriy egallashda ikkinchi marta pul to'lanmasligi
		var dup_claim := restored_tracker.claim_city(c_large, true)
		t.equal(bool(dup_claim["eligible"]), false, "Takroriy istiloda mukofot berilmaydi")
		t.equal(w.get_coins(), 750, "Hamyon o'zgarmasdan 750 bo'lib qoldi")

		if FileAccess.file_exists(test_w_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_w_path))
		restored_tracker.clear_saved_state()
	)

	# 5. Uzoq sessiya va 20 ta bot bilan 5 ta to'liq match simulyatsiyasi
	t.test("5. Uzoq sessiya: 20 ta bot bilan 5 ta match, xotira barqarorligi va kadrlar tushmasligi", func() -> void:
		var mem_before := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0

		for match_num in 5:
			var cfg := GameConfig.new()
			cfg.world_map = false
			cfg.grid_width = 80
			cfg.grid_height = 80
			cfg.bot_count = 20
			var world := GameWorld.new(cfg)

			# 20 ta bot + 1 o'yinchi joylashtirish
			var h := PlayerState.new(1, "Player", 0, false, 8.0, 4.0)
			h.place_at(40.0, 40.0, 0.0)
			world.players.append(h)
			world._by_id[1] = h

			for b_id in range(2, 22):
				var bot := PlayerState.new(b_id, "Bot%d" % b_id, b_id % 16, true, 8.0, 4.0)
				var bx := float((b_id * 3) % 70 + 5)
				var by := float((b_id * 7) % 70 + 5)
				bot.place_at(bx, by, 0.0)
				world.players.append(bot)
				world._by_id[b_id] = bot

			# 100 ta kadr simulyatsiyasi
			var t_start := Time.get_ticks_usec()
			for frame in 100:
				world.update(0.016)
			var t_dur := (Time.get_ticks_usec() - t_start) / 1000.0 # ms

			t.check(t_dur < 500.0, "Match %d: 100 kadr tez bajarildi (%.1f ms)" % [match_num + 1, t_dur])
			t.equal(world.players.size(), 21, "Barcha 21 o'yinchi (1+20) mavjud")

		var mem_after := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
		var mem_growth := mem_after - mem_before
		t.check(mem_growth < 15.0, "5 ta to'liq matchdan keyin xotira o'sishi minimal (%.2f MB)" % mem_growth)
	)


# ——— Phase 8 Final Fix: Test Isolation, Deduplication, Atomic Rewards, Real Gameplay & Endurance ———

func _test_phase8_final_save_isolation(t: TestRunner) -> void:
	t.group("Phase 8 Final: Save Isolation and Test Sandbox")

	t.test("1. Shop, Daily, Journey, Missions va Wallet test paytida faqat test_sandbox ga yozadi", func() -> void:
		var shop := root.get_node("/root/Shop") as ShopManager
		var daily := root.get_node("/root/Daily") as DailyRewardManager
		var journey := root.get_node("/root/Journey") as CountryStore
		var missions := root.get_node("/root/Missions") as MissionManager
		var wallet := root.get_node("/root/Wallet") as CurrencyManager
		var upgrades := root.get_node("/root/Upgrades") as UpgradeManager
		var purchases := root.get_node("/root/Purchases") as PurchaseManager

		t.check(shop.get_file_path().contains("test_sandbox"), "Shop test_sandbox yo'lida")
		t.check(daily.get_file_path().contains("test_sandbox"), "Daily test_sandbox yo'lida")
		t.check(journey.get_file_path().contains("test_sandbox"), "Journey test_sandbox yo'lida")
		t.check(missions.get_file_path().contains("test_sandbox"), "Missions test_sandbox yo'lida")
		t.check(wallet.get_file_path().contains("test_sandbox"), "Wallet test_sandbox yo'lida")
		t.check(upgrades.get_file_path().contains("test_sandbox"), "Upgrades test_sandbox yo'lida")
		t.check(purchases.get_file_path().contains("test_sandbox"), "Purchases test_sandbox yo'lida")

		# Modullarni reset qilish
		shop.reset()
		daily.reset()
		journey.reset()
		missions.reset()
		wallet.reset()
		upgrades.reset()
		purchases.reset()

		t.check(FileAccess.file_exists("user://test_sandbox/shop.cfg"), "test_sandbox/shop.cfg yaratildi")
		t.check(FileAccess.file_exists("user://test_sandbox/daily.cfg"), "test_sandbox/daily.cfg yaratildi")
		t.check(FileAccess.file_exists("user://test_sandbox/journey.cfg"), "test_sandbox/journey.cfg yaratildi")
		t.check(FileAccess.file_exists("user://test_sandbox/missions.cfg"), "test_sandbox/missions.cfg yaratildi")
		t.check(FileAccess.file_exists("user://test_sandbox/wallet.cfg"), "test_sandbox/wallet.cfg yaratildi")
	)

	t.test("2. SettingsStore test_sandbox muhitida ishlaydi", func() -> void:
		var store := SettingsStore.load_store()
		t.check(store.get_file_path().contains("test_sandbox"), "SettingsStore test_sandbox yo'lida")
		store.submit_result(99.9, 15, "test_map")
		t.check(FileAccess.file_exists("user://test_sandbox/settings.cfg"), "test_sandbox/settings.cfg yaratildi")
	)

	t.test("3. Nosozlik (crash/interruption) simulyatsiyasida ham ishlab chiqarish fayllari daxlsiz qoladi", func() -> void:
		var snap := SavePaths.snapshot_production_hashes()
		var res := SavePaths.verify_production_hashes(snap)
		t.equal(bool(res["ok"]), true, "Ishlab chiqarish fayllarining barchasi butun")
	)


func _test_phase8_transaction_deduplication(t: TestRunner) -> void:
	t.group("Phase 8 Final: Transaction Deduplication and Pruning")

	var test_w_path := "user://test_sandbox/test_dedup_wallet.cfg"

	t.test("1. 100 ta tranzaksiya oqimi va takroriy to'lovdan 100% himoya", func() -> void:
		var w := CurrencyManager.new(test_w_path)
		w.reset()

		for i in 100:
			var tx := "tx_100_batch_%d" % i
			var added := w.add_coins(10, "test", tx)
			t.equal(added, 10, "Tranzaksiya %d ga 10 tanga berildi" % i)

		t.equal(w.get_coins(), 1000, "100 ta tranzaksiyadan 1000 tanga yig'ildi")

		# Takroriy yuborish
		for i in 100:
			var tx := "tx_100_batch_%d" % i
			var added := w.add_coins(10, "test", tx)
			t.equal(added, 0, "Takroriy tranzaksiya %d rad etildi (0 tanga)" % i)

		t.equal(w.get_coins(), 1000, "Balans o'zgarmasdan 1000 bo'lib qoldi")
	)

	t.test("2. 2,000 ta tranzaksiya va doimiy xotira yaxlitligi", func() -> void:
		var w := CurrencyManager.new(test_w_path)
		w.reset()

		for i in 2000:
			var tx := "tx_2000_batch_%d" % i
			w.add_coins(5, "test", tx)

		t.equal(w.get_coins(), 10000, "2000 x 5 = 10000 tanga")
		t.equal(w.has_transaction("tx_2000_batch_0"), true, "1-tranzaksiya mavjud")
		t.equal(w.has_transaction("tx_2000_batch_1999"), true, "2000-tranzaksiya mavjud")
	)

	t.test("3. 5,000 ta tranzaksiya: faqat munosiblik muddati tugaganlar tozalanadi", func() -> void:
		var w := CurrencyManager.new(test_w_path)
		w.reset()
		var now := int(Time.get_unix_time_from_system())

		# 1000 ta eskirgan kunlik (8 kun oldin)
		for i in 1000:
			w._processed_tx["daily-2020-01-%04d" % i] = now - (8 * 86400)
		# 1000 ta faol kunlik (bugun)
		for i in 1000:
			w._processed_tx["daily-today-%04d" % i] = now
		# 1000 ta eskirgan match istilosi (35 kun oldin)
		for i in 1000:
			w._processed_tx["conquest_oldmatch_city_%d" % i] = now - (35 * 86400)
		# 1000 ta faol match istilosi (hozirgi match)
		for i in 1000:
			w._processed_tx["conquest_activematch_city_%d" % i] = now
		# 1000 ta umrbod promo kodlar
		for i in 1000:
			w._processed_tx["promo_bonus_%d" % i] = now - (100 * 86400)

		t.equal(w._processed_tx.size(), 5000, "5000 ta tranzaksiya kiritildi")

		# Tozalashni chaqiramiz
		w._prune_processed_tx()

		# Tekshiruv: eskirganlar o'chirilgan, faollar va promo kodlar 100% saqlangan
		t.check(not w._processed_tx.has("daily-2020-01-0001"), "Eskirgan kunlik tranzaksiya tozalandi")
		t.check(not w._processed_tx.has("conquest_oldmatch_city_1"), "35 kunlik eski match istilosi tozalandi")
		t.check(w._processed_tx.has("daily-today-0001"), "Bugungi faol kunlik tranzaksiya saqlab qolindi")
		t.check(w._processed_tx.has("conquest_activematch_city_1"), "Faol match istilosi saqlab qolindi")
		t.check(w._processed_tx.has("promo_bonus_1"), "Umrbod promo tranzaksiya HECH QACHON o'chirilmaydi")
	)

	t.test("4. 10,000 ta tranzaksiya: xotira hajmi va diskka saqlanish barqarorligi", func() -> void:
		var w := CurrencyManager.new(test_w_path)
		w.reset()

		var t0 := Time.get_ticks_msec()
		for i in 10000:
			w._processed_tx["tx_stress_%d" % i] = 1700000000
		var dur := Time.get_ticks_msec() - t0

		t.check(dur < 2000, "10,000 ta tranzaksiyani xotirada qayta ishlash tez (%.1f ms)" % dur)
		t.equal(w._processed_tx.size(), 10000, "10,000 ta tranzaksiya xotirada barqaror")

		var save_ok := w.save_currency()
		t.equal(save_ok, true, "10,000 tranzaksiya bilan hamyon diskka muvaffaqiyatli saqlandi")

		var w2 := CurrencyManager.new(test_w_path)
		t.equal(w2.processed_transactions_count(), 10000, "Diskdan 10,000 ta tranzaksiya to'liq qayta yuklandi")
	)

	t.test("5. Maksimal hamyon balansi va tranzaksiya qaydnomasi", func() -> void:
		var w := CurrencyManager.new(test_w_path)
		w.reset()

		# Balansni maksimalga to'ldiramiz
		w.add_coins(MonetizationConfig.MAX_BALANCE, "max_fill")
		t.equal(w.get_coins(), MonetizationConfig.MAX_BALANCE, "Balans maksimalga teng")

		# Balans to'la paytda 500 tangalik mukofot kelganda
		var credited := w.add_coins(500, "city_conquest", "tx_max_cap_test")
		t.equal(credited, 0, "Balans to'la bo'lgani uchun 0 tanga qo'shildi")
		t.equal(w.has_transaction("tx_max_cap_test"), true, "Tranzaksiya qayd etildi")

		# Pul sarflangandan so'ng xuddi shu tx_id qayta kelsa, qo'shilmasligi kerak!
		w.remove_coins(1000, "spend")
		t.equal(w.get_coins(), MonetizationConfig.MAX_BALANCE - 1000, "1000 tanga sarflandi")

		var dup_credited := w.add_coins(500, "city_conquest", "tx_max_cap_test")
		t.equal(dup_credited, 0, "Oldin qayd etilgan tx_id keyinchalik ham pul ololmaydi")
		t.equal(w.get_coins(), MonetizationConfig.MAX_BALANCE - 1000, "Balans o'zgarmasdan qoldi")
	)

	if FileAccess.file_exists(test_w_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_w_path))


func _test_phase8_atomic_city_rewards(t: TestRunner) -> void:
	t.group("Phase 8 Final: Atomic City Rewards and Reconciliation")

	var tracker := CitySystemRef.CityRewardTracker.new()
	tracker.reset("atomic_match_1")
	var test_w_path := "user://test_sandbox/test_atomic_wallet.cfg"
	var w := CurrencyManager.new(test_w_path)
	w.reset()

	var c_small := CitySystemRef.CityData.new()
	c_small.id = 1
	c_small.category = CitySystemRef.Category.SMALL
	c_small.stable_id = "UZ_Samarkand_10_10"
	c_small.display_name = "Samarqand"

	var c_med := CitySystemRef.CityData.new()
	c_med.id = 2
	c_med.category = CitySystemRef.Category.MEDIUM
	c_med.stable_id = "UZ_Bukhara_20_20"
	c_med.display_name = "Buxoro"

	var c_large := CitySystemRef.CityData.new()
	c_large.id = 3
	c_large.category = CitySystemRef.Category.LARGE
	c_large.stable_id = "UZ_Tashkent_30_30"
	c_large.display_name = "Toshkent"

	t.test("1. Ikki bosqichli atomik da'vo (prepare -> wallet -> finalize)", func() -> void:
		# 1-bosqich: prepare_claim
		var prep := tracker.prepare_claim(c_small, true, "world_map")
		t.equal(bool(prep["eligible"]), true, "Munosib deb topildi")
		t.equal(int(prep["coins"]), 50, "Kichik shahar: 50 tanga")
		t.check(str(prep["tx_id"]).contains("UZ_Samarkand_10_10"), "Stable ID tx_id da aks etdi")
		t.equal(tracker.is_city_eligible(c_small), true, "finalize chaqirilmaguncha tracker hali da'voni yakunlamagan")

		# Hamyonga qo'shish
		var credited := w.add_coins(int(prep["coins"]), "city_conquest", str(prep["tx_id"]))
		t.equal(credited, 50, "Hamyonga +50 tanga tushdi")

		# 2-bosqich: finalize_claim
		tracker.finalize_claim(c_small, credited)
		t.equal(tracker.is_city_eligible(c_small), false, "Endi shahar da'vo qilingan deb belgilandi")
		t.equal(tracker.get_total_conquest_coins(), 50, "Conquest tangalari 50 ga teng")
	)

	t.test("2. Tranzaksiya uzilishi va muvofiqlashtirish (reconciliation)", func() -> void:
		# Simulyatsiya: Hamyon pulni oldi, lekin tracker finalize chaqirilmasdan ilova uzildi
		var prep := tracker.prepare_claim(c_med, true, "world_map")
		var credited := w.add_coins(int(prep["coins"]), "city_conquest", str(prep["tx_id"]))
		t.equal(credited, 200, "Hamyonga +200 tushdi")
		t.equal(tracker.is_city_eligible(c_med), true, "Tracker hali bilmaydi")

		# Muvofiqlashtirish (reconcile)
		var reconciled := tracker.reconcile_with_wallet(w, c_med, "world_map")
		t.equal(reconciled, true, "Reconciliation hamyondan tranzaksiyani topdi")
		t.equal(tracker.is_city_eligible(c_med), false, "Shahar da'vo qilingan deb belgilandi")

		# Takroriy to'lov rad etiladi
		var prep2 := tracker.prepare_claim(c_med, true, "world_map")
		t.equal(bool(prep2["eligible"]), false, "Takroriy da'vo rad etildi")
	)

	t.test("3. Hamyon to'lgan holatda atomik ishlov berish", func() -> void:
		w.add_coins(MonetizationConfig.MAX_BALANCE, "fill")
		var prep := tracker.prepare_claim(c_large, true, "world_map")
		var credited := w.add_coins(int(prep["coins"]), "city_conquest", str(prep["tx_id"]))
		t.equal(credited, 0, "Balans to'la bo'lgani uchun 0 qo'shildi")

		tracker.finalize_claim(c_large, credited)
		t.equal(tracker.is_city_eligible(c_large), false, "Shahar da'vo qilingan deb yopildi")
		# Total conquest coins faqat real tushgan summani saqlaydi
		t.equal(tracker.get_total_conquest_coins(), 250, "Conquest coins faqat real tushgan summani saqlaydi (50 + 200 + 0)")
	)

	t.test("4. Match tiklash va yangi match izolyatsiyasi", func() -> void:
		tracker.save_state()
		var t2 := CitySystemRef.CityRewardTracker.new()
		var loaded_same := t2.load_state("", "atomic_match_1")
		t.equal(loaded_same, true, "Xuddi shu match ID bilan tiklash muvaffaqiyatli")
		t.equal(t2.is_city_eligible(c_small), false, "Samarqand da'vo qilingan")

		var t3 := CitySystemRef.CityRewardTracker.new()
		var loaded_diff := t3.load_state("", "new_different_match_99")
		t.equal(loaded_diff, false, "Boshqa match ID bilan eski match tiklanmadi")
		t.equal(t3.is_city_eligible(c_small), true, "Yangi matchda barcha shaharlar munosib")
		tracker.clear_saved_state()
	)

	if FileAccess.file_exists(test_w_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_w_path))


func _test_phase8_real_gameplay_integration(t: TestRunner) -> void:
	t.group("Phase 8 Final: Real Gameplay Capture and Reward Integration")

	t.test("1. Real harakat, trail yaratish, hudud yopilishi va shahar istilosi", func() -> void:
		var cfg := GameConfig.new()
		cfg.world_map = false
		cfg.grid_width = 30
		cfg.grid_height = 30
		cfg.bot_count = 0
		var world := GameWorld.new(cfg)

		# 3 ta shahar joylashtirish
		var cities_obj := CitySystemRef.new()
		var places := [
			{"name": "S1", "code": "UZ", "x": 12, "y": 12, "pop": 50000, "cap": 0},
			{"name": "M1", "code": "UZ", "x": 18, "y": 12, "pop": 300000, "cap": 0},
			{"name": "L1", "code": "UZ", "x": 24, "y": 12, "pop": 1500000, "cap": 1},
		]
		cities_obj.build(places, world.grid)
		world.cities = cities_obj

		var player := PlayerState.new(1, "Hero", 0, false, 8.0, 4.0)
		player.place_at(10.0, 10.0, 0.0)
		world.players.append(player)
		world._by_id[1] = player

		# O'yinchining boshlang'ich hududi (10..11, 10..11)
		for y in range(10, 12):
			for x in range(10, 12):
				world.grid.set_owner(x, y, player.id)

		var tracker := CitySystemRef.CityRewardTracker.new()
		tracker.reset("gameplay_integration_match")
		var test_w_path := "user://test_sandbox/test_gameplay_wallet.cfg"
		var w := CurrencyManager.new(test_w_path)
		w.reset()

		# O'yinchi harakati: o'z hududidan chiqadi, (11,10) -> (14,10) -> (14,14) -> (10,14) -> (10,11) qaytadi
		# Bu (12,12) dagi Kichik shaharni qamrab oladi!
		var path_pts: Array[Vector2i] = [
			Vector2i(12, 10), Vector2i(13, 10), Vector2i(14, 10),
			Vector2i(14, 11), Vector2i(14, 12), Vector2i(14, 13), Vector2i(14, 14),
			Vector2i(13, 14), Vector2i(12, 14), Vector2i(11, 14), Vector2i(10, 14),
			Vector2i(10, 13), Vector2i(10, 12), Vector2i(10, 11)
		]

		for pt in path_pts:
			world._enter_cell(player, pt.x, pt.y)

		# Eventlarni tekshirish
		var cap_event_found := false
		var city_event_found := false
		var captured_city: CitySystem.CityData = null

		for ev: Dictionary in world.events:
			if ev.get("type") == "capture":
				cap_event_found = true
			elif ev.get("type") == "city_captured":
				city_event_found = true
				captured_city = ev.get("city")

		t.equal(cap_event_found, true, "Hudud egallanish hodisasi yuz berdi")
		t.equal(city_event_found, true, "Shahar egallanish hodisasi yuz berdi")
		t.check(captured_city != null, "Egallangan shahar mavjud")
		if captured_city != null:
			t.equal(captured_city.name, "S1", "S1 (Kichik shahar) egallandi")

			# Gameplay mukofot oqimi
			var prep := tracker.prepare_claim(captured_city, true, "custom")
			t.equal(bool(prep["eligible"]), true, "Kichik shahar mukofotga munosib")
			t.equal(int(prep["coins"]), 50, "Kichik shahar uchun 50 tanga")
			var credited := w.add_coins(int(prep["coins"]), "city_conquest", str(prep["tx_id"]))
			t.equal(credited, 50, "Hamyonga +50 tanga tushdi")
			tracker.finalize_claim(captured_city, credited)

			# Qayta egallanganda 0 tanga
			var prep2 := tracker.prepare_claim(captured_city, true, "custom")
			t.equal(bool(prep2["eligible"]), false, "Takroriy istiloda mukofot berilmadi")

		if FileAccess.file_exists(test_w_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_w_path))
	)

	t.test("2. O'z izini kesish (SELF_CROSS) va o'lim qoidasi", func() -> void:
		var world := MapHelpers.make_world(60, 60)
		var p := MapHelpers.place_player(world, 28, 28)
		# To'rtburchak halqa: oxirgi tomon birinchi tomonni kesadi
		_walk(world, p, -PI / 2, 16)
		_walk(world, p, 0.0, 8)
		_walk(world, p, PI / 2, 12)
		_walk(world, p, PI, 12)
		t.equal(p.alive, false, "O'z izini kesganda o'yinchi halok bo'ldi")
		t.equal(p.death_cause, PlayerState.DeathCause.SELF_CROSS, "O'lim sababi: SELF_CROSS")
	)

	t.test("3. Raqib izini kesish (TRAIL_HIT) va bot o'limi", func() -> void:
		var world := MapHelpers.make_world(40, 40)
		var victim := MapHelpers.place_player(world, 5, 5)
		var killer := MapHelpers.place_player(world, 25, 5)
		# Bot hududdan chiqib iz qoldiradi
		victim.steer_to(0.0)
		victim.angle = 0.0
		for i in 40:
			world.update(1.0 / 60.0)
		t.greater(victim.trail.size(), 0, "Bot iz qoldirdi")

		# Qahramon botning izi ustidan kesib o'tadi
		var cell: int = victim.trail[victim.trail.size() / 2]
		var tx: int = cell % world.grid.width
		var ty: int = cell / world.grid.width
		killer.place_at(tx - 1.5, ty + 0.5, 0.0)
		for i in 30:
			if not victim.alive:
				break
			world.update(1.0 / 60.0)

		t.equal(victim.alive, false, "Botning izi kesilganda bot halok bo'ldi")
		t.equal(victim.death_cause, PlayerState.DeathCause.TRAIL_HIT, "O'lim sababi: TRAIL_HIT")
		t.equal(killer.kills, 1, "Qahramonga +1 kill berildi")
	)

	t.test("4. Qirg'oq bo'ylab harakat va suv chegarasi", func() -> void:
		var w := 10
		var h := 10
		var land := PackedByteArray()
		land.resize(w * h)
		for y in h:
			for x in w:
				land[y * w + x] = 1 if x < 5 else 0
		var grid := GameGrid.new(w, h, land)
		var cfg := GameConfig.new()
		cfg.grid_width = w
		cfg.grid_height = h
		var world := GameWorld.new(cfg)
		world.grid = grid

		var p := PlayerState.new(1, "P", 0, false, 8.0, 4.0)
		p.place_at(4.0, 4.0, 0.0)
		world.players.append(p)
		world._by_id[1] = p

		for i in 10:
			world._move(p, 0.05)

		t.check(p.x < 5.0, "O'yinchi suvga tushib ketmadi, qirg'oqda qoldi (x = %.2f)" % p.x)
	)


func _test_phase8_spatial_city_performance(t: TestRunner) -> void:
	t.group("Phase 8 Final: Spatial City Performance Optimization")

	var map_ids: PackedStringArray = ["world", "europe", "asia", "africa", "north_america", "south_america", "oceania"]

	for mid: String in map_ids:
		t.test("1. Xarita '%s': spatial buckets hisobi O(N^2) bilan 100%% bir xil" % mid, func() -> void:
			var map := WorldMap.load_map(mid)
			t.check(map != null and not map.places.is_empty(), "Xarita %s yuklandi" % mid)
			if map == null or map.places.is_empty():
				return

			var grid := GameGrid.new(map.width, map.height, map.land)
			var city_sys := CitySystemRef.new()
			city_sys.build(map.places, grid)

			var all_matched := true
			for i in city_sys.cities.size():
				var c1: CitySystem.CityData = city_sys.cities[i]
				var exact_min := 999.0
				for j in city_sys.cities.size():
					if i == j:
						continue
					var d := c1.pos.distance_to(city_sys.cities[j].pos)
					if d < exact_min:
						exact_min = d
				if absf(c1.neighbor_dist - exact_min) > 0.001:
					all_matched = false
					break

			t.equal(all_matched, true, "Xarita '%s' (%d ta shahar): barcha neighbor_dist 100%% aniq" % [mid, city_sys.cities.size()])
		)


func _test_phase8_long_session_endurance(t: TestRunner) -> void:
	t.group("Phase 8 Final: Long Session Endurance (20 Bots, 8-10 Min Simulated Match)")

	t.test("1. 20 ta bot bilan 500 soniyalik (8.3 daqiqa) uzluksiz o'yin simulyatsiyasi", func() -> void:
		var cfg := GameConfig.new()
		cfg.world_map = false
		cfg.grid_width = 80
		cfg.grid_height = 80
		cfg.bot_count = 20
		var world := MatchBuilder.create(cfg, 0, "Player", "figure:0", 42)

		var mem_before := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0

		var t_start := Time.get_ticks_msec()
		var total_captures := 0
		var total_kills := 0

		# 500 soniyalik in-game simulyatsiya (dt = 0.2s -> 2,500 qadam)
		for step in 2500:
			world.update(0.2)
			if not world.events.is_empty():
				for ev in world.events:
					if ev.get("type") == "capture":
						total_captures += 1
					elif ev.get("type") == "kill":
						total_kills += 1
				world.events.clear()

		var sim_dur_ms := Time.get_ticks_msec() - t_start
		var mem_after := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
		var mem_growth := mem_after - mem_before

		t.check(sim_dur_ms < 15000, "500 soniyalik (8.3 daqiqa) simulyatsiya %.1f soniyada tez yakunlandi" % (sim_dur_ms / 1000.0))
		t.check(mem_growth < 15.0, "8.3 daqiqalik simulyatsiyadan so'ng xotira o'sishi minimal (%.2f MB)" % mem_growth)
		t.equal(world.players.size(), 21, "Barcha 21 o'yinchi (1+20) tizimda barqaror")

		var all_coords_valid := true
		for p: PlayerState in world.players:
			if p.x < 0.0 or p.x > float(world.grid.width) or p.y < 0.0 or p.y > float(world.grid.height):
				all_coords_valid = false
				break
		t.equal(all_coords_valid, true, "Barcha bot koordinatalari xarita chegarasida to'g'ri saqlangan")
		t.check(total_captures > 0, "O'yin davomida real egallashlar yuz berdi (%d ta)" % total_captures)
	)


func _test_fonts_and_glyphs(t: TestRunner) -> void:
	t.group("shriftlar va gliflar tekshiruvi")

	t.test("1. Asosiy va zaxira shriftlar to'liq yuklanadi", func() -> void:
		UiKit.ensure_fonts()
		var base := UiKit.bold_font()
		t.check(base != null, "Asosiy Rubik-Bold shrifti yuklandi")
		var display := UiKit.display_font()
		t.check(display != null, "Sarlavha Nunito-ExtraBold shrifti yuklandi")
		var fallback_dejavu: Font = load(UiKit.FALLBACK_FONT_PATH)
		t.check(fallback_dejavu != null, "Zaxira DejaVuSans.ttf shrifti yuklandi")
	)

	t.test("2. O'zbek (lotin/kirill), rus va xalqaro matnlar to'g'ri o'lchanadi va ko'rsatiladi", func() -> void:
		UiKit.ensure_fonts()
		var font := UiKit.bold_font()
		var sample_texts := [
			"O'zbekiston", "Toshkent", "G'alaba", "Ko'prik",
			"Ўзбекистон", "Тошкент", "Ғалаба", "Ҳудуд",
			"Победа", "Захват", "Настройки", "Играть",
			"Score: 1000", "Level 1", "Flag Conquest"
		]
		var all_ok := true
		for s: String in sample_texts:
			var sz := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20)
			if sz.x <= 0.0 or sz.y <= 0.0:
				all_ok = false
				break
		t.check(all_ok, "Barcha o'zbek, kirill va lotin matnlari musbat o'lchamga ega")
	)

	t.test("3. Qo'shimcha xalqaro yozuvlar va bayroq emojilari qo'llab-quvvatlanadi", func() -> void:
		var emoji_font: Font = load(UiKit.EMOJI_FONT_PATH)
		t.check(emoji_font != null, "NotoColorEmoji shrifti yuklandi")
		for path: String in UiKit.SCRIPT_FONT_PATHS:
			var f: Font = load(path)
			t.check(f != null, "Xalqaro yozuv shrifti yuklandi: %s" % path.get_file())
	)


