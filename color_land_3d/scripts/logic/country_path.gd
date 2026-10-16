class_name CountryPath
extends RefCounted

## Mamlakatlar yo'li: har o'yindan keyin ochko yig'iladi va
## navbatdagi mamlakat "egallanadi".
##
## Bu yerda faqat **mantiq** bor — fayl o'qish va chizish boshqa
## joyda. Shuning uchun hisob-kitob headless testdan o'tadi.
##
## Shakllar `tool/make_country_shapes.py` bilan Natural Earth
## 1:110m dan tayyorlanadi.

const PATH := "res://data/country_shapes.json"

## Bir o'yin nechta ochko beradi.
##
## Hudud asosiy manba: 1% maydon = 10 ochko. O'ldirish ham
## qo'shiladi, lekin kamroq — yo'l hudud egallash haqida.
const POINTS_PER_PERCENT := 10.0
const POINTS_PER_KILL := 5
## Har o'yin uchun eng kam ochko: natija yomon bo'lsa ham yo'l
## sal bo'lsa-da oldinga siljisin.
const POINTS_MIN := 5

static func points_for(percent: float, kills: int) -> int:
	return maxi(POINTS_MIN, int(round(
		maxf(percent, 0.0) * POINTS_PER_PERCENT
		+ maxi(kills, 0) * POINTS_PER_KILL)))

## Ro'yxatni o'qiydi: [{code, name, goal, rings}].
static func load_all() -> Array:
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_error("Mamlakatlar fayli ochilmadi: %s" % PATH)
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary) or not (parsed as Dictionary).has(
			"countries"):
		push_error("Mamlakatlar fayli buzuq")
		return []
	return (parsed as Dictionary)["countries"]

## Halqalarni chizishga tayyor nuqtalar qilib beradi.
##
## Faylda ular bitta tekis ro'yxatda yotadi (x, y, x, y, ...) —
## shunda fayl ikki barobar kichik bo'ladi.
static func rings_of(country: Dictionary,
		box: float = 1.0) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for ring: Variant in country.get("rings", []):
		var flat: Array = ring
		var points := PackedVector2Array()
		points.resize(flat.size() / 2)
		for i in points.size():
			points[i] = Vector2(
				float(flat[i * 2]), float(flat[i * 2 + 1])) * box
		out.append(points)
	return out
