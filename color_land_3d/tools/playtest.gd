extends SceneTree

## O'yinni 30 marta to'liq o'ynab chiqadi va nosozlik belgilarini
## sanaydi.
##
## O'yinchini ham bot miyasi boshqaradi — shunda haqiqiy o'yin
## sharoiti chiqadi: hudud egallash, o'lim, qayta tug'ilish, qirg'oq
## bo'ylab yurish. Har o'yindan keyin panjara va o'yinchilar holati
## tekshiriladi.
##
##   godot --headless --script res://tools/playtest.gd -- 30 90

const MAPS: PackedStringArray = [
	"world", "africa", "asia", "europe",
	"north_america", "south_america", "oceania", "circle",
]
const LEVELS: PackedStringArray = ["easy", "normal", "hard"]

## O'yinchi shuncha vaqt qimirlamasa — tiqilib qolgan hisoblanadi.
const STUCK_SECONDS := 3.0

var _matches := 30
var _seconds := 90.0
var _problems := {}
var _rows: Array = []
## O'lim sabablari: kim nimadan o'ldi.
var _causes := {}
## Eng sekin kadr (millisekund).
var _slowest := 0.0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_matches = int(args[0])
	if args.size() > 1:
		_seconds = float(args[1])
	var started := Time.get_ticks_msec()
	for i in _matches:
		_play(i)
	_report(Time.get_ticks_msec() - started)
	quit(1 if not _problems.is_empty() else 0)

func _note(key: String, detail: String = "") -> void:
	if not _problems.has(key):
		_problems[key] = {"count": 0, "first": detail}
	_problems[key]["count"] += 1

func _play(index: int) -> void:
	var config := GameConfig.new()
	config.map_id = MAPS[index % MAPS.size()]
	config.difficulty = Difficulty.from_name(LEVELS[index % LEVELS.size()])
	config.bot_count = 15
	var world := MatchBuilder.create(
		config, index % 16, "Men", "emoji:\U01F98A", index + 1, "UZ")
	# O'yinchini ham bot miyasi boshqaradi.
	var me := world.human()
	var rng := RandomNumberGenerator.new()
	rng.seed = index * 7919 + 13
	me.brain = BotBrain.new(config.difficulty, rng)

	var step := 1.0 / 60.0
	var last := {}
	var still := {}
	var deaths := 0
	var respawns := 0
	var max_trail := 0
	var best_percent := 0.0
	var captures := 0
	var empty_captures := 0

	while world.elapsed < _seconds:
		var tick := Time.get_ticks_usec()
		world.update(step)
		_slowest = maxf(_slowest, (Time.get_ticks_usec() - tick) / 1000.0)
		for event in world.drain_events():
			match event["type"]:
				"capture":
					captures += 1
					if (event["cells"] as PackedInt32Array).is_empty():
						empty_captures += 1
				"death":
					deaths += 1
					var cause := int(event["cause"])
					var key: String = "%s%s" % [
						Strings.death_reason(cause),
						"" if int(event["killer"]) == 0 else " (raqib)"]
					_causes[key] = int(_causes.get(key, 0)) + 1
				"respawn":
					respawns += 1

		for p in world.players:
			if not p.alive:
				still.erase(p.id)
				continue
			max_trail = maxi(max_trail, p.trail.size())
			# Suvda yurib ketdimi?
			if not world.grid.playable(p.cx, p.cy):
				_note("suvda yurgan o'yinchi",
					"%s: %s (%d, %d)" % [config.map_id, p.player_name,
					p.cx, p.cy])
			# Qimirlamay qoldimi?
			var now := Vector2(p.x, p.y)
			var was: Vector2 = last.get(p.id, now)
			if now.distance_to(was) < 0.01:
				still[p.id] = float(still.get(p.id, 0.0)) + step
				if still[p.id] > STUCK_SECONDS:
					_note("tiqilib qolgan o'yinchi",
						"%s: %s (%.1f, %.1f)" % [config.map_id,
						p.player_name, p.x, p.y])
					still[p.id] = 0.0
			else:
				still[p.id] = 0.0
			last[p.id] = now
		best_percent = maxf(best_percent, world.percent_of(me))

	_check_grid(world, config)
	# Yetakchi kim va jami qancha yer egallangan.
	var leader := world.players[0]
	var owned := 0.0
	for p in world.players:
		owned += world.grid.percent_of(p.id)
		if world.grid.territory_of(p.id) > world.grid.territory_of(leader.id):
			leader = p
	_rows.append({
		"map": config.map_id, "level": LEVELS[index % LEVELS.size()],
		"percent": world.percent_of(me), "kills": me.kills,
		"alive": world.alive_count(), "deaths": deaths,
		"captures": captures, "max_trail": max_trail,
		"best": best_percent, "me_alive": me.alive,
		"net_dirty": world.grid.net_dirty.size(),
		"leader": leader.player_name,
		"leader_percent": world.grid.percent_of(leader.id),
		"owned": owned,
	})
	if empty_captures > 0:
		_note("bo'sh hudud egallash", "%d marta" % empty_captures)

