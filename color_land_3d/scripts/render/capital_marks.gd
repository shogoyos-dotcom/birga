extends MultiMeshInstance3D

## Poytaxt belgilari: dunyo xaritasidagi 236 poytaxt arena ustida
## kichik ustun bo'lib turadi.
##
## Hammasi bitta `MultiMesh` — 236 tugun emas, bitta chizish chaqiruvi.

## Ustun asosi (dunyo birligi).
const BASE := 0.75

## Eng kichik va eng katta poytaxt ustunining balandligi.
const MIN_HEIGHT := 1.0
const MAX_HEIGHT := 2.8

## Nom balandligi (dunyo birligi) va shrift o'lchami.
const NAME_SIZE := 1.25
const NAME_FONT := 48
const NAME_OUTLINE := 8

## Nom shu masofadan uzoqda chizilmaydi.
const NAME_RANGE := 62.0

var enabled := true:
	set(value):
		enabled = value
		visible = value

## Shahar nomlari ko'rinadimi.
var names_visible := true

var _labels: Array[Label3D] = []

## Poytaxtlarni joylaydi. `capitals` — {name, code, x, y, pop}.
func build(capitals: Array, grid: GameGrid) -> int:
	var box := BoxMesh.new()
	box.size = Vector3(BASE, 1.0, BASE)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = UiKit.GOLD
	mat.emission_enabled = true
	mat.emission = UiKit.GOLD
	mat.emission_energy_multiplier = 0.35
	mat.roughness = 0.4
	box.material = mat

	# Eng katta aholi — balandlikni shunga nisbatan o'lchash uchun.
	var top_pop := 1.0
	for c: Dictionary in capitals:
		top_pop = maxf(top_pop, float(c.get("pop", 0)))

	var placed: Array[Transform3D] = []
	for c: Dictionary in capitals:
		var x := int(c.get("x", -1))
		var y := int(c.get("y", -1))
		if not grid.playable(x, y):
			continue
		# Aholi juda keng tarqalgan, shuning uchun kvadrat ildiz:
		# kichik poytaxtlar ham ko'rinib turadi.
		var scale := sqrt(float(c.get("pop", 0)) / top_pop)
		var height := lerpf(MIN_HEIGHT, MAX_HEIGHT, clampf(scale, 0.0, 1.0))
		var basis := Basis.IDENTITY.scaled(Vector3(1.0, height, 1.0))
		placed.append(Transform3D(basis, Vector3(
			x + 0.5, ArenaBuilder.LAND_HEIGHT + height * 0.5, y + 0.5)))

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box
	mm.instance_count = placed.size()
	for i in placed.size():
		mm.set_instance_transform(i, placed[i])
	multimesh = mm
	_build_names(capitals, grid)
	return placed.size()

## Shahar nomlari. Har biri alohida `Label3D`, lekin `visibility_range`
## tufayli faqat kameraga yaqinlari chiziladi — bir vaqtda ekranda
## o'ndan ortig'i bo'lmaydi.
func _build_names(capitals: Array, grid: GameGrid) -> void:
	for child in _labels:
		child.queue_free()
	_labels.clear()
	if not names_visible:
		return
	for c: Dictionary in capitals:
		var x := int(c.get("x", -1))
		var y := int(c.get("y", -1))
		if not grid.playable(x, y):
			continue
		var label := Label3D.new()
		label.text = str(c.get("name", ""))
		label.font_size = NAME_FONT
		label.pixel_size = NAME_SIZE / float(NAME_FONT)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.shaded = false
		label.no_depth_test = true
		label.render_priority = 2
		label.modulate = UiKit.TEXT
		# Qora kontur: har qanday rang ustida o'qiladi.
		label.outline_size = NAME_OUTLINE
		label.outline_modulate = Color(0.04, 0.03, 0.09, 0.85)
		label.position = Vector3(
			x + 0.5, ArenaBuilder.LAND_HEIGHT + MAX_HEIGHT + 0.8, y + 0.5)
		# Uzoqdagi nomlar chizilmaydi.
		label.visibility_range_end = NAME_RANGE
		label.visibility_range_end_margin = 8.0
		add_child(label)
		_labels.append(label)
