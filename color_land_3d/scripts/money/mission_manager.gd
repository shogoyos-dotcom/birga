class_name MissionManager
extends Node

const SavePaths := preload("res://scripts/app/save_paths.gd")

## Kunlik topshiriqlar.
##
## Har kuni uchta topshiriq beriladi. Ro'yxat sanadan kelib chiqib
## tanlanadi, shuning uchun ilova qayta ochilsa ham o'sha kuni
## o'zgarmaydi va o'yinchi "yangilash" bilan osonini tanlay olmaydi.

const PATH := "user://missions.cfg"
const SECTION := "missions"
## Bir kunda nechta topshiriq.
const PER_DAY := 3

signal changed()

## Topshiriq turlari: har biri o'yin oxirida bir marta hisoblanadi.
const POOL: Array[Dictionary] = [
	{"id": "percent10", "kind": "percent", "target": 10, "reward": 250},
	{"id": "percent25", "kind": "percent", "target": 25, "reward": 600},
	{"id": "kills2", "kind": "kills", "target": 2, "reward": 300},
	{"id": "kills5", "kind": "kills", "target": 5, "reward": 700},
	{"id": "matches3", "kind": "matches", "target": 3, "reward": 200},
	{"id": "captures5", "kind": "captures", "target": 5, "reward": 350},
	{"id": "survive120", "kind": "survive", "target": 120, "reward": 400},
	{"id": "coins150", "kind": "coins", "target": 150, "reward": 300},
]

var _file_path: String = ""
var _config := ConfigFile.new()
var _day := ""
## id -> yig'ilgan qiymat.
var _progress: Dictionary = {}
## Mukofoti olingan topshiriqlar.
var _done: Dictionary = {}

func _init(custom_path: String = "") -> void:
	if not custom_path.is_empty():
		_file_path = custom_path
	_load()

func get_file_path() -> String:
	if not _file_path.is_empty():
		return _file_path
	return SavePaths.path_for(SavePaths.MISSIONS)

func set_file_path(path: String) -> void:
	_file_path = path
	_load()

func _load() -> void:
	_config = ConfigFile.new()
	var path := get_file_path()
	if FileAccess.file_exists(path):
		_config.load(path)
	_day = str(_config.get_value(SECTION, "day", ""))
	var p: Variant = _config.get_value(SECTION, "progress", {})
	_progress = (p as Dictionary).duplicate() if p is Dictionary else {}
	var d: Variant = _config.get_value(SECTION, "done", {})
	_done = (d as Dictionary).duplicate() if d is Dictionary else {}
	refresh()

## Kun almashgan bo'lsa yangi topshiriqlar beriladi.
func refresh() -> void:
	var today := DailyRewardManager.today()
	if _day == today:
		return
	_day = today
	_progress.clear()
	_done.clear()
	_save()
	changed.emit()

## Bugungi uchta topshiriq, har biri:
## {id, kind, target, reward, progress, completed}.
func today_missions() -> Array[Dictionary]:
	var picked := _pick_for(_day)
	var out: Array[Dictionary] = []
	for item: Dictionary in picked:
		var id := str(item["id"])
		out.append({
			"id": id, "kind": item["kind"], "target": int(item["target"]),
			"reward": int(item["reward"]),
			"progress": mini(int(_progress.get(id, 0)), int(item["target"])),
			"completed": bool(_done.get(id, false)),
		})
	return out

## Sanadan kelib chiqib uchta topshiriq tanlaydi — har kuni boshqa,
## lekin o'sha kun davomida o'zgarmas.
static func _pick_for(day: String) -> Array[Dictionary]:
	var seed_value := int(day.replace("-", ""))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var order: Array[int] = []
	for i in POOL.size():
		order.append(i)
	# Fisher-Yates: ro'yxat sanaga bog'liq holda aralashtiriladi.
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := order[i]
		order[i] = order[j]
		order[j] = tmp
	var out: Array[Dictionary] = []
	for k in mini(PER_DAY, order.size()):
		out.append(POOL[order[k]])
	return out

## O'yin natijasini hisobga qo'shadi. Bajarilgan topshiriqlar
## ro'yxatini qaytaradi.
func report(percent: float, kills: int, captures: int, seconds: float,
		coins: int) -> Array[Dictionary]:
	refresh()
	var values := {
		"percent": int(floor(percent)), "kills": kills,
		"matches": 1, "captures": captures,
		"survive": int(floor(seconds)), "coins": coins,
	}
	var finished: Array[Dictionary] = []
	for mission: Dictionary in today_missions():
		if bool(mission["completed"]):
			continue
		var id := str(mission["id"])
		var kind := str(mission["kind"])
		var add := int(values.get(kind, 0))
		if add <= 0:
			continue
		# "matches" va "captures" to'planadi, qolgani eng yaxshisi.
		var have := int(_progress.get(id, 0))
		var now: int = have + add if kind in ["matches", "captures", "coins"] \
			else maxi(have, add)
		_progress[id] = now
		if now >= int(mission["target"]):
			_done[id] = true
			var reward := int(mission["reward"])
			_wallet().add_coins(reward, "mission", "mission-%s-%s" % [_day, id])
			_metrics().send(Analytics.MISSION_COMPLETED,
				{"mission": id, "reward": reward})
			finished.append(mission)
	_save()
	if not finished.is_empty():
		changed.emit()
	return finished

func reset() -> void:
	_day = ""
	_progress.clear()
	_done.clear()
	_save()
	refresh()

func _save() -> void:
	_config.set_value(SECTION, "day", _day)
	_config.set_value(SECTION, "progress", _progress)
	_config.set_value(SECTION, "done", _done)
	var path := get_file_path()
	SavePaths.ensure_dir_exists(path.get_base_dir())
	_config.save(path)

# ——— Qo'shni modullar ———
#
# Avtoyuklangan modullar bir-birini **kompilyatsiya paytida**
# ko'rmaydi (`--script` rejimida global nom hali yo'q), shuning
# uchun ular daraxtdan ish paytida olinadi.

func _wallet() -> CurrencyManager:
	return get_node("/root/Wallet") as CurrencyManager

func _metrics() -> Analytics:
	return get_node("/root/Metrics") as Analytics
