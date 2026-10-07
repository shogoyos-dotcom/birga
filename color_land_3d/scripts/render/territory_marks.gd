extends Node3D

## Hudud ustidagi avatar naqshi: har o'yinchining bayrog'i yoki emojisi
## o'z hududining hamma yeriga takrorlanadi.
##
## Joylashuvni [MarkLayout] hisoblaydi; bu yerda faqat `Label3D` lar
## qayta ishlatiladi — har yangilanishda yangi tugun yaratilmaydi.

## Naqsh sekundda shuncha marta qayta hisoblanadi.
const REFRESH := 0.3

## Ekrandagi belgilarning umumiy chegarasi.
const MAX_TOTAL := 240

## Belgi quruqlik sathidan shu qadar yuqorida — arena yuzasi bilan
## z-fighting bo'lmasin.
const LIFT := 0.08

## Shrift o'lchami: `pixel_size` shundan kelib chiqib hisoblanadi.
const FONT_SIZE := 64

var enabled := true:
	set(value):
		enabled = value
		visible = value

var _world: GameWorld
var _pool: Array[Label3D] = []
var _timer := 0.0

func setup(world: GameWorld) -> void:
	_world = world
	_timer = 0.0
	refresh()

func _process(delta: float) -> void:
	if _world == null or not enabled:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = REFRESH
		refresh()

func refresh() -> void:
	if _world == null:
		return
	var used := 0
	for p in _world.players:
		if not p.alive or used >= MAX_TOTAL:
			continue
		var plan := MarkLayout.plan(_world.grid, p.id)
		var points: PackedVector2Array = plan["points"]
		if points.is_empty():
			continue
		var glyph := Profile.map_glyph(p.avatar)
		var step := float(plan["step"])
		for point in points:
			if used >= MAX_TOTAL:
				break
			_apply(_label(used), glyph, step, point)
			used += 1

	# Ortib qolgan belgilar o'chiriladi (tugunlar saqlanadi).
	for i in range(used, _pool.size()):
		_pool[i].visible = false

func _apply(node: Label3D, glyph: String, step: float,
		point: Vector2) -> void:
	node.visible = true
	node.text = glyph
	node.pixel_size = step * 0.62 / float(FONT_SIZE)
	node.position = Vector3(point.x, ArenaBuilder.LAND_HEIGHT + LIFT, point.y)

func _label(index: int) -> Label3D:
	while _pool.size() <= index:
		var node := Label3D.new()
		node.font_size = FONT_SIZE
		# Yotgan holatda: belgi quruqlik yuzasiga yopishib turadi.
		node.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		node.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		node.double_sided = false
		# Shaffoflik tartiblanmasin: belgilar bir sathda yotadi va
		# saralash xatosi mobil qurilmada miltillashga olib keladi.
		node.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		node.modulate = Color(1.0, 1.0, 1.0, 0.95)
		node.shaded = false
		node.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		# Bayroqlar uchun emoji shrifti bevosita kerak (zaxira orqali
		# ikki belgi qo'shilib bayroqqa aylanmaydi).
		var font := UiKit.emoji_font()
		if font != null:
			node.font = font
		add_child(node)
		_pool.append(node)
	return _pool[index]
