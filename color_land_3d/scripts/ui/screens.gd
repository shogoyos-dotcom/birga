extends CanvasLayer

## Butun interfeys: menyu, sozlamalar, profil, HUD, pauza va natija.
##
## Ekranlar kod bilan quriladi va kerak bo'lganda qayta yig'iladi —
## shunda til yoki rang o'zgarsa hamma joy darhol yangilanadi.

signal play_pressed
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

enum Screen { MENU, SETTINGS, PROFILE, HUD, PAUSE, RESULT, SHOP, ROOM, BOARD,
	MAPS }

var store: SettingsStore
## Belet va reklama xizmati (hozircha namuna).
var services := ContinueServices.new()

var _screen: Screen = Screen.MENU
var _root: Control
var _percent_label: Label
var _info_label: Label
var _board: VBoxContainer
var _result_data := {}
var _flag_query := ""
var _avatar_tab := 0
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
	_percent_label = null
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
	add_child(_root)

func _accent() -> Color:
	return Palette.head(store.color_index)

# ——— Menyu ———

func _build_menu() -> Control:
	var root := UiKit.overlay()
	var box := UiKit.centered_column(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var tickets := UiKit.ghost_button(
		"%d %s" % [store.tickets, Strings.t("tickets")], UiKit.GOLD)
	tickets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tickets.pressed.connect(func() -> void:
		Audio.tap()
		open_shop(Screen.MENU))
	top.add_child(tickets)
	var settings := UiKit.icon_button("⚙")
	settings.pressed.connect(func() -> void:
		Audio.tap()
		show_screen(Screen.SETTINGS))
	top.add_child(settings)
	box.add_child(top)

	box.add_child(UiKit.spacer(8))
	box.add_child(UiKit.label("COLOR LAND", 44))
	box.add_child(UiKit.label(Strings.t("rulesShort"), 17, UiKit.TEXT_DIM,
		HORIZONTAL_ALIGNMENT_CENTER, true))
	box.add_child(UiKit.spacer(8))

	var play := UiKit.button(Strings.t("modeBots"), _accent(), true)
	play.pressed.connect(func() -> void:
		Audio.tap()
		open_maps("play"))
	box.add_child(play)
	box.add_child(UiKit.label(Strings.t("modeBotsHint"), 13, UiKit.TEXT_FAINT))

	var friends := UiKit.ghost_button(Strings.t("modeFriends"), UiKit.MINT)
	friends.pressed.connect(func() -> void:
		Audio.tap()
		open_room(false))
	box.add_child(friends)

	var online := UiKit.ghost_button(Strings.t("modeOnline"), UiKit.GOLD)
	online.pressed.connect(func() -> void:
		Audio.tap()
		open_room(true))
	box.add_child(online)

	box.add_child(_profile_card())
	box.add_child(_record_card())

	var board := UiKit.ghost_button(Strings.t("onlineBoard"), UiKit.BLUE)
	board.pressed.connect(func() -> void:
		Audio.tap()
		open_board())
	box.add_child(board)
	return root

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

func _stat_tile(value: String, title: String, color: Color) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(UiKit.label(value, 24, color, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(UiKit.section(title))
	return box

func _player_name() -> String:
	var saved := store.nickname
	return saved if not saved.is_empty() else Strings.t("you")

# ——— Sozlamalar ———

func _build_settings() -> Control:
	var root := UiKit.overlay()
	var box := UiKit.centered_column(root)
	box.add_child(_header(Strings.t("settings"), func() -> void:
		_reset_armed = false
		show_screen(Screen.MENU)))

	# Ko'rinish
	var look := UiKit.panel()
	var look_box := VBoxContainer.new()
	look_box.add_theme_constant_override("separation", 10)
	look.add_child(look_box)
	look_box.add_child(UiKit.section(Strings.t("sectionAppearance")))
	look_box.add_child(UiKit.label(Strings.t("chooseColor"), 16, UiKit.TEXT_DIM,
		HORIZONTAL_ALIGNMENT_LEFT))
	var colors := HFlowContainer.new()
	colors.add_theme_constant_override("h_separation", 8)
	colors.add_theme_constant_override("v_separation", 8)
	for i in Palette.color_count():
		colors.add_child(UiKit.color_chip(i, i == store.color_index,
			func(index: int) -> void:
				Audio.tap()
				store.color_index = index
				settings_changed.emit()
				_rebuild()))
	look_box.add_child(colors)
	look_box.add_child(UiKit.label(Strings.t("themeLabel"), 16, UiKit.TEXT_DIM,
		HORIZONTAL_ALIGNMENT_LEFT))
	look_box.add_child(UiKit.chips(Strings.theme_names(),
		Palette.ORDER.find(store.theme_id),
		func(index: int) -> void:
			Audio.tap()
			store.theme_id = Palette.ORDER[index]
			Palette.set_theme(store.theme_id)
			settings_changed.emit()
			_rebuild(), _accent()))
	box.add_child(look)

	# O'yin
	var game := UiKit.panel()
	var game_box := VBoxContainer.new()
	game_box.add_theme_constant_override("separation", 10)
	game.add_child(game_box)
	game_box.add_child(UiKit.section(Strings.t("sectionGame")))
	game_box.add_child(UiKit.label(Strings.t("difficulty"), 16, UiKit.TEXT_DIM,
		HORIZONTAL_ALIGNMENT_LEFT))
	var levels := PackedStringArray([
		Strings.t("easy"), Strings.t("normal"), Strings.t("hard")])
	var names := PackedStringArray(["easy", "normal", "hard"])
	game_box.add_child(UiKit.chips(levels, names.find(store.difficulty_name),
		func(index: int) -> void:
			Audio.tap()
			store.difficulty_name = names[index]
			settings_changed.emit()
			_rebuild(), _accent()))
	game_box.add_child(UiKit.label(Strings.t("language"), 16, UiKit.TEXT_DIM,
		HORIZONTAL_ALIGNMENT_LEFT))
	var lang_names := PackedStringArray()
	for code: String in Strings.CODES:
		lang_names.append(Strings.native_name(code))
	game_box.add_child(UiKit.chips(lang_names,
		Strings.CODES.find(Strings.language()),
		func(index: int) -> void:
			Audio.tap()
			var code: String = Strings.CODES[index]
			store.language = code
			Strings.set_language(code)
			_rebuild(), _accent()))
	box.add_child(game)

	# Ovoz
	var audio := UiKit.panel()
	var audio_box := VBoxContainer.new()
	audio_box.add_theme_constant_override("separation", 10)
	audio.add_child(audio_box)
	audio_box.add_child(UiKit.section(Strings.t("sectionAudio")))
	audio_box.add_child(UiKit.switch_row(Strings.t("music"),
		store.music_enabled, func(value: bool) -> void:
			store.music_enabled = value
			Audio.set_music_enabled(value)
			_rebuild(), _accent()))
	audio_box.add_child(UiKit.switch_row(Strings.t("sound"),
		store.sound_enabled, func(value: bool) -> void:
			store.sound_enabled = value
			Audio.sound_enabled = value
			Audio.tap()
			_rebuild(), _accent()))
	audio_box.add_child(UiKit.switch_row(Strings.t("vibration"),
		store.vibration_enabled, func(value: bool) -> void:
			store.vibration_enabled = value
			Audio.vibration_enabled = value
			Audio.tap()
			_rebuild(), _accent()))
	box.add_child(audio)

	# Arena ko'rinishi — o'yin qaytadan boshlanmaydi.
	var view := UiKit.panel()
	var view_box := VBoxContainer.new()
	view_box.add_theme_constant_override("separation", 10)
	view.add_child(view_box)
	view_box.add_child(UiKit.section(Strings.t("sectionView")))
	view_box.add_child(UiKit.switch_row(Strings.t("showCapitals"),
		store.show_capitals, func(value: bool) -> void:
			store.show_capitals = value
			Audio.tap()
			view_changed.emit()
			_rebuild(), _accent()))
	view_box.add_child(UiKit.switch_row(Strings.t("showCityNames"),
		store.show_city_names, func(value: bool) -> void:
			store.show_city_names = value
			Audio.tap()
			view_changed.emit()
			_rebuild(), _accent()))
	view_box.add_child(UiKit.switch_row(Strings.t("showFlags"),
		store.show_flags, func(value: bool) -> void:
			store.show_flags = value
			Audio.tap()
			view_changed.emit()
			_rebuild(), _accent()))
	view_box.add_child(UiKit.switch_row(Strings.t("minimapLabel"),
		store.show_minimap, func(value: bool) -> void:
			store.show_minimap = value
			Audio.tap()
			view_changed.emit()
			_rebuild(), _accent()))
	box.add_child(view)

	# Ma'lumot: rekord ikki bosishda tozalanadi — tasodifan bosilmasin.
	var data := UiKit.panel()
	var data_box := VBoxContainer.new()
	data_box.add_theme_constant_override("separation", 10)
	data.add_child(data_box)
	data_box.add_child(UiKit.section(Strings.t("sectionData")))
	data_box.add_child(UiKit.label(
		"%.2f%%   %d %s" % [store.best_percent, store.best_kills,
			Strings.t("kills")], 18, UiKit.TEXT_DIM,
		HORIZONTAL_ALIGNMENT_LEFT))
	data_box.add_child(UiKit.label(Strings.t("boardUrl"), 16, UiKit.TEXT_DIM,
		HORIZONTAL_ALIGNMENT_LEFT))
	var board_field := LineEdit.new()
	board_field.text = store.leaderboard_url
	board_field.placeholder_text = "http://192.168.1.5:8080"
	board_field.add_theme_font_size_override("font_size", 16)
	board_field.add_theme_stylebox_override("normal",
		UiKit.style(UiKit.SURFACE, 12, 2, 10))
	board_field.add_theme_stylebox_override("focus",
		UiKit.style(UiKit.SURFACE, 12, 2, 10))
	board_field.text_changed.connect(func(text: String) -> void:
		store.leaderboard_url = text.strip_edges())
	data_box.add_child(board_field)

	var reset := UiKit.ghost_button(
		Strings.t("resetRecordConfirm") if _reset_armed
			else Strings.t("resetRecord"),
		UiKit.CORAL if _reset_armed else UiKit.TEXT_DIM)
	reset.pressed.connect(func() -> void:
		Audio.tap()
		if not _reset_armed:
			_reset_armed = true
			_rebuild()
			return
		_reset_armed = false
		store.reset_record()
		_rebuild()
		toast(Strings.t("recordReset")))
	data_box.add_child(reset)
	box.add_child(data)
	return root

func _header(title: String, on_back: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var back := UiKit.icon_button("←")
	back.pressed.connect(func() -> void:
		Audio.tap()
		on_back.call())
	row.add_child(back)
	var label := UiKit.label(title.to_upper(), 24, UiKit.TEXT,
		HORIZONTAL_ALIGNMENT_LEFT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row

# ——— Profil ———

func _build_profile() -> Control:
	var root := UiKit.overlay()
	var box := UiKit.centered_column(root)
	box.add_child(_header(Strings.t("profile"), func() -> void:
		_save_nickname()
		show_screen(Screen.MENU)))

	var card := UiKit.panel(UiKit.PANEL, 12)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var frame := UiKit.panel(UiKit.SURFACE, 6)
	frame.add_child(AvatarView.new(store.avatar, 52.0, store.avatar_image))
	row.add_child(frame)

	_nickname_edit = LineEdit.new()
	_nickname_edit.text = store.nickname
	_nickname_edit.placeholder_text = Strings.t("nicknameHint")
	_nickname_edit.max_length = Profile.MAX_NICKNAME
	_nickname_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nickname_edit.add_theme_font_size_override("font_size", 20)
	_nickname_edit.add_theme_stylebox_override("normal",
		UiKit.style(UiKit.SURFACE, 12, 2, 10))
	_nickname_edit.add_theme_stylebox_override("focus",
		UiKit.style(UiKit.SURFACE, 12, 2, 10))
	_nickname_edit.text_submitted.connect(func(_t: String) -> void:
		_save_nickname())
	row.add_child(_nickname_edit)
	box.add_child(card)

	# Avatar — bosh ustidagi belgi.
	box.add_child(UiKit.section(Strings.t("avatarLabel")))
	var tabs := PackedStringArray([
		Strings.t("tabEmoji"), Strings.t("tabFigure")])
	box.add_child(UiKit.chips(tabs, _avatar_tab, func(index: int) -> void:
		Audio.tap()
		_avatar_tab = index
		_rebuild(), _accent()))

	var panel := UiKit.panel(UiKit.PANEL, 12)
	box.add_child(panel)
	if _avatar_tab == 0:
		panel.add_child(_emoji_grid())
	else:
		panel.add_child(_figure_grid())
	box.add_child(_photo_row(store.avatar_image, ImagePicker.AVATAR_FILE,
		func(path: String) -> void: store.avatar_image = path))

	# Bayroq — hududni egallaydi, shuning uchun alohida tanlanadi.
	box.add_child(UiKit.section(Strings.t("cityLabel")))
	var city := LineEdit.new()
	city.text = store.city
	city.placeholder_text = Strings.t("cityLabel")
	city.max_length = 40
	city.add_theme_font_size_override("font_size", 18)
	city.add_theme_stylebox_override("normal",
		UiKit.style(UiKit.SURFACE, 12, 2, 10))
	city.add_theme_stylebox_override("focus",
		UiKit.style(UiKit.SURFACE, 12, 2, 10))
	city.text_changed.connect(func(text: String) -> void:
		store.city = text.strip_edges())
	box.add_child(city)

	box.add_child(UiKit.section(Strings.t("territoryFlag")))
	var flags := UiKit.panel(UiKit.PANEL, 12)
	flags.add_child(_flag_grid())
	box.add_child(flags)
	box.add_child(_photo_row(store.flag_image, ImagePicker.FLAG_FILE,
		func(path: String) -> void: store.flag_image = path))
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
	var limit: int = mini(list.size(), 60)
	for i in limit:
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

	var left := UiKit.panel(Color(UiKit.PANEL, 0.92), 12)
	left.position = Vector2(16, 16)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(left)
	var stats := VBoxContainer.new()
	left.add_child(stats)
	_percent_label = UiKit.label("0.00%", 34, _accent(),
		HORIZONTAL_ALIGNMENT_LEFT)
	stats.add_child(_percent_label)
	_info_label = UiKit.label("00:00", 16, UiKit.TEXT_DIM,
		HORIZONTAL_ALIGNMENT_LEFT)
	stats.add_child(_info_label)

	var pause := UiKit.icon_button("⏸")
	pause.anchor_left = 1.0
	pause.anchor_right = 1.0
	pause.position = Vector2(-74, 16)
	pause.pressed.connect(func() -> void:
		Audio.tap()
		show_screen(Screen.PAUSE))
	root.add_child(pause)

	var board_panel := UiKit.panel(Color(UiKit.PANEL, 0.92), 10)
	board_panel.anchor_left = 1.0
	board_panel.anchor_right = 1.0
	board_panel.position = Vector2(-186, 80)
	board_panel.custom_minimum_size = Vector2(170, 0)
	board_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(board_panel)
	_board = VBoxContainer.new()
	_board.add_theme_constant_override("separation", 3)
	board_panel.add_child(_board)

	_minimap = null
	if store.show_minimap and _minimap_texture != null:
		var map_panel := UiKit.panel(Color(UiKit.PANEL, 0.92), 8)
		map_panel.anchor_top = 1.0
		map_panel.anchor_bottom = 1.0
		map_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
		map_panel.position = Vector2(16, -16)
		map_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_minimap = MiniMap.new(_minimap_texture, _accent())
		map_panel.add_child(_minimap)
		root.add_child(map_panel)
	return root

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

## HUD ni yangilaydi. `rows` — [{name, avatar, color, percent, is_human}].
func update_hud(percent: float, kills: int, elapsed: float, rank: int,
		alive: int, rows: Array, marker: Vector2 = Vector2.ZERO) -> void:
	if _screen != Screen.HUD or _percent_label == null:
		return
	_percent_label.text = "%.2f%%" % percent
	_info_label.text = "%s   %d kill   %d/%d" % [
		_clock(elapsed), kills, rank, alive]
	if _minimap != null and is_instance_valid(_minimap):
		_minimap.marker = marker

	for child in _board.get_children():
		child.queue_free()
	_board.add_child(UiKit.section(Strings.t("leaderboard")))
	for i in rows.size():
		_board.add_child(_board_row(i + 1, rows[i]))

func _board_row(place: int, row: Dictionary) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 5)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var is_human: bool = row["is_human"]

	var rank := UiKit.label(str(place), 12,
		UiKit.BLUE if is_human else UiKit.TEXT_FAINT)
	rank.custom_minimum_size = Vector2(14, 0)
	line.add_child(rank)

	var dot := ColorRect.new()
	dot.color = Palette.head(int(row["color"]))
	dot.custom_minimum_size = Vector2(9, 9)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(dot)

	var avatar := AvatarView.new(str(row["avatar"]), 16.0)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(avatar)

	var name_label := UiKit.label(str(row["name"]), 13,
		UiKit.TEXT if is_human else UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	line.add_child(name_label)

	line.add_child(UiKit.label("%.1f%%" % float(row["percent"]), 13,
		UiKit.TEXT if is_human else UiKit.TEXT_DIM))
	return line

# ——— Pauza ———

func _build_pause() -> Control:
	var root := UiKit.overlay()
	var box := UiKit.centered_column(root, 400)
	var panel := UiKit.panel()
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	panel.add_child(inner)
	inner.add_child(UiKit.label(Strings.t("pause").to_upper(), 28))

	# Ovoz sozlamalari — o'yindan chiqmasdan.
	inner.add_child(UiKit.switch_row(Strings.t("music"), store.music_enabled,
		func(value: bool) -> void:
			store.music_enabled = value
			Audio.set_music_enabled(value)
			_rebuild(), _accent()))
	inner.add_child(UiKit.switch_row(Strings.t("sound"), store.sound_enabled,
		func(value: bool) -> void:
			store.sound_enabled = value
			Audio.sound_enabled = value
			Audio.tap()
			_rebuild(), _accent()))
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
		is_record: bool) -> void:
	_result_data = {
		"percent": percent, "kills": kills, "elapsed": elapsed,
		"reason": reason, "record": is_record,
	}

func _build_result() -> Control:
	var root := UiKit.overlay()
	var box := UiKit.centered_column(root, 420)
	var panel := UiKit.panel()
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	panel.add_child(inner)

	inner.add_child(UiKit.label(Strings.t("gameOver").to_upper(), 28))
	inner.add_child(UiKit.label(str(_result_data.get("reason", "")), 16,
		UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, true))
	if bool(_result_data.get("record", false)):
		inner.add_child(UiKit.label("★ " + Strings.t("newRecord"), 18, UiKit.GOLD))

	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 18)
	tiles.add_child(_stat_tile("%.2f%%" % float(_result_data.get("percent", 0.0)),
		Strings.t("territory"), _accent()))
	tiles.add_child(_stat_tile(str(_result_data.get("kills", 0)),
		Strings.t("kills"), UiKit.CORAL))
	tiles.add_child(_stat_tile(_clock(float(_result_data.get("elapsed", 0.0))),
		Strings.t("time"), UiKit.TEXT))
	inner.add_child(tiles)

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

# ——— Do'kon ———

## Do'konni ochadi; orqaga tugmasi `from` ekraniga qaytaradi.
func open_shop(from: Screen) -> void:
	_shop_return = from
	show_screen(Screen.SHOP)

func _build_shop() -> Control:
	var root := UiKit.overlay()
	var box := UiKit.centered_column(root, 420)
	box.add_child(_header(Strings.t("shop"), func() -> void:
		show_screen(_shop_return)))

	var panel := UiKit.panel()
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	panel.add_child(inner)

	inner.add_child(UiKit.label(
		"%d %s" % [store.tickets, Strings.t("tickets")], 28, UiKit.GOLD))
	inner.add_child(UiKit.label(Strings.t("demoPurchaseNote"), 13,
		UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, true))

	inner.add_child(UiKit.section(Strings.t("buyTickets")))
	for pack: Dictionary in services.packs():
		inner.add_child(_pack_row(pack))

	inner.add_child(UiKit.section(Strings.t("watchAd")))
	var ad := UiKit.button(Strings.t("watchAd"), UiKit.GOLD)
	ad.pressed.connect(func() -> void:
		Audio.tap()
		_watch_ad(false))
	inner.add_child(ad)

	var close := UiKit.ghost_button(Strings.t("close"))
	close.pressed.connect(func() -> void:
		Audio.tap()
		show_screen(_shop_return))
	inner.add_child(close)
	box.add_child(panel)
	return root

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
	var reward := services.show_rewarded()
	if reward <= 0:
		toast(Strings.t("adNotReady"))
		return
	_ad_busy = true
	# Namuna reklama: haqiqiy videoning o'rniga qisqa kutish.
	await get_tree().create_timer(0.6).timeout
	services.preload_ad()
	_ad_busy = false
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
	var root := UiKit.overlay()
	var box := UiKit.centered_column(root, 460)
	box.add_child(_header(Strings.t("chooseArena"), func() -> void:
		show_screen(Screen.MENU)))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for map_id: String in WorldMap.ids():
		grid.add_child(_map_tile(map_id))
	box.add_child(grid)
	return root

## Bitta maydon tugmasi: nomi va tanlanganligi.
func _map_tile(map_id: String) -> Control:
	var chosen := map_id == store.map_id
	var button := UiKit.button(
		Strings.map_name(map_id), _accent() if chosen else UiKit.SURFACE)
	button.custom_minimum_size = Vector2(0, 64)
	button.add_theme_font_size_override("font_size", 17)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not chosen:
		button.add_theme_color_override("font_color", UiKit.TEXT)
	button.pressed.connect(func() -> void:
		Audio.tap()
		store.map_id = map_id
		if _maps_then == "host":
			host_pressed.emit()
		else:
			play_pressed.emit())
	return button

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
