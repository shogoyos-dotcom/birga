class_name CitySystem
extends RefCounted

## Color Land 3D — Markaziy 3D Shaharlar va Hududiy Istilo Tizimi (Phase 5)
##
## 249 ta davlatning barcha shaharlarini boshqaradi, ularni 3 toifaga
## (Kichik, O'rta, Katta) ajratadi, hududiy halqa bilan egallanishini
## O(1) tezlikda hisoblaydi va bayroqlar bilan integratsiya qiladi.

const CityNames = preload("res://scripts/app/city_names.gd")
const RewardManager = preload("res://scripts/money/reward_manager.gd")
const MonetizationConfig = preload("res://scripts/money/monetization_config.gd")
const Profile = preload("res://scripts/app/profile.gd")

enum Category {
	SMALL = 0,
	MEDIUM = 1,
	LARGE = 2,
}

class CityData:
	var id: int = 0
	var stable_id: String = ""
	var name: String = ""
	var display_name: String = ""
	var country_code: String = ""
	var country_name: String = ""
	var x: int = 0
	var y: int = 0
	var pos: Vector2 = Vector2.ZERO
	var pop: int = 0
	var capital: bool = false
	var category: int = Category.SMALL
	var owner_id: int = 0 # 0 = neytral, >0 = o'yinchi yoki bot id
	var owner_country: String = ""
	var owner_name: String = ""
	var capture_time: float = 0.0
	var regional_style: String = "default"
	var reward_coins: int = 50
	var weight: float = 0.0
	var rank: float = 0.0
	var neighbor_dist: float = 999.0

	func is_captured() -> bool:
		return owner_id > 0

	func is_owned_by(player_id: int) -> bool:
		return owner_id == player_id

	func get_conquest_reward() -> int:
		return MonetizationConfig.get_city_capture_reward(category)

	func category_name() -> String:
		match category:
			Category.LARGE: return "Katta shahar"
			Category.MEDIUM: return "O'rta shahar"
			_: return "Kichik shahar"

	func category_badge() -> String:
		match category:
			Category.LARGE: return "★ KATTA METROPOL"
			Category.MEDIUM: return "◆ O'RTA SHAHAR"
			_: return "● KICHIK QISHLOQ"

var cities: Array[CityData] = []
var _by_cell: Dictionary = {} # cell_index (int) -> CityData
var _by_id: Dictionary = {} # id (int) -> CityData
var _player_captured_counts: Dictionary = {} # player_id (int) -> int
var _total_count: int = 0
var _grid_width: int = 0
var _grid_height: int = 0

## Xaritadagi barcha shaharlarni yuklaydi va indekslaydi.
func build(places: Array, grid: GameGrid) -> void:
	cities.clear()
	_by_cell.clear()
	_by_id.clear()
	_player_captured_counts.clear()

	_grid_width = grid.width
	_grid_height = grid.height

	var top_pop := 1.0
	for c: Dictionary in places:
		if grid.playable(int(c.get("x", -1)), int(c.get("y", -1))):
			top_pop = maxf(top_pop, float(c.get("pop", 0)))

	var next_id := 1
	for c: Dictionary in places:
		var x := int(c.get("x", -1))
		var y := int(c.get("y", -1))
		if not grid.playable(x, y):
			continue

		var raw_name: String = str(c.get("name", ""))
		var code: String = str(c.get("code", "")).to_upper()
		var pop: int = int(c.get("pop", 0))
		var capital: bool = int(c.get("cap", 0)) == 1

		# Aholi bo'yicha vazn (0..1)
		var weight := clampf(sqrt(float(pop) / top_pop), 0.0, 1.0)
		var rank := weight + (1.0 if capital else 0.0)

		# 3 toifaga ajratish:
		# - KATTA SHAHAR: Poytaxtlar yoki 1,000,000+ aholi
		# - O'RTA SHAHAR: 200,000 dan 999,999 gacha
		# - KICHIK SHAHAR: 200,000 dan kam aholi
		var cat := Category.SMALL
		if capital or pop >= 1000000:
			cat = Category.LARGE
		elif pop >= 200000:
			cat = Category.MEDIUM
		else:
			cat = Category.SMALL

		# Regional arxitektura uslubi
		var reg := _detect_regional_style(raw_name, code, capital)

		var city := CityData.new()
		city.id = next_id
		next_id += 1
		city.name = raw_name
		city.display_name = CityNames.of(raw_name)
		city.country_code = code
		city.stable_id = "%s_%s_%d_%d" % [code, raw_name, x, y]
		city.country_name = _get_country_name(code)
		city.x = x
		city.y = y
		city.pos = Vector2(float(x) + 0.5, float(y) + 0.5)
		city.pop = pop
		city.capital = capital
		city.category = cat
		city.owner_id = 0
		city.owner_country = code # Neytral holatda shahar o'z mamlakati kodi bilan
		city.owner_name = ""
		city.capture_time = 0.0
		city.regional_style = reg
		city.reward_coins = MonetizationConfig.get_city_capture_reward(cat)
		city.weight = weight
		city.rank = rank

		cities.append(city)
		_by_id[city.id] = city
		_by_cell[y * grid.width + x] = city

	# Qo'shni shaharlar orasidagi minimal masofani hisoblash (Zichlik va o'lcham uchun)
	for i in cities.size():
		var c1: CityData = cities[i]
		var min_d := 999.0
		for j in cities.size():
			if i == j:
				continue
			var d := c1.pos.distance_to(cities[j].pos)
			if d < min_d:
				min_d = d
		c1.neighbor_dist = min_d

	_total_count = cities.size()

