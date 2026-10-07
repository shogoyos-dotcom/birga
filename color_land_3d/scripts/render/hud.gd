extends Control

## Eng sodda HUD: foiz, vaqt, o'ldirishlar va reytingdagi o'rin.
## To'liq interfeys (menyu, sozlamalar, profil) keyingi bosqichda.

@onready var _percent: Label = $Panel/Box/Percent
@onready var _info: Label = $Panel/Box/Info

func set_stats(percent: float, kills: int, elapsed: float,
		rank: int, alive: int) -> void:
	_percent.text = "%.2f%%" % percent
	var minutes := int(elapsed) / 60
	var seconds := int(elapsed) % 60
	_info.text = "%02d:%02d   %d kill   %d/%d" % [
		minutes, seconds, kills, rank, alive]
