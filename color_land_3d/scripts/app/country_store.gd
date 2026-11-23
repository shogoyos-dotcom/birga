class_name CountryStore
extends Node

## O'yinchining mamlakatlar yo'lidagi o'rni.
##
## Har o'yin oxirida ochko qo'shiladi; nishonga yetganda navbatdagi
## mamlakatga o'tiladi. Ortib qolgan ochko yo'qolmaydi — keyingi
## mamlakatga o'tadi, shunda yaxshi o'yin bekorga ketmaydi.

const FILE := "user://journey.cfg"
const SECTION := "journey"

signal changed()

## [{code, name, goal, rings}] — tartibi faylda belgilangan.
var countries: Array = []

var _index := 0
var _points := 0
var _config := ConfigFile.new()

func _init() -> void:
	countries = CountryPath.load_all()
	_config.load(FILE)
	_index = clampi(int(_config.get_value(SECTION, "index", 0)),
		0, maxi(countries.size() - 1, 0))
	_points = maxi(int(_config.get_value(SECTION, "points", 0)), 0)

## Hozirgi mamlakat. Ro'yxat bo'sh bo'lsa — bo'sh lug'at.
func current() -> Dictionary:
	if countries.is_empty():
		return {}
	return countries[_index]

func index() -> int:
	return _index

func points() -> int:
	return _points

func goal() -> int:
	var row := current()
	return 1 if row.is_empty() else maxi(int(row.get("goal", 1)), 1)

## 0..100.
func percent() -> float:
	return clampf(float(_points) * 100.0 / float(goal()), 0.0, 100.0)

## Nechta mamlakat butunlay egallangan.
func done_count() -> int:
	return _index

## O'yin natijasini qo'shadi.
##
## Natija: {"gained": ochko, "done": [kod, ...], "percent": 0..100}.
## `done` — shu o'yinda tugatilgan mamlakatlar (bittadan ko'p
## bo'lishi mumkin: juda yaxshi o'yin ikkitasini birdan yopadi).
func report(percent_owned: float, kills: int) -> Dictionary:
	var gained := CountryPath.points_for(percent_owned, kills)
	return add(gained)

func add(gained: int) -> Dictionary:
	var done: Array = []
	if countries.is_empty() or gained <= 0:
		return {"gained": 0, "done": done, "percent": percent()}
	_points += gained
	while _index < countries.size() - 1 and _points >= goal():
		_points -= goal()
		done.append(str(current().get("code", "")))
		_index += 1
	# Oxirgi mamlakatda ochko to'planaveradi, lekin foiz 100 da
	# to'xtaydi — yo'l tugagani ko'rinib tursin.
	if _index == countries.size() - 1 and _points >= goal():
		if not done.has(str(current().get("code", ""))):
			done.append(str(current().get("code", "")))
		_points = goal()
	_save()
	changed.emit()
	return {"gained": gained, "done": done, "percent": percent()}

func reset() -> void:
	_index = 0
	_points = 0
	_save()
	changed.emit()

func _save() -> void:
	_config.set_value(SECTION, "index", _index)
	_config.set_value(SECTION, "points", _points)
	_config.save(FILE)
