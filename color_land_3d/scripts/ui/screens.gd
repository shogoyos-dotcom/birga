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
var _kill_capsule: PanelContainer
var _coin_capsule: PanelContainer
var _kill_label: Label
var _coin_label: Label
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
	var root := UiKit.overlay()
	var box := UiKit.centered_column(root)

	box.add_child(_top_bar())
	box.add_child(UiKit.spacer(2))
	box.add_child(_logo())
	# Markazda — mamlakatlar yo'li. Menyuning asosiy gapi shu:
	# "hozir qaysi yurtni egallayapsan".
	box.add_child(_journey_card())

	box.add_child(UiKit.spacer(4))
	var play := UiKit.round_button(Strings.t("play"), UiKit.YELLOW, 240)
	play.pressed.connect(func() -> void:
		Audio.tap()
		open_maps("play"))
	# 3D nafas olish (breathing pulse) effekti — tugmaga hajm beradi
	var tw := play.create_tween().set_loops()
	tw.tween_property(play, "scale", Vector2(1.05, 1.05), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(play, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	play.pivot_offset = Vector2(120, 120)
	box.add_child(play)
	box.add_child(UiKit.label(Strings.t("modeBotsHint"), 14,
		UiKit.TEXT_FAINT))

	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 14)
	for row: Array in [
			[Strings.t("modeFriends"), UiKit.MINT, false],
			[Strings.t("modeOnline"), UiKit.GOLD, true]]:
		var online: bool = row[2]
		var b := UiKit.button(str(row[0]), row[1] as Color)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			Audio.tap()
			open_room(online))
		modes.add_child(b)
	box.add_child(modes)

	box.add_child(UiKit.spacer(6))
	box.add_child(_tab_bar())
	return root

## Yuqoridagi qator: avatar, hamyon va sozlamalar.
func _top_bar() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var face := UiKit.icon_button("", 84)
	face.add_child(_avatar_mark(60.0))
	face.pressed.connect(func() -> void:
		Audio.tap()
		show_screen(Screen.PROFILE))
	row.add_child(face)

	row.add_child(_purse_chip("coin", Wallet.get_coins(), UiKit.YELLOW))
	row.add_child(_purse_chip("gem", Wallet.get_gems(), UiKit.VIOLET))

	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)

	# Reklama o'chirilgan bo'lsa nishon ham kerak emas.
	if not Purchases.has_no_ads():
		var no_ads := UiKit.icon_button("", 84)
		no_ads.add_child(GameIcon.new("noads", 44.0, UiKit.YELLOW))
		no_ads.pressed.connect(func() -> void:
			Audio.tap()
			show_screen(Screen.NOADS))
		row.add_child(no_ads)

	var settings := UiKit.icon_button("", 84)
	settings.add_child(GameIcon.new("gear", 44.0, UiKit.SURFACE))
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

## Mamlakatlar yo'li: shakl, nomi va to'lish chizig'i.
func _journey_card() -> Control:
	var card := UiKit.panel(UiKit.PANEL, 12)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	box.add_child(UiKit.section(Strings.t("journey")))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)

	var country := Journey.current()
	var frame := UiKit.panel(UiKit.SURFACE, 6)
	frame.add_child(CountryView.new(country, 110.0, Journey.percent(),
		UiKit.GREEN))
	row.add_child(frame)

	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 4)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.add_child(UiKit.title(
		Profile.country_name(str(country.get("code", ""))), 22,
		UiKit.TEXT))
	text.add_child(UiKit.label("%d / %d %s"
		% [Journey.points(), Journey.goal(), Strings.t("points")],
		14, UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT))
	var line := _thin_bar(Journey.percent(), UiKit.GREEN)
	text.add_child(line)
	text.add_child(UiKit.label(Strings.t("journeyDone")
		% [Journey.done_count(), Journey.countries.size()],
		12, UiKit.TEXT_FAINT, HORIZONTAL_ALIGNMENT_LEFT))
	row.add_child(text)
	return card

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

