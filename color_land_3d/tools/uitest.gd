extends SceneTree

## Interfeysni va chizish qatlamini "qo'lda" o'ynab chiqadi.
##
## Har bir ekran ochiladi, o'yin boshlanadi, pauza qilinadi, o'yinchi
## o'ldiriladi, natija ko'riladi, maydonlar almashtiriladi va
## sozlamalar o'zgartiriladi. Maqsad — skript xatolari, qotib qolish
## va xotira o'sishini topish.

var _steps: Array = []
var _at := 0
var _timer := 0.0
var _view: Node
var _nodes_before := 0

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")

func _build_steps() -> void:
	_steps = [
		["menyu", func() -> void: _view.show_screen_for_demo("menu")],
		["sozlamalar", func() -> void: _view.show_screen_for_demo("settings")],
		["profil", func() -> void: _view.show_screen_for_demo("profile")],
		["do'kon", func() -> void: _view.show_screen_for_demo("shop")],
		["xona", func() -> void: _view.show_screen_for_demo("room")],
		["reyting", func() -> void: _view.show_screen_for_demo("board")],
		["maydon tanlash", func() -> void: _view.show_screen_for_demo("maps")],
		["o'yin boshlandi", func() -> void: _view._on_play()],
		["boshqaruv", func() -> void: _view.steer_human(0.7)],
		["pauza", func() -> void: _view.show_screen_for_demo("pause")],
		["davom", func() -> void: _view._on_resume()],
		["o'lim", func() -> void:
			_view.world.kill(_view.world.human(),
				PlayerState.DeathCause.TRAIL_HIT, null)],
		["natija", func() -> void: pass],
		["belet bilan davom", func() -> void:
			_view._on_continue_with_ticket()],
		["menyuga", func() -> void: _view._on_menu()],
	]
	# Hamma maydon almashtirib ko'riladi.
	for map_id: String in WorldMap.ids():
		_steps.append(["maydon: " + map_id, func() -> void:
			_view.set_map_for_demo(map_id)])
	# Sozlamalar o'zgarishi.
	for theme_id: String in Palette.ORDER:
		_steps.append(["uslub: " + theme_id, func() -> void:
			_view.store.theme_id = theme_id
			_view._on_settings_changed()])
	for code: String in Strings.CODES:
		_steps.append(["til: " + code, func() -> void:
			Strings.set_language(code)
			_view.show_screen_for_demo("settings")])
	_steps.append(["ko'rinish kalitlari", func() -> void:
		_view.store.show_city_names = false
		_view.store.show_capitals = false
		_view.store.show_flags = false
		_view.store.show_minimap = false
		_view._apply_view_settings()])
	_steps.append(["kalitlar qaytadi", func() -> void:
		_view.store.show_city_names = true
		_view.store.show_capitals = true
		_view.store.show_flags = true
		_view.store.show_minimap = true
		_view._apply_view_settings()])
	_steps.append(["oxirgi o'yin", func() -> void: _view._on_play()])

func _process(delta: float) -> bool:
	if _view == null:
		_view = current_scene
		if _view == null:
			return false
		_build_steps()
		_nodes_before = _count_nodes(root)
		return false
	_timer -= delta
	if _timer > 0.0:
		return false
	_timer = 0.35
	if _at >= _steps.size():
		_finish()
		return true
	var step: Array = _steps[_at]
	_at += 1
	print("  %2d. %s" % [_at, step[0]])
	(step[1] as Callable).call()
	return false

func _finish() -> void:
	var nodes := _count_nodes(root)
	print("\ntugunlar: boshida %d, oxirida %d" % [_nodes_before, nodes])
	var usage := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	print("xotira: %.1f MB, obyektlar: %d" % [
		usage, Performance.get_monitor(Performance.OBJECT_COUNT)])
	print("HAMMA EKRAN OCHILDI")

func _count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total
