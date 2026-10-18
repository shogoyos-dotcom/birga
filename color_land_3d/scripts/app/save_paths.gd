class_name SavePaths
extends RefCounted

## Color Land 3D — Markaziy Saqlash Yo'llari va Test Ma'lumotlari Izolyatsiyasi (Phase 8 Final)
##
## Barcha doimiy ma'lumotlar (user://*.cfg va rasmlar) yo'llarini markazlashgan
## tarzda boshqaradi. Testlar vaqtida real o'yinchi fayllarini (wallet.cfg, shop.cfg,
## daily.cfg, journey.cfg va boshqalar) 100% himoya qilish uchun jarayon darajasida
## `user://test_sandbox/` xavfsiz izolyatsiyalangan muhitga yo'naltiradi.

const WALLET := "wallet.cfg"
const SHOP := "shop.cfg"
const DAILY := "daily.cfg"
const MISSIONS := "missions.cfg"
const PURCHASES := "purchases.cfg"
const UPGRADES := "upgrades.cfg"
const JOURNEY := "journey.cfg"
const SETTINGS := "settings.cfg"
const ACTIVE_MATCH_REWARDS := "active_match_rewards.cfg"
const AVATAR := "avatar.png"
const FLAG := "flag.png"

const ALL_PERSISTENT_FILES: PackedStringArray = [
	WALLET,
	SHOP,
	DAILY,
	MISSIONS,
	PURCHASES,
	UPGRADES,
	JOURNEY,
	SETTINGS,
	ACTIVE_MATCH_REWARDS,
	AVATAR,
	FLAG,
]

static var _is_test_mode: bool = _auto_detect_test_mode()
static var _test_dir: String = "user://test_sandbox/"
static var _custom_paths: Dictionary = {}

static func _auto_detect_test_mode() -> bool:
	if OS.has_environment("COLOR_LAND_TEST_MODE"):
		var env := OS.get_environment("COLOR_LAND_TEST_MODE").strip_edges()
		if env == "1" or env.to_lower() == "true":
			return true
	for arg: String in OS.get_cmdline_args():
		if "run_tests" in arg or "test_runner" in arg or "tests/" in arg:
			return true
	return false

static func is_test_mode() -> bool:
	return _is_test_mode

static func set_test_mode(enabled: bool, test_dir: String = "user://test_sandbox/") -> void:
	_is_test_mode = enabled
	_test_dir = test_dir if test_dir.ends_with("/") else test_dir + "/"
	if enabled:
		ensure_dir_exists(_test_dir)

static func get_test_dir() -> String:
	return _test_dir

static func path_for(filename: String) -> String:
	if _custom_paths.has(filename):
		return str(_custom_paths[filename])
	if _is_test_mode:
		ensure_dir_exists(_test_dir)
		return _test_dir + filename
	return "user://" + filename

static func resolve_path(filename: String) -> String:
	return path_for(filename)

static func set_custom_path(filename: String, path: String) -> void:
	_custom_paths[filename] = path

static func clear_custom_paths() -> void:
	_custom_paths.clear()

static func ensure_dir_exists(dir_path: String) -> void:
	var global_dir := ProjectSettings.globalize_path(dir_path)
	if not DirAccess.dir_exists_absolute(global_dir):
		DirAccess.make_dir_recursive_absolute(global_dir)

## Faqat test_sandbox ichidagi fayllarni tozalaydi. Hech qachon user:// ildizidagi fayllarga tegmaydi.
static func cleanup_test_data() -> void:
	var global_test_dir := ProjectSettings.globalize_path(_test_dir)
	if not DirAccess.dir_exists_absolute(global_test_dir):
		return
	var d := DirAccess.open(_test_dir)
	if d != null:
		d.list_dir_begin()
		var file_name := d.get_next()
		while not file_name.is_empty():
			if not d.current_is_dir():
				DirAccess.remove_absolute(ProjectSettings.globalize_path(_test_dir + file_name))
			file_name = d.get_next()
		d.list_dir_end()
	DirAccess.remove_absolute(global_test_dir)

static func compute_file_hash(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var bytes := f.get_buffer(f.get_length())
	f.close()
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return ctx.finish().hex_encode()

## Ishlab chiqarish fayllarining (user://) joriy holatidan SHA-256 xesh nusxasini oladi.
static func snapshot_production_hashes() -> Dictionary:
	var snapshot: Dictionary = {}
	for fname: String in ALL_PERSISTENT_FILES:
		var prod_path := "user://" + fname
		snapshot[fname] = {
			"exists": FileAccess.file_exists(prod_path),
			"hash": compute_file_hash(prod_path)
		}
	return snapshot

## Ishlab chiqarish fayllari testlar davomida o'zgarmaganligini qat'iy tekshiradi.
static func verify_production_hashes(snapshot: Dictionary) -> Dictionary:
	var mismatches: Array[String] = []
	for fname: String in ALL_PERSISTENT_FILES:
		var prod_path := "user://" + fname
		var expected: Dictionary = snapshot.get(fname, {"exists": false, "hash": ""})
		var now_exists := FileAccess.file_exists(prod_path)
		var now_hash := compute_file_hash(prod_path)

		if bool(expected["exists"]) != now_exists:
			mismatches.append("%s mavjudlik holati o'zgardi (oldin: %s, hozir: %s)" % [
				fname, expected["exists"], now_exists])
		elif bool(expected["exists"]) and str(expected["hash"]) != now_hash:
			mismatches.append("%s mazmuni o'zgardi! (oldingi xesh: %s, hozirgi xesh: %s)" % [
				fname, expected["hash"], now_hash])

	return {
		"ok": mismatches.is_empty(),
		"mismatches": mismatches
	}
