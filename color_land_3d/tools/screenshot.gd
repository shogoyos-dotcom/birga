extends SceneTree

## Sahnani bir necha soniya o'ynatib, PNG saqlaydi — qo'lda ko'rib
## tekshirish uchun. Konteynerda Vulkan yo'q, shuning uchun
## moslashuvchan (OpenGL) chizuvchi bilan ishga tushiriladi:
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --resolution 720x1280 \
##     --script res://tools/screenshot.gd -- 6 build/shot.png

const CitySystem = preload("res://scripts/logic/city_system.gd")
const ArenaBuilder = preload("res://scripts/render/arena_builder.gd")

var _frames_left := 0
var _out := "res://build/shot_3d.png"
var _seconds := 6.0
var _elapsed := 0.0
## "play" (standart), "menu", "settings", "profile", "pause", "shop",
## "result", "trail", "burst".
var _mode := "play"
## Tekshirish uchun avatar, masalan "flag:UZ".
var _avatar := ""
## Tekshirish uchun maydon, masalan "circle".
var _map := ""
## O'yinchini shu katakka qo'yadi, masalan "240,58"
var _at := ""
var _country := "UZ"
var _opened := false
## "burst" rejimida effekt oxirgi marta qaysi qadamda chaqirilgan.
var _burst_step := -1

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	print("screenshot args: ", args)
	for i in args.size():
		var s := str(args[i])
		if s.begins_with("country="):
			_country = s.substr(8)
		elif s.begins_with("c="):
			_country = s.substr(2)
		elif s.begins_with("mode="):
			_mode = s.substr(5)
		elif s.begins_with("m="):
			_mode = s.substr(2)
		elif s.begins_with("out="):
			_out = s.substr(4)
		elif s.begins_with("avatar="):
			_avatar = s.substr(7)
		elif s.begins_with("map="):
			_map = s.substr(4)
		elif s.begins_with("at="):
			_at = s.substr(3)
		elif s.ends_with(".png"):
			_out = s
		elif s.is_valid_float() and i == 0:
			_seconds = float(s)
		elif s in ["play", "menu", "flags", "heroes", "maps", "maps:continents", "maps:cities", "maps:special", "flag_base", "flag_territory", "multi_flags", "conquest", "burst", "trail", "shop", "settings"]:
			_mode = s
		elif s.length() == 2 and s == s.to_upper():
			_country = s
		elif i == 0 and s.is_valid_float():
			_seconds = float(s)
		elif i == 1 and not s.begins_with("-"):
			_out = s
		elif i == 2:
			_mode = s
	print("screenshot configured: seconds=%.1f out=%s mode=%s country=%s" % [_seconds, _out, _mode, _country])
	_frames_left = int(_seconds * 60.0)
	change_scene_to_file("res://scenes/main.tscn")

func _process(delta: float) -> bool:
	_elapsed += delta
	_drive()
	_frames_left -= 1
	if _frames_left > 0:
		return false
	var image := root.get_texture().get_image()
	var dir := _out.get_base_dir()
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var err := image.save_png(_out)
	print("skrinshot: %s (%s)" % [_out, "ok" if err == OK else "xato %d" % err])
	return true

