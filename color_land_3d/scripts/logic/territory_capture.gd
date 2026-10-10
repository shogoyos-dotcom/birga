class_name TerritoryCapturer
extends RefCounted

## Hudud egallash: iz yopilganda iz kataklari va u o'rab olgan hamma
## narsa o'yinchiga o'tadi.
##
## Usul: iz yopilgach, uning **qo'shni kataklaridan** to'ldirish
## boshlanadi. To'ldirish o'yinchining to'rtburchagi chetiga chiqib
## ketsa — demak bu tashqari, darhol to'xtatiladi. Chetga chiqmay
## tugasa — demak o'ralgan joy, u o'yinchiga o'tadi.
##
## Shuning uchun narx **egallangan maydonga** bog'liq, hududning
## kattaligiga emas. Ilgari har safar butun to'rtburchak uch marta
## aylanib chiqilardi: katta hududda bir nechta katak olish ham 15
## millisekund olib, kadr tushib ketardi.
##
## Suv hech qachon egallanmaydi, lekin to'ldirish u orqali erkin
## yuradi — shuning uchun okeanga ulangan qo'ltiq egallanmaydi, ichki
## ko'l esa ko'l bo'lib qoladi.
##
## Diqqat: bu yerda lambda ishlatilmaydi. GDScript lambdasi tashqi
## o'zgaruvchini nusxa qilib oladi, shuning uchun ichida o'zgartirilgan
## hisoblagich tashqarida eski holicha qolardi.

var grid: GameGrid

# Qayta ishlatiladigan buferlar — har egallashda yangi massiv
# ajratilmasin.
var _seen: PackedInt32Array
var _queue: PackedInt32Array
var _region: PackedInt32Array
## Tashrif belgisi: har egallashda bittaga oshadi, shuning uchun
## buferni tozalash kerak emas.
var _mark := 0

# Joriy egallash holati.
var _player_id: int
var _captured: int
var _cells: PackedInt32Array
var _taken_from: Dictionary
var _head: int
var _tail: int
var _x0: int
var _y0: int
var _x1: int
var _y1: int

func _init(p_grid: GameGrid) -> void:
	grid = p_grid
	var size := grid.width * grid.height
	_seen = PackedInt32Array()
	_seen.resize(size)
	_queue = PackedInt32Array()
	_queue.resize(size)
	_region = PackedInt32Array()

## Natija: {"captured": int, "cells": PackedInt32Array,
##          "taken_from": Dictionary[int, int]}
func capture(player_id: int, trail: PackedInt32Array) -> Dictionary:
	_player_id = player_id
	_captured = 0
	_cells = PackedInt32Array()
	_taken_from = {}

	# 1. Iz kataklari o'yinchiniki bo'ladi.
	for i: int in trail:
		grid.set_trail_index(i, 0)
		_claim(i)
	if trail.is_empty():
		return _result()

	# 2. Qidiruv maydoni — o'yinchi to'rtburchagi, bir katakka
	# kengaytirilgan. O'ralgan joy hech qachon bundan tashqarida
	# bo'lmaydi.
	var b := grid.bounds_of(player_id)
	if b.is_empty():
		return _result()
	_x0 = maxi(0, b[0] - 1)
	_y0 = maxi(0, b[1] - 1)
	_x1 = mini(grid.width - 1, b[2] + 1)
	_y1 = mini(grid.height - 1, b[3] + 1)
	_mark += 1

	# 3. Izning har bir qo'shnisidan to'ldirish.
	var w := grid.width
	for i: int in trail:
		var x: int = i % w
		var y: int = i / w
		_fill_from(x - 1, y)
		_fill_from(x + 1, y)
		_fill_from(x, y - 1)
		_fill_from(x, y + 1)
	return _result()

## Shu katakdan boshlanadigan sohani to'ldiradi. Soha to'rtburchak
## chetiga chiqsa — tashqari, hech narsa egallanmaydi.
func _fill_from(x: int, y: int) -> void:
	if x < _x0 or x > _x1 or y < _y0 or y > _y1:
		return
	var i: int = y * grid.width + x
	if _seen[i] == _mark or grid.owner_cells[i] == _player_id:
		return

	_head = 0
	_tail = 0
	_region.clear()
	_push(i)

	var w := grid.width
	while _head < _tail:
		var at: int = _queue[_head]
		_head += 1
		var ax: int = at % w
		var ay: int = at / w
		if ax <= _x0 or ax >= _x1 or ay <= _y0 or ay >= _y1:
			# Chetga chiqdi — tashqari. Belgilab qo'yilgan kataklar
			# saqlanib qoladi, shuning uchun keyingi urug'lar shu
			# yerni qaytadan kezmaydi.
			return
		if ax > _x0:
			_push(at - 1)
		if ax < _x1:
			_push(at + 1)
		if ay > _y0:
			_push(at - w)
		if ay < _y1:
			_push(at + w)

	# To'ldirish chetga chiqmay tugadi — demak o'ralgan joy.
	for cell: int in _region:
		if grid.is_land_index(cell):
			_claim(cell)

func _push(i: int) -> void:
	if _seen[i] == _mark or grid.owner_cells[i] == _player_id:
		return
	_seen[i] = _mark
	_queue[_tail] = i
	_tail += 1
	_region.append(i)

func _result() -> Dictionary:
	return {
		"captured": _captured,
		"cells": _cells,
		"taken_from": _taken_from,
	}

func _claim(i: int) -> void:
	var prev: int = grid.owner_cells[i]
	if prev == _player_id:
		return
	if prev != 0:
		_taken_from[prev] = int(_taken_from.get(prev, 0)) + 1
	grid.set_owner_index(i, _player_id)
	_cells.append(i)
	_captured += 1
