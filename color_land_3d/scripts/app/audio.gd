extends Node

## Ovoz effektlari, fon musiqasi va vibratsiya.
##
## Avtoyuklanadigan (autoload) tugun — har joydan `Audio.tap()` deb
## chaqirsa bo'ladi. Fayllar `assets/audio/` da va kod bilan
## yaratilgan (../color_land/tool/make_audio.py).

const SFX := {
	"capture": "res://assets/audio/capture.ogg",
	"kill": "res://assets/audio/kill.ogg",
	"death": "res://assets/audio/death.ogg",
	"tap": "res://assets/audio/tap.ogg",
}
const MUSIC_PATH := "res://assets/audio/music.ogg"

var music_enabled := true
var sound_enabled := true
var vibration_enabled := true

var _players: Dictionary = {}
var _music: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key: String in SFX:
		var player := AudioStreamPlayer.new()
		player.stream = load(SFX[key])
		player.volume_db = -6.0
		add_child(player)
		_players[key] = player

	_music = AudioStreamPlayer.new()
	var stream: AudioStream = load(MUSIC_PATH)
	# Kuy uzluksiz takrorlansin.
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_music.stream = stream
	_music.volume_db = -14.0
	add_child(_music)

## Sozlamalarni qo'llaydi.
func apply(music: bool, sound: bool, vibration: bool) -> void:
	sound_enabled = sound
	vibration_enabled = vibration
	set_music_enabled(music)

func set_music_enabled(value: bool) -> void:
	music_enabled = value
	if value:
		if not _music.playing:
			_music.play()
	else:
		_music.stop()

func _play(key: String) -> void:
	if not sound_enabled:
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
