class_name PlayerState
extends RefCounted

## Bitta o'yinchining (odam yoki bot) holati. Chizishdan mustaqil.

enum DeathCause { NONE, SELF_CROSS, TRAIL_HIT, TERRITORY_LOST }

## 1..255. 0 — "bo'sh katak" ma'nosini bildiradi.
var id: int
var player_name: String
var color_index: int
var is_bot: bool
## Avatar kodi: "emoji:🦊", "figure:3" yoki "flag:UZ" ([Profile] ga qarang).
var avatar: String = "figure:0"

var speed: float
var turn_rate: float

## Uzluksiz pozitsiya, katak birligida.
var x: float = 0.0
var y: float = 0.0
## Hozirgi katak.
var cx: int = 0
var cy: int = 0
## Harakat yo'nalishi va intilayotgan yo'nalish (radian).
var angle: float = 0.0
var target_angle: float = 0.0

var alive: bool = false
var kills: int = 0
var respawn_timer: float = 0.0
## O'lim paytidagi hudud hajmi — natija oynasi uchun.
var final_territory: int = 0
var death_cause: DeathCause = DeathCause.NONE

## O'z hududidan tashqarida chizilgan iz kataklari (tartib bilan).
var trail := PackedInt32Array()
## Izning uzluksiz yo'li — 3D lenta shu bo'yicha quriladi.
var trail_path := PackedVector2Array()

## Bot miyasi (faqat botlar uchun).
var brain: Object = null

func _init(p_id: int, p_name: String, p_color: int, p_is_bot: bool,
		p_speed: float, p_turn_rate: float) -> void:
	id = p_id
	player_name = p_name
	color_index = p_color
	is_bot = p_is_bot
	speed = p_speed
	turn_rate = p_turn_rate

func is_outside() -> bool:
	return not trail.is_empty()

func place_at(px: float, py: float, dir: float) -> void:
	x = px
	y = py
	cx = int(floor(px))
	cy = int(floor(py))
	angle = dir
	target_angle = dir
	trail.clear()
	trail_path.clear()
	alive = true
	death_cause = DeathCause.NONE
	respawn_timer = 0.0
	final_territory = 0

func steer_to(dir: float) -> void:
	target_angle = normalize_angle(dir)

## Yo'lga yangi nuqta qo'shadi (juda yaqin bo'lsa qo'shmaydi).
func add_path_point(px: float, py: float) -> void:
	if trail_path.size() >= 1:
		var last := trail_path[trail_path.size() - 1]
		if (Vector2(px, py) - last).length_squared() < 0.09:
			return
	trail_path.append(Vector2(px, py))

## Burchakni [-PI, PI] oralig'iga keltiradi.
static func normalize_angle(a: float) -> float:
	var r: float = fmod(a, TAU)
	if r > PI:
		r -= TAU
	if r < -PI:
		r += TAU
	return r
