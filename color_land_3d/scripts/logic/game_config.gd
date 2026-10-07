class_name GameConfig
extends RefCounted

## O'yinning barcha sozlamalari bir joyda. Mantiq qatlami faqat shuni biladi.

var grid_width: int = 520
var grid_height: int = 205
## Maydon dunyo xaritasidan yaratiladimi. `false` — butun to'rtburchak
## o'ynaladi (testlar uchun qulay).
var world_map: bool = true

## Boshlang'ich hudud joylashadigan kvadrat tomoni.
var start_block: int = 5
var bot_count: int = 15
var difficulty: Difficulty = Difficulty.new()

## Katak/sekund.
var player_speed: float = 8.0
## Radian/sekund.
var player_turn_rate: float = 14.0
var bot_turn_rate: float = 9.0
var bot_respawn_delay: float = 3.0
## Bir qadamda hisoblanadigan maksimal vaqt (lag paytida sakrashni oldini oladi).
var max_step_dt: float = 1.0 / 30.0
## Oxirgi necha katak iz "o'ziniki" hisoblanmaydi — barmoq tebranishi
## uchun o'ldirish adolatsiz bo'lardi.
var self_hit_grace: int = 3
## O'limdan keyin davom etishda kamida shuncha katak qaytarilsa, o'yinchi
## o'sha joyida tiklanadi.
var min_revive_cells: int = 10

func start_radius() -> float:
	return start_block / 2.0

func cell_count() -> int:
	return grid_width * grid_height

func bot_speed() -> float:
	return player_speed * difficulty.bot_speed_factor
