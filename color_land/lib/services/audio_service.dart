import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// O'yin tovushlari: effektlar, fon musiqasi va vibratsiya.
///
/// Fayllar `assets/audio/` ichida va `tool/make_audio.py` bilan kod
/// orqali yaratilgan — tashqaridan tayyor audio olinmagan.
///
/// Uchala sozlama bir-biridan mustaqil: musiqa, ovoz effektlari va
/// vibratsiya alohida o'chadi. O'chirilgan bo'lsa hech narsa
/// yuklanmaydi ham.
class AudioService {
  AudioService({
    required this.musicEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  /// Effekt fayllari — bir marta xotiraga yuklanadi.
  static const List<String> sfxFiles = <String>[
    'capture.ogg',
    'kill.ogg',
    'death.ogg',
    'tap.ogg',
  ];

  static const String musicFile = 'music.ogg';

  bool musicEnabled;
  bool soundEnabled;
  bool vibrationEnabled;

  bool _loaded = false;
  bool _musicPlaying = false;

  /// Testlarda haqiqiy audio qurilmasi yo'q — shu yerda o'chiriladi.
  @visibleForTesting
  static bool disabled = false;

  /// Effektlarni oldindan yuklaydi. Xato bo'lsa o'yin to'xtamaydi —
  /// ovozsiz davom etadi.
  Future<void> preload() async {
    if (disabled || _loaded || !soundEnabled) return;
    _loaded = true;
    try {
      await FlameAudio.audioCache.loadAll(sfxFiles);
    } catch (e) {
      debugPrint('Ovozlarni yuklab bo\'lmadi: $e');
    }
  }

  Future<void> _play(String file) async {
    if (disabled || !soundEnabled) return;
    try {
      await FlameAudio.play(file, volume: 0.7);
    } catch (e) {
      debugPrint('Ovoz chalinmadi ($file): $e');
    }
  }

  /// Hudud egallandi.
  void capture() {
    _play('capture.ogg');
    _buzz(HapticFeedback.lightImpact);
  }

  /// Raqib yiqitildi.
  void kill() {
    _play('kill.ogg');
    _buzz(HapticFeedback.mediumImpact);
  }

  /// O'yinchi o'ldi.
  void death() {
    _play('death.ogg');
    _buzz(HapticFeedback.heavyImpact);
  }

  /// Interfeys bosilishi.
  void tap() {
    _play('tap.ogg');
    _buzz(HapticFeedback.selectionClick);
  }

  void _buzz(Future<void> Function() feedback) {
    if (disabled || !vibrationEnabled) return;
    feedback();
  }

  /// Fon musiqasini boshlaydi (allaqachon chalinayotgan bo'lsa — hech narsa).
  Future<void> startMusic() async {
    if (disabled || !musicEnabled || _musicPlaying) return;
    _musicPlaying = true;
    try {
      // `initialize` ikki ishni qiladi: ilova fonga o'tganda musiqani
      // pauza qiladi va audio kontekstini `mixWithOthers` ga qo'yadi —
      // ya'ni foydalanuvchining o'z musiqasi to'xtab qolmaydi.
      // Qayta chaqirilsa hech narsa qilmaydi.
      await FlameAudio.bgm.initialize();
      await FlameAudio.bgm.play(musicFile, volume: 0.35);
    } catch (e) {
      _musicPlaying = false;
      debugPrint('Musiqa chalinmadi: $e');
    }
  }

  Future<void> stopMusic() async {
    if (!_musicPlaying) return;
    _musicPlaying = false;
    try {
      await FlameAudio.bgm.stop();
    } catch (e) {
      debugPrint('Musiqani to\'xtatib bo\'lmadi: $e');
    }
  }

  /// Sozlama o'zgarganda chaqiriladi.
  Future<void> setMusicEnabled(bool value) async {
    musicEnabled = value;
    if (value) {
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  Future<void> setSoundEnabled(bool value) async {
    soundEnabled = value;
    if (value) await preload();
  }

  void setVibrationEnabled(bool value) => vibrationEnabled = value;

  Future<void> dispose() => stopMusic();
}
