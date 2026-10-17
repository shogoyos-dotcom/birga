extends SceneTree

const WorldPacing = preload("res://scripts/logic/world_pacing.gd")

func _initialize() -> void:
	print("================================================================================")
	print("SIMULATING FULL MATCH ON EXPANDED WORLD (920x466, 20 BOTS)")
	print("================================================================================")
	
	var config := GameConfig.new()
	config.apply_pacing(WorldPacing.SCALE_EXPANDED)
	config.map_id = "world"
	config.bot_count = 20
	
	print("Config: scale=%d, size=%dx%d, bots=%d, speed=%.1f, start_block=%d" % [
		config.world_scale, config.grid_width, config.grid_height, config.bot_count, config.player_speed, config.start_block
	])
	
	var world := MatchBuilder.create(config, 0, "HumanPlayer", "slime", 1, "UZ")
	var human := world.human()
	# Give human player bot brain with normal difficulty so it plays realistically
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	human.brain = BotBrain.new(config.difficulty, rng)
	
	print("Initial players spawned: %d" % world.players.size())
	print("Human spawned at: (%.1f, %.1f)" % [human.x, human.y])
	
	# Track metrics over 12 minutes (720 seconds) of game time
	var max_sim_time: float = 720.0 # 12 minutes
	var step: float = 1.0 / 30.0
	var sim_start_ticks := Time.get_ticks_msec()
	
	var encounters_50 := 0 # within 50 units (screen view)
	var encounters_100 := 0 # within 100 units
	var capture_count := 0
	var player_kills := 0
	var bot_kills := 0
	var interval_timer := 0.0
	
	print("\n--- Match Progress Timeline ---")
	print("Time (min) | Human % | Alive Bots | Nearest Bot Dist | Human Kills | Total Captures")
	print("--------------------------------------------------------------------------------")
	
	while world.elapsed < max_sim_time:
		world.update(step)
		
		# Check distance to nearest bot
		var min_bot_dist := 99999.0
		for p in world.players:
			if p != human and p.alive:
				var d: float = Vector2(p.x - human.x, p.y - human.y).length()
				if d < min_bot_dist:
					min_bot_dist = d
				if d <= 50.0:
					encounters_50 += 1
				if d <= 100.0:
					encounters_100 += 1
		
		for ev in world.drain_events():
			if ev["type"] == "capture":
				capture_count += 1
			elif ev["type"] == "death":
				if ev.has("killer") and ev["killer"] != null:
					if ev["killer"] == human.id:
						player_kills += 1
					else:
						bot_kills += 1
		
		interval_timer += step
		if interval_timer >= 60.0: # Report every minute
			interval_timer = 0.0
			var mins := int(world.elapsed / 60.0)
			var h_pct := world.percent_of(human)
			var alive := world.alive_count() - (1 if human.alive else 0)
			print(String("%7d min | %6.2f%% | %10d | %16.1f | %11d | %14d" % [
				mins, h_pct, alive, min_bot_dist, player_kills, capture_count
			]))
			
		# Check if match ended by domination
		if world.percent_of(human) >= 50.0:
			print("DOMINATION: Human reached >50% territory at %.1f minutes!" % (world.elapsed / 60.0))
			break
			
	var real_calc_ms := Time.get_ticks_msec() - sim_start_ticks
	print("--------------------------------------------------------------------------------")
	print("SIMULATION FINISHED:")
	print("Simulated Match Duration: %.1f seconds (%.2f minutes)" % [world.elapsed, world.elapsed / 60.0])
	print("Real Compute Time: %d ms (%.2fx faster than real-time)" % [real_calc_ms, (world.elapsed * 1000.0) / float(real_calc_ms)])
	print("Total Captures: %d" % capture_count)
	print("Player Kills: %d, Bot Kills: %d" % [player_kills, bot_kills])
	print("Player Final Territory: %.2f%%" % world.percent_of(human))
	print("Screen-view Encounters (dist < 50): %d samples" % encounters_50)
	print("Near-view Encounters (dist < 100): %d samples" % encounters_100)
	print("================================================================================")
	quit(0)
