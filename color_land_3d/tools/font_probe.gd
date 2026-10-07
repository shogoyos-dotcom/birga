extends SceneTree

## Bayroq emojilari to'g'ri chiqyaptimi — tez tekshiruv.

func _initialize() -> void:
	UiKit.ensure_fonts()
	var root_control := Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("1a1728")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(bg)
	root.add_child(root_control)

	var box := VBoxContainer.new()
	box.position = Vector2(20, 20)
	root_control.add_child(box)

	var emoji: Font = load(UiKit.EMOJI_FONT_PATH)
	for codes: String in ["UZ", "US", "TR", "RU", "KZ", "DE"]:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 20)
		var a := Label.new()
		a.text = codes + " zaxira: " + Profile.flag_emoji(codes)
		a.add_theme_font_size_override("font_size", 28)
		line.add_child(a)
		var b := Label.new()
		b.text = "to'g'ridan: " + Profile.flag_emoji(codes)
		b.add_theme_font_override("font", emoji)
		b.add_theme_font_size_override("font_size", 28)
		line.add_child(b)
		box.add_child(line)
	await process_frame
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://build/font_probe.png")
	print("probe saqlandi")
	quit(0)
