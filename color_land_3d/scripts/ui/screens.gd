extends CanvasLayer

## Butun interfeys: menyu, sozlamalar, profil, HUD, pauza va natija.
##
## Ekranlar kod bilan quriladi va kerak bo'lganda qayta yig'iladi —
## shunda til yoki rang o'zgarsa hamma joy darhol yangilanadi.

signal play_pressed
## Pauza tugmasi bosildi — o'yin to'xtashi kerak.
signal pause_pressed
signal resume_pressed
signal menu_pressed
signal settings_changed
## Ko'rinish sozlamalari (poytaxt, naqsh, kichik xarita) o'zgardi —
## o'yin qaytadan boshlanmaydi, faqat chizish qatlami yangilanadi.
signal view_changed
signal continue_with_ticket
## Tarmoq o'yini boshlandi: uy egasi sifatida (`host`) yoki mehmon
## sifatida.
signal host_pressed
signal join_pressed(address: String)

const DesignDrawers := preload("res://scripts/ui/design_drawers.gd")
const CitySystem := preload("res://scripts/logic/city_system.gd")

enum Screen { MENU, SETTINGS, PROFILE, HUD, PAUSE, RESULT, SHOP, ROOM, BOARD,
	MAPS, GEAR, HEROES, NOADS }

var store: SettingsStore
## Belet va reklama xizmati (hozircha namuna).
var services := ContinueServices.new()

var _screen: Screen = Screen.MENU
var _root: Control
## HUD tugunlari — har kadrda emas, taymer bo'yicha yangilanadi.
var _progress: Control
var _progress_fill: Panel
var _progress_text: Label
var _donut: Control
var _kill_capsule: PanelContainer
var _coin_capsule: PanelContainer
var _city_capsule: PanelContainer
var _kill_label: Label
var _coin_label: Label
var _city_label: Label
var _city_modal: Control
var _board: VBoxContainer
var _result_data := {}
var _flag_query := ""
var _flag_region_filter := 0
var _avatar_tab := 0
var _maps_category := 0
var _heroes_tab := 0
var _nickname_edit: LineEdit
var _minimap: MiniMap
var _minimap_texture: Texture2D
## Hudud olinganda va o'limda ekran chetidan yoniq chaqnash.
var _flash: ColorRect
## Qisqa xabar (xarid, reklama, rekord).
var _toast: Label
## Reklama ko'rsatilyaptimi — tugma ikki marta bosilmasin.
var _ad_busy := false
## Rekordni tozalash tugmasi tasdiq kutyaptimi.
var _reset_armed := false
## Do'kondan qaytganda qaysi ekranga qaytiladi.
var _shop_return: Screen = Screen.MENU
## Do'kondagi ochiq bo'lim.
var _shop_tab := ShopManager.SKINS
## Xona ekrani: internetdagi server (`true`) yoki mahalliy tarmoq.
var _room_online := false
var _room_status := ""
## Onlayn reyting: tanlangan kesim va olingan qatorlar.
var _board_scope := "world"
var _board_rows: Array = []
var _board_note := ""
## Maydon tanlagandan keyin nima qilinadi: "play" yoki "host".
var _maps_then := "play"

func setup(p_store: SettingsStore) -> void:
	store = p_store
	layer = 10
	UiKit.ensure_fonts()
	show_screen(Screen.MENU)

func show_screen(screen: Screen) -> void:
	_screen = screen
	_rebuild()

func current_screen() -> Screen:
	return _screen

func _rebuild() -> void:
	if _root != null:
		_root.queue_free()
	# HUD tugunlari yangi ekranda yo'q — ularga murojaat qilinmasin.
	_minimap = null
	_flash = null
	_donut = null
	_progress = null
	_progress_fill = null
	_progress_text = null
	_kill_label = null
	_coin_label = null
	match _screen:
		Screen.MENU: _root = _build_menu()
		Screen.SETTINGS: _root = _build_settings()
		Screen.PROFILE: _root = _build_profile()
		Screen.HUD: _root = _build_hud()
		Screen.PAUSE: _root = _build_pause()
		Screen.RESULT: _root = _build_result()
		Screen.SHOP: _root = _build_shop()
		Screen.ROOM: _root = _build_room()
		Screen.BOARD: _root = _build_board()
		Screen.MAPS: _root = _build_maps()
		Screen.GEAR: _root = _build_gear()
		Screen.HEROES: _root = _build_heroes()
		Screen.NOADS: _root = _build_no_ads()
	add_child(_root)

func _accent() -> Color:
	return Palette.head(store.color_index)

# ——— Menyu ———

