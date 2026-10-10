class_name RewardManager
extends RefCounted

## O'yindan qancha tanga tushishini **hisoblaydi**.
##
## Hech narsa saqlamaydi va interfeysga tegmaydi: kirishga o'yin
## natijasi, chiqishga raqam. Hamma koeffitsiyent
## [MonetizationConfig] da — balansni o'zgartirish uchun o'yin
## kodiga tegilmaydi.

## Bitta o'yin uchun tanga: omon qolgan vaqt, egallangan hudud,
## yiqitilgan raqiblar va yo'lda yig'ilgan tangalar.
##
## Natija: {run, territory, kills, pickups, total}.
static func run_reward(elapsed: float, percent: float, kills: int,
		pickups: int = 0) -> Dictionary:
	var run := _ramp(MonetizationConfig.RUN_MIN, MonetizationConfig.RUN_MAX,
		elapsed / MonetizationConfig.RUN_FULL_SECONDS)
	var land := 0
	if percent > 0.0:
		land = _ramp(MonetizationConfig.TERRITORY_MIN,
			MonetizationConfig.TERRITORY_MAX,
			percent / MonetizationConfig.TERRITORY_FULL_PERCENT)
	var fight := 0
	if kills > 0:
		fight = _ramp(MonetizationConfig.KILL_MIN, MonetizationConfig.KILL_MAX,
			float(kills) / float(MonetizationConfig.KILL_FULL_COUNT))
	var total: int = mini(run + land + fight + maxi(pickups, 0),
		MonetizationConfig.RUN_COIN_CAP)
	return {
		"run": run, "territory": land, "kills": fight,
		"pickups": maxi(pickups, 0), "total": total,
	}

## Reklama ko'rilgandan keyin qancha qo'shiladi.
static func doubled(total: int) -> int:
	var bonus := int(round(total * MonetizationConfig.DOUBLE_COIN_MULTIPLIER)) - total
	return maxi(bonus, 0)

## Kunlik kirish mukofoti. `day` — 1 dan boshlanadi; ro'yxat tugasa
## aylanma qaytadan boshlanadi.
static func daily_login(day: int) -> int:
	var table := MonetizationConfig.DAILY_LOGIN
	if table.is_empty() or day < 1:
		return 0
	return table[(day - 1) % table.size()]

## Shahar ustidagi tanganing qiymati — aholi ulushiga qarab
## (0..1 oralig'idagi `weight`).
static func city_coin(weight: float) -> int:
	return _ramp(MonetizationConfig.CITY_COIN_MIN,
		MonetizationConfig.CITY_COIN_MAX, weight)

## `low`..`high` oralig'ida, `t` 0..1 ga qisiladi.
static func _ramp(low: int, high: int, t: float) -> int:
	return int(round(lerpf(float(low), float(high), clampf(t, 0.0, 1.0))))
