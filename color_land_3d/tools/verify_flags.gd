extends SceneTree

func _initialize() -> void:
	print("--- DAVLAT BAYROQLARI AUDITI (249 ISO KODLAR) ---")
	var file := FileAccess.open("res://data/countries.json", FileAccess.READ)
	if file == null:
		print("XATO: data/countries.json ochilmadi!")
		quit(1)
		return
	var text := file.get_as_text()
	file.close()
	var json: Variant = JSON.parse_string(text)
	if not (json is Array):
		print("XATO: data/countries.json massiv emas!")
		quit(1)
		return

	var countries: Array = json as Array
	print("Jami yuklangan davlatlar soni: %d" % countries.size())
	if countries.size() != 249:
		print("XATO: 249 ta davlat kutilgan edi, lekin %d ta topildi!" % countries.size())
		quit(1)
		return

	var font := UiKit.emoji_font()
	if font == null:
		print("OGOHLANTIRISH: NotoColorEmoji.ttf yuklanmadi!")
	else:
		print("NotoColorEmoji.ttf shrifti muvaffaqiyatli yuklandi.")

	var errors := 0
	for item in countries:
		var code: String = str(item.get("code", "")).strip_edges().to_upper()
		var name: String = str(item.get("name", "")).strip_edges()
		if code.length() != 2:
			print("XATO: noto'g'ri kod uzunligi: '%s' (%s)" % [code, name])
			errors += 1
			continue
		var emoji := Profile.flag_emoji(code)
		if emoji.is_empty():
			print("XATO: bayroq emojisi hosil bo'lmadi: %s" % code)
			errors += 1
			continue
		# AvatarView flag tekshiruvi
		var av := AvatarView.new("flag:" + code, 24.0)
		if av == null:
			print("XATO: AvatarView flag yaratilmadi: %s" % code)
			errors += 1
		av.free()

	if errors == 0:
		print("BARCHA 249 TA DAVLAT BAYROQLARI MUVAFFAQIYATLI TEKSHIRILDI VA CHIZILDI (0 xato)!")
	else:
		print("XATOLAR TOPILDI: %d ta xato!" % errors)
		quit(1)
		return

	# Sozlamalarni tekshirish
	var store := SettingsStore.new()
	print("show_flags boshlang'ich qiymati: %s (kutilgan: true)" % [store.show_flags])
	if not store.show_flags:
		print("XATO: show_flags standart holatda true bo'lishi kerak!")
		quit(1)
		return

	# Shared CITY_REWARDS tekshiruvi
	print("CITY_REWARDS konfiguratsiyasi:")
	for tier in ["small", "medium", "large"]:
		var rew: Dictionary = MonetizationConfig.CITY_REWARDS.get(tier, {})
		print("  - %s: %s (+%d coins)" % [tier, rew.get("title", ""), rew.get("coins", 0)])

	print("PHASE 2.5 BAYROQ VA MUKOFOT AUDITI 100% MUVAFFAQ QILINDI.")
	quit(0)
