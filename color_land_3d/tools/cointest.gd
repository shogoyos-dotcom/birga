extends SceneTree

## Shahar tangalari o'yin ichida: olinadi, yo'qoladi va
## [constant MonetizationConfig.CITY_COIN_RESPAWN] soniyadan keyin
## qaytadi.
##
## Chizuvchi (MultiMesh) bu yerda tekshirilmaydi: headless rejimda
## RenderingServer soxta bo'lib, nusxa matritsalarini saqlamaydi va
## o'qiganda doim birlik matritsa qaytaradi. Ko'rinishini skrinshot
## bilan tekshirish kerak.
##
##   godot --headless --path . --script res://tools/cointest.gd

var _view: Node
var _phase := 0
var _frames := 0
var _value := 0

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")

func _all_cells() -> PackedInt32Array:
	var grid: Object = _view.world.grid
	var cells := PackedInt32Array()
	cells.resize(grid.width * grid.height)
	for i in cells.size():
		cells[i] = i
	return cells

func _process(_delta: float) -> bool:
	_view = current_scene
	if _view == null or not _view.has_method("steer_human"):
		return false
	_frames += 1
	var field: Object = _view._coin_field
	match _phase:
		0:
			_view.set_map_for_demo("world")
			_view.start_for_demo()
			# Headless kadrlar juda qisqa — soatni tezlatamiz.
			Engine.time_scale = 20.0
			_phase = 1
		1:
			print("xaritada %d tanga" % field.size())
			# Hamma shaharni birdan egallaymiz.
			_value = field.collect_cells(_all_cells())
			_view._coins.take(field.flush_taken())
			print("olindi: qiymat %d, xaritadan ketgan %d"
				% [_value, field.taken_count()])
			_phase = 2
		2:
			# O'yinchi o'lsa o'yin to'xtab qoladi va soat ham
			# to'xtaydi — sinov uchun uni tiriltirib turamiz.
			_view.revive_human_for_demo()
			if _view.world.elapsed > MonetizationConfig.CITY_COIN_RESPAWN * 0.5:
				print("%.0f soniyada: xaritadan ketgan %d (hali qaytmasin)"
					% [_view.world.elapsed, field.taken_count()])
				_phase = 3
		3:
			_view.revive_human_for_demo()
			if _view.world.elapsed > MonetizationConfig.CITY_COIN_RESPAWN + 2.0:
				print("%.0f soniyada: xaritadan ketgan %d / %d, hisob %d"
					% [_view.world.elapsed, field.taken_count(),
						field.size(), field.collected()])
				# Hammasi qaytishi shart emas: 30 soniya ichida
				# botlar yangi hudud egallaydi va ayrim tangani
				# darhol olib qo'yadi. Muhimi — deyarli hammasi
				# qaytdi va hisob o'zgarmadi.
				var left := int(field.taken_count())
				var ok: bool = left * 20 < int(field.size()) \
					and int(field.collected()) == _value
				print("NOSOZLIK TOPILMADI" if ok else "NOSOZLIK BOR")
				quit(0 if ok else 1)
	if _frames > 60000:
		print("NOSOZLIK BOR: vaqt yetmadi")
		quit(1)
	return false