static func _detect_regional_style(name: String, code: String, is_capital: bool) -> String:
	var n := name.to_lower()
	if n == "paris" or (code == "FR" and is_capital):
		return "paris"
	elif code == "UZ" or n in ["tashkent", "samarqand", "samarkand", "bukhara", "andijon"]:
		return "uzbek"
	elif n == "rome" or (code == "IT" and is_capital):
		return "rome"
	elif code == "JP" or n in ["tokyo", "kyoto", "osaka"]:
		return "japan"
	elif code == "EG" or n in ["cairo", "alexandria", "luxor"]:
		return "egypt"
	elif code == "US":
		return "usa"
	return "default"

static func _get_country_name(code: String) -> String:
	# O'yin Profilidan mamlakat nomini olamiz
	var cname := Profile.country_name(code)
	if not cname.is_empty():
		return cname
	return code

## Hududiy tsikl yopilganda qamrab olingan yangi kataklardagi shaharlarni egallash
func check_capture_cells(cells: PackedInt32Array, player_id: int, player_country: String, player_name: String, elapsed: float) -> Array[CityData]:
	var captured: Array[CityData] = []
	for cell_idx: int in cells:
		var city: CityData = _by_cell.get(cell_idx, null)
		if city == null:
			continue
		# Agar allaqachon shu o'yinchiniki bo'lsa, qayta egallanmaydi
		if city.owner_id == player_id:
			continue

		var prev_owner := city.owner_id
		if prev_owner > 0 and _player_captured_counts.has(prev_owner):
			_player_captured_counts[prev_owner] = maxi(0, int(_player_captured_counts[prev_owner]) - 1)

		city.owner_id = player_id
		city.owner_country = player_country
		city.owner_name = player_name
		city.capture_time = elapsed

		var curr_count: int = int(_player_captured_counts.get(player_id, 0)) + 1
		_player_captured_counts[player_id] = curr_count

		captured.append(city)
	return captured

func get_city_at_cell(x: int, y: int) -> CityData:
	if x < 0 or y < 0 or x >= _grid_width or y >= _grid_height:
		return null
	return _by_cell.get(y * _grid_width + x, null)

func get_city_at_world_pos(pt: Vector2, max_dist: float = 3.5) -> CityData:
	var best: CityData = null
	var best_d2 := max_dist * max_dist
	for c: CityData in cities:
		var d2 := c.pos.distance_squared_to(pt)
		if d2 < best_d2:
			best_d2 = d2
			best = c
	return best

func get_city_by_id(id: int) -> CityData:
	return _by_id.get(id, null)

func get_player_captured_count(player_id: int) -> int:
	return int(_player_captured_counts.get(player_id, 0))

