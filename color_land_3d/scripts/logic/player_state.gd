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
## Bosh ustida shu belgi turadi.
var avatar: String = "figure:0"
## Hududda ko'rinadigan bayroq (ISO 3166-1 alpha-2).
var country: String = Profile.DEFAULT_COUNTRY

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

## Yo'l nuqtalari orasidagi eng kichik masofa (katakda).
const PATH_MIN_STEP := 0.4

## Oraliq nuqta to'g'ri chiziqdan shuncha chetlashmasa — tashlanadi.
const PATH_TOLERANCE := 0.2

## Yo'lga yangi nuqta qo'shadi.
##
## To'g'ri borayotgan qism ikki nuqtada qoladi: oxirgi nuqta to'g'ri
## chiziq ustida bo'lsa, u yangisi bilan almashtiriladi. Shuning uchun
## uzoq to'g'ri iz ham o'nlab emas, ikki nuqtadan iborat bo'ladi va 3D
## lenta to'liq tekis chiqadi.
func add_path_point(px: float, py: float) -> void:
	var point := Vector2(px, py)
	var count := trail_path.size()
	if count == 0:
		trail_path.append(point)
		return
	if (point - trail_path[count - 1]).length_squared() \
			< PATH_MIN_STEP * PATH_MIN_STEP:
		return
	if count >= 2 and _on_line(trail_path[count - 2], trail_path[count - 1],
			point):
		trail_path[count - 1] = point
		return
	trail_path.append(point)

## `b` nuqtasi `a`—`c` kesmasidan deyarli chetlashmaganmi.
static func _on_line(a: Vector2, b: Vector2, c: Vector2) -> bool:
	var line := c - a
	var length2 := line.length_squared()
	if length2 < 1e-6:
		return true
	var t: float = clampf((b - a).dot(line) / length2, 0.0, 1.0)
	return (a + line * t).distance_squared_to(b) \
		<= PATH_TOLERANCE * PATH_TOLERANCE

## Burchakni [-PI, PI] oralig'iga keltiradi.
static func normalize_angle(a: float) -> float:
	var r: float = fmod(a, TAU)
	if r > PI:
		r -= TAU
	if r < -PI:
		r += TAU
	return r
