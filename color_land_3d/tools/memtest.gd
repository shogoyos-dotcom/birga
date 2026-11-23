extends SceneTree

## Xotira va tugunlar sonini maydon bo'yicha o'lchaydi.

var _view: Node
var _at := 0
var _timer := 0.0
const ORDER: PackedStringArray = ["circle", "africa", "world"]

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")

func _process(delta: float) -> bool:
	if _view == null:
		_view = current_scene
		return false
	_timer -= delta
	if _timer > 0.0:
		return false
	_timer = 1.2
	if _at > 0:
		_report(ORDER[_at - 1])
	if _at >= ORDER.size():
		# Nomlarni o'chirib ko'ramiz.
		_view.store.show_city_names = false
		_view._apply_view_settings()
		await process_frame
		_report("world (nomsiz)")
		return true
	_view.set_map_for_demo(ORDER[_at])
	_at += 1
	return false

func _report(label: String) -> void:
	print("%-16s tugun %5d   xotira %6.1f MB   obyekt %5d   video %6.1f MB" % [
		label, _count(root),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.OBJECT_COUNT),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])

func _count(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count(child)
	return total
