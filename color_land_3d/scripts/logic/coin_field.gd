class_name CoinField
extends RefCounted

## Xaritadagi tangalar: har shaharda bittadan.
##
## Tanga ustidan yurib emas, **hududni egallab** olinadi: halqa
## yopilganda ichkarida qolgan shaharlarning tangasi hamyonga
## tushadi. Shuning uchun tanga yig'ish o'yinning asosiy
## harakatini kuchaytiradi — chetga og'dirmaydi.
##
## Uchta qoida shundan kelib chiqadi:
##  * **o'z hududingdagi tangani ololmaysan** — egallash faqat
##    yangi kataklarni qamraydi, o'zingniki esa yangi emas;
##  * **raqib sening yeringga kirib olib keta oladi** — u o'sha
##    kataklarni egallaganda tanga uniki bo'ladi;
##  * olingan tanga [constant MonetizationConfig.CITY_COIN_RESPAWN]
##    soniyadan keyin shaharda qayta paydo bo'ladi.
##
## Sof mantiq — Godot tugunlariga bog'liq emas, shuning uchun
## headless testdan o'tadi. Chizish `render/city_coins.gd` da.
##
## Tanganing kattaligi va qiymati shahar aholisiga qarab:
## kichik qishloq 1 tanga, eng yirik shahar 25 tanga.

## [{x, y, weight, value, taken}]
var coins: Array = []
var _taken := 0
var _collected := 0
## O'yin boshlanganidan beri o'tgan vaqt (soniya).
var _clock := 0.0
## Qaytishini kutayotgan tangalar: [{index, at}], vaqt bo'yicha
## tartiblangan — hammasining kutish muddati bir xil, shuning
## uchun navbat o'z-o'zidan tartibda qoladi.
var _waiting: Array = []
## Qaytib kelgan tangalar indeksi — chizuvchi shular bo'yicha
## yangilanadi.
var _returned := PackedInt32Array()
## Oxirgi `flush_taken()` dan beri olingan tangalar indeksi —
## chizuvchi shular bo'yicha yangilanadi, butun ro'yxatni emas.
var _dirty := PackedInt32Array()
## Katak indeksi -> tanga indeksi. Egallangan kataklar ro'yxati
## bo'yicha tez qidirish uchun.
var _by_cell: Dictionary = {}
var _last_collected_cells: Dictionary = {}

## `places` — xaritadagi shaharlar; `grid` o'ynaladigan katakni
## tekshirish uchun.
func build(places: Array, grid: GameGrid) -> void:
	coins.clear()
	_taken = 0
	_collected = 0
	_clock = 0.0
	_waiting.clear()
	_returned.clear()
	_dirty.clear()
	_by_cell.clear()
	var top := 1.0
	for c: Dictionary in places:
		if grid.playable(int(c.get("x", -1)), int(c.get("y", -1))):
			top = maxf(top, float(c.get("pop", 0)))
	for c: Dictionary in places:
		var x := int(c.get("x", -1))
		var y := int(c.get("y", -1))
		if not grid.playable(x, y):
			continue
		# Aholi juda keng tarqalgan, shuning uchun kvadrat ildiz —
		# kichik shahar ham ko'rinadigan tanga oladi.
		var weight := clampf(sqrt(float(c.get("pop", 0)) / top), 0.0, 1.0)
		_by_cell[y * grid.width + x] = coins.size()
		coins.append({
			"x": x + 0.5, "y": y + 0.5, "weight": weight,
			"value": RewardManager.city_coin(weight), "taken": false,
		})

func size() -> int:
	return coins.size()

## Hozir xaritada yo'q tangalar soni.
func taken_count() -> int:
	return _taken

## Shu o'yinda yig'ilgan jami tanga.
func collected() -> int:
	return _collected

## Katakdagi tanga mavjudmi (olinmagan va kutilishda emasmi).
func is_coin_available_at_cell(cell: int) -> bool:
	var index: int = _by_cell.get(cell, -1)
	if index < 0 or index >= coins.size():
		return false
	return not bool((coins[index] as Dictionary).get("taken", false))

## Katakdagi tanga qiymatini qaytaradi (agar mavjud bo'lsa).
func get_coin_value_at_cell(cell: int) -> int:
	var index: int = _by_cell.get(cell, -1)
	if index < 0 or index >= coins.size():
		return 0
	return int((coins[index] as Dictionary).get("value", 0))

## Egallangan kataklardagi tangalarni oladi va qiymatini qaytaradi.
##
## `score` yolg'on bo'lsa tanga xaritadan yo'qoladi, lekin hisobga
## qo'shilmaydi — uni raqib olib ketgan bo'ladi.
##
## Ro'yxatda faqat **yangi** egallangan kataklar bo'ladi, shuning
## uchun o'z hududingdagi tanga bu yerga tushmaydi.
func collect_cells(cells: PackedInt32Array, score: bool = true) -> int:
	_last_collected_cells.clear()
	var got := 0
	for cell: int in cells:
		var index: int = _by_cell.get(cell, -1)
		if index < 0:
			continue
		var coin: Dictionary = coins[index]
		if coin["taken"]:
			continue
		coin["taken"] = true
		var val: int = int(coin["value"])
		got += val
		_last_collected_cells[cell] = val
		_taken += 1
		_dirty.append(index)
		_waiting.append({
			"index": index,
			"at": _clock + MonetizationConfig.CITY_COIN_RESPAWN,
		})
	if score:
		_collected += got
	return got

## Oxirgi egallashda katakdan olingan tanga miqdori (agar olinmagan bo'lsa 0).
func get_last_collected_coin_for_cell(cell: int) -> int:
	return int(_last_collected_cells.get(cell, 0))

## Soatni oldinga suradi va muddati yetgan tangalarni qaytaradi.
##
## Natija — qayta paydo bo'lgan tangalar indeksi; chizuvchi
## shulardan foydalanadi.
func advance(delta: float) -> PackedInt32Array:
	_clock += delta
	_returned.clear()
	while not _waiting.is_empty() \
			and float((_waiting[0] as Dictionary)["at"]) <= _clock:
		var row: Dictionary = _waiting.pop_front()
		var index := int(row["index"])
		(coins[index] as Dictionary)["taken"] = false
		_taken -= 1
		_returned.append(index)
	return _returned

## Qaytishini kutayotgan tangalar soni.
func waiting_count() -> int:
	return _waiting.size()

## Oxirgi chaqiriqdan beri olingan tangalar indeksini qaytaradi va
## ro'yxatni bo'shatadi.
func flush_taken() -> PackedInt32Array:
	var out := _dirty.duplicate()
	_dirty.clear()
	return out
