class_name ArenaBuilder
extends RefCounted

## Dunyo xaritasidan 3D arena geometriyasini quradi.
##
## Quruqlik — okean sathidan [LAND_HEIGHT] ga ko'tarilgan plato:
##  * ustki yuza — qatorlar bo'ylab birlashtirilgan to'rtburchaklar
##    (greedy meshing), har katakka alohida kvadrat chizilmaydi;
##  * yon devorlar — faqat quruqlik/suv chegarasidagi qirralar.
##
## Natijada 520x205 xarita bir necha ming uchburchakka tushadi va
## statik mesh sifatida bir marta quriladi.

## Quruqlikning okean sathidan balandligi (dunyo birligi).
const LAND_HEIGHT := 1.6

## Natija: {"mesh": ArrayMesh, "quads": int}
static func build(grid: GameGrid) -> Dictionary:
	var top := SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side := SurfaceTool.new()
	side.begin(Mesh.PRIMITIVE_TRIANGLES)

	var quads := 0
	var w := grid.width
	var h := grid.height

	# ——— Ustki yuza: qatordagi ketma-ket quruqlik kataklari bitta
	# to'rtburchakka birlashtiriladi. UV butun xaritaga nisbatan, shuning
	# uchun egalik teksturasi aniq ustiga tushadi.
	for y in h:
		var x := 0
		while x < w:
			if not grid.is_land(x, y):
				x += 1
				continue
			var end := x
			while end < w and grid.is_land(end, y):
				end += 1
			_add_top_quad(top, x, y, end, y + 1, w, h)
			quads += 1
			x = end

	# ——— Yon devorlar: quruqlik katagining suvga (yoki xarita chetiga)
	# qaragan har bir qirrasi.
	for y in h:
		for x in w:
			if not grid.is_land(x, y):
				continue
			if not grid.is_land(x, y - 1):
				_add_wall(side, Vector2(x, y), Vector2(x + 1, y))
				quads += 1
			if not grid.is_land(x, y + 1):
				_add_wall(side, Vector2(x + 1, y + 1), Vector2(x, y + 1))
				quads += 1
			if not grid.is_land(x - 1, y):
				_add_wall(side, Vector2(x, y + 1), Vector2(x, y))
				quads += 1
			if not grid.is_land(x + 1, y):
				_add_wall(side, Vector2(x + 1, y), Vector2(x + 1, y + 1))
				quads += 1

	# Ustki yuzaning normali aniq yuqoriga qaraydi — `generate_normals()`
	# uni uchburchak aylanish yo'nalishidan hisoblab, teskari qilib
	# qo'yishi mumkin.
	side.generate_normals()
	var mesh: ArrayMesh = top.commit()
	side.commit(mesh)
	return {"mesh": mesh, "quads": quads}

static func _add_top_quad(st: SurfaceTool, x0: int, y0: int, x1: int, y1: int,
		w: int, h: int) -> void:
	var a := Vector3(x0, LAND_HEIGHT, y0)
	var b := Vector3(x1, LAND_HEIGHT, y0)
	var c := Vector3(x1, LAND_HEIGHT, y1)
	var d := Vector3(x0, LAND_HEIGHT, y1)
	var ua := Vector2(float(x0) / w, float(y0) / h)
	var ub := Vector2(float(x1) / w, float(y0) / h)
	var uc := Vector2(float(x1) / w, float(y1) / h)
	var ud := Vector2(float(x0) / w, float(y1) / h)
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
