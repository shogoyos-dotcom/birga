extends MultiMeshInstance3D

## Xaritadagi shaharlar: poytaxt ustunlari va shahar nomlari.
##
## Natural Earth 1:50m ro'yxatidan barcha davlat poytaxtlari va
## dunyodagi yirik shaharlar olinadi (dunyo xaritasida 1100 dan
## ortiq). Ustunlar bitta `MultiMesh` — bitta chizish chaqiruvi;
## nomlar esa alohida `Label3D`, lekin `visibility_range` tufayli
## faqat kameraga yaqinlari chiziladi.

## Poytaxt ustunining asosi va balandligi (dunyo birligi).
const BASE := 0.75
const MIN_HEIGHT := 1.0
const MAX_HEIGHT := 2.8

## Nom balandligi va shrift o'lchami.
const NAME_SIZE := 1.25
const NAME_FONT := 48
const NAME_OUTLINE := 8

## Nom shu masofadan uzoqda chizilmaydi.
const NAME_RANGE := 62.0
## Oddiy shahar nomi poytaxtnikidan shuncha kichik.
const CITY_SCALE := 0.78

var enabled := true:
	set(value):
		enabled = value
		visible = value

## Shahar nomlari ko'rinadimi.
var names_visible := true

var _labels: Array[Label3D] = []

## Shaharlarni joylaydi. `places` — {name, code, x, y, pop, cap}.
func build(places: Array, grid: GameGrid) -> int:
	var box := BoxMesh.new()
	box.size = Vector3(BASE, 1.0, BASE)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = UiKit.GOLD
	mat.emission_enabled = true
	mat.emission = UiKit.GOLD
	mat.emission_energy_multiplier = 0.35
	mat.roughness = 0.4
	box.material = mat

	var top_pop := 1.0
	for c: Dictionary in places:
		top_pop = maxf(top_pop, float(c.get("pop", 0)))

	# Ustun faqat davlat poytaxtlariga qo'yiladi — aks holda xarita
	# ustunlar o'rmoniga aylanardi.
	var placed: Array[Transform3D] = []
	for c: Dictionary in places:
		if int(c.get("cap", 0)) != 1:
			continue
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
	_build_names(places, grid)
	return placed.size()

func _build_names(places: Array, grid: GameGrid) -> void:
	for child in _labels:
		child.queue_free()
	_labels.clear()
	if not names_visible:
		return
	for c: Dictionary in places:
		var x := int(c.get("x", -1))
		var y := int(c.get("y", -1))
		if not grid.playable(x, y):
			continue
		var capital: bool = int(c.get("cap", 0)) == 1
		var label := Label3D.new()
		label.text = str(c.get("name", ""))
		label.font_size = NAME_FONT
		var size := NAME_SIZE if capital else NAME_SIZE * CITY_SCALE
		label.pixel_size = size / float(NAME_FONT)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.shaded = false
		label.no_depth_test = true
		label.render_priority = 2
		label.modulate = UiKit.TEXT if capital else UiKit.TEXT_DIM
		# Qora kontur: har qanday rang ustida o'qiladi.
		label.outline_size = NAME_OUTLINE
		label.outline_modulate = Color(0.04, 0.03, 0.09, 0.85)
		var lift := MAX_HEIGHT + 0.8 if capital else 1.0
		label.position = Vector3(
			x + 0.5, ArenaBuilder.LAND_HEIGHT + lift, y + 0.5)
		# Uzoqdagi nomlar chizilmaydi; oddiy shahar yaqinroqdan
		# ko'rinadi, shunda yozuvlar bir-birining ustiga tushmaydi.
		label.visibility_range_end = NAME_RANGE if capital \
			else NAME_RANGE * 0.55
		label.visibility_range_end_margin = 8.0
		add_child(label)
		_labels.append(label)
