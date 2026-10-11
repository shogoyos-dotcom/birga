extends MultiMeshInstance3D

## Shaharlar ustidagi tangalar.
##
## Hammasi bitta `MultiMesh` — 1113 ta tanga ham bitta chizish
## chaqirig'iga tushadi. Aylanish va tebranish **shaderda**
## bajariladi, shuning uchun har kadrda hech narsa yangilanmaydi;
## tanga olinganda esa faqat o'sha nusxaning o'lchami nolga
## tushiriladi.

## Tanganing eng kichik va eng katta radiusi (katak).
const MIN_RADIUS := 0.26
const MAX_RADIUS := 0.62
## Qalinligi va yerdan balandligi.
const THICK := 0.13
const HEIGHT := 0.9

const SHADER := """
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

uniform vec3 tint : source_color = vec3(1.0, 0.82, 0.25);
uniform float spin_speed = 2.3;
uniform float bob_height = 0.13;

void vertex() {
	// Har tanga o'z joyiga qarab boshqa fazada aylanadi — hammasi
	// bir vaqtda qimirlamaydi.
	float phase = MODEL_MATRIX[3].x * 0.7 + MODEL_MATRIX[3].z * 0.5;
	float t = TIME * spin_speed + phase;
	// To'liq aylanmaydi, chayqaladi: shunda tanga hech qachon
	// qirra bilan turib ko'rinmay qolmaydi.
	float a = sin(t) * 0.95;
	float c = cos(a);
	float s = sin(a);
	VERTEX.xz = vec2(c * VERTEX.x + s * VERTEX.z, -s * VERTEX.x + c * VERTEX.z);
	VERTEX.y += sin(t * 0.8) * bob_height;
}

void fragment() {
	// Metall emas: bu sahnada aks etadigan muhit yo'q, metall
	// qoralashib ketardi. O'rniga o'z nuri.
	ALBEDO = tint;
	METALLIC = 0.0;
	ROUGHNESS = 0.42;
	EMISSION = tint * 0.55;
}
"""

var _field: CoinField

func _ready() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Tangalarni joylaydi.
func build(field: CoinField) -> void:
	_field = field
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = THICK
	disc.radial_segments = 14
	disc.rings = 0
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = SHADER
	mat.set_shader_parameter("tint", Color("ffd23f"))
	disc.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = disc
	mm.instance_count = field.size()
	for i in field.size():
		mm.set_instance_transform(i, _at(i))
	multimesh = mm

## Olingan tangalarni yashiradi.
func take(indices: PackedInt32Array) -> void:
	if multimesh == null:
		return
	for i: int in indices:
		if i >= 0 and i < multimesh.instance_count:
			multimesh.set_instance_transform(i, Transform3D(
				Basis().scaled(Vector3.ZERO), Vector3.ZERO))

## Qayta paydo bo'lgan tangalarni o'z o'lchamiga qaytaradi.
func give_back(indices: PackedInt32Array) -> void:
	if multimesh == null:
		return
	for i: int in indices:
		if i >= 0 and i < multimesh.instance_count:
			multimesh.set_instance_transform(i, _at(i))

func _at(index: int) -> Transform3D:
	var coin: Dictionary = _field.coins[index]
	var radius: float = lerpf(MIN_RADIUS, MAX_RADIUS, float(coin["weight"]))
	# Tanga tik turadi: silindr o'qi X ga buriladi, shunda yassi
	# yuzlari oldinga qaraydi va aylanishi ko'rinadi.
	# Kamera pastga qarab turadi, shuning uchun tanga biroz orqaga
	# yotqiziladi — yuzi o'yinchiga qaraydi.
	var basis := Basis(Vector3.RIGHT, PI * 0.5 - 0.55).scaled(
		Vector3(radius, 1.0, radius))
	return Transform3D(basis, Vector3(
		coin["x"], ArenaBuilder.LAND_HEIGHT + HEIGHT, coin["y"]))
