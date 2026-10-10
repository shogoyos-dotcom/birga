class_name CoinField
extends RefCounted

## Xaritadagi tangalar: har shaharda bittadan.
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

## `places` — xaritadagi shaharlar; `grid` o'ynaladigan katakni
## tekshirish uchun.
func build(places: Array, grid: GameGrid) -> void:
	coins.clear()
	_taken = 0
	_collected = 0
	_dirty.clear()
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

## `(x, y)` atrofidagi tangalarni yig'adi va qiymatini qaytaradi.
## Olinganlari ikkinchi marta hisoblanmaydi.
func collect(x: float, y: float,
		radius: float = MonetizationConfig.CITY_COIN_RADIUS) -> int:
	var r2 := radius * radius
	var got := 0
	for i in coins.size():
		var coin: Dictionary = coins[i]
		if coin["taken"]:
			continue
		var dx: float = coin["x"] - x
		var dy: float = coin["y"] - y
		if dx * dx + dy * dy <= r2:
			coin["taken"] = true
			got += int(coin["value"])
			_taken += 1
			_dirty.append(i)
	_collected += got
	return got

## Oxirgi chaqiriqdan beri olingan tangalar indeksini qaytaradi va
## ro'yxatni bo'shatadi.
func flush_taken() -> PackedInt32Array:
	var out := _dirty.duplicate()
	_dirty.clear()
	return out
