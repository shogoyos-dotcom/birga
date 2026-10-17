extends SceneTree

const TestRunner := preload("res://tests/test_runner.gd")
const MapHelpers := preload("res://tests/map_helpers.gd")

## Headless test kiruvchi nuqtasi:
##   godot --headless --script res://tests/run_tests.gd

## Testlar birinchi kadrda ishlaydi, `_initialize` da emas:
## avtoyuklanadigan modullar (Wallet, Shop, Missions va hokazo)
## faqat daraxt tiklangandan keyin paydo bo'ladi.
func _process(_delta: float) -> bool:
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
	quit(0 if t.report() else 1)
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
		view_unlocked.queue_free()
		view_locked.queue_free()
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