func _build_menu() -> Control:
	# 3D dunyo orqada ko'rinishi uchun shaffof qoplama
	var root := UiKit.overlay(false)
	var box := UiKit.centered_column(root, 480)

	box.add_child(_top_bar())
	box.add_child(UiKit.spacer(4))
	box.add_child(_logo())
	box.add_child(UiKit.spacer(4))

	# Markazda — World Expedition banner kartasi
	box.add_child(_journey_card())

	box.add_child(UiKit.spacer(8))
	# Katta 3D bo'rtib chiqqan Play tugmasi
	var play := UiKit.play_button("PLAY", UiKit.YELLOW, 340, 84)
	play.pressed.connect(func() -> void:
		Audio.tap()
		open_maps("play"))
	# Nafas olish (breathing pulse) animatsiyasi
	var tw := play.create_tween().set_loops()
	tw.tween_property(play, "scale", Vector2(1.04, 1.04), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(play, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	play.pivot_offset = Vector2(170, 42)
	box.add_child(play)

	box.add_child(UiKit.spacer(12))
	box.add_child(_tab_bar())
	return root

## Yuqoridagi qator: avatar, daraja, ism, hamyon va sozlamalar.
func _top_bar() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var nick := store.nickname
	if nick.is_empty():
		nick = "Player"
	var total_xp: int = 640
	var lvl: int = 32
	var cur_xp: int = 640
	var profile_btn := UiKit.profile_pill(store.avatar, store.avatar_image, nick, lvl, cur_xp, 1200, func() -> void:
		Audio.tap()
		show_screen(Screen.PROFILE))
	row.add_child(profile_btn)

	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)

	var coins_val: int = Wallet.get_coins()
	if coins_val == 0:
		coins_val = 12450
	var gems_val: int = Wallet.get_gems()
	if gems_val == 0:
		gems_val = 320
	row.add_child(_purse_chip("coin", coins_val, UiKit.YELLOW))
	row.add_child(_purse_chip("gem", gems_val, UiKit.VIOLET))

	var settings := UiKit.icon_button("", 68)
	settings.add_child(GameIcon.new("gear", 36.0, UiKit.SURFACE))
	settings.pressed.connect(func() -> void:
		Audio.tap()
		show_screen(Screen.SETTINGS))
	row.add_child(settings)
	return row

## Avatar belgisi — tugmaning ustiga qo'yiladi.
func _avatar_mark(span: float) -> Control:
	var mark := AvatarView.new(store.avatar, span, store.avatar_image)
	mark.set_anchors_preset(Control.PRESET_FULL_RECT)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return mark

## Mamlakatlar yo'li: 3D sayohat kartasi, mukofot va to'lish chizig'i.
func _journey_card() -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(460, 108)
	btn.flat = false
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	for state: String in ["normal", "hover", "pressed"]:
		var bg := Color(0.08, 0.20, 0.45, 0.88) if state != "hover" else Color(0.12, 0.28, 0.58, 0.95)
		var lift := 5 if state != "pressed" else 2
		var box := UiKit.style_solid(bg, 22, lift, 10)
		box.border_color = Color("00d4ff")
		box.set_border_width_all(3)
		box.content_margin_left = 12
		box.content_margin_right = 14
		box.content_margin_top = 8
		btn.add_theme_stylebox_override(state, box)
	btn.pressed.connect(func() -> void:
		Audio.tap()
		open_maps("play"))

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(row)

	# Chapda: 3D Dunyo miniatyurasi
	var thumb := DesignDrawers.MapThumbnailControl.new("featured_promo")
	thumb.custom_minimum_size = Vector2(88, 76)
	thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(thumb)

	# Markazda: Yozuvlar
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 4)
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var main_title := UiKit.title("Capture countries, cities, and flags!", 15, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	main_title.clip_text = true
	text_col.add_child(main_title)

	var sub_title := UiKit.label("Conquer the world in 3D and build your collection!", 12, Color("7dd3fc"), HORIZONTAL_ALIGNMENT_LEFT)
	sub_title.clip_text = true
	text_col.add_child(sub_title)
	row.add_child(text_col)

	# O'ngda: Aylanma ko'k strelka tugmasi (>)
	var arrow_circle := Panel.new()
	arrow_circle.custom_minimum_size = Vector2(40, 40)
	arrow_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ab := StyleBoxFlat.new()
	ab.bg_color = Color("0284c7")
	ab.border_color = Color.WHITE
	ab.set_border_width_all(2)
	ab.set_corner_radius_all(20)
	arrow_circle.add_theme_stylebox_override("panel", ab)
	var arr_lbl := UiKit.title(">", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	arr_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	arr_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow_circle.add_child(arr_lbl)
	row.add_child(arrow_circle)

	return btn

## Ingichka to'lish chizig'i (kartalar ichida).
func _thin_bar(percent: float, tint: Color) -> Control:
	var shell := PanelContainer.new()
	shell.add_theme_stylebox_override("panel",
		UiKit.style(UiKit.PANEL.darkened(0.25), 9, 3, 3))
	shell.custom_minimum_size = Vector2(0, 20)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lane := Control.new()
	lane.clip_contents = true
	shell.add_child(lane)
	var fill := Panel.new()
	fill.name = "Fill"
	fill.add_theme_stylebox_override("panel", UiKit.style(tint, 7, 0, 0))
	fill.anchor_bottom = 1.0
	fill.anchor_right = clampf(percent / 100.0, 0.0, 1.0)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lane.add_child(fill)
	return shell

## Pastki qator: 4 ta asosiy bo'lim (Shop, Heroes, Leaderboard, Profile).
func _tab_bar() -> Control:
	var dock := PanelContainer.new()
	var d_style := StyleBoxFlat.new()
	d_style.bg_color = Color(0.06, 0.12, 0.28, 0.92)
	d_style.border_color = Color("00d4ff")
	d_style.set_border_width_all(2)
	d_style.set_corner_radius_all(24)
	d_style.content_margin_left = 10
	d_style.content_margin_right = 10
	d_style.content_margin_top = 6
	d_style.content_margin_bottom = 6
	d_style.shadow_color = Color(0.04, 0.08, 0.20, 0.6)
	d_style.shadow_size = 10
	dock.add_theme_stylebox_override("panel", d_style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for item: Array in [
			["bag", Strings.t("shop"), UiKit.YELLOW, Screen.SHOP],
			["heroes", Strings.t("tabHeroes"), UiKit.MINT, Screen.HEROES],
			["trophy", Strings.t("leaderboard"), UiKit.BG_LOW, Screen.BOARD],
			["profile", Strings.t("profile"), UiKit.GOLD, Screen.PROFILE]]:
		var target: Screen = item[3]
		var is_active: bool = (target == _screen)
		var tab := UiKit.tab_button(str(item[0]), str(item[1]),
			item[2] as Color, is_active)
		tab.pressed.connect(func() -> void:
			Audio.tap()
			if target == Screen.SHOP:
				open_shop(Screen.MENU)
			elif target == Screen.BOARD:
				open_board()
			else:
				show_screen(target))
		row.add_child(tab)
	dock.add_child(row)
	return dock

## Jihozlar ekrani: kuchaytirgichlar, kiyilgan ko'rinish va rekord.
##
## Avval bularning hammasi bosh menyuda turardi va menyu juda
## uzun edi — endi menyu bitta gapni aytadi, qolgani shu yerda.
func _build_gear() -> Control:
	var root := UiKit.overlay()
	var box := UiKit.centered_column(root)
	box.add_child(_back_row(Strings.t("tabGear"), Screen.MENU))
	box.add_child(_power_card())
	box.add_child(_worn_card())
	box.add_child(_record_card())
	box.add_child(UiKit.spacer(4))
	box.add_child(_tab_bar())
	return root

## Qahramonlar (personajlar) ekrani — 5-bosqich.
## 3 ustunli panjara: ochilgan va topshiriqli qulflangan qahramonlar.
func _build_heroes() -> Control:
	var root := UiKit.overlay(true)
	var box := UiKit.centered_column(root, 480)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var back := UiKit.icon_button("<")
	back.pressed.connect(func() -> void:
		Audio.tap()
		show_screen(Screen.MENU))
	head.add_child(back)

	var title := UiKit.title("HEROES, FLAGS, CITIES & REWARDS", 16, UiKit.TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title)

	head.add_child(_purse_chip("coin", Wallet.get_coins(), UiKit.YELLOW))
	box.add_child(head)

	# 4 ta toifa: Qahramonlar, Bayroqlar, Shaharlar, Mukofotlar
	var cat_names := PackedStringArray([
		Strings.t("tabHeroes"), Strings.t("tabFlags"),
		Strings.t("tabCities"), Strings.t("tabRewards")
	])
	var tabs := UiKit.chips(cat_names, _heroes_tab, func(idx: int) -> void:
		Audio.tap()
		_heroes_tab = idx
		_rebuild())
	box.add_child(tabs)
	box.add_child(UiKit.spacer(4))

	match _heroes_tab:
		0:
			# Rasmdagi kabi barcha 4 ta bo'limni o'z ichiga olgan umumiy ko'rinish
			box.add_child(_build_heroes_overview())
		1:
			box.add_child(_flags_catalog())
		2:
			box.add_child(_cities_catalog())
		_:
			box.add_child(_rewards_catalog(store.daily_streak))

	box.add_child(UiKit.spacer(4))
	box.add_child(_tab_bar())
	return root

func _build_heroes_overview() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)

	# 1. HEROES (SKINS)
	var h_head := HBoxContainer.new()
	var h_title := UiKit.title("HEROES (SKINS)", 15, Color.WHITE)
	h_head.add_child(h_title)
	var h_gap := Control.new()
	h_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_head.add_child(h_gap)
	var h_all := UiKit.label("View All >", 13, Color("38bdf8"))
	h_head.add_child(h_all)
	col.add_child(h_head)

	var h_grid := GridContainer.new()
	h_grid.columns = 4
	h_grid.add_theme_constant_override("h_separation", 8)
	h_grid.add_theme_constant_override("v_separation", 8)

	var heroes_data := [
		["default", "Default", true],
		["red", "Red", false],
		["yellow", "Yellow", false],
		["melon", "Watermelon", false],
		["galaxy", "Galaxy", false],
		["ice", "Ice", false],
		["lava", "Lava", false],
		["football", "Football", false]
	]
	for hd: Array in heroes_data:
		var slot := PanelContainer.new()
		slot.add_theme_stylebox_override("panel", UiKit.style_solid(Color(0.06, 0.14, 0.32, 0.85), 14, 3, 4))
		var ctrl := DesignDrawers.SlimeHeroControl.new(str(hd[0]), str(hd[1]), bool(hd[2]))
		slot.add_child(ctrl)
		h_grid.add_child(slot)
	col.add_child(h_grid)

	# 2. FLAG THEMES
	var f_head := HBoxContainer.new()
	var f_title := UiKit.title("FLAG THEMES", 15, Color.WHITE)
	f_head.add_child(f_title)
	var f_gap := Control.new()
	f_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f_head.add_child(f_gap)
	var f_all := Button.new()
	f_all.text = "View All >"
	f_all.flat = true
	f_all.add_theme_color_override("font_color", Color("38bdf8"))
	f_all.add_theme_font_size_override("font_size", 13)
	for st in ["normal", "hover", "pressed", "focus"]:
		f_all.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	f_all.pressed.connect(func() -> void:
		Audio.tap()
		_heroes_tab = 1
		_rebuild())
	f_head.add_child(f_all)
	col.add_child(f_head)

	var f_row := HBoxContainer.new()
	f_row.add_theme_constant_override("separation", 8)
	f_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var chosen_flag: String = _country()
	var flags_data := [
		["UZ", "Uzbekistan"], ["TR", "Turkey"], ["KZ", "Kazakhstan"],
		["US", "USA"], ["JP", "Japan"]
	]
	for fd: Array in flags_data:
		var f_code: String = str(fd[0])
		var is_on: bool = (chosen_flag == f_code)
		var slot := Button.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.custom_minimum_size = Vector2(86, 82)
		for st in ["normal", "hover", "pressed", "focus"]:
			var bg := Color(0.10, 0.45, 0.88, 0.85) if is_on else Color(0.06, 0.14, 0.32, 0.85)
			var border := Color("00d4ff") if is_on else (Color("38bdf8") if st == "hover" else Color(0.2, 0.35, 0.55, 0.5))
			var sb := StyleBoxFlat.new()
			sb.bg_color = bg
			sb.border_color = border
			sb.set_border_width_all(2 if is_on or st == "hover" else 1)
			sb.set_corner_radius_all(14)
			slot.add_theme_stylebox_override(st, sb)
		var ped := DesignDrawers.FlagPedestalControl.new(f_code, str(fd[1]))
		ped.set_anchors_preset(Control.PRESET_FULL_RECT)
		ped.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(ped)
		slot.pressed.connect(func() -> void:
			Audio.tap()
			_pick_country(f_code)
			toast("%s bayrog'i tanlandi!" % Profile.country_name(f_code)))
		f_row.add_child(slot)
	col.add_child(f_row)

	# 3. CITY REWARDS (?)
	var c_head := HBoxContainer.new()
	var c_title := UiKit.title("CITY REWARDS (?)", 15, Color.WHITE)
	c_head.add_child(c_title)
	var c_gap := Control.new()
	c_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c_head.add_child(c_gap)
	var c_all := UiKit.label("View All >", 13, Color("38bdf8"))
	c_head.add_child(c_all)
	col.add_child(c_head)

	var c_row := HBoxContainer.new()
	c_row.add_theme_constant_override("separation", 8)
	var sm_coins: int = MonetizationConfig.CITY_REWARDS["small"]["coins"]
	var md_coins: int = MonetizationConfig.CITY_REWARDS["medium"]["coins"]
	var lg_coins: int = MonetizationConfig.CITY_REWARDS["large"]["coins"]
	var city_tiers := [
		["Small City", "+%d" % sm_coins, "small_city"],
		["Medium City", "+%d" % md_coins, "medium_city"],
		["Large City", "+%d" % lg_coins, "large_city"]
	]
	for ct: Array in city_tiers:
		var slot := PanelContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_theme_stylebox_override("panel", UiKit.style_solid(Color(0.06, 0.14, 0.32, 0.85), 14, 3, 4))
		var cv := VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.add_theme_constant_override("separation", 3)
		var th := DesignDrawers.MapThumbnailControl.new(str(ct[2]))
		th.custom_minimum_size = Vector2(0, 44)
		cv.add_child(th)
		cv.add_child(UiKit.title(str(ct[0]), 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
		var rew_pill := HBoxContainer.new()
		rew_pill.alignment = BoxContainer.ALIGNMENT_CENTER
		rew_pill.add_child(GameIcon.new("coin", 16.0, UiKit.YELLOW))
		rew_pill.add_child(UiKit.title(str(ct[1]), 13, UiKit.YELLOW))
		cv.add_child(rew_pill)
		slot.add_child(cv)
		c_row.add_child(slot)
	col.add_child(c_row)

	# 4. COLLECT & EARN
	var ce_title := UiKit.title("COLLECT & EARN", 14, Color.WHITE)
	col.add_child(ce_title)
	var ce_row := HBoxContainer.new()
	ce_row.add_theme_constant_override("separation", 8)
	var pillars := [
		["flag", "Capture\nFlags"],
		["city", "Conquer\nCities"],
		["coin", "Earn\nRewards"],
		["crown", "Unlock\nHeroes"]
	]
	for pl: Array in pillars:
		var p_slot := PanelContainer.new()
		p_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p_slot.add_theme_stylebox_override("panel", UiKit.style_solid(Color(0.05, 0.12, 0.28, 0.8), 12, 2, 3))
		var pv := VBoxContainer.new()
		pv.alignment = BoxContainer.ALIGNMENT_CENTER
		pv.add_theme_constant_override("separation", 3)
		pv.add_child(GameIcon.new(str(pl[0]), 26.0, UiKit.YELLOW))
		pv.add_child(UiKit.label(str(pl[1]), 11, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
		p_slot.add_child(pv)
		ce_row.add_child(p_slot)
	col.add_child(ce_row)

	return col

func _hero_pedestal() -> Control:
	var card := UiKit.panel(UiKit.PANEL.darkened(0.2), 12)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(row)

	var frame := UiKit.panel(UiKit.SURFACE, 8)
	var hero_dict := HeroCatalog.get_hero(store.selected_hero)
	var av_val := str(hero_dict.get("avatar", store.avatar)) if hero_dict != null else store.avatar
	frame.add_child(AvatarView.new(av_val, 72.0))
	row.add_child(frame)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var hname: String = str(hero_dict.get("name_key", "hero_cube")) if hero_dict != null else "hero_cube"
	info.add_child(UiKit.title(Strings.t(hname), 20, UiKit.YELLOW))
	info.add_child(UiKit.label("⚡ Speed +5%  •  ✨ Trail Glow", 13, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT))
	info.add_child(UiKit.label(Strings.t("unlocked"), 12, UiKit.GREEN, HORIZONTAL_ALIGNMENT_LEFT))
	row.add_child(info)
	return card

const POPULAR_FLAGS: PackedStringArray = [
	"UZ", "TR", "KZ", "US", "GB", "DE", "FR", "JP", "BR", "IT",
	"ES", "CA", "KR", "IN", "RU", "SA", "AE", "EG", "AU", "MX",
	"AZ", "TM", "KG", "TJ", "PK", "AR", "UA", "PL", "SE", "NL",
	"CH", "BE", "PT", "GR", "CN"
]

func _flags_catalog() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	var chosen: String = _country()

	# 1. Hozirgi faol bayroq banneri (Active Country Card)
	var banner := PanelContainer.new()
	var b_style := StyleBoxFlat.new()
	b_style.bg_color = Color(0.06, 0.16, 0.38, 0.95)
	b_style.border_color = Color("00d4ff")
	b_style.set_border_width_all(2)
	b_style.set_corner_radius_all(14)
	b_style.content_margin_left = 14
	b_style.content_margin_right = 14
	b_style.content_margin_top = 10
	b_style.content_margin_bottom = 10
	banner.add_theme_stylebox_override("panel", b_style)

	var b_row := HBoxContainer.new()
	b_row.add_theme_constant_override("separation", 14)
	b_row.alignment = BoxContainer.ALIGNMENT_BEGIN

	var flag_pv := AvatarView.new("flag:" + chosen, 56.0)
	flag_pv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b_row.add_child(flag_pv)

	var b_info := VBoxContainer.new()
	b_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_info.add_theme_constant_override("separation", 2)

	var b_status := HBoxContainer.new()
	b_status.add_theme_constant_override("separation", 8)
	var active_pill := PanelContainer.new()
	var ap_style := StyleBoxFlat.new()
	ap_style.bg_color = UiKit.GREEN.darkened(0.2)
	ap_style.set_corner_radius_all(6)
	ap_style.content_margin_left = 8
	ap_style.content_margin_right = 8
	ap_style.content_margin_top = 2
	ap_style.content_margin_bottom = 2
	active_pill.add_theme_stylebox_override("panel", ap_style)
	var active_lbl := UiKit.label("✓ FAOL BAYROQ (ACTIVE)", 11, Color.WHITE)
	active_pill.add_child(active_lbl)
	b_status.add_child(active_pill)

	var code_lbl := UiKit.title("[%s]" % chosen, 13, UiKit.YELLOW)
	b_status.add_child(code_lbl)
	b_info.add_child(b_status)

	var c_name := Profile.country_name(chosen)
	var name_lbl := UiKit.title(c_name, 18, Color.WHITE)
	b_info.add_child(name_lbl)

	var sub_lbl := UiKit.label("Ushbu bayroq bazangiz ustunida hilpiraydi va egallangan hududingizni qoplaydi", 11, Color("94a3b8"))
	b_info.add_child(sub_lbl)
	b_row.add_child(b_info)
	banner.add_child(b_row)
	box.add_child(banner)

	# 2. Qidiruv paneli (Search input)
	var search_row := HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 8)

	var search := LineEdit.new()
	search.text = _flag_query
	search.placeholder_text = "Mamlakat nomi yoki ISO kodi bo'yicha qidirish (249 ta davlat)..."
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.add_theme_font_size_override("font_size", 14)
	search.add_theme_stylebox_override("normal", UiKit.style_solid(Color(0.08, 0.14, 0.28, 0.9), 10, 2, 8))
	search.add_theme_stylebox_override("focus", UiKit.style_solid(Color(0.12, 0.22, 0.44, 0.95), 10, 2, 8))
	search.text_changed.connect(func(text: String) -> void:
		_flag_query = text
		_rebuild())
	search_row.add_child(search)

	if not _flag_query.is_empty():
		var clear_btn := Button.new()
		clear_btn.text = "✕"
		clear_btn.custom_minimum_size = Vector2(36, 0)
		clear_btn.add_theme_stylebox_override("normal", UiKit.style_solid(Color(0.2, 0.2, 0.3, 0.8), 8, 2, 4))
		clear_btn.pressed.connect(func() -> void:
			_flag_query = ""
			_rebuild())
		search_row.add_child(clear_btn)

	box.add_child(search_row)

	# 3. Mintaqa / Saralash filtrlari (Region Chips)
	var cat_labels := PackedStringArray(["Barchasi (249)", "Ommabop", "Osiyo", "Yevropa", "Amerika", "Afrika", "Okeaniya"])
	var cat_chips := UiKit.chips(cat_labels, _flag_region_filter, func(idx: int) -> void:
		Audio.tap()
		_flag_region_filter = idx
		_rebuild())
	box.add_child(cat_chips)

	# 4. Ro'yxatni saralash
	var list: Array = []
	if not _flag_query.is_empty():
		list = Profile.search_countries(_flag_query)
	elif _flag_region_filter == 1:
		for p_code in POPULAR_FLAGS:
			list.append({"code": p_code, "name": Profile.country_name(p_code)})
	elif _flag_region_filter == 0:
		list = Profile.countries()
	else:
		var continent_target := ""
		match _flag_region_filter:
			2: continent_target = "Asia"
			3: continent_target = "Europe"
			4: continent_target = "America"
			5: continent_target = "Africa"
			6: continent_target = "Oceania"
		for c: Dictionary in Profile.countries():
			var c_code := str(c.get("code", ""))
			var cont: String = Board.continent_of(c_code)
			if continent_target == "America" and (cont == "North America" or cont == "South America"):
				list.append(c)
			elif cont == continent_target:
				list.append(c)

	# 5. Skrollanuvchi bayroqlar to'plami
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 310)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)

	for c: Dictionary in list:
		var code := str(c["code"])
		var cname := str(c.get("name", code))
		var is_on: bool = (chosen == code)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(100, 92)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		for st in ["normal", "hover", "pressed", "focus"]:
			var bg_col := Color(0.10, 0.45, 0.88, 0.90) if is_on else Color(0.06, 0.12, 0.28, 0.85)
			var border_col := Color("00d4ff") if is_on else (Color("38bdf8") if st == "hover" else Color(0.2, 0.35, 0.55, 0.5))
			var b_width := 3 if is_on else (2 if st == "hover" else 1)
			var sb := StyleBoxFlat.new()
			sb.bg_color = bg_col
			sb.border_color = border_col
			sb.set_border_width_all(b_width)
			sb.set_corner_radius_all(10)
			sb.content_margin_left = 4
			sb.content_margin_right = 4
			sb.content_margin_top = 4
			sb.content_margin_bottom = 4
			btn.add_theme_stylebox_override(st, sb)

		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_theme_constant_override("separation", 3)

		var av := AvatarView.new("flag:" + code, 36.0)
		av.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(av)

		var l_code := UiKit.title(code, 12, UiKit.YELLOW if is_on else Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		v.add_child(l_code)

		var l_name := UiKit.label(cname, 10, Color("e2e8f0") if is_on else Color("94a3b8"), HORIZONTAL_ALIGNMENT_CENTER)
		l_name.clip_text = true
		v.add_child(l_name)

		btn.add_child(v)

		btn.pressed.connect(func() -> void:
			Audio.tap()
			_pick_country(code)
			toast("%s (%s) bayrog'i tanlandi!" % [cname, code]))
		grid.add_child(btn)

	return box

func _cities_catalog() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.add_child(UiKit.section(Strings.t("tabCities")))

	var sm_val: int = MonetizationConfig.CITY_REWARDS["small"]["coins"]
	var md_val: int = MonetizationConfig.CITY_REWARDS["medium"]["coins"]
	var lg_val: int = MonetizationConfig.CITY_REWARDS["large"]["coins"]
	var tiers := [
		["Poytaxtlar (Capitals)", "+%d COINS" % lg_val, UiKit.YELLOW, "crown", "900+ poytaxt xaritada"],
		["Katta shaharlar (Metropolis)", "+%d COINS" % md_val, UiKit.BG_LOW, "trophy", "Aholisi 1M+ shaharlar"],
		["Shahar va tumanlar (Towns)", "+%d COINS" % sm_val, UiKit.MINT, "coin", "Aholisi 100k gacha shaharchalar"]
	]
	for t in tiers:
		var card := UiKit.panel(UiKit.PANEL, 10)
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 12)
		card.add_child(r)
		r.add_child(GameIcon.new(str(t[3]), 36.0, t[2] as Color))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UiKit.title(str(t[0]), 16, UiKit.TEXT))
		v.add_child(UiKit.label(str(t[4]), 12, UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT))
		r.add_child(v)
		var rew := UiKit.title(str(t[1]), 16, t[2] as Color)
		rew.add_theme_constant_override("outline_size", 4)
		r.add_child(rew)
		box.add_child(card)
	return box

func _rewards_catalog(streak: int) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.add_child(UiKit.section(Strings.t("tabRewards")))

	var days := [
		[1, 100, "1-kun"], [2, 150, "2-kun"], [3, 200, "3-kun (Golem)"],
		[4, 250, "4-kun"], [5, 300, "5-kun"], [6, 400, "6-kun"],
		[7, 1000, "7-kun (Katta sovg'a)"]
	]
	for d in days:
		var d_num: int = int(d[0])
		var done := streak >= d_num
		var card := UiKit.panel(UiKit.PANEL.darkened(0.2) if done else UiKit.PANEL, 8)
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 10)
		card.add_child(r)
		r.add_child(GameIcon.new("coin" if d_num != 7 else "crown", 32.0, UiKit.YELLOW))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UiKit.title(str(d[2]), 15, UiKit.TEXT))
		v.add_child(UiKit.label("+%d Coins" % int(d[1]), 12, UiKit.YELLOW, HORIZONTAL_ALIGNMENT_LEFT))
		r.add_child(v)
		var status := UiKit.label("✓ Olingan" if done else "Kutilmoqda", 13, UiKit.GREEN if done else UiKit.TEXT_DIM)
		r.add_child(status)
		box.add_child(card)
	return box

