extends SceneTree

## Ovoz tizimini tekshiradi: avtobuslar, balandlik egri chizig'i,
## kuy almashtirish va hamma fayl yuklanishi.
##
##   godot --headless --path . --script res://tools/audiotest.gd

var _fails := 0
var _checks := 0

func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
		print("  XATO: %s" % what)

func _initialize() -> void:
	# Avtoyuklangan tugunlar birinchi kadrda paydo bo'ladi, shuning
	# uchun tekshiruv `_process` da.
	pass

func _process(_delta: float) -> bool:
	var audio := root.get_node("/root/Audio")
	_check(audio != null, "Audio avtoyuklandi")
	if audio == null:
		quit(1)
		return true

	# Avtobuslar bormi.
	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index("Sfx")
	_check(music_bus > 0, "Music avtobusi bor")
	_check(sfx_bus > 0, "Sfx avtobusi bor")
	_check(AudioServer.get_bus_send(music_bus) == "Master",
		"Music -> Master ga uzatiladi")

	# Hamma kuy yuklanadimi va halqaga qo'yiladimi.
	for track: Dictionary in audio.TRACKS:
		var stream: AudioStream = load(track["path"])
		_check(stream != null, "kuy yuklandi: %s" % track["id"])
		if stream is AudioStreamOggVorbis:
			_check(stream.get_length() > 10.0,
				"kuy 10 soniyadan uzun: %s" % track["id"])

	# Kuy almashadimi.
	for track: Dictionary in audio.TRACKS:
		audio.set_track(track["id"])
		_check(audio.track_id == track["id"],
			"tanlangan kuy: %s" % track["id"])
	# Noma'lum nom standart kuyga tushadi.
	audio.set_track("yoq-bunaqa-kuy")
	_check(audio.track_id == audio.DEFAULT_TRACK,
		"noma'lum kuy standartga tushdi")

	# Balandlik: 0 da jim, 100 da eng baland, oraliq o'sib boradi.
	audio.set_music_volume(0)
	_check(AudioServer.is_bus_mute(music_bus), "0% da jim")
	var last := -200.0
	for percent: int in [5, 25, 50, 75, 100]:
		audio.set_music_volume(percent)
		var db := AudioServer.get_bus_volume_db(music_bus)
		_check(not AudioServer.is_bus_mute(music_bus),
			"%d%% da jim emas" % percent)
		_check(db > last, "%d%% oldingisidan baland" % percent)
		last = db
	_check(is_equal_approx(AudioServer.get_bus_volume_db(music_bus),
		audio.MUSIC_TRIM), "100% da kuchaytirish = MUSIC_TRIM")

	audio.set_sound_volume(0)
	_check(AudioServer.is_bus_mute(sfx_bus), "effektlar 0% da jim")
	audio.set_sound_volume(85)
	_check(not AudioServer.is_bus_mute(sfx_bus), "effektlar 85% da ochiq")

	# Chegaradan chiqqan qiymat qisiladi.
	audio.set_music_volume(500)
	_check(audio.music_volume == 100, "100 dan oshmaydi")
	audio.set_music_volume(-20)
	_check(audio.music_volume == 0, "0 dan tushmaydi")

	# Sozlamalar bilan to'liq qo'llash.
	var store := SettingsStore.load_store()
	store.music_volume = 40
	store.sound_volume = 60
	store.music_track = "neon"
	store.music_enabled = true
	audio.apply(store)
	_check(audio.music_volume == 40, "sozlamadan musiqa balandligi")
	_check(audio.sound_volume == 60, "sozlamadan effekt balandligi")
	_check(audio.track_id == "neon", "sozlamadan kuy")
	_check(audio.music_enabled, "sozlamadan musiqa yoqildi")

	# Tekshiruv tugadi — oqim ochiq qolmasin.
	audio.set_music_enabled(false)

	if _fails == 0:
		print("Ovoz tizimi joyida: %d ta tekshiruv" % _checks)
	else:
		print("%d ta tekshiruvdan %d tasi yiqildi" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)
	return true
