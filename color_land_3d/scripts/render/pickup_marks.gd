extends Node3D

## Xaritada yotgan tangalar va kuchaytirgich sferalari.
##
## Ikkita `MultiMesh`: biri tanga, biri sfera. Aylanish, tebranish
## va pulsatsiya **shaderda** — har kadrda hech narsa
## yangilanmaydi. Narsa olinganda faqat shu nusxaning o'lchami
## nolga tushiriladi, qaytganda esa yangi joyiga qo'yiladi.

## Tanga radiusi va yerdan balandligi.
const COIN_RADIUS := 0.44
const COIN_THICK := 0.12
const COIN_HEIGHT := 0.85
## Sfera radiusi va balandligi.
const ORB_RADIUS := 0.62
const ORB_HEIGHT := 1.05

## Sfera ranglari: qalqon — moviy, tezlik — yashil.
const SHIELD_TINT := Color("4fc3ff")
const DASH_TINT := Color("8ef05a")

const COIN_SHADER := """
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

uniform vec3 tint : source_color = vec3(1.0, 0.82, 0.25);

void vertex() {
	// Har tanga o'z joyiga qarab boshqa fazada aylanadi.
	float phase = MODEL_MATRIX[3].x * 0.7 + MODEL_MATRIX[3].z * 0.5;
	float t = TIME * 2.6 + phase;
	// Bu tangalar **to'liq** aylanadi: yo'lda ko'zga tashlanishi
	// kerak, shahar tangasidan ko'proq harakat qiladi.
	float c = cos(t);
	float s = sin(t);
	VERTEX.xz = vec2(c * VERTEX.x + s * VERTEX.z, -s * VERTEX.x + c * VERTEX.z);
	VERTEX.y += sin(t * 0.55) * 0.12;
}

void fragment() {
	ALBEDO = tint;
	METALLIC = 0.0;
	ROUGHNESS = 0.38;
	EMISSION = tint * 0.7;
}
"""

const ORB_SHADER := """
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

// Rang har nusxada boshqa: MultiMesh rangi orqali beriladi.
void vertex() {
	float phase = MODEL_MATRIX[3].x * 0.6 + MODEL_MATRIX[3].z * 0.4;
	float t = TIME * 1.6 + phase;
	// Nafas olgandek kichrayib-kattalashadi.
	VERTEX *= 1.0 + sin(t * 1.7) * 0.09;
	VERTEX.y += sin(t) * 0.16;
}

void fragment() {
	vec3 tint = COLOR.rgb;
	ALBEDO = tint;
	METALLIC = 0.0;
	ROUGHNESS = 0.22;
	// Chetlari yorqinroq: ichi shisha sharga o'xshaydi.
	float rim = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.0);
	EMISSION = tint * (0.5 + rim * 1.1);
	ALPHA = 0.9;
}
"""

var _field: PickupField
var _coins: MultiMeshInstance3D
var _orbs: MultiMeshInstance3D
## Narsa indeksidan nusxa indeksiga: tangalar va sferalar alohida
## `MultiMesh` da yotadi.
var _slot: Dictionary = {}

## Narsalarni joylaydi.
func build(field: PickupField) -> void:
	_field = field
	_slot.clear()
	for child in get_children():
		child.queue_free()

	var coin_spots: Array = []
	var orb_spots: Array = []
	for i in field.items.size():
		var item: Dictionary = field.items[i]
		if int(item["kind"]) == PickupField.Kind.COIN:
			_slot[i] = coin_spots.size()
			coin_spots.append(i)
		else:
			_slot[i] = orb_spots.size()
			orb_spots.append(i)

	_coins = _make_layer(_coin_mesh(), coin_spots.size(), false)
	_orbs = _make_layer(_orb_mesh(), orb_spots.size(), true)
	for i: int in coin_spots:
		_coins.multimesh.set_instance_transform(int(_slot[i]), _at(i))
	for i: int in orb_spots:
		var slot := int(_slot[i])
		_orbs.multimesh.set_instance_transform(slot, _at(i))
		_orbs.multimesh.set_instance_color(slot, _tint_of(i))

func _make_layer(mesh: Mesh, count: int,
		colors: bool) -> MultiMeshInstance3D:
	var node := MultiMeshInstance3D.new()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors
	mm.mesh = mesh
	mm.instance_count = count
	node.multimesh = mm
	add_child(node)
	return node

func _coin_mesh() -> Mesh:
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = COIN_THICK
	disc.radial_segments = 14
	disc.rings = 0
	var mat := _material(COIN_SHADER)
	mat.set_shader_parameter("tint", Color("ffd23f"))
	disc.material = mat
	return disc

func _orb_mesh() -> Mesh:
	var ball := SphereMesh.new()
	ball.radius = 1.0
	ball.height = 2.0
	ball.radial_segments = 14
	ball.rings = 7
	# Rang shaderga `COLOR` orqali keladi — har nusxada boshqa.
	ball.material = _material(ORB_SHADER)
	return ball

func _material(code: String) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = code
	return mat

## Olingan narsalarni yashiradi.
func take(indices: PackedInt32Array) -> void:
	for i: int in indices:
		_place(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))

## Qayta paydo bo'lganlarni yangi joyiga qo'yadi.
func give_back(indices: PackedInt32Array) -> void:
	for i: int in indices:
		_place(i, _at(i))

func _place(index: int, at: Transform3D) -> void:
	if not _slot.has(index):
		return
	var layer := _layer_of(index)
	if layer == null:
		return
	var slot := int(_slot[index])
	if slot >= 0 and slot < layer.multimesh.instance_count:
		layer.multimesh.set_instance_transform(slot, at)

func _layer_of(index: int) -> MultiMeshInstance3D:
	var item: Dictionary = _field.items[index]
	if int(item["kind"]) == PickupField.Kind.COIN:
		return _coins
	return _orbs

func _tint_of(index: int) -> Color:
	var item: Dictionary = _field.items[index]
	return SHIELD_TINT if int(item["kind"]) == PickupField.Kind.SHIELD \
		else DASH_TINT

func _at(index: int) -> Transform3D:
	var item: Dictionary = _field.items[index]
	var x := float(item["x"])
	var y := float(item["y"])
	if int(item["kind"]) == PickupField.Kind.COIN:
		# Tanga tik turadi va o'yinchiga qarab biroz yotqiziladi.
		var basis := Basis(Vector3.RIGHT, PI * 0.5 - 0.55).scaled(
			Vector3(COIN_RADIUS, 1.0, COIN_RADIUS))
		return Transform3D(basis, Vector3(
			x, ArenaBuilder.LAND_HEIGHT + COIN_HEIGHT, y))
	return Transform3D(
		Basis().scaled(Vector3.ONE * ORB_RADIUS),
		Vector3(x, ArenaBuilder.LAND_HEIGHT + ORB_HEIGHT, y))