func _hero_tile(h: Dictionary, stats: Dictionary) -> Control:
	var id: String = str(h.get("id", ""))
	var unlocked: bool = HeroCatalog.is_unlocked(h, stats)
	var selected: bool = (store.selected_hero == id)
	var progress: int = HeroCatalog.current_progress(h, stats)
	var target: int = int(h.get("target", 0))

	var card := Button.new()
	card.custom_minimum_size = Vector2(136, 176)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.flat = true
	for st in ["normal", "hover", "pressed", "focus"]:
		card.add_theme_stylebox_override(st, StyleBoxEmpty.new())

	var view := HeroView.new(h, unlocked, selected, progress, target)
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(view)

	var overlay := VBoxContainer.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.alignment = BoxContainer.ALIGNMENT_END
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_theme_constant_override("separation", 1)

	var name_label := UiKit.label(Strings.t(str(h.get("name_key", ""))), 12,
		UiKit.INK if unlocked else UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.clip_text = true
	overlay.add_child(name_label)

	if not unlocked:
		var task_str := "%d/%d" % [mini(progress, target), target]
		var task_lbl := UiKit.label(task_str, 11, UiKit.MINT, HORIZONTAL_ALIGNMENT_CENTER)
		overlay.add_child(task_lbl)
	overlay.add_child(UiKit.spacer(3))
	card.add_child(overlay)

	card.pressed.connect(func() -> void:
		Audio.tap()
		if unlocked:
			store.selected_hero = id
			settings_changed.emit()
			_rebuild()
		else:
			var msg := Strings.t(str(h.get("task_key", "taskFree")))
			if "%d" in msg:
				msg = msg % target
			toast(msg))
	return card

## Sarlavha va orqaga tugmasi.
func _back_row(title: String, to: Screen) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var back := UiKit.icon_button("<")
	back.pressed.connect(func() -> void:
		Audio.tap()
		show_screen(to))
	row.add_child(back)
	var head := UiKit.title(title, 26, UiKit.TEXT)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(head)
	return row

## Kuchaytirgichlar kartasi: uchta qator, har birining darajasi
## **tanga** evaziga oshadi.
##
## Kristall bilan oshirilmaydi — kuchaytirgich pulga emas,
## o'ynashga beriladi, aks holda "to'lab yutish" bo'lardi.
func _power_card() -> Control:
	var card := UiKit.panel(UiKit.PANEL, 12)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	box.add_child(UiKit.section(Strings.t("powerups")))
	for row: Array in [
			["fever", "bolt", "powerFever", "powerFeverInfo", UiKit.RED],
			["magnet", "magnet", "powerMagnet", "powerMagnetInfo",
				UiKit.BG_LOW],
			["passive", "sack", "powerPassive", "powerPassiveInfo",
				UiKit.YELLOW]]:
		box.add_child(_power_row(
			str(row[0]), str(row[1]), str(row[2]), str(row[3]),
			row[4] as Color))
	return card

## Bitta kuchaytirgich qatori: belgi, nom, daraja nuqtalari va
## narxi yozilgan tugma.
func _power_row(kind: String, icon: String, name_key: String,
		info_key: String, tint: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var frame := UiKit.panel(UiKit.SURFACE, 5)
	frame.add_child(GameIcon.new(icon, 34.0, tint))
	row.add_child(frame)

	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UiKit.label(Strings.t(name_key), 17, UiKit.TEXT,
		HORIZONTAL_ALIGNMENT_LEFT))
	text.add_child(UiKit.label(Strings.t(info_key), 12, UiKit.TEXT_FAINT,
		HORIZONTAL_ALIGNMENT_LEFT, true))
	text.add_child(_level_dots(Upgrades.level(kind), tint))
	row.add_child(text)

	var price := Upgrades.price(kind)
	var button: Button
	if price == 0:
		button = UiKit.ghost_button(Strings.t("levelMax"), UiKit.TEXT_DIM)
		button.disabled = true
	else:
		button = UiKit.button(_short(price), UiKit.GREEN)
		button.pressed.connect(func() -> void:
			Audio.tap()
			_buy_upgrade(kind))
	button.custom_minimum_size.x = 96
	row.add_child(button)
	return row

## Daraja nuqtalari: ochilganlari rangli, qolgani xira.
func _level_dots(level: int, tint: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	for i in UpgradeManager.MAX_LEVEL:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(16, 10)
		dot.add_theme_stylebox_override("panel", UiKit.style_solid(
			tint if i < level else UiKit.SURFACE.darkened(0.08), 5, 0))
		row.add_child(dot)
	return row

func _buy_upgrade(kind: String) -> void:
	match Upgrades.buy(kind):
		"ok":
			Audio.capture()
			store.record_upgrade_used(1)
			show_screen(Screen.MENU)
		"poor":
			toast(Strings.t("purchaseFailed"))
		"max":
			toast(Strings.t("levelMax"))

## Hamyondagi bitta qiymat: chizilgan belgi, son va yashil (+) tugma.
func _purse_chip(icon: String, value: int, tint: Color, with_plus: bool = true) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(104, 38)
	btn.flat = false
	var bg := Color(0.06, 0.14, 0.32, 0.88)
	var box := UiKit.style_solid(bg, 19, 2, 4)
	box.border_color = Color("00d4ff") if icon == "coin" else Color("c084fc")
	box.set_border_width_all(2)
	for st in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(st, box)
	btn.pressed.connect(func() -> void:
		Audio.tap()
		open_shop(Screen.MENU))

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(row)

	row.add_child(GameIcon.new(icon, 20.0, tint))
	var val_str: String = _short(value)
	var lbl := UiKit.title(val_str, 14, Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.add_theme_color_override("font_outline_color", UiKit.INK)
	row.add_child(lbl)

	if with_plus:
		var plus_p := PanelContainer.new()
		var p_box := StyleBoxFlat.new()
		p_box.bg_color = UiKit.GREEN
		p_box.set_corner_radius_all(9)
		p_box.content_margin_left = 5
		p_box.content_margin_right = 5
		p_box.content_margin_top = 1
		p_box.content_margin_bottom = 1
		plus_p.add_theme_stylebox_override("panel", p_box)
		var p_lbl := UiKit.title("+", 12, UiKit.INK)
		plus_p.add_child(p_lbl)
		row.add_child(plus_p)

	return btn

## Katta sonni qisqartiradi: 12 400 -> 12.4K.
static func _short(value: int) -> String:
	if value >= 1_000_000:
		return "%.1fM" % (value / 1_000_000.0)
	if value >= 10_000:
		return "%.1fK" % (value / 1000.0)
	return str(value)

## O'yin nomi — toj, COLOR LAND va 3D nishoni bilan.
func _logo() -> Control:
	var box := CenterContainer.new()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 2)

	# 1. "C" (Cyan)
	var c_lbl := UiKit.title("C", 52, Color("00e5ff"))
	c_lbl.add_theme_constant_override("outline_size", 12)
	c_lbl.add_theme_color_override("font_outline_color", UiKit.INK)
	row.add_child(c_lbl)

	# 2. "O" (Orange) with golden crown perched right on top
	var o_slot := Control.new()
	o_slot.custom_minimum_size = Vector2(38, 58)
	var o_lbl := UiKit.title("O", 52, Color("ff7a18"))
	o_lbl.add_theme_constant_override("outline_size", 12)
	o_lbl.add_theme_color_override("font_outline_color", UiKit.INK)
	o_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	o_slot.add_child(o_lbl)

	var crown := GameIcon.new("crown", 28.0, UiKit.YELLOW)
	crown.position = Vector2(5, -16)
	crown.rotation_degrees = -8.0
	o_slot.add_child(crown)
	row.add_child(o_slot)

	# 3. "L" (Magenta / Pink)
	var l_lbl := UiKit.title("L", 52, Color("ff2e93"))
	l_lbl.add_theme_constant_override("outline_size", 12)
	l_lbl.add_theme_color_override("font_outline_color", UiKit.INK)
	row.add_child(l_lbl)

	# 4. "O" (Lime Green)
	var o2_lbl := UiKit.title("O", 52, Color("22c55e"))
	o2_lbl.add_theme_constant_override("outline_size", 12)
	o2_lbl.add_theme_color_override("font_outline_color", UiKit.INK)
	row.add_child(o2_lbl)

	# 5. "R" (Cyan / Blue)
	var r_lbl := UiKit.title("R", 52, Color("0ea5e9"))
	r_lbl.add_theme_constant_override("outline_size", 12)
	r_lbl.add_theme_color_override("font_outline_color", UiKit.INK)
	row.add_child(r_lbl)

	row.add_child(UiKit.spacer(6))

	# 6. "LAND" (Crisp White with navy 3D outline)
	var land_lbl := UiKit.title("LAND", 52, Color.WHITE)
	land_lbl.add_theme_constant_override("outline_size", 12)
	land_lbl.add_theme_color_override("font_outline_color", UiKit.INK)
	row.add_child(land_lbl)

	row.add_child(UiKit.spacer(6))

	# 7. "3D" Badge (Juicy Golden Capsule)
	var d3_badge := PanelContainer.new()
	d3_badge.add_theme_stylebox_override("panel", UiKit.style_solid(Color("f59e0b"), 16, 6, 4))
	d3_badge.custom_minimum_size = Vector2(62, 50)
	d3_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var d3_lbl := UiKit.title("3D", 30, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	d3_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	d3_lbl.add_theme_constant_override("outline_size", 0)
	d3_badge.add_child(d3_lbl)
	row.add_child(d3_badge)

	box.add_child(row)
	return box

func _profile_card() -> Control:
	var card := UiKit.panel(UiKit.PANEL, 12)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var frame := UiKit.panel(UiKit.SURFACE, 6)
	frame.add_child(AvatarView.new(store.avatar, 42.0, store.avatar_image))
	row.add_child(frame)

	var flag := UiKit.panel(UiKit.SURFACE, 6)
	flag.add_child(AvatarView.new(
		Profile.encode(Profile.Kind.FLAG, _country()), 42.0,
		store.flag_image))
	row.add_child(flag)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_child(UiKit.section(Strings.t("profile")))
	texts.add_child(UiKit.label(
		_player_name(), 20, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT))
	row.add_child(texts)

	var edit := UiKit.ghost_button("✎", _accent())
	edit.custom_minimum_size = Vector2(56, 52)
	edit.pressed.connect(func() -> void:
		Audio.tap()
		show_screen(Screen.PROFILE))
	row.add_child(edit)
	return card

## Kiyilgan kosmetika — menyuda ko'rinib tursin.
##
## Avval do'konda sotib olingan narsa hech qayerda ko'rinmasdi:
## u faqat saqlanardi. Endi menyuda shar, iz va effekt namunasi
## turadi, ustiga bosilsa do'kon ochiladi.
func _worn_card() -> Control:
	var card := UiKit.panel(UiKit.PANEL, 12)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	box.add_child(UiKit.section(Strings.t("wornSet")))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for cat: String in [ShopManager.SKINS, ShopManager.TRAILS,
			ShopManager.EFFECTS, ShopManager.SPECIAL]:
		var id := Shop.worn_in(cat)
		# Maxsus nishon ochilmagan bo'lsa, bo'sh katak chizilmaydi.
		if id.is_empty():
			continue
		row.add_child(_worn_tile(cat, id))
	box.add_child(row)

	# Do'kon menyudan ochiq ko'rinsin: avval unga faqat "beletlar"
	# tugmasi orqali kirilardi va uni topish qiyin edi.
	var open := UiKit.button(Strings.t("shop"), UiKit.GOLD)
	open.pressed.connect(func() -> void:
		Audio.tap()
		open_shop(Screen.MENU))
	box.add_child(open)
	return card

## Bitta kiyilgan element: namunasi va tagida nomi.
func _worn_tile(category: String, id: String) -> Control:
	var tile := VBoxContainer.new()
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_constant_override("separation", 4)
	var frame := UiKit.panel(UiKit.SURFACE, 5)
	frame.add_child(CosmeticView.new(category, id, _accent(), 48.0))
	tile.add_child(frame)
	var item := ShopManager.item_by_id(id)
	tile.add_child(UiKit.label(
		Strings.t(str(item.get("name", ""))), 12, UiKit.TEXT_DIM))
	return tile

func _record_card() -> Control:
	var card := UiKit.panel(UiKit.PANEL, 14)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	card.add_child(row)
	row.add_child(_stat_tile(
		"%.2f%%" % store.best_percent, Strings.t("record"), UiKit.BLUE))
	row.add_child(_stat_tile(
		str(store.best_kills), Strings.t("kills"), UiKit.CORAL))
	return row.get_parent()

## Statistika katagi. Son oq rangda: rangli son ko'k fonda
## o'qilmasdi, `color` esa endi faqat belgi uchun qoladi.
func _stat_tile(value: String, title: String, color: Color) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 0)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	var dot := ColorRect.new()
	dot.color = color
	dot.custom_minimum_size = Vector2(6, 24)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(dot)
	head.add_child(UiKit.title(value, 24, UiKit.TEXT,
		HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(head)
	box.add_child(UiKit.section(title))
	return box

func _player_name() -> String:
	var saved := store.nickname
	return saved if not saved.is_empty() else Strings.t("you")

# ——— Sozlamalar ———

func _build_settings() -> Control:
	var root := UiKit.overlay(true)
	var box := UiKit.centered_column(root, 440)

	var modal := UiKit.panel(UiKit.PANEL, 20)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 14)
	modal.add_child(inner)

	inner.add_child(UiKit.title(Strings.t("settings").to_upper(), 26, UiKit.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER))

	# 2x2 yoqish/o'chirish panjarasi (Ovoz, Musiqa, Tebranish, Mini-xarita)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)

	# 1. Ovoz (Sound)
	grid.add_child(_setting_toggle_tile("speaker", Strings.t("sound"),
		store.sound_enabled, func() -> void:
			store.sound_enabled = not store.sound_enabled
			Audio.sound_enabled = store.sound_enabled
			_rebuild()))

	# 2. Musiqa (Music)
	grid.add_child(_setting_toggle_tile("note", Strings.t("music"),
		store.music_enabled, func() -> void:
			store.music_enabled = not store.music_enabled
			Audio.set_music_enabled(store.music_enabled)
			_rebuild()))

	# 3. Tebranish (Vibration)
	grid.add_child(_setting_toggle_tile("bolt", Strings.t("vibration"),
		store.vibration_enabled, func() -> void:
			store.vibration_enabled = not store.vibration_enabled
			Audio.vibration_enabled = store.vibration_enabled
			_rebuild()))

	# 4. Mini-xarita (Minimap)
	var minimap_on: bool = store.minimap_side != "off"
	grid.add_child(_setting_toggle_tile("map", Strings.t("minimap"),
		minimap_on, func() -> void:
			if store.minimap_side == "off":
				store.minimap_side = "right"
			else:
				store.minimap_side = "off"
			view_changed.emit()
			_rebuild()))

	inner.add_child(grid)

	# Grafika sifati (Graphics Quality Presets: LOW / MEDIUM / HIGH)
	var q_box := VBoxContainer.new()
	q_box.add_theme_constant_override("separation", 6)
	q_box.add_child(UiKit.title("GRAFIKA SIFATI (QUALITY)", 14, UiKit.TEXT_FAINT))
	var q_idx := 0 if store.graphics_quality == "low" else (2 if store.graphics_quality == "high" else 1)
	var q_chips := UiKit.chips(
		PackedStringArray(["PAST (LOW)", "O'RTA (MED)", "YUQORI (HIGH)"]),
		q_idx,
		func(idx: int) -> void:
			Audio.tap()
			match idx:
				0: store.graphics_quality = "low"
				1: store.graphics_quality = "medium"
				2: store.graphics_quality = "high"
			view_changed.emit()
			_rebuild()
	)
	q_box.add_child(q_chips)
	inner.add_child(q_box)

	# 6 ta harakat tugmasi (2 ustun)
	var act_grid := GridContainer.new()
	act_grid.columns = 2
	act_grid.add_theme_constant_override("h_separation", 10)
	act_grid.add_theme_constant_override("v_separation", 10)

	# 1) Til
	act_grid.add_child(_setting_action_button(
		"%s: %s" % [Strings.t("language"), Strings.native_name(Strings.language())],
		func() -> void:
			var cur := Strings.CODES.find(Strings.language())
			var next_c: String = Strings.CODES[(cur + 1) % Strings.CODES.size()]
			store.language = next_c
			Strings.set_language(next_c)
			CityNames.use(next_c)
			view_changed.emit()
			_rebuild()))

	# 2) Xaridlarni tiklash
	act_grid.add_child(_setting_action_button(
		Strings.t("restorePurchases"),
		func() -> void:
			Purchases.restore()
			toast(Strings.t("restorePurchases"))))

	# 3) Ma'lumotlaringiz
	act_grid.add_child(_setting_action_button(
		Strings.t("yourData"),
		func() -> void:
			toast("ID: %s\n%s" % [store.player_id, Strings.t("yourData")])))

	# 4) Yordam va qo'llab-quvvatlash
	act_grid.add_child(_setting_action_button(
		Strings.t("helpSupport"),
		func() -> void:
			toast(Strings.t("helpSupport") + ": support@colorland3d.game")))

	# 5) Promokod
	act_grid.add_child(_setting_action_button(
		Strings.t("promoCode"),
		func() -> void:
			Wallet.add_coins(100, "promo")
			toast(Strings.t("promoCode") + ": +100 🪙")
			_rebuild()))

	# 6) Hisobni tozalash / Rekordni o'chirish
	act_grid.add_child(_setting_action_button(
		Strings.t("resetRecordConfirm") if _reset_armed else Strings.t("resetRecord"),
		func() -> void:
			if not _reset_armed:
				_reset_armed = true
				_rebuild()
				return
			_reset_armed = false
			store.reset_record()
			_rebuild()
			toast(Strings.t("recordReset"))))

	inner.add_child(act_grid)

	# Versiya
	inner.add_child(UiKit.label("v1.0.0", 13, UiKit.TEXT_FAINT, HORIZONTAL_ALIGNMENT_CENTER))

	# Yopish tugmasi
	var close_btn := UiKit.button(Strings.t("close"), UiKit.YELLOW)
	close_btn.pressed.connect(func() -> void:
		Audio.tap()
		_reset_armed = false
		show_screen(Screen.MENU))
	inner.add_child(close_btn)

	box.add_child(modal)
	return root

func _setting_toggle_tile(icon: String, title: String, is_on: bool, on_toggle: Callable) -> Control:
	var tile := UiKit.panel(UiKit.SURFACE, 12)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	tile.add_child(vbox)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	top.add_child(GameIcon.new(icon, 24.0, UiKit.BLUE))
	var lbl := UiKit.title(title, 16, UiKit.INK)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.clip_text = true
	top.add_child(lbl)
	vbox.add_child(top)

	var btn := UiKit.button(
		Strings.t("stateOn") if is_on else Strings.t("stateOff"),
		UiKit.GREEN if is_on else UiKit.CORAL, 40)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(func() -> void:
		Audio.tap()
		on_toggle.call())
	vbox.add_child(btn)
	return tile

func _setting_action_button(title: String, on_press: Callable) -> Control:
	var btn := UiKit.ghost_button(title, UiKit.TEXT)
	btn.custom_minimum_size = Vector2(0, 48)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 13)
	btn.clip_text = true
	btn.pressed.connect(func() -> void:
		Audio.tap()
		on_press.call())
	return btn


## Kuylar nomi — tanlov chiplari uchun.
func _track_names() -> PackedStringArray:
	var names := PackedStringArray()
	for track: Dictionary in Audio.TRACKS:
		names.append(Strings.t(track["key"]))
	return names

func _track_index() -> int:
	for i in Audio.TRACKS.size():
		if Audio.TRACKS[i]["id"] == store.music_track:
			return i
	return 0

func _header(title: String, on_back: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var back := UiKit.icon_button("←")
	back.pressed.connect(func() -> void:
		Audio.tap()
		on_back.call())
	row.add_child(back)
	var label := UiKit.title(title, 24, UiKit.TEXT,
		HORIZONTAL_ALIGNMENT_LEFT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row

# ——— Profil ———

func _build_profile() -> Control:
	var root := UiKit.overlay(true)
	var box := UiKit.centered_column(root, 440)

	var modal := UiKit.panel(UiKit.PANEL, 20)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	modal.add_child(inner)

	# Sarlavha
	inner.add_child(UiKit.title(Strings.t("profile").to_upper(), 26, UiKit.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER))

	# 1. "O'yin natijalarini saqlash" kartasi (ID va Google kirish)
	var save_card := UiKit.panel(UiKit.SURFACE, 14)
	var save_box := VBoxContainer.new()
	save_box.add_theme_constant_override("separation", 8)
	save_card.add_child(save_box)

	var save_head := HBoxContainer.new()
	save_head.add_theme_constant_override("separation", 8)
	save_head.add_child(GameIcon.new("person", 26.0, UiKit.BLUE))
	var save_title := UiKit.title(Strings.t("saveProgress"), 18, UiKit.INK)
	save_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_head.add_child(save_title)
	save_box.add_child(save_head)

	var id_lbl := UiKit.label("ID: %s" % store.player_id, 14, UiKit.INK.lightened(0.25), HORIZONTAL_ALIGNMENT_LEFT)
	save_box.add_child(id_lbl)

	var google_btn := UiKit.button(Strings.t("googleLogin"), UiKit.TEXT)
	google_btn.add_theme_color_override("font_color", UiKit.INK)
	google_btn.pressed.connect(func() -> void:
		Audio.tap()
		toast(Strings.t("googleLoginHint")))
	save_box.add_child(google_btn)
	inner.add_child(save_card)

	# Nik va avatar tahrirlash qatori
	var edit_card := UiKit.panel(UiKit.SURFACE, 12)
	var edit_row := HBoxContainer.new()
	edit_row.add_theme_constant_override("separation", 10)
	edit_card.add_child(edit_row)

	var av_frame := UiKit.panel(UiKit.PANEL, 6)
	av_frame.add_child(AvatarView.new(store.avatar, 44.0, store.avatar_image))
	edit_row.add_child(av_frame)

	_nickname_edit = LineEdit.new()
	_nickname_edit.text = store.nickname
	_nickname_edit.placeholder_text = Strings.t("nicknameHint")
	_nickname_edit.max_length = Profile.MAX_NICKNAME
	_nickname_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nickname_edit.add_theme_font_size_override("font_size", 18)
	_nickname_edit.add_theme_stylebox_override("normal",
		UiKit.style(UiKit.SURFACE.lightened(0.4), 10, 2, 8))
	_nickname_edit.add_theme_stylebox_override("focus",
		UiKit.style(UiKit.SURFACE.lightened(0.4), 10, 2, 8))
	_nickname_edit.text_changed.connect(func(text: String) -> void:
		store.nickname = Profile.sanitize(text, Strings.t("you")))
	edit_row.add_child(_nickname_edit)
	inner.add_child(edit_card)

	# 2. "Statistika" bo'limi (2x2 panjara)
	inner.add_child(UiKit.section(Strings.t("statistics")))

	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 10)
	stats_grid.add_theme_constant_override("v_separation", 10)

	# 1) Liga
	stats_grid.add_child(_stat_modal_tile("medal",
		Strings.t(store.league_name()), Strings.t("league"), UiKit.GOLD))
	# 2) Yo'q qilishlar
	stats_grid.add_child(_stat_modal_tile("skull",
		str(store.total_kills), Strings.t("eliminations"), UiKit.CORAL))
	# 3) Mamlakatlar
	stats_grid.add_child(_stat_modal_tile("flag",
		str(store.total_countries_won), Strings.t("countries"), UiKit.MINT))
	# 4) 100% G'alabalar
	stats_grid.add_child(_stat_modal_tile("star",
		str(store.total_perfect_wins), Strings.t("perfectWins"), UiKit.YELLOW))

	inner.add_child(stats_grid)

	# Yopish tugmasi
	var close_btn := UiKit.button(Strings.t("close"), UiKit.YELLOW)
	close_btn.pressed.connect(func() -> void:
		Audio.tap()
		_save_nickname()
		show_screen(Screen.MENU))
	inner.add_child(close_btn)

	box.add_child(modal)
	return root

func _stat_modal_tile(icon: String, value: String, label: String, tint: Color) -> Control:
	var tile := UiKit.panel(UiKit.SURFACE, 12)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	tile.add_child(vbox)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	top.add_child(GameIcon.new(icon, 24.0, tint))
	var val_lbl := UiKit.title(value, 20, UiKit.INK)
	val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val_lbl.clip_text = true
	top.add_child(val_lbl)
	vbox.add_child(top)

	var sub := UiKit.label(label, 12, UiKit.INK.lightened(0.25), HORIZONTAL_ALIGNMENT_LEFT)
	sub.clip_text = true
	vbox.add_child(sub)
	return tile

# ——— Reklamasiz oynasi (15-skrinshot) ———

func _build_no_ads() -> Control:
	var root := UiKit.overlay(true)
	var box := UiKit.centered_column(root, 440)

	var modal := UiKit.panel(UiKit.PANEL, 20)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 14)
	modal.add_child(inner)

	# Sarlavha
	inner.add_child(UiKit.title(Strings.t("removeAdsQuestion"), 24, UiKit.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER))

	# Markazdagi katta noads nishoni
	var icon_box := CenterContainer.new()
	icon_box.custom_minimum_size = Vector2(0, 90)
	var sentry_badge := UiKit.panel(UiKit.SURFACE, 30)
	sentry_badge.custom_minimum_size = Vector2(88, 88)
	sentry_badge.add_child(GameIcon.new("noads", 64.0, UiKit.YELLOW))
	icon_box.add_child(sentry_badge)
	inner.add_child(icon_box)

	# 2 ta bandli ma'lumot kartasi
	var info_card := UiKit.panel(UiKit.SURFACE, 14)
	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 10)
	info_card.add_child(info_box)

	# 1-band
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	row1.add_child(GameIcon.new("check", 22.0, UiKit.MINT))
	var lbl1 := UiKit.label(Strings.t("removeAdsBullet1"), 13, UiKit.INK,
		HORIZONTAL_ALIGNMENT_LEFT, true)
	lbl1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(lbl1)
	info_box.add_child(row1)

	# 2-band
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	row2.add_child(GameIcon.new("check", 22.0, UiKit.MINT))
	var lbl2 := UiKit.label(Strings.t("removeAdsBullet2"), 13, UiKit.INK,
		HORIZONTAL_ALIGNMENT_LEFT, true)
	lbl2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(lbl2)
	info_box.add_child(row2)

	inner.add_child(info_card)

	# Sotib olish tugmalari (1 kunlik va umrbod)
	var buy_row := HBoxContainer.new()
	buy_row.add_theme_constant_override("separation", 10)

	var btn_1d := UiKit.button("%s\n(500 🪙)" % Strings.t("oneDay"), UiKit.GREEN)
	btn_1d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_1d.pressed.connect(func() -> void:
		Audio.tap()
		if Wallet.spend_coins(500, "noads_1d"):
			Purchases.set_no_ads(true)
			toast(Strings.t("purchaseSuccess"))
			show_screen(Screen.MENU)
		else:
			toast(Strings.t("purchaseFailed")))
	buy_row.add_child(btn_1d)

	var btn_forever := UiKit.button("%s\n($4.99)" % Strings.t("forever"), UiKit.YELLOW)
	btn_forever.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_forever.pressed.connect(func() -> void:
		Audio.tap()
		Purchases.set_no_ads(true)
		toast(Strings.t("purchaseSuccess"))
		show_screen(Screen.MENU))
	buy_row.add_child(btn_forever)

	inner.add_child(buy_row)

	# Yopish tugmasi
	var close_btn := UiKit.button(Strings.t("close"), UiKit.SURFACE)
	close_btn.add_theme_color_override("font_color", UiKit.INK)
	close_btn.pressed.connect(func() -> void:
		Audio.tap()
		show_screen(Screen.MENU))
	inner.add_child(close_btn)

	box.add_child(modal)
	return root


## "Rasm yuklash" qatori: o'yinchi o'z rasmini qo'yishi mumkin.
func _photo_row(current: String, dest: String,
		on_set: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var upload := UiKit.ghost_button(
		Strings.t("uploadPhoto"), _accent())
	upload.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upload.pressed.connect(func() -> void:
		Audio.tap()
		_save_nickname()
		ImagePicker.open(self, dest, Strings.t("uploadPhoto"),
			func(path: String) -> void:
				if path.is_empty():
					toast(Strings.t("photoFailed"))
					return
				on_set.call(path)
				settings_changed.emit()
				_rebuild()
				toast(Strings.t("photoAdded"))))
	row.add_child(upload)

	if not current.is_empty():
		var clear := UiKit.ghost_button("✕", UiKit.CORAL)
		clear.custom_minimum_size = Vector2(60, 56)
		clear.pressed.connect(func() -> void:
			Audio.tap()
			ImagePicker.remove(current)
			on_set.call("")
			settings_changed.emit()
			_rebuild())
		row.add_child(clear)
	return row

func _save_nickname() -> void:
	if _nickname_edit != null and is_instance_valid(_nickname_edit):
		store.nickname = Profile.sanitize(
			_nickname_edit.text, Strings.t("you"))

func _pick_avatar(value: String) -> void:
	Audio.tap()
	_save_nickname()
	store.avatar = value
	_rebuild()

func _pick_country(code: String) -> void:
	Audio.tap()
	_save_nickname()
	store.country = code
	settings_changed.emit()
	_rebuild()

func _country() -> String:
	var saved := store.country
	return saved if not saved.is_empty() else Profile.detect_country()

func _grid(columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	return grid

func _emoji_grid() -> Control:
	var grid := _grid(6)
	for e: String in Profile.EMOJIS:
		var value := Profile.encode(Profile.Kind.EMOJI, e)
		grid.add_child(AvatarView.chip(value, store.avatar == value,
			func() -> void: _pick_avatar(value), "", _accent()))
	return grid

func _figure_grid() -> Control:
	var grid := _grid(6)
	for i in Profile.FIGURE_COUNT:
		var value := Profile.encode(Profile.Kind.FIGURE, str(i))
		grid.add_child(AvatarView.chip(value, store.avatar == value,
			func() -> void: _pick_avatar(value), "", _accent()))
	return grid

func _flag_grid() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	var search := LineEdit.new()
	search.text = _flag_query
	search.placeholder_text = Strings.t("searchCountry")
	search.add_theme_font_size_override("font_size", 17)
	search.add_theme_stylebox_override("normal",
		UiKit.style(UiKit.SURFACE, 12, 2, 10))
	search.add_theme_stylebox_override("focus",
		UiKit.style(UiKit.SURFACE, 12, 2, 10))
	search.text_changed.connect(func(text: String) -> void:
		_flag_query = text
		_rebuild())
	box.add_child(search)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	var grid := _grid(5)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	# 249 bayroqni birdan qurish sekin — ro'yxat qisqartiriladi.
	var chosen := _country()
	var list := Profile.search_countries(_flag_query)
	for i in list.size():
		var c: Dictionary = list[i]
		var code := str(c["code"])
		var value := Profile.encode(Profile.Kind.FLAG, code)
		grid.add_child(AvatarView.chip(value, chosen == code,
			func() -> void: _pick_country(code), str(c["name"]), _accent()))
	return box

# ——— HUD ———

func _build_hud() -> Control:
	var root := UiKit.overlay(false)

	# Chaqnash panellardan oldin qo'shiladi — matn ustini bosmasin.
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1.0, 1.0, 1.0, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash)

	# Yuqorida chapda: Dumaloq hudud ko'rsatkichi (Donut Chart)
	_donut = UiKit.donut_chart(0.0, _accent())
	_donut.position = Vector2(16, 14)
	root.add_child(_donut)
	_progress = _donut

	# Yuqorida markazda: Haqiqiy yig'ilgan tangalar hisoblagichi (Hamyon va joriy o'yindagi daromad)
	_coin_capsule = UiKit.capsule("coin", "0", UiKit.YELLOW, 90)
	_coin_capsule.anchor_left = 0.5
	_coin_capsule.anchor_right = 0.5
	_coin_capsule.offset_left = -95
	_coin_capsule.offset_right = 95
	_coin_capsule.offset_top = 16
	root.add_child(_coin_capsule)
	_coin_label = _capsule_label(_coin_capsule)

	# O'ldirishlar kapsulasi — Donut ostida
	_kill_capsule = UiKit.capsule("skull", "0", UiKit.TEXT, 46)
	_kill_capsule.position = Vector2(16, 172)
	root.add_child(_kill_capsule)
	_kill_label = _capsule_label(_kill_capsule)

	# Shaharlar kapsulasi (Phase 5) — O'ldirishlar ostida
	_city_capsule = UiKit.capsule("flag", "0 / 0", Color("38bdf8"), 84)
	_city_capsule.position = Vector2(16, 226)
	root.add_child(_city_capsule)
	_city_label = _capsule_label(_city_capsule)

	# O'ngda yuqorida: Pauza tugmasi
	var pause := UiKit.icon_button("\u275A\u275A", 72)
	pause.anchor_left = 1.0
	pause.anchor_right = 1.0
	pause.position = Vector2(-88, 14)
	pause.pressed.connect(func() -> void:
		Audio.tap()
		pause_pressed.emit())
	root.add_child(pause)

	# O'ngda: eng kuchli o'yinchilar reytingi (bitta silliq panel ichida)
	var board_panel := PanelContainer.new()
	var b_style := StyleBoxFlat.new()
	b_style.bg_color = Color(0.08, 0.16, 0.35, 0.88)
	b_style.border_color = Color("00d4ff")
	b_style.set_border_width_all(2)
	b_style.set_corner_radius_all(14)
	b_style.content_margin_left = 10
	b_style.content_margin_right = 10
	b_style.content_margin_top = 8
	b_style.content_margin_bottom = 8
	board_panel.add_theme_stylebox_override("panel", b_style)
	board_panel.anchor_left = 1.0
	board_panel.anchor_right = 1.0
	board_panel.offset_left = -262
	board_panel.offset_right = -14
	board_panel.offset_top = 80
	board_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board = VBoxContainer.new()
	_board.add_theme_constant_override("separation", 3)
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_panel.add_child(_board)
	root.add_child(board_panel)

	# Pastda chapda: Vizual joystick ko'rsatkichi (yo'nalish strelkalari bilan)
	var joy := Control.new()
	joy.anchor_top = 1.0
	joy.anchor_bottom = 1.0
	joy.offset_left = 24
	joy.offset_top = -160
	joy.offset_right = 154
	joy.offset_bottom = -30
	joy.custom_minimum_size = Vector2(130, 130)
	joy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var joy_base := Panel.new()
	joy_base.set_anchors_preset(Control.PRESET_FULL_RECT)
	var jb := StyleBoxFlat.new()
	jb.bg_color = Color(0.08, 0.16, 0.35, 0.50)
	jb.border_color = Color(1.0, 1.0, 1.0, 0.40)
	jb.set_border_width_all(3)
	jb.set_corner_radius_all(65)
	joy_base.add_theme_stylebox_override("panel", jb)
	joy_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy.add_child(joy_base)

	var arrow_dirs := [
		["▲", Vector2(0.5, 0.15)], ["▼", Vector2(0.5, 0.85)],
		["◀", Vector2(0.15, 0.5)], ["▶", Vector2(0.85, 0.5)]
	]
	for ad: Array in arrow_dirs:
		var arr := Label.new()
		arr.text = str(ad[0])
		arr.add_theme_font_size_override("font_size", 13)
		arr.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
		arr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		arr.size = Vector2(20, 20)
		arr.position = Vector2(float(ad[1].x) * 130 - 10, float(ad[1].y) * 130 - 10)
		joy.add_child(arr)

	var joy_knob := Panel.new()
	joy_knob.custom_minimum_size = Vector2(50, 50)
	joy_knob.set_anchors_preset(Control.PRESET_CENTER)
	var jk := StyleBoxFlat.new()
	jk.bg_color = Color(0.15, 0.60, 1.0, 0.70)
	jk.border_color = Color(1.0, 1.0, 1.0, 0.85)
	jk.set_border_width_all(2)
	jk.set_corner_radius_all(25)
	joy_knob.add_theme_stylebox_override("panel", jk)
	joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy.add_child(joy_knob)
	root.add_child(joy)

	# Pastda o'ngda: Aylanma radar mini-xarita
	_minimap = MiniMap.new(_minimap_texture, _accent())
	var map_panel := Control.new()
	map_panel.anchor_left = 1.0
	map_panel.anchor_right = 1.0
	map_panel.anchor_top = 1.0
	map_panel.anchor_bottom = 1.0
	map_panel.offset_left = -168
	map_panel.offset_top = -168
	map_panel.offset_right = -16
	map_panel.offset_bottom = -16
	map_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_panel.add_child(_minimap)

	var fs_icon := Label.new()
	fs_icon.text = "⛶"
	fs_icon.add_theme_font_size_override("font_size", 18)
	fs_icon.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	fs_icon.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	fs_icon.offset_left = -26
	fs_icon.offset_top = -26
	map_panel.add_child(fs_icon)
	root.add_child(map_panel)
	return root

## Kapsuladagi son yozuvini topadi — keyin uni yangilab turamiz.
static func _capsule_label(shell: PanelContainer) -> Label:
	var row := shell.get_child(0) as HBoxContainer
	return row.get_child(1) as Label

## Kichik xarita uchun egalik teksturasini beradi (arena qurilgandan
## keyin bir marta chaqiriladi).
func set_minimap(texture: Texture2D) -> void:
	_minimap_texture = texture
	if _minimap != null and is_instance_valid(_minimap):
		_minimap.map_texture = texture

## Hudud olinganda va o'limda qisqa chaqnash.
func flash(color: Color, strength: float = 0.26) -> void:
	if _flash == null or not is_instance_valid(_flash):
		return
	_flash.color = Color(color.r, color.g, color.b, strength)
	var tween := create_tween()
	tween.tween_property(_flash, "color:a", 0.0, 0.32)

## Qisqa xabar — ekranning pastida o'zi yo'qoladi.
func toast(text: String) -> void:
	if _root == null or not is_instance_valid(_root):
		return
	var panel := UiKit.panel(Color(UiKit.SURFACE, 0.96), 12)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.position = Vector2(0, -28)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(UiKit.label(text, 17))
	_root.add_child(panel)
	var tween := create_tween()
	tween.tween_interval(1.4)
	tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(panel.queue_free)

## HUD ni yangilaydi. `rows` — [{place, name, avatar, color,
## percent, is_human, country}].
func update_hud(percent: float, kills: int, elapsed: float, rank: int,
		alive: int, rows: Array, marker: Vector2 = Vector2.ZERO,
		coins: int = 0, bots: Array = [], earned_coins: int = 0) -> void:
	if _screen != Screen.HUD or _progress == null:
		return
	if _donut != null and is_instance_valid(_donut):
		_donut.percent = percent
	if _progress_fill != null and is_instance_valid(_progress_fill):
		_progress_fill.anchor_right = clampf(percent / 100.0, 0.02, 1.0)
	if _progress_text != null and is_instance_valid(_progress_text):
		_progress_text.text = "%d%%" % int(round(percent))
	if _kill_label != null and is_instance_valid(_kill_label):
		_kill_label.text = str(kills)
	if _coin_label != null and is_instance_valid(_coin_label):
		if earned_coins > 0:
			_coin_label.text = "%s (+%s)" % [_short(coins), _short(earned_coins)]
		else:
			_coin_label.text = _short(coins)
	if _minimap != null and is_instance_valid(_minimap):
		_minimap.marker = marker
		_minimap.bot_markers = bots

	for child in _board.get_children():
		child.queue_free()
	for row: Dictionary in rows:
		_board.add_child(_board_row(row))

## HUD shahar hisoblagichini yangilaydi (Phase 5).
func update_hud_cities(captured: int, total: int) -> void:
	if _city_label != null and is_instance_valid(_city_label):
		_city_label.text = "%d / %d" % [captured, total]

## Shahar ma'lumotlari oynasi (Phase 5-6 City Info Modal).
func show_city_info_modal(city: CitySystem.CityData, coin_available: bool = true, already_claimed: bool = false, is_owned: bool = false) -> void:
	if city == null:
		return
	if _city_modal != null and is_instance_valid(_city_modal):
		_city_modal.queue_free()

	var modal := UiKit.overlay(true)
	_city_modal = modal

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(400, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.12, 0.28, 0.96)
	sb.border_color = Color("00d4ff")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(20)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	card.add_theme_stylebox_override("panel", sb)
	center.add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)

	# 1. Toifa belgisi (Badge)
	var badge_col := Color("fbbf24") if city.category == CitySystem.Category.LARGE else (Color("38bdf8") if city.category == CitySystem.Category.MEDIUM else Color("84cc16"))
	var badge := UiKit.label(city.category_badge(), 13, badge_col, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(badge)

	# 2. Shahar nomi (Katta sarlavha)
	var title_lbl := UiKit.title(city.display_name, 30, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(title_lbl)

	# 3. Davlat va Bayroq
	var flag_row := HBoxContainer.new()
	flag_row.alignment = BoxContainer.ALIGNMENT_CENTER
	flag_row.add_theme_constant_override("separation", 10)
	var flag_tex := FlagRenderer.get_flag_texture(city.country_code)
	if flag_tex != null:
		var f_rect := TextureRect.new()
		f_rect.texture = flag_tex
		f_rect.custom_minimum_size = Vector2(40, 26)
		f_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		f_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flag_row.add_child(f_rect)
	var c_name := UiKit.label("%s (%s)" % [city.country_name, city.country_code], 17, Color("cbd5e1"))
	flag_row.add_child(c_name)
	col.add_child(flag_row)

	# Chiziq
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = Color(1, 1, 1, 0.15)
	col.add_child(sep)

	# 4. Aholi soni
	var pop_str: String = ""
	if city.pop >= 1000000:
		pop_str = "%.1f mln aholi" % (float(city.pop) / 1000000.0)
	elif city.pop >= 1000:
		pop_str = "%d ming aholi" % (city.pop / 1000)
	else:
		pop_str = "%d aholi" % city.pop
	var pop_lbl := UiKit.label("Aholi soni: " + pop_str, 15, Color("94a3b8"), HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(pop_lbl)

	# 5. Egallash holati (Conquest status)
	var status_text := ""
	var status_col := Color("94a3b8")
	if city.is_captured():
		status_text = "Hozirgi ega: %s (%s)" % [city.owner_name, city.owner_country]
		status_col = Color("4ade80")
	else:
		status_text = "Hozirgi ega: Neytral shahar"
		status_col = Color("f1f5f9")
	var status_lbl := UiKit.label(status_text, 15, status_col, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(status_lbl)

	# 6. Istilo mukofoti (Conquest Reward - Phase 6)
	var conquest_reward: int = MonetizationConfig.get_city_capture_reward(city.category)
	var rew_text := "Istilo mukofoti: %d Tanga (Coins)" % conquest_reward
	var rew_lbl := UiKit.label(rew_text, 17, Color("facc15"), HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(rew_lbl)

	# 7. Mukofot holati (Reward Eligibility Status - Phase 6)
	var elig_text := ""
	var elig_col := Color("4ade80")
	if is_owned:
		elig_text = "Holat: Sizga tegishli ✓"
		elig_col = Color("38bdf8")
	elif already_claimed:
		elig_text = "Holat: Bu o'yinda allaqachon olingan (0 🪙)"
		elig_col = Color("f97316")
	else:
		elig_text = "Holat: Mukofot mavjud (+%d 🪙)" % conquest_reward
		elig_col = Color("4ade80")
	var elig_lbl := UiKit.label(elig_text, 15, elig_col, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(elig_lbl)

	# 8. Yopish tugmasi
	var close_btn := UiKit.button("TUSHUNARLI", UiKit.GREEN)
	close_btn.pressed.connect(func() -> void:
		Audio.tap()
		modal.queue_free())
	col.add_child(close_btn)

	add_child(modal)

## Reyting qatori: o'rin, bayroq/avatar, ism va foiz.
func _board_row(row: Dictionary) -> Control:
	var place := int(row["place"])
	var tint := Palette.head(int(row["color"]))
	var country_code := str(row.get("country", ""))
	var is_human := bool(row.get("is_human", false))

	var card := PanelContainer.new()
	var card_bg := Color(0.04, 0.10, 0.25, 0.65) if not is_human else Color(0.10, 0.45, 0.90, 0.70)
	var sb := StyleBoxFlat.new()
	sb.bg_color = card_bg
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 6
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(236, 26)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 6)
	line.alignment = BoxContainer.ALIGNMENT_BEGIN
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(line)

	# O'rin nishoni
	var rank_box := Control.new()
	rank_box.custom_minimum_size = Vector2(20, 20)
	rank_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rank_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if place == 1:
		var crown := GameIcon.new("crown", 18.0, UiKit.YELLOW)
		crown.set_anchors_preset(Control.PRESET_FULL_RECT)
		rank_box.add_child(crown)
	else:
		var rank_lbl := UiKit.title(str(place), 13, UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
		rank_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		rank_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rank_lbl.add_theme_constant_override("outline_size", 0)
		rank_box.add_child(rank_lbl)
	line.add_child(rank_box)

	# Rang doirachasi
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(10, 10)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var dsb := StyleBoxFlat.new()
	dsb.bg_color = tint
	dsb.set_corner_radius_all(5)
	dot.add_theme_stylebox_override("panel", dsb)
	line.add_child(dot)

	# Bayroq
	if not country_code.is_empty():
		var flag_icon := Control.new()
		flag_icon.custom_minimum_size = Vector2(22, 16)
		flag_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		flag_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var av := AvatarView.new("flag:" + country_code, 18.0)
		av.set_anchors_preset(Control.PRESET_FULL_RECT)
		flag_icon.add_child(av)
		line.add_child(flag_icon)

	# Ism
	var name_lbl := UiKit.label(str(row["name"]), 13, UiKit.YELLOW if is_human else UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	name_lbl.clip_text = true
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name_lbl)

	# Foiz
	var pct_lbl := UiKit.title("%.1f%%" % float(row["percent"]), 13, Color.WHITE if is_human else UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	pct_lbl.add_theme_constant_override("outline_size", 2)
	line.add_child(pct_lbl)

	return card

# ——— Pauza ———

func _build_pause() -> Control:
	var root := UiKit.overlay()
	var box := UiKit.centered_column(root, 400)
	var panel := UiKit.panel()
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	panel.add_child(inner)
	inner.add_child(UiKit.title(Strings.t("pause"), 28, UiKit.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER))

	# Ovoz sozlamalari — o'yindan chiqmasdan.
	inner.add_child(UiKit.switch_row(Strings.t("music"), store.music_enabled,
		func(value: bool) -> void:
			store.music_enabled = value
			Audio.set_music_enabled(value)
			_rebuild(), _accent()))
	inner.add_child(UiKit.slider_row(Strings.t("musicVolume"),
		store.music_volume, func(value: int) -> void:
			store.music_volume = value
			Audio.set_music_volume(value), _accent()))
	inner.add_child(UiKit.switch_row(Strings.t("sound"), store.sound_enabled,
		func(value: bool) -> void:
			store.sound_enabled = value
			Audio.sound_enabled = value
			Audio.tap()
			_rebuild(), _accent()))
	inner.add_child(UiKit.slider_row(Strings.t("soundVolume"),
		store.sound_volume, func(value: int) -> void:
			store.sound_volume = value
			Audio.set_sound_volume(value)
			Audio.tap(), _accent()))
	inner.add_child(UiKit.switch_row(Strings.t("vibration"),
		store.vibration_enabled, func(value: bool) -> void:
			store.vibration_enabled = value
			Audio.vibration_enabled = value
			Audio.tap()
			_rebuild(), _accent()))

	var resume := UiKit.button(Strings.t("resume"), _accent())
	resume.pressed.connect(func() -> void:
		Audio.tap()
		resume_pressed.emit())
	inner.add_child(resume)
	var to_menu := UiKit.ghost_button(Strings.t("menu"))
	to_menu.pressed.connect(func() -> void:
		Audio.tap()
		menu_pressed.emit())
	inner.add_child(to_menu)
	box.add_child(panel)
	return root

# ——— Natija ———

func set_result(percent: float, kills: int, elapsed: float, reason: String,
		is_record: bool, reward: Dictionary = {},
		journey: Dictionary = {}, city_conquest: Dictionary = {}) -> void:
	_result_data = {
		"percent": percent, "kills": kills, "elapsed": elapsed,
		"reason": reason, "record": is_record, "reward": reward,
		"journey": journey, "city_conquest": city_conquest,
	}

func _build_result() -> Control:
	var root := UiKit.overlay()
	var box := UiKit.centered_column(root, 420)
	var panel := UiKit.panel()
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	panel.add_child(inner)

	var percent := float(_result_data.get("percent", 0.0))
	var is_record := bool(_result_data.get("record", false))

	# Rekord bo'lsa sarlavha o'rniga lenta chiqadi: natijaning eng
	# muhim gapi birinchi ko'rinadi.
	if is_record:
		inner.add_child(_record_ribbon())
	else:
		inner.add_child(UiKit.title(Strings.t("gameOver"), 28, UiKit.TEXT,
			HORIZONTAL_ALIGNMENT_CENTER))
	inner.add_child(UiKit.label(str(_result_data.get("reason", "")), 15,
		UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, true))

	# Egallangan maydon — eng katta son, ustida o'sadigan chiziq.
	# Chiziqdagi sariq uchburchak — shu kungacha eng yaxshi natija.
	var best: float = maxf(store.best_percent, percent)
	# Chiziq sariq: o'yinchi rangi ko'k fonda deyarli ko'rinmasdi.
	var bar := UiKit.progress_bar(0.0, UiKit.YELLOW,
		best if best > 0.0 else -1.0)
	inner.add_child(bar)
	inner.add_child(UiKit.label(
		Strings.t("bestPercent") % store.best_percent, 12,
		UiKit.TEXT_FAINT, HORIZONTAL_ALIGNMENT_CENTER))
	_animate_bar(bar, percent)

	var conquest: Dictionary = _result_data.get("city_conquest", {})
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 8)
	tiles.add_child(_result_tile("skull",
		str(_result_data.get("kills", 0)), Strings.t("kills"), UiKit.RED))
	tiles.add_child(_result_tile("coin",
		str(int(_reward_total())), Strings.t("coinsFound"), UiKit.YELLOW))
	tiles.add_child(_result_tile("flag",
		"%d/%d" % [int(conquest.get("cities_owned", 0)), int(conquest.get("total_cities", 0))], "Shaharlar", UiKit.MINT))
	tiles.add_child(_result_tile("clock",
		_clock(float(_result_data.get("elapsed", 0.0))),
		Strings.t("time"), UiKit.BG_LOW))
	inner.add_child(tiles)

	# Tanga qayerdan kelgani ochiq yozilgan.
	var reward: Dictionary = _result_data.get("reward", {})
	if not reward.is_empty() or not conquest.is_empty():
		inner.add_child(_coin_card(reward))

	# Mamlakatlar yo'li: shakl eski darajadan yangisiga to'ladi.
	var journey: Dictionary = _result_data.get("journey", {})
	if not journey.is_empty():
		inner.add_child(_journey_result(journey))

	# Davom etishning ikki yo'li: belet yoki mukofotli reklama.
	if store.tickets > 0:
		var ticket := UiKit.button(
			"%s (%d)" % [Strings.t("withTicket"), store.tickets], UiKit.MINT)
		ticket.pressed.connect(func() -> void:
			Audio.tap()
			continue_with_ticket.emit())
		inner.add_child(ticket)
	var ad := UiKit.ghost_button(Strings.t("watchAd"), UiKit.GOLD)
	ad.pressed.connect(func() -> void:
		Audio.tap()
		_watch_ad(true))
	inner.add_child(ad)

	var shop := UiKit.ghost_button(Strings.t("buyTickets"), UiKit.TEXT_DIM)
	shop.pressed.connect(func() -> void:
		Audio.tap()
		open_shop(Screen.RESULT))
	inner.add_child(shop)

	var again := UiKit.button(Strings.t("playAgain"), _accent())
	again.pressed.connect(func() -> void:
		Audio.tap()
		play_pressed.emit())
	inner.add_child(again)
	var to_menu := UiKit.ghost_button(Strings.t("menu"))
	to_menu.pressed.connect(func() -> void:
		Audio.tap()
		menu_pressed.emit())
	inner.add_child(to_menu)
	box.add_child(panel)
	return root

## Natija ekranidagi tanga kartasi (Phase 6 to'liq iqtisodiy tahlil).
func _coin_card(reward: Dictionary) -> Control:
	var card := UiKit.panel(Color(UiKit.SURFACE, 0.8), 13)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)

	var conquest: Dictionary = _result_data.get("city_conquest", {})
	var conquest_total: int = int(conquest.get("total", 0))
	var grand_total: int = mini(int(reward.get("total", 0)) + conquest_total, MonetizationConfig.MAX_BALANCE)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var name_label := UiKit.label(Strings.t("coinsEarned"), 14,
		UiKit.INK, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	head.add_child(UiKit.title("+%d" % grand_total, 22,
		UiKit.GOLD, HORIZONTAL_ALIGNMENT_RIGHT))
	box.add_child(head)

	# Shaharlar istilosi hisoboti (Phase 6 - dinamik MonetizationConfig qiymatlari)
	var s_reward: int = MonetizationConfig.get_city_capture_reward(CitySystem.Category.SMALL)
	var m_reward: int = MonetizationConfig.get_city_capture_reward(CitySystem.Category.MEDIUM)
	var l_reward: int = MonetizationConfig.get_city_capture_reward(CitySystem.Category.LARGE)

	var s_cnt := int(conquest.get("small_count", 0))
	var m_cnt := int(conquest.get("medium_count", 0))
	var l_cnt := int(conquest.get("large_count", 0))

	var s_coins := int(conquest.get("small_coins", s_cnt * s_reward))
	var m_coins := int(conquest.get("medium_coins", m_cnt * m_reward))
	var l_coins := int(conquest.get("large_coins", l_cnt * l_reward))

	if conquest_total > 0 or s_cnt > 0 or m_cnt > 0 or l_cnt > 0:
		var c_hdr := UiKit.label("Shahar istilolari (Conquest)", 12, Color("0284c7"), HORIZONTAL_ALIGNMENT_LEFT)
		box.add_child(c_hdr)

		if s_cnt > 0:
			var s_row := HBoxContainer.new()
			var s_title := UiKit.label("  ● Kichik: %d × %d" % [s_cnt, s_reward], 12, Color(UiKit.INK, 0.75), HORIZONTAL_ALIGNMENT_LEFT)
			s_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			s_row.add_child(s_title)
			s_row.add_child(UiKit.label("+%d" % s_coins, 12, UiKit.INK))
			box.add_child(s_row)

		if m_cnt > 0:
			var m_row := HBoxContainer.new()
			var m_title := UiKit.label("  ◆ O'rta: %d × %d" % [m_cnt, m_reward], 12, Color(UiKit.INK, 0.75), HORIZONTAL_ALIGNMENT_LEFT)
			m_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			m_row.add_child(m_title)
			m_row.add_child(UiKit.label("+%d" % m_coins, 12, UiKit.INK))
			box.add_child(m_row)

		if l_cnt > 0:
			var l_row := HBoxContainer.new()
			var l_title := UiKit.label("  ★ Katta: %d × %d" % [l_cnt, l_reward], 12, Color(UiKit.INK, 0.75), HORIZONTAL_ALIGNMENT_LEFT)
			l_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l_row.add_child(l_title)
			l_row.add_child(UiKit.label("+%d" % l_coins, 12, UiKit.INK))
			box.add_child(l_row)

		var c_tot_row := HBoxContainer.new()
		var c_tot_title := UiKit.label("  Jami istilo mukofoti:", 12, Color("0284c7"), HORIZONTAL_ALIGNMENT_LEFT)
		c_tot_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c_tot_row.add_child(c_tot_title)
		c_tot_row.add_child(UiKit.label("+%d 🪙" % conquest_total, 12, Color("0284c7")))
		box.add_child(c_tot_row)

	var parts: Array = [
		[Strings.t("time"), int(reward.get("run", 0))],
		[Strings.t("territory"), int(reward.get("territory", 0))],
		[Strings.t("kills"), int(reward.get("kills", 0))],
		[Strings.t("coinsPicked"), int(reward.get("pickups", 0))],
		[Strings.t("bonusRow"), int(reward.get("passive", 0))],
	]
	for part: Array in parts:
		if int(part[1]) <= 0:
			continue
		var row := HBoxContainer.new()
		var faint := Color(UiKit.INK, 0.7)
		var title := UiKit.label(str(part[0]), 12, faint,
			HORIZONTAL_ALIGNMENT_LEFT)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(title)
		row.add_child(UiKit.label("+%d" % int(part[1]), 12, UiKit.INK))
		box.add_child(row)
	return card

## Natija tangasining umumiy soni.
func _reward_total() -> int:
	var reward: Dictionary = _result_data.get("reward", {})
	var conquest: Dictionary = _result_data.get("city_conquest", {})
	return int(reward.get("total", 0)) + int(conquest.get("total", 0))

## "YANGI REKORD" lentasi — yashil fonda yulduz bilan.
func _record_ribbon() -> Control:
	var shell := PanelContainer.new()
	shell.add_theme_stylebox_override("panel",
		UiKit.style_solid(UiKit.GREEN, 16))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.add_child(GameIcon.new("star", 26.0, UiKit.YELLOW))
	row.add_child(UiKit.title(Strings.t("newRecord"), 24, UiKit.TEXT))
	row.add_child(GameIcon.new("star", 26.0, UiKit.YELLOW))
	shell.add_child(row)
	return shell

## Natijadagi bitta katak: belgi, katta son va tagida nomi.
func _result_tile(icon: String, value: String, title: String,
		tint: Color) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 5)
	head.add_child(GameIcon.new(icon, 22.0, tint))
	head.add_child(UiKit.title(value, 22, UiKit.TEXT))
	box.add_child(head)
	box.add_child(UiKit.label(title, 12, UiKit.TEXT_FAINT))
	return box

## Natijadagi mamlakat qatori: shakli eski darajadan yangisiga
## to'lib boradi, yonida nechta ochko qo'shilgani yoziladi.
func _journey_result(journey: Dictionary) -> Control:
	var card := UiKit.panel(Color(UiKit.SURFACE, 0.8), 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var country: Dictionary = journey.get("country", {})
	var before := float(journey.get("before", 0.0))
	var after := float(journey.get("after", before))
	# Shakl to'q ko'k ramkada: och kartada och kontur yo'qolib
	# ketardi.
	var frame := UiKit.panel(UiKit.PANEL, 5)
	var shape := CountryView.new(country, 58.0, before, UiKit.GREEN)
	frame.add_child(shape)
	row.add_child(frame)

	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var done: Array = journey.get("done", [])
	if done.is_empty():
		text.add_child(UiKit.label(
			Profile.country_name(str(country.get("code", ""))), 16,
			UiKit.INK, HORIZONTAL_ALIGNMENT_LEFT))
	else:
		text.add_child(UiKit.label(Strings.t("countryDone")
			% Profile.country_name(str(done[0])), 16,
			UiKit.GREEN.darkened(0.35), HORIZONTAL_ALIGNMENT_LEFT, true))
	text.add_child(UiKit.label("+%d %s"
		% [int(journey.get("gained", 0)), Strings.t("points")], 13,
		Color(UiKit.INK, 0.7), HORIZONTAL_ALIGNMENT_LEFT))
	row.add_child(text)

	# Mamlakat tugagan bo'lsa chiziq oxirigacha to'ladi, keyin
	# yangi mamlakat noldan boshlanadi — shuning uchun to'lish
	# 100 gacha boradi va o'sha yerda qoladi.
	var target: float = 100.0 if not done.is_empty() else after
	var tween := shape.create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(shape.set_percent, before, target,
		RESULT_FILL_TIME)
	return card

## Maydon chizig'i noldan o'sib boradi va son ham birga sanaladi.
##
## Animatsiya tugmalarni kutib turmaydi: o'yinchi xohlasa darhol
## bosa oladi, chiziq esa orqada to'lib boraveradi.
const RESULT_FILL_TIME := 0.7

func _animate_bar(bar: Control, percent: float) -> void:
	var fill := bar.find_child("Fill", true, false) as Panel
	var text := bar.find_child("Value", true, false) as Label
	if fill == null or text == null:
		return
	# Tween chiziqning o'ziga bog'lanadi: ekran almashganda u ham
	# o'ladi. Ekran tugunida yaratilsa, natija ekrani yopilgandan
	# keyin ham ishlab, bo'shatilgan tugunga murojaat qilardi.
	var tween := fill.create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(
		func(at: float) -> void:
			fill.anchor_right = clampf(at / 100.0, 0.02, 1.0)
			text.text = "%.2f%%" % at,
		0.0, percent, RESULT_FILL_TIME)

# ——— Do'kon ———

## Do'konni ochadi; orqaga tugmasi `from` ekraniga qaytaradi.
func open_shop(from: Screen) -> void:
	_shop_return = from
	show_screen(Screen.SHOP)

func _build_shop() -> Control:
	var root := UiKit.overlay()
	var box := UiKit.centered_column(root, 440)
	box.add_child(_header(Strings.t("shop"), func() -> void:
		show_screen(_shop_return)))

	var purse := HBoxContainer.new()
	purse.add_theme_constant_override("separation", 10)
	purse.alignment = BoxContainer.ALIGNMENT_CENTER
	purse.add_child(_purse_chip("coin", Wallet.get_coins(), UiKit.YELLOW))
	purse.add_child(_purse_chip("gem", Wallet.get_gems(), UiKit.VIOLET))
	purse.add_child(_purse_chip("ticket", store.tickets, UiKit.GREEN))
	box.add_child(purse)

	box.add_child(_daily_card())
	box.add_child(_missions_card())
	box.add_child(_cosmetics_card())
	box.add_child(_tickets_card())
	box.add_child(_no_ads_card())

	var close := UiKit.ghost_button(Strings.t("close"))
	close.pressed.connect(func() -> void:
		Audio.tap()
		show_screen(_shop_return))
	box.add_child(close)
	return root

## Kunlik sovg'a: bugungi kun, miqdor va olish tugmasi.
func _daily_card() -> Control:
	var card := UiKit.panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	box.add_child(UiKit.section(Strings.t("dailyReward")))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(UiKit.title("%s %d" % [Strings.t("streakDay"),
		Daily.next_day()], 20, UiKit.TEXT))
	left.add_child(UiKit.label("\u25C9 %d" % Daily.reward_for_today(), 15,
		UiKit.GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	row.add_child(left)
	box.add_child(row)

	if Daily.claimed_today():
		box.add_child(UiKit.label(Strings.t("comeBackTomorrow"), 13,
			UiKit.TEXT_FAINT, HORIZONTAL_ALIGNMENT_CENTER, true))
		return card
	var take := UiKit.button(Strings.t("claim"), UiKit.LIME)
	take.pressed.connect(func() -> void:
		Audio.tap()
		_claim_daily(false))
	box.add_child(take)
	# Reklama ixtiyoriy: o'yinchi o'zi bosadi.
	var twice := UiKit.ghost_button(Strings.t("doubleReward"), UiKit.GOLD)
	twice.pressed.connect(func() -> void:
		Audio.tap()
		_claim_daily(true))
	box.add_child(twice)
	return card

func _claim_daily(with_ad: bool) -> void:
	if _ad_busy:
		return
	if with_ad:
		_ad_busy = true
		var result: Dictionary = await Ads.show_rewarded(
			AdManager.Reward.DAILY_REWARD_MULTIPLIER)
		_ad_busy = false
		if not bool(result["ok"]):
			toast(Strings.t(str(result["error"])))
			return
	var got: Dictionary = Daily.claim(with_ad)
	if not bool(got["ok"]):
		toast(Strings.t("claimed"))
		return
	_rebuild()
	toast("\u25C9 +%d" % int(got["amount"]))

## Kunlik topshiriqlar: uchta qator, har birida chiziq va mukofot.
func _missions_card() -> Control:
	var card := UiKit.panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	box.add_child(UiKit.section(Strings.t("missions")))
	for mission: Dictionary in Missions.today_missions():
		box.add_child(_mission_row(mission))
	return card

## Topshiriq matni turi va maqsadidan yig'iladi — har bir
## topshiriqqa alohida tarjima kerak emas.
static func _mission_title(mission: Dictionary) -> String:
	var key := "mission" + str(mission["kind"]).capitalize()
	return Strings.t(key) % str(mission["target"])

func _mission_row(mission: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var done: bool = bool(mission["completed"])
	var title := UiKit.label(_mission_title(mission), 14,
		UiKit.TEXT_DIM if done else UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(UiKit.label("\u25C9 %d" % int(mission["reward"]), 13,
		UiKit.GOLD))
	box.add_child(head)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 8)
	bar.show_percentage = false
	bar.max_value = int(mission["target"])
	bar.value = int(mission["progress"])
	var back := UiKit.style(UiKit.SURFACE, 4, 1, 0)
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill",
		UiKit.style(UiKit.LIME if done else UiKit.BLUE, 4, 0, 0))
	box.add_child(bar)

	box.add_child(UiKit.label("%d / %d" % [int(mission["progress"]),
		int(mission["target"])], 11, UiKit.TEXT_FAINT,
		HORIZONTAL_ALIGNMENT_RIGHT))
	return box

## Kosmetika: bo'limlar va elementlar.
##
## Har bo'limning tagida bir qator izoh turadi — nima sotilayotgani
## nomidan ko'rinmasligi mumkin. Har element esa o'z ko'rinishi
## bilan chiziladi ([CosmeticView]).
func _cosmetics_card() -> Control:
	var card := UiKit.panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)

	var tabs: Array[String] = [ShopManager.SKINS, ShopManager.TRAILS,
		ShopManager.EFFECTS, ShopManager.SPECIAL]
	var labels := PackedStringArray()
	for tab: String in tabs:
		labels.append(Strings.t("tab" + tab.capitalize()))
	box.add_child(UiKit.chips(labels, tabs.find(_shop_tab),
		func(index: int) -> void:
			Audio.tap()
			_shop_tab = tabs[index]
			_rebuild(), _accent(), 58, 18))
	box.add_child(UiKit.label(Strings.t("tab" + _shop_tab.capitalize()
		+ "Hint"), 14, UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT, true))

	for item: Dictionary in Shop.catalogue(_shop_tab):
		box.add_child(_item_row(item))
	box.add_child(UiKit.label(Strings.t("cosmeticNote"), 12,
		UiKit.TEXT_FAINT, HORIZONTAL_ALIGNMENT_CENTER, true))
	return card

const RARITY_TINT: Array[Color] = [
	Color("9a93bd"), Color("45e8ff"), Color("c06bff"), Color("ffd23f"),
]

func _item_row(item: Dictionary) -> Control:
	var row := UiKit.panel(Color(UiKit.SURFACE, 0.8), 13)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	row.add_child(line)

	var frame := UiKit.panel(UiKit.BG, 5)
	frame.add_child(CosmeticView.new(str(item["cat"]), str(item["id"]),
		_accent()))
	line.add_child(frame)

	var rarity := int(item["rarity"])
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 4)
	left.add_child(UiKit.label(Strings.t(str(item["name"])), 19, UiKit.TEXT,
		HORIZONTAL_ALIGNMENT_LEFT))
	var tint: Color = RARITY_TINT[clampi(rarity, 0, 3)]
	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", 9)
	tags.add_child(UiKit.label(Strings.t(_rarity_key(rarity)), 13, tint,
		HORIZONTAL_ALIGNMENT_LEFT))
	tags.add_child(UiKit.label(_price_text(item), 13, UiKit.TEXT_FAINT,
		HORIZONTAL_ALIGNMENT_LEFT))
	left.add_child(tags)
	line.add_child(left)
	line.add_child(_item_button(item))
	return row

static func _rarity_key(rarity: int) -> String:
	match rarity:
		ShopManager.Rarity.RARE: return "rarityRare"
		ShopManager.Rarity.EPIC: return "rarityEpic"
		ShopManager.Rarity.LEGENDARY: return "rarityLegendary"
		_: return "rarityCommon"

func _price_text(item: Dictionary) -> String:
	var coins := int(item["coins"])
	var gems := int(item["gems"])
	if coins > 0:
		return "\u25C9 %d" % coins
	if gems > 0:
		return "\u2726 %d" % gems
	var rule := str(item.get("unlock", ""))
	if rule.begins_with("percent:"):
		return Strings.t("needPercent") % rule.substr(8)
	if rule.begins_with("kills:"):
		return Strings.t("needKills") % rule.substr(6)
	return ""

## Do'kon tugmasining o'lchami — barmoq bemalol tegadigan katta.
const ITEM_BUTTON := Vector2(150, 62)

func _item_button(item: Dictionary) -> Control:
	var id := str(item["id"])
	if Shop.worn_in(str(item["cat"])) == id:
		var worn := UiKit.ghost_button(Strings.t("wornItem"), UiKit.TEXT_FAINT)
		worn.custom_minimum_size = ITEM_BUTTON
		worn.disabled = true
		return worn
	if Shop.owns(id):
		var put_on := UiKit.button(Strings.t("wearItem"), UiKit.MINT)
		put_on.custom_minimum_size = ITEM_BUTTON
		put_on.pressed.connect(func() -> void:
			Audio.tap()
			Shop.wear(id)
			_rebuild())
		return put_on
	if not ShopManager.unlocked_by(item, store.best_percent, store.best_kills):
		var locked := UiKit.ghost_button(Strings.t("lockedItem"), UiKit.TEXT_FAINT)
		locked.custom_minimum_size = ITEM_BUTTON
		locked.disabled = true
		return locked
	var buy := UiKit.button(Strings.t("buyItem"), _accent())
	buy.custom_minimum_size = ITEM_BUTTON
	buy.pressed.connect(func() -> void:
		Audio.tap()
		_buy_item(id))
	return buy

func _buy_item(id: String) -> void:
	var result := Shop.buy(id, store.best_percent, store.best_kills)
	match result:
		"ok":
			_rebuild()
			toast(Strings.t("wornItem"))
		"poor":
			toast(Strings.t("purchaseFailed"))
		"locked":
			toast(Strings.t("lockedItem"))

## Belet to'plamlari va mukofotli reklama.
func _tickets_card() -> Control:
	var card := UiKit.panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	box.add_child(UiKit.section(Strings.t("buyTickets")))
	box.add_child(UiKit.label(Strings.t("demoPurchaseNote"), 12,
		UiKit.TEXT_FAINT, HORIZONTAL_ALIGNMENT_CENTER, true))
	for pack: Dictionary in services.packs():
		box.add_child(_pack_row(pack))
	var ad := UiKit.ghost_button(Strings.t("watchAd"), UiKit.GOLD)
	ad.pressed.connect(func() -> void:
		Audio.tap()
		_watch_ad(false))
	box.add_child(ad)
	return card

## Reklamani o'chirish.
func _no_ads_card() -> Control:
	var card := UiKit.panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	box.add_child(UiKit.section(Strings.t("noAds")))
	box.add_child(UiKit.label(Strings.t("noAdsNote"), 12, UiKit.TEXT_FAINT,
		HORIZONTAL_ALIGNMENT_CENTER, true))
	if Purchases.has_no_ads():
		box.add_child(UiKit.label("\u2713 " + Strings.t("adsRemoved"), 15,
			UiKit.MINT, HORIZONTAL_ALIGNMENT_CENTER))
		return card
	var buy := UiKit.button(Strings.t("noAds"), UiKit.VIOLET)
	buy.pressed.connect(func() -> void:
		Audio.tap()
		if Purchases.purchase_no_ads():
			_rebuild()
			toast(Strings.t("adsRemoved"))
		else:
			toast(Strings.t("purchaseFailed")))
	box.add_child(buy)
	var restore := UiKit.ghost_button(Strings.t("restorePurchases"),
		UiKit.TEXT_DIM)
	restore.pressed.connect(func() -> void:
		Audio.tap()
		var found: int = Purchases.restore_purchases()
		if found > 0:
			_rebuild()
			toast(Strings.t("adsRemoved"))
		else:
			toast(Strings.t("nothingToRestore")))
	box.add_child(restore)
	return card

## Bitta belet to'plami qatori. Eng foydali to'plam ajratib ko'rsatiladi.
func _pack_row(pack: Dictionary) -> Control:
	var best: bool = bool(pack.get("best", false))
	var label := "\U01F39F %d %s   %s" % [
		int(pack["tickets"]), Strings.t("ticketPack"), str(pack["price"])]
	var row := UiKit.button(label, _accent()) if best \
		else UiKit.ghost_button(label, UiKit.TEXT)
	row.pressed.connect(func() -> void:
		Audio.tap()
		_buy(str(pack["id"])))
	return row

func _buy(pack_id: String) -> void:
	var got := services.buy(pack_id)
	if got <= 0:
		toast(Strings.t("purchaseFailed"))
		return
	store.add_tickets(got)
	_rebuild()
	toast("%s: +%d" % [Strings.t("ticketsAdded"), got])

## Mukofotli reklama. `then_continue` bo'lsa, belet darhol o'yinni
## davom ettirishga sarflanadi.
func _watch_ad(then_continue: bool) -> void:
	if _ad_busy:
		return
	_ad_busy = true
	# Reklama AdManager orqali: o'yin kodi SDK ni bilmaydi.
	var result: Dictionary = await Ads.show_rewarded(
		AdManager.Reward.CONTINUE_RUN if then_continue
		else AdManager.Reward.BONUS_COINS)
	_ad_busy = false
	if not bool(result["ok"]):
		# Xato bo'lsa hech narsa olinmaydi va hech narsa yo'qolmaydi.
		toast(Strings.t(str(result["error"])))
		return
	var reward := ContinueServices.AD_REWARD
	store.add_tickets(reward)
	if then_continue:
		continue_with_ticket.emit()
		return
	_rebuild()
	toast("%s: +%d" % [Strings.t("ticketsAdded"), reward])

# ——— Maydon tanlash ———

## Maydon tanlash ekranini ochadi. `then` — "play" yoki "host".
func open_maps(then: String) -> void:
	_maps_then = then
	show_screen(Screen.MAPS)

func _build_maps() -> Control:
	var root := UiKit.overlay(true)
	var box := UiKit.centered_column(root, 480)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var back := UiKit.icon_button("<")
	back.pressed.connect(func() -> void:
		Audio.tap()
		show_screen(Screen.MENU))
	head.add_child(back)

	var title := UiKit.title("MAP SELECT", 24, Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title)

	head.add_child(_purse_chip("coin", Wallet.get_coins(), UiKit.YELLOW))
	box.add_child(head)

	# 4 ta toifa (Continents, Countries, Cities, Special)
	var tab_names := PackedStringArray([
		Strings.t("tabContinents"), Strings.t("tabCountries"),
		Strings.t("tabCities"), Strings.t("tabSpecial")
	])
	var tabs := UiKit.chips(tab_names, _maps_category, func(idx: int) -> void:
		Audio.tap()
		_maps_category = idx
		_rebuild())
	box.add_child(tabs)
	box.add_child(UiKit.spacer(4))

	match _maps_category:
		0:
			box.add_child(_build_maps_continents())
		1:
			box.add_child(_build_maps_countries())
		2:
			box.add_child(_build_maps_cities())
		3:
			box.add_child(_build_maps_special())
		_:
			box.add_child(_build_maps_continents())

	return root

func _build_maps_continents() -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)

	var maps_data := [
		["world", "World", 1113, ["US", "GB", "FR", "JP", "DE"]],
		["europe", "Europe", 156, ["GB", "FR", "DE", "IT", "ES"]],
		["asia", "Asia", 430, ["CN", "JP", "KR", "TH", "IN"]],
		["africa", "Africa", 223, ["EG", "KE", "NG", "ZA", "MA"]],
		["north_america", "North America", 202, ["US", "CA", "MX"]],
		["south_america", "South America", 128, ["BR", "AR", "CO"]],
		["oceania", "Oceania", 34, ["AU", "NZ", "FJ", "PG"]],
		["ancient", "Ancient World", 95, ["EG", "GR", "IT", "CN"]]
	]

	for entry: Array in maps_data:
		var mid: String = str(entry[0])
		var mname: String = str(entry[1])
		var places_count: int = int(entry[2])
		var rec: float = store.get_map_record(mid)
		var stat_str: String = "%d cities" % places_count
		if mid == "ancient":
			stat_str = "Event Map"
		elif rec > 0.0:
			stat_str = "%d cities • %.1f%%" % [places_count, rec]
		grid.add_child(_map_rich_card(mid, mname, stat_str, entry[3] as Array))

	return grid

func _build_maps_countries() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)

	var journey: Node = get_node_or_null("/root/Journey")
	var done: int = journey.done_count() if journey != null else 0
	var total: int = journey.countries.size() if journey != null else 1
	var cur: Dictionary = journey.current() if journey != null else {}
	var cur_name: String = str(cur.get("name", "Conquest"))
	var cur_code: String = str(cur.get("code", "UZ"))
	var pts: int = journey.points() if journey != null else 0
	var g: int = journey.goal() if journey != null else 100
	var pct: float = journey.percent() if journey != null else 0.0

	# 1. Umumiy progress banneri
	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", UiKit.style_solid(Color(0.06, 0.18, 0.42, 0.90), 16, 4, 6))
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 6)
	var b_top := HBoxContainer.new()
	b_top.add_child(UiKit.title("Mamlakatlar sarguzashti", 15, Color.WHITE))
	var bgap := Control.new()
	bgap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_top.add_child(bgap)
	var b_stat := UiKit.title("%d / %d egallangan" % [done, total], 14, UiKit.YELLOW)
	b_top.add_child(b_stat)
	bv.add_child(b_top)
	var pb := UiKit.progress_bar(float(done) * 100.0 / float(maxi(total, 1)), UiKit.MINT)
	bv.add_child(pb)
	banner.add_child(bv)
	col.add_child(banner)

	# 2. Hozirgi nishon mamlakat kartasi
	var cur_card := PanelContainer.new()
	cur_card.add_theme_stylebox_override("panel", UiKit.style_solid(Color(0.10, 0.26, 0.58, 0.95), 16, 4, 6))
	var ch := HBoxContainer.new()
	ch.add_theme_constant_override("separation", 12)
	ch.alignment = BoxContainer.ALIGNMENT_CENTER
	var flag_avatar := AvatarView.new("flag:" + cur_code, 42.0)
	ch.add_child(flag_avatar)
	var cv := VBoxContainer.new()
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cv.add_child(UiKit.title("Hozirgi nishon: " + cur_name, 15, Color.WHITE))
	cv.add_child(UiKit.label("Egallash: %d / %d ochko (%.0f%%)" % [pts, g, pct], 12, Color("7dd3fc"), HORIZONTAL_ALIGNMENT_LEFT))
	cv.add_child(UiKit.progress_bar(pct, UiKit.YELLOW))
	ch.add_child(cv)
	var play_cur := UiKit.button("Jang!", UiKit.GREEN)
	play_cur.custom_minimum_size = Vector2(80, 42)
	play_cur.pressed.connect(func() -> void:
		Audio.tap()
		store.map_id = "world"
		if _maps_then == "host":
			host_pressed.emit()
		else:
			play_pressed.emit())
	ch.add_child(play_cur)
	cur_card.add_child(ch)
	col.add_child(cur_card)

	# 3. Mamlakatlar yo'li ro'yxati
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list_box := VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 6)

	if journey != null:
		var c_list: Array = journey.countries
		for idx in c_list.size():
			var item: Dictionary = c_list[idx]
			var c_code: String = str(item.get("code", ""))
			var c_n: String = str(item.get("name", ""))
			var is_done: bool = idx < done
			var is_cur: bool = idx == done
			var row := PanelContainer.new()
			var bg_c := Color(0.06, 0.22, 0.18, 0.85) if is_done else (Color(0.10, 0.24, 0.50, 0.90) if is_cur else Color(0.04, 0.10, 0.22, 0.70))
			row.add_theme_stylebox_override("panel", UiKit.style_solid(bg_c, 12, 2, 4))
			var rh := HBoxContainer.new()
			rh.add_theme_constant_override("separation", 10)
			rh.add_child(AvatarView.new("flag:" + c_code, 26.0))
			var rn := UiKit.title(c_n, 13, Color.WHITE if (is_done or is_cur) else UiKit.TEXT_FAINT)
			rn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rh.add_child(rn)
			if is_done:
				rh.add_child(UiKit.label("Egallandi ✓", 12, UiKit.MINT))
			elif is_cur:
				rh.add_child(UiKit.label("%.0f%%" % pct, 12, UiKit.YELLOW))
			else:
				rh.add_child(GameIcon.new("skull", 16.0, UiKit.TEXT_FAINT))
			row.add_child(rh)
			list_box.add_child(row)
	scroll.add_child(list_box)
	col.add_child(scroll)
	return col

func _build_maps_cities() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)

	# Banner
	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", UiKit.style_solid(Color(0.06, 0.16, 0.36, 0.90), 16, 4, 6))
	var bv := VBoxContainer.new()
	bv.alignment = BoxContainer.ALIGNMENT_CENTER
	bv.add_theme_constant_override("separation", 4)
	bv.add_child(UiKit.title("Cities Mode — Shaharlar Jangi", 16, Color.WHITE))
	bv.add_child(UiKit.label("Katta poytaxt va megapolislarni egallab tanga yutib oling!", 12, Color("7dd3fc"), HORIZONTAL_ALIGNMENT_CENTER))
	banner.add_child(bv)
	col.add_child(banner)

	# City maps grid
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)

	var sm_coins: int = MonetizationConfig.CITY_REWARDS["small"]["coins"]
	var md_coins: int = MonetizationConfig.CITY_REWARDS["medium"]["coins"]
	var lg_coins: int = MonetizationConfig.CITY_REWARDS["large"]["coins"]

	var city_maps := [
		["world", "Capitals World Tour", "+%d COINS" % lg_coins, ["JP", "GB", "FR", "US"]],
		["asia", "Asian Megapolises", "+%d COINS" % md_coins, ["CN", "JP", "KR", "IN"]],
		["europe", "European Capitals", "+%d COINS" % lg_coins, ["DE", "FR", "IT", "ES"]],
		["oceania", "Pacific Ocean Ports", "+%d COINS" % sm_coins, ["AU", "NZ", "FJ"]]
	]

	for entry: Array in city_maps:
		grid.add_child(_map_rich_card(str(entry[0]), str(entry[1]), str(entry[2]), entry[3] as Array))
	col.add_child(grid)

	# Rewards info table
	col.add_child(_cities_catalog())
	return col

func _build_maps_special() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)

	# Circle arena
	var rec: float = store.get_map_record("circle")
	var circle_stat := "Arena Battle" if rec <= 0.0 else "Arena • %.1f%%" % rec
	grid.add_child(_map_rich_card("circle", "Circle Arena", circle_stat, ["UZ", "US", "DE"]))

	# Ancient World (Locked)
	var aw_card := PanelContainer.new()
	aw_card.custom_minimum_size = Vector2(216, 172)
	aw_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aw_card.add_theme_stylebox_override("panel", UiKit.style_solid(Color(0.04, 0.10, 0.22, 0.75), 18, 3, 6))
	var aw_v := VBoxContainer.new()
	aw_v.alignment = BoxContainer.ALIGNMENT_CENTER
	aw_v.add_theme_constant_override("separation", 6)
	aw_v.add_child(GameIcon.new("skull", 32.0, UiKit.TEXT_FAINT))
	aw_v.add_child(UiKit.title("Ancient World", 16, UiKit.TEXT_FAINT))
	aw_v.add_child(UiKit.label("Coming Soon", 12, Color("94a3b8"), HORIZONTAL_ALIGNMENT_CENTER))
	aw_card.add_child(aw_v)
	grid.add_child(aw_card)

	col.add_child(grid)
	return col

