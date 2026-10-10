extends SceneTree

## Xaritada nechta shaharning nomi yoziladi va bitta ekranga
## nechtasi tushadi — `capital_marks.gd` dagi oraliqlarni shu bilan
## sozlangan.
##
##   godot --headless --path . --script res://tools/nametest.gd
##
## "Bir ekran" — kameraning taxminiy ko'rish maydoni: 37 katak
## keng, 55 katak chuqur (balandlik 48, orqaga 36, fov 58°).

const VIEW_HALF_X := 18.5
const VIEW_HALF_Y := 27.5
const SAMPLES := 200

func _process(_delta: float) -> bool:
	for map_id: String in ["world", "asia", "europe", "north_america",
			"africa", "south_america", "oceania"]:
		var map := WorldMap.load_map(map_id)
		var grid := GameGrid.new(map.width, map.height, map.land)
		var marks: Node = load("res://scripts/render/capital_marks.gd").new()
		root.add_child(marks)
		var total: int = marks.build(map.places, grid)
		var named: Array = marks._named

		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var dots := 0
		var names := 0
		var taken := 0
		# Tugunlar havzasi (POOL) yetarlimi: NAME_RANGE doirasiga
		# tushadigan nomlar undan ko'p bo'lsa, eng chetdagisi
		# goh ko'rinib goh yo'qolib miltillaydi.
		var range2: float = marks.NAME_RANGE * marks.NAME_RANGE
		var in_range_max := 0
		while taken < SAMPLES:
			var cx := rng.randf_range(0.0, map.width)
			var cy := rng.randf_range(0.0, map.height)
			if not grid.playable(int(cx), int(cy)):
				continue
			taken += 1
			for c: Dictionary in map.places:
				if absf(c["x"] - cx) < VIEW_HALF_X \
						and absf(c["y"] - cy) < VIEW_HALF_Y:
					dots += 1
			var here := Vector2(cx, cy)
			var in_range := 0
			for row: Dictionary in named:
				if absf(row["at"].x - cx) < VIEW_HALF_X \
						and absf(row["at"].y - cy) < VIEW_HALF_Y:
					names += 1
				if here.distance_squared_to(row["at"]) <= range2:
					in_range += 1
			in_range_max = maxi(in_range_max, in_range)

		print("%-14s shahar %4d, nomlanadi %4d (%2.0f%%);  " % [
				map_id, total, named.size(),
				100.0 * named.size() / maxi(total, 1)]
			+ "bir ekranda %.1f nuqta, %.1f nom;  " % [
				float(dots) / SAMPLES, float(names) / SAMPLES]
			+ "havza %d / %d" % [in_range_max, marks.POOL])
		marks.queue_free()
	quit()
	return true
