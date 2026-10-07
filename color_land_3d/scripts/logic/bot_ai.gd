class_name BotBrain
extends RefCounted

## Oddiy, lekin tirik ko'rinadigan bot.
##
## Xulq-atvori:
##  * o'z hududidan chiqib to'rtburchak tsikl chizadi va qaytadi;
##  * raqib yaqinlashsa darhol uyiga qaytadi;
##  * yaqinda himoyasiz iz ko'rsa — unga hujum qiladi;
##  * oldidagi katakda o'z izi, suv yoki devor bo'lsa — chetlab o'tadi.
##
## Yo'nalishlar faqat to'rt tomonga — shunda tsikllar toza to'rtburchak
## bo'ladi va bot o'z izini tasodifan kesib o'tmaydi.

enum Phase { PLANNING, LOOPING, RETURNING, HUNTING }

const DIRS: Array[float] = [0.0, PI / 2.0, PI, -PI / 2.0]

var difficulty: Difficulty
var phase: Phase = Phase.PLANNING

## Oxirgi marta o'z hududida turgan katak — qaytish nuqtasi.
var home_x := 0
var home_y := 0

var _rng: RandomNumberGenerator
## Rejalashtirilgan tsikl bosqichlari: [burchak, uzunlik] juftliklari.
var _leg_angles := PackedFloat32Array()
var _leg_cells := PackedFloat32Array()
var _leg_index := 0
var _leg_left := 0.0
var _think_timer := 0.0
var _target_x := 0
var _target_y := 0

func _init(p_difficulty: Difficulty, rng: RandomNumberGenerator) -> void:
	difficulty = p_difficulty
	_rng = rng

func on_respawn(_world: GameWorld, self_player: PlayerState) -> void:
	phase = Phase.PLANNING
	_leg_angles.clear()
	_leg_cells.clear()
	_leg_index = 0
	_leg_left = 0.0
	_think_timer = 0.0
	home_x = self_player.cx
	home_y = self_player.cy

func update(world: GameWorld, me: PlayerState, dt: float) -> void:
	var grid := world.grid
	var at_home: bool = grid.contains(me.cx, me.cy) \
		and grid.owner_at(me.cx, me.cy) == me.id
	if at_home:
		home_x = me.cx
		home_y = me.cy
		if phase != Phase.HUNTING:
			if phase == Phase.RETURNING or _leg_angles.is_empty():
				phase = Phase.PLANNING

	_leg_left -= me.speed * dt
	_think_timer -= dt
	if _think_timer > 0.0:
		_avoid_immediate_danger(world, me)
		return
	_think_timer = difficulty.reaction_delay

	match phase:
		Phase.PLANNING:
			_plan(world, me)
		Phase.LOOPING:
			if _is_threatened(world, me):
				phase = Phase.RETURNING
			elif _leg_left <= 0.0:
				_leg_index += 1
				if _leg_index >= _leg_angles.size():
					phase = Phase.RETURNING
				else:
					_leg_left = _leg_cells[_leg_index]
					me.steer_to(_leg_angles[_leg_index])
		Phase.HUNTING:
			var prey := _find_prey(world, me)
			if prey.is_empty() or _is_threatened(world, me):
				phase = Phase.RETURNING
			else:
				_target_x = prey[0]
				_target_y = prey[1]
				me.steer_to(_cardinal_toward(me, _target_x + 0.5, _target_y + 0.5))
		Phase.RETURNING:
			if at_home:
				phase = Phase.PLANNING
			else:
				me.steer_to(_cardinal_toward(me, home_x + 0.5, home_y + 0.5))

	_avoid_immediate_danger(world, me)

## O'z hududidan chiqib to'rtburchak chizadigan reja tuzadi.
func _plan(world: GameWorld, me: PlayerState) -> void:
	_leg_angles.clear()
	_leg_cells.clear()
	_leg_index = 0

	var prey := _find_prey(world, me)
	if not prey.is_empty():
		phase = Phase.HUNTING
		_target_x = prey[0]
		_target_y = prey[1]
		me.steer_to(_cardinal_toward(me, _target_x + 0.5, _target_y + 0.5))
		return

	var base: float = (4 + _rng.randi_range(0, 4)) * difficulty.bot_loop_factor
	var out := _outward_angle(world, me)
	var side: int = 1 if _rng.randf() < 0.5 else -1

	_leg_angles.append(out)
	_leg_cells.append(base + 2.0)
	_leg_angles.append(_rotate(out, side))
	_leg_cells.append(maxf(2.0, base * 0.8))
	_leg_angles.append(_rotate(out, side * 2))
	_leg_cells.append(base + 4.0)

	phase = Phase.LOOPING
	_leg_left = _leg_cells[0]
	me.steer_to(_leg_angles[0])