## O'yin tugagach panjara izchilmi.
func _check_grid(world: GameWorld, config: GameConfig) -> void:
	var grid := world.grid
	var owned := 0
	var water_owned := 0
	var ghost_trail := 0
	var alive_ids := {}
	for p in world.players:
		if p.alive:
			alive_ids[p.id] = true

	for i in grid.owner_cells.size():
		var id: int = grid.owner_cells[i]
		if id != 0:
			owned += 1
			if not grid.is_land_index(i):
				water_owned += 1
		var trail: int = grid.trail_cells[i]
		if trail != 0 and not alive_ids.has(trail):
			ghost_trail += 1

	if water_owned > 0:
		_note("suvdagi hudud", "%s: %d katak" % [config.map_id, water_owned])
	if ghost_trail > 0:
		_note("o'lgan o'yinchining izi",
			"%s: %d katak" % [config.map_id, ghost_trail])
	if owned > grid.land_cells:
		_note("hudud quruqlikdan ko'p", config.map_id)

	# Foizlar yig'indisi 100 dan oshmasligi kerak.
	var total := 0.0
	for p in world.players:
		total += grid.percent_of(p.id)
	if total > 100.5:
		_note("foizlar yig'indisi 100 dan oshdi",
			"%s: %.1f%%" % [config.map_id, total])

	# Tarmoq ro'yxati solo o'yinda hech kim tomonidan bo'shatilmaydi —
	# u cheksiz o'smasligi kerak.
	if grid.net_dirty.size() > grid.owner_cells.size():
		_note("tarmoq ro'yxati cheksiz o'syapti",
			"%d katak" % grid.net_dirty.size())

func _report(ms: int) -> void:
	print("\n=== %d o'yin, har biri %.0f s (jami %.1f s hisob) ===" % [
		_matches, _seconds, ms / 1000.0])
	var sum_percent := 0.0
	var sum_kills := 0
	var survived := 0
	var max_dirty := 0
	for row: Dictionary in _rows:
		sum_percent += row["best"]
		sum_kills += row["kills"]
		if row["me_alive"]:
			survived += 1
		max_dirty = maxi(max_dirty, int(row["net_dirty"]))
		print("%-14s %-6s eng yaxshi %5.2f%%  oxirida %5.2f%%  %d kill  "
			% [row["map"], row["level"], row["best"], row["percent"],
			row["kills"]]
			+ "tirik %2d  egallash %3d  eng uzun iz %3d  %s" % [
			row["alive"], row["captures"], row["max_trail"],
			"tirik" if row["me_alive"] else "o'ldi"])
	print("\no'rtacha eng yaxshi %.2f%%, jami %d kill, %d/%d o'yinda omon qoldi"
		% [sum_percent / _rows.size(), sum_kills, survived, _rows.size()])
	print("tarmoq ro'yxatining eng katta hajmi: %d katak" % max_dirty)
	var owned := 0.0
	var leader := 0.0
	for row: Dictionary in _rows:
		owned += row["owned"]
		leader += row["leader_percent"]
	print("o'rtacha: egallangan yer %.1f%%, yetakchi %.2f%%" % [
		owned / _rows.size(), leader / _rows.size()])
	print("eng sekin kadr: %.2f ms" % _slowest)
	print("\no'lim sabablari:")
	var total := 0
	for key: String in _causes:
		total += int(_causes[key])
	for key: String in _causes:
		print("  %-34s %5d  (%.0f%%)" % [key, _causes[key],
			100.0 * int(_causes[key]) / maxi(total, 1)])

	if _problems.is_empty():
		print("\nNOSOZLIK TOPILMADI")
		return
	print("\n=== NOSOZLIKLAR ===")
	for key: String in _problems:
		print("  %-36s %4d marta   (%s)" % [key, _problems[key]["count"],
			_problems[key]["first"]])
