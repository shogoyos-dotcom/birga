class_name ArenaBuilder
extends RefCounted

## Maydon niqobidan 3D arena geometriyasini quradi.
##
## Quruqlik — okean sathidan [LAND_HEIGHT] ga ko'tarilgan plato:
##  * ustki yuza — qatorlar bo'ylab birlashtirilgan to'rtburchaklar
##    (greedy meshing), har katakka alohida kvadrat chizilmaydi;
##  * yon devorlar — faqat quruqlik/suv chegarasidagi qirralar.
##
## Geometriya **chizish niqobidan** quriladi: u o'yin panjarasidan uch
## barobar maydaroq va silliqlangan, shuning uchun qirg'oq zinapoya
## bo'lib ko'rinmaydi. Mantiq esa o'zining dag'alroq niqobi bilan
## ishlaydi — o'yin qoidalari o'zgarmaydi.

## Quruqlikning okean sathidan balandligi (dunyo birligi).
const LAND_HEIGHT := 1.6

## Natija: {"mesh": ArrayMesh, "quads": int}
##
## `cell` — chizish niqobining bitta katagi dunyoda necha birlik
## (1/scale). UV esa o'yin panjarasiga nisbatan hisoblanadi, shunda
## egalik teksturasi aniq ustiga tushadi.
static func build(map: WorldMap) -> Dictionary:
	var mask := map.render_land
	var w := map.render_width
	var h := map.render_height
	var cell := 1.0 / float(maxi(map.scale, 1))

	var top := SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side := SurfaceTool.new()
	side.begin(Mesh.PRIMITIVE_TRIANGLES)

	var quads := 0

	# ——— Ustki yuza: qatordagi ketma-ket quruqlik kataklari bitta
	# to'rtburchakka birlashtiriladi.
	for y in h:
		var row := y * w
		var x := 0
		while x < w:
			if mask[row + x] == 0:
				x += 1
				continue
			var end := x
			while end < w and mask[row + end] == 1:
				end += 1
			_add_top_quad(top, x * cell, y * cell, end * cell, (y + 1) * cell,
				map.width, map.height)
			quads += 1
			x = end

	# ——— Yon devorlar: quruqlik katagining suvga (yoki chetga) qaragan
	# har bir qirrasi.
	for y in h:
		var row := y * w
		for x in w:
			if mask[row + x] == 0:
				continue
			var left := x * cell
			var top_edge := y * cell
			var right := (x + 1) * cell
			var bottom := (y + 1) * cell
			if not _is_land(mask, w, h, x, y - 1):
				_add_wall(side, Vector2(left, top_edge), Vector2(right, top_edge))
				quads += 1
			if not _is_land(mask, w, h, x, y + 1):
				_add_wall(side, Vector2(right, bottom), Vector2(left, bottom))
				quads += 1
			if not _is_land(mask, w, h, x - 1, y):
				_add_wall(side, Vector2(left, bottom), Vector2(left, top_edge))
				quads += 1
			if not _is_land(mask, w, h, x + 1, y):
				_add_wall(side, Vector2(right, top_edge), Vector2(right, bottom))
				quads += 1

	# Ustki yuzaning normali aniq yuqoriga qaraydi — `generate_normals()`
	# uni uchburchak aylanish yo'nalishidan hisoblab, teskari qilib
	# qo'yishi mumkin.
	side.generate_normals()
	var mesh: ArrayMesh = top.commit()
	side.commit(mesh)
	return {"mesh": mesh, "quads": quads}

static func _is_land(mask: PackedByteArray, w: int, h: int,
		x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= w or y >= h:
		return false
	return mask[y * w + x] == 1

static func _add_top_quad(st: SurfaceTool, x0: float, y0: float,
		x1: float, y1: float, w: int, h: int) -> void:
	var a := Vector3(x0, LAND_HEIGHT, y0)
	var b := Vector3(x1, LAND_HEIGHT, y0)
	var c := Vector3(x1, LAND_HEIGHT, y1)
	var d := Vector3(x0, LAND_HEIGHT, y1)
	var ua := Vector2(x0 / w, y0 / h)
	var ub := Vector2(x1 / w, y0 / h)
	var uc := Vector2(x1 / w, y1 / h)
	var ud := Vector2(x0 / w, y1 / h)
	# Aylanish yo'nalishi: yuqoridan qaraganda old tomon bo'lsin, aks
	# holda yuza kesib tashlanadi va faqat okean ko'rinadi.
	st.set_normal(Vector3.UP)
	_tri(st, a, ua, b, ub, c, uc)
	_tri(st, a, ua, c, uc, d, ud)

static func _add_wall(st: SurfaceTool, from: Vector2, to: Vector2) -> void:
	var a := Vector3(from.x, LAND_HEIGHT, from.y)
	var b := Vector3(to.x, LAND_HEIGHT, to.y)
	var c := Vector3(to.x, 0.0, to.y)
	var d := Vector3(from.x, 0.0, from.y)
	# Devorda tekstura kerak emas — UV bir nuqtaga yig'iladi.
	var uv := Vector2(0.0, 0.0)
	_tri(st, a, uv, b, uv, c, uv)
	_tri(st, a, uv, c, uv, d, uv)

static func _tri(st: SurfaceTool, p0: Vector3, u0: Vector2,
		p1: Vector3, u1: Vector2, p2: Vector3, u2: Vector2) -> void:
	st.set_uv(u0)
	st.add_vertex(p0)
	st.set_uv(u1)
	st.add_vertex(p1)
	st.set_uv(u2)
	st.add_vertex(p2)
