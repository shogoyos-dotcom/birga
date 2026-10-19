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
		elif s in ["play", "menu", "flags", "heroes", "maps", "maps:continents", "maps:cities", "maps:special", "flag_base", "flag_territory", "multi_flags", "conquest", "burst", "trail", "shop", "settings", "environment", "coastline"] or s.begins_with("p6_") or s.begins_with("city_"):
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
	quit(0)
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
	if _mode.begins_with("p6_") and _map.is_empty():
		_map = "world"
	if not _map.is_empty() and view.has_method("set_map_for_demo"):
		view.set_map_for_demo(_map)
	if not _avatar.is_empty() and view.has_method("set_avatar_for_demo"):
		view.set_avatar_for_demo(_avatar)
	if not _country.is_empty() and view.has_method("set_country_for_demo"):
		view.set_country_for_demo(_country)
	if view.store != null and (view.store.theme_id == "pastel" or view.store.theme_id.is_empty()):
		view.store.theme_id = "paper"
		Palette.set_theme("paper")
		if view.has_method("_apply_sky"):
			view._apply_sky()
		if view.has_method("_apply_view_settings"):
			view._apply_view_settings()

	var is_3d_action: bool = (_mode == "play" or _mode == "trail" or _mode == "burst" \
		or _mode == "flag_base" or _mode == "flag_territory" or _mode == "multi_flags" or _mode == "conquest" \
		or _mode.begins_with("city_") or _mode.begins_with("p6_") or _mode == "environment" or _mode == "coastline")
	if _mode == "p6_match_summary":
		is_3d_action = false

	if not is_3d_action:
		if not _opened:
			_opened = true
			if _mode == "p6_match_summary":
				var journey = view.get_node_or_null("/root/Journey")
				var cur_country: Dictionary = journey.current() if journey != null else {"code": "UZ", "name": "O'zbekiston"}
				var moved := {
					"country": cur_country,
					"before": 42.0,
					"after": 64.0,
					"gained": 185,
					"done": [],
				}
				var reward := {
					"total": 200,
					"place_coins": 100,
					"kill_coins": 60,
					"area_coins": 40,
				}
				var conquest := {
					"small_count": 3,
					"medium_count": 2,
					"large_count": 1,
					"total": 1050,
					"cities_owned": 6,
					"cities_total": 18,
					"duplicates_prevented": 2,
				}
				view.ui.set_result(28.4, 6, 260.0,
					Strings.death_reason(PlayerState.DeathCause.TRAIL_HIT), true,
					reward, moved, conquest)
				view.ui.show_screen(view.ui.Screen.RESULT)
			elif _mode == "maps:continents":
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

	# Phase 6: Shahar mukofotlari va iqtisodiyot rejimlarini boshqarish
	if _mode.begins_with("p6_"):
		if not _opened:
			_opened = true
			var cities_list: Array = view.world.cities.cities if view.world.cities != null else []
			var p: Object = view.world.human()

			if _mode == "p6_reward_small":
				var target_city = null
				for c in cities_list:
					if c.category == CitySystem.Category.SMALL:
						target_city = c
						break
				if target_city != null:
					target_city.owner_id = p.id
					target_city.owner_country = p.country
					target_city.owner_name = p.player_name
					var cx := int(target_city.pos.x)
					var cy := int(target_city.pos.y)
					for dy in range(-7, 8):
						for dx in range(-9, 10):
							if view.world.grid.playable(cx + dx, cy + dy):
								view.world.grid.set_owner(cx + dx, cy + dy, p.id)
					view.paint.sync()
					view._city_renderer._spawn_city_node(target_city)
					view._city_renderer.on_city_captured(target_city)
					view._spawn_conquest_reward_fx(target_city, 50)
					view._match_conquest_coins = 50
					view.world.cities._player_captured_counts[p.id] = 1
					view._refresh_hud()
					view.ui.toast("★ %s EGALLANDI! (+50 🪙)" % target_city.display_name.to_upper())
					var cpos := Vector3(target_city.pos.x, ArenaBuilder.LAND_HEIGHT, target_city.pos.y)
					view.set_camera_demo_pose(cpos + Vector3(-5.2, 6.8, 6.8), cpos + Vector3(0, 1.2, 0))

			elif _mode == "p6_reward_medium":
				var target_city = null
				for c in cities_list:
					if c.category == CitySystem.Category.MEDIUM and (c.name == "Samarkand" or c.name == "Tashkent" or c.name == "Lyon"):
						target_city = c
						break
				if target_city == null:
					for c in cities_list:
						if c.category == CitySystem.Category.MEDIUM:
							target_city = c
							break
				if target_city != null:
					target_city.owner_id = p.id
					target_city.owner_country = p.country
					target_city.owner_name = p.player_name
					var cx := int(target_city.pos.x)
					var cy := int(target_city.pos.y)
					for dy in range(-4, 5):
						for dx in range(-5, 6):
							if view.world.grid.playable(cx + dx, cy + dy):
								view.world.grid.set_owner(cx + dx, cy + dy, p.id)
					view.paint.sync()
					view._city_renderer._spawn_city_node(target_city)
					view._city_renderer.on_city_captured(target_city)
					view._spawn_conquest_reward_fx(target_city, 200)
					view._match_conquest_coins = 200
					view.world.cities._player_captured_counts[p.id] = 1
					view._refresh_hud()
					view.ui.toast("★ %s EGALLANDI! (+200 🪙)" % target_city.display_name.to_upper())
					var cpos := Vector3(target_city.pos.x, ArenaBuilder.LAND_HEIGHT, target_city.pos.y)
					view.set_camera_demo_pose(cpos + Vector3(-7.5, 9.2, 9.2), cpos + Vector3(0, 1.5, 0))

			elif _mode == "p6_reward_large":
				var target_city = null
				for c in cities_list:
					if c.category == CitySystem.Category.LARGE and (c.name == "Cairo" or c.name == "Paris" or c.name == "London" or c.name == "Tokyo"):
						target_city = c
						break
				if target_city == null:
					for c in cities_list:
						if c.category == CitySystem.Category.LARGE:
							target_city = c
							break
				if target_city != null:
					target_city.owner_id = p.id
					target_city.owner_country = p.country
					target_city.owner_name = p.player_name
					var cx := int(target_city.pos.x)
					var cy := int(target_city.pos.y)
					for dy in range(-4, 5):
						for dx in range(-5, 6):
							if view.world.grid.playable(cx + dx, cy + dy):
								view.world.grid.set_owner(cx + dx, cy + dy, p.id)
					view.paint.sync()
					view._city_renderer._spawn_city_node(target_city)
					view._city_renderer.on_city_captured(target_city)
					view._spawn_conquest_reward_fx(target_city, 500)
					view._match_conquest_coins = 500
					view.world.cities._player_captured_counts[p.id] = 1
					view._refresh_hud()
					view.ui.toast("★ %s EGALLANDI! (+500 🪙)" % target_city.display_name.to_upper())
					var cpos := Vector3(target_city.pos.x, ArenaBuilder.LAND_HEIGHT, target_city.pos.y)
					view.set_camera_demo_pose(cpos + Vector3(-8.5, 11.0, 11.0), cpos + Vector3(0, 2.0, 0))

			elif _mode == "p6_coin_anim":
				var target_city = null
				for c in cities_list:
					if c.category == CitySystem.Category.LARGE or c.category == CitySystem.Category.MEDIUM:
						target_city = c
						break
				if target_city != null:
					target_city.owner_id = p.id
					target_city.owner_country = p.country
					target_city.owner_name = p.player_name
					view._city_renderer._spawn_city_node(target_city)
					view._spawn_conquest_reward_fx(target_city, 500)
					view._match_conquest_coins = 750
					view.world.cities._player_captured_counts[p.id] = 3
					view._refresh_hud()
					var cpos := Vector3(target_city.pos.x, ArenaBuilder.LAND_HEIGHT, target_city.pos.y)
					view.set_camera_demo_pose(cpos + Vector3(-4.0, 4.5, 4.8), cpos + Vector3(0, 2.4, 0))

			elif _mode == "p6_wallet_hud":
				var target_city = null
				for c in cities_list:
					if c.category == CitySystem.Category.MEDIUM:
						target_city = c
						break
				if target_city != null:
					target_city.owner_id = p.id
					target_city.owner_country = p.country
					target_city.owner_name = p.player_name
					var cx := int(target_city.pos.x)
					var cy := int(target_city.pos.y)
					for dy in range(-8, 9):
						for dx in range(-10, 11):
							if view.world.grid.playable(cx + dx, cy + dy):
								view.world.grid.set_owner(cx + dx, cy + dy, p.id)
					view.paint.sync()
					view._city_renderer._spawn_city_node(target_city)
				view._match_conquest_coins = 450
				view.world.cities._player_captured_counts[p.id] = 3
				view._refresh_hud()
				var ppos := Vector3(p.x, ArenaBuilder.LAND_HEIGHT, p.y)
				view.set_camera_demo_pose(ppos + Vector3(0.0, 16.0, 18.0), ppos + Vector3(0, 0, 0))

			elif _mode == "p6_city_info":
				var target_city = null
				for c in cities_list:
					if c.category == CitySystem.Category.LARGE:
						target_city = c
						break
				if target_city == null and not cities_list.is_empty():
					target_city = cities_list[0]
				if target_city != null:
					view.ui.show_city_info_modal(target_city, true, false, false)

			elif _mode == "p6_duplicate_prevented":
				var target_city = null
				for c in cities_list:
					if c.category == CitySystem.Category.MEDIUM:
						target_city = c
						break
				if target_city == null and not cities_list.is_empty():
					target_city = cities_list[0]
				if target_city != null:
					target_city.owner_id = p.id
					target_city.owner_country = p.country
					target_city.owner_name = p.player_name
					view._city_renderer._spawn_city_node(target_city)
					view.ui.show_city_info_modal(target_city, false, true, true)
					view.ui.toast("★ %s: ALLAQACHON OLINGAN (+0 🪙)" % target_city.display_name.to_upper())

			elif _mode == "p6_multi_cities":
				var count := 0
				for c in cities_list:
					c.owner_id = p.id
					c.owner_country = p.country
					c.owner_name = p.player_name
					var cx := int(c.pos.x)
					var cy := int(c.pos.y)
					for dy in range(-7, 8):
						for dx in range(-9, 10):
							if view.world.grid.playable(cx + dx, cy + dy):
								view.world.grid.set_owner(cx + dx, cy + dy, p.id)
					view._city_renderer._spawn_city_node(c)
					count += 1
					if count >= 4:
						break
				view.paint.sync()
				view._match_conquest_coins = 750
				view.world.cities._player_captured_counts[p.id] = 4
				view._refresh_hud()
				var center_pos := Vector3(cities_list[0].pos.x, ArenaBuilder.LAND_HEIGHT, cities_list[0].pos.y) if not cities_list.is_empty() else Vector3.ZERO
				view.set_camera_demo_pose(center_pos + Vector3(-18.0, 24.0, 22.0), center_pos + Vector3(0, 0, 0))

			elif _mode == "p6_gameplay_flags_cities":
				var target_city = null
				for c in cities_list:
					if c.category == CitySystem.Category.MEDIUM:
						target_city = c
						break
				if target_city != null:
					view._city_renderer._spawn_city_node(target_city)
				view._match_conquest_coins = 200
				view.world.cities._player_captured_counts[p.id] = 2
				view._refresh_hud()

			elif _mode == "p6_live_conquest_evidence":
				var target_city = null
				for c in cities_list:
					if c.category == CitySystem.Category.MEDIUM and c.name == "Paris":
						target_city = c
						break
				if target_city == null:
					for c in cities_list:
						if c.category == CitySystem.Category.MEDIUM:
							target_city = c
							break
				if target_city != null:
					var cx := int(target_city.pos.x)
					var cy := int(target_city.pos.y)
					# Boshlang'ich hududni yoniga qo'yamiz
					for dy in range(-4, 5):
						for dx in range(-12, -7):
							if view.world.grid.playable(cx + dx, cy + dy):
								view.world.grid.set_owner(cx + dx, cy + dy, p.id)
					p.x = float(cx - 7)
					p.y = float(cy)
					p.alive = true
					view.paint.sync()
					view._city_renderer._spawn_city_node(target_city)

					# Shaharni to'liq o'rab oladigan iz
					var trail_offsets := [
						Vector2i(-6, -5), Vector2i(-3, -6), Vector2i(0, -6), Vector2i(3, -6), Vector2i(6, -5),
						Vector2i(7, -3), Vector2i(7, 0), Vector2i(7, 3), Vector2i(6, 5),
						Vector2i(3, 6), Vector2i(0, 6), Vector2i(-3, 6), Vector2i(-6, 5)
					]
					for off: Vector2i in trail_offsets:
						var gx: int = cx + off.x
						var gy: int = cy + off.y
						if view.world.grid.playable(gx, gy):
							var idx: int = view.world.grid.index(gx, gy)
							view.world.grid.set_trail_index(idx, p.id)
							p.add_trail(idx)

					# Haqiqiy dvigatel funksiyasini chaqiramiz:
					view.world._finish_loop(p)
					view.paint.sync()
					var cpos := Vector3(target_city.pos.x, ArenaBuilder.LAND_HEIGHT, target_city.pos.y)
					view.set_camera_demo_pose(cpos + Vector3(-7.5, 9.5, 9.5), cpos + Vector3(0, 1.5, 0))

		if _mode == "p6_gameplay_flags_cities":
			view.steer_human(_elapsed * 0.48)
			view.revive_human_for_demo()
		return

	if _mode == "environment":
		if not _opened:
			_opened = true
			var p: Object = view.world.human()
			var cpos := Vector3(p.x - 6.0, ArenaBuilder.LAND_HEIGHT, p.y + 10.0)
			view.set_camera_demo_pose(cpos + Vector3(-16.0, 19.0, 25.0), cpos + Vector3(4.0, 1.0, -4.0))
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

	if _mode == "coastline":
		var p: Object = view.world.human()
		var grid: GameGrid = view.world.grid
		var cx := 440
		var cy := 142
		p.place_at(float(cx), float(cy), 0.0)
		p.alive = true
		if view._city_renderer != null:
			view._city_renderer.visible = false
		if view._coins != null:
			view._coins.visible = false
		if view._pickups != null:
			view._pickups.visible = false
		for dy in range(-7, 8):
			for dx in range(-8, 9):
				var gx := cx + dx
				var gy := cy + dy
				if grid.playable(gx, gy) and Vector2(float(dx), float(dy)).length() <= 7.0:
					grid.set_owner(gx, gy, p.id)
		view.paint.sync()
		view._avatars.refresh()
		var cpos := Vector3(438.0, ArenaBuilder.LAND_HEIGHT, 142.0)
		view.set_camera_demo_pose(cpos + Vector3(-8.0, 11.0, 9.0), cpos + Vector3(1.0, 0.0, 0.0))
		return

	if _mode == "trail":
		view.steer_human(0.62)
		return

	# multi_flags yoki odatiy play
	view.steer_human(_elapsed * 0.52)
	view.revive_human_for_demo()