func get_total_cities_count() -> int:
	return _total_count

func get_neutral_cities_count() -> int:
	var count := 0
	for c in cities:
		if c.owner_id == 0:
			count += 1
	return count

## Bot AI uchun: berilgan pozitsiyaga eng yaqin egallanmagan yoki dushman shahri
func get_nearest_target_city(pos: Vector2, max_radius: float, my_player_id: int) -> CityData:
	var best: CityData = null
	var best_d2 := max_radius * max_radius
	for c: CityData in cities:
		# O'zim egallagan shaharlarga bormayman
		if c.owner_id == my_player_id:
			continue
		var d2 := c.pos.distance_squared_to(pos)
		if d2 < best_d2:
			best_d2 = d2
			best = c
	return best

## Radius ichidagi barcha shaharlar
func get_cities_in_radius(pos: Vector2, radius: float) -> Array[CityData]:
	var res: Array[CityData] = []
	var r2 := radius * radius
	for c in cities:
		if c.pos.distance_squared_to(pos) <= r2:
			res.append(c)
	return res

## O'yinchi yoki bot o'lganda yoki barcha hududini yo'qotganda uning shaharlarini neytral holatga qaytarish
func reset_player_cities(player_id: int) -> Array[CityData]:
	var lost: Array[CityData] = []
	for c: CityData in cities:
		if c.owner_id == player_id:
			c.owner_id = 0
			c.owner_country = c.country_code
			c.owner_name = ""
			c.capture_time = 0.0
			lost.append(c)
	_player_captured_counts[player_id] = 0
	return lost

## O'yinchi tug'ilganda (spawn) uning boshlang'ich doirasiga tushgan shaharlarni egallash
func check_starting_disc(cx: int, cy: int, radius: float, player: Object, elapsed: float) -> Array[CityData]:
	var r2 := radius * radius
	var min_x := maxi(0, int(cx - radius - 1))
	var max_x := mini(_grid_width - 1, int(cx + radius + 1))
	var min_y := maxi(0, int(cy - radius - 1))
	var max_y := mini(_grid_height - 1, int(cy + radius + 1))

	var captured: Array[CityData] = []
	for gy in range(min_y, max_y + 1):
		for gx in range(min_x, max_x + 1):
			var dx := float(gx - cx)
			var dy := float(gy - cy)
			if dx * dx + dy * dy <= r2:
				var c: CityData = _by_cell.get(gy * _grid_width + gx, null)
				if c != null and c.owner_id != player.id:
					var prev_owner := c.owner_id
					if prev_owner > 0 and _player_captured_counts.has(prev_owner):
						_player_captured_counts[prev_owner] = maxi(0, int(_player_captured_counts[prev_owner]) - 1)

					c.owner_id = player.id
					c.owner_country = player.country
					c.owner_name = player.player_name
					c.capture_time = elapsed
					var curr_count: int = int(_player_captured_counts.get(player.id, 0)) + 1
					_player_captured_counts[player.id] = curr_count
					captured.append(c)
	return captured

## Panjara (GameGrid) bilan shaharlar egaligini 100% solishtirib tekshirish va muvofiqlashtirish
func reconcile_with_grid(grid: GameGrid, players_by_id: Variant = null) -> Dictionary:
	var lost: Array[CityData] = []
	var transferred: Array[CityData] = []

	for c: CityData in cities:
		var grid_owner: int = grid.owner_at(c.x, c.y)
		if grid_owner == 0 and c.owner_id != 0:
			# Panjara neytral, lekin shahar egallangan deb turibdi -> neytralga o'tadi
			var prev_owner := c.owner_id
			if _player_captured_counts.has(prev_owner):
				_player_captured_counts[prev_owner] = maxi(0, int(_player_captured_counts[prev_owner]) - 1)
			c.owner_id = 0
			c.owner_country = c.country_code
			c.owner_name = ""
			c.capture_time = 0.0
			lost.append(c)
		elif grid_owner > 0 and c.owner_id != grid_owner:
			# Panjara egasi boshqa, lekin shahar unga o'tmagan -> yangi egasiga o'tkaziladi
			var prev_owner := c.owner_id
			if prev_owner > 0 and _player_captured_counts.has(prev_owner):
				_player_captured_counts[prev_owner] = maxi(0, int(_player_captured_counts[prev_owner]) - 1)
			c.owner_id = grid_owner
			var p = null
			if players_by_id is Array and grid_owner < players_by_id.size():
				p = players_by_id[grid_owner]
			elif players_by_id is Dictionary:
				p = players_by_id.get(grid_owner, null)
			if p != null:
				c.owner_country = p.country
				c.owner_name = p.player_name
			else:
				c.owner_country = c.country_code
				c.owner_name = "Player %d" % grid_owner
			var curr: int = int(_player_captured_counts.get(grid_owner, 0)) + 1
			_player_captured_counts[grid_owner] = curr
			transferred.append(c)

	return {"lost": lost, "transferred": transferred}