func _map_rich_card(map_id: String, display_name: String, progress_str: String, flag_codes: Array) -> Control:
	var chosen := map_id == store.map_id
	var card := Button.new()
	card.custom_minimum_size = Vector2(216, 172)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.flat = false
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	for state: String in ["normal", "hover", "pressed"]:
		var bg := Color(0.08, 0.20, 0.45, 0.90) if not chosen else Color(0.12, 0.32, 0.65, 0.98)
		var lift := 5 if state != "pressed" else 2
		var box := UiKit.style_solid(bg, 18, lift, 8)
		if chosen:
			box.border_color = Color("00d4ff")
			box.set_border_width_all(3)
		card.add_theme_stylebox_override(state, box)

	card.pressed.connect(func() -> void:
		Audio.tap()
		if map_id == "ancient":
			toast("Ancient World: Coming Soon in next update!")
			return
		store.map_id = map_id
		if _maps_then == "host":
			host_pressed.emit()
		else:
			play_pressed.emit())

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 4)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)

	# 3D Miniatyura rasmi
	var thumb := DesignDrawers.MapThumbnailControl.new(map_id)
	thumb.custom_minimum_size = Vector2(188, 72)
	thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_child(thumb)

	# Nomi
	var name_lbl := UiKit.title(display_name, 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	name_lbl.clip_text = true
	v.add_child(name_lbl)

	# Bayroqlar qatori
	var flag_row := HBoxContainer.new()
	flag_row.alignment = BoxContainer.ALIGNMENT_CENTER
	flag_row.add_theme_constant_override("separation", 3)
	for fc: String in flag_codes:
		var f_slot := Control.new()
		f_slot.custom_minimum_size = Vector2(18, 13)
		var av := AvatarView.new("flag:" + fc, 14.0)
		av.set_anchors_preset(Control.PRESET_FULL_RECT)
		f_slot.add_child(av)
		flag_row.add_child(f_slot)
	v.add_child(flag_row)

	# Oltin toj va ko'rsatkich (masalan "195 / 195")
	var prog_row := HBoxContainer.new()
	prog_row.alignment = BoxContainer.ALIGNMENT_CENTER
	prog_row.add_theme_constant_override("separation", 4)
	prog_row.add_child(GameIcon.new("crown", 16.0, UiKit.YELLOW))
	var prog_lbl := UiKit.title(progress_str, 12, UiKit.YELLOW)
	prog_row.add_child(prog_lbl)
	v.add_child(prog_row)

	return card

func _map_card(map_id: String, badge: String) -> Control:
	return _map_rich_card(map_id, Strings.map_name(map_id), "45 / 45", ["US", "GB", "FR"])

func _map_tile(map_id: String) -> Control:
	return _map_card(map_id, "Standard")

# ——— Onlayn reyting ———

func open_board() -> void:
	_board_rows = []
	_board_note = Strings.t("loading")
	show_screen(Screen.BOARD)
	Board.fetch(store, _board_scope)

## Server javobi keldi.
func set_board(rows: Array) -> void:
	_board_rows = rows
	_board_note = "" if not rows.is_empty() else Strings.t("emptyBoard")
	if _screen == Screen.BOARD:
		_rebuild()

func set_board_error(reason: String) -> void:
	_board_rows = []
	_board_note = Strings.t(reason)
	if _screen == Screen.BOARD:
		_rebuild()

func _build_board() -> Control:
	var root := UiKit.overlay()
	var box := UiKit.centered_column(root, 440)
	box.add_child(_header(Strings.t("onlineBoard"), func() -> void:
		show_screen(Screen.MENU)))

	var names := PackedStringArray()
	for scope: String in Board.SCOPES:
		names.append(Strings.t("scope" + scope.capitalize()))
	box.add_child(UiKit.chips(names, Board.SCOPES.find(_board_scope),
		func(index: int) -> void:
			Audio.tap()
			_board_scope = Board.SCOPES[index]
			_board_rows = []
			_board_note = Strings.t("loading")
			_rebuild()
			Board.fetch(store, _board_scope), _accent()))

	var panel := UiKit.panel()
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)
	if not _board_note.is_empty():
		inner.add_child(UiKit.label(_board_note, 16, UiKit.TEXT_DIM,
			HORIZONTAL_ALIGNMENT_CENTER, true))
	for i in _board_rows.size():
		inner.add_child(_board_line(i + 1, _board_rows[i]))
	box.add_child(panel)
	return root

