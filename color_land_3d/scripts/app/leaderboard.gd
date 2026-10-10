extends Node

## Onlayn reyting: shahar, davlat, materik va dunyo bo'yicha.
##
## O'yin faqat **mijoz** tomoni: natija serverga yuboriladi va
## ro'yxat undan o'qiladi. Server manzili sozlanmagan bo'lsa, reyting
## faqat shu qurilmadagi eng yaxshi natijani ko'rsatadi — o'yin
## baribir internetsiz ishlayveradi.
##
## Server HTTP API si (`server/leaderboard.py` da namunasi bor):
##   POST <base>/score   {name, country, city, continent, percent, kills}
##   GET  <base>/top?scope=world|continent|country|city&key=<qiymat>
##        -> {"rows": [{"name", "percent", "kills", "country", "city"}]}

signal loaded(scope: String, rows: Array)
signal failed(reason: String)

const CONTINENTS_PATH := "res://data/continents.json"

## Qaysi kesimda ko'rsatiladi.
const SCOPES: PackedStringArray = ["city", "country", "continent", "world"]

const TIMEOUT := 8.0

static var _continents: Dictionary = {}

var _http: HTTPRequest
var _scope := "world"

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT
	add_child(_http)
	_http.request_completed.connect(_on_response)

## Davlat kodidan materik nomi.
static func continent_of(code: String) -> String:
	if _continents.is_empty():
		var file := FileAccess.open(CONTINENTS_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary:
				_continents = parsed
	return str(_continents.get(code.to_upper(), ""))

## Server sozlanganmi.
static func base_url(store: SettingsStore) -> String:
	var address := store.leaderboard_url.strip_edges()
	if address.is_empty():
		return ""
	if not address.begins_with("http"):
		address = "http://" + address
	return address.rstrip("/")

## Natijani yuboradi. Server yo'q bo'lsa jim o'tadi.
func submit(store: SettingsStore, percent: float, kills: int) -> void:
	var url := base_url(store)
	if url.is_empty() or _http == null:
		return
	var body := JSON.stringify({
		"name": store.nickname, "country": store.country,
		"city": store.city, "continent": continent_of(store.country),
		"percent": percent, "kills": kills,
	})
	# Natija yuborish javobi kerak emas — alohida so'rov bilan.
	var sender := HTTPRequest.new()
	sender.timeout = TIMEOUT
	add_child(sender)
	sender.request_completed.connect(
		func(_r: int, _c: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
			sender.queue_free())
	var error := sender.request(url + "/score", [
		"Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if error != OK:
		sender.queue_free()

## Ro'yxatni oladi. Javob `loaded` signalida keladi.
func fetch(store: SettingsStore, scope: String) -> void:
	var url := base_url(store)
	if url.is_empty():
		failed.emit("noServer")
		return
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	_scope = scope
	var key := ""
	match scope:
		"city": key = store.city
		"country": key = store.country
		"continent": key = continent_of(store.country)
	var query := "?scope=%s&key=%s" % [scope, key.uri_encode()]
	if _http.request(url + "/top" + query) != OK:
		failed.emit("connectFailed")

func _on_response(result: int, code: int, _headers: PackedStringArray,
		body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		failed.emit("connectFailed")
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not (parsed is Dictionary) or not parsed.has("rows"):
		failed.emit("connectFailed")
		return
	loaded.emit(_scope, parsed["rows"])
