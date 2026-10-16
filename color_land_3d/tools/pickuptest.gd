extends SceneTree

## Yo'ldagi tangalar va sferalar o'yin ichida.
##
## Tekshiriladi:
##  * o'yinchi narsa ustidan yurganda uni oladi;
##  * olingani [constant PickupField.RESPAWN] soniyadan keyin
##    **boshqa joyda** qaytadi;
##  * yashil sfera tezlikni oshiradi va muddati tugagach qaytaradi;
##  * moviy sfera bergan qalqon bitta urilishni yutadi.
##
## Chizuvchi (MultiMesh) bu yerda tekshirilmaydi: headless rejimda
## RenderingServer nusxa matritsalarini saqlamaydi.
##
##   godot --headless --path . --script res://tools/pickuptest.gd

var _view: Node
var _phase := 0
var _frames := 0
var _bad: Array[String] = []
var _was := Vector2.ZERO
var _base := 0.0

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")

func _fail(text: String) -> void:
	_bad.append(text)
	print("  xato: %s" % text)

## O'yinchini birinchi narsaning ustiga qo'yadi.
func _step_onto(index: int) -> void:
	var item: Dictionary = _view._pickup_field.items[index]
	var p: Object = _view.world.human()
	p.place_at(float(item["x"]), float(item["y"]), p.angle)

func _process(_delta: float) -> bool:
	_view = current_scene
	if _view == null or not _view.has_method("steer_human"):
		return false
	_frames += 1
	var field: Object = _view._pickup_field
	match _phase:
		0:
			_view.set_map_for_demo("world")
			_view.start_for_demo()
			Engine.time_scale = 20.0
			_phase = 1
		1:
			print("xaritada %d narsa" % field.size())
			if int(field.size()) != _view.pickup_count(_view.world.grid):
				_fail("narsa soni noto'g'ri")
			# Birinchi tanganing ustiga chiqamiz.
			var coin := _first_of(PickupField.Kind.COIN)
			var item: Dictionary = field.items[coin]
			_was = Vector2(float(item["x"]), float(item["y"]))
			print("tanga ustiga qo'yildi: %s" % _was)
			_step_onto(coin)
			_phase = 2
		2:
			# Keyingi kadrda `_collect_pickups` ishlaydi.
			print("terilgan tanga: %d" % int(_view._loose_coins))
			if int(_view._loose_coins) < 1:
				_fail("ustidan yurdi, lekin olinmadi")
			_phase = 3
		3:
			_view.revive_human_for_demo()
			if _view.world.elapsed > PickupField.RESPAWN + 2.0:
				var coin := _first_of(PickupField.Kind.COIN)
				var item: Dictionary = field.items[coin]
				var now := Vector2(float(item["x"]), float(item["y"]))
				print("qaytdi: %s -> %s" % [_was, now])
				if now == _was:
					_fail("o'sha joyda qaytdi")
				_phase = 4
		4:
			# Yashil sfera: tezlik oshadi.
			var p: Object = _view.world.human()
			_base = float(_view._base_speed)
			_step_onto(_first_of(PickupField.Kind.DASH))
			_phase = 5
		5:
			var p: Object = _view.world.human()
			print("tezlik: %.2f -> %.2f" % [_base, p.speed])
			if p.speed <= _base:
				_fail("yashil sfera tezlikni oshirmadi")
			_phase = 6
		6:
			_view.revive_human_for_demo()
			if _view.world.elapsed > float(_view._boost_until) + 1.0:
				var p: Object = _view.world.human()
				print("muddat tugagach tezlik: %.2f" % p.speed)
				if not is_equal_approx(p.speed, _base):
					_fail("tezlik asliga qaytmadi")
				_phase = 7
		7:
			# Moviy sfera: qalqon bitta urilishni yutadi.
			_step_onto(_first_of(PickupField.Kind.SHIELD))
			_phase = 8
		8:
			var p: Object = _view.world.human()
			if not p.shield:
				_fail("moviy sfera qalqon bermadi")
			p.add_trail(_view.world.grid.index(p.cx + 3, p.cy))
			_view.world.kill(p, PlayerState.DeathCause.TRAIL_HIT, null)
			print("urilishdan keyin: tirik %s, qalqon %s"
				% [p.alive, p.shield])
			if not p.alive:
				_fail("qalqon asramadi")
			if p.shield:
				_fail("qalqon sarflanmadi")
			print("NOSOZLIK TOPILMADI" if _bad.is_empty() else "NOSOZLIK BOR")
			quit(0 if _bad.is_empty() else 1)
	if _frames > 60000:
		print("NOSOZLIK BOR: vaqt yetmadi")
		quit(1)
	return false

## Shu turdagi birinchi **joyida turgan** narsaning indeksi.
func _first_of(kind: int) -> int:
	var field: Object = _view._pickup_field
	for i in int(field.size()):
		var item: Dictionary = field.items[i]
		if int(item["kind"]) == kind and not bool(item["taken"]):
			return i
	_fail("bu turdagi narsa qolmadi")
	return 0
