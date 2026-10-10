class_name GameWorld
extends RefCounted

## O'yinning butun mantiqi: harakat, iz, hudud egallash, o'lim qoidalari.
## Chizishga umuman bog'liq emas — headless testlardan o'tadi.

## Chizish qatlami har kadrda bo'shatib oladigan hodisalar.
## {"type": "capture"|"death"|"respawn", ...}
var events: Array[Dictionary] = []

var config: GameConfig
var grid: GameGrid
var players: Array[PlayerState] = []
var elapsed: float = 0.0
## O'yinchi ID -> rang indeksi.
var color_index_by_id := PackedByteArray()
## Xaritadagi shaharlar: {name, code, x, y, pop, cap}. Chizish qatlami
## ularni arena ustiga nom va belgi qilib qo'yadi.
var places: Array[Dictionary] = []
## Yuklangan maydon — arena geometriyasi uning silliqlangan niqobidan
## quriladi.
var map: WorldMap

var _rng: RandomNumberGenerator
var _by_id: Array[PlayerState] = []
var _capturer: TerritoryCapturer

func _init(p_config: GameConfig, seed_value: int = 0) -> void:
	config = p_config
	var land := PackedByteArray()
	if config.world_map:
		# Panjara o'lchami xaritadan olinadi — har maydonning o'z
		# kengligi va balandligi bor.
		map = WorldMap.load_map(config.map_id)
		if map.ok:
			land = map.land
			places = map.places
			config.grid_width = map.width
			config.grid_height = map.height
		else:
			# Xarita o'qilmasa o'yin yiqilmasin: butun to'rtburchak
			# maydon o'ynaladi.
			push_error("Maydon yuklanmadi — to'rtburchak maydon")
	grid = GameGrid.new(config.grid_width, config.grid_height, land)
	_capturer = TerritoryCapturer.new(grid)
	_rng = RandomNumberGenerator.new()
	if seed_value != 0:
		_rng.seed = seed_value
	color_index_by_id.resize(256)
	_by_id.resize(256)

## Shu qurilmadagi o'yinchi. Tarmoqda mehmon o'zi birinchi bo'lmasligi
## mumkin, shuning uchun indeks alohida saqlanadi.
var local_index: int = 0

func human() -> PlayerState:
	return players[local_index]

func player_by_id(id: int) -> PlayerState:
	if id <= 0 or id >= _by_id.size():
		return null
	return _by_id[id]

## Tarmoqdagi yangi odam o'yinchi. Joy qolmasa `null`.
func add_human(p_name: String, color: int, avatar: String,
		country: String) -> PlayerState:
	if players.size() >= 255:
		return null
	var player := add_player(
		p_name, color % Palette.color_count(), false)
	player.avatar = avatar
	player.country = Profile.sanitize_country(country)
	return player

## Shu o'yinchini mahalliy deb belgilaydi.
func set_local(id: int) -> void:
	for i in players.size():
		if players[i].id == id:
			local_index = i
			return

func add_player(p_name: String, color: int, is_bot: bool,
		brain: Object = null) -> PlayerState:
	var id: int = players.size() + 1
	assert(id < 256, "Maksimal 255 o'yinchi")
	var p := PlayerState.new(
		id, p_name, color, is_bot,
		config.bot_speed() if is_bot else config.player_speed,
		config.bot_turn_rate if is_bot else config.player_turn_rate)
	p.brain = brain
	players.append(p)
	_by_id[id] = p
	color_index_by_id[id] = color
	return p

func spawn_all() -> void:
	for p in players:
		spawn(p)

## Bo'sh joy topib o'yinchini joylashtiradi. Joy topilmasa `false`.
func spawn(p: PlayerState) -> bool:
	var size := config.start_block
	var margin := size + 2
	for attempt in 400:
		var left: int = margin + _rng.randi_range(0, grid.width - 2 * margin - size - 1)
		var top: int = margin + _rng.randi_range(0, grid.height - 2 * margin - size - 1)
		if not grid.is_block_free(left, top, size):
			continue
		var cx: int = left + size / 2
		var cy: int = top + size / 2
		# Kichik orolga tushib qolmaslik uchun atrofda yetarli quruqlik
		# borligini tekshiramiz.
		if not _has_room(cx, cy):
			continue
		grid.fill_disc(cx, cy, config.start_radius(), p.id)
		p.place_at(cx + 0.5, cy + 0.5, _rng.randf() * TAU - PI)
		if p.brain != null:
			p.brain.on_respawn(self, p)
		events.append({"type": "respawn", "player": p.id})
		return true
	return false