## O'yinchini avtomatik yurgizadi: hududdan chiqib katta halqa chizadi
## va qaytadi — skrinshotda iz ham, egallangan hudud ham ko'rinsin.
func _drive() -> void:
	var view := current_scene
	if view == null or not view.has_method("steer_human"):
		return
	if view.get("store") == null or view.get("world") == null:
		return
	if _mode.begins_with("board:") and view.has_method("set_board_url_for_demo"):
		view.set_board_url_for_demo(_mode.substr(6))
		_mode = "board"
	if not _map.is_empty() and view.has_method("set_map_for_demo"):
		view.set_map_for_demo(_map)
	if not _avatar.is_empty() and view.has_method("set_avatar_for_demo"):
		view.set_avatar_for_demo(_avatar)
	if not _country.is_empty() and view.has_method("set_country_for_demo"):
		view.set_country_for_demo(_country)

	var is_3d_action: bool = (_mode == "play" or _mode == "trail" or _mode == "burst" \
		or _mode == "flag_base" or _mode == "flag_territory" or _mode == "multi_flags" or _mode == "conquest" \
		or _mode.begins_with("city_"))

	if not is_3d_action:
		if not _opened:
			_opened = true
			if _mode == "maps:continents":
				view.show_screen_for_demo("maps")
				view.ui._maps_category = 1
				view.ui._rebuild()
			elif _mode == "maps:cities":
				view.show_screen_for_demo("maps")
				view.ui._maps_category = 2
				view.ui._rebuild()
			elif _mode == "maps:special":
				view.show_screen_for_demo("maps")
				view.ui._maps_category = 3
				view.ui._rebuild()
			elif _mode == "flags":
				view.store.country = _country
				view.show_screen_for_demo("heroes")
				view.ui._heroes_tab = 1
				view.ui._rebuild()
			else:
				view.show_screen_for_demo(_mode)
		return

	view.start_for_demo()
	if not _at.is_empty():
		var parts := _at.split(",")
		if parts.size() == 2:
			var p: Object = view.world.human()
			p.x = float(parts[0])
			p.y = float(parts[1])
			view._place_camera_instantly()
		_at = ""

	# Phase 5: 3D Shaharlar rejimlarini boshqarish
	if _mode.begins_with("city_"):
		if _mode == "city_hud":
			view.steer_human(_elapsed * 0.45)
			return

		if not _opened:
			_opened = true
			var cities_list: Array = view.world.cities.cities if view.world.cities != null else []
			var p: Object = view.world.human()

			if _mode == "city_small":
				var target_city = null
				for c in cities_list:
					if c.category == CitySystem.Category.SMALL:
						target_city = c
						break
				if target_city != null:
					view._city_renderer._spawn_city_node(target_city)
					var cpos := Vector3(target_city.pos.x, ArenaBuilder.LAND_HEIGHT, target_city.pos.y)
					view.set_camera_demo_pose(cpos + Vector3(-5.2, 6.5, 6.5), cpos + Vector3(0, 0.8, 0))

			elif _mode == "city_medium":
				var target_city = null
				for c in cities_list:
					if c.category == CitySystem.Category.MEDIUM and c.regional_style == "default":
						target_city = c
						break
				if target_city != null:
					view._city_renderer._spawn_city_node(target_city)
					var cpos := Vector3(target_city.pos.x, ArenaBuilder.LAND_HEIGHT, target_city.pos.y)
					view.set_camera_demo_pose(cpos + Vector3(-7.8, 9.2, 9.2), cpos + Vector3(0, 1.2, 0))

			elif _mode == "city_large":
				var target_city = null
				for c in cities_list:
					if c.category == CitySystem.Category.LARGE and c.regional_style == "default":
						target_city = c
						break
				if target_city == null and not cities_list.is_empty():
					target_city = cities_list[0]
				if target_city != null:
					view._city_renderer._spawn_city_node(target_city)
					var cpos := Vector3(target_city.pos.x, ArenaBuilder.LAND_HEIGHT, target_city.pos.y)
					view.set_camera_demo_pose(cpos + Vector3(-10.5, 12.8, 12.8), cpos + Vector3(0, 2.5, 0))

			elif _mode == "city_paris":
				var target_city = null
				for c in cities_list:
					if c.name == "Paris":
						target_city = c
						break
				if target_city != null:
					view._city_renderer._spawn_city_node(target_city)
					var cpos := Vector3(target_city.pos.x, ArenaBuilder.LAND_HEIGHT, target_city.pos.y)
					view.set_camera_demo_pose(cpos + Vector3(-7.2, 8.8, 8.8), cpos + Vector3(0, 1.8, 0))

			elif _mode == "city_tashkent":
				var target_city = null
				for c in cities_list:
					if c.name == "Tashkent":
						target_city = c
						break
				if target_city != null:
					view._city_renderer._spawn_city_node(target_city)
					var cpos := Vector3(target_city.pos.x, ArenaBuilder.LAND_HEIGHT, target_city.pos.y)
					view.set_camera_demo_pose(cpos + Vector3(-7.2, 8.8, 8.8), cpos + Vector3(0, 1.8, 0))

			elif _mode == "city_captured":
				var target_city = null
				for c in cities_list:
					if c.name == "Tashkent" or c.category == CitySystem.Category.LARGE:
						target_city = c
						break
				if target_city != null:
					target_city.owner_id = p.id
					target_city.owner_country = p.country
					target_city.owner_name = p.player_name
					var cx := int(target_city.pos.x)
					var cy := int(target_city.pos.y)
					for dy in range(-10, 11):
						for dx in range(-12, 13):
							if view.world.grid.playable(cx + dx, cy + dy):
								view.world.grid.set_owner(cx + dx, cy + dy, p.id)
					view.paint.sync()
					view._city_renderer._spawn_city_node(target_city)
					view._city_renderer.on_city_captured(target_city)
					var cpos := Vector3(target_city.pos.x, ArenaBuilder.LAND_HEIGHT, target_city.pos.y)
					view.set_camera_demo_pose(cpos + Vector3(-8.5, 10.2, 10.2), cpos + Vector3(0, 1.6, 0))

			elif _mode == "city_bot":
				var target_city = null
				for c in cities_list:
					if c.name == "Paris" or c.category == CitySystem.Category.MEDIUM:
						target_city = c
						break
				var bot: Object = view.world.players[1] if view.world.players.size() > 1 else p
				if target_city != null:
					target_city.owner_id = bot.id
					target_city.owner_country = bot.country
					target_city.owner_name = bot.player_name
					var cx := int(target_city.pos.x)
					var cy := int(target_city.pos.y)
					for dy in range(-8, 9):
						for dx in range(-10, 11):
							if view.world.grid.playable(cx + dx, cy + dy):
								view.world.grid.set_owner(cx + dx, cy + dy, bot.id)
					view.paint.sync()
					view._city_renderer._spawn_city_node(target_city)
					view._city_renderer.on_city_captured(target_city)
					var cpos := Vector3(target_city.pos.x, ArenaBuilder.LAND_HEIGHT, target_city.pos.y)
					view.set_camera_demo_pose(cpos + Vector3(-8.5, 10.2, 10.2), cpos + Vector3(0, 1.6, 0))

			elif _mode == "city_conquest":
				var cpos := Vector3(p.x, ArenaBuilder.LAND_HEIGHT, p.y)
				if not cities_list.is_empty():
					var c0 = cities_list[0]
					cpos = Vector3(c0.pos.x, ArenaBuilder.LAND_HEIGHT, c0.pos.y)
					view._city_renderer.update_lod(cpos, 0.5)
				view.set_camera_demo_pose(cpos + Vector3(-18.0, 24.0, 24.0), cpos + Vector3(0, 0, 0))

			elif _mode == "city_info":
				var target_city = null
				for c in cities_list:
					if c.name == "Tashkent" or c.name == "Paris":
						target_city = c
						break
				if target_city != null:
					view.ui.show_city_info_modal(target_city)
		return

	if _mode == "flag_base" or _mode == "flag_territory":
		var p: Object = view.world.human()
		if _elapsed < 0.2:
			var cx := int(p.x)
			var cy := int(p.y)
			for dy in range(-12, 13):
				for dx in range(-18, 19):
					var gx := cx + dx
					var gy := cy + dy
					if view.world.grid.playable(gx, gy) and Vector2(dx * 1.5, dy).length() <= 16.0:
						view.world.grid.set_owner_cell(gx, gy, p.id)
			view.paint.sync()
			view._avatars.refresh()
			view._flag_poles.update_poles()
		var base_node: Node3D = view._flag_poles._base_poles.get(p.id)
		var base_pos := base_node.global_position if base_node != null else Vector3(p.x, ArenaBuilder.LAND_HEIGHT, p.y)
		view.set_camera_demo_pose(base_pos + Vector3(-3.2, 7.0, 9.2), base_pos + Vector3(1.2, 3.6, 0.0))
		return

	if _mode == "burst" or _mode == "conquest":
		if _frames_left <= 6 and _burst_step < 0:
			_burst_step = 1
			var p: Object = view.world.human()
			view._burst.burst(Vector3(p.x,
				ArenaBuilder.LAND_HEIGHT + view.HEAD_RADIUS, p.y))
		view.steer_human(_elapsed * 0.55)
		view.revive_human_for_demo()
		return

	if _mode == "trail":
		view.steer_human(0.62)
		return

	# multi_flags yoki odatiy play
	view.steer_human(_elapsed * 0.52)
	view.revive_human_for_demo()
