extends MultiMeshInstance3D

## Xaritadagi shaharlar: poytaxt ustunlari va shahar nomlari.
##
## Natural Earth 1:50m ro'yxatidan barcha davlat poytaxtlari va
## dunyodagi yirik shaharlar olinadi — dunyo xaritasida 1100 dan
## ortiq. Ustunlar bitta `MultiMesh` bo'lib, bitta chizish
## chaqiruvida chiziladi.
##
## Nomlar esa **qayta ishlatiladigan hovuz**: har shaharga alohida
## tugun yaratilsa, dunyo xaritasida 1100 ta `Label3D` va o'ttiz
## megabaytcha xotira ketardi. Buning o'rniga [POOL] ta tugun bor va
## ular kameraga eng yaqin shaharlarga biriktirib boriladi.

## Poytaxt ustunining asosi va balandligi (dunyo birligi).
const BASE := 0.75
const MIN_HEIGHT := 1.0
const MAX_HEIGHT := 2.8

## Nom shrifti va ekrandagi o'lchami (`fixed_size` rejimida).
const NAME_FONT := 48
const SCREEN_SIZE := 0.0004
const NAME_OUTLINE := 8

## Nom shu masofadan uzoqda ko'rsatilmaydi (katak).
const NAME_RANGE := 62.0
## Oddiy shahar nomi poytaxtnikidan shuncha kichik va yaqinroqdan
## ko'rinadi — yozuvlar bir-birining ustiga tushmaydi.
const CITY_SCALE := 0.78
const CITY_RANGE := 0.55

## Bir vaqtda ekranda bo'ladigan nomlar soni.
const POOL := 48

## Ikki nom shundan yaqin bo'lmasin (katak) — zich joyda yozuvlar
## bir-birining ustiga tushmasin. Muhimroq shahar (poytaxt, keyin
## yaqinrog'i) birinchi joylashadi.
const MIN_GAP := 11.0

## Ro'yxat sekundiga shuncha marta yangilanadi.
const REFRESH := 0.4

var enabled := true:
	set(value):
		enabled = value
		visible = value

## Shahar nomlari ko'rinadimi.
var names_visible := true:
	set(value):
		names_visible = value
		_focus = Vector2(-9999.0, -9999.0)
		for label in _labels:
			label.visible = false

var _labels: Array[Label3D] = []
var _places: Array = []
var _focus := Vector2(-9999.0, -9999.0)
var _timer := 0.0

## Shaharlarni joylaydi. `places` — {name, code, x, y, pop, cap}.
func build(places: Array, grid: GameGrid) -> int:
	_places = []
	for c: Dictionary in places:
		var x := int(c.get("x", -1))
		var y := int(c.get("y", -1))
		if grid.playable(x, y):
			_places.append(c)
	_focus = Vector2(-9999.0, -9999.0)

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
	for c: Dictionary in _places:
		top_pop = maxf(top_pop, float(c.get("pop", 0)))

	# Ustun faqat davlat poytaxtlariga qo'yiladi — aks holda xarita
	# ustunlar o'rmoniga aylanardi.
	var placed: Array[Transform3D] = []
	for c: Dictionary in _places:
		if int(c.get("cap", 0)) != 1:
			continue
		# Aholi juda keng tarqalgan, shuning uchun kvadrat ildiz:
		# kichik poytaxtlar ham ko'rinib turadi.
		var scale := sqrt(float(c.get("pop", 0)) / top_pop)
		var height := lerpf(MIN_HEIGHT, MAX_HEIGHT, clampf(scale, 0.0, 1.0))
		var basis := Basis.IDENTITY.scaled(Vector3(1.0, height, 1.0))
		placed.append(Transform3D(basis, Vector3(
			int(c["x"]) + 0.5, ArenaBuilder.LAND_HEIGHT + height * 0.5,
			int(c["y"]) + 0.5)))

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box
	mm.instance_count = placed.size()
	for i in placed.size():
		mm.set_instance_transform(i, placed[i])
	multimesh = mm
	return placed.size()

## Kamera (yoki o'yinchi) qayerda — shuning atrofidagi nomlar
## ko'rsatiladi.
func update_focus(center: Vector2, delta: float) -> void:
	if not enabled or not names_visible or _places.is_empty():
		return
	_timer -= delta
	# Ro'yxat kamdan-kam yangilanadi, lekin o'yinchi uzoqlashsa
	# darhol.
	if _timer > 0.0 and center.distance_squared_to(_focus) < 64.0:
		return
	_timer = REFRESH
	_focus = center
	_assign(center)

func _assign(center: Vector2) -> void:
	# Yaqindagilarni yig'amiz: poytaxtlar oldinda, keyin masofa
	# bo'yicha.
	var near: Array = []
	var capital_range := NAME_RANGE * NAME_RANGE
	var city_range := NAME_RANGE * CITY_RANGE * (NAME_RANGE * CITY_RANGE)
	for c: Dictionary in _places:
		var capital: bool = int(c.get("cap", 0)) == 1
		var d := center.distance_squared_to(
			Vector2(int(c["x"]) + 0.5, int(c["y"]) + 0.5))
		if d > (capital_range if capital else city_range):
			continue
		near.append({"c": c, "d": d, "cap": capital})
	near.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["cap"] != b["cap"]:
			return a["cap"]
		return a["d"] < b["d"])

	var placed := PackedVector2Array()
	var used := 0
	var gap := MIN_GAP * MIN_GAP
	for row: Dictionary in near:
		if used >= POOL:
			break
		var at := Vector2(
			int(row["c"]["x"]) + 0.5, int(row["c"]["y"]) + 0.5)
		var crowded := false
		for other in placed:
			if at.distance_squared_to(other) < gap:
				crowded = true
				break
		if crowded:
			continue
		placed.append(at)
		_apply(_label(used), row["c"], row["cap"])
		used += 1
	for i in range(used, _labels.size()):
		_labels[i].visible = false

func _apply(label: Label3D, place: Dictionary, capital: bool) -> void:
	label.visible = true
	label.text = str(place.get("name", ""))
	# `fixed_size` tufayli yozuv kamera uzoqligiga qarab kattalashmaydi
	# — xaritadagi nomlar bir xil o'lchamda, o'qishga qulay.
	label.pixel_size = SCREEN_SIZE if capital else SCREEN_SIZE * CITY_SCALE
	label.modulate = UiKit.TEXT if capital else UiKit.TEXT_DIM
	var lift := MAX_HEIGHT + 0.8 if capital else 1.0
	label.position = Vector3(
		int(place["x"]) + 0.5, ArenaBuilder.LAND_HEIGHT + lift,
		int(place["y"]) + 0.5)

func _label(index: int) -> Label3D:
	while _labels.size() <= index:
		var label := Label3D.new()
		label.font_size = NAME_FONT
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.fixed_size = true
		label.shaded = false
		# Qora kontur: har qanday rang ustida o'qiladi.
		label.outline_size = NAME_OUTLINE
		label.outline_modulate = Color(0.04, 0.03, 0.09, 0.85)
		label.no_depth_test = true
		label.render_priority = 2
		add_child(label)
		_labels.append(label)
	return _labels[index]
