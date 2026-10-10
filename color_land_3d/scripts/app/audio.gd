extends Node

## Ovoz effektlari, fon musiqasi va vibratsiya.
##
## Avtoyuklanadigan (autoload) tugun — har joydan `Audio.tap()` deb
## chaqirsa bo'ladi.
##
## Balandlik ikki qatlamda boshqariladi:
##   * har bir ovozning o'z `volume_db` si — miksni muvozanatlaydi
##     (masalan o'lim tovushi "tap" dan balandroq);
##   * "Music" va "Sfx" avtobuslari — o'yinchi sozlagan balandlik.
## Shuning uchun slayderni surish miksni buzmaydi.
##
## Fayllar `assets/audio/` da va kod bilan yaratilgan:
## musiqa — `tool/make_music.py`, effektlar — `../color_land/tool/make_audio.py`.

const SFX := {
	"capture": "res://assets/audio/capture.ogg",
	"kill": "res://assets/audio/kill.ogg",
	"death": "res://assets/audio/death.ogg",
	"tap": "res://assets/audio/tap.ogg",
}

## Har bir effektning miksdagi o'rni (dB).
const SFX_LEVEL := {
	"capture": -5.0,
	"kill": -6.0,
	"death": -4.0,
	"tap": -11.0,
}

## Tanlanadigan kuylar. `key` — `data/strings.json` dagi nom kaliti.
const TRACKS: Array[Dictionary] = [
	{
		"id": "pulse",
		"key": "trackPulse",
		"path": "res://assets/audio/music_pulse.ogg",
	},
	{
		"id": "neon",
		"key": "trackNeon",
		"path": "res://assets/audio/music_neon.ogg",
	},
	{
		"id": "sprint",
		"key": "trackSprint",
		"path": "res://assets/audio/music_sprint.ogg",
	},
	{
		"id": "retro",
		"key": "trackRetro",
		"path": "res://assets/audio/music.ogg",
	},
]

const DEFAULT_TRACK := "pulse"

## Avtobus nomlari.
const MUSIC_BUS := "Music"
const SFX_BUS := "Sfx"

## 100% da avtobusning kuchaytirishi (dB). Musiqa fon bo'lib
## tursin — shuning uchun effektlardan pastroq.
const MUSIC_TRIM := -7.0
const SFX_TRIM := -1.0

## Kuy almashganda qancha vaqtda ko'tariladi (soniya).
const FADE := 0.4

var music_enabled := true
var sound_enabled := true
var vibration_enabled := true

## 0..100. Noldan katta bo'lsa ham `music_enabled` o'chiq bo'lsa jim.
var music_volume := 70
var sound_volume := 85

var track_id := DEFAULT_TRACK

var _players: Dictionary = {}
var _music: AudioStreamPlayer
var _fade: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()

	for key: String in SFX:
		var player := AudioStreamPlayer.new()
		player.stream = load(SFX[key])
		player.volume_db = float(SFX_LEVEL.get(key, -6.0))
		player.bus = SFX_BUS
		add_child(player)
		_players[key] = player

	_music = AudioStreamPlayer.new()
	_music.bus = MUSIC_BUS
	add_child(_music)
	_load_track(track_id)
	_push_volumes()

## Avtobuslar `default_bus_layout.tres` dan keladi. Agar u biron
## sababdan yuklanmasa, o'yin ovozsiz qolmasin — shu yerda yaratiladi.
func _ensure_buses() -> void:
	for name: String in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(name) >= 0:
			continue
		var index := AudioServer.bus_count
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, name)
		AudioServer.set_bus_send(index, "Master")

## Sozlamalarni qo'llaydi.
func apply(store: SettingsStore) -> void:
	sound_enabled = store.sound_enabled
	vibration_enabled = store.vibration_enabled
	music_volume = store.music_volume
	sound_volume = store.sound_volume
	_push_volumes()
	set_track(store.music_track)
	set_music_enabled(store.music_enabled)

func set_music_enabled(value: bool) -> void:
	music_enabled = value
	if value:
		if not _music.playing:
			_music.play()
			_fade_in()
	else:
		_music.stop()

## Kuyni almashtiradi. O'ynab turgan bo'lsa yangisi yumshoq ko'tariladi.
func set_track(id: String) -> void:
	if id == track_id:
		return
	_load_track(id)
	if music_enabled:
		_music.play()
		_fade_in()

func _load_track(id: String) -> void:
	var path := ""
	for track: Dictionary in TRACKS:
		if track["id"] == id:
			path = track["path"]
			break
	if path.is_empty():
		id = DEFAULT_TRACK
		path = TRACKS[0]["path"]
	track_id = id
	var stream: AudioStream = load(path)
	# Kuy uzluksiz takrorlansin.
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_music.stream = stream

func _fade_in() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_music.volume_db = -24.0
	_fade = create_tween()
	_fade.tween_property(_music, "volume_db", 0.0, FADE)

## Musiqa balandligi (0..100).
func set_music_volume(percent: int) -> void:
	music_volume = clampi(percent, 0, 100)
	_push_volumes()

## Effektlar balandligi (0..100).
func set_sound_volume(percent: int) -> void:
	sound_volume = clampi(percent, 0, 100)
	_push_volumes()

func _push_volumes() -> void:
	_set_bus(MUSIC_BUS, music_volume, MUSIC_TRIM)
	_set_bus(SFX_BUS, sound_volume, SFX_TRIM)

func _set_bus(name: String, percent: int, trim: float) -> void:
	var index := AudioServer.get_bus_index(name)
	if index < 0:
		return
	var level := clampf(percent / 100.0, 0.0, 1.0)
	AudioServer.set_bus_mute(index, level <= 0.0)
	if level <= 0.0:
		return
	# Daraja kvadratga yaqin egri chiziq bilan o'giriladi — slayder
	# o'rtasida ovoz "yarmi" bo'lib eshitiladi.
	AudioServer.set_bus_volume_db(index, linear_to_db(pow(level, 1.7)) + trim)

func _exit_tree() -> void:
	# Tugun daraxtdan chiqqanda o'ynab turgan oqim AudioServer'da
	# osilib qolmasin. (Ilova to'liq yopilganda Godot baribir
	# "leaked instance" deb ogohlantiradi — bu dvigatelning o'z
	# yopilish tartibi, o'zgarishdan oldin ham shunaqa edi.)
	if _music != null and _music.playing:
		_music.stop()

func _play(key: String) -> void:
	if not sound_enabled or sound_volume <= 0:
		return
	var player: AudioStreamPlayer = _players.get(key)
	if player != null:
		player.play()

func _buzz(strength: float) -> void:
	if not vibration_enabled:
		return
	# Godot'da haptik faqat Android/iOS da ishlaydi; boshqa joyda jim.
	Input.vibrate_handheld(int(strength))

## Hudud egallandi.
func capture() -> void:
	_play("capture")
	_buzz(25)

## Raqib yiqitildi.
func kill() -> void:
	_play("kill")
	_buzz(45)

## O'yinchi o'ldi.
func death() -> void:
	_play("death")
	_buzz(90)

## Interfeys bosilishi.
func tap() -> void:
	_play("tap")
	_buzz(12)