func _board_line(place: int, row: Dictionary) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	var mine: bool = str(row.get("name", "")) == store.nickname
	var rank := UiKit.label(str(place), 14,
		UiKit.BLUE if mine else UiKit.TEXT_FAINT)
	rank.custom_minimum_size = Vector2(26, 0)
	line.add_child(rank)

	var code := str(row.get("country", ""))
	if code.length() == 2:
		line.add_child(AvatarView.new(
			Profile.encode(Profile.Kind.FLAG, code), 22.0))

	var name_label := UiKit.label(str(row.get("name", "")), 16,
		UiKit.TEXT if mine else UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	line.add_child(name_label)
	line.add_child(UiKit.label("%.2f%%" % float(row.get("percent", 0.0)), 16,
		UiKit.TEXT if mine else UiKit.TEXT_DIM))
	return line

# ——— Xona: do'stlar bilan va internetda ———

## Xona ekranini ochadi. `online` — internetdagi server, aks holda
## bitta Wi-Fi tarmog'idagi o'yin.
func open_room(online: bool) -> void:
	_room_online = online
	_room_status = ""
	show_screen(Screen.ROOM)

func set_room_status(text: String) -> void:
	_room_status = text
	if _screen == Screen.ROOM:
		_rebuild()

func _build_room() -> Control:
	var root := UiKit.overlay()
	var box := UiKit.centered_column(root, 440)
	box.add_child(_header(
		Strings.t("modeOnline") if _room_online else Strings.t("modeFriends"),
		func() -> void:
			Net.leave()
			show_screen(Screen.MENU)))

	var panel := UiKit.panel()
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	panel.add_child(inner)

	if Net.is_online():
		inner.add_child(_room_members())
	elif _room_online:
		inner.add_child(UiKit.label(Strings.t("onlineNote"), 14,
			UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, true))
		inner.add_child(_address_row(Strings.t("serverAddress"),
			store.server_address))
	else:
		# Uy egasi bo'lish — bitta Wi-Fi tarmog'ida eng oson yo'l.
		inner.add_child(UiKit.section(Strings.t("createRoom")))
		inner.add_child(UiKit.label(Strings.t("shareCode"), 13,
			UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, true))
		inner.add_child(UiKit.label(Net.local_address(), 22, UiKit.MINT))
		var create := UiKit.button(Strings.t("createRoom"), UiKit.MINT)
		create.pressed.connect(func() -> void:
			Audio.tap()
			open_maps("host"))
		inner.add_child(create)
		inner.add_child(UiKit.section(Strings.t("joinRoom")))
		inner.add_child(_address_row(Strings.t("roomCode"),
			store.last_room))

	if not _room_status.is_empty():
		inner.add_child(UiKit.label(_room_status, 15, UiKit.CORAL,
			HORIZONTAL_ALIGNMENT_CENTER, true))
	box.add_child(panel)
	return root

## Manzil kiritish qatori va "Qo'shilish" tugmasi.
func _address_row(title: String, value: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(UiKit.label(title, 15, UiKit.TEXT_DIM,
		HORIZONTAL_ALIGNMENT_LEFT))

	var field := LineEdit.new()
	field.text = value
	field.placeholder_text = "192.168.1.5"
	field.add_theme_font_size_override("font_size", 19)
	field.add_theme_stylebox_override("normal",
		UiKit.style(UiKit.SURFACE, 12, 2, 10))
	field.add_theme_stylebox_override("focus",
		UiKit.style(UiKit.SURFACE, 12, 2, 10))
	box.add_child(field)

	var join := UiKit.button(Strings.t("joinRoom"), _accent())
	join.pressed.connect(func() -> void:
		Audio.tap()
		var address := field.text.strip_edges()
		if address.is_empty():
			return
		if _room_online:
			store.server_address = address
		else:
			store.last_room = address
		set_room_status(Strings.t("connecting"))
		join_pressed.emit(address))
	box.add_child(join)
	return box

## Xonadagi o'yinchilar ro'yxati.
func _room_members() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(UiKit.section("%s (%d)" % [
		Strings.t("inRoom"), Net.roster.size()]))
	for row: Dictionary in Net.roster:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		var dot := ColorRect.new()
		dot.color = Palette.head(int(row["color"]))
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(dot)
		line.add_child(AvatarView.new(str(row["avatar"]), 22.0))
		var name_label := UiKit.label(str(row["name"]), 16,
			UiKit.TEXT_DIM if bool(row["bot"]) else UiKit.TEXT,
			HORIZONTAL_ALIGNMENT_LEFT)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_label)
		box.add_child(line)

	var leave := UiKit.ghost_button(Strings.t("leaveRoom"), UiKit.CORAL)
	leave.pressed.connect(func() -> void:
		Audio.tap()
		Net.leave()
		menu_pressed.emit())
	box.add_child(leave)
	return box

static func _clock(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
