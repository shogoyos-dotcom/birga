class_name DragScroll
extends ScrollContainer

## Barmoq bilan surib aylantiriladigan ro'yxat.
##
## Godot'ning oddiy `ScrollContainer` ida surish hodisasi tugmagacha
## yetib bormaydi: bosilgan tugma uni o'zi yeb qo'yadi, shuning uchun
## sozlamalar ekranini faqat yon chiziqchadan aylantirish mumkin edi.
##
## Shu sabab hodisa `_input` da ushlanadi — u interfeysdan **oldin**
## keladi. Bosish darhol surishga aylanmaydi: barmoq [constant
## THRESHOLD] pikseldan ko'p yurgandagina aylantirish boshlanadi,
## shunda oddiy bosish tugmaga tegishli bo'lib qolaveradi.

## Shundan keyin surish deb hisoblanadi (piksel).
const THRESHOLD := 10.0

var _holding := false
var _dragging := false
var _from := 0.0
var _origin := 0

func _init() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_press((event as InputEventScreenTouch).pressed,
			(event as InputEventScreenTouch).position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_press(mb.pressed, mb.position)
	elif event is InputEventScreenDrag:
		_move((event as InputEventScreenDrag).position)
	elif event is InputEventMouseMotion and _holding:
		_move((event as InputEventMouseMotion).position)

func _press(down: bool, at: Vector2) -> void:
	if down:
		# Faqat shu ro'yxat ustida boshlangan harakat hisoblanadi.
		_holding = get_global_rect().has_point(at)
		_dragging = false
		_from = at.y
		_origin = scroll_vertical
		return
	_holding = false
	_dragging = false

func _move(at: Vector2) -> void:
	if not _holding:
		return
	var moved := at.y - _from
	if not _dragging:
		if absf(moved) < THRESHOLD:
			return
		_dragging = true
		# Hisobni chegaradan boshlaymiz — sakrab ketmasin.
		_from = at.y - signf(moved) * THRESHOLD
		moved = signf(moved) * THRESHOLD
	scroll_vertical = _origin - int(at.y - _from)
	get_viewport().set_input_as_handled()