## Pastki qator: do'kon, qahramonlar, asosiy, reyting, jihozlar.
func _tab_bar() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for item: Array in [
			["bag", Strings.t("shop"), UiKit.YELLOW, Screen.SHOP],
			["heroes", Strings.t("tabHeroes"), UiKit.MINT, Screen.HEROES],
			["home", Strings.t("tabHome"), UiKit.GOLD, Screen.MENU],
			["trophy", Strings.t("leaderboard"), UiKit.BG_LOW, Screen.BOARD],
			["bolt", Strings.t("tabGear"), UiKit.RED, Screen.GEAR]]:
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
	return row

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
	var root := UiKit.overlay()
	var box := UiKit.centered_column(root, 460)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var back := UiKit.icon_button("<")
	back.pressed.connect(func() -> void:
		Audio.tap()
		show_screen(Screen.MENU))
	head.add_child(back)

	var title := UiKit.title(Strings.t("tabHeroes"), 24, UiKit.TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title)

	head.add_child(_purse_chip("coin", Wallet.get_coins(), UiKit.YELLOW))
	head.add_child(_purse_chip("gem", Wallet.get_gems(), UiKit.VIOLET))
	box.add_child(head)

	var streak: int = store.daily_streak
	var daily_node := get_node_or_null("/root/Daily")
	if daily_node != null and daily_node.has_method("streak"):
		streak = maxi(streak, int(daily_node.streak()))
	var stats := store.stats_dict(streak)
	var unlocked_count := HeroCatalog.unlocked_count(stats)

	var banner := UiKit.panel(UiKit.PANEL, 12)
	var banner_box := HBoxContainer.new()
	banner_box.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_box.add_theme_constant_override("separation", 10)
	banner_box.add_child(GameIcon.new("heroes", 26.0, UiKit.YELLOW))
	banner_box.add_child(UiKit.title("%d / %d  %s" % [
		unlocked_count, HeroCatalog.HEROES.size(), Strings.t("tabHeroes")],
		18, UiKit.TEXT))
	banner.add_child(banner_box)
	box.add_child(banner)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 12)

	for h: Dictionary in HeroCatalog.HEROES:
		grid.add_child(_hero_tile(h, stats))
	box.add_child(grid)

	box.add_child(UiKit.spacer(4))
	box.add_child(_tab_bar())
	return root

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

## Hamyondagi bitta qiymat: chizilgan belgi va son.
func _purse_chip(icon: String, value: int, tint: Color) -> Control:
	return UiKit.capsule(icon, _short(value), tint)

## Katta sonni qisqartiradi: 12 400 -> 12.4K.
static func _short(value: int) -> String:
	if value >= 1_000_000:
		return "%.1fM" % (value / 1_000_000.0)
	if value >= 10_000:
		return "%.1fK" % (value / 1000.0)
	return str(value)

## O'yin nomi — ikki qator, ikkinchisi limon rangda.
func _logo() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -8)
	box.add_child(UiKit.title("Color", 46, UiKit.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UiKit.title("Land", 46, UiKit.LIME,
		HORIZONTAL_ALIGNMENT_CENTER))
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

	# Yuqorida: egallangan foiz chizig'i, oxirida 100% yulduzi.
	_progress = UiKit.progress_bar(0.0, _accent(), store.best_percent)
	_progress_fill = _progress.find_child("Fill", true, false) as Panel
	_progress_text = _progress.find_child("Value", true, false) as Label
	_progress.anchor_right = 1.0
	_progress.offset_left = 16
	_progress.offset_right = -116
	_progress.offset_top = 14
	root.add_child(_progress)

	var star := GameIcon.new("star", 44.0, UiKit.YELLOW)
	star.anchor_left = 1.0
	star.anchor_right = 1.0
	star.offset_left = -164
	star.offset_right = -120
	star.offset_top = 22
	star.offset_bottom = 66
	root.add_child(star)

	# "\u23F8" hech bir shriftda yo'q — tugma bo'sh ko'rinardi.
	var pause := UiKit.icon_button("\u275A\u275A", 84)
	pause.anchor_left = 1.0
	pause.anchor_right = 1.0
	pause.position = Vector2(-100, 14)
	pause.pressed.connect(func() -> void:
		Audio.tap()
		# Ekranni o'zimiz almashtirmaymiz: avval o'yin to'xtashi
		# kerak, shuning uchun qaror `GameView` da qabul qilinadi.
		pause_pressed.emit())
	root.add_child(pause)

	# Chapda: o'ldirishlar va shu o'yinda yig'ilgan tanga.
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	stats.position = Vector2(16, 90)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stats)
	_kill_capsule = UiKit.capsule("skull", "0", UiKit.TEXT, 54)
	stats.add_child(_kill_capsule)
	_coin_capsule = UiKit.capsule("coin", "0", UiKit.YELLOW, 54)
	stats.add_child(_coin_capsule)
	_kill_label = _capsule_label(_kill_capsule)
	_coin_label = _capsule_label(_coin_capsule)

	# O'ngda: eng kuchli uchtasi va o'yinchining o'z qatori.
	_board = VBoxContainer.new()
	_board.add_theme_constant_override("separation", 7)
	_board.anchor_left = 1.0
	_board.anchor_right = 1.0
	_board.offset_left = -250
	_board.offset_right = -12
	_board.offset_top = 96
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_board)

	_minimap = null
	if store.minimap_side != "off" and _minimap_texture != null:
		var map_panel := UiKit.panel(Color(UiKit.TEXT, 0.9), 6)
		map_panel.anchor_top = 1.0
		map_panel.anchor_bottom = 1.0
		map_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
		if store.minimap_side == "right":
			map_panel.anchor_left = 1.0
			map_panel.anchor_right = 1.0
			map_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			map_panel.position = Vector2(-16, -16)
		else:
			map_panel.position = Vector2(16, -16)
		map_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_minimap = MiniMap.new(_minimap_texture, _accent())
		map_panel.add_child(_minimap)
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
## percent, is_human}].
func update_hud(percent: float, kills: int, elapsed: float, rank: int,
		alive: int, rows: Array, marker: Vector2 = Vector2.ZERO,
		coins: int = 0) -> void:
	if _screen != Screen.HUD or _progress == null:
		return
	if _progress_fill != null and is_instance_valid(_progress_fill):
		_progress_fill.anchor_right = clampf(percent / 100.0, 0.02, 1.0)
	if _progress_text != null and is_instance_valid(_progress_text):
		_progress_text.text = "%d%%" % int(round(percent))
	if _kill_label != null and is_instance_valid(_kill_label):
		_kill_label.text = str(kills)
	if _coin_label != null and is_instance_valid(_coin_label):
		_coin_label.text = str(coins)
	if _minimap != null and is_instance_valid(_minimap):
		_minimap.marker = marker

	for child in _board.get_children():
		child.queue_free()
	for row: Dictionary in rows:
		_board.add_child(_board_row(row))

