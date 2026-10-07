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

var enabled := true:
	set(value):
		enabled = value
		visible = value

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
	return placed.size()
