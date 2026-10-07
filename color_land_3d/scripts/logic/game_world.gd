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

var _rng: RandomNumberGenerator
var _by_id: Array[PlayerState] = []
var _capturer: TerritoryCapturer

func _init(p_config: GameConfig, seed_value: int = 0) -> void:
	config = p_config
	var land := PackedByteArray()
	if config.world_map:
		var map := WorldMap.load_default()
		assert(map.width == config.grid_width and map.height == config.grid_height,
			"Dunyo xaritasi panjara o'lchamiga mos kelmadi")
		land = map.land
	grid = GameGrid.new(config.grid_width, config.grid_height, land)
	_capturer = TerritoryCapturer.new(grid)
	_rng = RandomNumberGenerator.new()
	if seed_value != 0:
		_rng.seed = seed_value
	color_index_by_id.resize(256)
	_by_id.resize(256)

func human() -> PlayerState:
	return players[0]

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
		if grid.playable(int(floor(cx_clamped)), row):
			p.x = cx_clamped
		if grid.playable(int(floor(p.x)), int(floor(cy_clamped))):
			p.y = cy_clamped

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

	# Qoida: o'z izingni kesib o'tsang — o'lasan. Lekin endigina qo'ygan
	# bir necha katak bundan mustasno.
	if grid.trail_cells[i] == p.id:
		if not _is_fresh_trail(p, i):
			kill(p, PlayerState.DeathCause.SELF_CROSS, null)
		return

	if p.trail.is_empty():
		# Hududdan endi chiqdi — yo'l shu nuqtadan boshlanadi.
		p.trail_path.clear()
		p.trail_path.append(Vector2(p.x, p.y))
	grid.set_trail_index(i, p.id)
	p.trail.append(i)

## `i` — `p` ning eng so'nggi bir necha izidan birimi?
func _is_fresh_trail(p: PlayerState, i: int) -> bool:
	var from: int = maxi(0, p.trail.size() - config.self_hit_grace)
	for k in range(p.trail.size() - 1, from - 1, -1):
		if p.trail[k] == i:
			return true
	return false

func _finish_loop(p: PlayerState) -> void:
	var result := _capturer.capture(p.id, p.trail)
	p.trail.clear()
	p.trail_path.clear()
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
	p.trail.clear()
	p.trail_path.clear()
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

## Hodisalarni olib, navbatni bo'shatadi.
func drain_events() -> Array[Dictionary]:
	if events.is_empty():
		return []
	var copy := events.duplicate()
	events.clear()
	return copy
