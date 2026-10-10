extends MultiMeshInstance3D

## Xaritadagi shaharlar: belgilar va nomlar.
##
## Har shaharda **nuqta** bor, poytaxtlarda esa oltin **ustun**.
## Ikkalasining ham kattaligi shahar aholisiga qarab o'zgaradi —
## yozuvlar ham shunday.
##
## Nomlar ikki bosqichda tanlanadi:
##
##  1. **Bir marta**, xarita yuklanganda: shaharlar muhimligi bo'yicha
##     saralanadi (poytaxt va aholi) va bir-biridan [MIN_GAP] katak
##     narida turadiganlari tanlanadi. Bu ro'yxat o'yin davomida
##     o'zgarmaydi.
##  2. **Har kadrda**: shu ro'yxatdan kameraga eng yaqinlari
##     [POOL] ta tayyor tugunga biriktiriladi.
##
## Ilgari tanlov har safar masofa bo'yicha qaytadan hisoblanardi va
## o'yinchi qimirlashi bilan nomlar o'rin almashib, miltillab ketardi.
## Endi ro'yxat qotib turadi, chetga chiqqani esa asta so'nadi.

## Poytaxt ustunining asosi va balandligi (dunyo birligi).
const BASE := 0.7
const MIN_HEIGHT := 1.0
const MAX_HEIGHT := 2.8

## Shahar nuqtasining eng kichik va eng katta radiusi (katak).
const DOT_MIN := 0.22
const DOT_MAX := 0.62
const DOT_HEIGHT := 0.22

## Nom shrifti va ekrandagi o'lchami (`fixed_size` rejimida).
const NAME_FONT := 48
const SCREEN_SIZE := 0.00042

## Nom shu masofadan uzoqda ko'rsatilmaydi (katak), oxirgi
## [FADE] ulushida asta so'nadi.
const NAME_RANGE := 56.0
const FADE := 0.22

## Bir vaqtda ekranda bo'ladigan nomlar soni.
##
## Ataylab ehtiyot bilan olingan: ko'rish doirasiga sig'adigan
## shaharlardan ko'proq. Agar chegara tez-tez urilsa, eng uzoqdagi
## nom goh ko'rinib, goh yo'qolib miltillab qolardi.
const POOL := 64

## Nomi yoziladigan shaharlar bir-biridan shuncha narida turadi.
const MIN_GAP := 13.0

## Ro'yxat sekundiga shuncha marta qayta tanlanadi.
const REFRESH := 0.3

var enabled := true:
	set(value):
		enabled = value
		visible = value
		if _dots != null:
			_dots.visible = value

## Shahar nomlari ko'rinadimi.
var names_visible := true:
	set(value):
		names_visible = value
		_timer = 0.0
		for label in _labels:
			label.visible = false

var _dots: MultiMeshInstance3D
var _labels: Array[Label3D] = []
## Nomi yoziladigan shaharlar (muhimligi bo'yicha, siyraklashtirilgan).
var _named: Array = []
## Hozir ko'rinib turgan nomlar: [{label, at, size}].
var _active: Array = []
var _timer := 0.0

func _ready() -> void:
	_dots = MultiMeshInstance3D.new()
	_dots.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_dots)

## Shaharlarni joylaydi. `places` — {name, code, x, y, pop, cap}.
func build(places: Array, grid: GameGrid) -> int:
	var rows: Array = []
	var top_pop := 1.0
	for c: Dictionary in places:
		if grid.playable(int(c.get("x", -1)), int(c.get("y", -1))):
			top_pop = maxf(top_pop, float(c.get("pop", 0)))
	for c: Dictionary in places:
		var x := int(c.get("x", -1))
		var y := int(c.get("y", -1))
		if not grid.playable(x, y):
			continue
		# Aholi juda keng tarqalgan (ming kishidan yigirma milliongacha),
		# shuning uchun kvadrat ildiz: kichik shahar ham ko'rinadi.
		var weight := sqrt(float(c.get("pop", 0)) / top_pop)
		var capital: bool = int(c.get("cap", 0)) == 1
		rows.append({
			"name": str(c.get("name", "")),
			"at": Vector2(x + 0.5, y + 0.5),
			"weight": clampf(weight, 0.0, 1.0),
			"cap": capital,
			# Poytaxt har doim oddiy shahardan muhimroq.
			"rank": weight + (1.0 if capital else 0.0),
		})

	_build_pillars(rows)
	_build_dots(rows)
	_pick_named(rows)
	_timer = 0.0
	for label in _labels:
		label.visible = false
	_active.clear()
	return rows.size()

