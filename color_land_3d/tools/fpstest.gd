extends SceneTree

## Kadr vaqtini o'lchaydi — shaderni o'zgartirgandan keyin narxni
## bilish uchun.
##
## Konteynerda haqiqiy videokarta yo'q (llvmpipe — protsessorda
## chizadi), shuning uchun **mutlaq** son telefonniki emas. Lekin
## ikki variantni bir xil sharoitda solishtirish mumkin: fragment
## shaderi qimmatlashsa, shu yerda ham qimmatlashadi.
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --resolution 720x1280 \
##     --script res://tools/fpstest.gd

var _view: Node
var _frames := 0
var _times: Array[float] = []

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")

var _mark := 0

func _process(_delta: float) -> bool:
	_view = current_scene
	if _view == null or not _view.has_method("steer_human"):
		return false
	_frames += 1
	if _frames == 1:
		# Cheklovsiz chizamiz, aks holda vaqt vsync ga qarab chiqadi.
		Engine.max_fps = 0
		_view.set_map_for_demo("world")
		_view.start_for_demo()
		return false
	_view.steer_human(_frames * 0.02)
	_view.revive_human_for_demo()
	# Birinchi 120 kadr — isinish (shader kompilyatsiyasi, kesh).
	var now := Time.get_ticks_usec()
	if _frames > 120 and _mark > 0:
		_times.append(float(now - _mark) / 1000.0)
	_mark = now
	if _times.size() >= 200:
		_times.sort()
		var sum := 0.0
		for t in _times:
			sum += t
		print("kadr: o'rtacha %.2f ms, o'rtanchasi %.2f ms, eng sekini %.2f ms"
			% [sum / _times.size(), _times[_times.size() / 2],
				_times[_times.size() - 1]])
		quit()
	return false