## O'yin davomida shaharlar istilosi mukofotlarini bir marta berilishini va
## takrorlanishdan himoyalanishini boshqaruvchi sessiya klassi (PHASE 6).
class CityRewardTracker:
	## O'yin davomida shaharlar istilosi mukofotlarini bir marta berilishini,
	## takrorlanishdan himoyalanishini va o'yin to'xtatilib (pause) qayta
	## davom ettirilganda (resume) yoki saqlangan holatdan tiklanganda (recovery)
	## mukofotlar tarixini saqlab qolishni boshqaruvchi klass.
	##
	## O'yin xususiyati:
	##  * Color Land 3D real vaqtdagi arcade o'yini: o'yinchi o'lganda yoki menyuga
	##    chiqqanda o'yin tugaydi va natijalar qayd etiladi.
	##  * O'yin davomida PAUSE/RESUME qilinganda yoki bitta match sessiyasi
	##    davom etganda barcha egallangan shaharlar tarixi va mukofot huquqi
	##    to'liq saqlanadi — qayta ochilganda qayta tanga berilmaydi.
	##  * Agar o'yin holati diskka saqlansa, to_dict() va from_dict() orqali
	##    match ID va barcha stable_id lar 100% tiklanadi.
	##  * Yangi match boshlangandagina reset() orqali yangi sessiya boshlanadi.

	const SAVE_FILE_PATH := "user://active_match_rewards.cfg"

	var _claimed_ids: Dictionary = {} # city_id (int) -> bool
	var _claimed_stable_keys: Dictionary = {} # stable_id (String) -> bool
	var _match_id: String = ""
	var _duplicates_prevented: int = 0
	var _rewarded_counts_by_category: Dictionary = {
		Category.SMALL: 0,
		Category.MEDIUM: 0,
		Category.LARGE: 0,
	}
	var _total_conquest_coins: int = 0

	func reset(match_id: String = "") -> void:
		_claimed_ids.clear()
		_claimed_stable_keys.clear()
		_match_id = match_id if not match_id.is_empty() else str(int(Time.get_unix_time_from_system()))
		_duplicates_prevented = 0
		_rewarded_counts_by_category = {
			Category.SMALL: 0,
			Category.MEDIUM: 0,
			Category.LARGE: 0,
		}
		_total_conquest_coins = 0

	## Shu o'yin davom etayotgan bo'lsa (resume), tarixni tozalama!
	## Faqat match_id boshqa bo'lsa yoki yangi o'yin bo'lsa reset qilinadi.
	func resume_or_start(match_id: String) -> bool:
		if not _match_id.is_empty() and _match_id == match_id:
			# Xuddi shu o'yin davom etmoqda — tarix saqlanadi
			return true
		reset(match_id)
		return false

	func get_match_id() -> String:
		return _match_id

	func set_match_id(val: String) -> void:
		_match_id = val

	func is_city_eligible(city: CityData) -> bool:
		if city == null:
			return false
		if _claimed_ids.has(city.id):
			return false
		if not city.stable_id.is_empty() and _claimed_stable_keys.has(city.stable_id):
			return false
		return true

	func claim_city(city: CityData, is_human: bool) -> Dictionary:
		if not is_human:
			return {"eligible": false, "coins": 0, "reason": "bot"}
		if not is_city_eligible(city):
			_duplicates_prevented += 1
			return {"eligible": false, "coins": 0, "reason": "already_claimed"}
		_claimed_ids[city.id] = true
		if not city.stable_id.is_empty():
			_claimed_stable_keys[city.stable_id] = true
		var coins: int = MonetizationConfig.get_city_capture_reward(city.category)
		_rewarded_counts_by_category[city.category] = int(_rewarded_counts_by_category.get(city.category, 0)) + 1
		_total_conquest_coins += coins
		var tx_id := "conquest_%s_city_%d" % [_match_id, city.id]
		return {
			"eligible": true,
			"coins": coins,
			"category": city.category,
			"tx_id": tx_id,
			"city_name": city.display_name,
		}

	func get_rewarded_count(cat: int) -> int:
		return int(_rewarded_counts_by_category.get(cat, 0))

	func get_total_conquest_coins() -> int:
		return _total_conquest_coins

	func get_duplicates_prevented() -> int:
		return _duplicates_prevented

	func get_claimed_count() -> int:
		return _claimed_ids.size()

	func get_claimed_city_ids() -> Array:
		return _claimed_ids.keys()

	func get_claimed_stable_keys() -> Array:
		return _claimed_stable_keys.keys()

	func restore_claimed_ids(ids: Array) -> void:
		for id in ids:
			_claimed_ids[int(id)] = true

	func restore_claimed_stable_keys(keys: Array) -> void:
		for k in keys:
			var s := str(k)
			if not s.is_empty():
				_claimed_stable_keys[s] = true

	## Holatni to'liq lug'atga eksport qilish (Serializatsiya)
	func to_dict() -> Dictionary:
		return {
			"match_id": _match_id,
			"claimed_ids": _claimed_ids.keys(),
			"claimed_stable_keys": _claimed_stable_keys.keys(),
			"duplicates_prevented": _duplicates_prevented,
			"rewarded_counts": _rewarded_counts_by_category.duplicate(),
			"total_conquest_coins": _total_conquest_coins,
		}

	## Saqlangan lug'atdan holatni 100% tiklash (Deserializatsiya)
	func from_dict(data: Dictionary) -> void:
		if data.is_empty():
			return
		_match_id = str(data.get("match_id", ""))
		_duplicates_prevented = int(data.get("duplicates_prevented", 0))
		_total_conquest_coins = int(data.get("total_conquest_coins", 0))

		_claimed_ids.clear()
		var ids: Array = data.get("claimed_ids", [])
		for id in ids:
			_claimed_ids[int(id)] = true

		_claimed_stable_keys.clear()
		var keys: Array = data.get("claimed_stable_keys", [])
		for k in keys:
			var s := str(k)
			if not s.is_empty():
				_claimed_stable_keys[s] = true

		var counts: Dictionary = data.get("rewarded_counts", {})
		_rewarded_counts_by_category = {
			Category.SMALL: int(counts.get(Category.SMALL, counts.get(str(Category.SMALL), 0))),
			Category.MEDIUM: int(counts.get(Category.MEDIUM, counts.get(str(Category.MEDIUM), 0))),
			Category.LARGE: int(counts.get(Category.LARGE, counts.get(str(Category.LARGE), 0))),
		}

	## O'yin sessiyasini diskka saqlash (Recovery fayli)
	func save_state(path: String = SAVE_FILE_PATH) -> bool:
		var cfg := ConfigFile.new()
		cfg.set_value("match", "state", to_dict())
		var err := cfg.save(path)
		return err == OK

	## Saqlangan o'yin sessiyasini diskdan yuklab tiklash
	func load_state(path: String = SAVE_FILE_PATH) -> bool:
		var cfg := ConfigFile.new()
		var err := cfg.load(path)
		if err != OK:
			return false
		var data: Variant = cfg.get_value("match", "state", {})
		if data is Dictionary and not data.is_empty():
			from_dict(data)
			return true
		return false

	## O'yin tugaganda saqlangan tiklash faylini o'chirish
	func clear_saved_state(path: String = SAVE_FILE_PATH) -> void:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

