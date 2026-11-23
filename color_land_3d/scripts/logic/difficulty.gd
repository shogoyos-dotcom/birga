class_name Difficulty
extends RefCounted

## O'yin qiyinligi: bot tezligi, tsikl uzunligi va ehtiyotkorligi.
## Matnli nomlar interfeys qatlamida — bu yerda faqat raqamlar.

enum Level { EASY, NORMAL, HARD }

var level: Level
var bot_speed_factor: float
var bot_loop_factor: float
var reaction_delay: float
var danger_radius: float
var hunt_radius: float

func _init(p_level: Level = Level.NORMAL) -> void:
	level = p_level
	match p_level:
		Level.EASY:
			bot_speed_factor = 0.80
			bot_loop_factor = 0.70
			reaction_delay = 0.55
			danger_radius = 6.0
			hunt_radius = 9.0
		Level.HARD:
			bot_speed_factor = 1.08
			bot_loop_factor = 1.45
			reaction_delay = 0.12
			danger_radius = 12.0
			hunt_radius = 22.0
		_:
			bot_speed_factor = 0.95
			bot_loop_factor = 1.00
			reaction_delay = 0.30
			danger_radius = 9.0
			hunt_radius = 15.0

static func from_name(name: String) -> Difficulty:
	match name:
		"easy": return Difficulty.new(Level.EASY)
		"hard": return Difficulty.new(Level.HARD)
		_: return Difficulty.new(Level.NORMAL)

func name() -> String:
	match level:
		Level.EASY: return "easy"
		Level.HARD: return "hard"
		_: return "normal"