## Hududning markazidan tashqariga qaragan to'rt tomondan birini tanlaydi.
func _outward_angle(world: GameWorld, me: PlayerState) -> float:
	var grid := world.grid
	var best: float = DIRS[_rng.randi_range(0, 3)]
	var best_score := -1.0
	for d in DIRS:
		var score := 0.0
		for step in range(1, 9):
			var x: int = int(floor(me.x + cos(d) * step))
			var y: int = int(floor(me.y + sin(d) * step))
			# Suv ham, xarita cheti ham yurib bo'lmaydigan joy.
			if not grid.playable(x, y):
				score -= 6.0
				break
			var o := grid.owner_at(x, y)
			if o == 0:
				score += 1.0
			elif o != me.id:
				score += 0.5
			if grid.trail_at(x, y) != 0:
				score -= 2.0
		score += _rng.randf()
		if score > best_score:
			best_score = score
			best = d
	return best

## Yaqin atrofda himoyasiz iz bormi? Bo'lsa — eng yaqin katagini qaytaradi.
func _find_prey(world: GameWorld, me: PlayerState) -> PackedInt32Array:
	var grid := world.grid
	var r2: float = difficulty.hunt_radius * difficulty.hunt_radius
	var best := PackedInt32Array()
	var best_dist := INF

	for other in world.players:
		if other.id == me.id or not other.alive or other.trail.is_empty():
			continue
		for cell: int in other.trail:
			var x: int = cell % grid.width
			var y: int = cell / grid.width
			var dx: float = x + 0.5 - me.x
			var dy: float = y + 0.5 - me.y
			var d2: float = dx * dx + dy * dy
			if d2 > r2 or d2 >= best_dist:
				continue
			# Raqib o'sha katakka mendan tezroq yetib borsa — ma'nosi yo'q.
			var ox: float = other.x - (x + 0.5)
			var oy: float = other.y - (y + 0.5)
			if ox * ox + oy * oy < d2 * 0.6:
				continue
			best_dist = d2
			best = PackedInt32Array([x, y])
	return best

## Tashqarida turganda yaqin atrofda raqib bormi?
func _is_threatened(world: GameWorld, me: PlayerState) -> bool:
	if me.trail.is_empty():
		return false
	var r2: float = difficulty.danger_radius * difficulty.danger_radius
	for other in world.players:
		if other.id == me.id or not other.alive:
			continue
		var dx: float = other.x - me.x
		var dy: float = other.y - me.y
		if dx * dx + dy * dy < r2:
			return true
	# Iz juda uzayib ketdi — xavfli, qaytgan ma'qul.
	return me.trail.size() > 70 * difficulty.bot_loop_factor

## Oldinda devor, suv yoki o'z izi bo'lsa yo'nalishni o'zgartiradi.
func _avoid_immediate_danger(world: GameWorld, me: PlayerState) -> void:
	if not _is_blocked(world, me, me.target_angle):
		return

	var best := INF
	var best_dir := INF
	for d in DIRS:
		if _is_blocked(world, me, d):
			continue
		# Orqaga qaytish — o'z iziga kirish degani, undan qochamiz.
		if absf(PlayerState.normalize_angle(d - me.angle)) > PI * 0.9:
			continue
		var nx: float = me.x + cos(d) * 3.0
		var ny: float = me.y + sin(d) * 3.0
		var dist: float = Vector2(nx - (home_x + 0.5), ny - (home_y + 0.5)).length()
		if dist < best:
			best = dist
			best_dir = d
	if best_dir != INF:
		me.steer_to(best_dir)
		phase = Phase.RETURNING

## `angle` yo'nalishida yaqin kataklarda devor, suv yoki o'z izi bormi?
func _is_blocked(world: GameWorld, me: PlayerState, angle: float) -> bool:
	var grid := world.grid
	var steps: int = 2 if me.trail.is_empty() else 3
	for step in range(1, steps + 1):
		var x: int = int(floor(me.x + cos(angle) * step))
		var y: int = int(floor(me.y + sin(angle) * step))
		if not grid.playable(x, y):
			return true
		if grid.trail_at(x, y) == me.id:
			return true
	return false

## Nishonga qarab eng mos to'rt tomondan birini tanlaydi.
func _cardinal_toward(me: PlayerState, tx: float, ty: float) -> float:
	var dx: float = tx - me.x
	var dy: float = ty - me.y
	if absf(dx) >= absf(dy):
		return 0.0 if dx >= 0.0 else PI
	return PI / 2.0 if dy >= 0.0 else -PI / 2.0

## Burchakni 90° * `quarters` ga buradi.
func _rotate(angle: float, quarters: int) -> float:
	return PlayerState.normalize_angle(angle + quarters * PI / 2.0)
