extends SceneTree

## Hudud chegarasi qanchalik silliq chiqishini tekshiradi.
##
## Panjaraga **aniq ma'lum** shakl chiziladi: silliq to'lqinli
## doira. Katakka tushirilganda u zinapoyaga aylanadi, shader esa
## uni qaytadan silliqlashi kerak. Shakl har safar bir xil, shuning
## uchun shaderni o'zgartirib oldin/keyin solishtirish mumkin.
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --resolution 720x1280 \
##     --script res://tools/edgetest.gd -- build/edge.png

var _view: Node
var _phase := 0
var _frames := 0
var _out := "res://build/edge.png"
## "bench" bo'lsa: skrinshot emas, kadr vaqti o'lchanadi.
var _bench := false
var _mark := 0
var _times: Array[float] = []

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_bench = _out == "bench"
	change_scene_to_file("res://scenes/main.tscn")

## Chegaraga boy maydon — shader narxini o'lchash uchun.
##
## Naqsh aniq formula bilan chiziladi, shuning uchun ikki
## yugurishda sahna bir xil bo'ladi va faqat shader farq qiladi.
func _paint_patches(cx: float, cy: float) -> void:
	var grid: Object = _view.world.grid
	for y in range(int(cy) - 70, int(cy) + 71):
		for x in range(int(cx) - 70, int(cx) + 71):
			if x < 0 or y < 0 or x >= grid.width or y >= grid.height:
				continue
			var a := int(floor(x / 9.0 + 0.9 * sin(y * 0.21)))
			var b := int(floor(y / 9.0 + 0.9 * sin(x * 0.23)))
			grid.set_owner(x, y, 1 + posmod(a + b, 6))

## Toza doira — markazi o'yinchining joyida.
func _paint_blob(cx: float, cy: float) -> void:
	var grid: Object = _view.world.grid
	var id: int = _view.world.human().id
	for y in range(int(cy) - 32, int(cy) + 33):
		for x in range(int(cx) - 32, int(cx) + 33):
			if x < 0 or y < 0 or x >= grid.width or y >= grid.height:
				continue
			var dx := x + 0.5 - cx
			var dy := y + 0.5 - cy
			# Oddiy doira: kataklarga tushirilganda uning o'qlari
			# yonida uzun to'g'ri qatorlar paydo bo'ladi. Shader
			# ularni yo'qotsa, chegara chinakam doira bo'lib
			# ko'rinadi.
			if sqrt(dx * dx + dy * dy) <= 13.0:
				grid.set_owner(x, y, id)
	# Ingichka tilimlar: 1, 2 va 3 katak kengligida. Keng oyna
	# ularni "yutib" yubormasligi kerak — hudud egasiniki bo'lib
	# qolgan joy ekranda ham ko'rinishi shart.
	for width: int in [1, 2, 3]:
		var top: int = int(cy) - 8 + (width - 1) * 7
		for row in width:
			for x in range(int(cx) + 13, int(cx) + 30):
				grid.set_owner(x, top + row, id)

func _process(_delta: float) -> bool:
	_view = current_scene
	if _view == null or not _view.has_method("steer_human"):
		return false
	_frames += 1
	match _phase:
		0:
			_view.set_map_for_demo("circle")
			_view.start_for_demo()
			_phase = 1
		1:
			var p: Object = _view.world.human()
			p.x = 160.0
			p.y = 160.0
			if _bench:
				_paint_patches(160.0, 160.0)
				Engine.max_fps = 0
			else:
				_paint_blob(160.0, 160.0)
			# Bayroq naqshi chegarani yopib qo'yadi — o'chiramiz,
			# kamerani esa butun shakl ko'rinadigan qilib kengaytiramiz.
			_view.store.show_flags = false
			_view._apply_view_settings()
			_view.camera.fov = 100.0
			# Dunyo to'xtasin: o'yinchi joyidan qimirlamasin va
			# shakl ikki yugurishda ham bir xil chiqsin.
			_view._set_playing(false)
			_view._place_camera_instantly()
			_phase = 2
		2:
			if _bench:
				var now := Time.get_ticks_usec()
				if _frames > 60 and _mark > 0:
					_times.append(float(now - _mark) / 1000.0)
				_mark = now
				if _times.size() >= 120:
					_times.sort()
					var sum := 0.0
					for t in _times:
						sum += t
					print("kadr: o'rtacha %.1f ms, o'rtanchasi %.1f ms"
						% [sum / _times.size(),
							_times[_times.size() / 2]])
					quit()
				return false
			# Bir necha kadr — tekstura va kamera joyiga tushsin.
			if _frames > 20:
				var image := root.get_texture().get_image()
				var err := image.save_png(_out)
				print("skrinshot: %s (%s)"
					% [_out, "ok" if err == OK else "xato"])
				quit()
	return false
