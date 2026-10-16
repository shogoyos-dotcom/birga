class_name HeroCatalog
extends RefCounted

## Qahramonlar (personajlar) katalogi va ularni ochish shartlari.
##
## Mantiq qatlami: dvigatel tugunlariga bog'liq emas, to'liq test qilinadi.
## Har bir qahramonning o'ziga xos topshirig'i (sharti) va maqsadli soni bor.
## O'yinchi natijalariga qarab avtomatik ochiladi.

enum ReqType { FREE, STREAK, MATCHES, KILLS, SPHERES, COUNTRIES, UPGRADES, REVIVES }

const HEROES: Array[Dictionary] = [
	# 1. Boshlang'ich qahramonlar
	{"id": "hero_cube", "name_key": "heroCube", "type": ReqType.FREE, "target": 0,
		"task_key": "taskFree", "skin": "skin_classic", "color": Color("ffd23f")},
	{"id": "hero_melon", "name_key": "heroMelon", "type": ReqType.FREE, "target": 0,
		"task_key": "taskFree", "skin": "skin_melon", "color": Color("e8384f")},

	# 2. Ketma-ket kirish kunlari (streak)
	{"id": "hero_penguin", "name_key": "heroPenguin", "type": ReqType.STREAK, "target": 1,
		"task_key": "taskStreak", "skin": "skin_frost", "color": Color("7ad7ff")},
	{"id": "hero_golem", "name_key": "heroGolem", "type": ReqType.STREAK, "target": 3,
		"task_key": "taskStreak", "skin": "skin_magma", "color": Color("ff6a12")},
	{"id": "hero_deer", "name_key": "heroDeer", "type": ReqType.STREAK, "target": 7,
		"task_key": "taskStreak", "skin": "skin_forest", "color": Color("d29054")},

	# 3. O'yinlar soni
	{"id": "hero_bear", "name_key": "heroBear", "type": ReqType.MATCHES, "target": 3,
		"task_key": "taskMatches", "skin": "skin_frost", "color": Color("e8f4f8")},
	{"id": "hero_gingerbread", "name_key": "heroGingerbread", "type": ReqType.MATCHES, "target": 15,
		"task_key": "taskMatches", "skin": "skin_orange", "color": Color("c67c3b")},
	{"id": "hero_pirate", "name_key": "heroPirate", "type": ReqType.MATCHES, "target": 30,
		"task_key": "taskMatches", "skin": "skin_magma", "color": Color("802020")},

	# 4. Raqiblarni yo'q qilish (kills)
	{"id": "hero_seal", "name_key": "heroSeal", "type": ReqType.KILLS, "target": 10,
		"task_key": "taskKills", "skin": "skin_glow", "color": Color("9ab3c5")},
	{"id": "hero_balloon", "name_key": "heroBalloon", "type": ReqType.KILLS, "target": 15,
		"task_key": "taskKills", "skin": "skin_prism", "color": Color("ffd83e")},
	{"id": "hero_dragon", "name_key": "heroDragon", "type": ReqType.KILLS, "target": 300,
		"task_key": "taskKills", "skin": "skin_galaxy", "color": Color("9932cc")},

	# 5. Sferalar (tezlik va qalqon)
	{"id": "hero_chest", "name_key": "heroChest", "type": ReqType.SPHERES, "target": 50,
		"task_key": "taskSpheres", "skin": "skin_donut", "color": Color("e5a65d")},
	{"id": "hero_speed", "name_key": "heroSpeed", "type": ReqType.SPHERES, "target": 150,
		"task_key": "taskSpheres", "skin": "skin_glow", "color": Color("3ee28e")},

	# 6. Mamlakatlar yo'li (countries)
	{"id": "hero_conqueror1", "name_key": "heroConqueror1", "type": ReqType.COUNTRIES, "target": 1,
		"task_key": "taskCountries", "skin": "skin_forest", "color": Color("4caf50")},
	{"id": "hero_conqueror3", "name_key": "heroConqueror3", "type": ReqType.COUNTRIES, "target": 3,
		"task_key": "taskCountries", "skin": "skin_galaxy", "color": Color("3f51b5")},
	{"id": "hero_conqueror10", "name_key": "heroConqueror10", "type": ReqType.COUNTRIES, "target": 10,
		"task_key": "taskCountries", "skin": "skin_prism", "color": Color("9c27b0")},

	# 7. Kuchaytirgichlar ishlatish
	{"id": "hero_booster30", "name_key": "heroBooster30", "type": ReqType.UPGRADES, "target": 30,
		"task_key": "taskUpgrades", "skin": "skin_orange", "color": Color("ff9800")},
	{"id": "hero_booster60", "name_key": "heroBooster60", "type": ReqType.UPGRADES, "target": 60,
		"task_key": "taskUpgrades", "skin": "skin_magma", "color": Color("e91e63")},

	# 8. Qayta tirilish
	{"id": "hero_phoenix1", "name_key": "heroPhoenix1", "type": ReqType.REVIVES, "target": 1,
		"task_key": "taskRevives", "skin": "skin_magma", "color": Color("ff5722")},
	{"id": "hero_phoenix5", "name_key": "heroPhoenix5", "type": ReqType.REVIVES, "target": 5,
		"task_key": "taskRevives", "skin": "skin_galaxy", "color": Color("ff3d00")},
	{"id": "hero_phoenix15", "name_key": "heroPhoenix15", "type": ReqType.REVIVES, "target": 15,
		"task_key": "taskRevives", "skin": "skin_prism", "color": Color("d50000")},
]

## Qahramon haqidagi ma'lumotni topadi.
static func get_hero(id: String) -> Dictionary:
	for h: Dictionary in HEROES:
		if str(h["id"]) == id:
			return h
	return HEROES[0]

## Berilgan statistikaga qarab qahramonning joriy progressini hisoblaydi.
static func current_progress(hero: Dictionary, stats: Dictionary) -> int:
	var req: ReqType = hero["type"] as ReqType
	match req:
		ReqType.FREE:
			return 1
		ReqType.STREAK:
			return int(stats.get("streak", 0))
		ReqType.MATCHES:
			return int(stats.get("matches", 0))
		ReqType.KILLS:
			return int(stats.get("kills", 0))
		ReqType.SPHERES:
			return int(stats.get("spheres", 0))
		ReqType.COUNTRIES:
			return int(stats.get("countries", 0))
		ReqType.UPGRADES:
			return int(stats.get("upgrades", 0))
		ReqType.REVIVES:
			return int(stats.get("revives", 0))
	return 0

## Qahramon ochilganmi yoki yo'q.
static func is_unlocked(hero: Dictionary, stats: Dictionary) -> bool:
	var target: int = int(hero["target"])
	if target <= 0:
		return true
	return current_progress(hero, stats) >= target

## Jami ochilgan qahramonlar soni.
static func unlocked_count(stats: Dictionary) -> int:
	var count := 0
	for h: Dictionary in HEROES:
		if is_unlocked(h, stats):
			count += 1
	return count