## Tug'ilish joyi atrofida yetarli quruqlik bormi.
func _has_room(cx: int, cy: int) -> bool:
	if grid.land.is_empty():
		return true
	const RADIUS := 8
	var land := 0
	for y in range(cy - RADIUS, cy + RADIUS + 1):
		for x in range(cx - RADIUS, cx + RADIUS + 1):
			if grid.playable(x, y):
				land += 1
	# (2*8+1)^2 = 289 katakdan kamida yarmi quruqlik bo'lsin.
	return land >= 145

## Bir kadrni hisoblaydi. `dt` juda katta bo'lsa bo'laklarga bo'linadi.
func update(dt: float) -> void:
	var remaining: float = clampf(dt, 0.0, 0.25)
	while remaining > 0.0:
		var step: float = minf(remaining, config.max_step_dt)
		_step(step)
		remaining -= step

func _step(dt: float) -> void:
	elapsed += dt
	for p in players:
		if not p.alive:
			if p.is_bot:
				p.respawn_timer -= dt
				if p.respawn_timer <= 0.0 and not spawn(p):
					p.respawn_timer = 1.0
			continue
		if p.brain != null:
			p.brain.update(self, p, dt)
		_turn(p, dt)
		_move(p, dt)

func _turn(p: PlayerState, dt: float) -> void:
	var diff := PlayerState.normalize_angle(p.target_angle - p.angle)
	var max_step: float = p.turn_rate * dt
	if absf(diff) <= max_step:
		p.angle = p.target_angle
	else:
		p.angle = PlayerState.normalize_angle(
			p.angle + (-max_step if diff < 0.0 else max_step))

func _move(p: PlayerState, dt: float) -> void:
	var dist: float = p.speed * dt
	var nx: float = p.x + cos(p.angle) * dist
	var ny: float = p.y + sin(p.angle) * dist

	# Xarita cheti va suv — to'siq, o'lim emas. O'qlar alohida
	# tekshiriladi: faqat suvga qaragan tezlik yo'qoladi, shuning uchun
	# o'yinchi qirg'oq bo'ylab sirpanib boraveradi.
	const EDGE := 1e-4
	var cx_clamped: float = clampf(nx, EDGE, grid.width - EDGE)
	var cy_clamped: float = clampf(ny, EDGE, grid.height - EDGE)

	if grid.land.is_empty():
		p.x = cx_clamped
		p.y = cy_clamped
	else:
		var row: int = int(floor(p.y))
		var moved := false
		if grid.playable(int(floor(cx_clamped)), row):
			p.x = cx_clamped
			moved = true
		if grid.playable(int(floor(p.x)), int(floor(cy_clamped))):
			p.y = cy_clamped
			moved = true
		if not moved:
			_slide_along_shore(p, dist)

	if not p.trail.is_empty():
		p.add_path_point(p.x, p.y)

	var tx: int = int(floor(p.x))
	var ty: int = int(floor(p.y))

	# Burchakni "kesib o'tish"ni oldini olish uchun har bir katakdan
	# bittalab o'tamiz (bir kadrda odatda 0 yoki 1 qadam).
	var guard := 0
	while p.alive and (p.cx != tx or p.cy != ty) and guard < 64:
		guard += 1
		var sx: int = p.cx + (1 if tx > p.cx else (-1 if tx < p.cx else 0))
		var sy: int = p.cy + (1 if ty > p.cy else (-1 if ty < p.cy else 0))
		if sx != p.cx and sy != p.cy:
			# Diagonal: avval uzoqroq o'qdan yuramiz.
			if absi(tx - p.cx) >= absi(ty - p.cy):
				sy = p.cy
			else:
				sx = p.cx
		_enter_cell(p, sx, sy)

