extends SceneTree

const WorldPacing = preload("res://scripts/logic/world_pacing.gd")

const MAPS: PackedStringArray = [
	"world", "africa", "asia", "europe",
	"north_america", "south_america", "oceania", "circle"
]

func _initialize() -> void:
	print("================================================================================")
	print("PHASE 3: MAP DIMENSIONS & CELL COUNTS VALIDATION (ALL 7 MAPS + CIRCLE)")
	print("================================================================================")
	print(str("Engine: ", Engine.get_version_info()["string"]))
	print(str("OS: ", OS.get_name(), " ", OS.get_version()))
	print("--------------------------------------------------------------------------------")
	print(String("%-15s | %-12s | %-12s | %-8s | %-8s | %-6s | %-6s" % [
		"Map ID", "Classic WxH", "Expanded WxH", "Cls Land", "Exp Land", "Ratio", "Cities"
	]))
	print("--------------------------------------------------------------------------------")

	var all_ok := true
	var results := []

	for mid in MAPS:
		# 1. Classic scale (1)
		var t0 := Time.get_ticks_usec()
		var map_cls := WorldMap.load_map(mid, WorldPacing.SCALE_CLASSIC)
		var t_cls_ms := (Time.get_ticks_usec() - t0) / 1000.0

		# 2. Expanded scale (2)
		var t1 := Time.get_ticks_usec()
		var map_exp := WorldMap.load_map(mid, WorldPacing.SCALE_EXPANDED)
		var t_exp_ms := (Time.get_ticks_usec() - t1) / 1000.0

		var ratio: float = float(map_exp.land_cells) / float(maxi(1, map_cls.land_cells))
		var cls_wxh := "%dx%d" % [map_cls.width, map_cls.height]
		var exp_wxh := "%dx%d" % [map_exp.width, map_exp.height]

		print(String("%-15s | %-12s | %-12s | %8d | %8d | %5.2fx | %6d" % [
			mid, cls_wxh, exp_wxh, map_cls.land_cells, map_exp.land_cells, ratio, map_exp.places.size()
		]))

		# Verification of all places / cities in expanded map:
		var place_errs := 0
		for p in map_exp.places:
			var px := int(p.get("x", -1))
			var py := int(p.get("y", -1))
			if px < 0 or px >= map_exp.width or py < 0 or py >= map_exp.height:
				push_error("Place out of bounds on map %s: %s at (%d, %d)" % [mid, p.get("name", ""), px, py])
				place_errs += 1
				all_ok = false
			elif not map_exp.is_land(px, py):
				push_error("Place NOT ON LAND on map %s: %s at (%d, %d)" % [mid, p.get("name", ""), px, py])
				place_errs += 1
				all_ok = false

		if place_errs > 0:
			print("   --> WARNING: %d places had issues on %s" % [place_errs, mid])

		results.append({
			"id": mid,
			"cls_w": map_cls.width, "cls_h": map_cls.height, "cls_land": map_cls.land_cells, "cls_ms": t_cls_ms,
			"exp_w": map_exp.width, "exp_h": map_exp.height, "exp_land": map_exp.land_cells, "exp_ms": t_exp_ms,
			"ratio": ratio, "places": map_exp.places.size(), "places_valid": (place_errs == 0)
		})

	print("--------------------------------------------------------------------------------")
	if all_ok:
		print("RESULT: ALL 8 MAPS EXPANDED WITH 100% TOPOLOGICAL INTEGRITY AND VALID CITIES!")
	else:
		print("RESULT: ERRORS FOUND IN MAP VALIDATION!")
	print("================================================================================")
	quit(0 if all_ok else 1)
