extends SceneTree

const COUNTRIES_PATH := "res://data/countries.json"
const SVG_DIR := "res://assets/flags/svg"
const PNG_DIR := "res://assets/flags/png"
const TARGET_W := 192
const TARGET_H := 128

func _initialize() -> void:
	var f := FileAccess.open(COUNTRIES_PATH, FileAccess.READ)
	if f == null:
		push_error("Cannot open countries.json")
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Array):
		push_error("Invalid countries.json")
		quit(1)
		return

	var countries: Array = parsed
	var count := 0
	var failed := 0

	for item: Dictionary in countries:
		var code := str(item.get("code", "")).to_upper()
		var svg_path := "%s/%s.svg" % [SVG_DIR, code]
		var png_path := "%s/%s.png" % [PNG_DIR, code]

		var svg_file := FileAccess.open(svg_path, FileAccess.READ)
		if svg_file == null:
			push_error("Missing SVG: " + svg_path)
			failed += 1
			continue

		var svg_text := svg_file.get_as_text()
		svg_file.close()

		var img := Image.new()
		var err := img.load_svg_from_string(svg_text, 0.4)
		if err != OK:
			push_error("Failed to parse SVG for %s: %d" % [code, err])
			failed += 1
			continue

		if img.get_width() != TARGET_W or img.get_height() != TARGET_H:
			img.resize(TARGET_W, TARGET_H, Image.INTERPOLATE_LANCZOS)

		var save_err := img.save_png(png_path)
		if save_err != OK:
			push_error("Failed to save PNG for %s: %d" % [code, save_err])
			failed += 1
			continue

		count += 1

	print("Rasterized %d / %d flags successfully (failed: %d)" % [count, countries.size(), failed])
	quit(0 if failed == 0 else 1)
