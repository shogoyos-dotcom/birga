extends SceneTree

## Kadr sakrashini o'lchaydi: qaysi amal qancha vaqt oladi.
##
## Har kadrda `world.update()` ning vaqti o'lchanadi va 3 ms dan
## oshgan kadrlar sababi bilan yoziladi — nechta katak egallandi,
## o'yinchining to'rtburchagi qancha katak edi.

func _initialize() -> void:
	var rows: Array = []
	var buckets := {}
	for m in 3:
		var config := GameConfig.new()
		config.map_id = "world"
		config.bot_count = 15
		var world := MatchBuilder.create(config, m, "Men", "figure:0", m + 1)
		var rng := RandomNumberGenerator.new()
		rng.seed = m * 1013 + 7
		world.human().brain = BotBrain.new(config.difficulty, rng)
		var step := 1.0 / 60.0
		while world.elapsed < 300.0:
			var at := Time.get_ticks_usec()
			world.update(step)
			var took := (Time.get_ticks_usec() - at) / 1000.0
			var captured := 0
			var deaths := 0
			var area := 0
			for event in world.drain_events():
				if event["type"] == "capture":
					captured += (event["cells"] as PackedInt32Array).size()
					var box := world.grid.bounds_of(int(event["player"]))
					if not box.is_empty():
						area = maxi(area,
							(box[2] - box[0] + 1) * (box[3] - box[1] + 1))
				elif event["type"] == "death":
					deaths += 1
			if took > 3.0:
				rows.append({"ms": took, "cells": captured,
					"area": area, "deaths": deaths})
			# To'rtburchak kattaligi bo'yicha o'rtacha vaqt.
			if captured > 0 and area > 0:
				var key: int = int(pow(2, floor(log(area) / log(2))))
				if not buckets.has(key):
					buckets[key] = [0.0, 0]
				buckets[key][0] += took
				buckets[key][1] += 1

	rows.sort_custom(func(a, b): return a["ms"] > b["ms"])
	print("\n=== eng sekin 12 kadr ===")
	for i in mini(12, rows.size()):
		var r: Dictionary = rows[i]
		print("  %6.2f ms   %5d katak egallandi   to'rtburchak %7d   %d o'lim"
			% [r["ms"], r["cells"], r["area"], r["deaths"]])
	print("\n3 ms dan oshgan kadrlar: %d ta (15 daqiqalik o'yinda, 54 000 kadr)"
		% rows.size())

	print("\n=== to'rtburchak kattaligi -> o'rtacha kadr vaqti ===")
	var keys := buckets.keys()
	keys.sort()
	for key: int in keys:
		var pair: Array = buckets[key]
		print("  %7d katakgacha   %6.3f ms   (%d marta)"
			% [key * 2, pair[0] / pair[1], pair[1]])
	quit(0)
