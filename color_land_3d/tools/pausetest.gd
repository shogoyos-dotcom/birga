extends SceneTree

## Pauza tugmasi bosilganda nima bo'lishini o'lchaydi.
##
## Shikoyat: "pauzani bossam tangalarim nolga tushib qolyapti".
## Shuning uchun har qadamda uchta son yoziladi: HUD dagi yozuv,
## shu o'yinda yig'ilgan tanga va hamyondagi tanga.
##
##   godot --headless --path . --script res://tools/pausetest.gd

var _view: Node
var _frames := 0
var _phase := 0
var _wait := 0
## Pauzagacha o'lchangan qiymatlar — keyin shular bilan solishtiriladi.
var _coins_before := 0
var _time_before := 0.0
var _spot_before := Vector2.ZERO

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")

func _say(label: String) -> void:
	var ui: Object = _view.ui
	var hud := "—"
	if ui.get("_coin_label") != null and is_instance_valid(ui._coin_label):
		hud = str(ui._coin_label.text)
	var p: Object = _view.world.human()
	print("%-22s ekran=%-7s HUD=%-6s o'yinda=%-3d hamyon=%-5d vaqt=%6.2f joy=%.1f,%.1f" % [
		label, str(ui.current_screen()), hud,
		_view._coin_field.collected(),
		int(root.get_node("/root/Wallet").get_coins()),
		_view.world.elapsed, p.x, p.y])

## Butun panjara — tangalarni majburan yig'ish uchun.
func _all_cells() -> PackedInt32Array:
	var grid: Object = _view.world.grid
	var cells := PackedInt32Array()
	cells.resize(grid.width * grid.height)
	for i in cells.size():
		cells[i] = i
	return cells

## Ikki shart: pauzada dunyo to'xtaydi va yig'ilgan tanga
## davom etgandan keyin ham joyida qoladi.
func _verdict() -> bool:
	var ok := true
	var p: Object = _view.world.human()
	var moved := Vector2(p.x, p.y).distance_to(_spot_before)
	# Davom etilgandan keyin bir necha kadr o'tdi, shuning uchun
	# kichik siljish normal — pauzadagi 3 soniya emas.
	if _view.world.elapsed - _time_before > 0.5 or moved > 3.0:
		print("XATO: pauzada dunyo to'xtamadi (%.2f s, %.1f katak)"
			% [_view.world.elapsed - _time_before, moved])
		ok = false
	if _view._coin_field.collected() != _coins_before:
		print("XATO: tanga %d dan %d ga tushdi"
			% [_coins_before, _view._coin_field.collected()])
		ok = false
	print("NOSOZLIK TOPILMADI" if ok else "NOSOZLIK BOR")
	return ok

func _process(_delta: float) -> bool:
	_view = current_scene
	if _view == null or not _view.has_method("steer_human"):
		return false
	_frames += 1
	if _wait > 0:
		_wait -= 1
		return false
	match _phase:
		0:
			_view.set_map_for_demo("world")
			_view.start_for_demo()
			var at: Object = _view.world.human()
			at.x = 240.0
			at.y = 58.0
			_view._place_camera_instantly()
			_phase = 1
		1:
			# Halqa chizib yuramiz — shahar ustidan o'tsa tanga tushadi.
			_view.steer_human(_frames * 0.03)
			_view.revive_human_for_demo()
			if _view._coin_field.collected() == 0 and _frames > 900:
				# Tasodifga tayanmaymiz: hisoblagichda son bo'lishi
				# shart, aks holda "nolga tushdi"ni ko'rib bo'lmaydi.
				_view._coin_field.collect_cells(_all_cells())
				_view._coins.take(_view._coin_field.flush_taken())
			if _view._coin_field.collected() > 0:
				_say("1. o'yin davomida")
				var p: Object = _view.world.human()
				_coins_before = _view._coin_field.collected()
				_time_before = _view.world.elapsed
				_spot_before = Vector2(p.x, p.y)
				_phase = 2
		2:
			# Aynan pauza tugmasi nima qilsa — shu.
			# Aynan pauza tugmasi chaqiradigan yo'l.
			_view.show_screen_for_demo("pause")
			_say("2. pauza bosildi")
			_wait = 180
			_phase = 3
		3:
			_say("3. pauzada 3 soniya")
			_view._on_resume()
			_wait = 20
			_phase = 4
		4:
			_say("4. davom etildi")
			quit(0 if _verdict() else 1)
	return false
