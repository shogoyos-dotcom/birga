extends SceneTree

## Ikki jarayonli tarmoq sinovi:
##   godot --script res://tools/net_test.gd -- host 14
##   godot --script res://tools/net_test.gd -- client 127.0.0.1 12

var _role := "host"
var _address := "127.0.0.1"
var _seconds := 12.0
var _elapsed := 0.0
var _kicked := false
var _reported := 0.0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_role = args[0]
	if args.size() > 1:
		if _role == "client":
			_address = args[1]
		else:
			_seconds = float(args[1])
	if args.size() > 2:
		_seconds = float(args[2])
	change_scene_to_file("res://scenes/main.tscn")

func _process(delta: float) -> bool:
	_elapsed += delta
	var view := current_scene
	if view == null:
		return false
	if not _kicked and _elapsed > 1.0:
		_kicked = true
		if _role == "host":
			view._on_host()
			print("HOST: xona ochildi, o'yinchilar ", view.world.players.size())
		else:
			view._on_join(_address)
			print("CLIENT: ulanmoqda ", _address)
	if _elapsed - _reported > 3.0 and _kicked:
		_reported = _elapsed
		_report(view)
	if _elapsed < _seconds:
		return false
	_report(view)
	print("%s: tugadi" % _role.to_upper())
	return true

func _report(view: Node) -> void:
	if view.world == null:
		print("%s: dunyo yo'q" % _role.to_upper())
		return
	var p = view.world.human()
	var net := root.get_node_or_null("/root/Net")
	var roster: int = net.roster.size() if net != null else 0
	print("%s: o'yinchi %d/%d, mening ID %d, joy (%.1f, %.1f), hudud %d, egallangan %d" % [
		_role.to_upper(), view.world.players.size(), roster,
		p.id, p.x, p.y, view.world.grid.territory_of(p.id),
		_owned(view.world.grid)])

func _owned(grid: GameGrid) -> int:
	var total := 0
	for id in range(1, 40):
		total += grid.territory_of(id)
	return total
