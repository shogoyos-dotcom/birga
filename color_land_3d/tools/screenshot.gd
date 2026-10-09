extends SceneTree

## Sahnani bir necha soniya o'ynatib, PNG saqlaydi — qo'lda ko'rib
## tekshirish uchun. Konteynerda Vulkan yo'q, shuning uchun
## moslashuvchan (OpenGL) chizuvchi bilan ishga tushiriladi:
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --resolution 720x1280 \
##     --script res://tools/screenshot.gd -- 6 build/shot.png

var _frames_left := 0
var _out := "res://build/shot_3d.png"
var _seconds := 6.0
var _elapsed := 0.0
## "play" (standart), "menu", "settings", "profile", "pause", "shop",
## "result".
var _mode := "play"
## Tekshirish uchun avatar, masalan "flag:UZ".
var _avatar := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_seconds = float(args[0])
	if args.size() > 1:
		_out = args[1]
	if args.size() > 2:
		_mode = args[2]
	if args.size() > 3:
		_avatar = args[3]
	_frames_left = int(_seconds * 60.0)
	change_scene_to_file("res://scenes/main.tscn")

func _process(delta: float) -> bool:
	_elapsed += delta
	_drive()
	_frames_left -= 1
	if _frames_left > 0:
		return false
	var image := root.get_texture().get_image()
	var dir := _out.get_base_dir()
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var err := image.save_png(_out)
	print("skrinshot: %s (%s)" % [_out, "ok" if err == OK else "xato %d" % err])
	return true

## O'yinchini avtomatik yurgizadi: hududdan chiqib katta halqa chizadi
## va qaytadi — skrinshotda iz ham, egallangan hudud ham ko'rinsin.
func _drive() -> void:
	var view := current_scene
	if view == null or not view.has_method("steer_human"):
		return
	if not _avatar.is_empty() and view.has_method("set_avatar_for_demo"):
		view.set_avatar_for_demo(_avatar)
	if _mode != "play" and _mode != "trail":
		view.show_screen_for_demo(_mode)
		return
	view.start_for_demo()
	if _mode == "trail":
		# Diagonal to'g'ri chiziq — zinapoya eng yomon ko'rinadigan
		# holat; iz tekis chiqyaptimi, shu bilan tekshiriladi.
		view.steer_human(0.62)
		return
	# Keng, silliq halqa: radius = tezlik / burchak tezligi ~= 14 katak.
	# Keskin burilishda o'yinchi o'z izini kesib o'lib qoladi.
	view.steer_human(_elapsed * 0.55)
	# 15 ta bot ov qilayotgani uchun o'yinchi o'lib qolishi mumkin —
	# skrinshot davom etsin.
	view.revive_human_for_demo()