## Ikkala o'q ham to'silganda — qirg'oqning ichki burchagida — o'yinchi
## butunlay to'xtab qolardi.
##
## Shu yerda yo'nalishga eng yaqin bo'sh tomon qidiriladi va o'yinchi
## o'sha tomonga sirpanadi. Yo'nalishning o'zi o'zgarmaydi: barmoq
## qayerni ko'rsatsa, o'sha yoqqa intilaveradi.
func _slide_along_shore(p: PlayerState, dist: float) -> void:
	for step in SHORE_TURNS:
		for sign in [1.0, -1.0]:
			var angle: float = p.angle + step * sign
			var nx: float = p.x + cos(angle) * dist
			var ny: float = p.y + sin(angle) * dist
			if nx <= 0.0 or ny <= 0.0 \
					or nx >= grid.width or ny >= grid.height:
				continue
			if not grid.playable(int(floor(nx)), int(floor(ny))):
				continue
			p.x = nx
			p.y = ny
			return

## Qirg'oq bo'ylab sirpanish uchun sinab ko'riladigan burchaklar.
const SHORE_TURNS: PackedFloat32Array = [
	PI / 6.0, PI / 3.0, PI / 2.0, PI * 2.0 / 3.0,
]

func _enter_cell(p: PlayerState, nx: int, ny: int) -> void:
	# Suv va xarita cheti — to'siq.
	if not grid.playable(nx, ny):
		return
	p.cx = nx
	p.cy = ny
	var i := grid.index(nx, ny)

	# Qoida: kimdir sening izingga tegsa — sen o'lasan, unga +1 kill.
	#
	# Bu tekshiruv katak kimniki ekanidan oldin turadi: raqib mening
	# hududim ustidan o'tayotganda ham iz qoldiradi, va o'sha izni o'z
	# hududim ichida kessam ham u o'lishi kerak.
	var other: int = grid.trail_cells[i]
	if other != 0 and other != p.id:
		var victim := _by_id[other]
		if victim != null and victim.alive:
			kill(victim, PlayerState.DeathCause.TRAIL_HIT, p)

	if grid.owner_cells[i] == p.id:
		# O'z hududiga qaytdi — iz bo'lsa hudud egallanadi.
		if not p.trail.is_empty():
			_finish_loop(p)
		return

	# Qoida: o'z izingni **kesib** o'tsang — o'lasan.
	if grid.trail_cells[i] == p.id:
		if not _own_trail_allowed(p, i):
			kill(p, PlayerState.DeathCause.SELF_CROSS, null)
		return

	p.since_retrace += 1
	if p.trail.is_empty():
		# Hududdan endi chiqdi — yo'l shu nuqtadan boshlanadi.
		p.trail_path.clear()
		p.trail_path.append(Vector2(p.x, p.y))
	grid.set_trail_index(i, p.id)
	p.add_trail(i)

## O'z iziga tegish kechiriladimi.
##
## Ikki holat ajratiladi:
##  * **endigina qo'yilgan katak** — barmoq tebranishi yoki qirg'oq
##    bo'ylab sirpanish; o'ldirish adolatsiz bo'lardi;
##  * **iz bo'ylab ortga qaytish** — ingichka bo'g'ozga yoki kichik
##    orolga kirib qolgan o'yinchi boshqa yo'ldan chiqolmaydi. Qaytishda
##    u izning ketma-ket kataklariga tegadi, shuning uchun har tegish
##    oldingisining qo'shnisi bo'lsa — bu qaytish, kesish emas.
##
## Haqiqiy kesishda o'yinchi izga butunlay boshqa joydan kiradi:
## tartib raqami uzoq bo'ladi va qoida ishlaydi.
func _own_trail_allowed(p: PlayerState, i: int) -> bool:
	var k: int = p.trail_at.get(i, -1)
	if k < 0:
		return true
	if p.trail.size() - k <= config.self_hit_grace:
		p.retrace_index = k
		p.since_retrace = 0
		return true
	if p.retrace_index >= 0 and p.since_retrace <= 1 \
			and absi(k - p.retrace_index) <= config.retrace_jump:
		p.retrace_index = k
		p.since_retrace = 0
		return true
	return false

