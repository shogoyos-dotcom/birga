class_name TerritoryCapturer
extends RefCounted

## Hudud egallash: iz yopilganda iz kataklari va u o'rab olgan hamma
## narsa o'yinchiga o'tadi.
##
## Usul: o'yinchining o'z hududini "devor" deb olib, uning to'rtburchagi
## chetidan BFS yuritiladi. Yetib bo'lmagan kataklar — o'ralgan, demak
## o'yinchiniki. Suv hech qachon egallanmaydi, lekin BFS u orqali erkin
## yuradi, shuning uchun okeanga ulangan qo'ltiq ham egallanmaydi.
##
## Qidiruv faqat o'yinchi to'rtburchagi ichida ketadi — bu to'g'ri,
## chunki devor bo'lib faqat o'sha o'yinchining kataklari xizmat qiladi.
##
## Diqqat: bu yerda lambda ishlatilmaydi. GDScript lambdasi tashqi
## o'zgaruvchini nusxa qilib oladi, shuning uchun ichida o'zgartirilgan
## hisoblagich tashqarida eski holicha qolardi.

var grid: GameGrid

# Qayta ishlatiladigan buferlar — har egallashda yangi massiv
# ajratilmasin.
var _reached: PackedByteArray
var _queue: PackedInt32Array

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
	_reached = PackedByteArray()
	_reached.resize(grid.width * grid.height)
	_queue = PackedInt32Array()
	_queue.resize(grid.width * grid.height)

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

	var b := grid.bounds_of(player_id)
	if b.is_empty():
		return _result()

	# 2. To'rtburchakni bir katakka kengaytiramiz — tashqi halqa BFS
	# uchun boshlang'ich nuqta bo'lib xizmat qiladi.
	_x0 = maxi(0, b[0] - 1)
	_y0 = maxi(0, b[1] - 1)
	_x1 = mini(grid.width - 1, b[2] + 1)
	_y1 = mini(grid.height - 1, b[3] + 1)

	var w := grid.width
	for y in range(_y0, _y1 + 1):
		var row := y * w
		for x in range(_x0, _x1 + 1):
			_reached[row + x] = 0

	_head = 0
	_tail = 0
	for x in range(_x0, _x1 + 1):
		_push(x, _y0)
		_push(x, _y1)
	for y in range(_y0, _y1 + 1):
		_push(_x0, y)
		_push(_x1, y)

	while _head < _tail:
		var i: int = _queue[_head]
		_head += 1
		var x: int = i % w
		var y: int = i / w
		if x > _x0: _push(x - 1, y)
		if x < _x1: _push(x + 1, y)
		if y > _y0: _push(x, y - 1)
		if y < _y1: _push(x, y + 1)

	# 3. Yetib bo'lmagan begona kataklar — o'ralgan, demak o'yinchiga
	# o'tadi. Suv bundan mustasno: o'ralib qolgan ko'l ko'l bo'lib qoladi.
	for y in range(_y0, _y1 + 1):
		var row := y * w
		for x in range(_x0, _x1 + 1):
			var i := row + x
			if _reached[i] == 0 and grid.owner_cells[i] != _player_id \
					and grid.is_land_index(i):
				_claim(i)

	return _result()

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

func _push(x: int, y: int) -> void:
	var i: int = y * grid.width + x
	if _reached[i] == 0 and grid.owner_cells[i] != _player_id:
		_reached[i] = 1
		_queue[_tail] = i
		_tail += 1
