class_name CoinField
extends RefCounted

## Xaritadagi tangalar: har shaharda bittadan.
##
## Tanga ustidan yurib emas, **hududni egallab** olinadi: halqa
## yopilganda ichkarida qolgan shaharlarning tangasi hamyonga
## tushadi. Shuning uchun tanga yig'ish o'yinning asosiy
## harakatini kuchaytiradi — chetga og'dirmaydi.
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
## Oxirgi `flush_taken()` dan beri olingan tangalar indeksi —
## chizuvchi shular bo'yicha yangilanadi, butun ro'yxatni emas.
var _dirty := PackedInt32Array()
## Katak indeksi -> tanga indeksi. Egallangan kataklar ro'yxati
## bo'yicha tez qidirish uchun.
var _by_cell: Dictionary = {}

## `places` — xaritadagi shaharlar; `grid` o'ynaladigan katakni
## tekshirish uchun.
func build(places: Array, grid: GameGrid) -> void:
	coins.clear()
	_taken = 0
	_collected = 0
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

func taken_count() -> int:
	return _taken

## Shu o'yinda yig'ilgan jami tanga.
func collected() -> int:
	return _collected

## Egallangan kataklardagi tangalarni yig'adi va qiymatini
## qaytaradi. Olinganlari ikkinchi marta hisoblanmaydi.
func collect_cells(cells: PackedInt32Array) -> int:
	var got := 0
	for cell: int in cells:
		var index: int = _by_cell.get(cell, -1)
		if index < 0:
			continue
		var coin: Dictionary = coins[index]
		if coin["taken"]:
			continue
		coin["taken"] = true
		got += int(coin["value"])
		_taken += 1
		_dirty.append(index)
	_collected += got
	return got

## Oxirgi chaqiriqdan beri olingan tangalar indeksini qaytaradi va
## ro'yxatni bo'shatadi.
func flush_taken() -> PackedInt32Array:
	var out := _dirty.duplicate()
	_dirty.clear()
	return out
