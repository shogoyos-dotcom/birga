class_name ArenaBuilder
extends RefCounted

## Tayyor geometriyadan 3D arena quradi.
##
## Shakl generatorda hisoblanadi: quruqlikning uzluksiz maydoni
## 0.5 sathida kesiladi (marching squares) va chiziqli interpolatsiya
## tufayli chegara katakka yopishmaydi. Shuning uchun bu yerda faqat
## tayyor uchburchaklar va devor kesmalari meshga ko\'chiriladi —
## hech qanday katak aylanishi yo\'q, yuklash tez.

## Quruqlikning okean sathidan balandligi (dunyo birligi).
const LAND_HEIGHT := 1.6

## Natija: {"mesh": ArrayMesh, "quads": int}
static func build(map: WorldMap) -> Dictionary:
	var mesh := ArrayMesh.new()
	var tri_count: int = map.top_points.size() / 3
	var wall_count: int = map.wall_points.size() / 2

	# ——— Ustki yuza. UV o\'yin panjarasiga nisbatan: egalik teksturasi
	# aynan ustiga tushadi.
	var top := PackedVector3Array()
	var top_uv := PackedVector2Array()
	var top_normal := PackedVector3Array()
	top.resize(map.top_points.size())
	top_uv.resize(map.top_points.size())
	top_normal.resize(map.top_points.size())
	var scale := Vector2(1.0 / map.width, 1.0 / map.height)
	for i in map.top_points.size():
		var p := map.top_points[i]
		top[i] = Vector3(p.x, LAND_HEIGHT, p.y)
		top_uv[i] = p * scale
		top_normal[i] = Vector3.UP

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = top
	arrays[Mesh.ARRAY_TEX_UV] = top_uv
	arrays[Mesh.ARRAY_NORMAL] = top_normal
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	# ——— Yon devorlar: har kesma okean sathigacha tushadigan
	# to\'rtburchak. Normal gorizontal, shuning uchun devor to\'q
	# ko\'rinadi va plato hajmli bo\'lib turadi.
	var side := PackedVector3Array()
	var side_normal := PackedVector3Array()
	var side_uv := PackedVector2Array()
	side.resize(wall_count * 6)
	side_normal.resize(wall_count * 6)
	side_uv.resize(wall_count * 6)
	for k in wall_count:
		var a := map.wall_points[k * 2]
		var b := map.wall_points[k * 2 + 1]
		var dir := b - a
		var normal := Vector3(dir.y, 0.0, -dir.x).normalized()
		var top_a := Vector3(a.x, LAND_HEIGHT, a.y)
		var top_b := Vector3(b.x, LAND_HEIGHT, b.y)
		var low_a := Vector3(a.x, 0.0, a.y)
		var low_b := Vector3(b.x, 0.0, b.y)
		var at := k * 6
		var corners := [top_a, top_b, low_b, top_a, low_b, low_a]
		for i in 6:
			side[at + i] = corners[i]
			side_normal[at + i] = normal
			side_uv[at + i] = Vector2.ZERO

	var wall_arrays := []
	wall_arrays.resize(Mesh.ARRAY_MAX)
	wall_arrays[Mesh.ARRAY_VERTEX] = side
	wall_arrays[Mesh.ARRAY_NORMAL] = side_normal
	wall_arrays[Mesh.ARRAY_TEX_UV] = side_uv
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, wall_arrays)

	return {"mesh": mesh, "quads": tri_count + wall_count}