## Reyting qatori: dumaloq avatar, o'rin nishoni va o'yinchi
## rangidagi foiz tasmasi. Birinchi o'rinda boshida toj turadi.
##
## Avatar va nishon [Control] ichida turadi, [PanelContainer] da
## emas: konteyner bolalarini o'zi joylashtiradi va ankerlarni
## e'tiborsiz qoldiradi — nishon butun katakni egallab olardi.
func _board_row(row: Dictionary) -> Control:
	var place := int(row["place"])
	var tint := Palette.head(int(row["color"]))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", -16)
	line.alignment = BoxContainer.ALIGNMENT_END
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var face := Control.new()
	face.custom_minimum_size = Vector2(68, 68)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var disc := Panel.new()
	disc.set_anchors_preset(Control.PRESET_FULL_RECT)
	disc.add_theme_stylebox_override("panel",
		UiKit.style_solid(tint.lightened(0.5), 34, 4, 0))
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(disc)

	var avatar := AvatarView.new(str(row["avatar"]), 52.0)
	avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar.offset_left = 8
	avatar.offset_top = 8
	avatar.offset_right = -8
	avatar.offset_bottom = -8
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(avatar)

	# O'rin nishoni — avatarning chap pastida.
	var badge := Panel.new()
	badge.add_theme_stylebox_override("panel", UiKit.style(
		UiKit.YELLOW if place == 1 else UiKit.TEXT, 16, UiKit.OUTLINE, 0))
	badge.anchor_top = 1.0
	badge.anchor_bottom = 1.0
	badge.offset_left = -4
	badge.offset_right = 26
	badge.offset_top = -30
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var number := UiKit.title(str(place), 17, UiKit.INK,
		HORIZONTAL_ALIGNMENT_CENTER)
	number.set_anchors_preset(Control.PRESET_FULL_RECT)
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.add_theme_constant_override("outline_size", 0)
	badge.add_child(number)
	face.add_child(badge)

	if place == 1:
		var crown := GameIcon.new("crown", 34.0, UiKit.YELLOW)
		crown.anchor_left = 0.5
		crown.anchor_right = 0.5
		crown.offset_left = -17
		crown.offset_right = 17
		crown.offset_top = -28
		crown.offset_bottom = 6
		face.add_child(crown)

	var tape := PanelContainer.new()
	var tape_box := UiKit.style_solid(tint, 18, 5, 8)
	tape_box.content_margin_left = 34
	tape_box.content_margin_right = 14
	tape.add_theme_stylebox_override("panel", tape_box)
	tape.custom_minimum_size = Vector2(144, 54)
	tape.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tape.add_child(UiKit.title("%.2f%%" % float(row["percent"]), 22,
		UiKit.TEXT, HORIZONTAL_ALIGNMENT_RIGHT))

	line.add_child(face)
	line.add_child(tape)
	return line

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
		journey: Dictionary = {}) -> void:
	_result_data = {
		"percent": percent, "kills": kills, "elapsed": elapsed,
		"reason": reason, "record": is_record, "reward": reward,
		"journey": journey,
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

	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 14)
	tiles.add_child(_result_tile("skull",
		str(_result_data.get("kills", 0)), Strings.t("kills"), UiKit.RED))
	tiles.add_child(_result_tile("coin",
		str(int(_reward_total())), Strings.t("coinsFound"), UiKit.YELLOW))
	tiles.add_child(_result_tile("clock",
		_clock(float(_result_data.get("elapsed", 0.0))),
		Strings.t("time"), UiKit.BG_LOW))
	inner.add_child(tiles)

	# Tanga qayerdan kelgani ochiq yozilgan.
	var reward: Dictionary = _result_data.get("reward", {})
	if not reward.is_empty():
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

## Natija ekranidagi tanga kartasi.
func _coin_card(reward: Dictionary) -> Control:
	var card := UiKit.panel(Color(UiKit.SURFACE, 0.8), 13)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	# Karta och rangda, shuning uchun matn to'q ko'k: oq-xira
	# matn bu fonda o'qilmasdi.
	var name_label := UiKit.label(Strings.t("coinsEarned"), 14,
		UiKit.INK, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	head.add_child(UiKit.title("+%d" % int(reward.get("total", 0)), 22,
		UiKit.GOLD, HORIZONTAL_ALIGNMENT_RIGHT))
	box.add_child(head)

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
	return int(reward.get("total", 0))

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
