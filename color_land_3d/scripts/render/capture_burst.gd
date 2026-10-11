extends CPUParticles3D

## Hudud egallaganda chiqadigan effekt.
##
## Do'kondagi "Effektlar" bo'limi shu tugunni sozlaydi. Effekt
## tanlanmagan bo'lsa tugun umuman ishlamaydi — zarracha yo'q,
## hisob-kitob ham yo'q.
##
## Effekt o'yin qoidalariga tegmaydi: u hodisa **sodir bo'lgandan
## keyin** chiqadi va hech narsani o'zgartirmaydi.
##
## `CPUParticles3D` ataylab tanlangan: GPU zarrachalari har
## chizuvchida bir xil ishlamaydi (moslashuvchan OpenGL rejimida
## ular umuman chiqmadi), 40 ta zarracha esa protsessor uchun
## sezilarli yuk emas.

var _enabled := false

func _ready() -> void:
	emitting = false
	one_shot = true
	explosiveness = 1.0
	local_coords = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bit := QuadMesh.new()
	bit.size = Vector2(0.42, 0.42)
	mesh = bit

## Do'kondan tanlangan effektni o'rnatadi.
func apply_cosmetics(tint: Color) -> void:
	# Avtoyuklangan nom `--script` rejimida yo'q — daraxtdan olinadi.
	var shop := get_node_or_null("/root/Shop")
	var id := "fx_none"
	if shop != null:
		id = str(shop.worn_in(ShopManager.EFFECTS))
	var look := Cosmetics.effect(id)
	_enabled = int(look["count"]) > 0
	if not _enabled:
		emitting = false
		return
	amount = int(look["count"])
	lifetime = float(look["life"])

	var fly := float(look["fly"])
	initial_velocity_min = fly * 0.6
	initial_velocity_max = fly
	emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 0.4
	if bool(look["ring"]):
		# To'lqin: zarrachalar hamma tomonga, lekin faqat yer
		# tekisligi bo'ylab uchadi (`flatness`).
		direction = Vector3.RIGHT
		spread = 180.0
		flatness = 1.0
		gravity = Vector3.ZERO
	else:
		# Konfetti: yuqoriga sochiladi va pastga tushadi.
		direction = Vector3.UP
		spread = 55.0
		flatness = 0.0
		gravity = Vector3(0.0, -14.0, 0.0)
	scale_amount_min = 0.6
	scale_amount_max = 1.3
	angle_min = -180.0
	angle_max = 180.0
	angular_velocity_min = -320.0
	angular_velocity_max = 320.0

	var draw := StandardMaterial3D.new()
	draw.albedo_color = tint
	draw.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_override = draw

## Berilgan nuqtada bir marta portlaydi.
func burst(at: Vector3) -> void:
	if not _enabled:
		return
	global_position = at
	restart()
	emitting = true