func _finish_loop(p: PlayerState) -> void:
	var result := _capturer.capture(p.id, p.trail)
	p.clear_trail()
	var cells: PackedInt32Array = result["cells"]
	if cells.is_empty():
		return
	events.append({"type": "capture", "player": p.id, "cells": cells})

	# Qoida: butun hududi egallangan o'yinchi o'ladi.
	for victim_id: int in (result["taken_from"] as Dictionary).keys():
		if grid.territory_of(victim_id) != 0:
			continue
		var victim := _by_id[victim_id]
		if victim != null and victim.alive:
			kill(victim, PlayerState.DeathCause.TERRITORY_LOST, p)

## O'yinchini o'ldiradi: hududi bo'sh bo'ladi, izi tozalanadi.
func kill(p: PlayerState, cause: PlayerState.DeathCause,
		killer: PlayerState) -> void:
	if not p.alive:
		return
	p.alive = false
	p.death_cause = cause
	p.clear_trail()
	if killer != null and killer.id != p.id:
		killer.kills += 1
	p.final_territory = grid.territory_of(p.id)
	var cleared := grid.clear_player(p.id)
	p.respawn_timer = config.bot_respawn_delay
	events.append({
		"type": "death",
		"player": p.id,
		"cause": cause,
		"killer": killer.id if killer != null else 0,
		"cleared": cleared,
	})

## O'yinchining hozirgi (yoki o'lgan bo'lsa — o'limdagi) maydon foizi.
func percent_of(p: PlayerState) -> float:
	if p.alive:
		return grid.percent_of(p.id)
	return p.final_territory * 100.0 / float(grid.land_cells)

## O'yinchining reytingdagi o'rni (1 dan boshlab).
func rank_of(p: PlayerState) -> int:
	var place := 1
	var mine := grid.territory_of(p.id)
	for other in players:
		if other.id != p.id and other.alive and grid.territory_of(other.id) > mine:
			place += 1
	return place

func alive_count() -> int:
	var n := 0
	for p in players:
		if p.alive:
			n += 1
	return n

## O'lgan o'yinchini qaytaradi: o'limda bo'shagan kataklaridan hali
## bo'sh turganlari unga qaytariladi va o'yinchi o'sha hududning
## o'rtasiga qo'yiladi. Juda kam katak qolgan bo'lsa — yangi joydan.
func revive(p: PlayerState, cells: PackedInt32Array) -> bool:
	if p.alive:
		return true
	var restored := PackedInt32Array()
	for i: int in cells:
		if grid.owner_cells[i] == 0 and grid.trail_cells[i] == 0:
			grid.set_owner_index(i, p.id)
			restored.append(i)
	if restored.size() < config.min_revive_cells:
		for i: int in restored:
			grid.set_owner_index(i, 0)
		return spawn(p)

	var sum_x := 0
	var sum_y := 0
	for i: int in restored:
		sum_x += i % grid.width
		sum_y += i / grid.width
	var cx: int = sum_x / restored.size()
	var cy: int = sum_y / restored.size()

	# Markaz boshqa o'yinchiga o'tib ketgan bo'lishi mumkin — eng yaqin
	# o'z katagimizni topamiz.
	var best := restored[0]
	var best_dist := 1 << 30
	for i: int in restored:
		var dx: int = i % grid.width - cx
		var dy: int = i / grid.width - cy
		var d: int = dx * dx + dy * dy
		if d < best_dist:
			best_dist = d
			best = i
	p.place_at(best % grid.width + 0.5, best / grid.width + 0.5,
		_rng.randf() * TAU - PI)
	events.append({"type": "respawn", "player": p.id})
	return true

## Hodisalarni olib, navbatni bo'shatadi.
func drain_events() -> Array[Dictionary]:
	if events.is_empty():
		return []
	var copy := events.duplicate()
	events.clear()
	return copy