## Poytaxt ustunlari — bitta MultiMesh.
func _build_pillars(rows: Array) -> void:
	var box := BoxMesh.new()
	box.size = Vector3(BASE, 1.0, BASE)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = UiKit.GOLD
	mat.emission_enabled = true
	mat.emission = UiKit.GOLD
	mat.emission_energy_multiplier = 0.35
	mat.roughness = 0.4
	box.material = mat

	var placed: Array[Transform3D] = []
	for row: Dictionary in rows:
		if not row["cap"]:
			continue
		var height: float = lerpf(MIN_HEIGHT, MAX_HEIGHT, row["weight"])
		var basis := Basis.IDENTITY.scaled(Vector3(1.0, height, 1.0))
		placed.append(Transform3D(basis, Vector3(
			row["at"].x, ArenaBuilder.LAND_HEIGHT + height * 0.5,
			row["at"].y)))
	multimesh = _mesh_from(box, placed)

## Har shaharning nuqtasi — yana bitta MultiMesh.
func _build_dots(rows: Array) -> void:
	var dot := CylinderMesh.new()
	dot.top_radius = 1.0
	dot.bottom_radius = 1.0
	dot.height = DOT_HEIGHT
	dot.radial_segments = 10
	dot.rings = 0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("b9c0e0")
	mat.emission_enabled = true
	mat.emission = Color("b9c0e0")
	mat.emission_energy_multiplier = 0.12
	mat.roughness = 0.5
	dot.material = mat

	var placed: Array[Transform3D] = []
	for row: Dictionary in rows:
		var radius: float = lerpf(DOT_MIN, DOT_MAX, row["weight"])
		var basis := Basis.IDENTITY.scaled(Vector3(radius, 1.0, radius))
		placed.append(Transform3D(basis, Vector3(
			row["at"].x, ArenaBuilder.LAND_HEIGHT + DOT_HEIGHT * 0.5,
			row["at"].y)))
	_dots.multimesh = _mesh_from(dot, placed)

static func _mesh_from(mesh: Mesh, placed: Array[Transform3D]) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = placed.size()
	for i in placed.size():
		mm.set_instance_transform(i, placed[i])
	return mm

## Nomi yoziladigan shaharlarni bir marta tanlaydi: muhimi oldin,
## va ular bir-biridan [MIN_GAP] katak narida turadi.
func _pick_named(rows: Array) -> void:
	var sorted := rows.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["rank"] > b["rank"])
	_named = []
	var gap := MIN_GAP * MIN_GAP
	for row: Dictionary in sorted:
		var crowded := false
		for kept: Dictionary in _named:
			if row["at"].distance_squared_to(kept["at"]) < gap:
				crowded = true
				break
		if not crowded:
			_named.append(row)

## Kamera (yoki o'yinchi) qayerda — shuning atrofidagi nomlar
## ko'rsatiladi va chetdagilari so'nadi.
func update_focus(center: Vector2, delta: float) -> void:
	if not enabled or not names_visible or _named.is_empty():
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = REFRESH
		_assign(center)
	_fade(center)

func _assign(center: Vector2) -> void:
	var near: Array = []
	var range2 := NAME_RANGE * NAME_RANGE
	for row: Dictionary in _named:
		var d: float = center.distance_squared_to(row["at"])
		if d <= range2:
			near.append({"row": row, "d": d})
	near.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["d"] < b["d"])

	_active.clear()
	var used: int = mini(near.size(), POOL)
	for i in used:
		var row: Dictionary = near[i]["row"]
		var label := _label(i)
		label.visible = true
		label.text = row["name"]
		# Yozuv kattaligi ham shahar kattaligiga qarab.
		var scale: float = 0.62 + 0.85 * row["weight"] \
			+ (0.15 if row["cap"] else 0.0)
		label.pixel_size = SCREEN_SIZE * scale
		label.position = Vector3(
			row["at"].x,
			ArenaBuilder.LAND_HEIGHT + (MAX_HEIGHT + 0.8 if row["cap"]
				else 1.1),
			row["at"].y)
		_active.append({"label": label, "at": row["at"],
			"cap": row["cap"]})
	for i in range(used, _labels.size()):
		_labels[i].visible = false

## Chet nomlari birdan yo'qolmasin — masofaga qarab so'nadi.
func _fade(center: Vector2) -> void:
	var fade_from := NAME_RANGE * (1.0 - FADE)
	for item: Dictionary in _active:
		var d: float = center.distance_to(item["at"])
		var alpha: float = clampf(
			(NAME_RANGE - d) / (NAME_RANGE - fade_from), 0.0, 1.0)
		var label: Label3D = item["label"]
		var base: Color = UiKit.TEXT if item["cap"] else UiKit.TEXT_DIM
		label.modulate = Color(base.r, base.g, base.b, alpha)
		label.outline_modulate = Color(0.04, 0.03, 0.09, 0.85 * alpha)

func _label(index: int) -> Label3D:
	while _labels.size() <= index:
		var label := Label3D.new()
		label.font_size = NAME_FONT
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		# Kamera uzoqligiga qarab kattalashmaydi — xaritadagi nomlar
		# bir xil o'lchamda, o'qishga qulay.
		label.fixed_size = true
		label.outline_size = 8
		label.no_depth_test = true
		label.render_priority = 2
		add_child(label)
		_labels.append(label)
	return _labels[index]
