class_name TestRunner
extends RefCounted

## Oddiy headless test yurituvchi.
##
## Godot'da o'rnatilgan test tizimi yo'q, lekin mantiq qatlami
## dvigatelga bog'liq emas — shuning uchun shunchaki chaqirib,
## natijani solishtirish kifoya. Ishga tushirish:
##   godot --headless --script res://tests/run_tests.gd

var _passed := 0
var _failed := 0
var _group := ""
var _test := ""
var _failures: Array[String] = []

func group(name: String) -> void:
	_group = name

func test(name: String, body: Callable) -> void:
	_test = name
	body.call()

func _fail(message: String) -> void:
	_failed += 1
	_failures.append("  %s / %s\n    %s" % [_group, _test, message])

func _ok() -> void:
	_passed += 1

func check(condition: bool, message: String = "") -> void:
	if condition:
		_ok()
	else:
		_fail("shart bajarilmadi" + ("" if message.is_empty() else ": " + message))

func equal(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual == expected:
		_ok()
	else:
		_fail("kutilgan %s, kelgan %s%s" % [
			expected, actual, "" if message.is_empty() else " (" + message + ")"])

func close_to(actual: float, expected: float, tol: float = 0.001,
		message: String = "") -> void:
	if absf(actual - expected) <= tol:
		_ok()
	else:
		_fail("kutilgan ~%s, kelgan %s%s" % [
			expected, actual, "" if message.is_empty() else " (" + message + ")"])

func greater(actual: Variant, than: Variant, message: String = "") -> void:
	if actual > than:
		_ok()
	else:
		_fail("%s > %s bo'lishi kerak edi%s" % [
			actual, than, "" if message.is_empty() else " (" + message + ")"])

func less(actual: Variant, than: Variant, message: String = "") -> void:
	if actual < than:
		_ok()
	else:
		_fail("%s < %s bo'lishi kerak edi%s" % [
			actual, than, "" if message.is_empty() else " (" + message + ")"])

## Natijani chop etadi; hamma test o'tgan bo'lsa `true`.
func report() -> bool:
	print("")
	if _failed == 0:
		print("Hammasi o'tdi: %d ta tekshiruv" % _passed)
		return true
	print("XATO: %d ta tekshiruv o'tmadi (%d ta o'tdi)" % [_failed, _passed])
	for f in _failures:
		print(f)
	return false
